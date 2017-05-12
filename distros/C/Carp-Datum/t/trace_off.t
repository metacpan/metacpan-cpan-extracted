#
# $Id: trace_off.t,v 0.1 2001/03/31 10:04:37 ram Exp $
#
#  Copyright (c) 2000-2001, Christophe Dehaudt & Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: trace_off.t,v $
# Revision 0.1  2001/03/31 10:04:37  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

print "1..4\n";

require 't/test.pl';
require 't/code.pl';
sub ok;

use Carp::Datum qw(:all off);

test::trace();

ok 1, contains("t/file.err", "Log::Agent message");

my $file = "t/file.err";
ok 2, contains($file, "DTRACE warning");
ok 3, contains($file, "Log::Agent warning");
ok 4, !contains($file, "DTRACE message");

unlink 't/file.out', 't/file.err';

