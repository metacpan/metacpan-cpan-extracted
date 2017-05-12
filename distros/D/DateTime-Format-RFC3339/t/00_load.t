#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
   require_ok( 'DateTime::Format::RFC3339' );
}

diag( "Testing DateTime::Format::RFC3339 $DateTime::Format::RFC3339::VERSION" );
diag( "Using Perl $]" );

for (sort grep /\.pm\z/, keys %INC) {
   s{\.pm\z}{};
   s{/}{::}g;
   eval { diag(join(' ', $_, $_->VERSION || '<unknown>')) };
}
