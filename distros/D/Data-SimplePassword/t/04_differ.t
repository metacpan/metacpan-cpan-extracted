#

use strict;
use lib qw(blib);
use Data::SimplePassword;

use Test::More;
use List::MoreUtils;

my $sp = Data::SimplePassword->new;

# trying to use non-blocking RNG for quick test
$sp->provider("devurandom")
    if $sp->is_available_provider("devurandom");

my $n = $ENV{RUN_HEAVY_TEST} ? 1000 : 10;
my @result;
for(1..$n){
    push @result, $sp->make_password( 32 );
}

ok( scalar List::MoreUtils::uniq( @result ) == $n, "unique test" );

done_testing;

__END__
