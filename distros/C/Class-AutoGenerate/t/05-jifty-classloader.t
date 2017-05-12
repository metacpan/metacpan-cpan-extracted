#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 63;
use_ok('Class::AutoGenerate');

# This test roughly simulates the work of the original Jifty::ClassLoader::INC
# upon which this ideas was based.

package Jifty::ClassLoader;
use Class::AutoGenerate -base;

# App -> just an empty package
requiring '*' => generates {};

# App::XXX -> basic empty customizations of Jifty features
requiring qr/^\w+::(Record|Collection|Notification
                   |Dispatcher|Bootstrap|Upgrade|CurrentUser
                   |Handle|Event|Event::Model|Action
                   |Action::Record::\w+)$/x => generates { 
    eval "package Jifty::$1; 1;";
    extends "Jifty::$1";
};

requiring '*::View' => generates { 
    uses 'Jifty::View::Declare', '-base';
};

requiring '*::Model::*Collection' => generates {
    my $base = $1;
    my $name = $2;

    extends "${base}::Collection";

    defines 'record_class' => sub { "${base}::Model::$name" };
};

requiring '*::Event::Model::*' => generates {
    my $base = $1;
    my $name = $2;

    extends "${base}::Event::Model";

    defines 'record_class' => sub { "${base}::Model::$name" };
};

requiring [ '*::Action::Create*', '*::Action::Update*',
            '*::Action::Delete*', '*::Action::Search*' ] => generates {
    my $base = $1;
    my $name = $2;

    extends "${base}::Action::Record::$name";

    defines 'record_class' => sub { "${base}::Model::$name" };
};

package main;

my $class_loader = Jifty::ClassLoader->new( match_only => [ 'App', 'App::**' ] );

require_ok('App');
is($INC{'App.pm'}, $class_loader);

require_ok('App::Record');
is($INC{'App/Record.pm'}, $class_loader);
isa_ok(bless({}, 'App::Record'), 'Jifty::Record');

require_ok('App::Collection');
is($INC{'App/Collection.pm'}, $class_loader);
isa_ok(bless({}, 'App::Collection'), 'Jifty::Collection');

require_ok('App::Notification');
is($INC{'App/Notification.pm'}, $class_loader);
isa_ok(bless({}, 'App::Notification'), 'Jifty::Notification');

require_ok('App::Dispatcher');
is($INC{'App/Dispatcher.pm'}, $class_loader);
isa_ok(bless({}, 'App::Dispatcher'), 'Jifty::Dispatcher');

require_ok('App::Bootstrap');
is($INC{'App/Bootstrap.pm'}, $class_loader);
isa_ok(bless({}, 'App::Bootstrap'), 'Jifty::Bootstrap');

require_ok('App::Upgrade');
is($INC{'App/Upgrade.pm'}, $class_loader);
isa_ok(bless({}, 'App::Upgrade'), 'Jifty::Upgrade');

require_ok('App::CurrentUser');
is($INC{'App/CurrentUser.pm'}, $class_loader);
isa_ok(bless({}, 'App::CurrentUser'), 'Jifty::CurrentUser');

require_ok('App::Handle');
is($INC{'App/Handle.pm'}, $class_loader);
isa_ok(bless({}, 'App::Handle'), 'Jifty::Handle');

require_ok('App::Event');
is($INC{'App/Event.pm'}, $class_loader);
isa_ok(bless({}, 'App::Event'), 'Jifty::Event');

require_ok('App::Event::Model');
is($INC{'App/Event/Model.pm'}, $class_loader);
isa_ok(bless({}, 'App::Event::Model'), 'Jifty::Event::Model');

require_ok('App::Action');
is($INC{'App/Action.pm'}, $class_loader);
isa_ok(bless({}, 'App::Action'), 'Jifty::Action');

require_ok('App::Action::Record::Create');
is($INC{'App/Action/Record/Create.pm'}, $class_loader);
isa_ok(bless({}, 'App::Action::Record::Create'), 'Jifty::Action::Record::Create');

require_ok('App::Model::FooCollection');
is($INC{'App/Model/FooCollection.pm'}, $class_loader);
require_ok('App::Model::BarCollection');
is($INC{'App/Model/BarCollection.pm'}, $class_loader);

require_ok('App::Event::Model::Foo');
is($INC{'App/Event/Model/Foo.pm'}, $class_loader);
require_ok('App::Event::Model::Bar');
is($INC{'App/Event/Model/Bar.pm'}, $class_loader);

require_ok('App::Action::CreateFoo');
is($INC{'App/Action/CreateFoo.pm'}, $class_loader);
require_ok('App::Action::UpdateFoo');
is($INC{'App/Action/UpdateFoo.pm'}, $class_loader);
require_ok('App::Action::DeleteFoo');
is($INC{'App/Action/DeleteFoo.pm'}, $class_loader);
require_ok('App::Action::SearchFoo');
is($INC{'App/Action/SearchFoo.pm'}, $class_loader);
require_ok('App::Action::CreateBar');
is($INC{'App/Action/CreateBar.pm'}, $class_loader);
require_ok('App::Action::UpdateBar');
is($INC{'App/Action/UpdateBar.pm'}, $class_loader);
require_ok('App::Action::DeleteBar');
is($INC{'App/Action/DeleteBar.pm'}, $class_loader);
require_ok('App::Action::SearchBar');
is($INC{'App/Action/SearchBar.pm'}, $class_loader);
