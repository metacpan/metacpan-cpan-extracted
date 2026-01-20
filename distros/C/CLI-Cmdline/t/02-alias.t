# t/02-alias.t - Test alias functionality using | syntax
use strict;
use warnings;
use Test::More tests => 28;
use Test::NoWarnings 'had_no_warnings';

use CLI::Cmdline qw(parse);

my %opt;

sub run_test {
    my ($desc, $opt_ref, $sw, $opt_str, @args) = @_;
    local @ARGV = @args;
    my $result = CLI::Cmdline::parse($opt_ref, $sw // '', $opt_str // '');
    ok($result, $desc) or diag("Failed: @args");
    return $result;
}

# 01 - basic short alias
%opt = ( v => 0 );
run_test('01 - short alias -v', \%opt, 'v|verbose', '', '-v');
is($opt{v}, 1, '01 - v incremented');

# 02 - long alias
%opt = ( v => 0 );
run_test('02 - long alias --verbose', \%opt, 'v|verbose', '', '--verbose');
is($opt{v}, 1, '02 - verbose maps to v');

# 03 - multiple aliases including extra long
%opt = ( v => 0 );
run_test('03 - multiple alias forms', \%opt, 'v|verbose|verbosity', '',
    '-v', '--verbose', '-vv', '--verbosity');
is($opt{v}, 5, '03 - all aliases count toward v');

# 04 - no stray keys created
ok(!exists $opt{verbose},   '04 - no verbose key created');
ok(!exists $opt{verbosity}, '04 - no verbosity key created');

# 05 - option with argument via short alias
%opt = ( file => '' );
run_test('05 - short option alias -f', \%opt, '', 'file|f|input', '-f', 'data.txt');
is($opt{file}, 'data.txt', '05 - value stored under canonical file');

# 06 - option via long alias
%opt = ( file => '' );
run_test('06 - long alias --input', \%opt, '', 'file|f|input', '--input=data.txt');
is($opt{file}, 'data.txt', '06 - input maps to file');

# 07 - attached value with long alias
%opt = ( out => '' );
run_test('07 - attached --output=', \%opt, '', 'out|output|o', '--output=result.log');
is($opt{out}, 'result.log', '07 - output maps to out');

# 08 - bundling with aliased short switches
%opt = ( x => 0, v => 0, q => 0 );
run_test('08 - bundling -xvq with aliases', \%opt, 'x|extract v|verbose q|quiet', '', '-xvq');
is($opt{x}, 1, '08 - x incremented');
is($opt{v}, 1, '08 - v incremented via alias');
is($opt{q}, 1, '08 - q incremented via alias');

# 09 - array collection using short and long alias
%opt = ( tag => [] );
run_test('09 - array with tag|t alias', \%opt, '', 'tag|t',
    '--tag', 'build', '-t', 'test', '--t=prod');
is_deeply($opt{tag}, ['build', 'test', 'prod'], '09 - all values collected');

# 10 - long name as canonical, short as aliases
%opt = ( debug => 0 );
run_test('10 - long canonical debug|d|dbg', \%opt, 'debug|d|dbg', '', '-d', '--dbg');
is($opt{debug}, 2, '10 - both short and dbg increment debug');
ok(!exists $opt{d}, '10 - no stray d key');

# 11 - required option missing (via alias spec)
%opt = ( src => '' );
run_test('11 - required src missing', \%opt, '', 'src|source|s');
is($opt{src}, '', '11 - missing required → empty string');

# 12 - required option provided via short alias
%opt = ( src => '' );
run_test('12 - required provided via -s', \%opt, '', 'src|source|s', '-s', 'input.txt');
is($opt{src}, 'input.txt', '12 - value set via short alias');

had_no_warnings();
done_testing();
