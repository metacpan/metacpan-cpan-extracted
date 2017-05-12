package CGI::AppBuilder::Header;

# Perl standard modules
use strict;
use warnings;
use Getopt::Std;
use POSIX qw(strftime);
use Carp;
use CGI::AppBuilder;
use CGI::AppBuilder::Message qw(:echo_msg);

our $VERSION = 1.001;
require Exporter;
our @ISA         = qw(Exporter CGI::AppBuilder);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(build_html_header 
                   );
our %EXPORT_TAGS = (
    all  => [@EXPORT_OK]
);

=head1 NAME

CGI::AppBuilder::Header - Configuration initializer 

=head1 SYNOPSIS

  use CGI::AppBuilder::Header;

  my $ab = CGI::AppBuilder::Header->new(
     'ifn', 'my_init.cfg', 'opt', 'vhS:a:');
  my ($q, $ar, $ar_log) = $ab->start_app($0, \%ARGV);
  print $ab->disp_form($q, $ar); 

=head1 DESCRIPTION

This class provides methods for reading and parsing configuration
files. 

=cut

=head2 new (ifn => 'file.cfg', opt => 'hvS:')

This is a inherited method from CGI::AppBuilder. See the same method
in CGI::AppBuilder for more details.

=cut

sub new {
  my ($s, %args) = @_;
  return $s->SUPER::new(%args);
}

=head3 build_html_header ($q, $ar)

Input variables:

  $q    - CGI object
  $ar   - array ref for parameters

Variables used or routines called:

  Debug::EchoMessage
    echo_msg - echo messages
    set_param - get a parameter from hash array

How to use:

  my $ifn = 'myConfig.ini';
  my ($q,$ar) = $s->get_inputs($ifn);
  my $hrf = $self->build_html_header($q, $ar);

Return: hash array or array ref

This method performs the following tasks:

  1) check the following parameters: page_title, page_style,
     page_meta, page_author, page_target, js_src, js_code
  2) writes log records to log files
  3) close database connection if it finds DB handler in {dbh}

=cut

sub build_html_header {
    my $s = shift;
    my ($q, $ar) = @_;

    # 4. start HTML header
    my $title = $s->set_param('page_title', $ar);
       $title = "Untitled Page"            if ! $title;
    my $style = $s->set_param('page_style', $ar);
       $style = '<!-- -->'                 if ! $style;
    my $author = $s->set_param('page_author', $ar);
       $author = 'Hanming.Tu@gmail.com' if ! $author;
    my $target = $s->set_param('page_target', $ar);
       # $target = '_blank'                  if ! $target;
    my $bdy   = $s->set_param('body_desc', $ar); 
       $ar->{body_attr} = ($bdy) ? eval $bdy : {}; 
    my $js_src  = $s->set_param('js_src', $ar);
    my $js_code = $s->set_param('js_code', $ar);
    my $yr = strftime "%Y", localtime time;
    my $meta_txt = $s->set_param('page_meta', $ar);
    my $mrf = {};
    if ($meta_txt) {
       $mrf = eval $meta_txt;
       $mrf->{'keywords'} = 'Perl Modules';
       $mrf->{'copyright'}= "copyright $yr Hanming Tu";
    } else {
       $mrf = {'keywords'=>'Perl Modules',
         'copyright'=>"copyright $yr Hanming Tu"};
    }
    my %ar_hdr = (-title=>$title, -author=>$author, -meta=>$mrf);
    $ar_hdr{-target}= $target    if $target;
    $ar_hdr{-style} = ($style =~ /^<!--/) ? $style : {'src'=>"$style"};
    $ar_hdr{-script} = [];
    if ($js_src) {
        if (index($js_src, ',') > 0) {
            my @js = map {
              {-language=>'JavaScript1.2', -src=>$_}
            } (split /,/, $js_src);
            $ar_hdr{-script} = \@js;
        } else {
            $ar_hdr{-script} = [{-language=>'JavaScript1.2', -src=>$js_src}];
        }
    } 
    if ($js_code) {
      push @{$ar_hdr{-script}}, ({-language=>'JavaScript1.2', -code=>$js_code}); 
    }
    $ar->{html_header} = \%ar_hdr;
    return wantarray ? %ar_hdr : \%ar_hdr;
}

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version extracts the disp_form method from CGI::Getopt class.

  0.11 Inherited the new constructor from CGI::AppBuilder.

=item * Version 0.20

=cut

=head1 SEE ALSO (some of docs that I check often)

Oracle::Loader, Oracle::Trigger, CGI::Getopt, File::Xcopy,
CGI::AppBuilder, CGI::AppBuilder::Message, CGI::AppBuilder::Log,
CGI::AppBuilder::Config, etc.

=head1 AUTHOR

Copyright (c) 2005 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

