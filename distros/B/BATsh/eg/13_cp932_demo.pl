#!/usr/bin/perl
######################################################################
#
# 13_cp932_demo.pl - run a CP932 (Shift_JIS) .batsh script with BATsh
#
# Demonstrates BATsh 0.07 multibyte support for Japanese Windows.
# The demo script below contains "dame-moji": very common CP932
# characters whose SECOND byte collides with an ASCII shell
# metacharacter, and which byte-oriented shells corrupt:
#
#   SO   0x83 0x5C  (trail = backslash)
#   HYOU 0x95 0x5C  (trail = backslash)
#   PO   0x83 0x7C  (trail = pipe)
#   CHI  0x83 0x60  (trail = backtick)
#   DA   0x83 0x5E  (trail = caret, the cmd.exe escape)
#
# This .pl file itself stays US-ASCII by writing the CP932 bytes as
# \xNN escapes; on a real Japanese Windows machine you would simply
# save your .batsh file in CP932 (Shift_JIS / ANSI) and run:
#
#   perl lib/BATsh.pm nihongo.batsh
#
# The encoding is auto-detected; --encoding=cp932 forces it.
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use BATsh;

my $SO    = "\x83\x5C";              # katakana SO
my $FU    = "\x83\x74";              # katakana FU
my $TO    = "\x83\x67";              # katakana TO
my $HYOU  = "\x95\x5C";              # kanji "table/front"
my $DA    = "\x83\x5E";              # katakana DA
my $ME    = "\x83\x81";              # katakana ME
my $SOFT  = $SO . $FU . $TO;         # "SOFUTO"
my $DAME  = $DA . $ME;               # "DAME"

my $script = join("\n",
    ':: CMD section: CP932 value with a 0x5C trail byte',
    "SET NAME=$SOFT",
    'ECHO CMD says: %NAME%',
    'ECHO first char: %NAME:~0,1%',
    '',
    '# SH section: same value through the Env bridge',
    'echo sh says: $NAME',
    'echo length in characters: ${#NAME}',
    "X=$DAME$HYOU",
    'case $X in',
    "    $DA*) echo case matched: \$X ;;",
    '    *) echo case fell through ;;',
    'esac',
    '',
);

BATsh->run_string($script, encoding => 'cp932');
