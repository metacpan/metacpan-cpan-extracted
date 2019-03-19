#!perl
use 5.006;
use strict;
use warnings;
use lib::relative '.';
use MY::Kit;
use MY::Tests;

BEGIN {
    plan skip_all => 'Could not load MooX::Types::MooseLike' unless
        eval { require MooX::Types::MooseLike; 1; };
}

use MY::Class::MooXTypesMooseLike;

MY::Tests::test_accessors(
    MY::Class::MooXTypesMooseLike->new(medint=>15, regular=>'hello')
);

MY::Tests::test_accessors(
    MY::Class::MooXTypesMooseLike->new(medint=>15, regular=>'hello'),
    1
);

MY::Tests::test_construction 'MY::Class::MooXTypesMooseLike';

done_testing();
