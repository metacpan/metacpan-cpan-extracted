use Test2::V0;
#
use lib '../lib', 'lib';
use Acme::Free::Advice::Slip qw[:all];
#
imported_ok qw[advice search];
#
ok +advice(), 'stringify';
#
subtest 'random advice' => sub {
    is my $slip = advice(), hash {
        field advice => D();
        field id     => D();
        end()
    }, 'advice() returns a random slip';
    isa_ok $slip, ['Acme::Free::Advice::Slip'], 'slips are blessed hashes';
};
subtest 'specific advice' => sub {
    is my $slip = advice(224), hash {
        field advice => string q[Don't drink bleach.];
        field id     => number 224;
        end;
    }, 'advice(1) returns a known slip';
    is advice(100000), U(), 'advice(100000) returns undef';
};
subtest 'search for advice' => sub {
    is my $list = [ search('time') ], array {
        all_items hash {
            field advice => D();
            field date   => D();
            field id     => D();
            end;
        };
        etc;
    }, 'search("time") returns a list of slips';
    isa_ok $list->[0], ['Acme::Free::Advice::Slip'], 'elements are blessed hashes';
    is [ search('tfcsqfdafdsa') ], [], 'search("tfcsqfdafdsa") returns an empty list';
};
#
done_testing;
