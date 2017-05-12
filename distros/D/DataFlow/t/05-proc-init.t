use Test::More tests => 10;

use DataFlow::Proc;

my $uc = sub { uc };

sub test_uc_with {
    my @args = @_;
    my $proc = DataFlow::Proc->new(@args);
    ok($proc);
    my @res = $proc->process('abcdef');
    is( $res[0], 'ABCDEF' );
}

test_uc_with( p => $uc );
test_uc_with( p => DataFlow::Proc->new( p => $uc ) );
use DataFlow;
test_uc_with( p => DataFlow->new( [ DataFlow::Proc->new( p => $uc ) ] ) );
test_uc_with( p => DataFlow->new( [$uc] ) );
test_uc_with($uc);

