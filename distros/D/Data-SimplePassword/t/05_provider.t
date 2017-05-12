#

use strict;
use lib qw(blib);
use Data::SimplePassword;

use Test::More;
use Test::Exception;

my $sp = Data::SimplePassword->new;

can_ok( $sp, "provider" );

dies_ok { $sp->provider('') } "empty string not allowed";
dies_ok { $sp->provider('/dev/nonexistent') } "nonexistent provider failed";

# once a provider is set, it returns the one
SKIP: {
    my $type = 'rand';
    skip "unknown readon", 1 if not eval "\$sp->provider('$type')";

    ok( $sp->provider eq $type, "set name" );
};

done_testing;

__END__
