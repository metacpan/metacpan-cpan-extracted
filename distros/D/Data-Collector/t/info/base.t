#!perl

use strict;
use warnings;

use Test::More tests => 12;
use Test::Fatal;

use Sub::Override;
use Data::Collector::Info;

my $sub  = Sub::Override->new( 'Data::Collector::Info::info_keys' => sub {0} );
my $info = Data::Collector::Info->new;
isa_ok( $info, 'Data::Collector::Info' );

is( $info->load, 1, 'load() return value' );

$sub->restore;

like(
    exception { $info->info_keys },
    qr/^No default info_keys method/,
    'No default info_keys method',
);

like(
    exception { $info->all },
    qr/^No default all method/,
    'No default all method',
);

$info->register('key');
like(
    exception { $info->register('key') },
    qr/^Sorry, key already reserved/,
    'Sorry, key already reserved',
);

$info->clear_registry();
is(
    exception { $info->register('key') },
    undef,
    'Registry cleared',
);

my $found = 0;

{
    no warnings qw/redefine once/;
    *Set::Object::contains = sub {
        isa_ok( $_[0], 'Set::Object',           'correct 1 parameter' );
        is(     $_[1], 'Data::Collector::Info', 'correct 2 parameter' );
        $found or return 1;
        return;
    };
}

is(
    exception { $info = Data::Collector::Info->new },
    undef,
    'No problem if $INFO_MODULES->contains() actually contains',
);

$found++;

ok( exception { $info->BUILD }, 'Dies' );
