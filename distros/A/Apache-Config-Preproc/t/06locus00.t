# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 1;

use TestPreproc;
my $obj = new TestPreproc -expand => [qw(locus)];
ok($obj->dump_reformat_synclines, $obj->dump_expect)

__DATA__
!>httpd.conf
# Start of file

# Comment 1
# Comment 2
# Comment 3


# End of file
!=
# {{$server_root/httpd.conf}}:1
# Start of file
# $server_root/httpd.conf:2

# {{$server_root/httpd.conf}}:3-5
# Comment 1
# Comment 2
# Comment 3
# {{$server_root/httpd.conf}}:6-7


# {{$server_root/httpd.conf}}:8
# End of file
!$
