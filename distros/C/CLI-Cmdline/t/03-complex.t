# t/03-complex.t - Test spec strings with or without -/-- prefixes
use strict;
use warnings;
use Test::More tests => 28;

use CLI::Cmdline qw(parse);

my %opt;

sub run_test {
    my ($desc, $opt_ref, $sw, $opt_str, @args) = @_;
    local @ARGV = @args;
    my $result = CLI::Cmdline::parse($opt_ref, $sw // '', $opt_str // '');
    ok($result, $desc) or diag("Failed: @args");
    return $result;
}

# 01 - bare names only (no prefixes in spec)
%opt = ( v => 0, quiet => 0 );
run_test('01 - bare spec names', \%opt, 'v|verbose quiet|q', '', '-v', '--quiet');
is($opt{v}, 1, '01 - v from bare spec');
is($opt{quiet}, 1, '01 - quiet from bare spec');

# 02 - traditional prefixed spec
%opt = ( h => 0 );
run_test('02 - prefixed spec -h|--help', \%opt, '-h|--help', '', '--help');
is($opt{h}, 1, '02 - help maps to h');

# 03 - mixed bare and prefixed in same spec
%opt = ( x => 0 );
run_test('03 - mixed styles x|-x|--extract', \%opt, 'x|-x|--extract', '', '--extract', '-x');
is($opt{x}, 2, '03 - both forms increment x');

# 04 - option with bare name in spec
%opt = ( file => '' );
run_test('04 - bare option name file|f', \%opt, '', 'file|f', '--file=data.txt');
is($opt{file}, 'data.txt', '04 - file set from bare spec');

# 05 - option with prefixed spec
%opt = ( input => '' );
run_test('05 - prefixed option --input|-i', \%opt, '', '--input|-i', '-i', 'in.txt');
is($opt{input}, 'in.txt', '05 - input set via short alias');

# 06 - complex real-world example using bare names
%opt = (
    verbose => 0,
    dryrun  => 0,
    config  => '',
    include => [],
);
run_test('06 - complex bare spec', \%opt,
    'verbose|v dryrun|n|dry-run',
    'config|c include|I|inc',
    '-vvv', '--dry-run', '--config=/etc/app.cfg', '-I', 'lib', '--include', 'extra'
);
is($opt{verbose}, 3, '06 - verbose counted');
is($opt{dryrun}, 1, '06 - dry-run set');
is($opt{config}, '/etc/app.cfg', '06 - config set');
is_deeply($opt{include}, ['lib', 'extra'], '06 - include collected via aliases');

# 07 - empty switch string
%opt = ( file => '' );
run_test('07 - empty switch string', \%opt, '', 'file', '--file', 'test.txt');
is($opt{file}, 'test.txt', '07 - option works with no switches');

# 08 - empty option string
%opt = ( v => 0 );
run_test('08 - empty option string', \%opt, 'v|verbose', '', '-vvv');
is($opt{v}, 3, '08 - switches work with no options');

# 09 - both spec strings empty
%opt = ( dummy => 42 );
run_test('09 - both specs empty', \%opt, '', '');
is($opt{dummy}, 42, '09 - existing value preserved');

# 10 - required options with bare names, missing then provided
%opt = ( src => '', dest => '' );
run_test('10 - required bare options missing', \%opt, '', 'src dest|d');
is($opt{src}, '', '10 - src missing → empty');
is($opt{dest}, '', '10 - dest missing → empty');

run_test('10 - required provided via aliases', \%opt, '', 'src dest|d',
    '--src', 'a.txt', '-d', 'b.txt');
is($opt{src}, 'a.txt', '10 - src provided');
is($opt{dest}, 'b.txt', '10 - dest via short alias');

done_testing();
