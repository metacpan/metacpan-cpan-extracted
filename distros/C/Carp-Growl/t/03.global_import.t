use Test::More tests => 24;

use lib 't/testlib';    # for loading DUMMY Growl::Any

{
    eval { require Carp::Growl }
        or BAIL_OUT("Can't load 'Carp::Growl'");

    Carp::Growl->import('global');
    ok( defined &{'CORE::GLOBAL::warn'},      'import global warn()' );
    ok( defined &{'CORE::GLOBAL::die'},       'import global die()' );
    ok( !defined &{ __PACKAGE__ . '::warn' }, 'not import local warn()' );
    ok( !defined &{ __PACKAGE__ . '::die' },  'not import local die()' );
    ok( defined &{ __PACKAGE__ . '::carp' },  'import local carp()' );
    ok( defined &{ __PACKAGE__ . '::croak' }, 'import local croak()' );

    Carp::Growl->unimport();
    ok( !defined &{'CORE::GLOBAL::warn'},      'unimport global warn()' );
    ok( !defined &{'CORE::GLOBAL::die'},       'unimport global die()' );
    ok( !defined &{ __PACKAGE__ . '::carp' },  'unimport local carp()' );
    ok( !defined &{ __PACKAGE__ . '::croak' }, 'unimport local croak()' );

    sub pre_installed_sub {1}
    *{'CORE::GLOBAL::warn'}      = \&pre_installed_sub;
    *{'CORE::GLOBAL::die'}       = \&pre_installed_sub;
    *{ __PACKAGE__ . '::warn' }  = \&pre_installed_sub;
    *{ __PACKAGE__ . '::die' }   = \&pre_installed_sub;
    *{ __PACKAGE__ . '::carp' }  = \&pre_installed_sub;
    *{ __PACKAGE__ . '::croak' } = \&pre_installed_sub;

    Carp::Growl->import('global');

    ok( defined &{'CORE::GLOBAL::warn'},      'import global warn()' );
    ok( defined &{'CORE::GLOBAL::die'},       'import global die()' );
    ok( !defined &{ __PACKAGE__ . '::warn' }, 'not import local warn()' );
    ok( !defined &{ __PACKAGE__ . '::die' },  'not import local die()' );
    ok( defined &{ __PACKAGE__ . '::carp' },  'import local carp()' );
    ok( defined &{ __PACKAGE__ . '::croak' }, 'import local croak()' );
    isnt( \&{'CORE::GLOBAL::warn'},
        \&::pre_installed_sub, 'override global warn()' );
    isnt( \&{'CORE::GLOBAL::die'},
        \&::pre_installed_sub, 'override global die()' );
    isnt(
        \&{ __PACKAGE__ . '::carp' },
        \&::pre_installed_sub,
        'override local carp()'
    );
    isnt(
        \&{ __PACKAGE__ . '::croak' },
        \&::pre_installed_sub,
        'override local croak()'
    );

    Carp::Growl->unimport();

    is( \&{'CORE::GLOBAL::warn'},
        \&::pre_installed_sub, 'restore global warn()' );
    is( \&{'CORE::GLOBAL::die'},
        \&::pre_installed_sub, 'restore global die()' );
    is( \&{ __PACKAGE__ . '::carp' },
        \&::pre_installed_sub,
        'restore local carp()'
      );
    is( \&{ __PACKAGE__ . '::croak' },
        \&::pre_installed_sub,
        'restore local croak()'
      );
}
