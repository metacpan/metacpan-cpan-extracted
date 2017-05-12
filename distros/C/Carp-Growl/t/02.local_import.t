use Test::More tests => 11;

use lib 't/testlib';    # for loading DUMMY Growl::Any

{
    eval { require Carp::Growl } or BAIL_OUT("Can't load 'Carp::Growl'");

    {
        Carp::Growl->import();
        for $f (qw/warn die carp croak/) {
            ok( defined &{ '::' . $f }, 'import local ' . $f . '()' );
        }
        Carp::Growl->unimport();
        for $f (qw/warn die carp croak/) {
            ok( !defined &{ *{ __PACKAGE__ . '::' . $f } },
                'unimport local ' . $f . '()' );
        }
    }
    {
        my $pre_installed_sub = sub {1};
        *{ __PACKAGE__ . '::carp' } = $pre_installed_sub;
        Carp::Growl->import();
        ok( defined &{ __PACKAGE__ . '::carp' }, 'import local warn()' );
        isnt( *{ __PACKAGE__ . '::carp' }{CODE},
            $pre_installed_sub, 'override local warn()' );

        Carp::Growl->unimport();
        is( *{ __PACKAGE__ . '::carp' }{CODE},
            $pre_installed_sub, 'restore local warn()' );
    }
}
