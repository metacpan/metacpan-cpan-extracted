# Purpose : Provide a common interface to a variety of rendering formats
# Author  : Matt Wilson - Original version by John Alden
# Created : March 2006
# CVS     : $Header: /home/cvs/software/cvsroot/any_renderer/lib/Any/Renderer.pm,v 1.14 2006/09/04 12:15:52 johna Exp $

package Any::Renderer;

use strict;
use File::Find;
use File::Spec;

use vars qw($VERSION %Formats @LowPriProviders);
$VERSION = sprintf"%d.%03d", q$Revision: 1.14 $ =~ /: (\d+)\.(\d+)/;

#Modules that provide an extensible set of formats that could clash with A::R native providers
@LowPriProviders = qw(Data::Serializer);

sub new
{
	my ( $class, $format, $options ) = @_;
	die("You must specify a format in the Any::Renderer constructor") unless(defined $format && length $format);
	$options = {} unless defined $options;

	#Update the list of formats if the format isn't found to discover any new modules
	unless($Formats{ $format }) {
		my $formats = available_formats();
		die ( "Unrecognised format - " . $format. ".  Known formats are:" . join(" ", @$formats) ) unless $Formats{ $format };
	}

	TRACE ( "Any::Renderer::new w/format '$format'" );
	DUMP ( "options", $options );

	my $self = {
		'format'  => $format,
		'options' => $options,
	};
	
	bless $self, $class;

	return $self;
}

sub render
{
	my ( $self, $data ) = @_;

	my $format = $self->{ 'format' }; 
	TRACE ( "Rendering to '" . $format . "'" );
	DUMP ( "Rendering data", $data );
	 
	# determine which module we need
	my $module = _load_module($Formats { $format });    
	my $renderer = $module->new ( $format, $self->{ 'options' } );

	return $renderer->render ( $data );
}

sub requires_template
{
	# allow use as either method or function
	my $format = pop;
	my $req_template = 0;

	# Reload the list of formats if we don't already know about it
	Any::Renderer::available_formats() unless ($Formats { $format });
	die( "Unable to find any providers for '$format'" ) unless ( $Formats { $format } );
	
	my $module = _load_module($Formats { $format });       
	my $func = $module->can ( "requires_template" )
		or die ( "${module}::requires_template method could not be found." );    
	$req_template = &$func ( $format );

	TRACE ( "Does '$format' require a template? $req_template" );

	return $req_template;
}

# butchered from Any::Template
sub available_formats
{
	TRACE ( "Generating list of all possible formats" );

	my @possible_locations = grep { -d $_ } map { File::Spec->catdir ( $_, split ( /::/, __PACKAGE__ ) ) } @INC;

	my %found;
	my $collector = sub
	{
		return unless $_ =~ /\.pm$/;

		my $file = $File::Find::name;
		$file =~ s/\Q$File::Find::topdir\E//;
		$file =~ s/\.pm$//;

		my @dirs = File::Spec->splitdir ( $file );
		shift @dirs;
		$file = join ( "::", @dirs );

		$found{ $file }=1;
	};

	File::Find::find ( $collector, @possible_locations );

	#Ensure that modules adapting other multi-format modules have lower precedence 
	#than native Any::Renderer backends in the event of both offering the same format
	my @backends = ();
	foreach (@LowPriProviders) {
		push @backends, $_ if delete $found{$_}; #ensure these are at the front of the list
	}
	push @backends, keys %found; #Higher precendence modules go later in the list

	%Formats = (); #Clear and rebuild
	foreach my $file ( @backends )
	{
		# load the module and discover which formats it presents us with,
		# including whether the formats need a template
		TRACE ( "Testing $file" );
		
		my ($module, $func);
		eval {
			$module = _load_module($file);     
			$func = $module->can( "available_formats" );
		};
		warn($@) if($@); #Warn if there are compilation problems with backend modules
		
		next unless $func;
		
		my $formats_offered = &$func;

		DUMP ( "${module}::available_formats", $formats_offered );

		foreach ( @$formats_offered )
		{
			$Formats { $_ } = $file;
		}
	}

	return [ sort keys %Formats ];
}

#Loads an Any::Renderer backend (safely)
sub _load_module {
	my $file = shift; 
	die ("Backend module name $file looks dodgy - will not load") unless($file =~ /^[\w:]+$/); #Protect against code injection

	my $module = "Any::Renderer::" . $file;  
	unless($INC{"Any/Renderer/$file.pm"}) {
		TRACE ( "Loading renderer backend '" . $module . "'" );
		eval "require " . $module;
		die ("Any::Renderer - problem loading backend module: ". $@ ) if ( $@ );
	}
	return $module;
}

