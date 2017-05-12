package MyApp::Autobox::Integer;

use base 'Data::Object::Autobox::Composite::Integer';

sub custom {
    __PACKAGE__;
}

1;
