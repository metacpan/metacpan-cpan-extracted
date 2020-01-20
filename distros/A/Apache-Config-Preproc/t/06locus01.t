# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 1;

use TestPreproc;
my $obj = new TestPreproc -expand => [qw(locus)],
                          '-no-comment-grouping' => 1,
                          '-no-blank-grouping' => 1;
ok($obj->dump_reformat_synclines, $obj->dump_expect)

__DATA__
!>httpd.conf
# Start of file

# Comment 1
# Comment 2
# Comment 3


# End of file
!=
# $server_root/httpd.conf:1
# Start of file
# $server_root/httpd.conf:2

# $server_root/httpd.conf:3
# Comment 1
# $server_root/httpd.conf:4
# Comment 2
# $server_root/httpd.conf:5
# Comment 3
# $server_root/httpd.conf:6

# $server_root/httpd.conf:7

# $server_root/httpd.conf:8
# End of file
!$
