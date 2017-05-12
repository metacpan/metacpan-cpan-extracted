use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Path qw(rmtree);
use Alien::Prototype;

my $dir = 't/eraseme';

# Figure out how many tests we're going to run
my @files = Alien::Prototype->files();
plan tests => 1 + scalar @files;

# Clean up from any previous test run.
cleanup_old_test_run: {
    rmtree( $dir ) if (-e $dir);
}

# Install, and make sure that the files got installed properly.
install_prototype: {
    Alien::Prototype->install( $dir );
    foreach my $file (@files) {
        ok( -e "$dir/$file", "$file exists" );
    }
}

# Install over top of an existing install; shouldn't choke.
reinstall_prototype: {
    lives_ok { Alien::Prototype->install($dir) };
}

# Clean up after ourselves
cleanup: {
    rmtree( $dir );
}
