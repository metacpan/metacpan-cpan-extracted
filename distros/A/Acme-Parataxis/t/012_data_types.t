use v5.40;
use Test2::V1 -ipP;
use blib;
use Acme::Parataxis;
$|++;

# Helper to flush Perl's temporary stack (tmps).
# Returning an object from XS creates a mortal SV. Even after the Perl variable
# ($res) is cleared, the mortal reference remains until the current scope exits
# or FREETMPS is called. Calling a simple fiber forces an ENTER/LEAVE cycle.
sub flush_stack {
    Acme::Parataxis->new( code => sub {1} )->call();
}
subtest 'Multiple Complex Arguments' => sub {
    my $fiber = Acme::Parataxis->new(
        code => sub ( $hash, $array, $scalar ) {
            is ref $hash,   'HASH',  'Arg 1 is HASH';
            is ref $array,  'ARRAY', 'Arg 2 is ARRAY';
            is ref $scalar, '',      'Arg 3 is SCALAR';
            return { result => [ $scalar, $array, $hash ] };
        }
    );
    my $input_h = { a => 1 };
    my $input_a = [ 2, 3 ];
    my $input_s = "four";
    my $res     = $fiber->call( $input_h, $input_a, $input_s );
    is $res->{result}, [ $input_s, $input_a, $input_h ], 'Returned re-ordered arguments correctly';
};
subtest 'Deeply Nested Structure' => sub {
    my $deep  = { level1 => { level2 => [ { val => 42 }, { val => 43 } ] } };
    my $fiber = Acme::Parataxis->new(
        code => sub ($data) {
            return $data->{level1}{level2}[1];
        }
    );
    my $res = $fiber->call($deep);
    is $res, { val => 43 }, 'Extracted data from deep structure correctly';
};
subtest 'Return Hash Reference' => sub {
    my $fiber = Acme::Parataxis->new(
        code => sub {
            return { key => 'value', nested => [ 1, 2, 3 ] };
        }
    );
    my $res = $fiber->call();
    is ref $res,       'HASH',      'Returned a HASH reference';
    is $res->{key},    'value',     'Hash key is correct';
    is $res->{nested}, [ 1, 2, 3 ], 'Nested array is correct';
    ok $fiber->is_done, 'Fiber finished';
};
subtest 'Yield and Resume with Complex Data' => sub {
    my $fiber = Acme::Parataxis->new(
        code => sub {
            my $input = Acme::Parataxis->yield( { status => 'waiting' } );
            is( ref $input, 'ARRAY', 'Received an ARRAY reference via yield' );
            return { received => $input };
        }
    );
    diag 'Calling fiber (step 1)...';
    my $yielded = $fiber->call();
    is $yielded->{status}, 'waiting', 'Yielded HASH correctly';
    diag 'Resuming fiber with an array ref...';
    my $final = $fiber->call( [ 'A', 'B' ] );
    is $final->{received}, [ 'A', 'B' ], 'Final return contains the resumed data';
};
our $DESTROYED = 0;
{

    package Local::Destructor {
        use Test2::V1 qw[diag];
        sub new { bless { name => pop @_ }, $_[0] }

        sub DESTROY ( $self, @ ) {
            diag 'Destroy ' . $self->{name};
            $main::DESTROYED++;
        }
    }
}
subtest 'Objects with Destructors' => sub {
    $DESTROYED = 0;
    subtest 'Passing object into fiber' => sub {
        {
            my $obj   = Local::Destructor->new('A');
            my $fiber = Acme::Parataxis->new(
                code => sub ($o) {
                    isa_ok $o, ['Local::Destructor'], 'Fiber returned object';
                    return 'OK';
                }
            );
            $fiber->call($obj);
            $obj = undef;    # Local ref gone

            # Fiber should have finished and reported its results, releasing the arg
            is $DESTROYED, 1, 'Object destroyed (fiber finished and released args)';
        }
    };
    $DESTROYED = 0;
    subtest 'Returning object from fiber' => sub {
        my $res;
        {
            my $fiber = Acme::Parataxis->new( code => sub { Local::Destructor->new('B') } );
            $res = $fiber->call();
            isa_ok $res, ['Local::Destructor'], 'Fiber returned object';

            # Fiber is technically done, but we manually flag it to ensure
            # the Perl-side wrapper drops its internal references.
            $fiber->is_done();
            is $DESTROYED, 0, 'Object still alive in parent var';
        }
        $res = undef;

        # Force a stack cycle to clear the mortal reference returned by the XS call
        flush_stack();
        is $DESTROYED, 1, 'Object destroyed in parent after release';
    };
};
#
done_testing();
