use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

do {
    package Class1;
    use Class::Method::Modifiers;

    eval { before foo => sub {}; };
    ::like($@,
      qr/The method 'foo' is not found in the inheritance hierarchy for class Class1/,
    );
};

do {
    package Class2;
    use Class::Method::Modifiers;

    eval { after foo => sub {}; };
    ::like(
      $@,
      qr/The method 'foo' is not found in the inheritance hierarchy for class Class2/,
    );
};

do {
    package Class3;
    use Class::Method::Modifiers;

    eval { around foo => sub {}; };
    ::like(
      $@,
      qr/The method 'foo' is not found in the inheritance hierarchy for class Class3/,
    );
};

do {
    package Class4;
    use Class::Method::Modifiers;

    sub foo {}

    eval { around 'foo', 'bar' => sub {}; };
    ::like(
      $@,
      qr/The method 'bar' is not found in the inheritance hierarchy for class Class4/,
    );
};

done_testing;
