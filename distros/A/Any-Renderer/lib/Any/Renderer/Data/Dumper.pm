package Any::Renderer::Data::Dumper;

# $Id: Dumper.pm,v 1.9 2006/08/23 19:41:16 johna Exp $

use strict;
use vars qw($VERSION);
use Data::Dumper;

$VERSION = sprintf"%d.%03d", q$Revision: 1.9 $ =~ /: (\d+)\.(\d+)/;

use constant FORMAT_NAME => 'Data::Dumper';

sub new
{
  my ( $class, $format, $options ) = @_;
  die("Invalid format $format") unless($format eq FORMAT_NAME);
  
  $options ||= {};
  my $self = {
    'options' => $options,
    'varname' => delete $options->{VariableName},
  };

  $options->{DumperOptions} ||= {};
  foreach my $opt(keys %{$options->{DumperOptions}}) {
    die("Data::Dumper does not support a $opt method") unless(Data::Dumper->can($opt));
  }

  bless $self, $class;

  return $self;
}

sub render
{
  my ( $self, $data ) = @_;

  TRACE ( "Rendering w/Data::Dumper" );
  DUMP ( $data );

  my $o = Data::Dumper->new([ $data ], [ $self->{ 'varname' } ]);
  $o->Sortkeys(1);
  foreach my $opt(keys %{$self->{options}{DumperOptions}}) {
    $o->$opt($self->{options}{DumperOptions}{$opt}); #Fire corresponding methods
  }
  return $o->Dump();
}

sub requires_template
{
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

Any::Renderer::Data::Dumper - render data structures through Data::Dumper

=head1 SYNOPSIS

  use Any::Renderer;

  my %options = ('DumperOptions' => {'Indent' => 1});
  my $format = "Data::Dumper";
  my $r = new Any::Renderer ( $format, \%options );

  my $data_structure = [...]; # arbitrary structure
  my $string = $r->render ( $data_structure );

=head1 DESCRIPTION

Any::Renderer::Data::Dumper renders any Perl data structure passed to it into
a string representation via Data::Dumper.  For example:

  perl -MAny::Renderer -e "print Any::Renderer->new('Data::Dumper')->render({a => 1, b => [2,3]})"

results in:

  $VAR1 = {
            'a' => 1,
            'b' => [
                     2,
                     3
                   ]
          };

=head1 FORMATS

=over 4

=item Data::Dumper

=back

=head1 METHODS

=over 4

=item $r = new Any::Renderer::Data::Dumper($format, \%options)

C<$format> must be C<Data::Dumper>.
See L</OPTIONS> for a description of valid C<%options>.

=item $string = $r->render($data_structure)

The main method.

=item $bool = Any::Renderer::Data::Dumper::requires_template($format)

False in this case.

=item $list_ref = Any::Renderer::Data::Dumper::available_formats()

Just the one - C<Data::Dumper>.

=back

=head1 OPTIONS

=over 4

=item VariableName

Name of the perl variable the structure is assigned to.  Defaults to C<$VAR1>.

=item DumperOptions

This hashref of options is mapped to Data::Dumper methods (Indent, Purity, Useqq, etc.).  For example:

  perl -MAny::Renderer -e "print Any::Renderer->new('Data::Dumper', {DumperOptions => {Indent=>0}})->render({a => 1, b => [2,3]})"

results in:

  $VAR1 = {'a' => 1,'b' => [2,3]};

See L<Data::Dumper> for the list of I<Configuration Variables or Methods>.

=back

=head1 SEE ALSO

L<Data::Dumper>, L<Any::Renderer>

=head1 VERSION

$Revision: 1.9 $ on $Date: 2006/08/23 19:41:16 $ by $Author: johna $

=head1 AUTHOR

Matt Wilson and John Alden <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2006. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
