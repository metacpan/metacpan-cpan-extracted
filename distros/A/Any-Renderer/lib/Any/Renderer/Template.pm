package Any::Renderer::Template;

# $Id: Template.pm,v 1.21 2006/09/04 12:15:53 johna Exp $

use vars qw($VERSION %Formats $Cache $CacheMaxItems $CacheMaxAtime $CachePurgeInterval $CacheLastPurged);

use Any::Template;
use Cache::AgainstFile;
use strict;

use constant MUST_COMPILE => $ENV{ANY_RENDERER_AT_SAFE};

$VERSION = sprintf"%d.%03d", q$Revision: 1.21 $ =~ /: (\d+)\.(\d+)/;

#Package-level cache and settings
$Cache = undef; #Generated on first use
$CacheMaxItems = 1000;
$CacheMaxAtime = 6 * 60 * 60; # seconds (6 hours)
$CachePurgeInterval = 60 * 60 ; # seconds (1 hour)
$CacheLastPurged = undef;

sub new
{
  my ( $class, $format, $options ) = @_;
  die("You must specify a format in the Any::Renderer::Template constructor") unless(defined $format && length $format);

  unless($Formats{$format}) {
    _scan_available_formats(); #Discover if it's appeared recently
    die("The format '$format' doesn't appear to be supported by Any::Template") unless($Formats{$format});
  }

  #Separate options for this module from options passed through to backend
  $options ||= {};
  my $backend_options = $options->{TemplateOptions} || {
    map {$_ => $options->{$_}} 
    grep {$_ !~ /^(Template|TemplateFilename|TemplateString|NoCache)$/} 
    keys %$options
  };

  $Cache ||= _init_cache ();

  my $self = {
    'format'  => $format,
    'template_file' => $options->{'Template'} || $options->{'TemplateFilename'},
    'template_string' => $options->{'TemplateString'},
    'options' => $backend_options,
    'cache' => $options->{'NoCache'}? undef: $Cache,
  };

  die("You must specify either a template filename or string containing a template") unless($self->{template_file} || defined $self->{template_string});

  bless $self, $class;  
  return $self;
}

# load the template via Any::Template or Cache::AgainstFile
sub render
{
  my ( $self, $data ) = @_;

  my $template;
  my $template_file = $self->{template_file};
  my $template_string = $self->{template_string};
  if ( $template_file )
  {
    if( $self->{cache} )
    {
      TRACE ( "Loading template '" . $template_file . "' via Cache" );
      $template = $self->{cache}->get($template_file, $self->{ 'format' }, $self->{ 'options' });
      _purge_cache($self->{cache}) if(time - $CacheLastPurged > $CachePurgeInterval);
    }
    else
    {
      TRACE ( "No cache found, loading template via _template_from_file" );
      $template = _template_from_file ( $template_file, $self->{'format'}, $self->{'options'}  );
    }
  }
  elsif ( $template_string )
  {
    TRACE ( "Using in-memory template and new Any::Template" );
    $template = _template_from_string($template_string, $self->{'format'}, $self->{'options'});
  }
  else
  {
    die ( "No template provided!" );
  }

  return $template->process ( $data );
}

# returns whether or not this format requires a template
sub requires_template
{
  return 1; #True in all cases
}

# return a list reference of the formats that we handle
sub available_formats
{
  _scan_available_formats();
  return [ sort keys %Formats ];  
}

#
# Private routines
#

# a sub-routine for loading of templates
sub _template_from_file
{
  my ( $filename, $format, $options ) = @_;

  TRACE ( "_template_from_file : loading '$filename' as '$format'" );
  DUMP ( "options", $options );

  my %ops = (
    'Options'   => $options,
    'Filename'  => $filename,
  );
  $ops{'Backend'} = $format unless($format eq 'Any::Template');

  return new Any::Template ( \%ops );
}

sub _template_from_string
{
  my($string, $format, $options) = @_;	
  my %ops = (
    'Options'   => $options,
    'String'    => $string,
  );
  $ops{'Backend'} = $format unless($format eq 'Any::Template');

  return new Any::Template ( \%ops );
}

sub _scan_available_formats
{
  my $formats = Any::Template::available_backends();
  if (MUST_COMPILE) {
    @$formats = grep {
       eval {new Any::Template({Backend => $_, String => ""})} , !$@
    } @$formats;
  }
  %Formats = map {$_ => 1} (@$formats, 'Any::Template');
}

