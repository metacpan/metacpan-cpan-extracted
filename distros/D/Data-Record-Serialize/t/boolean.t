#! perl

use feature 'say';

use Test2::V0;
use Data::Record::Serialize;

subtest 'no encoder support' => sub {
    my $drs;
    my $output;
    ok(
        lives {
            $drs = Data::Record::Serialize->new(
                encode => 'ddump',
                output => \$output,
                types  => {
                    bool => 'B'
                } );
        },
        'construct object'
    ) or note $@;

    for my $test (
        [ '',    0, '""' ],
        [ '0',   0, '"0"' ],
        [ 0,     0, '0' ],
        [ undef, 0, 'undef' ],
        [ '1',   1, '"1"' ],
        [ 1,     1, '1' ],
      )
    {
        my ( $send, $expect, $label ) = @$test;

        $drs->fh->seek( 0, 0 );
        $drs->send( { bool => $send } );
        my $got = eval $output;    ## no critic(ProhibitStringyEval)
        is( $got, { bool => $expect }, "bool = $label" );
    }
};

{
    package My::Test::Encode::bool;
    use Moo::Role;

    sub map_types { { B => 'B' } }
    sub to_bool   { $_[1] ? 'true' : 'false' }
    with 'Data::Record::Serialize::Encode::ddump';
}

subtest 'encoder support' => sub {

    my $drs;
    my $output;
    ok(
        lives {
            $drs = Data::Record::Serialize->new(
                encode => '+My::Test::Encode::bool',
                output => \$output,
                types  => {
                    bool => 'B'
                } );
        },
        'construct object'
    ) or note $@;

    for my $test (
        [ '',    'false', '""' ],
        [ '0',   'false', '"0"' ],
        [ 0,     'false', '0' ],
        [ undef, 'false', 'undef' ],
        [ '1',   'true',  '"1"' ],
        [ 1,     'true',  '1' ],
      )
    {
        my ( $send, $expect, $label ) = @$test;

        $drs->fh->seek( 0, 0 );
        $drs->send( { bool => $send } );
        my $got = eval $output;    ## no critic(ProhibitStringyEval)
        is( $got, { bool => $expect }, "bool = $label" );
    }
};

done_testing;
