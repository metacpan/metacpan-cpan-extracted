#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use Test::More;
    use lib './lib';
    use vars qw( $IS_SUPPORTED $DEBUG );
    use_ok( 'Apache2::SSI::Notes' ) || BAIL_OUT( "Unable to load Apache2::SSI::Notes" );
    use_ok( 'Apache2::SSI::SharedMem' ) || BAIL_OUT( "Unable to load Apache2::SSI::SharedMem" );
    our $IS_SUPPORTED = 1;
    if( !Apache2::SSI::SharedMem->supported )
    {
        # plan skip_all => 'IPC::SysV not supported on this system';
        $IS_SUPPORTED = 0;
    }
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

SKIP:
{
    skip( 'IPC::SysV not supported on this system', 39 ) if( !$IS_SUPPORTED );
    ok( scalar( keys( %$Apache2::SSI::SharedMem::SEMOP_ARGS ) ) > 0, 'sempahore parameters' );
    BAIL_OUT( '$SEMOP_ARGS not set somehow!' ) if( !scalar( keys( %$Apache2::SSI::SharedMem::SEMOP_ARGS ) ) );

    ok( Apache2::SSI::SharedMem->supported, 'supported' );

    my $shem = Apache2::SSI::SharedMem->new(
        debug => $DEBUG,
        key => 'test_key',
        size => 2048,
        destroy => 1,
        mode => 0666,
    );
    ## Clean up


    ok( $shem->create == 0, 'create default value' );
    $shem->create( 1 );
    ok( $shem->create == 1, 'create updated value' );
    my $exists = $shem->exists;
    ## ok( defined( $exists ), 'exists return defined value' );
    # ok( !$shem->exists, 'exists' );
    ok( defined( $exists ) && !$exists, 'exists' );
    my $s = $shem->open;
    ok( defined( $s ), 'Shared memory object' );
    BAIL_OUT( "Failed to create shared memory object: $!" ) if( !defined( $s ) );

    isa_ok( $s, 'Apache2::SSI::SharedMem' );
    my $id = $s->id;
    ok( defined( $id ) && $id =~ /\S+/, "shared memory id is \"$id\"" );
    my $semid = $s->semid;
    ok( defined( $semid ) && $semid =~ /\S+/, "semaphore id is \"$semid\"" );
    my $owner = $s->owner;
    ok( defined( $owner ) && $owner =~ /\S+/, "shared memory owner \"$owner\"" );
    my $test_data = { name => 'John Doe', location => 'Tokyo' };
    my $shem_object = $s->write( $test_data );
    ok( defined( $shem_object ), 'write' );
    ok( overload::StrVal( $s ) eq overload::StrVal( $shem_object ), 'write return value' );
    my $buffer = $s->read;
    ok( defined( $buffer ), 'read no argument' );
    ok( ref( $buffer ) eq 'HASH', 'read buffer data integrity' );
    if( ref( $buffer ) eq 'HASH' && $buffer->{name} eq 'John Doe' && $buffer->{location} eq 'Tokyo' )
    {
        pass( 'read data check' );
    }
    else
    {
        fail( 'read data check' );
    }
    my $result = qx( $^X ./t/80.sharedmem.pl 2>&1 );
    chomp( $result );
    if( $result eq 'ok' )
    {
        pass( 'shared data with separate process' );
    }
    else
    {
        diag( "Failed process with: '$result'" );
        fail( 'shared data with separate process' );
    }
    my $data = $s->read;
    ok( ref( $data ) eq 'HASH', 'shared updated data type' );
    ok( $data->{year} == 2021, 'updated data value' );
    my $data2;
    $s->read( $data2 );
    ok( ref( $data2 ) eq 'HASH', 'different read usage' );
    ok( $data2->{year} == 2021, 'different read data check' );
    ok( defined( $s->lock ), 'lock' );
    ok( $s->locked, 'locked' );
    $data->{test} = 'ok';
    ok( defined( $s->write( $data ) ), 'updated data with lock' );
    ok( defined( $s->unlock ), 'unlock' );
    ok( defined( $s->remove ), 'remove' );
    ok( !$s->exists, 'exists after remove' );

    ## Notes

    my $n = Apache2::SSI::Notes->new( debug => $DEBUG, key => 'test_notes' );
    isa_ok( $n, 'Apache2::SSI::Notes' );

    my $all = $n->get;
    ok( ref( $all ) eq 'HASH', 'notes respository data type' );
    ok( !scalar( keys( %$all ) ), 'initially empty' );
    $n->set( PersonId => '1234567', 'set' );
    ok( $n->get( 'PersonId' ) eq '1234567', 'get' );
    my $c = 0;
    $n->do(sub
    {
        $c++ if( $_[0] eq 'PersonId' && $_[1] eq '1234567' );
        $_[1] = '12345678';
    });
    ok( $c == 1, 'do' );
    ok( $n->get( 'PersonId' ) eq '12345678', 'get check' );
    ok( defined( $n->unset( 'PersonId' ) ), 'unset' );
    ok( !defined( $n->get( 'PersonId' ) ), 'check after unset' );
    ok( $n->set( 'name' => 'John Doe' ), 'set 2' );
    $all = $n->get;
    ok( scalar( keys( %$all ) ) == 1, 'get all' );
    ok( $all->{name} eq 'John Doe' );
    ok( defined( $n->clear ), 'clear' );
    $all = $n->get;
    ok( scalar( keys( %$all ) ) == 0, 'data check after clear' );
    diag( "Removing test notes." ) if( $DEBUG );
    $n->remove;
}

done_testing();
