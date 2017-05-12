#-*- mode: cperl -*-#
use Test::More;
use blib;

chdir 't' if -d 't';
require './setup.pl';

unless( have_crontab() ) {
    plan skip_all => "no crontab available";
    exit;
}
plan tests => 2;

use_ok('Config::Crontab');

my $crontabf = ".tmp_crontab.$$";
my $crontabd = <<'_CRONTAB_';
MAILTO=scott

## logs nightly
#30 4 * * * /home/scott/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1
_CRONTAB_

## write a crontab file
open FILE, ">$crontabf"
  or die "Couldn't open $crontabf: $!\n";
print FILE $crontabd;
close FILE;

my $ct = new Config::Crontab( -file => $crontabf );
$ct->remove_tab;

ok( ! -e $crontabf, "crontab removed" );

END {
    unlink $crontabf;
}
