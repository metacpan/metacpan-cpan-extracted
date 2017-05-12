use Test::More tests => 3;

use DataFlow::Proc;
use DataFlow::Policy::WithSpec;

# tests: 1
my $uc = DataFlow::Proc->new(
    p      => sub                                   { uc },
    policy => DataFlow::Policy::WithSpec->new( spec => '->[2]', ),
);
ok($uc);

my $aref       = [qw/aa bb cc dd ee ff/];
my $aref_procd = ( $uc->process($aref) )[0];
is( $aref_procd, $aref, 'preserves non-strings' );
is_deeply( $aref_procd, [qw/aa bb CC dd ee ff/] );

