package MyApp::Autobox::Hash;

use base 'Data::Object::Autobox::Composite::Hash';

sub custom {
    __PACKAGE__;
}

1;
