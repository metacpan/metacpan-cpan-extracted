package DBIx::QuickORM::Test::Type::ByName;
use strict;
use warnings;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Test::Type::ByName - A type class for tests.

=head1 DESCRIPTION

Claims string fields whose names end in C<_ref>.

=cut

sub matches {
    my $class = shift;
    my ($name, $field, $dialect) = @_;
    return $name =~ m/_ref$/ && $field->{affinity} eq 'string' && $dialect->isa('DBIx::QuickORM::Dialect');
}

1;
