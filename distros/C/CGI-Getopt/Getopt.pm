package CGI::Getopt;

# Perl standard modules
use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use CGI;
use Getopt::Std;
use Debug::EchoMessage;

our $VERSION = 0.13;
warningsToBrowser(1);

require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(get_inputs read_init_file read_cfg_file
                   );
our %EXPORT_TAGS = (
    all  => [@EXPORT_OK]
);

=head1 NAME

CGI::Getopt - Configuration initializer 

=head1 SYNOPSIS

  use CGI::Getopt;

  my $cg = CGI::Getopt->new('ifn', 'my_init.cfg', 'opt', 'vhS:a:');
  my $ar = $cg->get_inputs; 

=head1 DESCRIPTION

This program enables CGI and command line inputs. It uses CGI and 
Getopt::Std modules. 

=cut

=head3 new (ifn => 'file.cfg', opt => 'hvS:')

Input variables:

  $ifn  - input/initial file name. 
  $opt  - options for Getopt::Std

Variables used or routines called:

  None

How to use:

   my $cg = new CGI::Getopt;      # or
   my $cg = CGI::Getopt->new;     # or
   my $cg = CGI::Getopt->new(ifn=>'file.cfg',opt=>'hvS:'); # or
   my $cg = CGI::Getopt->new('ifn', 'file.cfg','opt','hvS:'); 

Return: new empty or initialized CGI::Getopt object.

This method constructs a Perl object and capture any parameters if
specified. It creates and defaults the following variables:
 
  $self->{ifn} = ""
  $self->{opt} = 'hvS:'; 

=cut

sub new {
    my $caller        = shift;
    my $caller_is_obj = ref($caller);
    my $class         = $caller_is_obj || $caller;
    my $self          = bless {}, $class;
    my %arg           = @_;   # convert rest of inputs into hash array
    foreach my $k ( keys %arg ) {
        if ($caller_is_obj) {
            $self->{$k} = $caller->{$k};
        } else {
            $self->{$k} = $arg{$k};
        }
    }
    $self->{ifn} = ""     if ! exists $arg{ifn};
    $self->{opt} = 'hvS:' if ! exists $arg{opt};
    return $self;
}

=head3 get_inputs($ifn, $opt)

Input variables:

  $ifn  - input/initial file name. 
  $opt  - options for Getopt::Std, for instance 'vhS:a:'

Variables used or routines called:

  None

How to use:

  my $ar = $self->get_inputs('/tmp/my_init.cfg','vhS:');

Return: ($q, $ar) where $q is the CGI object and 
$ar is a hash array reference containing parameters from web form,
or command line and/or configuration file if specified.

This method performs the following tasks:

  1) create a CGI object
  2) get input from CGI web form or command line 
  3) read initial file if provided
  4) merge the two inputs into one hash array

This method uses the following rules: 

  1) All parameters in the initial file can not be changed through
     command line or web form;
  2) The "-S" option in command line can be used to set non-single
     char parameters in the format of 
     -S k1=value1:k2=value2
  3) Single char parameters are included only if they are listed
     in $opt input variable.

Some parameters are dfined automatically:

  script_name - $ENV{SCRIPT_NAME} 
  url_dn      - $ENV{HTTP_HOST}
  home_url    - http://$ENV{HTTP_HOST}
  HomeLoc     - http://$ENV{HTTP_HOST}/
  version     - $VERSION
  action      - https://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}
  encoding    - application/x-www-form-urlencoded
  method      - POST

=cut