#
# Cache management
#

sub _init_cache
{
  $CacheLastPurged = time();
  return new Cache::AgainstFile ( \&_template_from_file, {
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


sub TRACE {}
sub DUMP {}

1;

=head1 NAME

Any::Renderer::Template - render data structure using a template

=head1 SYNOPSIS

  use Any::Renderer;

  my %options = ( 'Template'  => 'path/to/template.tmpl' );

  my $format = "HTML::Template";
  my $r = new Any::Renderer ( $format, \%options );

  my $data_structure = [...]; # arbitrary structure code
  my $string = $r->render ( $data_structure );

You can get a list of all formats that this module handles using the following syntax:

  my $list_ref = Any::Renderer::Template::available_formats ();

Also, determine whether or not a format requires a template with requires_template:

  my $bool = Any::Renderer::Template::requires_template ( $format );

=head1 DESCRIPTION

Any::Renderer::Template renders any Perl data structure passed to it with
Any::Template. The Any::Template backend used depends on the 'format' parameter passed to
the object constructor.

Templates expressed as filenames are cached using a package-level in-memory cache with Cache::AgainstFile.  
This will stat the file to validate the cache before using the cached object, so if the template is updated,
this will be immediately picked up by all processes holding a cached copy.

=head1 FORMATS

All the formats supported by Any::Template.  Try this to find out what's available on your system:

  perl -MAny::Renderer::Template -e "print join(qq{\n}, sort @{Any::Renderer::Template::available_formats()})"

An B<Any::Template> format is also provided.  This uses the default backend (as specified in the ANY_TEMPLATE_DEFAULT environment variable).

=head1 METHODS

=over 4

=item $r = new Any::Renderer::Template($format,\%options)

See L</FORMATS> for a description of valid values for C<$format>.
See L</OPTIONS> for a description of valid C<%options>.

=item $scalar = $r->render($data_structure)

The main method.

=item $bool = Any::Renderer::Template::requires_template($format)

This will be true for these formats.

=item $list_ref = Any::Renderer::Template::available_formats()

This will discover the formats supported by your Any::Template installation.

=back

=head1 OPTIONS

=over 4

=item Template (aka TemplateFilename)

Name of file containing template.  Mandatory unless TemplateString is defined.

=item TemplateString

String containing template.  Mandatory unless Template or TemplateFilename is defined.

=item NoCache

Suppress in-memory caching of templates loaded from the filesystem.

=item TemplateOptions

A hashref of options for the backend templating engine.  

If C<TemplateOptions> is not explicitly specified, 
all options passed to this module that are not recognised will be passed through
Any::Template (via the C<Options> constructor option) to the backend templating engine for the rendering process.
This flatter options structure may be more convenient but does introduce the risk of a nameclash between an option name in an obscure back-end templating module 
and an option specific to Any::Render::Template - it's your choice.

Further information on the options for each backend module can be found in the documentation for Any::Template::$backend 
or the documentation for the backend templating module itself.

=back

=head1 GLOBAL VARIABLES

The package-level template cache is created on demand the first time it's needed.
There are a few global variables which you can tune before it's created (i.e. before you create any objects):

=over 4

=item $Any::Renderer::Template::CacheMaxItems

Maximum number of template objects held in the cache.  Default is 1000.

=item $Any::Renderer::Template::CacheMaxAtime

Items older than this will be purged from the cache when the next purge() call happens.  In Seconds.  Default is 6 hours.

=item $Any::Renderer::Template::CachePurgeInterval

How often to purge the cache.  In Seconds.  Default is 1 hour.

=back

=head1 ENVIRONMENT

Set the C<ANY_RENDERER_AT_SAFE> environment variable to a true value if you want to check each Any::Template 
backend compiles before adding it to the list of available formats.
This is safer in that modules with missing dependencies are not advertised as available but it incurs a
CPU and memory overhead.

=head1 SEE ALSO

L<Any::Template>, L<Any::Renderer>, L<Cache::AgainstFile>

=head1 VERSION

$Revision: 1.21 $ on $Date: 2006/09/04 12:15:53 $ by $Author: johna $

=head1 AUTHOR

Matt Wilson and John Alden <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2006. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
