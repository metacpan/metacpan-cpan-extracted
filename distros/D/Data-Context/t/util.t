use strict;
use warnings;
use Test::More;
use Data::Dumper qw/Dumper/;

use Data::Context::Util qw/lol_path lol_iterate do_require/;

my ($data, $tests) = get_data();
test_lol_path();
test_lol_iterate();
test_do_require();

done_testing;

sub test_lol_path {

    for my $path ( keys %$tests ) {
        is lol_path($data, $path)
            , $tests->{$path}
            , "lol_path '$path' returns ".(defined $tests->{$path} ? "'$tests->{$path}'" : 'undef');
    }

    my $replacer;
    my $data = Data::Context::Util::lol_path( {}, 'a' );
    is_deeply $data, undef, 'Non-existant path returns undef';

    $data = Data::Context::Util::lol_path( { b => [] }, 'a.b' );
    is_deeply $data, undef, 'Non-existant path returns undef';

    $data = Data::Context::Util::lol_path( { b => [] }, 'b' );
    is_deeply $data, [], 'get hash value';

    $data = Data::Context::Util::lol_path( { b => [1] }, 'b.0' );
    is_deeply $data, 1, 'Get array value';

    $data = Data::Context::Util::lol_path( [2], '0' );
    is_deeply $data, 2, 'Get value from array lol';

    eval { $data = Data::Context::Util::lol_path( [\'str ref'], '0.a' ); };
    my $error = $@;
    like $error, qr/^Don't know how to deal with SCALAR/, 'Error on scalar ref';

    eval { $data = Data::Context::Util::lol_path( [Dummy->new(data => {})], '0.a' ); };
    $error = $@;
    like $error, qr/^Don't know how to deal with Dummy/, 'Error on object with no accessor';

    my $raw = [{ replace => 'me'}];
    ($data, $replacer) = Data::Context::Util::lol_path( $raw, '0' );
    is_deeply $data, { replace => 'me'}, 'Get value from array lol';
    $data = $replacer->(['my data']);
    is_deeply $raw, [['my data']], 'Replace sub path data with replacer'
        or diag explain $raw, $data;

    ($data, $replacer) = Data::Context::Util::lol_path( $raw, '' );
    $data = $replacer->(['my data']);
    is_deeply $raw, ['my data'], 'Replace all data ARRAY with replacer'
        or diag explain $raw, $data;

    $raw = { b => 2 };
    ($data, $replacer) = Data::Context::Util::lol_path( $raw, '' );
    $data = $replacer->({ a => 1 });
    is_deeply $raw, { a => 1 }, 'Replace all data HASH with replacer'
        or diag explain $raw, $data;

    $raw = '';
    ($data, $replacer) = Data::Context::Util::lol_path( $raw, '' );
    eval { $replacer->({ a => 1 }); };
    $error = $@;
    like $error, qr/^Can't replace ''!/, 'Error on object with no accessor';

    $data = Data::Context::Util::lol_path( $raw, '' );
    is_deeply $data, $raw, 'Get what I put in back';
}

sub test_lol_iterate {
    my %result;
    lol_iterate(
        $data,
        sub {
            my ( $data, $path ) = @_;
            $result{$path} = $data if $path;
        }
    );

    for my $path ( keys %$tests ) {
        is $result{$path}, $tests->{$path}, "lol_iterate saw '$path' had a value of '".(defined $tests->{$path} ? $tests->{$path} : '')."'";
    }

    # iterate over constant data
    %result = ();
    lol_iterate(
        1,
        sub {
            my ( $data, $path ) = @_;
            $result{$path || ''} = $data;
        }
    );
    is_deeply {''=>1}, \%result, "Iterate over constant object ok";

    # itterate over null data
    %result = ();
    lol_iterate(
        undef,
        sub {
            my ( $data, $path ) = @_;
            $result{$path || ''} = $data;
        }
    );
    is_deeply {}, \%result, "Iterate over undefined object without path ok";

    # with a defined path
    lol_iterate(
        undef,
        sub {
            my ( $data, $path ) = @_;
            $result{$path || ''} = $data;
        },
        'path'
    );
    is_deeply {}, \%result, "Iterate over undefined object with path ok"
        or note Dumper \%result;
}

sub test_do_require {
    eval { do_require('123::B456'); };
    ok $@, 'Get error loading bad module';
}

sub get_data {
    return (
        {
            a => "A",
            b => [
                {
                    b_a => "B A",
                },
                {
                    b_b => [
                        {
                            b_b_a => "B B A",
                        },
                        {
                            b_b_b => "B B B",
                        },
                    ],
                },
            ],
            c => Dummy->new(
                data => {
                    'c_a' => 'C A',
                }
            ),
            d => bless [], 'other object',
        },
        {
            'a'               => 'A',
            'b.0.b_a'         => "B A",
            'b.1.b_b.1.b_b_b' => "B B B",
            'c.data.c_a'      => 'C A',
            'e'               => undef,
            'b.1.b_b.1.b_b_e' => undef,
            'b.1.b_b.2.b_b_e' => undef,
            'b.1.b_b.1.._b_e' => undef,
            'a.0'             => undef,
        }
    );
}

package Dummy;

use Moose;

BEGIN {
    has data => (
        is  => 'rw',
        isa => 'HashRef',
    );
};
