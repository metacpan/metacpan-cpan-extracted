use strict;
use Test::More 0.98;
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use Affix qw[:all];
use File::Spec;
use t::lib::nativecall;
use experimental 'signatures';
$|++;
#
#plan skip_all => q[You use *BSD. You don't like nice things.] if $^O =~ /bsd/i;
#
compile_test_lib('58_affix_import_vars');
sub get_integer : Native('t/58_affix_import_vars') : Signature([]=>Int);
sub get_string : Native('t/58_affix_import_vars') : Signature([]=>Str);
subtest 'integer' => sub {
    is get_integer(), 5, 'correct lib value returned';
    pin( my $integer, Affix::locate_lib('t/58_affix_import_vars'), 'integer', Int );
    is $integer, 5, 'correct initial value returned';
    ok $integer = 90, 'set value via magic';
    is get_integer(), 90, 'correct new lib value returned';
};
subtest 'string' => sub {
    is get_string(), 'Hi!', 'correct initial lib value returned';
    pin( my $string, Affix::locate_lib('t/58_affix_import_vars'), 'string', Str );
    is $string, 'Hi!', 'correct initial value returned';
    ok $string = 'Testing', 'set value via magic';
    is get_string(), 'Testing', 'correct new lib value returned';
};
done_testing;
