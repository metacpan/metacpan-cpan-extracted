package MyApp::Autobox::Number;

use base 'Data::Object::Autobox::Composite::Number';

sub custom {
    __PACKAGE__;
}

1;
