use strict;
use warnings;
use Test::More;

# plan( skip_all => 'Author test. Set TEST_AUTHOR to a true value to run.' )
#   unless $ENV{TEST_AUTHOR};

eval {
    require Test::Kwalitee;
    Test::Kwalitee->import( tests => [qw( -no_symlinks )] );
    unlink 'Debian_CPANTS.txt' if -e 'Debian_CPANTS.txt';
};
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

