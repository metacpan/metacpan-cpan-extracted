use Test2::V0;
use Test::Alien;
use Alien::GtkNodes;
use Glib::Object::Introspection;

alien_ok 'Alien::GtkNodes';
Alien::GtkNodes->init;

ok( lives {
    Glib::Object::Introspection->setup(
        basename => 'GtkNodes',
        version => '0.1',
        package => 'GtkNodes',
    )
}, "Glib::Object::Introspection found alien" );

done_testing;
