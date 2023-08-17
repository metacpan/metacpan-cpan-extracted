#!perl -w

use strict;
use warnings;
use lib './lib';
use vars qw( $DEBUG );
$DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
# use Test::More qw(plan ok);
use Test::More;
plan tests => 6;

use Data::Pretty qw(dump);
use Symbol qw(gensym);
local $Data::Pretty::DEBUG = $DEBUG;

is(dump(*STDIN), "*main::STDIN", 'dump STDIN');
is(dump(\*STDIN), "\\*main::STDIN", 'dump \*STDIN');
is(dump(gensym()), "do {\n    require Symbol;\n    Symbol::gensym();\n}", 'dump symbol');

$a = [];
${*foo}[1] = $a;
${*foo}{bar} = 2;
is(dump(\*foo, $a) . "\n", <<'EOT', 'dump complex');
do {
    my $a = \*main::foo;
    *{$a} = [undef, []];
    *{$a} = { bar => 2 };
    ($a, *{$a}{ARRAY}[1]);
}
EOT

use IO::Socket::INET;
my $s = IO::Socket::INET->new(
    Listen => 1,
    Timeout => 5,
    LocalAddr => '127.0.0.1',
);
$s = dump($s);
print "$s\n";
like($s, qr/my \$a = bless\(Symbol::gensym\(\), "IO::Socket::INET"\);/, 'blessed object dump');
like($s, qr/^\s+io_socket_timeout\s+=> 5,/m, 'dump object properties');
