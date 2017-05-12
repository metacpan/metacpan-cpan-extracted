package YUI::Test::Bar::Manager;

use strict;

use base qw(Rose::DB::Object::Manager);

use YUI::Test::Bar;

sub object_class { 'YUI::Test::Bar' }

__PACKAGE__->make_manager_methods('bars');

1;