sub TRACE {}
sub DUMP {}

1;

=head1 NAME

Any::Renderer - Common API for modules that convert data structures into strings

=head1 SYNOPSIS

	$renderer = new Any::Renderer ( $format, \%options );
	$string = $renderer->render ( $structure );
	$bool = Any::Renderer::requires_template ( $format );
	$list_ref = Any::Renderer::available_formats ();

=head1 DESCRIPTION

A renderer in this context is something that turns a data structure into a
string.  This includes templating engines, serialisers etc.

This module provides a consistent API to these services so that your
application can generate output in an extensible variety of formats.
Formats currently supported include:

	- XML (via XML::Simple)
	- XML+XSLT
	- Data::Dumper
	- Javascript, Javascript::Anon & JSON
	- UrlEncoded
	- The formats supported by Data::Serializer (e.g. Config::General and Config::Wrest)
	- Any templating language supported by Any::Template

The module will discover any backend modules and offer up their formats.
Once loaded, Any::Renderer will look for a module to handle any new formats it doesn't know about, so adding new formats in a persistent environment won't require the module to be reloaded.
However if you CHANGE which module provides a format you will need to reload Any::Renderer (e.g. send a SIGHUP to modperl).

=head1 METHODS

=over 4

=item $r = new Any::Renderer($format,\%options)

Create a new instance of an Any::Render object using a rendering format of
$format and the options listed in the hash %options (see individual rendering
module documentation for details of which options various modules accept).

=item $string = $r->render($data_structure)

Render the data structure $data_structure with the Any::Renderer object $r.
The resulting string will be returned.

=item $bool = Any::Renderer::requires_template($format)

Determine whether or not the rendering format $format requires a template to
be passed as an option to the object constructor. If the format does require a
template than 1 will be returned, otherwise 0.

=item $list_ref = Any::Renderer::available_formats()

Discover a list of all known rendering formats that the backend modules
provide, e.g. ( 'HTML::Template', 'JavaScript' [, ...]).

=back

=head1 GLOBAL VARIABLES

=over 4

=item @Any::Renderer::LowPriProviders

A list of backend providers which have lower precedence (if there is more than one module which provides a given format).
The earlier things appear in this list, the lower the precedence.

Defaults to C<Data::Serializer> as this provides both XML::Simple and Data::Dumper (which have native Any::Renderer backends).

=back

=head1 WRITING A CUSTOM BACKEND

Back-end modules should have the same public interface as Any::Renderer itself:

=over 4

=item $o = new Any::Renderer::MyBackend($format, \%options);

=item $string = $o->render($data_structure);

=item $bool = requires_template($format)

=item $arrayref = available_formats()

=back

For example:

	package Any::Renderer::MyFormat;
	sub new {
	  my ( $class, $format, $options ) = @_;
	  die("Invalid format $format") unless($format eq 'MyFormat');
	  return bless({}, $class); #More complex classes might stash away options and format 
	}
	
	sub render {
	  my ( $self, $data ) = @_;
	  return _my_format($data);
	}
	
	sub requires_template {
	  die("Invalid format") unless($_[0] eq 'MyFormat');
	  return 0; #No template required
	}
	
	sub handle_formats {
	  return [ 'MyFormat' ]; #Just the one
	}

=head1 SEE ALSO

=over 4

=item All the modules in the Any::Renderer:: distribution

L<http://search.cpan.org/dist/Any-Renderer>.
Each module lists the formats it supports in the FORMATS section.
Many of also include sample output fragments.

=item L<Any::Template>

A templating engine is a special case of a renderer (one that uses a template, usually from a file or string, to control formatting).
If you are considering exposing another templating language via Any::Renderer, instead consider exposing it via Any::Template.
All the templating engines supported by Any::Template are automatically available via Any::Renderer.

=item L<Data::Serializer>

A serializer is a special case of a renderer which offers bidirectional processing (rendering == serialization, deserialisation does not map to the renderer interface).
If you are considering exposing another serialization mechanism via Any::Renderer, instead consider exposing it via Data::Serializer.
All the serializers supported by Data::Serializer are automatically available via Any::Renderer.

=back
	
=head1 VERSION

$Revision: 1.14 $ on $Date: 2006/09/04 12:15:52 $ by $Author: johna $

=head1 AUTHOR

Matt Wilson (original version by John Alden) <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2006. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
