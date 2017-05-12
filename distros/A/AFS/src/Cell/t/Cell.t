# -*-cperl-*-

use strict;
use lib qw(../../inc ../inc);
use blib;

use Test::More;

BEGIN {
    use AFS::FS;
    if (AFS::FS::isafs('./')) { plan tests => 8; }
    else { plan skip_all => 'Working directory is not in AFS file system ...'; }

    use_ok('AFS::Cell', qw (configdir expandcell
                            getcellinfo localcell
                            whichcell wscell
                           )
          );
}

my $conf_dir = configdir;
ok(defined $conf_dir, 'configdir ');

my $cell = localcell;
ok(defined $cell, 'localcell');

ok($cell eq expandcell($cell), 'expandcell');

ok($cell eq whichcell("/afs/$cell"), 'whichcell');

ok($cell eq wscell, 'wscell');

my ($Cell, @hosts) = getcellinfo;
ok($Cell eq localcell, 'getcellinfo(cell) ');
ok($#hosts ge 0, 'getcellinfo(hosts) ');
