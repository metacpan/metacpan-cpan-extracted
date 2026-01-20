#!/usr/bin/perl
use strict;
use warnings;
use Test::More  tests => 163;
use Data::Dumper;
use Test::NoWarnings 'had_no_warnings';

use CLI::Cmdline qw(parse);

sub run_test {
    my ($desc, $argv, $sw, $opt, $init, $expect_p, $expect_argv, $expect_ret) = @_;

    local @ARGV = @$argv;
    my %p = %$init;

    my $ret = CLI::Cmdline::parse(\%p, $sw // '', $opt // '');

    is($ret, $expect_ret, "$desc: return");
    is_deeply(\%p, $expect_p, "$desc: params")     or diag "Got: " . Dumper(\%p);
    is_deeply(\@ARGV, $expect_argv, "$desc: ARGV") or diag "Got: " . Dumper(\@ARGV);
}

run_test("01 - single switch", ['-v'], '-v', '', {}, {v=>1}, [], 1);
run_test("02 - multi switch", ['-verbose'], '-verbose', '', {}, {verbose=>1}, [], 1);
run_test("03 - multi repeated", ['-verbose','-verbose'], '-verbose', '', {}, {verbose=>2}, [], 1);
run_test("04 - bundled switches", ['-vh'], '-v -h', '', {}, {v=>1,h=>1}, [], 1);
run_test("05 - bundled repeat", ['-vvv'], '-v', '', {}, {v=>3}, [], 1);
run_test("06 - option separate", ['-dir','/tmp'], '', '-dir', {}, {dir=>'/tmp'}, [], 1);
run_test("07 - multi option", ['-header','x'], '', '-header', {}, {header=>'x'}, [], 1);
run_test("08 - bundled option last", ['-vd','/tmp'], '-v', '-d', {}, {v=>1,d=>'/tmp'}, [], 1);
run_test("09 - repeated array", ['-f','a','-f','b'], '', '-f', {f=>[]}, {f=>['a','b']}, [], 1);
run_test("10 - repeated scalar", ['-f','a','-f','b'], '', '-f', {}, {f=>'b'}, [], 1);

run_test("11 - unknown single", ['-x'], '-v', '', {}, {v=>0}, ['-x'], 0);
run_test("12 - unknown multi", ['-debug'], '-v', '', {}, {v=>0}, ['-debug'], 0);
run_test("13 - unknown in bundle", ['-vx'], '-v', '', {}, {v=>1}, ['-vx'], 0);  # v incremented, whole bundle rejected
run_test("14 - option not last", ['-dv','/tmp'], '-v', '-d', {}, {v=>0,d=>''}, ['-dv','/tmp'], 0);
run_test("15 - missing arg", ['-dir'], '', '-dir', {}, {dir=>''}, ['-dir'], 0);

run_test("16 - -- ends", ['-v','--','-file.txt'], '-v', '', {}, {v=>1}, ['-file.txt'], 1);
run_test("17 - lone dash", ['-'], '-v', '', {}, {v=>0}, ['-'], 1);
run_test("18 - positional only", ['a.txt'], '', '', {}, {}, ['a.txt'], 1);
run_test("19 - auto defaults", ['-v'], '-v -h', '-dir', {}, {v=>1,h=>0,dir=>''}, [], 1);
run_test("20 - mixed", ['-vh','-header','x','file.txt'], '-v -h', '-header', {}, {v=>1,h=>1,header=>'x'}, ['file.txt'], 1);

run_test("21 - ambiguous full wins", ['-ver'], '-ver', '', {}, {ver=>1}, [], 1);
run_test("22 - ambiguous bundle if no full", ['-ver'], '-v -e -r', '', {}, {v=>1,e=>1,r=>1}, [], 1);
run_test("23 - longer full wins", ['-verb'], '-verb -v', '', {}, {verb=>1,v=>0}, [], 1);
run_test("24 - unknown middle bundle", ['-vxy'], '-v -y', '', {}, {v=>1,y=>0}, ['-vxy'], 0);
run_test("25 - option middle bundle", ['-vdx','/tmp'], '-v -x', '-d', {}, {v=>1,x=>0,d=>''}, ['-vdx','/tmp'], 0);
run_test("26 - bundle option no arg", ['-vd'], '-v', '-d', {}, {v=>1,d=>''}, ['-vd'], 0);
run_test("27 - valid multi not bundled", ['-help'], '-help', '', {}, {help=>1}, [], 1);
run_test("28 - single option not last", ['-fda','val'], '', '-f -d', {}, {f=>'',d=>''}, ['-fda','val'], 0);
run_test("29 - valid and unknown bundle", ['-vux'], '-v -u', '', {}, {v=>1,u=>1}, ['-vux'], 0);
run_test("30 - overlong bundle no full", ['-abcd'], '-a -b', '', {}, {a=>1,b=>1}, ['-abcd'], 0);
run_test("31 - full overrides singles", ['-on'], '-on -o -n', '', {}, {on=>1,o=>0,n=>0}, [], 1);
run_test("32 - case sensitive", ['-V'], '-v', '', {}, {v=>0}, ['-V'], 0);

# === TESTS FOR LONG OPTIONS AND = SUPPORT ===
run_test("33 - long switch", ['--verbose'], '--verbose', '', {}, {verbose=>1}, [], 1);
run_test("34 - long switch repeated", ['--verbose','--verbose'], '--verbose', '', {}, {verbose=>2}, [], 1);
run_test("35 - long option separate arg", ['--output','out.txt'], '', '--output', {}, {output=>'out.txt'}, [], 1);
run_test("36 - long option attached =", ['--output=out.txt'], '', '--output', {}, {output=>'out.txt'}, [], 1);
run_test("37 - long option empty =", ['--output='], '', '--output', {}, {output=>''}, [], 1);
run_test("38 - long option = with space (invalid)", ['--output=','out.txt'], '', '--output', {}, {output=>''}, ['out.txt'], 1);  # treats '=' as empty value
run_test("39 - repeated long option array", ['--header','a','--header=b'], '', '--header', {header=>[]}, {header=>['a','b']}, [], 1);
run_test("40 - repeated long option scalar", ['--file','x','--file=y'], '', '--file', {}, {file=>'y'}, [], 1);
run_test("41 - mixed short and long", ['-v','--header','title.txt','data.txt'], '-v', '--header', {}, {v=>1,header=>'title.txt'}, ['data.txt'], 1);
run_test("42 - mixed bundled and long", ['-vh','--output=out.log'], '-v -h', '--output', {}, {v=>1,h=>1,output=>'out.log'}, [], 1);
run_test("43 - long switch with short bundle", ['--verbose','-vh'], '--verbose -v -h', '', {}, {verbose=>1,v=>1,h=>1}, [], 1);
run_test("44 - long option attached with short", ['-v','--output=file.txt'], '-v', '--output', {}, {v=>1,output=>'file.txt'}, [], 1);

# === Error cases for long options ===
run_test("45 - unknown long switch", ['--unknown'], '--verbose', '', {}, {verbose=>0}, ['--unknown'], 0);
run_test("46 - unknown long option", ['--debug','val'], '', '--output', {}, {output=>''}, ['--debug','val'], 0);
run_test("47 - long option missing arg separate", ['--output'], '', '--output', {}, {output=>''}, ['--output'], 0);
run_test("48 - long option missing after =", ['--output='], '', '--output', {}, {output=>''}, [], 1);  # empty is allowed
run_test("49 - long option = but no value and no next", ['--output='], '', '--output', {}, {output=>''}, [], 1);
run_test("50 - long switch with = (treated as unknown)", ['--verbose=3'], '--verbose', '', {}, {verbose=>0}, ['--verbose=3'], 0);
run_test("51 - long option with = but unknown", ['--debug=val'], '', '--output', {}, {output=>''}, ['--debug=val'], 0);

# === Combination edge cases ===
run_test("52 - long and short same name conflict (long wins if --)", ['--v'], '-v --v', '', {}, {v=>1}, [], 1);  # --v matches long v
run_test("53 - short v and long verbose", ['-v','--verbose'], '-v --verbose', '', {}, {v=>1,verbose=>1}, [], 1);
run_test("54 - -- ends after long", ['--verbose','--','--secret'], '--verbose', '', {}, {verbose=>1}, ['--secret'], 1);

had_no_warnings();
done_testing();
