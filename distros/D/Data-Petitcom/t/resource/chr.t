use strict;
use warnings;
use utf8;

use Test::More tests => 5;
use Test::Exception;

use Path::Class;
require( file(__FILE__)->dir->file(qw{ .. util.pl})->absolute->stringify );

BEGIN { use_ok 'Data::Petitcom::Resource::CHR' }

my $chr = new_ok 'Data::Petitcom::Resource::CHR';
isa_ok $chr, 'Data::Petitcom::Resource';

subtest 'data' => sub {
    ok $chr->data( LoadData('CHR.bmp') );
    dies_ok { $chr->data( LoadData('GRP.bmp')  ) }, 'only 256x64 supported';
};

subtest 'save' => sub {
    my $data = LoadData('CHR.bmp');
    $chr->data($data);
    my $ptc = $chr->save( sp_width => 32, sp_height => 32 );
    is_deeply [ unpack 'C*', $ptc->dump ], [ unpack 'C*', LoadData('CHR.ptc') ];
};