sub get_inputs {
    my $s = shift;
    my ($ifn, $par) = @_;

    $ifn = $s->{ifn} if !$ifn;
    $par = $s->{opt} if !$par;
    $s->echoMSG("IFN=$ifn\nOPT=$par",3);
    $s->echoMSG("ARGV: @ARGV",3);

    # return () if (!$ENV{'QUERY_STRING'} && !$ENV{'DOCUMENT_URI'} &&
    #      !$ENV{'REMOTE_ADDR'}  && !@ARGV);

    my %opt = ();           # optional inputs
    my %cfg = ();           # configuration parameters
    my $ds = '/';           # dir separator
    my $q = new CGI;        # create CGI object
    my $script_name = "";
       $script_name = $ENV{SCRIPT_NAME} if exists $ENV{SCRIPT_NAME};
    $opt{script_name} = $script_name;
    if (exists $ENV{HTTP_HOST}) {
        $opt{url_dn} = $ENV{HTTP_HOST};
        if (exists $ENV{HTTPS} && $ENV{HTTPS} =~ /^on/i) { 
            $opt{action} = "https://$opt{url_dn}$ENV{SCRIPT_NAME}";
        } else {
            $opt{action} = "http://$opt{url_dn}$ENV{SCRIPT_NAME}";
        }
    } else {
        $opt{url_dn} = ""; 
        $opt{action} = "command line";
    }
    $opt{encoding}  = 'application/x-www-form-urlencoded';
    $opt{method}    = 'POST';
    if (!$ENV{'QUERY_STRING'} || @ARGV) {
        $s->echoMSG("Got ARGV...", 3);
        # since $s->{opt} was set in new, then we have $par
        getopts("$par", \%opt);
        # $s->disp_param(\%opt); 
    } else {
        $s->echoMSG("Got QUERY_STRING...", 3);
        # corresponding to ARGV
        my $p1 = $par;  $p1 =~ s/://g;   # remove ':"
        foreach my $k (split //, $p1) { 
            $opt{$k} = $q->param($k);    # get inputs 
        }
    }
    my @names = ();
    if (exists $ENV{QUERY_STRING} && $ENV{QUERY_STRING}) {
        @names = $q->param;
    }
    if (exists $opt{S} && $opt{S}) {
        foreach my $r (split /\:/, $opt{S}) { 
            my ($k, $v) = (split /=/, $r);
            $opt{$k} = $v if ! exists $opt{$k};
        }
    }
    foreach my $k (@names) { 
        $opt{$k} = $q->param($k) if ! exists $opt{$k}; 
    }
    # check input variables
    $opt{v}  = 'n' if ! exists $opt{v} || !defined($opt{v}); 
    $opt{v}  = ($opt{v} && $opt{v} =~ /^y/i)?1:$opt{v};
    $opt{v}  = ($opt{v} =~ /\d+/)?$opt{v}:0;
    
    %cfg = ($ifn && -f $ifn)?$s->read_init_file($ifn):();
    $cfg{version} = "CGI::Getopt $VERSION";
    
    if (exists $ENV{HTTP_HOST}) {
        $cfg{home_url} = "http://$ENV{HTTP_HOST}"  if !$cfg{home_url}; 
        $cfg{HomeLoc}  = "http://$ENV{HTTP_HOST}/" if !$cfg{HomeLoc}; 
    } else {
        $cfg{home_url} = ""   ; # home URL
        $cfg{HomeLoc}  = "/"  ; # ASP var
    }
    foreach my $k (keys %opt) { 
        $cfg{$k} = $opt{$k} if ! exists $cfg{$k}; 
    }
    return ($q, \%cfg);
}

=head3  read_init_file($fn)

Input variables:

  $fn - full path to a file name

Variables used or routines called:

  None 

How to use:

  my $ar = $self->read_init_file('crop.cfg');

Return: a hash array ref 

This method reads a configuraton file containing parameters in the 
format of key=values. Multiple lines is allowed for values as long
as the lines after the "key=" line are indented as least with two 
blanks. For instance:

  width = 80
  desc  = This is a long
          description about the value

This will create a hash array of 

  ${$ar}{width} = 80
  ${$ar}{desc}  = "This is a long description about the value"

=cut

sub read_init_file {
    my $s = shift;
    my ($fn) = @_;
    if (!$fn)    { carp "    No file name is specified."; return; }
    if (!-f $fn) { carp "    File - $fn does not exist!"; return; }
    
    my ($k, $v, %h);
    open FILE, "< $fn" or
        croak "ERR: could not read to file - $fn: $!\n";
    while (<FILE>) {
        # skip comment and empty lines
        next if $_ =~ /^#/ || $_ =~ /^\s*$/; 
        chomp;               # remove line break
        if ($_ =~ /\s*(\w+)\s*=\s*(.+)/) {
            $k = $1; $v = $2;  
            $v =~ s/\s*#.*$//;   # remove inline comments
            $h{$k} = $v;
        } else {
            $v = $_; 
            # remove leading and trailing spaces 
            $v =~ s/^\s+//; $v =~ s/\s+$//; 
            $v =~ s/\s*#.*$//;   # remove inline comments
            $h{$k} .= " $v";
        }
    }
    close FILE;
    return %h;
}

