package Any::Renderer::Data::Serializer;

# $Id: Serializer.pm,v 1.5 2006/09/04 12:15:54 johna Exp $

use strict;
use vars qw($VERSION %Formats);
use Data::Serializer;
use File::Find;

#If true data::serializer modules are loaded to check they compile
#Set to true value for safety at the cost of performance/memory (e.g. in a dev/test env)
use constant MUST_COMPILE => $ENV{ANY_RENDERER_DS_SAFE};

$VERSION = sprintf"%d.%03d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;

sub new
{
  my ( $class, $format, $options ) = @_;
  
  unless($Formats{$format}) {
    _scan_available_formats(); #Discover if it's appeared recently
    die("The format '$format' doesn't appear to be supported by Data::Serializer") unless($Formats{$format});
  }
  
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

  TRACE ( "Rendering w/Data::Serializer" );
  DUMP ("Input data structure", $data );

  my $ds = new Data::Serializer('serializer' => $self->{format}, 'options' => $self->{options}) or die($!);
  my $string = $ds->raw_serialize($data);
  TRACE("Rendered as: " . $string);
  return $string;
}

sub requires_template
{
  my ( $format ) = @_;
  return 0; #None do
}

sub available_formats
{
  _scan_available_formats();
  return [ sort keys %Formats ];
}


sub _scan_available_formats
{
  TRACE ( "Generating list of all possible formats" );

  my @possible_locations = grep { -d $_ } map { File::Spec->catdir ( $_, split ( /::/, 'Data::Serializer' ) ) } @INC;

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

    return if $file eq 'Cookbook'; #Skip non-backend modules in D::S namespace

    $found{ $file } = 1;
  };

  File::Find::find ( $collector, @possible_locations );
  
  #Only add those that compile
  if(MUST_COMPILE) {
    %Formats = ();
    foreach my $module (keys %found) {
      eval {
        _load_module($module);
        $Formats{$module} = 1;
      };
      warn($@) if($@);
    }
  } else {
    %Formats = %found;  
  }
  
  DUMP("Available formats", \%Formats);
}

sub _load_module {
  my $file = shift; 

  my $module = "Data::Serializer::" . $file;  
  TRACE ( "Loading Data::Serializer backend '" . $module . "'" );
  die ("Module name $module looks dodgy - will not load") unless($module =~ /^[\w:]+$/); #Protect against code injection
  eval "require " . $module;
  die ("Data::Serializer - problem loading backend module: ". $@ ) if ( $@ );
  
  return $module;
}

sub TRACE {}
sub DUMP {}

1;

=head1 NAME

Any::Renderer::Data::Serializer - adaptor for Any::Renderer to use any Data::Serializer backends

=head1 SYNOPSIS

  use Any::Renderer;

  my %options = ();
  my $format = "YAML"; #One of the formats provided by Data::Serializer
  my $r = new Any::Renderer ( $format, \%options );

  my $data_structure = [...]; # arbitrary structure code
  my $string = $r->render ( $data_structure );

=head1 DESCRIPTION

Any::Renderer::Data::Serializer renders any Perl data structure passed to it into
a string representation using modules exposing the Data::Serializer API.

=head1 FORMATS

All the formats supported by Data::Serializer.  Try this to find out what's available on your system:

  perl -MAny::Renderer::Data::Serializer -e "print join(qq{\n}, sort @{Any::Renderer::Data::Serializer::available_formats()})"

=head1 METHODS

=over 4

=item $r = new Any::Renderer::Data::Serializer($format, \%options)

See L</FORMATS> for a description of valid values for C<$format>.
C<%options> are passed through to the backend module (e.g. to XML::Dumper)

=item $string = $r->render($data_structure)

The main method.

=item $bool = Any::Renderer::Data::Serializer::requires_template($format)

This will be false for these formats.

=item $list_ref = Any::Renderer::Data::Serializer::available_formats()

This will discover the formats supported by your Data::Serializer installation.

=back

=head1 ENVIRONMENT

Set the C<ANY_RENDERER_DS_SAFE> environment variable to a true value if you want to check each Data::Serializer 
backend compiles before adding it to the list of available formats.
This is safer in that modules with missing dependencies are not advertised as available but it incurs a
CPU and memory overhead.

=head1 SEE ALSO

L<Data::Serializer>, L<Any::Renderer>

=head1 VERSION

$Revision: 1.5 $ on $Date: 2006/09/04 12:15:54 $ by $Author: johna $

=head1 AUTHOR

John Alden <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2006. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
