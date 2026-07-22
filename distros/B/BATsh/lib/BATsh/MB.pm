package BATsh::MB;
######################################################################
#
# BATsh::MB - Multibyte (DBCS) script guard for BATsh
#
# https://metacpan.org/dist/BATsh
#
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com>
#
######################################################################
#
# THE PROBLEM (the classic "0x5C problem" of CP932 aka DAME-MOJI)
#
# In double-byte character sets such as CP932 (Shift_JIS as used on
# Japanese Windows), the SECOND byte of a two-byte character may fall
# in the ASCII range 0x40-0x7E.  That range contains shell
# metacharacters:
#
#   \  0x5C   escape character / path separator   (SO, HYOU, NOH, ...)
#   |  0x7C   pipeline separator                  (PO, BO, ...)
#   `  0x60   command substitution                (CHI, ...)
#   ^  0x5E   cmd.exe escape character            (DA, ...)
#   {  0x7B   }  0x7D   [  0x5B   ]  0x5D   ~  0x7E   @  0x40
#   A-Z a-z   (corrupted by uc/lc on variable names and values)
#
# A byte-oriented parser that scans for these characters will tear a
# two-byte character in half: "ECHO <SO>FUTO" loses a byte to caret
# unescaping, "echo <PO>INTO | cmd" splits the pipeline in the middle
# of a character, and so on.
#
# THE SOLUTION (guard transform)
#
# Rather than teaching every scanner in BATsh::CMD / BATsh::SH about
# lead and trail bytes, the script text is passed through a reversible
# GUARD TRANSFORM on input:
#
#   LEAD TRAIL              (TRAIL in the dangerous 0x40-0x7E range)
#     is rewritten to
#   \x01 LEAD (TRAIL+0x80)  (three bytes, no ASCII metacharacters)
#
#   a literal \x01 byte (never present in real scripts) is rewritten
#   to \x01\x01 so that the transform is bijective.
#
# Two-byte characters whose trail byte is already >= 0x80 are left
# unchanged (they contain no ASCII bytes and are harmless).  After the
# transform, NO byte of any multibyte character is an ASCII
# metacharacter, so every existing byte-oriented scanner in BATsh is
# automatically DBCS-safe.  The inverse transform (decode) is applied
# at the output boundaries: print, external command execution,
# filesystem calls, and %ENV export.
#
# Because uc()/lc() never modify bytes >= 0x80 and the guard moves all
# ASCII trail bytes up into 0xC0-0xFE, case conversion of guarded text
# (variable-name uppercasing in BATsh::Env, ${VAR^^}, ...) is also
# safe as a side effect.
#
# SUPPORTED ENCODINGS
#
#   cp932  (aliases: sjis, shiftjis, shift_jis, shift-jis, 932)
#   gbk    (aliases: cp936, 936)
#   uhc    (aliases: cp949, ksc5601, 949)
#   big5   (aliases: cp950, 950)
#   utf8   (aliases: utf-8)   -- pass-through: UTF-8 trail bytes are
#                                all >= 0x80 and need no guarding
#   none   (aliases: ascii, us-ascii, binary)  -- pass-through
#   auto   -- detect from the script source (see detect() below)
#
######################################################################

use 5.00503;
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use vars qw($VERSION);
$VERSION = '0.07';
$VERSION = $VERSION;

use vars qw($ENCODING $ACTIVE $ACTIVE_ENC $LEAD $TRAIL $DANGER);

# Requested encoding ('auto' until told otherwise) and the currently
# ACTIVE guard.  Under 'auto' the guard is switched on when a DBCS
# source is detected and is then STICKY: a later pure-ASCII run_string
# does not switch it off, because Env may still hold guarded values
# from the earlier script.  Only an explicit set_encoding() call
# deactivates the guard.
$ENCODING   = 'auto';
$ACTIVE     = 0;
$ACTIVE_ENC = '';

