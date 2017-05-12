package YUI::Test::Foo::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use YUI::Test::Foo;

sub object_class { 'YUI::Test::Foo' }

__PACKAGE__->make_manager_methods('foos');

1;

