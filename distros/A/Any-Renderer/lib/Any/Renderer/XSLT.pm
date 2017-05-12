package Any::Renderer::XSLT;

# $Id: XSLT.pm,v 1.14 2006/09/04 12:15:53 johna Exp $

use strict;
use Cache::AgainstFile;
use XML::LibXSLT;
use XML::LibXML;
use Any::Renderer::XML;

# a global XML parser and cache 
use vars qw($VERSION $XMLParser $Cache $CacheMaxItems $CacheMaxAtime $CachePurgeInterval $CacheLastPurged);

#Package-level cache and settings
$Cache = undef; #Generated on first use
$CacheMaxItems = 1000;
$CacheMaxAtime = 6 * 60 * 60; # seconds (6 hours)
$CachePurgeInterval = 60 * 60 ; # seconds (1 hour)
$CacheLastPurged = undef;

$VERSION = sprintf"%d.%03d", q$Revision: 1.14 $ =~ /: (\d+)\.(\d+)/;

use constant FORMAT_NAME => "XSLT";

sub new
{
  my ( $class, $format, $options ) = @_;
  die("Invalid format $format") unless($format eq FORMAT_NAME);

  $Cache ||= _init_cache ();

  my $self = {
    'template_file' => $options->{'Template'} || $options->{'TemplateFilename'},
    'template_string' => $options->{'TemplateString'},
    'options' => $options || {},
    'xml_renderer' => new Any::Renderer::XML('XML',$options),
    'cache' => $options->{'NoCache'}? undef: $Cache,
  };

  die("You must specify either a template filename or string containing a template") unless($self->{template_file} || defined $self->{template_string});
  bless $self, $class;

  return $self;
}

sub render
{
  my ( $self, $data ) = @_;

  TRACE ( "Rendering XSLT" );
  DUMP ( $data );

  my $stylesheet = '';
  my $template_file = $self->{template_file};
  my $template_string = $self->{template_string};
  if ( $template_file )
  {
    if( $self->{cache} )
    {
      TRACE ( "Fetching XSLT from cache" );
      $stylesheet = $self->{cache}->get( $template_file );
      _purge_cache($self->{cache}) if(time - $CacheLastPurged > $CachePurgeInterval);      
    }
    else
    {
      TRACE ( "Compiling XSLT from filesystem" );    
      $stylesheet = _xslt_from_file ( $template_file );
    }
  }
  elsif ( $template_string )
  {
    TRACE ( "Compiling XSLT from string" );
    $stylesheet = _xslt_from_string($template_string);
  }
  else
  {
    die ( "No template provided!" );
  }

  my $xml = $self->{xml_renderer}->render($data);
  my $transformed = $stylesheet->transform($XMLParser->parse_string ( $xml ) );
  return $stylesheet->output_string ( $transformed );
}

sub requires_template
{
  return 1;
}

sub available_formats
{
  return [ FORMAT_NAME ];
}

#
# Cache management
#

sub _init_cache
{
  $CacheLastPurged = time();
  return new Cache::AgainstFile ( \&_xslt_from_file, {
    'Method'    => 'Memory',
    'Grace'     => 0, # seconds
    'MaxATime'  => $CacheMaxAtime,
    'MaxItems'  => $CacheMaxItems,
  } );
}

sub _purge_cache
{
  my $cache = shift;
  return unless defined $cache;
  $cache->purge();
  $CacheLastPurged = time();
}

sub _xslt_from_file
{
  my ( $filename ) = @_;
  TRACE ( "Any::Renderer::XSLT::_xslt_from_file - reading XSLT from disk '$filename'" );

  $XMLParser ||= new XML::LibXML ();

  my $xslt = new XML::LibXSLT ();
  my $stylesheet = $xslt->parse_stylesheet($XMLParser->parse_file ( $filename ));
  return $stylesheet;
}

sub _xslt_from_string
{
  my ( $string ) = @_;
  TRACE ( "Any::Renderer::XSLT::_xslt_from_string" );

  $XMLParser ||= new XML::LibXML ();

  my $xslt = new XML::LibXSLT ();
  my $stylesheet = $xslt->parse_stylesheet($XMLParser->parse_string( $string ));
  return $stylesheet;
}

sub TRACE {}
sub DUMP {}

1;

=head1 NAME

Any::Renderer::XSLT - render by XLST of XML element representation of data structure

=head1 SYNOPSIS

  use Any::Renderer;

  my %xml_options = ();
  my %options = (
    'XmlOptions' => \%xml_options,
    'Template'   => 'path/to/template.xslt',
  );
  my $format = "XSLT";
  my $r = new Any::Renderer ( $format, \%options );

  my $data_structure = [...]; # arbitrary structure code
  my $string = $r->render ( $data_structure );

You can get a list of all formats that this module handles using the following syntax:

  my $list_ref = Any::Renderer::XSLT::available_formats ();

Also, determine whether or not a format requires a template with requires_template:

  my $bool = Any::Renderer::XSLT::requires_template ( $format );

=head1 DESCRIPTION

Any::Renderer::XSLT renders a Perl data structure as an interstitial XML
representation (via Any::Renderer::XML) and then proceeds to apply a XSLT transformation to it to generate
the final output.

XSL Templates expressed as filenames are cached using a package-level in-memory cache with Cache::AgainstFile.  
This will stat the file to validate the cache before using the cached object, so if the template is updated,
this will be immediately picked up by all processes holding a cached copy.

=head1 FORMATS

=over 4

=item XSLT

=back

=head1 METHODS

=over 4

=item $r = new Any::Renderer::XSLT($format,\%options)

C<$format> must be C<XSLT>.
See L</OPTIONS> for a description of valid C<%options>.

=item $scalar = $r->render($data_structure)

The main method.

=item $bool = Any::Renderer::XSLT::requires_template($format)

True in this case.

=item $list_ref = Any::Renderer::XSLT::available_formats()

Just the one - C<XSLT>.

=back

=head1 OPTIONS

=over 4

=item XmlOptions

A hash reference to options passed to XML::Simple::XMLout to control the generation of the interstitial XML.
See L<XML::Simple> for a detailed description of all of the available options.

=item VariableName

Set the XML root element name in the interstitial XML. You can also achieve this by setting the
C<RootName> or C<rootname> options passed to XML::Simple in the C<XML> options
hash. This is a shortcut to make this renderer behave like some of the other
renderer backends.

=item Template (aka TemplateFilename)

Filename of XSL template.  Mandatory unless TemplateString is defined.

=item TemplateString

String containing XSL template.  Mandatory unless Template or TemplateFilename is defined.

=item NoCache

Disable in-memory caching of XSLTs loaded from the filesystem.

=back 

=head1 GLOBAL VARIABLES

The package-level template cache is created on demand the first time it's needed.
There are a few global variables which you can tune before it's created (i.e. before you create any objects):

=over 4

=item $Any::Renderer::XSLT::CacheMaxItems

Maximum number of template objects held in the cache.  Default is 1000.

=item $Any::Renderer::XSLT::CacheMaxAtime

Items older than this will be purged from the cache when the next purge() call happens.  In Seconds.  Default is 6 hours.

=item $Any::Renderer::XSLT::CachePurgeInterval

How often to purge the cache.  In Seconds.  Default is 1 hour.

=back

=head1 SEE ALSO

L<Any::Renderer::XML>, L<Any::Renderer>, L<Cache::AgainstFile>

=head1 VERSION

$Revision: 1.14 $ on $Date: 2006/09/04 12:15:53 $ by $Author: johna $

=head1 AUTHOR

Matt Wilson and John Alden <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2006. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
