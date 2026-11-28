package DBIx::QuickORM::Test::Type::ByBase;
use strict;
use warnings;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Test::Type::ByBase - A type class for tests.

=head1 DESCRIPTION

Claims integer and varchar fields by base type. Keys by the value as given.

=cut

sub base_types          { qw/integer int varchar/ }
sub canonical_key_value { $_[1] }

1;
