package DBIx::QuickORM::Test::Type::Upper;
use strict;
use warnings;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Test::Type::Upper - A type class for deflation tests.

=head1 DESCRIPTION

Deflates a scalar reference to the upper-cased string. Has no
C<is_inflated>.

=cut

sub deflate { uc ${$_[1]} }

1;
