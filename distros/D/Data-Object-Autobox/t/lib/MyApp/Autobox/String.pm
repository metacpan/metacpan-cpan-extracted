package MyApp::Autobox::String;

use base 'Data::Object::Autobox::Composite::String';

sub custom {
    __PACKAGE__;
}

1;
