use strict;
use warnings;

BEGIN {
    unless ($ENV{RELEASE_TESTING})
    {
        use Test::More;
        plan(skip_all => 'these tests are for release candidate testing');
    }
}
 
# use Test::Kwalitee ();
use Test::Kwalitee;


# Test::Kwalitee->import( tests => [ "use_strict" ] );
