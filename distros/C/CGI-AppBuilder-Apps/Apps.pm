package CGI::AppBuilder::Apps;

# Perl standard modules
# use strict;
use warnings;
# use Getopt::Std;
use POSIX qw(strftime);
# use CGI;
# use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
# use CGI::Pretty ':standard'; 
 use CGI::AppBuilder; 

our $VERSION = 1.0001;

# require Exporter;
our @ISA         = qw(Exporter CGI::AppBuilder);
our @EXPORT      = qw();
our @EXPORT_OK   = (qw(start_app end_app build_html_header));
our %EXPORT_TAGS = (
    all      => [@EXPORT_OK]
);

=head1 NAME

CGI::AppBuilder - CGI Application Builder 

=head1 SYNOPSIS

  use CGI::AppBuilder::Apps;

  my $cg = CGI::AppBuilder::Apps->new('ifn', 'my_init.cfg', 'opt', 'vhS:a:');
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

   my $ca = new CGI::AppBuilder::Apps;      # or
   my $ca = CGI::AppBuilder::Apps->new;     # or
   my $ca = CGI::AppBuilder::Apps->new(ifn=>'file.cfg',opt=>'hvS:'); # or
   my $ca = CGI::AppBuilder::Apps->new('ifn', 'file.cfg','opt','hvS:'); 

Return: new empty or initialized CGI::AppBuilder::Apps object.

This method constructs a Perl object and capture any parameters if
specified. It creates and defaults the following variables:
 
  $self->{ifn} = ""
  $self->{opt} = 'hvS:'; 

=cut

sub new {
  my ($s, %args) = @_;
  return $s->SUPER::new(%args);
}

=head3 start_app ($prg,$arg,$nhh)

Input variables:

  $prg  - program name 
  $arg  - array ref for arguments - %ARGV
  $nhh  - no html header pre-printed 
          0 - HTML header will be set when it is possible
          1 - no HTML header is set in any circumstance

Variables used or routines called:

  build_html_header 	- build HTML header array
  echo_msg  		- echo messages
  start_log 		- start and write message log
  get_inputs 		- read input file and/or CGI form inputs
    

How to use:

   my ($q, $ar, $ar_log) = $self->start_app($0,\@ARGV);

Return: ($q,$ar,$ar_log) where 

  $q - a CGI object
  $ar - hash ref containing parameters from input file and/or 
        CGI form inputs and the following elements:
    ifn - initial file name
    opt - command input options
    cfg - configuration array
    html_header - HTML header parameters (hash ref)
    msg - contain message hash
  $ar_log - hash ref containing log information

This method performs the following tasks:

  1) initial a CGI object
  2) read initial file if specified or search for a default file
     and save the file name to $ar->{ifn}. The default file is your 
     program name with .ini extension. For instance, if your CGI program
     name is 'myapp.pl', it will look for a file named 'myapp.ini'. 
  3) define message level. Default to level 1. 
  4) start HTML header and body using I<page_title> and I<page_style>
     if they are defined.
  5) parse CGI form inputs and combine them with parameters defined
     in initial file
  6) read configuration file ($prg.cfgi, for instance 'myapp.cfg') if it 
     exists and save the array to $ar->{cfg}
  7) prepare log record if writing log is enabled

It checks the parameters read from initial file for page_title, 
page_style, page_author, page_meta, top_nav, bottom_nav, and js_src. 

=cut

