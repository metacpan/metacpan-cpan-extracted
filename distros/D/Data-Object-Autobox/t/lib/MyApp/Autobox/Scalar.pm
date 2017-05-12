package MyApp::Autobox::Scalar;

use base 'Data::Object::Autobox::Composite::Scalar';

sub custom {
    __PACKAGE__;
}

1;
