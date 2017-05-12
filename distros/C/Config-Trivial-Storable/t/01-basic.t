#   $Id: 01-basic.t 69 2014-05-23 10:27:30Z adam $

use strict;
use Test::More tests => 4;

BEGIN { use_ok( 'Config::Trivial::Storable' ); }

is( $Config::Trivial::Storable::VERSION, '0.32', 'Version Check' );

my $config = Config::Trivial::Storable->new;
ok(defined $config, 'Object is defined' );
isa_ok( $config, 'Config::Trivial::Storable', 'Oject/Class Check' );

exit;
__END__
