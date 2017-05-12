package Apache::AxKit::Provider::CGI;

use 5.008;
use strict;
use warnings;

require Exporter;

#our @ISA = qw(Exporter);
our @ISA = ('Apache::AxKit::Provider::File');

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.02';

use Apache;
use Apache::Log;
use Apache::AxKit::Exception;
use Apache::AxKit::Provider;
use Apache::AxKit::Provider::File;
use AxKit;
use Apache::Constants;
use File::Basename;
use XML::Simple;

# copied mostly from Filter provider...
sub get_fh {
    my $self = shift;
    throw Apache::AxKit::Exception::IO(-text => "Can't get fh for CGI filehandle");
}

sub get_strref {
    my $self = shift;
    require $self->{file};
    my ($response, $stylesheet) = content();
    delete $INC{$self->{file}};

    my $xml = ($stylesheet ? "<?xml-stylesheet href=\"$stylesheet\" type=\"text/xsl\" ?>\n" : '');
    $xml .= XML::Simple::XMLout($response, 'keyattr'=>[], 'rootname'=>'response', 'noattr'=>1);

    return \$xml;
}

sub process {
    my $self = shift;

    my $xmlfile = $self->{file};

    local $^W;
    # always process this resource.
    chdir(dirname($xmlfile));
    return 1;
}

sub exists {
    my $self = shift;
    return 1;
}

sub has_changed () { 1; }

sub mtime {
    my $self = shift;
    return time(); # always fresh
}

1;
__END__

=head1 NAME

Apache::AxKit::Provider::CGI - CGI generated XML content without Taglibs

=head1 SYNOPSIS

  Apache::AxKit::Provider::CGI is an AxKit Content Provider.
  If you have a working instance of AxKit, you can use
  Apache::AxKit::Provider::CGI by adding the following directive to
  your httpd.conf file:

    AxContentProvider Apache::AxKit::Provider::CGI


=head1 ABSTRACT

  AxKit has a very powerful Taglib architecture that allows you to
  separate you content from your presentation.

  This module provides an alternative to taglibs. The general philosphy
  here is to respond to http requests with perl CGI scripts. Such scripts
  perform two duties. First, they generate content. Second, they determine
  the stylesheet for presenting the content. The CGI scripts do not
  generate the stylesheets. They simply determine which stylesheet should
  be used for presentation.

  CGI scripts must contain a "content()" subroutine that returns a hashref 
  containing the generated content, and optionally, the name of a stylesheet.

  The hashref is converted to XML and wrapped in a <response> tag using
  XML::Simple. If the CGI script specifies a stylesheet, an appropriate
  processing instruction is prepended to the xml document.

  This xml document is then provided to AxKit for further processing.

=head1 DESCRIPTION

  The AxContentProvider directive can be couched in a <Location> or
  <Directory> directive like this:

    <Location /mydir>
        AllowOverride None
        Options ExecCGI
        SetHandler perl-script
        AxContentProvider Apache::AxKit::Provider::CGI
        PerlHandler AxKit
    </Location>

  Then you simpley provide perl scripts and corresponding xsl
  stylesheets.

  The perl scripts should supply a content() subroutine. That subroutine
  should return a hashref, and optionally, the name of an xsl stylesheet.

  For example, you could write test.cgi like this:

    use CGI::Utils;
                                                                                                                               
    sub content {
      my $q = new CGI::Utils;
      $q->parse;
                                                                                                                               
      my @weekdays = ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');
      my $response = {'weekdays'=> \@weekdays, 'dow'=>$q->param('DayOfWeek')};
      return $response, $q->param('stylesheet');
    }
                                                                                                                               
    1;

  From you browser, the request "test.cgi??DayOfWeek=Wed" will produce a document that looks like this:
    <response>
      <dow>Wed</dow>
      <weekdays>Sunday</weekdays>
      <weekdays>Monday</weekdays>
      <weekdays>Tuesday</weekdays>
      <weekdays>Wednesday</weekdays>
      <weekdays>Thursday</weekdays>
      <weekdays>Friday</weekdays>
      <weekdays>Saturday</weekdays>
    </response>

  The request "test.cgi??DayOfWeek=Wed&stylesheet=/xsl/test.xsl" will produce a document that looks
  like this:

    <?xml-stylesheet href="/xsl/test.xsl" type="text/xsl" ?>
    <response>
      <dow>Wed</dow>
      <weekdays>Sunday</weekdays>
      <weekdays>Monday</weekdays>
      <weekdays>Tuesday</weekdays>
      <weekdays>Wednesday</weekdays>
      <weekdays>Thursday</weekdays>
      <weekdays>Friday</weekdays>
      <weekdays>Saturday</weekdays>
    </response>


=head1 SEE ALSO

  AxKit
  Apache::AxKit::Provider
  AxKit Provider HOWTO: http://axkit.org/docs/provider-howto.dkb?section=2

=head1 AUTHOR

Sean McMurray

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Sean McMurray

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 VERSION

  0.02

=cut