# Per-encoding byte classes (as character-class body strings).
#   lead   : first byte of a two-byte character
#   trail  : any valid second byte
#   danger : second bytes that are also ASCII metacharacter candidates
my %ENC_TABLE = (
    'cp932' => {
        lead   => "\x81-\x9f\xe0-\xfc",
        trail  => "\x40-\x7e\x80-\xfc",
        danger => "\x40-\x7e",
    },
    'gbk' => {
        lead   => "\x81-\xfe",
        trail  => "\x40-\x7e\x80-\xfe",
        danger => "\x40-\x7e",
    },
    'uhc' => {
        lead   => "\x81-\xfe",
        trail  => "\x41-\x5a\x61-\x7a\x81-\xfe",
        danger => "\x41-\x5a\x61-\x7a",
    },
    'big5' => {
        lead   => "\x81-\xfe",
        trail  => "\x40-\x7e\xa1-\xfe",
        danger => "\x40-\x7e",
    },
);

my %ALIAS = (
    'cp932'     => 'cp932',
    'sjis'      => 'cp932',
    'shiftjis'  => 'cp932',
    'shift_jis' => 'cp932',
    'shift-jis' => 'cp932',
    '932'       => 'cp932',
    'gbk'       => 'gbk',
    'cp936'     => 'gbk',
    '936'       => 'gbk',
    'uhc'       => 'uhc',
    'cp949'     => 'uhc',
    'ksc5601'   => 'uhc',
    '949'       => 'uhc',
    'big5'      => 'big5',
    'cp950'     => 'big5',
    '950'       => 'big5',
    'utf8'      => 'utf8',
    'utf-8'     => 'utf8',
    'none'      => 'none',
    'ascii'     => 'none',
    'us-ascii'  => 'none',
    'binary'    => 'none',
    'auto'      => 'auto',
);

# ----------------------------------------------------------------
# set_encoding: select the requested encoding
#   'auto'          detect per script (sticky activation)
#   a DBCS name     activate the guard now
#   'utf8'/'none'   deactivate the guard now
# Returns the canonical name; dies on an unknown encoding.
# ----------------------------------------------------------------
sub set_encoding {
    my $enc = defined $_[0] && $_[0] !~ /\ABATsh::MB\z/ ? $_[0] : $_[1];
    $enc = 'auto' unless defined $enc && $enc ne '';
    my $canon = $ALIAS{lc $enc};
    unless (defined $canon) {
        require Carp;
        Carp::croak("BATsh::MB: unknown encoding '$enc' (supported: " .
            "cp932 sjis gbk uhc big5 utf8 none auto)");
    }
    $ENCODING = $canon;
    if    ($canon eq 'auto')                 { }               # sticky
    elsif (exists $ENC_TABLE{$canon})        { _activate($canon) }
    else                                     { _deactivate() }  # utf8/none
    return $canon;
}

sub encoding  { return $ENCODING }
sub active    { return $ACTIVE ? $ACTIVE_ENC : '' }

sub _activate {
    my ($canon) = @_;
    my $t = $ENC_TABLE{$canon};
    $LEAD       = $t->{lead};
    $TRAIL      = $t->{trail};
    $DANGER     = $t->{danger};
    $ACTIVE     = 1;
    $ACTIVE_ENC = $canon;
}

sub _deactivate {
    $ACTIVE     = 0;
    $ACTIVE_ENC = '';
}

# ----------------------------------------------------------------
# detect: guess the encoding of a chunk of script source (bytes)
#   no bytes >= 0x80          -> 'none'
#   well-formed UTF-8         -> 'utf8'
#   otherwise                 -> 'cp932'
# The UTF-8 test is structural (RFC 3629 sequence forms), written
# byte-wise so it runs identically from Perl 5.005_03 onward.
# ----------------------------------------------------------------
sub detect {
    my $src = defined $_[0] && $_[0] !~ /\ABATsh::MB\z/ ? $_[0] : $_[1];
    return 'none' unless defined $src;
    return 'none' unless $src =~ /[\x80-\xff]/;
    return _valid_utf8($src) ? 'utf8' : 'cp932';
}

