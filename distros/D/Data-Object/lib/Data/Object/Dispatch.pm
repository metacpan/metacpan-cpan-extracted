package Data::Object::Dispatch;

use parent 'Data::Object::Code';

# BUILD

sub new {
  my ($class, $name, $func, @args) = @_;

  return if !$name;

  my $space = $class->space($name);

  my $curry = $func ? $space->cop($func, @args) : sub { $space->call(@_) };

  return bless $curry, $class;
}

# METHODS

1;

=encoding utf8

=head1 NAME

Data::Object::Dispatch

=cut

=head1 ABSTRACT

Data-Object Dispatch Class

=cut

=head1 SYNOPSIS

  use Data::Object::Dispatch;

  my $dispatch = Data::Object::Dispatch->new($package);

  $dispatch->call(@args);

=cut

=head1 DESCRIPTION

Data::Object::Dispatch creates dispatcher objects. A dispatcher is a closure
object which when called execute subroutines in a package, and can be curried.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  my $data = Data::Object::Dispatch->new("Data::Object::Export");

Construct a new object.

=cut

=head1 ROLES

This package inherits all behavior from the folowing role(s):

=cut

=over 4

=item *

L<Data::Object::Role::Detract>

=item *

L<Data::Object::Role::Dumper>

=item *

L<Data::Object::Role::Throwable>

=item *

L<Data::Object::Role::Type>

=back

=head1 RULES

This package adheres to the requirements in the folowing rule(s):

=cut

=over 4

=item *

L<Data::Object::Rule::Defined>

=back
