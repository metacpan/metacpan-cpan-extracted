package # hide from PAUSE 
    VCTest::Schema;
    
use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes(qw/Test1 Test2 Test3/);

1;
