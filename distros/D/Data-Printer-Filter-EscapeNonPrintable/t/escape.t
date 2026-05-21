#!perl
#
# Test if DDP's missing chars (ASCII control chars + DEL) get escaped and colorized correctly.
# Based on https://github.com/garu/Data-Printer/blob/379f0cecc3c1ec0bfb10b38b780f940bb2865c66/t/002-scalar.t#L151.

use v5.26.0;

use strict;
use warnings;

use Test2::V1 qw< subtest is >;

use Data::Printer::Object;
use Data::Printer::Filter;

subtest 'Test escaping of missing chars' => sub {
    my $ddp = Data::Printer::Object->new(
        colored       => 0,
        print_escapes => 1,
        filters       => [ qw< EscapeNonPrintable > ],
    );

    my $MISSING_CHARS =
      "\x{01}\x{02}\x{03}\x{04}\x{05}\x{06}\x{0b}\x{0e}\x{0f}\x{10}\x{11}\x{12}\x{13}\x{14}\x{15}\x{16}\x{17}\x{18}\x{19}\x{1a}\x{1c}\x{1d}\x{1e}\x{1f}\x{7f}";

    my $parsed = $ddp->parse( \$MISSING_CHARS );

    is(
        $parsed,
        q{"\001\002\003\004\005\006\v\016\017\020\021\022\023\024\025\026\027\030\031\032\034\035\036\037\177"},
        'escaped missing chars (ASCII control chars + DEL)',
    );

    T2->note($parsed);
};

subtest 'Test colors from escaped missing chars' => sub {
    # Make sure color output is consistent, because DDP changes its colors theme
    # depth based on TTY environment variables.
    local $ENV{COLORTERM} = 'truecolor';

    my %TESTS = (
        A => {
            got      => "foo\x{0b}bar\x{7f}",
            expected =>
              qq{\e[0;38;2;102;217;239m"\e[m\e[0;38;2;144;181;90mfoo\e[0;38;2;0;150;136m\\v\e[0;38;2;144;181;90mbar\e[0;38;2;0;150;136m\\177\e[0;38;2;144;181;90m\e[m\e[0;38;2;102;217;239m"\e[m},
        },
        B => {
            got      => "\x{0b}foo\x{0b}bar\x{7f}xyz\x{0b}",
            expected =>
              qq{\e[0;38;2;102;217;239m"\e[m\e[0;38;2;144;181;90m\e[0;38;2;0;150;136m\\v\e[0;38;2;144;181;90mfoo\e[0;38;2;0;150;136m\\v\e[0;38;2;144;181;90mbar\e[0;38;2;0;150;136m\\177\e[0;38;2;144;181;90mxyz\e[0;38;2;0;150;136m\\v\e[0;38;2;144;181;90m\e[m\e[0;38;2;102;217;239m"\e[m},
        },
        C => {
            got      => "\x{7f}foo\x{0b}\x{0b}bar\x{0b}\x{7f}\x{0b}\x{0b}\x{7f}\x{7f}xyz\x{0b}",
            expected =>
              qq{\e[0;38;2;102;217;239m"\e[m\e[0;38;2;144;181;90m\e[0;38;2;0;150;136m\\177\e[0;38;2;144;181;90mfoo\e[0;38;2;0;150;136m\\v\\v\e[0;38;2;144;181;90mbar\e[0;38;2;0;150;136m\\v\e[0;38;2;144;181;90m\e[0;38;2;0;150;136m\\177\e[0;38;2;144;181;90m\e[0;38;2;0;150;136m\\v\\v\e[0;38;2;144;181;90m\e[0;38;2;0;150;136m\\177\\177\e[0;38;2;144;181;90mxyz\e[0;38;2;0;150;136m\\v\e[0;38;2;144;181;90m\e[m\e[0;38;2;102;217;239m"\e[m},
        },
    );

    my $ddp = Data::Printer::Object->new(
        colored       => 1,
        theme         => 'Material',
        print_escapes => 1,
        filters       => [ qw< EscapeNonPrintable > ],
    );

    foreach my $t ( sort keys %TESTS ) {
        my $parsed = $ddp->parse( \$TESTS{$t}{got} );

        is(
            $parsed, $TESTS{$t}{expected},
            "string match ($parsed)",
        );
    }
};

subtest 'Test decoration' => sub {
    my $ddp = Data::Printer::Object->new(
        colored       => 0,
        print_escapes => 1,
    );

    my $REF = \"foo\x{0b}bar\x{7f}";
    my $str = Data::Printer::Filter::EscapeNonPrintable::parse( $REF, $ddp );

    is(
        $str, q{"foo\vbar\177"},
        "string match ($str)",
    );
};

T2->done_testing;
