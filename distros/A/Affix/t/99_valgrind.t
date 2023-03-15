use strict;
use Test::More 0.98;
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use Config;
use Affix;
$|++;
#
use t::lib::nativecall;
#
plan skip_all => 'Only run valgrind tests locally' unless -e 't/' . __FILE__;
plan skip_all => 'Test::Valgrind is required to test your distribution with valgrind'
    unless require Test::Valgrind;
#
my $lib = compile_test_lib('99_valgrind');
#
affix $lib => 's_bool' => [] => Size_t;
is s_bool(), 1, 'affixed function works';
#
subtest 'Valgrind' => sub {
    Test::Valgrind->analyse( file => 't/' . __FILE__ );
};
#
done_testing;
