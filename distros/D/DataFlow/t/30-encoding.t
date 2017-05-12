use Test::More tests => 5;

use_ok('DataFlow::Proc::Encoding');
new_ok('DataFlow::Proc::Encoding');

sub convert_ok {
    my $test = ref( $_[0] ) eq 'HASH' ? shift : {@_};

    my $e = DataFlow::Proc::Encoding->new(
        from => $test->{from}->[0],
        to   => $test->{to}->[0],
    );

    my @res = $e->process( $test->{from}->[1] );
    ok( $res[0] eq $test->{to}->[1] );
}

convert_ok(
    from => [ 'iso8859-1' => "B\x{ed}cego" ],
    to   => [ 'utf8'      => "Bícego" ]
);

my $e = DataFlow::Proc::Encoding->new(
    policy => 'Scalar',
    from   => 'iso8859-1',
    to     => 'utf8'
);
ok($e);
is( ( $e->process("\x{e9}") )[0], "é", 'converts characters properly' );

