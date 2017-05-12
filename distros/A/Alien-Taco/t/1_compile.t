# Import the main modules in separate processes to ensure
# they can all be loaded successfully.

use strict;

use Test::More tests => 2;

foreach (qw/Alien::Taco Alien::Taco::Server/) {
    if (my $pid = fork) {
       waitpid($pid, 0);
       ok(!$?, $_);
    }
    else {
        die 'fork failed' unless defined $pid;
        eval "use $_;";
        die if $@;
        exit;
    }
}
