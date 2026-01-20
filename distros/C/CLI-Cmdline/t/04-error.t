# t/04-error.t - Test error cases and invalid command-line input
use strict;
use warnings;
use Test::More tests => 28;
use Test::NoWarnings 'had_no_warnings';

use CLI::Cmdline qw(parse);

my %opt;

sub run_test {
    my ($desc, $opt_ref, $sw, $opt_str, @args) = @_;
    my @restored;
    {
        local @ARGV = @args;
        my $result = CLI::Cmdline::parse($opt_ref, $sw // '', $opt_str // '');
        ok(!$result, $desc) or diag("Unexpected success with: @args");
        @restored = @ARGV;   # capture what was restored after failure
    }
    return \@restored;
}

# 01 - unknown short switch
%opt = ( v => 0 );
my $restored = run_test('01 - unknown short switch -x', \%opt, 'v|verbose', '', '-x');
is_deeply($restored, ['-x'], '01 - @ARGV restored on unknown short');

# 02 - unknown long option
%opt = ( verbose => 0 );
$restored = run_test('02 - unknown long --quiet', \%opt, 'verbose|v', '', '--quiet');
is_deeply($restored, ['--quiet'], '02 - @ARGV restored on unknown long');

# 03 - option requires argument but none given (space form)
%opt = ( file => '' );
$restored = run_test('03 - missing argument after --file', \%opt, '', 'file|f', '--file');
is_deeply($restored, ['--file'], '03 - stops at --file, @ARGV restored');

# 04 - option requires argument but none given (bundled last)
%opt = ( file => '', v => 0 );
$restored = run_test('04 - missing argument after -f in bundle -vf', \%opt, 'v|verbose', 'file|f', '-vf');
is_deeply($restored, ['-vf'], '04 - entire bundle restored');

# 05 - option requires argument but none given (attached = but empty)
%opt = ( output => '' );
{
    local @ARGV = ('--output');
    my $result = CLI::Cmdline::parse(\%opt, '', 'output|o');
    ok(!$result, '05 - missing argument after --output (no next)');
    is_deeply(\@ARGV, ['--output'], '05 - --output restored');
}

# 06 - short option requiring arg in middle of bundle
%opt = ( x => 0, file => '' );
$restored = run_test('06 - -xf where -f needs arg', \%opt, 'x', 'file|f', '-xf');
is_deeply($restored, ['-xf'], '06 - bundle restored when middle needs arg');

# 07 - unknown option in bundle
%opt = ( v => 0, q => 0 );
$restored = run_test('07 - unknown -z in bundle -vqz', \%opt, 'v|verbose q|quiet', '', '-vqz');
is_deeply($restored, ['-vqz'], '07 - entire bundle rejected on unknown');

# 08 - lone dash is not an option
%opt = ( v => 0 );
{
    local @ARGV = ('-', 'file.txt');
    ok( CLI::Cmdline::parse(\%opt, 'v', ''), '08 - lone - is not option' );
    is_deeply(\@ARGV, ['-', 'file.txt'], '08 - lone - and positional remain');
}

# 09 - -- ends option processing
%opt = ( v => 0 );
{
    local @ARGV = ('-v', '--', '--secret', 'pos1');
    ok( CLI::Cmdline::parse(\%opt, 'v|verbose', ''), '09 - -- stops processing' );
    is( $opt{v}, 1, '09 - -v processed' );
    is_deeply(\@ARGV, ['--secret', 'pos1'], '09 - everything after -- preserved');
}

# 10 - invalid attached form with unknown option
%opt = ( file => '' );
$restored = run_test('10 - unknown --xyz=val', \%opt, '', 'file', '--xyz=val');
is_deeply($restored, ['--xyz=val'], '10 - unknown attached restored');

# 11 - mix valid and invalid
%opt = ( v => 0, file => '' );
{
    local @ARGV = ('-v', '--file', 'data.txt', '--bad');
    my $result = CLI::Cmdline::parse(\%opt, 'v', 'file');
    ok(!$result, '11 - fails on --bad after valid options');
    is( $opt{v}, 1, '11 - valid -v processed' );
    is( $opt{file}, 'data.txt', '11 - valid --file processed' );
    is_deeply(\@ARGV, ['--bad'], '11 - only invalid part restored');
}

# 12 - required argument missing at end of bundle
%opt = ( v => 0, dir => '' );
$restored = run_test('12 - -vd without arg for -d', \%opt, 'v', 'dir|d', '-vd');
is_deeply($restored, ['-vd'], '12 - bundle restored');

had_no_warnings();
done_testing();