sub start_app {
    my $s = shift;
    my ($prg, $ar_arg, $nhh) = @_;

    # 0. check if it is in the web mode
    my $web_flag = (exists $ENV{HTTP_HOST}||exists $ENV{QUERY_STRING}) ? 1 : 0;
    my $ct_printed = 0; 
    if (defined($nhh) && $nhh =~ /^0$/ && $web_flag) { 
      my $ct = "Content-Type: text/html\n\n"; print $ct; $ct_printed = 1; 
    } 
    my $args = ($ar_arg && ref($ar_arg) =~ /ARRAY/)?(join " ", @$ar_arg):'';
    my $frt = $prg; $frt =~ s/\.\w+$//; 		# file name root
    my ($ifn,$cfg,$pod) = ("$frt.ini", "$frt.cfg", "$frt.pod"); 
    my $opt  = 'a:v:hS:';
    my ($q, $ar);

    # 1. check if it is in verbose mode or not
    if ($web_flag) {
        $q = CGI->new;
	my $v1 = $q->param('v');
	my $v2 = $q->Vars->{v}; 
	if ((defined($v1) && $v1) || (defined($v2) && $v2)) { 
            if (! $ct_printed && $nhh !~ /^1$/) { 
              print $q->header("text/html");  ++$ct_printed;
            }
	}
    }
    #
    # 2. Read initial file
    ($q,$ar) = $s->get_inputs($ifn,$opt);
    $ar->{ini_fn} = $ifn;
    $ar->{cfg_fn} = $cfg;
    $ar->{pod_fn} = $pod;
    my $ck_flag = $s->set_cookies($q, $ar);  # set $ar->{_cookie} 
    
    if ((exists $ar->{Verbose} && $ar->{Verbose} =~ /^Y/i) ||
       (exists $ar->{v} && $ar->{v}) ){
       print $q->header("text/html") if ! $ct_printed; 
    } 
    $s->echo_msg(" += Starting application...",2);
    $s->echo_msg(" ++ Reading initial file $ifn...",2)    if  -f $ifn;
    $s->echo_msg(" +  Initial file - $ifn: not found.",2) if !-f $ifn;
    # if user has defined messages in the initial file, we need to 
    # convert it into hash.
    $ar->{msg} = eval $ar->{msg} if exists $ar->{msg}; 

    # 3. start HTML header
    my %ar_hdr = $s->build_html_header($q, $ar); 
    $ar->{html_header} = \%ar_hdr   if ! exists $ar->{html_header}; 
    $ar->{svr_name} = `hostname` 
      if (!exists $ar->{svr_name} || !$ar->{svr_name}) && $^O !~ /^MSWin/i;
    chomp $ar->{svr_name} if exists $ar->{svr_name};

    # 4. start the HTML page
    my $pretty = $s->set_param('tab_pretty', $ar);
    if (!$nhh && (
        exists $ENV{HTTP_HOST} || exists $ENV{QUERY_STRING})) { 
        print $q->header("text/html") if ! $ct_printed; 
        ++$ct_printed; 
        print "\n"   if $pretty; 
	print $q->start_html(%ar_hdr);
        print "\n"   if $pretty; 
        print $ar->{top_nav} if exists $ar->{top_nav} && $ar->{top_nav};
        print "\n"   if $pretty; 
    }

    # 5. read configuration file
    if (-f $cfg) { 
        $s->echo_msg(" ++ Reading config file $cfg...",1);
        $ar->{cfg} = $s->read_cfg_file($cfg); 
    } else {
        $s->echo_msg("WARN: (start_app) could not find config file $cfg.", 3);
    }

    # 6. set log array
    my ($ds,$log_dir,$log_brf, $log_dtl) = ('/',"","","");
       $log_dir = (exists ${$ar}{log_dir})?${$ar}{log_dir}:'.';
    my $lgf = $ifn; $lgf =~ s/\.\w+//; $lgf =~ s/.*[\/\\](\w+)$/$1/;
    my $tmp = "";
       $tmp = $ar->{svr_name} if exists $ar->{svr_name} && $ar->{svr_name};
       $tmp .= '_' . (strftime "%Y%m%d", localtime time);
       $log_brf = join $ds, $log_dir, "${lgf}_brief.log";
       $log_dtl = join $ds, $log_dir, "${lgf}_${tmp}.log";
    my ($lfh_brf,$lfh_dtl,$txt,$ar_log) = ("","","","");
    if (exists ${$ar}{write_log} && ${$ar}{write_log}) {
        $ar_log = $s->start_log($log_dtl,$log_brf,"",$args,2);
        $s->{write_log} = $ar->{write_log}; 
    }

    # my $c2 = $s->get_cookies($q, $ar); 
    # $s->echo_msg($c2, 0);

    $s->echo_msg($ar,5);
    $s->echo_msg($ar_log,5);
    return ($q,$ar,$ar_log);
}

=head3 end_app ($q, $ar, $ar_log, $nhh)

Input variables:

  $q    - CGI object 
  $ar   - array ref for parameters 
  $ar_log - hash ref for log record
  $nhh  - no html header pre-printed 
          1 - no HTML is printed in any circumstance
          0 - HTML header will be printed when it is possible

Variables used or routines called:

  echo_msg - echo messages
  end_log - start and write message log
  set_param - get a parameter from hash array

How to use:

   my ($q, $ar, $ar_log) = $self->start_app($0,\@ARGV);
   $self->end_app($q, $ar, $ar_log);

Return: none 

This method performs the following tasks:

  1) ends HTML document 
  2) writes log records to log files 
  3) close database connection if it finds DB handler in {dbh}

=cut

sub end_app {
    my $s = shift;
    my ($q, $ar, $ar_log, $nhh) = @_;
    if (exists ${$ar}{write_log} && ${$ar}{write_log}) {
        $s->end_log($ar_log);
    }
    my $dbh = $s->set_param('dbh', $ar);
    my $pretty = $s->set_param('tab_pretty', $ar);
    $dbh->disconnect() if $dbh; 
    if (exists $ar->{bottom_nav} && $pretty) {
        $ar->{bottom_nav} =~ s/<br>/<br>\n/g;
    }
    if (exists $ENV{HTTP_HOST} || exists $ENV{QUERY_STRING}) { 
        print $ar->{bottom_nav} if exists $ar->{bottom_nav} && !$nhh; 
        print "\n"           if !$nhh && $pretty;
        print $q->end_html   if !$nhh;
    }
    # clear the stored parameters
    $_[0] = undef;
    $_[1] = undef;
    $_[2] = undef; 
    $_[3] = undef; 
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

The start_app and end_app were extracted out of CGI::AppBuilder class and formed
this sub class. 

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


