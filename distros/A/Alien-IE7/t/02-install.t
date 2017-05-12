use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Path qw(rmtree);
use Alien::IE7;

my $dir = 't/eraseme';

# Figure out how many tests we're going to run
my @files = Alien::IE7->files();
plan tests => 1 + scalar @files;

# Clean up from any previous test run
cleanup_old_test_run: {
    rmtree( $dir ) if (-e $dir);
}

# Install, and make sure that all of the files got installed properly
install_ie7: {
    Alien::IE7->install( $dir );
    foreach my $file (@files) {
        ok( -e "$dir/$file", "$file exists" );
    }
}

# Install on top of an existing install; shouldn't choke
reinstall_ie7: {
    lives_ok { Alien::IE7->install($dir) };
}

# Clean up after ourselves
cleanup: {
    rmtree( $dir );
}