sub _valid_utf8 {
    my ($s) = @_;
    my $i = 0;
    my $n = length($s);
    while ($i < $n) {
        my $o = ord(substr($s, $i, 1));
        if    ($o < 0x80) { $i++ }
        elsif ($o >= 0xC2 && $o <= 0xDF) {
            return 0 unless _cont($s, $i + 1, 1); $i += 2;
        }
        elsif ($o == 0xE0) {
            return 0 unless _rng($s, $i+1, 0xA0, 0xBF) && _cont($s, $i+2, 1);
            $i += 3;
        }
        elsif ($o >= 0xE1 && $o <= 0xEF) {
            return 0 unless _cont($s, $i + 1, 2); $i += 3;
        }
        elsif ($o == 0xF0) {
            return 0 unless _rng($s, $i+1, 0x90, 0xBF) && _cont($s, $i+2, 2);
            $i += 4;
        }
        elsif ($o >= 0xF1 && $o <= 0xF4) {
            return 0 unless _cont($s, $i + 1, 3); $i += 4;
        }
        else { return 0 }
    }
    return 1;
}

sub _cont {
    my ($s, $i, $count) = @_;
    for my $k (0 .. $count - 1) {
        return 0 if $i + $k >= length($s);
        my $o = ord(substr($s, $i + $k, 1));
        return 0 unless $o >= 0x80 && $o <= 0xBF;
    }
    return 1;
}

sub _rng {
    my ($s, $i, $lo, $hi) = @_;
    return 0 if $i >= length($s);
    my $o = ord(substr($s, $i, 1));
    return ($o >= $lo && $o <= $hi) ? 1 : 0;
}

# ----------------------------------------------------------------
# activate_for: called by BATsh with the raw script source before it
# is executed.  Under 'auto', detection may switch the guard ON (and
# it then stays on -- see the stickiness note above).  Under an
# explicit encoding the guard state is already fixed by set_encoding.
# ----------------------------------------------------------------
sub activate_for {
    my $src = defined $_[0] && $_[0] !~ /\ABATsh::MB\z/ ? $_[0] : $_[1];
    if ($ENCODING eq 'auto') {
        my $det = detect($src);
        _activate($det) if exists $ENC_TABLE{$det};
    }
    return $ACTIVE;
}

# ----------------------------------------------------------------
# enc: apply the guard transform (raw DBCS bytes -> guarded form)
# dec: remove the guard transform  (guarded form -> raw DBCS bytes)
# Both are identity functions while the guard is inactive, so that
# ASCII and UTF-8 operation is entirely unaffected.
# ----------------------------------------------------------------
sub enc {
    my ($s) = @_;
    return $s unless $ACTIVE && defined $s;
    return $s unless $s =~ /[\x01\x81-\xfe]/;
    $s =~ s/\x01/\x01\x01/g;
    # Deliberately NOT /o: the classes change when the active encoding
    # changes, so the substitution must be recompiled per call.
    $s =~ s/([$LEAD])([$TRAIL])/
        do {
            my ($lb, $tb) = ($1, $2);
            $tb =~ m<\A[$DANGER]\z>
                ? "\x01" . $lb . chr(ord($tb) + 0x80)
                : $lb . $tb
        }
    /gex;
    return $s;
}

sub dec {
    my ($s) = @_;
    return $s unless $ACTIVE && defined $s;
    return $s unless index($s, "\x01") >= 0;
    $s =~ s/\x01(\x01|[$LEAD][\xc0-\xfe])/
        $1 eq "\x01"
            ? "\x01"
            : substr($1, 0, 1) . chr(ord(substr($1, 1, 1)) - 0x80)
    /gex;
    return $s;
}

# ----------------------------------------------------------------
# Character-oriented helpers, operating on GUARDED strings.
# While the guard is inactive they fall back to byte semantics, so
# existing ASCII behaviour is preserved bit-for-bit.
#
#   mb_length($guarded)             -> number of characters
#   mb_substr($guarded, $off, $len) -> guarded substring by characters
#       $off may be negative (counts back from the end, like substr);
#       $len may be omitted (rest of string).
# ----------------------------------------------------------------
sub mb_length {
    my ($s) = @_;
    return 0 unless defined $s;
    return length($s) unless $ACTIVE;
    my $chars = _mb_chars(dec($s));
    return scalar @{$chars};
}

