use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok 'Coat::Persistent' }

{
    package A;
    use Coat;
    use Coat::Persistent;

    has_p 'a';

    package B;
    use Coat;
    use Coat::Persistent;

    has_p 'b';
}

my @a_fields   = sort keys %{ Coat::Meta->all_attributes( 'A' ) };
my @a_expected = sort qw(id a);

my @b_fields   = sort keys %{ Coat::Meta->all_attributes( 'B' ) };
my @b_expected = sort qw(id b);

is_deeply(\@a_fields, \@a_expected, 'fields for A are good');
is_deeply(\@b_fields, \@b_expected, 'fields for A are good');

