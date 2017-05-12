# -*- Mode: Perl; -*-

=head1 NAME

00_uri_encode.t - Test the uri_encode funcionality

=cut

use strict;
use Test::More tests => 104;

use_ok("Data::URIEncode", qw(flat_to_complex complex_to_flat query_to_complex complex_to_query));

my $data;
my $out;

$data = {
    "foo:2" => "bar",
    "foo:5" => "bing",
};
ok(($out = flat_to_complex($data)), 'Ran flat_to_complex');
ok($out->{"foo"}->[2] eq "bar", "foo.2");
ok($out->{"foo"}->[5] eq "bing", "foo.5");
ok(! defined $out->{"foo"}->[4], "foo.4");

ok(flat_to_complex({"foo"         => "a"})->{"foo"}             eq "a", "key: (foo)");
ok(flat_to_complex({"0"           => "a"})->{"0"}               eq "a", "key: (0)");
ok(flat_to_complex({"foo.bar.baz" => "a"})->{"foo"}{"bar"}{baz} eq "a", "key: (foo.bar.baz)");
ok(flat_to_complex({"foo:0"       => "a"})->{"foo"}->[0]        eq "a", "key: (foo:0)");
ok(flat_to_complex({"foo:0:2"     => "a"})->{"foo"}->[0]->[2]   eq "a", "key: (foo:0:2)");
ok(flat_to_complex({"foo.0"       => "a"})->{"foo"}->{"0"}      eq "a", "key: (foo.0)");
ok(flat_to_complex({"foo.0.2"     => "a"})->{"foo"}->{"0"}{"2"} eq "a", "key: (foo.0.2)");
ok(flat_to_complex({"foo."        => "a"})->{"foo"}->{""}       eq "a", "key: (foo.)");
ok(flat_to_complex({"foo.''"      => "a"})->{"foo"}->{""}       eq "a", "key: (foo.'')");
ok(flat_to_complex({".foo"        => "a"})->{"foo"}             eq "a", "key: (.foo)");
ok(flat_to_complex({"''.foo"      => "a"})->{""}->{"foo"}       eq "a", "key: (''.foo)");
ok(flat_to_complex({"..foo"       => "a"})->{""}->{"foo"}       eq "a", "key: (..foo)");
ok(flat_to_complex({".''.foo"     => "a"})->{""}->{"foo"}       eq "a", "key: (.''.foo)");
ok(flat_to_complex({"foo..bar"    => "a"})->{"foo"}{""}{"bar"}  eq "a", "key: (foo..bar)");
ok(flat_to_complex({" "           => "a"})->{" "}               eq "a", "key: ( )");
ok(flat_to_complex({" . "         => "a"})->{" "}->{" "}        eq "a", "key: ( . )");
ok(flat_to_complex({" . . "       => "a"})->{" "}->{" "}->{" "} eq "a", "key: ( . . )");
ok(flat_to_complex({"foo.'.'"     => "a"})->{"foo"}->{"."}      eq "a", "key: (foo.'.')");
ok(flat_to_complex({"'.'.foo"     => "a"})->{"."}->{"foo"}      eq "a", "key: ('.'.foo)");
ok(flat_to_complex({"'.'"         => "a"})->{"."}               eq "a", "key: ('.')");
ok(flat_to_complex({"'.'.'.'"     => "a"})->{"."}->{"."}        eq "a", "key: ('.'.'.')");
ok(flat_to_complex({"'.'.'.'.'.'" => "a"})->{"."}->{"."}->{"."} eq "a", "key: ('.'.'.'.'.')");
ok(flat_to_complex({"'\\'\\''"    => "a"})->{"''"}              eq "a", "key: ('\\'\\'')");
ok(flat_to_complex({"''"          => "a"})->{""}                eq "a", "key: ('')");
ok(flat_to_complex({""            => "a"})->{""}                eq "a", "key: ()");
ok(flat_to_complex({":3"          => "a"})->[3]                 eq "a", "key: (:3)");

