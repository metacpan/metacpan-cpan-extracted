use Test::More tests => 15;

use DataFlow::Proc;

# tests: 1
my $uc = DataFlow::Proc->new(
    policy => 'ProcessInto',
    p      => sub { uc },
);
ok($uc);
is( ( $uc->process('aaa') )[0], 'AAA', 'works for a simple processing' );

my $aref       = [qw/aa bb cc dd ee ff/];
my $aref_procd = ( $uc->process($aref) )[0];

#isnt( $aref_procd, $aref, 'preserves non-strings' );
is( $aref_procd->[2], 'CC', q{preserves references' properties} );

my $complex = {
    a => 'aaa',
    b => [ 'b0', 'b1', 'b3' ],
    c => {
        c1 => 'c1a',
        c2 => [
            'c2aa',
            {
                c2bb => 'c2bb11',
                c2cc => 'c2cc11',
                c2dd => [qw/c2dd omg this is deep/],
            }
        ],
        c3 => 'c3a',
    },
};

my $cres = ( $uc->process($complex) )[0];

#use Data::Dumper; warn Dumper($cres);

ok( exists $cres->{a} );
is( $cres->{a}, 'AAA' );

ok( exists $cres->{b} );
is( $cres->{b}->[0], 'B0' );
is( $cres->{b}->[1], 'B1' );
is( $cres->{b}->[2], 'B3' );

ok( exists $cres->{c} );
is( $cres->{c}->{c1},              'C1A' );
is( $cres->{c}->{c2}->[0],         'C2AA' );
is( $cres->{c}->{c2}->[1]->{c2bb}, 'C2BB11' );
is( $cres->{c}->{c2}->[1]->{c2cc}, 'C2CC11' );
is_deeply( $cres->{c}->{c2}->[1]->{c2dd}, [qw/C2DD OMG THIS IS DEEP/] );

