#
# $Id: basic_on.t,v 0.1 2001/03/31 10:04:37 ram Exp $
#
#  Copyright (c) 2000-2001, Christophe Dehaudt & Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: basic_on.t,v $
# Revision 0.1  2001/03/31 10:04:37  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

print "1..5\n";

require 't/test.pl';
require 't/code.pl';
sub ok;

use Carp::Datum qw(:all on);

my $line = __LINE__ + 1;
DFEATURE(my $f);

my $file = "t/file.err";
ok 1, contains($file, "^   \\+-> global \\[t/basic_on.t:$line\\]");

$line = __LINE__ + 1;
test::square(1);
ok 2, contains($file, "test::square\\(1\\) from global at t/basic_on.t:$line");

test::wrap_square(1);
ok 3, contains($file,
	"test::square\\(1\\) from test::wrap_square\\(\\) at t/test.pl");

$line = __LINE__ + 1;
DVOID;		# Force destruction
ok 4, contains($file, "^   \\|  Returning \\[t/basic_on.t:$line\\]");

ok 5, 0 == -s "t/file.out";

unlink 't/file.out', 't/file.err';

