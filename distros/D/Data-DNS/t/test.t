#!/usr/bin/env perl
use Test::More;
use LWP::Online qw(:skip_all);
use Test::More;
use common::sense;

my $class = q{Data::DNS};
my $object_class = $class.q{::TLD};

require_ok $class;
require_ok $object_class;

ok($class->exists(q{com}));
ok(!$class->exists(q{invalid}));

foreach my $test (
    [q{org},    $object_class->TYPE_GTLD],
    [q{edu},    $object_class->TYPE_SPONSORED],
    [q{jp},     $object_class->TYPE_CCTLD],
    [q{arpa},   $object_class->TYPE_INFRA],
) {
    my $tld = $class->get($test->[0]);

    isa_ok($tld, $object_class);

    is($tld->type, $test->[1]);
}

my $tld = $class->get(q{org});

isa_ok($tld->rdap_record, q{Net::RDAP::Object::Domain});
isa_ok($tld->gtld_record, q{ICANN::gTLD});
isa_ok($tld->rdap_server, q{Net::RDAP::Service});

done_testing;
