package # hide from PAUSE
    MyApp;

use base qw(Class::Accessor::Fast::Contained);

MyApp->mk_accessors(qw(name role salary));

1;