ok(flat_to_complex({".foo"         => "a"})->{"foo"}             eq "a", "key: (.foo)");
ok(flat_to_complex({".foo.bar.baz" => "a"})->{"foo"}{"bar"}{baz} eq "a", "key: (.foo.bar.baz)");
ok(flat_to_complex({".foo:0"       => "a"})->{"foo"}->[0]        eq "a", "key: (.foo:0)");
ok(flat_to_complex({".foo:0:2"     => "a"})->{"foo"}->[0]->[2]   eq "a", "key: (.foo:0:2)");
ok(flat_to_complex({".foo.0"       => "a"})->{"foo"}->{"0"}      eq "a", "key: (.foo.0)");
ok(flat_to_complex({".foo.0.2"     => "a"})->{"foo"}->{"0"}{"2"} eq "a", "key: (.foo.0.2)");
ok(flat_to_complex({".foo."        => "a"})->{"foo"}->{""}       eq "a", "key: (.foo.)");
ok(flat_to_complex({".''.foo"      => "a"})->{""}->{"foo"}       eq "a", "key: (.''.foo)");
ok(flat_to_complex({".foo..bar"    => "a"})->{"foo"}{""}{"bar"}  eq "a", "key: (.foo..bar)");
ok(flat_to_complex({". "           => "a"})->{" "}               eq "a", "key: (. )");
ok(flat_to_complex({". . "         => "a"})->{" "}->{" "}        eq "a", "key: (. . )");
ok(flat_to_complex({". . . "       => "a"})->{" "}->{" "}->{" "} eq "a", "key: (. . . )");
ok(flat_to_complex({".foo.'.'"     => "a"})->{"foo"}->{"."}      eq "a", "key: (.foo.'.')");
ok(flat_to_complex({".'.'.foo"     => "a"})->{"."}->{"foo"}      eq "a", "key: (.'.'.foo)");
ok(flat_to_complex({"'.'.foo"      => "a"})->{"."}->{"foo"}      eq "a", "key: ('.'.foo)");
ok(flat_to_complex({".'.'"         => "a"})->{"."}               eq "a", "key: (.'.')");
ok(flat_to_complex({".'.'.'.'"     => "a"})->{"."}->{"."}        eq "a", "key: (.'.'.'.')");
ok(flat_to_complex({".'.'.'.'.'.'" => "a"})->{"."}->{"."}->{"."} eq "a", "key: (.'.'.'.'.'.')");
ok(flat_to_complex({".'\\'\\''"    => "a"})->{"''"}              eq "a", "key: (.'\\'\\'')");
ok(flat_to_complex({".'.:\\''"     => "a"})->{".:'"}             eq "a", "key: (.'.:\\'')");
ok(flat_to_complex({".''"          => "a"})->{""}                eq "a", "key: (.'')");
ok(flat_to_complex({"."            => "a"})->{""}                eq "a", "key: (.)");

ok(! eval { flat_to_complex({".1" => "a", ":1" => "a"      }) }, "Can't coerce ($@)");
ok(! eval { flat_to_complex({"foo.1" => "a", "foo:1" => "a"}) }, "Can't coerce ($@)");
ok(! eval { flat_to_complex({"foo.1" => "a", "'foo':1"=>"a"}) }, "Can't coerce ($@)");
ok(! eval { flat_to_complex({"foo:10000"             => "a"}) }, "Couldn't run - too big ($@)");
ok(! eval { flat_to_complex({"foo"   => "a", "foo.a" => "a"}) }, "Couldn't run - overlap of keys ($@)");
ok(! eval { flat_to_complex({"foo:1" => "a", "foo:a" => "a"}) }, "Couldn't run - using a for index ($@)");
ok(! eval { flat_to_complex({"foo:a" => "a"                }) }, "Couldn't run - using a for index ($@)");
ok(! eval { flat_to_complex({":a" => "a"                   }) }, "Couldn't run - using a for index ($@)");

