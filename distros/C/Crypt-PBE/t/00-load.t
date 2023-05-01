#!perl -T

use strict;
use warnings;
use Test::More;

require_ok('Crypt::PBE');
require_ok('Crypt::PBE::PBKDF1');
require_ok('Crypt::PBE::PBKDF2');
require_ok('Crypt::PBE::PBES1');
require_ok('Crypt::PBE::PBES2');
require_ok('Crypt::PBE::CLI');

done_testing();

diag("Crypt::PBE $Crypt::PBE::VERSION, Perl $], $^X");
