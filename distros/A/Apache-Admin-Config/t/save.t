use strict;
use Test;
plan test => 886;

use Apache::Admin::Config;
ok(1);

my $conf = new Apache::Admin::Config 't/httpd.conf-dist';

open(CONF, 't/httpd.conf-dist');

my @conf = split(/\n/, $conf->dump_raw);
my $i = 0;
while(<CONF>)
{
    chomp;
    ok($_ eq $conf[$i++]);
}

close(CONF);
