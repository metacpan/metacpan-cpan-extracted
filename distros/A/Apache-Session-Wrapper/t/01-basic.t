#!/usr/bin/perl -w

use strict;

use File::Spec;
use File::Temp ();

use Test::More tests => 20;

use_ok('Apache::Session::Wrapper');


my %params =
    ( class     => 'Flex',
      store     => 'File',
      lock      => 'Null',
      generate  => 'MD5',
      serialize => 'Storable',
    );

$params{directory} = File::Temp::tempdir( CLEANUP => 1 );

# We do this to generate a pre-existing session id that will be used
# in the tests below.
use Apache::Session::Flex;
my %session;
tie %session, 'Apache::Session::Flex', undef,
    { Store     => 'File',
      Lock      => 'Null',
      Generate  => 'MD5',
      Serialize => 'Storable',
      Directory => $params{directory},
    };
$session{bar}{baz} = 1;
my $id = $session{_session_id};
untie %session;

{
    my $w = Apache::Session::Wrapper->new(%params);

    ok( tied %{ $w->session }, 'session is a tied thing' );
    isa_ok( tied %{ $w->session }, 'Apache::Session' );
}

{
    my $w = Apache::Session::Wrapper->new(%params);

    $w->session( session_id => $id )->{foo} = 'bar';
}

{
    my $w = Apache::Session::Wrapper->new(%params);

    is( $w->session( session_id => $id )->{foo}, 'bar',
        'stored a value in the session' );
}

{
    my $w = Apache::Session::Wrapper->new(%params);

    eval { $w->session( session_id => 'abcdef' ) };

    ok( ! $@, 'invalid session id is allowed by default' );
}

{
    my $w = Apache::Session::Wrapper->new( %params, allow_invalid_id => 0 );

    eval { $w->session( session_id => 'abcdef' ) };
    my $e = $@;

    ok( $e, 'invalid session id caused an error' );
    isa_ok( $e, 'Apache::Session::Wrapper::Exception::NonExistentSessionID' );
}

{
    my $w = Apache::Session::Wrapper->new(%params);

    $w->session( session_id => $id )->{bar}{baz} = 50;

    is( $w->session( session_id => $id )->{bar}{baz}, 50,
        'always write - in memory value' );
}

{
    my $w = Apache::Session::Wrapper->new(%params);

    is( $w->session( session_id => $id )->{bar}{baz}, 50,
        'always write - stored value' );
}


{
    my $w = Apache::Session::Wrapper->new( %params, always_write => 0 );

    $w->session( session_id => $id )->{bar}{baz} = 100;

    is( $w->session( session_id => $id )->{bar}{baz}, 100,
        'always write is off - in memory value' );
}

{
    my $w = Apache::Session::Wrapper->new( %params, always_write => 0 );

    is( $w->session( session_id => $id )->{bar}{baz}, 50,
        'always write is off - stored value' );

    $w = Apache::Session::Wrapper->new( %params, session_id => $id );
    is( $w->session->{_session_id}, $id, 'id matches session id given to new()' );
}

{
    my $w = Apache::Session::Wrapper->new( %params );

    $w->session( session_id => $id )->{quux} = 100;

    $w->delete_session;

    is( $w->session( session_id => $id )->{quux}, undef,
        'session is empty after delete_session' );
}

{
    no warnings 'redefine';
    # so attempt to connect to MySQL doesn't happen
    local *Apache::Session::Wrapper::_make_session = sub {};

    my $wrapper =
        eval { local $^W = 0;
               Apache::Session::Wrapper->new( class     => 'Flex',
                                              store     => 'MySQL',
                                              lock      => 'Null',
                                              generate  => 'MD5',
                                              serialize => 'Storable',
                                              data_source => 'foo',
                                              user_name   => 'bar',
                                              password    => 'baz',
                                            ) };
    unlike( $@, qr/parameters/, 'pass correct parameters for MySQL flex' );

    is( $wrapper->{params}{DataSource}, 'foo', 'DataSource is foo' );
    is( $wrapper->{params}{UserName}, 'bar', 'UserName is bar' );
    is( $wrapper->{params}{Password}, 'baz', 'Password is baz' );
}

{
    eval { local $^W = 0;
           Apache::Session::Wrapper->new( class       => 'Postgres',
                                          data_source => 'foo',
                                          user_name   => 'foo',
                                          password    => 'foo',
                                          commit      => 0,
                                        ) };
    unlike( $@, qr/parameters/, 'first param set for Pg' );
}

{
    my $dbh = bless {}, 'DBI';

    eval { local $^W = 0;
           Apache::Session::Wrapper->new( class  => 'Postgres',
                                          handle => $dbh,
                                          commit => 0,
                                        ) };
    unlike( $@, qr/parameters/, 'second param set for Pg' );
}

{
    my $dbh = bless {}, 'DBI';

    eval { Apache::Session::Wrapper->new( class  => 'Postgres',
                                          commit => 0,
                                        ) };
    like( $@, qr/required parameters.+missing: handle/, 'incomplete params for Pg' );
}
