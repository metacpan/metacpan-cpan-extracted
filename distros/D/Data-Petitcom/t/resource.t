use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

BEGIN { use_ok 'Data::Petitcom::Resource' }

subtest 'get_resource' => sub {
    isa_ok get_resource(), 'Data::Petitcom::Resource::PRG';
    isa_ok get_resource( resource => 'PRG' ), 'Data::Petitcom::Resource::PRG';
    isa_ok get_resource( resource => 'prg' ), 'Data::Petitcom::Resource::PRG';
    isa_ok get_resource( resource => 'CHR' ), 'Data::Petitcom::Resource::CHR';
    dies_ok { get_resource( resource => 'SCR' ) }, 'unimpremented resource';
};
