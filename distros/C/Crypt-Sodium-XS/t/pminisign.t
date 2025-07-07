use strict;
use warnings;
use Test::More;
use File::Temp;
use FindBin;

# assumes the location of bin directory. booooooooo.
SKIP: {
  skip "perl version too old" if $] < 5.020000;
  package Crypt::Sodium::XS::Test::Pminisign;
  require "$FindBin::Bin/../bin/pminisign" or die "require pminisign failed: $@";
}

#my $tmpfile = File::Temp->new;
#my $tmpdir = File::Temp->newdir;


# test generating keypairs

# with MINISIGN_CONFIG_DIR env var
# with HOME env var
# with -p (path to public key) arg
# with -s (path to secret key) arg

# probably validate generation by 

ok(1);

done_testing();
