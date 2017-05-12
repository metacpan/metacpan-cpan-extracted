use strict;
use warnings;
use AnyEvent::Groonga;
use Test::More tests => 1;

my $g = AnyEvent::Groonga->new;
isa_ok( $g, "AnyEvent::Groonga" );

