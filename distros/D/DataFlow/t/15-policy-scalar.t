use Test::More tests => 4;

use DataFlow::Proc;

# tests: 1
my $uc = DataFlow::Proc->new(
    policy => 'Scalar',
    p      => sub { uc },
);
ok($uc);

is( ( $uc->process('aaa') )[0], 'AAA', 'works for a simple processing' );
my $aref       = [qw/aa bb cc dd ee ff/];
my $aref_procd = ( $uc->process($aref) )[0];
is( $aref_procd,      $aref, 'preserves non-strings' );
is( $aref_procd->[2], 'cc',  q{preserves references' properties} );

