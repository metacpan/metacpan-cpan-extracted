use strict;
use warnings;
use Test::More;
BEGIN {
    eval q[use Test::Base];
    plan skip_all => "Test::Base required for testing base" if $@;
};

__END__

=== simple
--- input
--- expected