ok(complex_to_flat({"foo" => "a"               })->{"foo"}         eq "a", "key: (foo)");
ok(complex_to_flat({"0"   => "a"               })->{"0"}           eq "a", "key: (0)");
ok(complex_to_flat({"foo" => {"bar" => "a"}    })->{"foo.bar"}     eq "a", "key: (foo.bar)");
ok(complex_to_flat({"foo" => {bar=>{baz=>"a"}} })->{"foo.bar.baz"} eq "a", "key: (foo.bar.baz)");
ok(complex_to_flat({"foo" => ["a"]             })->{"foo:0"}       eq "a", "key: (foo:0)");
ok(complex_to_flat({"foo" => [[0,1,"a"]]       })->{"foo:0:2"}     eq "a", "key: (foo:0:2)");
ok(complex_to_flat({"foo" => {"0" => "a"}      })->{"foo.0"}       eq "a", "key: (foo.0)");
ok(complex_to_flat({"foo" => {"0"=>{"2"=>"a"}} })->{"foo.0.2"}     eq "a", "key: (foo.0.2)");
ok(complex_to_flat({"foo" => {"" => "a"}       })->{"foo.''"}      eq "a", "key: (foo.'')");
ok(complex_to_flat({""    => {"foo" => "a"}    })->{"''.foo"}      eq "a", "key: (''.foo)");
ok(complex_to_flat({"foo" => {""=>{"bar"=>"a"}}})->{"foo.''.bar"}  eq "a", "key: (foo.''.bar)");
ok(complex_to_flat({" "   => "a"               })->{" "}           eq "a", "key: ( )");
ok(complex_to_flat({" "   => {" " => "a"}      })->{" . "}         eq "a", "key: ( . )");
ok(complex_to_flat({" "   => {" " =>{" "=>"a"}}})->{" . . "}       eq "a", "key: ( . . )");
ok(complex_to_flat({"foo" => {"." => "a"}      })->{"foo.'.'"}     eq "a", "key: (foo.'.')");
ok(complex_to_flat({"."   => {"foo" => "a"}    })->{"'.'.foo"}     eq "a", "key: ('.'.foo)");
ok(complex_to_flat({"."   => "a"               })->{"'.'"}         eq "a", "key: ('.')");
ok(complex_to_flat({"."   => {"." => "a"}      })->{"'.'.'.'"}     eq "a", "key: ('.'.'.')");
ok(complex_to_flat({"."   => {"."=>{"."=> "a"}}})->{"'.'.'.'.'.'"} eq "a", "key: ('.'.'.'.'.')");
ok(complex_to_flat({"''"  => "a"               })->{"'\\'\\''"}      eq "a", "key: ('\\'\\'')");
ok(complex_to_flat({""    => "a"               })->{"''"}          eq "a", "key: ('')");
ok(complex_to_flat([0, 1, 2, "a"               ])->{":3"}          eq "a", "key: (:3)");

Foo: {
    local $Data::URIEncode::DUMP_BLESSED_DATA;
    $Data::URIEncode::DUMP_BLESSED_DATA = 0;
    ok(! eval { complex_to_flat(bless [], "main") }, 'Couldn"t flatten: ($@)');
    ok(! eval { complex_to_flat(bless {}, "main") }, 'Couldn"t flatten: ($@)');
};

ok(! eval { complex_to_flat(sub {}) },           'Couldn"t flatten: ($@)');
ok(! eval { complex_to_flat(undef) },            'Couldn"t flatten: ($@)');
ok(! eval { complex_to_flat("undef") },          'Couldn"t flatten: ($@)');

ok(complex_to_query(["a","b"]) eq ":0=a&:1=b", ":0=a&:1=b");
ok(complex_to_query({"a","b"}) eq "a=b", "a=b");
ok(complex_to_query({x => {y => ["a","b"], z => 1}}) eq "x.y:0=a&x.y:1=b&x.z=1", "x.y:0=a&x.y:1=b&x.z=1");

SKIP: {
    skip('No CGI found', 9) if ! eval { require CGI };

    ok(query_to_complex(":0=a&:1=b"            )->[1]               eq "b", "str: :0=a&:1=b");
    ok(query_to_complex("a=b"                  )->{"a"}             eq "b", "str: a=b");
    ok(query_to_complex("x.y:0=a&x.y:1=b&x.z=1")->{"x"}->{"y"}->[1] eq "b", "str: x.y:0=a&x.y:1=b&x.z=1");

    ok(query_to_complex(\ ":0=a&:1=b"            )->[1]               eq "b", "str ref: :0=a&:1=b");
    ok(query_to_complex(\ "a=b"                  )->{"a"}             eq "b", "str ref: a=b");
    ok(query_to_complex(\ "x.y:0=a&x.y:1=b&x.z=1")->{"x"}->{"y"}->[1] eq "b", "str ref: x.y:0=a&x.y:1=b&x.z=1");

    ok(query_to_complex(CGI->new(\ ":0=a&:1=b"            ))->[1]               eq "b", "CGI->new: :0=a&:1=b");
    ok(query_to_complex(CGI->new(\ "a=b"                  ))->{"a"}             eq "b", "CGI->new: a=b");
    ok(query_to_complex(CGI->new(\ "x.y:0=a&x.y:1=b&x.z=1"))->{"x"}->{"y"}->[1] eq "b", "CGI->new: x.y:0=a&x.y:1=b&x.z=1");

};

ok(query_to_complex({":0" => "a", ":1" => "b"}                   )->[1]               eq "b", "hashref: :0=a&:1=b");
ok(query_to_complex({"a" => "b"}                                 )->{"a"}             eq "b", "hashref: a=b");
ok(query_to_complex({"x.y:0" =>"a", "x.y:1" => "b", "x.z" => "1"})->{"x"}->{"y"}->[1] eq "b", "hashref: x.y:0=a&x.y:1=b&x.z=1");

ok(! eval { query_to_complex([]) }, 'Blew up - not a known type to deal with');

