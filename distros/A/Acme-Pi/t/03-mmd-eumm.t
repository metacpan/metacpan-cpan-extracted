use strict;
use warnings;

use Test::More 0.88;
use utf8;
use Acme::Pi;


use Module::Metadata;
diag 'using Module::Metadata ', Module::Metadata->VERSION;

my $mmd_version = Module::Metadata->new_from_module('Acme::Pi')->version;
diag 'Module::Metadata extracted $VERSION:  ', $mmd_version,
    ($mmd_version eq Acme::Pi->VERSION ? ': correct' : ': WRONG');


use ExtUtils::MakeMaker;
diag 'using ExtUtils::MakeMaker ', ExtUtils::MakeMaker->VERSION;

my $parse_pmversion = MM->parse_version($INC{'Acme/Pi.pm'});
diag 'MM->parse_version extracted $VERSION: ', $parse_pmversion,
    ($parse_pmversion eq Acme::Pi->VERSION ? ': correct' : ': WRONG');


# These tests are informational only and we do not wish them to fail.
pass('checks complete!');

done_testing;
