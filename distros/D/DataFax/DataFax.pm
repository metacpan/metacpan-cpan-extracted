package DataFax;

# Perl standard modules
use strict;
use warnings;
use Getopt::Std;
use POSIX qw(strftime);
# use DataFax::Config   qw(:all); 
use DataFax::StudyDB    qw(:all);
use DataFax::StudySubs  qw(:all);

our $VERSION = 0.10;

require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT      = qw();
our @IMPORT_OK = (@DataFax::StudyDB::EXPORT_OK,
    @DataFax::StudySubs::EXPORT_OK 
);
our @EXPORT_OK   = ('new', @IMPORT_OK);
our %EXPORT_TAGS = (
    # config   => [@DataFax::Config::EXPORT_OK],
    dfdb     => [@DataFax::StudyDB::EXPORT_OK],
    echo_msg => $DataFax::StudySubs::EXPORT_TAGS{echo_msg},
    param    => $DataFax::StudySubs::EXPORT_TAGS{param},
    subs     => [@DataFax::StudySubs::EXPORT_OK],
    all      => [@EXPORT_OK, @IMPORT_OK]
);

=head1 NAME

DataFax - an DataFax object 

=head1 SYNOPSIS

  use DataFax;

  my $cg = DataFax->new('ifn', 'my_init.cfg', 'opt', 'vhS:a:');

=head1 DESCRIPTION

This is the base object for DataFax. 

=cut

=head3 new (ifn => 'file.cfg', opt => 'hvS:')

Input variables:

  ifn  - input/initial file name. 
  opt  - options for Getopt::Std
  datafax_dir  - full path to where DataFax system is installled
                 If not specified, it will try to get it from
                 $ENV{DATAFAX_DIR}.
  datafax_host - DataFax server name or IP address
                 If not specified, it will try to get it from
                 $ENV{DATAFAX_HOST} or `hostname` on UNIX system.

Variables used or routines called:

  None

How to use:

   my $df = new DataFax;      # or
   my $df = DataFax->new;     # or
   my $df = DataFax->new(ifn=>'file.cfg',opt=>'hvS:'); # or
   my $df = DataFax->new('ifn', 'file.cfg','opt','hvS:'); 

Return: new empty or initialized DataFax object.

This method constructs a Perl object and capture any parameters if
specified. It creates and defaults the following variables:
 
  ifn          = ""
  opt          = 'hvS:' 
  datafax_dir  = $ENV{DATAFAX_DIR}
  datafax_host = $ENV{DATAFAX_HOST} | `hostname`
  unix_os      = 'linux|solaris'

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
    $self->{unix_os} = 'linux|solaris';
    $self->{datafax_dir} = "" if ! exists $self->{datafax_dir};
    $self->{datafax_host}= "" if ! exists $self->{datafax_host};
    $self->{datafax_dir} = $ENV{DATAFAX_DIR}
       if exists $ENV{DATAFAX_DIR} && ! $self->{datafax_dir};
    $self->{datafax_host} = $ENV{DATAFAX_HOST}
       if exists $ENV{DATAFAX_HOST} && ! $self->{datafax_host};
    $self->{datafax_host} = `hostname`
       if ! $self->{datafax_host} && $^O =~ /^($self->{unix_os})/i;
    return $self;
}

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version is to set base for other DataFax classes.

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

