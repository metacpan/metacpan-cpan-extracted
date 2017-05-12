package Any::Renderer::XML;

# $Id: XML.pm,v 1.8 2006/08/22 20:14:09 johna Exp $

use strict;
use vars qw($VERSION);
use XML::Simple;

$VERSION = sprintf"%d.%03d", q$Revision: 1.8 $ =~ /: (\d+)\.(\d+)/;

use constant FORMAT_NAME => "XML";

sub new
{
  my ( $class, $format, $options ) = @_;
  die("Invalid format $format") unless($format eq FORMAT_NAME);

  my $self = {
    'options' => $options,
  };

  bless $self, $class;
  return $self;
}

sub render
{
  my ( $self, $data ) = @_;

  TRACE ( "Rendering XML data" );
  DUMP ( $data );

  my $charset = $self->{options}{Encoding} || 'ISO-8859-1';
  my %xmlopts = (
    'noattr'      => 1,
    'keyattr'     => undef,
    'keeproot'    => 1,
    'rootname'    => 'output',
    'xmldecl'     => qq{<?xml version="1.0" encoding="$charset" standalone="yes"?>},
    'contentkey'  => undef,
    'noescape'    => 0,
  );

  while ( my ( $k, $v ) = each %{ $self->{ 'options' }->{ 'XmlOptions' } } )
  {
    # smash case to ensure the options override defaults
    $xmlopts { lc $k } = $v;
  }

  if (my $varname = $self->{ 'options' }{ 'VariableName' }) {
    # VariableName overrides the 'options' hash
    $xmlopts { 'rootname' } =  $varname;
  }

  my $out = '';

  {
    # XML::Simple 1.23 produces use-of-uninitialized... warnings
    local $^W = 0;
    $out = XML::Simple::XMLout ( $data, %xmlopts );
  }

  return $out;
}

sub requires_template
{
  my ( $format ) = @_;

  return 0;
}

sub available_formats
{
  return [ FORMAT_NAME ];
}

sub TRACE {}
sub DUMP {}

1;

=head1 NAME

Any::Renderer::XML - render a data structure as element-only XML

=head1 SYNOPSIS

  use Any::Renderer;

  my %xml_options = ();
  my %options = ( 'XmlOptions' => \%xml_options );
  my $format = "XML";
  my $r = new Any::Renderer ( $format, \%options );

  my $data_structure = [...]; # arbitrary structure code
  my $string = $r->render ( $data_structure );

You can get a list of all formats that this module handles using the following syntax:

  my $list_ref = Any::Renderer::XML::available_formats ();

Also, determine whether or not a format requires a template with requires_template:

  my $bool = Any::Renderer::XML::requires_template ( $format );

=head1 DESCRIPTION

Any::Renderer::XML renders any Perl data structure passed to it as element-only XML.  For example:

  perl -MAny::Renderer -e "print Any::Renderer->new('XML')->render({a => 1, b => [2,3]})"

results in:

  <?xml version="1.0" encoding="ISO-8859-1" standalone="yes"?>
  <output>
    <a>1</a>
    <b>2</b>
    <b>3</b>
  </output>

The rendering process comes with all the caveats cited in the XML::Simple documentation.  For example if your data structure contains binary data or ASCII control characters, then the XML document that is generated may not be well-formed.

=head1 FORMATS

=over 4

=item XML

=back

=head1 METHODS

=over 4

=item $r = new Any::Renderer::XML($format,\%options)

C<$format> must be C<XML>.
See L</OPTIONS> for a description of available options.

=item $scalar = $r->render($data_structure)

The main method.

=item $bool = Any::Renderer::XML::requires_template($format)

False in this case.

=item $list_ref = Any::Renderer::XML::available_formats()

Just the one - C<XML>.

=back

=head1 OPTIONS

=over 4

=item XmlOptions

A hash reference of options that can be passed to XML::Simple::XMLout, see
L<XML::Simple> for a detailed description of all of the available
options.

=item VariableName

Set the XML root element name. You can also achieve this by setting the
C<RootName> or C<rootname> options passed to XML::Simple in the C<XML> options
hash. This is a shortcut to make this renderer behave like some of the other
renderer backends.

=item Encoding

Character set of the generated XML document.  Defaults to ISO-8859-1.

=back

=head1 SEE ALSO

L<XML::Simple>, L<Any::Renderer>

=head1 VERSION

$Revision: 1.8 $ on $Date: 2006/08/22 20:14:09 $ by $Author: johna $

=head1 AUTHOR

Matt Wilson <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2006. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
