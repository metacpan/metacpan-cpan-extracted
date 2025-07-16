use strict;
use warnings;
use Test::More;
use File::Temp;
use FindBin '$Bin';

plan skip_all => "perl version too old" if $] < 5.020000;
{
  ok(require "$Bin/../bin/pminisign", "require pminisign");
}

#my $tmpfile = File::Temp->new;
#my $tmpdir = File::Temp->newdir;


# test generating keypairs

# with MINISIGN_CONFIG_DIR env var
# with HOME env var
# with -p (path to public key) arg
# with -s (path to secret key) arg

# probably validate generation by 

done_testing();
