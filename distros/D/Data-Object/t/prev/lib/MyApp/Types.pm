package MyApp::Types;

use Type::Utils -all;

use parent 'Data::Object::Library';

declare "AllCaps",
    as Data::Object::Library::StrObj,
    where { uc("$_") eq "$_" };

coerce "AllCaps",
    from Data::Object::Library::StrObj,
    via { uc("$_") };

1;
