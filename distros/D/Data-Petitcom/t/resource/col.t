use strict;
use warnings;
use utf8;

use Test::More tests => 5;

use Path::Class;
require( file(__FILE__)->dir->file(qw{ .. util.pl})->absolute->stringify );

BEGIN { use_ok 'Data::Petitcom::Resource::COL' }

my $col = new_ok 'Data::Petitcom::Resource::COL';
isa_ok $col, 'Data::Petitcom::Resource';

subtest 'save' => sub {
    my $data = LoadData('COL.bmp');
    my $col = Data::Petitcom::Resource::COL->new( data => $data );
    my $ptc = $col->save;
    ok $ptc;
    isa_ok $ptc, 'Data::Petitcom::PTC';
    is_deeply [ unpack 'C*', $ptc->dump ], [ unpack 'C*', LoadData('COL.ptc') ];
};

subtest 'load' => sub {
    my $ptc = Data::Petitcom::PTC->new->load( LoadData('COL.ptc') );
    my $col = Data::Petitcom::Resource::COL->new->load($ptc);
    ok $col;
    is_deeply [ unpack 'C*', $col->data ], [ unpack 'C*', LoadData('COL.bmp') ];
};
