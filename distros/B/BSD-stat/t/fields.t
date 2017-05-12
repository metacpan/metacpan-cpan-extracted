#
# $Id: fields.t,v 1.21 2012/08/19 13:29:26 dankogai Exp $
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use strict;
my $Debug = 0;
BEGIN { plan tests => 18 };

use BSD::stat qw(:FIELDS);
my $bsdstat = lstat($0);

for my $s (qw(dev ino mode nlink uid gid rdev size
	      atime mtime ctime blksize blocks
	      atimensec mtimensec  ctimensec flags gen))
{
    no strict; 
    $Debug and warn "\$st_$s = ", ${"st_$s"};
    ok($bsdstat->$s() == ${"st_$s"});
}

$Debug and print $bsdstat->dev, "\n";
