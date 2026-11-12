use 5.012;
use strict;
use warnings;
use Test::More;
use Data::Dump::Streamer qw(Dump regex :undump);

our $DUMP_INTERPOLATED;
my @sources= (
    q(@{[ $main::DUMP_INTERPOLATED++ ]}),
    q(${[ $main::DUMP_INTERPOLATED++ ]}),
    q(${[1]}),   q(${ [ $main::DUMP_INTERPOLATED++ ]}),
    q(@{2}),     q(${2}),     q(@{ 1,2 }), q(${ 1,2 }),
    q(@{1,}),    q(${1,}),    q(@[1]),     q($[1]),
    q(@{[[1]]}), q(${[[1]]}), q(@{{2}),    q(${{2}),
    q(@foo),     q($foo),     q($|),       q($\w),  q($\b), q($!),
    q(\@{x}),    q(\${x}),    q[($)],      q[$(a)], q[$ ],  q[$],
    q(a/b),      q(a!b),      q(a%b),      q(a&b),  q(a<b), q(a>b),
    q(a"b),      q(a#b),      q(/!%&<>"#),
);
for my $slashes (2 .. 4) {
    for my $suffix ('@foo', '$foo', '@{x}', '${x}', '@[1]', '$[1]', '/a', '!a')
    {
        push @sources, ('\\' x $slashes) . $suffix;
    }
}

my @subjects= (
    '',     '@',   '@@',       '@@@',     '$',      '$$',
    '@{2}', '@{{', '${2}',     '${[1]}',  '@{[1]}', '@[1]',
    '1',    'foo', '@foo',     '$foo',    '/a',     '!a',
    'a/b',  'a!b', 'a%b',      'a&b',     'a<b',    'a>b',
    'a"b',  'a#b', '/!%&<>"#', "\\\@foo", "\\\$foo"
);

for my $source (@sources) {
    SKIP: {
        my $regexp;
        {
            no warnings;
            $regexp= eval { qr/$source/ };
        }

        # Perl releases differ on whether these literal-brace patterns exist.
        # Skip only rejected inputs; errors evaluating a DDS dump still fail.
        skip "This Perl rejects the original pattern: $source", 2 + @subjects
            if $@;
        local $DUMP_INTERPOLATED= 0;
        my $dump= Dump($regexp)->Terse(1)->Out;
        my $restored;
        {
            no warnings;
            local $\= 'THIS MUST NOT BE INTERPOLATED';
            $restored= eval $dump;
        }
        is($@, '', "output evaluates for $source") or diag $dump;
        is($DUMP_INTERPOLATED, 0,
            "output does not execute interpolation for $source");
        if (ref($restored) eq 'Regexp') {
            for my $subject (@subjects) {
                is(
                    !!($subject =~ $restored),
                    !!($subject =~ $regexp),
                    "match preserved for $source against $subject"
                );
            }
        }
    }
}

for my $source ("a # a comment\nb", "a\tb", "a\rb", "a\0b", "\x{100}/\x{263a}")
{
    for my $extended (0, 1) {
        my $regexp= $extended ? qr/$source/x : qr/$source/;
        my $dump= Dump($regexp)->Terse(1)->Out;
        my $restored= eval $dump;
        is($@, '', "output evaluates with extended=$extended") or diag $dump;
        next unless ref($restored) eq 'Regexp';
        for my $subject ('ab', "a\tb", "a\rb", "a\0b", $source, 'a', 'b') {
            is(
                !!($subject =~ $restored),
                !!($subject =~ $regexp),
                "extended=$extended match preserved"
            );
        }
    }
}

{
    my @extended_modes= ('x');
    push @extended_modes, 'xx' if $] >= 5.026;

    for my $codepoint (0x85, 0x200e, 0x200f, 0x2028, 0x2029) {
        my $source= 'a' . chr($codepoint) . 'b';
        utf8::upgrade($source);

        for my $mode (@extended_modes) {

            # Compile /xx dynamically so the test still parses before 5.26.
            my $original= eval 'qr/$source/' . $mode;
            die $@ if $@;
            my $label= sprintf 'U+%04X /%s', $codepoint, $mode;
            my $text= Dump($original)->Terse(1)->Out;
            my $copy= eval $text;
            is($@, '', "$label: output evaluates") or diag $text;
            isa_ok($copy, 'Regexp', "$label: restored pattern");
            next unless ref($copy) eq 'Regexp';

            for my $subject ('ab', $source, 'acb') {
                is(
                    !!($subject =~ $copy),
                    !!($subject =~ $original),
                    "$label: whitespace matching survives"
                ) or diag $text;
            }
        }
    }
}

{
    # Keep this test free of a caller-side use utf8, which would mask an
    # unflagged source string containing raw UTF-8 bytes.
    for my $codepoint (0x263a, 0x1f642) {
        my $character= chr($codepoint);
        my $source= 'a\\' . $character . 'b';
        my $original= qr/$source/;
        my $label= sprintf 'escaped U+%04X', $codepoint;
        ok("a${character}b" =~ $original, "$label: original matches");

        my $text= Dump($original)->Terse(1)->Out;
        my $copy= eval $text;
        is($@, '', "$label: output evaluates") or diag $text;
        isa_ok($copy, 'Regexp', "$label: restored pattern");
        next unless ref($copy) eq 'Regexp';

        for my $subject ("a${character}b", 'ab', $source) {
            is(
                !!($subject =~ $copy),
                !!($subject =~ $original),
                "$label: literal Unicode matching survives"
            );
        }
    }
}

{
    my $original= qr/a.b/im;
    my ($pattern, $modifiers)= regex($original);
    is($pattern, 'a.b', 'compatibility API returns the source pattern');
    like($modifiers, qr/i/, 'compatibility API retains case-insensitive mode');
    like($modifiers, qr/m/, 'compatibility API retains multiline mode');
    ok(defined scalar regex($original),
        'compatibility API supports scalar context');
    ok(!scalar regex({}), 'compatibility API rejects non-regexps');
    bless $original, 'DDSRegexpCompatibility';
    my $text= Dump()->Names('value')->Data([ $original, $original ])->Out;
    my $value;
    my $copy= eval $text . '$value';
    is($@, '', 'shared reblessed regexp output evaluates') or diag $text;
    is(ref($copy->[0]), 'DDSRegexpCompatibility', 'regexp subclass survives');
    is(
        Data::Dump::Streamer::refaddr($copy->[0]),
        Data::Dump::Streamer::refaddr($copy->[1]),
        'regexp identity survives'
    );
    ok("AXB" =~ $copy->[0], 'restored reblessed regexp remains functional');
}

done_testing;
