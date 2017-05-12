use Test::More tests => 44;

use strict;

use DataFlow;
use DataFlow::Proc;

# each call = 2 tests
sub test_uc_with {
    my $flow = DataFlow->new(@_);
    ok( $flow, q{test_uc_wth(} . join( q{,}, @_ ) . q{)} );
    my @res = $flow->process('abcdef');
    is( $res[0], 'ABCDEF', '...and returns the right value' );
}

my $uc = sub { uc };
my $proc = DataFlow::Proc->new( p => $uc );
my $flow = DataFlow->new( procs => [$proc] );
my $nested = DataFlow->new( [$flow] );

# proc
test_uc_with( procs => [$proc] );    # 1,2
test_uc_with( procs => $proc );
test_uc_with( [$proc] );
test_uc_with($proc);                 # 7,8

# code
test_uc_with( procs => [$uc] );      # 9,10
test_uc_with( procs => $uc );
test_uc_with( [$uc] );
test_uc_with($uc);                   # 15,16

# flow
test_uc_with( procs => [$flow] );    # 17,18
test_uc_with( procs => $flow );
test_uc_with( [$flow] );
test_uc_with($flow);                 # 23,24

# nested
test_uc_with( procs => [$nested] );    # 25,26
test_uc_with( procs => $nested );
test_uc_with( [$nested] );
test_uc_with($nested);                 # 31,32

# string
test_uc_with( procs => ['UC'] );       # 33,34
test_uc_with( procs => 'UC' );
test_uc_with( ['UC'] );
test_uc_with('UC');                    # 47,48

# each call = 2 tests
sub test_ucf_with {
    my $flow = DataFlow->new(@_);
    ok( $flow, q{test_ucf_wth(} . join( q{,}, @_ ) . q{)} );
    my @res = $flow->process('abcdef');
    is( $res[0], 'Abcdef' );
}

my $ucfirst = sub { ucfirst };
my @mix = ( $nested, $flow, $proc, 'UC', sub { lc }, $ucfirst );

# mix
test_ucf_with( procs => [@mix] );
test_ucf_with( [@mix] );

