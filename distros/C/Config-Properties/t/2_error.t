# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use Test::More tests => 2;
BEGIN { use_ok('Config::Properties') };

my $cfg=Config::Properties->new();

eval {
    $cfg->load(\*DATA)
};

like ($@, qr/line\s6\b/, "error at line 6 is ok");



__DATA__
# hello
foo=one
    Bar : maybe one\none\tone\r
eq\=ua\:l jamon

this_is_an_error\=line

more : another \
    configuration \
    line
less= who said:\tless ??? 

cra\n\=\:\ \\z'y' jump
