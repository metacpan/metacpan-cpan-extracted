#!/usr/bin/perl -w

use strict;

use File::Temp ();

use Test::More tests => 10;

use Apache::Session::Wrapper;


my $tempdir = File::Temp::tempdir( CLEANUP => 1 );

{
    {
        package Apache::Session::FooBar;
        use base 'Apache::Session::File';
    }
    # Passing the full name with Apache::Session:: prefix makes sure
    # we can handle that.
    Apache::Session::Wrapper->RegisterClass
        ( name     => 'Apache::Session::FooBar',
          required => 'File',
        );

    eval { Apache::Session::Wrapper->new
               ( class         => 'FooBar',
                 directory      => $tempdir,
                 lock_directory => $tempdir,
               ) };
    is( $@, '', 'made a new wrapper using FooBar class' );

    eval { Apache::Session::Wrapper->new( class => 'FooBar' ) };

    like( $@, qr/required parameters.+missing: directory/, 'incomplete params for FooBar' );
}

{
    {
        package Apache::Session::Baz;
        use base 'Apache::Session::File';
    }

    Apache::Session::Wrapper->RegisterClass( name     => 'Baz',
                                             required => [ [ 'thing' ] ],
                                             optional => [ 'foo' ],
                                           );

    eval { Apache::Session::Wrapper->new( class => 'Baz',
                                          thing => 1,
                                        ) };
    is( $@, '', 'made a new wrapper using Baz class' );

    eval { Apache::Session::Wrapper->new( class => 'Baz',
                                          thing => 1,
                                          foo   => 27,
                                        ) };
    is( $@, '', 'made a new wrapper using Baz class with optional param' );

    eval { Apache::Session::Wrapper->new( class => 'Baz' ) };

    like( $@, qr/required parameters.+missing: thing/, 'incomplete params for Baz' );

    eval { Apache::Session::Wrapper->new( class => 'Baz',
                                          thing => 1,
                                          bar   => 5,
                                        ) };

    like( $@, qr/following parameter/, 'extra invalid param for Baz' );
}

{
    {
        package Apache::Session::Quux;
        use base 'Apache::Session::File';
    }

    # Tests multiple valid sets of required params.
    Apache::Session::Wrapper->RegisterClass( name     => 'Quux',
                                             required => [ [ 'thing1', 'thing2' ],
                                                           [ 'kitty' ],
                                                         ],
                                           );

    eval { Apache::Session::Wrapper->new( class  => 'Quux',
                                          thing1 => 1,
                                          thing2 => 1,
                                        ) };
    is( $@, '', 'made a new wrapper using Quux class' );

    eval { Apache::Session::Wrapper->new( class => 'Quux',
                                          kitty => 'Hello',
                                        ) };
    is( $@, '', 'made a new wrapper using Quux class' );

    eval { Apache::Session::Wrapper->new( class  => 'Quux',
                                          thing1 => 1,
                                        ) };
    like( $@, qr/some or all/i, 'missing required params for Quux' );
}

{
    {
        package Apache::Session::Store::Dummy;
        use base 'Apache::Session::Store::File';
    }

    {
        package Apache::Session::Generate::Dummy;
        use Apache::Session::Generate::MD5;

        # double assignment prevents a "used only once" warning
        *Apache::Session::Generate::Dummy::generate =
        *Apache::Session::Generate::Dummy::generate =
            \&Apache::Session::Generate::MD5::generate;

        *Apache::Session::Generate::Dummy::validate =
        *Apache::Session::Generate::Dummy::validate =
            \&Apache::Session::Generate::MD5::validate;
    }

    Apache::Session::Wrapper->RegisterFlexClass
        ( name     => 'Apache::Session::Store::Dummy',
          type     => 'store',
          required => [ [ 'size' ] ],
        );

    Apache::Session::Wrapper->RegisterFlexClass
        ( name     => 'Generate::Dummy',
          type     => 'generate',
          required => [ [ 'seed' ] ],
          optional => [ 'goo' ],
        );

    eval { Apache::Session::Wrapper->new
            ( class     => 'Flex',
              store     => 'Dummy',
              lock      => 'Null',
              generate  => 'Dummy',
              serialize => 'Storable',
              size      => 'big',
              seed      => 'corn',
            ) };
    is( $@, '', 'made a new Flex wrapper with Dummy store & generate' );

}


