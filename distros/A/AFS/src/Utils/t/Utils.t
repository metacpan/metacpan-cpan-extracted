# -*-cperl-*-

use strict;
use lib qw(../../inc ../inc);
use blib;

use Test::More;

BEGIN {
    use AFS::FS;
    if (AFS::FS::isafs('./')) { plan tests => 7; }
    else { plan skip_all => 'Working directory is not in AFS file system ...'; }

    use_ok('AFS::Utils', qw (
                             XSVERSION get_server_version get_syslib_version
                             setpag sysname unlog
                            )
          );
}

my $setpag = setpag;
ok(defined $setpag, 'setpag');

my $xsversion = XSVERSION;
ok(defined $xsversion, 'XSVERSION');

my $syslib_version = get_syslib_version;
ok(defined $syslib_version, 'get_syslib_version');

my $server_version = get_server_version('cm');
ok(defined $server_version, 'get_server_version');

my $sysname = sysname;
ok(defined $sysname, 'sysname');

my $unlog = unlog;
ok(defined $unlog, 'unlog');
