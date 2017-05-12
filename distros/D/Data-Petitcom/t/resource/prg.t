use strict;
use warnings;
use utf8;

use Test::More tests => 7;

use Path::Class;
require( file(__FILE__)->dir->file(qw{ .. util.pl})->absolute->stringify );

BEGIN { use_ok 'Data::Petitcom::Resource::PRG' }

my $prg = new_ok 'Data::Petitcom::Resource::PRG';
isa_ok $prg, 'Data::Petitcom::Resource';

subtest '_encode' => sub {
    my $data = {
        'Ф' => [ 0x18 ],
        'あ' => [ 0xB1 ],
        'ン' => [ 0xDD ],
        'ガ' => [ 0xB6, 0xDE ], #  => ｶﾞ(cp932)
    };
    for my $char (keys %$data) {
        is_deeply [ unpack( 'C*', Data::Petitcom::Resource::PRG::_encode($char) ) ], $data->{$char};
    }
};

subtest '_decode' => sub {
    my $data = {
        '18'   => [ 'Ф', 'Ф' ],
        'B1'   => [ 'ｱ', 'ア' ],
        'DD'   => [ 'ﾝ', 'ン' ],
        'B6DE' => [ 'ｶﾞ', 'カ゛' ],
    };
    for my $code (keys %$data) {
        my $bin = pack 'H*', $code;
        cmp_ok Data::Petitcom::Resource::PRG::_decode($bin), 'eq', $data->{$code}->[0];
        cmp_ok Data::Petitcom::Resource::PRG::_decode($bin, 1), 'eq', $data->{$code}->[1];
    }
};

subtest 'save' => sub {
    my $prg = Data::Petitcom::Resource::PRG->new(
        data => LoadData('PRG.txt')
    );
    my $ptc = $prg->save;
    ok $ptc;
    isa_ok $ptc, 'Data::Petitcom::PTC';
    is_deeply [ unpack 'C*', $ptc->dump ], [ unpack 'C*', LoadData('PRG.ptc') ];
};

subtest 'load' => sub {
    my $ptc = Data::Petitcom::PTC->new->load( LoadData('PRG.ptc') );
    my $prg = Data::Petitcom::Resource::PRG->new->load($ptc);
    ok $prg;
    cmp_ok $prg->data, 'eq', LoadData('PRG.txt');
};
