use Test::More;
use strict;

use Config::Path;

my $conf = Config::Path->new(
    directory => 't/conf',
);

cmp_ok($conf->fetch('thingies/0/name'), 'eq', 'thing1', 'arrays');

ok(!defined($conf->fetch('thingies/fart/name')), 'got undef for unreachable item');

ok(!defined($conf->fetch('thingies/fart/name')), 'got undef for unreachable (array) item');

cmp_ok($conf->fetch('one/for/the'), 'eq', 'hustle', 'deep hash');

ok(!defined($conf->fetch('one/far/the')), 'got undef for unreachable (hash) item');

SKIP: {
    local $@;
    eval { require XML::Simple; };
    skip "XML::Simple required for XML testing", 4 if $@;

    $conf = Config::Path->new(
        directory => 't/conf/xml',
    );

    cmp_ok($conf->fetch('xml/not'), 'eq', 'empty', 'got value for xml item');
    ok(!defined($conf->fetch('xml/empty')), 'got undef for empty item');

    $conf = Config::Path->new(
        directory => 't/conf/xml',
        convert_empty_to_undef => 0
    );

    cmp_ok($conf->fetch('xml/not'), 'eq', 'empty', 'got value for xml item');
    ok(ref $conf->fetch('xml/empty') eq 'HASH', 'got hashref for empty xml item');
}

done_testing;
