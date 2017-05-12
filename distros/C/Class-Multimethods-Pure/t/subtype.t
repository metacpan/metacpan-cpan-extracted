use Test::More tests => 9;

BEGIN { use_ok('Class::Multimethods::Pure') }

{
    multi test1 => (Any) => sub {
        "Generic";
    };

    multi test1 => (subtype(Any, sub { $_[0] == 6 })) => sub {
        "Six";
    };

    multi test1 => (subtype(Any, sub { $_[0] > 10 })) => sub {
        "Big";
    };

    multi test1 => (subtype(Any, sub { $_[0] == 40 })) => sub {
        "Forty";
    };

    is(test1(5),  "Generic",   "catch-all");
    is(test1(6),  "Six",       "specific");
    is(test1(20), "Big",       "comparison");
    ok(!eval { test1(40); 1 }, "ambiguous");
}

{
    multi test2 => (Any) => sub {
        "Generic";
    };

    multi test2 => (subtype(Any, sub { $_[0] == 6 })) => sub {
        "Six";
    };

    my $Big = subtype(Any, sub { $_[0] > 10 });

    multi test2 => ($Big) => sub {
        "Big";
    };

    multi test2 => (subtype($Big, sub { $_[0] == 40 })) => sub {
        "Forty";
    };
    
    is(test2(5),  "Generic",   "catch-all");
    is(test2(6),  "Six",       "specific");
    is(test2(20), "Big",       "comparison");
    is(eval { test2(40) }, "Forty",  "specialized subtypes");
}

# vim: ft=perl :
