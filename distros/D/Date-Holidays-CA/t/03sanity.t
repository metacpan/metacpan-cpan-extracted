use strict;
use warnings;
use Test::More qw(no_plan);

BEGIN { use_ok('Date::Holidays::CA', qw(:all)) };


# sanity tests.  do the results that we get back make any sense?

# are the dates valid?
# do holidays that are supposed to fall on Monday actually fall there?
#    ...etc
