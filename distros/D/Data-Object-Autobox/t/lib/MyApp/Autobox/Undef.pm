package MyApp::Autobox::Undef;

use base 'Data::Object::Autobox::Composite::Undef';

sub custom {
    __PACKAGE__;
}

1;
