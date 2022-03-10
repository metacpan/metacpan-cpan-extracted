#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test2::IPC;
    use Module::Generic::File qw( file tempfile sys_tmpdir );
    # use Nice::Try debug_file => './dev/t_promise.log', debug => 4, debug_code => 1;
    use Nice::Try;
    use Test2::V0;
    # use Test::More qw( no_plan );
    use Time::HiRes;
    # For debugging only
    # use Devel::Confess;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use ok( 'Class::Promise', qw(:all) );
};

use warnings 'Class::Promise';
my $pid = $$;
diag( "Main pid is '$pid'" ) if( $DEBUG );
my $prom = Class::Promise->new(sub
{
    my $str = 'Test 1';
    diag( "[pid = $$] $str" ) if( $DEBUG );
    pass( 'child sub' );
    ok( $$ != $pid, 'code executed in sub process' );
    return( $str );
}, { debug => $DEBUG });
isa_ok( $prom, ['Class::Promise'], 'promise object' );

ok( !$prom->is_child, 'main process' );

$prom->then(sub
{
    my $val = shift( @_ );
    is( $val, 'Test 1', 'then' );
    diag( "My pid is '$$'" ) if( $DEBUG );
    ok( $$ != $pid, 'then() executed in sub process' );
});

Class::Promise->new(sub
{
    diag( "Dying..." ) if( $DEBUG );
    die( "Oh my!\n" );
}, { debug => $DEBUG, share_auto_destroy => $DESTROY_SHARED_MEM })->then(sub
{
    diag( "Got here, but should not" ) if( $DEBUG );
    fail( 'should not catch error' );
})->catch(sub
{
    like( $_[0], qr/\bOh\s+my\b/, 'catch error' );
});

subtest 'concurrency' => sub
{
    my $tmpdir = sys_tmpdir();
    my $tmpfile = $tmpdir->child( 'module_generic_promise_test.txt' );
    my $f = $tmpfile;
    $f->empty;
    $f->close;
    diag( "CONCURRENCY 1 with parent pid '$$'" ) if( $DEBUG );
    my $result : shared = '';
    my( $truc, %bidule, @chouette );
    $truc = 'Jean';
    %bidule = ( name => 'John', location => 'Paris' );
    @chouette = qw( Pierre Paul Jacques );
    share( $truc, %bidule, @chouette );
    my $p1 = Class::Promise->new(sub
    {
        print( STDERR "Concurrent promise 1 ($$), sleeping.\n" ) if( $DEBUG );
        diag( "Is \$result tied ? ", tied( $result ) ? 'Yes' : 'No', ". Value is -> '$result'" );
        sleep(2);
        $result .= "concurrency 1\n";
        my $file = $tmpfile->clone;
        diag( "Writing 'concurrency 1' to file $tmpfile and my pid is '$$' vs parent '$pid'" ) if( $DEBUG );
        $file->append( "concurrency 1\n" );
    }, { debug => $DEBUG })->then(sub
    {
        isa_ok( $_[0], ['Module::Generic::File'] );
    })->catch(sub
    {
        fail( 'concurrency test 1 with error: ' . $_[0] );
    });
#     })->wait;

    diag( "CONCURRENCY 2 with parent pid '$$'" ) if( $DEBUG );
    my $p2 = Class::Promise->new(sub
    {
        print( STDERR "Concurrent promise 2 ($$), sleeping.\n" ) if( $DEBUG );
        sleep(0.5);
        $result .= "concurrency 2\n";
        my $file = file( $tmpfile );
        diag( "Appending 'concurrency 2' to $tmpfile and my pid is '$$' vs parent '$pid'" ) if( $DEBUG );
        $file->append( "concurrency 2\n" );
    }, { debug => $DEBUG, timeout => 2 })->then(sub
    {
        isa_ok( $_[0], ['Module::Generic::File'] );
        $_[0];
    })->then(sub
    {
        isa_ok( $_[0], ['Module::Generic::File'] );
    })->catch(sub
    {
        fail( 'concurrency test 2 with error: ' . $_[0] );
    });
    #})->wait;
    
    diag( "Awaiting promise 1 and 2" ) if( $DEBUG );
    await( $p1, $p2 );
    diag( "Result now is '$result'" ) if( $DEBUG );
    is( $result, "concurrency 2\nconcurrency 1\n", 'concurrency' );
    
    $f = file( $tmpfile );
    my $lines = $f->lines;
    diag( $lines->length, " lines found in $tmpfile -> ", $lines->join( '' )->scalar ) if( $DEBUG );
    is( $lines->join( '' )->scalar, "concurrency 2\nconcurrency 1\n", 'concurrency check' );
    $f->empty;
};

done_testing();

__END__

