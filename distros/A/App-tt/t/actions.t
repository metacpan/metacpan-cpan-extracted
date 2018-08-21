use lib '.';
use t::Helper;

my $tt = t::Helper->tt;

for my $action (split /\W/, 'log,start,stop,status,register') {
  ok $tt->can("cmd_$action"), "tt $action";
}

done_testing;
