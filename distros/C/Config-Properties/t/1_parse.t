# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use utf8;

use Test::More tests => 17;
BEGIN { use_ok('Config::Properties') };

my $cfg=Config::Properties->new();
for (1) {
    eval { $cfg->load(\*DATA) };
}
ok (!$@, "don't use \$_");


is ($cfg->getProperty('foo'), 'one', 'foo');
is ($cfg->getProperty('eq=ua:l'), 'jamon', 'eq=ual');
is ($cfg->getProperty('Bar'), "maybe one\none\tone\r", 'Bar');
is ($cfg->getProperty('more'), 'another configuration line', 'more');
is ($cfg->getProperty('less'), "who said:\tless ??? ", 'less');
is ($cfg->getProperty("cra\n=: \\z'y'"), 'jump', 'crazy');
is ($cfg->getProperty("#nocmt"), 'good', 'no comment 1');
is ($cfg->getProperty("!nocmt"), 'good', 'no comment 2');
is ($cfg->getProperty("lineend1"), 'here', 'line end 1');
is ($cfg->getProperty("lineend2"), 'here', 'line end 2');
is ($cfg->getProperty("\\\\machinename\\folder"),
    "\\\\windows\\ style\\path",
    'windows style path');
is ($cfg->getProperty("cmd3"),
    '/usr/share/Artemis/bin/loki -vip 10.51.100.120 -file f3058 -it 10 -repeat 100000000 -proc read -vdir /vol1 -useGateway 172.16.254.254 %ETH%',
    'derrick bug');

is ($cfg->getProperty("unicode"), "he\x{0113}llo", "unicode unencode");

is ($cfg->getProperties->{foo}, 'one', 'getProperties one');
my %props=$cfg->properties;
is ($props{foo}, 'one', 'properties one');


__DATA__
# hello
foo=one
    Bar : maybe one\none\tone\r
eq\=ua\:l jamon

more : another \
    configuration \
    line
less= who said:\tless ??? 

cra\n\=\:\ \\z'y' jump

\#nocmt = good
#nocmt = bad

\!nocmt = good
!nocmt = bad

unicode = he\u0113llo

lineend1=here
lineend2=here

cmd3=/usr/share/Artemis/bin/loki -vip 10.51.100.120 -file f3058 -it 10 -repeat 100000000 -proc read -vdir /vol1 -useGateway 172.16.254.254 %ETH%

\\\\machinename\\folder = \\\\windows\\ style\\path
