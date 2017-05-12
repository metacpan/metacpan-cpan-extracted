use strict;
use warnings;
use AnyEvent::Groonga;
use Test::More tests => 8;

my $g = AnyEvent::Groonga->new;

can_ok( $g, "new" );
can_ok( $g, "call" );
can_ok( $g, "protocol" );
can_ok( $g, "host" );
can_ok( $g, "port" );
can_ok( $g, "groonga_path" );
can_ok( $g, "database_path" );
can_ok( $g, "command_list" );
