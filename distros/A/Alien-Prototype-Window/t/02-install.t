use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Path qw(rmtree);
use Alien::Prototype::Window;

my $dir = 't/eraseme';

# Figure out how many tests we're going to run
my @files = Alien::Prototype::Window->files();
plan tests => 2 + scalar @files;

# Clean up from any previous test run.
cleanup_old_test_run: {
    rmtree( $dir ) if (-e $dir);
}

# Install, and make sure that all of the files got installed properly.
install_pwc: {
    Alien::Prototype::Window->install( $dir );
    # make sure script.aculo.us got installed
    ok( -e "$dir/scriptaculous.js", "script.aculo.us installed" );
    # make sure our files got installed
    foreach my $file (@files) {
        ok( -e "$dir/$file", "$file exists" );
    }
}

# Install on top of an existing install; shouldn't choke
reinstall_pwc: {
    lives_ok { Alien::Prototype::Window->install($dir) };
}

# Clean up after ourselves
cleanup: {
    rmtree( $dir );
}
