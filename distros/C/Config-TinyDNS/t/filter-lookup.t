#!/usr/bin/perl

use warnings;
use strict;

use Test::More;
use Test::Exception;

use Config::TinyDNS qw/:ALL/;
use Scalar::Util qw/reftype/;

BEGIN {
    for (qw/_lookup_filt _decode_filt/) {   
        no strict "refs";
        *$_ = \&{"Config::TinyDNS\::$_"};
    }
}

my $Filters = Config::TinyDNS::_filter_hash;
reftype $Filters eq "HASH" or die "_filter_hash doesn't return a href!";

%$Filters = ();

throws_ok { _lookup_filt "foo" } qr/bad filter: foo/, 
                                "lookup bad filter throws";

sub dummy { 1 }
sub dimmy { 1 }

#diag "dimmy: " . \&dimmy;

$Filters->{code}    = \&dummy;
$Filters->{ref}     = \sub { \&dummy };
$Filters->{refargs} = \sub { $_[0] eq "foo" ? \&dummy : \&dimmy };
$Filters->{badref}  = [];
$Filters->{badrref} = \[];

lives_ok {
    is _lookup_filt("code"), \&dummy,           "lookup code filter";
}                                               "...no exception";

lives_ok {
    is _lookup_filt("ref"), \&dummy,            "lookup ref filter";
}                                               "...no exception";

throws_ok { _lookup_filt "badref" } 
    qr/^bad \%Filters entry: badref => ARRAY\(0x[[:xdigit:]]+\)/,
                                                "lookup bad filter";
like $@, qr!at .*Config/TinyDNS.pm line!,       "...die not croak";

dies_ok { _lookup_filt "badrref" }              "lookup bad ref filter";
like $@, qr!at .*Config/TinyDNS.pm line!,       "...die not croak";

lives_ok {
    is _lookup_filt("code", "foo"), \&dummy,    "lookup code w/args";
}                                               "...no exception";

lives_ok {
    is _lookup_filt("ref", "foo"), \&dummy,     "lookup ref w/args";
}                                               "...no exception";

lives_ok {
    is _lookup_filt("refargs", "foo"), \&dummy, "lookup refargs";
}                                               "...no exception";

lives_ok {
    isnt _lookup_filt("refargs", "b"), \&dummy, "...honours args";
}                                               "...no exception";


lives_ok { 
    ok !defined _decode_filt(undef),            "decode undef";
}                                               "...no exception";

throws_ok { _decode_filt("foo") } qr/bad filter: foo/,
                                                "decode bad filter";

my $sub = sub { 1 };
lives_ok {
    is _decode_filt($sub), $sub,                "decode CODE";
}                                               "...no exception";

lives_ok {
    is _decode_filt("code"), \&dummy,           "decode non-ref";
}                                               "...no exception";

lives_ok {
    is _decode_filt(["refargs", "foo"]), \&dummy, 
                                                "decode refargs ARRAY";
}                                               "...no exception";

lives_ok {
    is _decode_filt(["code", "foo"]), \&dummy,    
                                                "decode non-args ARRAY";
}                                               "...no exception";

throws_ok { _decode_filt {} } qr/bad filter: HASH\(/,
                                                "decode bad ref";
like $@, qr/.*filter-lookup\.t line/,           "croak not die";

%$Filters = ();

my $ref = \&dummy;

lives_ok { 
    register_tdns_filters 
        foo => \&dummy,
        bar => \$ref;
}                                           "register filters lives";
is_deeply $Filters, {
    foo => \&dummy,
    bar => \$ref,
},                                          "correct registrations";

throws_ok { 
    register_tdns_filters foo => sub { 1 }
} qr/filter 'foo' is already registered/,   "duplicate registration";
is $Filters->{foo}, \&dummy,                "...not registered";

for my $f (undef, "foo", [], {}, \undef, \[], \{}) {
    my $n = defined $f ? $f : "undef";
    throws_ok {
        register_tdns_filters baz => $f
    } qr/filter must be a coderef\(ref\)/,  "bad filter type: $n";
    ok !exists $Filters->{baz},             "...not registered";
}

done_testing;
