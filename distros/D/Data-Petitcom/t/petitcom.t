use strict;
use warnings;

use Test::More tests => 4;

use Path::Class;
require( file(__FILE__)->dir->file('util.pl')->absolute->stringify );

BEGIN { use_ok 'Data::Petitcom' }

subtest 'Save (see. resource.t, resource/(chr|col|grp|prg).t)' => sub {
    ok Save( LoadData('PRG.txt') );
    ok Save( LoadData('CHR.bmp'), resource => 'CHR', sp_width => 32, sp_height => 32 );
    ok Save( LoadData('GRP.bmp'), resource => 'GRP' );
};

subtest 'Load (see ptc.t)' => sub {
    ok Load( LoadData('PRG.ptc') );
    ok Load( LoadData('CHR.ptc'), sp_width => 32, sp_height => 32 );
    ok Load( LoadData('GRP.ptc'), );
};

subtest 'QRCode (see qrcode.t)' => sub {
    my $code    = LoadData('PRG.txt');
    my $raw_ptc = LoadData('PRG.ptc');
    my $ptc     = Data::Petitcom::PTC->load($raw_ptc);
    ok QRCode($code);
    ok QRCode($raw_ptc);
    ok QRCode($ptc);
};
