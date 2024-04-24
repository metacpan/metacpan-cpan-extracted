#!perl -T

use strict;
use warnings;

use Test::More;
use CSAF::Type;

my $TYPES = CSAF::Type::TYPE_CLASSES();

foreach my $name (sort keys %{$TYPES}) {

    subtest "'$name' type" => sub {

    SKIP: {

            eval {
                my $class = CSAF::Type->new(name => $name, value => {});
                isa_ok($class, $TYPES->{$name}, "'$name' type using CSAF::Type->new");
            };

            skip "$name: $@", 1 if $@;

            eval {
                my $class = CSAF::Type->name($name, {});
                isa_ok($class, $TYPES->{$name}, "'$name' type using CSAF::Type->name");
            };

            skip "$name: $@", 1 if $@;

        }

    };

}

done_testing();