sub mb_substr {
    my ($s, $off, $len) = @_;
    return '' unless defined $s;
    unless ($ACTIVE) {
        return defined $len ? substr($s, $off, $len) : substr($s, $off);
    }
    my $chars = _mb_chars(dec($s));
    my $n = scalar @{$chars};
    $off = $n + $off if $off < 0;
    $off = 0 if $off < 0;
    return '' if $off >= $n;
    my $end = defined $len ? $off + $len : $n;
    $end = $n if $end > $n;
    return '' if $end <= $off;
    return enc(join('', @{$chars}[$off .. $end - 1]));
}

# Split RAW (decoded) DBCS bytes into characters, forward-scanning:
# a lead byte followed by a valid trail byte forms one two-byte
# character; anything else is a single byte.
sub _mb_chars {
    my ($s) = @_;
    my @c = ();
    my $i = 0;
    my $n = length($s);
    while ($i < $n) {
        my $b = substr($s, $i, 1);
        if ($b =~ /[$LEAD]/ && $i + 1 < $n
            && substr($s, $i + 1, 1) =~ /[$TRAIL]/) {
            push @c, substr($s, $i, 2);
            $i += 2;
        }
        else {
            push @c, $b;
            $i++;
        }
    }
    return [ @c ];
}

# ----------------------------------------------------------------
# strip_bom: remove a UTF-8 byte-order mark from the head of the
# first script line (harmless everywhere, required for editors that
# save UTF-8-with-BOM).
# ----------------------------------------------------------------
sub strip_bom {
    my $s = defined $_[0] && $_[0] !~ /\ABATsh::MB\z/ ? $_[0] : $_[1];
    return $s unless defined $s;
    $s =~ s/\A\xef\xbb\xbf//;
    return $s;
}

1;

__END__

=head1 NAME

BATsh::MB - Multibyte (CP932/DBCS) script guard for BATsh

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

  use BATsh;

  # Explicit encoding
  BATsh->run('nihongo.batsh', encoding => 'cp932');

  # Or rely on auto-detection (the default):
  # a non-UTF-8 script containing bytes >= 0x80 is treated as CP932
  BATsh->run('nihongo.batsh');

  # Environment-variable override
  #   set BATSH_ENCODING=cp932

=head1 DESCRIPTION

BATsh::MB makes BATsh safe for scripts written in CP932 (Shift_JIS as
used on Japanese Windows) and other double-byte character sets whose
trail bytes overlap the ASCII range 0x40-0x7E.

Without protection, byte-oriented shell parsing tears such characters
apart: the trail byte 0x5C is mistaken for a backslash escape or path
separator, 0x7C for a pipeline separator, 0x60 for a backtick, 0x5E
for the cmd.exe caret escape, and uc()/lc() corrupt trail bytes in the
a-z range.  This is the well-known "dame-moji" problem affecting very
common characters such as SO (0x835C), HYOU (0x955C), NOH (0x945C),
PO (0x837C), CHI (0x8360), and DA (0x835E).

Rather than teaching every scanner about lead/trail bytes, BATsh::MB
applies a reversible guard transform on input: each two-byte character
whose trail byte falls in the dangerous ASCII range is rewritten to a
three-byte form C<\x01 LEAD (TRAIL+0x80)> containing no ASCII bytes.
The inverse transform is applied at output boundaries (print, external
commands, filesystem calls, %ENV export).  Between the two, all of
BATsh's byte-oriented parsing is automatically DBCS-safe.

=head1 FUNCTIONS

=over 4

=item set_encoding(ENC)

Select the encoding: cp932 (sjis), gbk, uhc, big5, utf8, none, auto.

=item detect(BYTES)

Return 'none', 'utf8', or 'cp932' for a chunk of script source.

=item enc(STR) / dec(STR)

Apply / remove the guard transform.  Identity while inactive.

=item mb_length(STR) / mb_substr(STR, OFF, LEN)

Character-based length and substring on guarded strings.  These give
C<${#VAR}>, C<${VAR:N:L}>, and C<%VAR:~n,m%> character semantics for
DBCS text (byte semantics, unchanged, while the guard is inactive).

=back

=head1 SUPPORTED PERL VERSIONS

Perl 5.00503 or later.

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
