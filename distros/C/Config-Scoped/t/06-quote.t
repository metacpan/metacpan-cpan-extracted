# vim: cindent ft=perl

use warnings;
use strict;

use Test::More tests => 5;

BEGIN { use_ok('Config::Scoped') }
my ( $p, $cfg );
isa_ok( $p = Config::Scoped->new(), 'Config::Scoped' );

my $text = <<'eot';
foo {
    word = without_spaces_and_other_separators
    single = 'everything you know from "perl" in single quotes!'
    %macro _MACRO_ macro
    double = "now with _MACRO_ expansion in double quotes"
    'here doc' = <<here;
    with _MACRO_ expansion
here
}
eot

my $expected = {
    'foo' => {
        'double'   => 'now with macro expansion in double quotes',
        'single'   => 'everything you know from "perl" in single quotes!',
        'word'     => 'without_spaces_and_other_separators',
        'here doc' => '    with macro expansion
'
    }
};

is_deeply( $p->parse( text => $text ), $expected, 'simple quoting tests' );

$text = <<'eot';
foo {
    single = '\tasdf\n';
    double = "\tasdf\n";
    here_single = <<'stop';
\tasdf\n
stop
    here_double = <<stop;
\tasdf\n
stop
}
eot

$expected = {
    'foo' => {
        single      => '\tasdf\n',
        double      => "\tasdf\n",
        here_single => '\tasdf\n
',
        here_double => "\tasdf\n\n",
    }
};

$p = Config::Scoped->new();
is_deeply( $p->parse( text => $text ), $expected, 'backslash substitution' );

$text = <<'eot';
rock { escape = "\x43\x6f\x6e\x66\x69\x67\x3a\x3a\x53\x63\x6f\x70\x65\x64\x20\x72\x6f\x63\x6b\x73";
}
eot

$expected = { 'rock' => { 'escape' => 'Config::Scoped rocks' } };


$p = Config::Scoped->new();
is_deeply( $p->parse( text => $text ), $expected, 'more escapes' );
