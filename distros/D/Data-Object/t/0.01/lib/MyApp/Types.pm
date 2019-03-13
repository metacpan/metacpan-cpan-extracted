package MyApp::Types;

use Type::Utils -all;

use parent 'Data::Object::Config::Library';

declare "AllCaps", as Data::Object::Config::Library::StrObj, where { uc("$_") eq "$_" };

coerce "AllCaps", from Data::Object::Config::Library::StrObj, via { uc("$_") };

1;
