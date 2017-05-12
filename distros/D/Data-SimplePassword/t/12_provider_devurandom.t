#

use strict;
use lib qw(blib);
use Data::SimplePassword;

use Test::More;

my $sp = Data::SimplePassword->new;

my $type = 'devurandom';

plan skip_all => qq{provider '$type' not available} if not $sp->is_available_provider( $type );

ok( length $sp->make_password( 32 ) == 32, "password length" );

done_testing;

__END__
