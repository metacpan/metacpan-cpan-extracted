#

use strict;
use lib qw(blib);
use Data::SimplePassword;

use Test::More;

my $sp = Data::SimplePassword->new;

my $type = 'rand';

my $rv = eval "\$sp->provider('$type')";
plan skip_all => qq{provider '$type' not available} if not $rv;

ok( length $sp->make_password( 32 ) == 32, "password length" );

done_testing;

__END__
