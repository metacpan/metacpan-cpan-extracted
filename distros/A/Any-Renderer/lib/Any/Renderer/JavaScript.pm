package Any::Renderer::JavaScript;

# $Id: JavaScript.pm,v 1.8 2006/08/21 08:30:23 johna Exp $

use strict;
use vars qw($VERSION %Formats);
use Data::JavaScript;

$VERSION = sprintf"%d.%03d", q$Revision: 1.8 $ =~ /: (\d+)\.(\d+)/;
%Formats = map {$_ => 1} @{available_formats()};

sub new
{
  my ( $class, $format, $options ) = @_;
  die("The format '$format' isn't supported") unless($Formats{$format});

  my $self = {
    'options' => $options,
  };

  bless $self, $class;
  return $self;
}

sub render
{
  my ( $self, $data ) = @_;

  TRACE ( "Rendering w/Data::JavaScript" );
  DUMP ( $data );

  my $variable_name = $self->{ 'options' }->{ 'VariableName' } || 'script_output';
  return Data::JavaScript::jsdump ( $variable_name, $data ); 
}

sub requires_template
{
  return 0;
}

sub available_formats
{
  return [ 'JavaScript', 'Javascript' ];
}

sub TRACE {}
sub DUMP {}

1;

=head1 NAME

Any::Renderer::JavaScript - render as a JavaScript object

=head1 SYNOPSIS

  use Any::Renderer;

  my %options = ( 'VariableName' => 'myvariable' );
  my $format = "JavaScript";
  my $r = new Any::Renderer ( $format, \%options );

  my $data_structure = [...]; # arbitrary structure code
  my $string = $r->render ( $data_structure );

You can get a list of all formats that this module handles using the following syntax:

  my $list_ref = Any::Renderer::JavaScript::available_formats ();

Also, determine whether or not a format requires a template with requires_template:

  my $bool = Any::Renderer::JavaScript::requires_template ( $format );

=head1 DESCRIPTION

Any::Renderer::JavaScript renders any Perl data structure passed to it as a
sequence of JavaScript statements to create the corresponding data structure in JavaScript. For example:

  perl -MAny::Renderer -e "print Any::Renderer->new('JavaScript')->render({a => 1, b => [2,3]})"

results in:

  var script_output = new Object;script_output['a'] = 1;script_output['b'] = new Array;script_output['b'][0] = 2;script_output['b'][1] = 3;

=head1 FORMATS

=over 4

=item JavaScript (aka Javascript)

=back

=head1 METHODS

=over 4

=item $r = new Any::Renderer::JavaScript($format,\%options)

See L</FORMATS> for a description of valid values for C<$format>.
See L</OPTIONS> for a description of valid C<%options>.

=item $scalar = $r->render($data_structure)

The main method.

=item $bool = Any::Renderer::JavaScript::requires_template($format)

False in this case.

=item $list_ref = Any::Renderer::JavaScript::available_formats()

See L</FORMATS> for a list.

=back

=head1 OPTIONS

=over 4

=item VariableName

Name of the javascript variable that the new data structure is to be assigned to.  Defaults to C<script_output>.

=back

=head1 SEE ALSO

L<Data::JavaScript>, L<Any::Renderer>

=head1 VERSION

$Revision: 1.8 $ on $Date: 2006/08/21 08:30:23 $ by $Author: johna $

=head1 AUTHOR

Matt Wilson <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2006. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
