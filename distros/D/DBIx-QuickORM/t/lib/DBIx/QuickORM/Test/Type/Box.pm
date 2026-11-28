package DBIx::QuickORM::Test::Type::Box;
use strict;
use warnings;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Test::Type::Box - A type class for deflation tests.

=head1 DESCRIPTION

An arrayref deflates to its items joined with commas. A string starting with
C<box:> counts as inflated and deflates to the rest of it. Every C<deflate>
call is recorded in C<@CALLS> as C<[$value, $field, $conn]>. A key is keyed by
its value as given.

=cut

our @CALLS;

sub is_inflated {
    my $class = shift;
    my ($value) = @_;
    return $value =~ m/^box:/ ? 1 : 0;
}

sub deflate {
    my $class = shift;
    my ($value, $field, $conn) = @_;
    push @CALLS => [$value, $field, $conn];
    return join ',' => @$value if ref($value) eq 'ARRAY';
    return $value =~ m/^box:(.*)$/s ? $1 : $value;
}

sub canonical_key_value { $_[1] }

1;
