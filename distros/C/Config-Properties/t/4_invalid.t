# -*- Mode: Perl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use Test::More tests => 1;

use Config::Properties;

my $cfg=Config::Properties->new();

my %valid = map { $_=> 1 }
    qw ( foo Bar eq=ua:l more cra\n=:\ \\z'y' );

$cfg->setValidator( sub { $valid{shift()} } );

eval {
    $cfg->load(\*DATA);
};

like ($@, qr/less.*line 9\b/, 'invalid line 9 is ok');




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
