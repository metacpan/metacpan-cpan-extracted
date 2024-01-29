#!perl

use Test2::V0;

use Test::Lib;

use Data::Record::Serialize;

use Data::Dumper;

sub Serializer {
    my $buffer = shift;
    Data::Record::Serialize->new( output => $buffer, encode => '+My::Test::Encode::workflow' );
}

subtest close => sub {

    my ( $s, @output );
    ok(
        lives {
            $s = Serializer( \@output );
        },
        'constructor',
    ) or diag $@;

    $s->send( { key => 'value' } );

    $s->close;

    is( \@output, [ 'start', { key => 'value' }, 'finalize' ], );
};

subtest demolish => sub {

    my @output;
    subtest 'write' => sub {
        my $s;
        ok(
            lives {
                $s = Serializer( \@output );
            },
            'constructor',
        ) or diag $@;

        $s->send( { key => 'value' } );
    };

    is( \@output, [ 'start', { key => 'value' }, 'finalize' ], );
};

done_testing;
