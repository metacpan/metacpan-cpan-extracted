# -*- Mode: CPerl -*-
#use lib qw(../lib);

use Test::More;
use DDC::Any qw(:none);
use File::Basename;
use lib '.'; ##-- for perl 5.26 (--> '.' is no longer in @INC; did you mean do "./t/parseme.pl"?)
use strict;
no warnings 'once';

##-- import
if (!DDC::Any->have_xs()) {
  plan skip_all => 'DDC::XS '.($DDC::XS::VERSION ? "v$DDC::XS::VERSION is too old" : 'not available');
}
DDC::Any->import(':xs');

my $TEST_DIR = File::Basename::dirname($0);
my $loadpl = do "$TEST_DIR/qcomments.pl"
  or die("$0: failed to load qcomments.pl: $@");
ok($loadpl,"loaded $TEST_DIR/qcomments.pl");

test_qcomments('DDC::Any');
done_testing();
