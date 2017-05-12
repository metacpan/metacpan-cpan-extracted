package YUI::Test::Goo::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use YUI::Test::Goo;

sub object_class { 'YUI::Test::Goo' }

__PACKAGE__->make_manager_methods('goos');

1;

