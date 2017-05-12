use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

use Path::Class;
require( file(__FILE__)->dir->file('util.pl')->absolute->stringify );

BEGIN { use_ok 'Data::Petitcom::PTC' }

new_ok 'Data::Petitcom::PTC';

subtest 'resource' => sub {
    my $ptc = Data::Petitcom::PTC->new;
    is $ptc->resource, 'PRG';
    for (qw/PRG GRP CHR COL/) {
        ok $ptc->resource($_);
    }
    dies_ok { ptc->name('SCR') };
};

subtest 'name' => sub {
    my $ptc = Data::Petitcom::PTC->new;
    is $ptc->name, 'DPTC';
    is $ptc->name('abcdefgh'), 'ABCDEFGH';
    is $ptc->name('abcdefgh0123456789'), 'ABCDEFGH';
    dies_ok { ptc->name('this is invalid-name !') };
};

subtest 'version' => sub {
    my $ptc = Data::Petitcom::PTC->new;
    is $ptc->version, 'PETC0300';
    for (qw/PETC0300 PETC0100/) {
        ok $ptc->version($_);
    }
    dies_ok { ptc->name('PETC0500') };
};

subtest 'data' => sub {
    my $ptc = Data::Petitcom::PTC->new;
    ok $ptc->data('dummy');
    is $ptc->data, 'PETC0300RPRGdummy';
};

subtest 'load/restore/dump' => sub {
    plan tests => 3;
    my $raw_ptc = LoadData('PRG.ptc');
    my $ptc     = Data::Petitcom::PTC->load($raw_ptc);

    subtest 'load' => sub {
        is $ptc->resource, 'PRG';
        is $ptc->name,     'DPTC_PRG';
        is $ptc->version,  'PETC0300';
        ok $ptc->data;
    };

    subtest 'restore' => sub {
        my $resource = $ptc->restore;
        isa_ok $resource, 'Data::Petitcom::Resource::PRG';
        my $raw_data = LoadData('PRG.txt');
        cmp_ok( $resource->data, 'eq', $raw_data );
    };

    subtest 'dump' => sub {
        my @dump = unpack 'C*', $ptc->dump;
        my @raw  = unpack 'C*', $raw_ptc;
        is_deeply( \@dump, \@raw );
    };
};
