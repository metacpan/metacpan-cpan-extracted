######################################################################
#
# 0001-classify.t  Mode detection and line parsing unit tests
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

eval { require BATsh } or die "Cannot load BATsh: $@";

my @tests = (
    # classify_token -- CMD
    sub { _ok(BATsh::classify_token('ECHO')     eq 'CMD', 'ECHO => CMD') },
    sub { _ok(BATsh::classify_token('SET')      eq 'CMD', 'SET => CMD') },
    sub { _ok(BATsh::classify_token('IF')       eq 'CMD', 'IF => CMD') },
    sub { _ok(BATsh::classify_token('FOR')      eq 'CMD', 'FOR => CMD') },
    sub { _ok(BATsh::classify_token('GOTO')     eq 'CMD', 'GOTO => CMD') },
    sub { _ok(BATsh::classify_token('CALL')     eq 'CMD', 'CALL => CMD') },
    sub { _ok(BATsh::classify_token('SETLOCAL') eq 'CMD', 'SETLOCAL => CMD') },
    sub { _ok(BATsh::classify_token('@ECHO')    eq 'CMD', '@ECHO => CMD') },
    sub { _ok(BATsh::classify_token('%VAR%')    eq 'CMD', '%VAR% => CMD') },
    # classify_token -- SH
    sub { _ok(BATsh::classify_token('echo')     eq 'SH', 'echo => SH') },
    sub { _ok(BATsh::classify_token('for')      eq 'SH', 'for => SH') },
    sub { _ok(BATsh::classify_token('export')   eq 'SH', 'export => SH') },
    sub { _ok(BATsh::classify_token('if')       eq 'SH', 'if => SH') },
    sub { _ok(BATsh::classify_token('.')        eq 'SH', '. => SH') },
    sub { _ok(BATsh::classify_token('Echo')     eq 'SH', 'Echo (mixed) => SH') },
    # _parse_line
    sub { my ($m) = BATsh::_parse_line('');
          _ok($m eq 'EMPTY', '_parse_line empty => EMPTY') },
    sub { my ($m) = BATsh::_parse_line('   ');
          _ok($m eq 'EMPTY', '_parse_line spaces => EMPTY') },
    sub { my ($m) = BATsh::_parse_line(':: comment');
          _ok($m eq 'COMMENT', '_parse_line :: => COMMENT') },
    sub { my ($m) = BATsh::_parse_line('REM remark');
          _ok($m eq 'COMMENT', '_parse_line REM => COMMENT') },
    sub { my ($m) = BATsh::_parse_line('@REM remark');
          _ok($m eq 'COMMENT', '_parse_line @REM => COMMENT') },
    sub { my ($m) = BATsh::_parse_line('# sh comment');
          _ok($m eq 'COMMENT', '_parse_line # => COMMENT') },
    sub { my ($m) = BATsh::_parse_line('#!/bin/sh');
          _ok($m eq 'SH', '_parse_line #! shebang => SH') },
    sub { my ($m, undef, $f) = BATsh::_parse_line('ECHO hello');
          _ok($m eq 'CMD' && $f eq 'ECHO', '_parse_line ECHO => CMD') },
    sub { my ($m, undef, $f) = BATsh::_parse_line('echo hello');
          _ok($m eq 'SH'  && $f eq 'echo', '_parse_line echo => SH') },
    sub { my ($m, undef, $f) = BATsh::_parse_line('SET FOO=bar baz');
          _ok($m eq 'CMD' && $f eq 'SET', '_parse_line SET => CMD') },
    sub { my ($m, undef, $f) = BATsh::_parse_line('export FOO=bar');
          _ok($m eq 'SH'  && $f eq 'export', '_parse_line export => SH') },
    # depth tracking
    sub { _ok(BATsh::_cmd_paren_delta('IF X (') ==  1, 'paren ( => +1') },
    sub { _ok(BATsh::_cmd_paren_delta(')')       == -1, 'paren ) => -1') },
    sub { _ok(BATsh::_cmd_paren_delta('ECHO hi') ==  0, 'paren none => 0') },
    sub { _ok(BATsh::_cmd_paren_delta('echo "a(b)"') == 0, 'paren quoted => 0') },
    sub { _ok(BATsh::_sh_depth_delta('if')    ==  1, 'sh if => +1') },
    sub { _ok(BATsh::_sh_depth_delta('for')   ==  1, 'sh for => +1') },
    sub { _ok(BATsh::_sh_depth_delta('while') ==  1, 'sh while => +1') },
    sub { _ok(BATsh::_sh_depth_delta('fi')    == -1, 'sh fi => -1') },
    sub { _ok(BATsh::_sh_depth_delta('done')  == -1, 'sh done => -1') },
    sub { _ok(BATsh::_sh_depth_delta('esac')  == -1, 'sh esac => -1') },
    sub { _ok(BATsh::_sh_depth_delta('then')  ==  0, 'sh then => 0') },
    sub { _ok(BATsh::_sh_depth_delta('else')  ==  0, 'sh else => 0') },
    sub { _ok(BATsh::_sh_depth_delta('echo')  ==  0, 'sh echo => 0') },
);

print "1.." . scalar(@tests) . "\n";
my ($run, $fail) = (0, 0);
sub _ok {
    my ($ok, $name) = @_;
    $run++; $fail++ unless $ok;
    print +($ok ? '' : 'not ') . "ok $run - $name\n";
}
$_->() for @tests;
END { exit 1 if $fail }