=head3  read_cfg_file($fn,$ot, $fs)

Input variables:

  $fn - full path to a file name
  $ot - output array type: A(array) or H(hash)
  $fs - field separator, default to vertical bar (|)


Variables used or routines called:

  echoMSG  - display message

How to use:

  my $arf = $self->read_cfg_file('crop.cfg', 'H');

Return: an array or hash array ref containing (${$arf}[$i]{$itm},
${$arf}[$i][$j];

This method reads a configuraton file containing delimited fields. 
It looks a line starting with '#CN:' for column names. If it finds 
the line, it uses to define the first row in the array or use the 
column names as keys in the hash array. 

The default output type is A(array). It will read the field names
into the first row ([0][0]~[0][n]). If output array type is hash,
then it uses the columns name as keys such as ${$arf}[$i]{key}. 
If it does not find '#CN:' line, it will use 'FD001' ~ 'FD###' as
keys.

  #Form: fm1
  #CN: Step|VarName|DispName|Action|Description				
  0.0|t1|Title||CROP Worksheet				


=cut

sub read_cfg_file {
    my $s = shift;
    my ($fn,$ot,$fs) = @_;
    #
    if (!$fn)    { carp "    No file name is specified."; return; }
    if (!-f $fn) { carp "    File - $fn does not exist!"; return; }
    $ot = 'A' if !$ot;
    
    my (@a, @b, $i, $j, $k, @keys, $rec);
    open FILE, "< $fn" or
        croak "ERR: could not read to file - $fn: $!\n";
    @a = <FILE>;
    close FILE;
    my @r = (); 
    # get column names first
    for my $x (0..$#a) {
        $rec = $a[$x];
        next if ($rec !~ /^#\s*CN:\s*(.*)/);
        $k =$1; $k =~ s/^\s+//; $k =~ s/\s+$//; $k =~ s/\s+/_/g;
        @keys = split /\|/, $k;
        $r[0] = [@keys];
        last;
    }
    
    # get content
    $i = 0; $rec = "";
    for my $x (0..$#a) {
        # skip comment and empty lines
        next if ($a[$x] =~ /^#/ || $a[$x] =~ /^\s*$/);
        chomp $a[$x]; 
        if ($a[$x] =~ /^\s*\|/) {
            $rec .= " $a[$x]"; # continuous record
        } elsif (index($a[$x], "\|")>=0) {
            if ($rec) {        # save the previous record
                $rec =~ s/\s+/ /g; @b = split /\|/, $rec; 
                ++$i; $r[$i]=[@b];
            }
            $rec = $a[$x];     # a new record
        } else {
            $rec .= " $a[$x]"; # continuous record
        }
    }
    if ($rec) { 
        $rec =~ s/\s+/ /g; @b = split /\|/, $rec; 
        ++$i; $r[$i]=[@b];
    }
    if (!@keys) {  # if it did not get the keys
        for $j (0..$#{$r[1]}) {
            push @keys, (sprintf "DF%03d", $j+1);
        }
        $r[0] = [@keys];        
    }
    return \@r if $ot =~ /^A/i; 
    #
    my @hr = ();

    # convert the array into hash array
    for $i (1..$#r) {
        my %h = ();
        for $j (0..$#{$r[$i]}) {
            $k = $r[0][$j]; 
            $h{$k} = $r[$i][$j];
        }
        $j = $i-1;
        $hr[$j] = \%h;
    }
    return \@hr;
}


1;

=head1 HISTORY

=over 4

=item * Version 0.1

This version is to test the concept and routines.

=item * Version 0.11

04/29/2005 (htu) - fixed a few minor things such as module title. 

=item * Version 0.12

Make sure Debug::EchoMessage installed as pre-required.

=item * Version 0.13

Added read_cfg_file routine.

=cut

=head1 SEE ALSO (some of docs that I check often)

Data::Describe, Oracle::Loader, CGI::Getopt, File::Xcopy,
perltoot(1), perlobj(1), perlbot(1), perlsub(1), perldata(1),
perlsub(1), perlmod(1), perlmodlib(1), perlref(1), perlreftut(1).

=head1 AUTHOR

Copyright (c) 2005 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut


