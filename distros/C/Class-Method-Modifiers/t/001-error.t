use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;

do {
    package Class1;
    use Class::Method::Modifiers;

    ::like(
      ::exception { before foo => sub {}; },
      qr/The method 'foo' is not found in the inheritance hierarchy for class Class1/,
    );
};

do {
    package Class2;
    use Class::Method::Modifiers;

    ::like(
      ::exception { after foo => sub {}; },
      qr/The method 'foo' is not found in the inheritance hierarchy for class Class2/,
    );
};

do {
    package Class3;
    use Class::Method::Modifiers;

    ::like(
      ::exception { around foo => sub {}; },
      qr/The method 'foo' is not found in the inheritance hierarchy for class Class3/,
    );
};

do {
    package Class4;
    use Class::Method::Modifiers;

    sub foo {}

    ::like(
      ::exception { around 'foo', 'bar' => sub {}; },
      qr/The method 'bar' is not found in the inheritance hierarchy for class Class4/,
    );
};

done_testing;
