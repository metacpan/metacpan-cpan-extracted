use strict;
use warnings;

use Test::More import => [ qw( plan ) ];

BEGIN { plan skip_all => 'Not release testing context' unless $ENV{ RELEASE_TESTING } }

use Test::Needs qw( Test::Perl::Critic );

Test::Perl::Critic::all_critic_ok( 'lib', 't', 'maint' );
