package MyApp::Autobox::Array;

use base 'Data::Object::Autobox::Composite::Array';

sub custom {
    __PACKAGE__;
}

1;
