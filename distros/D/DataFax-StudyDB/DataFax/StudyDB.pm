package DataFax::StudyDB;

use strict;
use vars qw(@ISA $VERSION @EXPORT @EXPORT_OK @IMPORT_OK %EXPORT_TAGS);
use Carp;
use DataFax; 
use DataFax::StudySubs qw(:all); 

$VERSION = 0.11;
@ISA       = qw(Exporter DataFax);
@EXPORT    = qw(readDFstudies);
@EXPORT_OK = qw(readDFstudies);
@IMPORT_OK = qw(dfparam get_dfparam exec_cmd);
%EXPORT_TAGS= (
    all     =>[@EXPORT_OK],
);

=head1 NAME

DataFax::StudyDB - DataFax DFstudies.db parser

=head1 SYNOPSIS

  use DataFax::StudyDB;

  my $db = DataFax::StudyDB->new('datafax_dir'=>'/opt/datafax', 
            'datafax_host'=>'mydfsvr');
  # or
  my $db = new DataFax::StudyDB 'datafax_dir'=>'/opt/datafax', 
            'datafax_host'=>'mydfsvr';

=head1 DESCRIPTION

This class locates DataFax DFstudies.db, parse it and load it to
a relational database such as Oracle. 

=cut

=head2 new (datafax_dir=>'/opt/datafax',datafax_host=>'my_svr')

Input variables:

  datafax_dir  - full path to where DataFax system is installled 
                 If not specified, it will try to get it from
                 $ENV{DATAFAX_DIR}.
  datafax_host - DataFax server name or IP address
                 If not specified, it will try to get it from
                 $ENV{DATAFAX_HOST} or `hostname` on UNIX system.

Variables used or routines called:

  None

How to use:

  my $db = DataFax::StudyDB->new('datafax_dir'=>'/opt/datafax', 
            'datafax_host'=>'mydfsvr');
Return: an empty or initialized class object.

This method constructs a Perl object and capture any parameters if
specified. It creates and defaults the following variables:

  datafax_dir  = $ENV{DATAFAX_DIR}
  datafax_host = $ENV{DATAFAX_HOST} | `hostname` 
  unix_os      = 'linux|solaris'

=cut

sub new {
  my ($s, %args) = @_;
  return $s->SUPER::new(%args);
}

# ---------------------------------------------------------------------

=head2 Export Tag: all

The :all tag includes the all the methods in this module.

  use DataFax::StudyDB qw(:all);

It includes the following sub-routines:

=head3 readDFstudies($q, $ar)

Input variables:

  $ifn - input file name 
  $ar  - a parameter array ref
    source_dir   - source directory
    datafax_dir  - DataFax directory
    datafax_host - DataFax server name/IP address
    real_time    - whether to ge real time data

Variables used or routines called: 

  DataFax::StudySubs
    get_dfparam - get parameters 
    
How to use:

  my $s = new DataFax::StudyDB;
  my $ifn = '/opt/datafax/lib/DFstudies.db'; 
  my $pr = { real_time=>1,datafax_host=>'df_svr',
             datafax_usr=>'datafax', datafax_pwd=>'secret'}; 
  my ($c, $d) = $s->readDFstudies{$ifn);
  my ($c, $d) = $s->readDFstudies{"", $pr);

Return: ($c,$d) where $c is an array ref while $d is hash ref.

  $c->[$i][$j] - array ref where 
       $i is row number and 
       $j is column number; 
       $i=0 - the first row contains the column names in the 
              following order
              study_number,study_title,client_name,study_dir,
              source_dir,datafax_dir,host_name,rpc_program,
              rpc_program_no,rpc_version_no,study_status,comments
  $d->{$sn}{$itm} hash ref where
       $sn is three-digit study number padding with leading zeros
       $itm is column names as listed in $c->[0]. 

This method reads DFstudies and parse the file into two arrays. 

=cut

sub readDFstudies {
    my $s = shift;
    my ($ifn, $ar) = @_;
    my $vs  = 'source_dir,datafax_dir,datafax_host,dir_sep,local_host,';
       $vs .= 'unix_os,real_time';
    my  ($sdr,$dfd,$dfh,$ds,$svr,$uos,$rt) = $s->get_dfparam($vs, $ar);
    croak "ERR (readDFstudies): DATAFAX_DIR is not specified." 
        if !$ifn && !$dfd; 
    croak "ERR: could not get real time DFstudies.db on this OS" 
        if $rt && $svr && $dfh && $svr ne $dfh && $^O !~ /^($uos)/i;
    $ds = '/'  if ! $ds; 
    $svr = `hostname` if !$svr && $^O =~ /^($uos)/i; 
    my $dir = ($rt) ? $dfd : $sdr; 
    my $cmd = 'cat ' . (($ifn) ? $ifn : 
              (join $ds, $dir, 'lib', 'DFstudies.db'));
    $s->echo_msg("  - running $cmd...", 1); 
    my @a = $s->exec_cmd($cmd,$ar); 
    my $c = bless [], ref($s)||$s;
    my $d = bless {}, ref($s)||$s;
    my $vars  = 'study_number,study_title,client_name,study_dir,';
       $vars .= 'source_dir,datafax_dir,host_name,rpc_program,';
       $vars .= 'rpc_program_no,rpc_version_no,study_status,comments'; 
    push @$c, [split /,/, $vars]; 
    my ($rpc); 
    foreach (@a) {
        # Fields in DFstudies.db:
        #   0 - study number           4 - command to start server
        #   1 - host name              5 - candidate host names
        #   2 - RPC program number     6 - label
        #   3 - RPC version number
        next     if $_ =~ /^(#|\s*$)/;
        chomp;
        my @b = split(/\|/,$_);
        my $sn  = $b[0];                    # add leading zeros
        $sn  = sprintf "%03d", $b[0] if $b[0] =~ /^\d+$/; 
        $d->{$sn} = {};
        $d->{$sn}{host_name}      = ($b[1])?$b[1]:$b[5];
        $d->{$sn}{rpc_program_no} = $b[2];
        $d->{$sn}{rpc_version_no} = $b[3];
        ($rpc,$dir) =  
            ($b[4] =~ /(.*)\s*-c\s*(.+)\/lib\/DFserver\.cf/); 
        $d->{$sn}{rpc_program}    = $rpc;
        $d->{$sn}{study_dir}      = $dir;
        $d->{$sn}{source_dir}     = join $ds, $sdr, "S$sn";
        $d->{$sn}{client_name}    = $b[5];
        $d->{$sn}{study_title}    = $b[6];
        $d->{$sn}{datafax_dir}    = $dfd;
        if ($b[1] =~ /^\-/) {
            $d->{$sn}{comments} = $b[1];
            $d->{$sn}{study_status} = 'Down';
            $d->{$sn}{host_name}    = $b[5];
        } else {
            $d->{$sn}{comments} = "";
            $d->{$sn}{study_status}   = 'Up';
        }
        $d->{$sn}{study_number} = $sn;
        push @$c, [map { $d->{$sn}{$_} } (split /,/, $vars) ]; 
    }
    close FILE;
    my $n = $#$c+1;
    $s->echo_msg("    $n valid records.", 2); 
    return ($c,$d);
}

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version is to create a method to read in DFstudies.db.

  0.11 - use new method from DataFax

=item * Version 0.20

=cut

=head1 SEE ALSO (some of docs that I check often)

Oracle::Loader, Oracle::Trigger, CGI::Getopt, File::Xcopy,
DataFax, CGI::AppBuilder, etc.

=head1 AUTHOR

Copyright (c) 2005 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

