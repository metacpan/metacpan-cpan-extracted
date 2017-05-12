package MyApp::Autobox::Float;

use base 'Data::Object::Autobox::Composite::Float';

sub custom {
    __PACKAGE__;
}

1;
