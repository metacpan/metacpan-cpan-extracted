use Test::More tests => 5;

use DataFlow::Proc;

# tests: 1
my $uc = DataFlow::Proc->new(
    policy => 'ScalarOnly',
    p      => sub { uc },
);
ok($uc);

is( ( $uc->process('aaa') )[0], 'AAA', 'works for a simple processing' );
my $aref       = [qw/aa bb cc dd ee ff/];
my $aref_procd = ( $uc->process($aref) )[0];
isnt( $aref_procd,      $aref, 'preserves non-strings' );
isnt( $aref_procd->[2], 'cc',  q{preserves references' properties} );
isnt( $aref_procd->[2], 'CC',
    q{does not applies processor in nested data structures} );

