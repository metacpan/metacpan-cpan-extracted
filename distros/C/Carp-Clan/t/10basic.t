use strict;
use warnings;

use Test::More;

plan tests => 2;

use_ok( 'Carp::Clan', 'Use Carp::Clan' );

eval {
    Carp::Clan->import(qw(^Carp\\b));
};

is($@, '', 'No errors importing');

__END__

