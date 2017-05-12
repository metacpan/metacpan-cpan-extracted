use Test::More tests => 12;

use strict;

use DataFlow;
use DataFlow::Proc;

# each call = 2 tests
sub test_uc_with {
    my $flow = dataflow @_;
    ok( $flow, q{test_uc_wth(} . join( q{,}, @_ ) . q{)} );
    my @res = $flow->process('abcdef');
    is( $res[0], 'ABCDEF', '...and returns the right value' );
}

my $uc = sub { uc };
my $proc = DataFlow::Proc->new( p => $uc );
my $flow = DataFlow->new( procs => [$proc] );
my $nested = DataFlow->new( [$flow] );

# proc
test_uc_with($proc);

# code
test_uc_with($uc);

# flow
test_uc_with($flow);

# nested
test_uc_with($nested);

# string
test_uc_with('UC');

# each call = 2 tests
sub test_ucf_with {
    my $flow = dataflow @_;
    ok( $flow, q{test_ucf_wth(} . join( q{,}, @_ ) . q{)} );
    my @res = $flow->process('abcdef');
    is( $res[0], 'Abcdef' );
}

my $ucfirst = sub { ucfirst };
my @mix = ( $nested, $flow, $proc, 'UC', sub { lc }, $ucfirst );

# mix
test_ucf_with(@mix);

