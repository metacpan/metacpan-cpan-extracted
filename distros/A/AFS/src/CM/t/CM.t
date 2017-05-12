# -*-cperl-*-

use strict;
use lib qw(../../inc ../inc);
use blib;

use Test::More;

BEGIN {
    use AFS::FS;
    if (AFS::FS::isafs('./')) { plan tests => 15; }
    else { plan skip_all => 'Working directory is not in AFS file system ...'; }

    use_ok('AFS::CM', qw (
                          checkvolumes
                          cm_access flush flushcb flushvolume
                          getcacheparms getcrypt
                          
                          checkconn getcellstatus getvolstats
                          setcachesize setcellstatus setcrypt
                         )
          );
}

can_ok('AFS::CM', qw(checkvolumes));

my $ok = cm_access('/afs');
ok($ok, 'cm_access(/afs)');

$ok = cm_access('/tmp');
ok(!$ok, 'cm_access(/tmp)');

can_ok('AFS::CM', qw(flush));

can_ok('AFS::CM', qw(flushcb));

can_ok('AFS::CM', qw(flushvolume));

my ($max, undef) = getcacheparms;
ok($max, 'getcacheparms');

can_ok('AFS::CM', qw(getcrypt));

can_ok('AFS::CM', qw(checkconn));
can_ok('AFS::CM', qw(getcellstatus));
can_ok('AFS::CM', qw(getvolstats));
can_ok('AFS::CM', qw(setcachesize));
can_ok('AFS::CM', qw(setcellstatus));
can_ok('AFS::CM', qw(setcrypt));
