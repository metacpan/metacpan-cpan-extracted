use strict;
use warnings;
use Test::More tests => 2;

my $b = `perl t/pexit.pl`;
is($b, 'exitmsg');

my $d = `perl t/perror.pl`;
is($d, 'errmsg');
