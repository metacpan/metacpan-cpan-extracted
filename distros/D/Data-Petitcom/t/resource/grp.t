use strict;
use warnings;
use utf8;

use Test::More tests => 5;
use Test::Exception;

use Path::Class;
require( file(__FILE__)->dir->file(qw{ .. util.pl})->absolute->stringify );

BEGIN { use_ok 'Data::Petitcom::Resource::GRP' }

my $grp = new_ok 'Data::Petitcom::Resource::GRP';
isa_ok $grp, 'Data::Petitcom::Resource';

subtest 'data' => sub {
    ok $grp->data( LoadData('GRP.bmp') );
    dies_ok { $grp->data( LoadData('CHR.bmp')  ) }, 'only 256x192 supported';
};

subtest 'save' => sub {
    my $data = LoadData('GRP.bmp');
    $grp->data($data);
    my $ptc = $grp->save();
    is_deeply [ unpack 'C*', $ptc->dump ], [ unpack 'C*', LoadData('GRP.ptc') ];
};
