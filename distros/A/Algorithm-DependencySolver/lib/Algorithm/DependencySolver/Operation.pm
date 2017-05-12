package Algorithm::DependencySolver::Operation;
$Algorithm::DependencySolver::Operation::VERSION = '1.01';
use Moose;

=head1 NAME

Algorithm::DependencySolver::Operation - An operation representation

=head1 VERSION

version 1.01

=head1 SYNOPSIS

  my $operation = Algorithm::DependencySolver::Operation->new(
    id            => 2,
    depends       => [qw(x)],
    affects       => [qw(y)],
    prerequisites => [1],
    obj           => $whatever
  );

=head1 OPTIONAL ATTRIBUTES

=head2 obj

An arbitrary object, which is never used by anything in the C<Algorithm::DependencySolver::*> namespace.

=cut

has 'obj' => (
    is       => 'rw',
);


=head2 prerequisites

An arrayref of other Operation objects, identified by their id strings.

If an operation C<$b> depends on operation <C$a>, then any cycle which
would have resulted in C<$b> running before C<$a> will be broken just
before operation C<$a>.

That is, if there exists a cycle containing both C<$a> and C<$b>, then
edge C<$e> will be removed, where C<$e> is any edge within the cycle
which points directly to C<$a>.

=cut

has 'prerequisites' => (
    is       => 'rw',
    default  => sub { [] },
);

=head2 id

A string which uniquely identifies this operation

=cut

has 'id'     => (
    is       => 'rw',
);

=head2 depends

An arrayref of resources (each resource is simply a string identifier) that
this operation depends on.

=cut

has 'depends' => (
    is       => 'rw',
    default  => sub { [] },
);

=head2 affects

An arrayref of resources (each resource is simply a string identifier)
that this operation affects (i.e., modifies).

=cut

has 'affects' => (
    is       => 'rw',
#   isa      => 'ArrayRef[String]',
    default  => sub { [] },
);

no Moose;
__PACKAGE__->meta->make_immutable;
