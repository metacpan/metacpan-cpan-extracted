use strict;
use Test::More tests => 1;

my $out = `$^X t/cgi.pl`;
like $out, qr/Lincoln/;


