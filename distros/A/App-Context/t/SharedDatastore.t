#!/usr/local/bin/perl -w

use strict;

use Test::More qw(no_plan);
use lib "lib";
use lib "../lib";

BEGIN {
   use_ok("App");
}

my $context = App->context(
    conf_file => "",
    conf => {
        SharedDatastore => {
            simple => {
                class => "App::SharedDatastore",
            },
            compress => {
                class => "App::SharedDatastore",
                compress => 1,
            },
            base64 => {
                class => "App::SharedDatastore",
                base64 => 1,
            },
            compress_base64 => {
                class => "App::SharedDatastore",
                compress => 1,
                base64 => 1,
            },
        },
    },
);

{
    my ($sds, $key, $value, $keyref, $valueref, $valueref2, $hashkey, $serialized_value);

    foreach my $name ("default", "simple", "compress", "base64", "compress_base64") {
        $sds = $context->service("SharedDatastore", $name);
        ok(defined $sds, "[$name] constructor ok");

        isa_ok($sds, "App::SharedDatastore", "[$name] right class");
        is($sds->service_type(), "SharedDatastore", "[$name] right service type");

        my $dump = $sds->dump();
        ok($dump =~ /^\$SharedDatastore__$name = /, "[$name] dump");

        $sds->set("pi", 3.1416);
        $value = $sds->get("pi");
        is($value, 3.1416, "[$name] set()/get() works (for pi=$value)");

        $keyref = [ "person",
            { "age.ge" => 21, last_name => "Adkins" },
            [ "person_id", "last_name", "first_name", "age", "eye_color" ],
            { numrows => 20, cache => {}, },
        ];
        $valueref = [
            [ 1, "Adkins", "Stephen",        40, "Blue",  ],
            [ 2, "Adkins", "Susan (Little)", 40, "Brown", ],
            [ 3, "Adkins", "Bill",           43, "Brown", ],
            [ 4, "Adkins", "Susan",          44, "Brown", ],
            [ 5, "Adkins", "Marybeth",       47, "Blue",  ],
        ];

        $sds->set_ref($keyref, $valueref);
        $valueref2 = $sds->get_ref($keyref);
        is_deeply($valueref, $valueref2, "[$name] set_ref()/get_ref() works");

        $hashkey = $sds->hashkey($keyref);
        $valueref2 = $sds->get_ref($hashkey);
        is_deeply($valueref, $valueref2, "[$name] set_ref()/get_ref(hashkey) works (hashkey=$hashkey)");

        $serialized_value = $sds->serialize($valueref);
        $value = $sds->get($hashkey);
        is($value, $serialized_value, "[$name] set_ref()/get(hashkey) works");

        $valueref2 = $sds->deserialize($serialized_value);
        is_deeply($valueref, $valueref2, "[$name] serialize()/deserialize() works");

        $value = $sds->get("foo");
        is($value, undef, "[$name] get(foo) is undef");

        $valueref2 = $sds->get_ref("foo");
        is($valueref2, undef, "[$name] get_ref(foo) is undef");

        $sds->set_ref("foo", undef);
        $value = $sds->get_ref("foo");
        is($value, undef, "[$name] get_ref(foo) is undef after set to undef");
    }
}

exit 0;

