package Any::Renderer::JavaScript::Anon;

# $Id: Anon.pm,v 1.9 2006/08/21 08:30:24 johna Exp $

use strict;
use vars qw($VERSION %Formats);
use Data::JavaScript::Anon;

$VERSION = sprintf"%d.%03d", q$Revision: 1.9 $ =~ /: (\d+)\.(\d+)/;
%Formats = map {$_ => 1} @{available_formats()};

sub new
{
  my ( $class, $format, $options ) = @_;
  die("The format '$format' isn't supported") unless($Formats{$format});

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

  if ($self->{'format'} eq 'JSON') {
    TRACE ( "Rendering to JSON" );
    DUMP ( $data );

    return Data::JavaScript::Anon->anon_dump ( $data ); 
  } else {
    TRACE ( "Rendering to Data::JavaScript::Anon" );
    DUMP ( $data );

    my $variable_name = $self->{ 'options' }->{ 'VariableName' } || 'script_output';
    return Data::JavaScript::Anon->var_dump ( $variable_name, $data ); 
  }
}

sub requires_template
{
  return 0;
}

sub available_formats
{
  return [ "JavaScript::Anon", "Javascript::Anon", "JSON" ];
}

sub TRACE {}
sub DUMP {}

1;

=head1 NAME

Any::Renderer::JavaScript::Anon - renders anonymous JavaScript data structure

=head1 SYNOPSIS

  use Any::Renderer;

  my %options = ( 'VariableName' => 'myvariable' );
  my $format = "JavaScript::Anon";
  my $r = new Any::Renderer ( $format, \%options );

  my $data_structure = [...]; # arbitrary structure code
  my $string = $r->render ( $data_structure );

You can get a list of all formats that this module handles using the following syntax:

  my $list_ref = Any::Renderer::JavaScript::Anon::available_formats ();

Also, determine whether or not a format requires a template with requires_template:

  my $bool = Any::Renderer::JavaScript::Anon::requires_template ( $format );

=head1 DESCRIPTION

Any::Renderer::JavaScript::Anon renders any Perl data structure passed to it
as a JavaScript anonymous data structure.

=head1 FORMATS

=over 4

=item JavaScript::Anon (aka Javascript::Anon)

A more compact equivalent to the JavaScript format, using anonymous structures in the assignment.

  perl -MAny::Renderer -e "print Any::Renderer->new('Javascript::Anon')->render({a => 1, b => [2,3]})"

results in:

  var script_output = { a: 1, b: [ 2, 3 ] };

=item JSON

Use the format 'JSON' to return completely anonymous data structures - i.e. with no leading
"var script_output = " and no trailing ";"

  perl -MAny::Renderer -e "print Any::Renderer->new('JSON')->render({a => 1, b => [2,3]})"
  
results in:

  { a: 1, b: [ 2, 3 ] }

=back

=head1 METHODS

=over 4

=item $r = new Any::Renderer::JavaScript::Anon($format,\%options)

See L</FORMATS> for a description of valid values for C<$format>.
See L</OPTIONS> for a description of valid C<%options>.

=item $scalar = $r->render($data_structure)

The main method.

=item $bool = Any::Renderer::JavaScript::Anon::requires_template($format)

False in this case.

=item $list_ref = Any::Renderer::JavaScript::Anon::available_formats()

See L</FORMATS> for a list.

=back

=head1 OPTIONS

=over 4

=item VariableName

Name of the javascript variable that the new data structure is to be assigned to.  Defaults to C<script_output>.
Does not apply when using C<JSON> format.

=back

=head1 SEE ALSO

L<Data::JavaScript::Anon>, L<Any::Renderer>

=head1 VERSION

$Revision: 1.9 $ on $Date: 2006/08/21 08:30:24 $ by $Author: johna $

=head1 AUTHOR

Matt Wilson E<lt>matthew.wilson@bbc.co.ukE<gt>

=head1 COPYRIGHT

(c) BBC 2006. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
