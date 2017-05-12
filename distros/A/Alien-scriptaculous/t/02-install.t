use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Path qw(rmtree);
use Alien::scriptaculous;

my $dir = 't/eraseme';

# Figure out how many tests we're going to run
my @files = Alien::scriptaculous->files();
plan tests => 2 + scalar @files;

# Clean up from any previous test run.
cleanup_old_test_run: {
    rmtree( $dir ) if (-e $dir);
}

# Install, and make sure that all of the files got installed properly.
install_scriptaculous: {
    Alien::scriptaculous->install( $dir );
    # make sure Prototype got installed
    ok( -e "$dir/prototype.js", "prototype installed" );
    # make sure our files got installed
    foreach my $file (@files) {
        ok( -e "$dir/$file", "$file exists" );
    }
}

# Install on top of an existing install; shouldn't choke
reinstall_scriptaculous: {
    lives_ok { Alien::scriptaculous->install($dir) };
}

# Clean up after ourselves
cleanup: {
    rmtree( $dir );
}
