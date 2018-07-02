#!perl

use strict;
use warnings;
use Test::More;

use Assert::Refute::T::Errors;
use Assert::Refute;

dies_like {
    package T;
    Assert::Refute->configure( driver => 'Carp' );
} qr/Usage.*hash/, "Hash required";

dies_like {
    package T;
    Assert::Refute->configure({ driver => 'Carp' });
} qr/Carp.*Assert::Refute::Report.*driver/, "Carp is not recognized as driver";

done_testing;
