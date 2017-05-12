package # hide from PAUSE 
    DATest::Schema;
    
use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes(qw/Test1A Test1B Test2A Test2B Test2C Test2D Test3A Test4A Test5A Test5B Test6A Test6B/);

1;