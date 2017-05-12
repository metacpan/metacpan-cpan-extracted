use Test::More;

use App::Kit::Pangea;

isa_ok( App::Kit::Pangea->new, 'App::Kit::Pangea' );
isa_ok( App::Kit::Pangea->new, 'App::Kit' );

done_testing;
