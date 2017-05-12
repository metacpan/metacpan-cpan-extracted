package CGI::AppBuilder;

# Perl standard modules
use strict;
use warnings;
use Getopt::Std;
use POSIX qw(strftime);
use CGI;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use CGI::Pretty ':standard';
use CGI::AppBuilder::Apps     qw(:all); 
use CGI::AppBuilder::Config   qw(:all); 
use CGI::AppBuilder::Message  qw(:all); 
use CGI::AppBuilder::Log      qw(:all); 
use CGI::AppBuilder::Form     qw(:all); 
use CGI::AppBuilder::Table    qw(:all); 
use CGI::AppBuilder::Header   qw(:all); 
use CGI::AppBuilder::Frame    qw(:all); 
use CGI::AppBuilder::Net      qw(:all); 
use CGI::AppBuilder::File     qw(:all); 
use CGI::AppBuilder::Security qw(:all); 
use CGI::AppBuilder::Define   qw(:all); 
use CGI::AppBuilder::HTML     qw(:all); 
use CGI::AppBuilder::PLSQL    qw(:all); 

our $VERSION = 1.0001;
warningsToBrowser(1);

require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT      = qw();
our @IMPORT_OK = (@CGI::AppBuilder::Apps::EXPORT_OK,
    @CGI::AppBuilder::Config::EXPORT_OK,
    @CGI::AppBuilder::Message::EXPORT_OK, 
    @CGI::AppBuilder::Log::EXPORT_OK, 
    @CGI::AppBuilder::Form::EXPORT_OK, 
    @CGI::AppBuilder::Table::EXPORT_OK, 
    @CGI::AppBuilder::Header::EXPORT_OK, 
    @CGI::AppBuilder::Frame::EXPORT_OK,
    @CGI::AppBuilder::Net::EXPORT_OK,
    @CGI::AppBuilder::File::EXPORT_OK,     
    @CGI::AppBuilder::Security::EXPORT_OK,
    @CGI::AppBuilder::Define::EXPORT_OK,
    @CGI::AppBuilder::HTML::EXPORT_OK,
    @CGI::AppBuilder::PLSQL::EXPORT_OK,
);
our @EXPORT_OK   = (@IMPORT_OK);
our %EXPORT_TAGS = (
    app      => [@CGI::AppBuilder::Apps::EXPORT_OK],
    config   => [@CGI::AppBuilder::Config::EXPORT_OK],
    echo_msg => [@CGI::AppBuilder::Message::EXPORT_OK],
    log      => [@CGI::AppBuilder::Log::EXPORT_OK],
    form     => [@CGI::AppBuilder::Form::EXPORT_OK],
    table    => [@CGI::AppBuilder::Table::EXPORT_OK],
    header   => [@CGI::AppBuilder::Header::EXPORT_OK],
    frame    => [@CGI::AppBuilder::Frame::EXPORT_OK],
    exec     => [@CGI::AppBuilder::Net::EXPORT_OK],    
    file     => [@CGI::AppBuilder::File::EXPORT_OK],        
    security => [@CGI::AppBuilder::Security::EXPORT_OK],        
    html     => [@CGI::AppBuilder::HTML::EXPORT_OK],        
    plsql    => [@CGI::AppBuilder::PLSQL::EXPORT_OK], 
    all      => [@EXPORT_OK, @IMPORT_OK]
);

=head1 NAME

CGI::AppBuilder - CGI Application Builder 

=head1 SYNOPSIS

  use CGI::AppBuilder;

  my $cg = CGI::AppBuilder->new('ifn', 'my_init.cfg', 'opt', 'vhS:a:');
  my $ar = $cg->get_inputs; 

=head1 DESCRIPTION

There are already many application builders out there. Why you need 
another one? Well, if you are already familiar with CGI::Builder or
CGI::Application, this one will provide some useful methods to you to
read your configuration file and pre-process your templates. 
Please read on.

=cut

=head3 new (ifn => 'file.cfg', opt => 'hvS:')

Input variables:

  $ifn  - input/initial file name. 
  $opt  - options for Getopt::Std

Variables used or routines called:

  None

How to use:

   my $ca = new CGI::AppBuilder;      # or
   my $ca = CGI::AppBuilder->new;     # or
   my $ca = CGI::AppBuilder->new(ifn=>'file.cfg',opt=>'hvS:'); # or
   my $ca = CGI::AppBuilder->new('ifn', 'file.cfg','opt','hvS:'); 

Return: new empty or initialized CGI::AppBuilder object.

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

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version is to extract out the app methods from CGI::Getopt class.
It was too much for CGI::Getopt to include the start_app, end_app,
build_html_header, and disp_form methods. 

  0.11 Rewrote start_app method so that content-type can be changed.
  0.12 Moved disp_form to CGI::AppBuilder::Form,
       moved build_html_header to CGI::AppBuilder::Header, and 
       imported all the methods in sub-classes into this class.

=item * Version 1.0001

Removed start_app and end_app to CGI::AppBuilder::Apps module. 

=cut

=head1 SEE ALSO (some of docs that I check often)

Oracle::Loader, Oracle::Trigger, CGI::Getopt, File::Xcopy,
CGI::AppBuilder, CGI::AppBuilder::Message, CGI::AppBuilder::Log,
CGI::AppBuilder::Config, etc.

=head1 AUTHOR

Copyright (c) 2005 ~ 2015 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

