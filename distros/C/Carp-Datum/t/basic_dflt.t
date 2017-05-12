#
# $Id: basic_dflt.t,v 0.1 2001/03/31 10:04:37 ram Exp $
#
#  Copyright (c) 2000-2001, Christophe Dehaudt & Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: basic_dflt.t,v $
# Revision 0.1  2001/03/31 10:04:37  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

print "1..2\n";

require 't/test.pl';
require 't/code.pl';
sub ok;

use Carp::Datum;

DFEATURE(my $f);

test::square(1);
test::wrap_square(1);

DVOID;		# Force destruction

ok 1, 0 == -s "t/file.out";
ok 2, 0 == -s "t/file.err";

unlink 't/file.out', 't/file.err';

