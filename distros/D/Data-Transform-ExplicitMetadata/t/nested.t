use strict;
use warnings;

use Data::Transform::ExplicitMetadata qw(encode decode);

use Scalar::Util qw(refaddr);
use Test::More tests => 12;

test_nested_struct();
test_nested_with_duplicate_ref();

sub test_nested_struct {
    my $stringref = \'a string';

    our $overloaded_glob = 1;
    our @overloaded_glob = ( 1 );
    our %overloaded_glob = ( one => 1 );
    sub overloaded_glob { 1 }
    my $globref = \*overloaded_glob;

    use vars '$STDOUT';
    my $stdoutref = \*STDOUT;

    my $arrayref = [
        1,
        2,
        $stringref,
        $stdoutref,
    ];

    my $original = {
        one => 1,
        two => 2,
        array => $arrayref,
        glob => $globref,
    };

    my $expected = {
        __refaddr => refaddr($original),
        __reftype => 'HASH',
        __value => {
            one => 1,
            two => 2,
            array => {
                __refaddr => refaddr($arrayref),
                __reftype => 'ARRAY',
                __value => [
                    1,
                    2,
                    {
                        __refaddr => refaddr($stringref),
                        __reftype => 'SCALAR',
                        __value => $$stringref,
                    },
                    {
                        __reftype => 'GLOB',
                        __refaddr => refaddr($stdoutref),
                        __value => {
                            NAME => 'STDOUT',
                            PACKAGE => 'main',
                            IO => fileno(STDOUT),
                            SCALAR => {
                                __reftype => 'SCALAR',
                                __value => undef,
                                __refaddr => refaddr(\$STDOUT),
                            }
                        }
                    },
                ],
            },
            glob => {
                __refaddr => refaddr($globref),
                __reftype => 'GLOB',
                __value => {
                    NAME => 'overloaded_glob',
                    PACKAGE => 'main',
                    SCALAR => {
                        __reftype => 'SCALAR',
                        __refaddr => refaddr(\$overloaded_glob),
                        __value => 1,
                    },
                    ARRAY => {
                        __reftype => 'ARRAY',
                        __refaddr => refaddr(\@overloaded_glob),
                        __value => [ 1 ],
                    },
                    HASH => {
                        __reftype => 'HASH',
                        __refaddr => refaddr(\%overloaded_glob),
                        __value => { one => 1 },
                    },
                    CODE => {
                        __reftype => 'CODE',
                        __refaddr => refaddr(\&overloaded_glob),
                        __value => sprintf('CODE(0x%x)', refaddr(\&overloaded_glob)),
                    },
                },
            }
        }
    };

    my $encoded = encode($original);

    # different platforms have different values for the seek position of STDOUT
    # For example, running this test with prove, I get undef on Unix-like systems
    # and '0 but true' on Windows.  Running the test directly with perl, I get a
    # large-ish positive number
    ok(exists $encoded->{__value}{array}{__value}[3]{__value}{IOseek}, 'IO slot has IOseek key');
    delete $encoded->{__value}{array}{__value}[3]{__value}{IOseek};

    my $open_mode = delete $encoded->{__value}{array}{__value}[3]{__value}{IOmode};

    SKIP: {
        skip(q(Filehandle open mode tests don't work on Windows), 1) if ($^O =~ m/MSWin/);
        ok(($open_mode eq '>') || ($open_mode eq '+<'),
            'IO slot open mode');
    };

    is_deeply($encoded, $expected, 'encode nested data structure');

    my $decoded = decode($encoded);

    # globs need special inspection
    my $original_overloaded_glob = delete($original->{glob});
    my $decoded_overloaded_glob = delete($decoded->{glob});
    my $original_stdout_glob = splice(@{$original->{array}}, 3, 1);
    my $decoded_stdout_glob = splice(@{$decoded->{array}}, 3, 1);

    is_deeply($decoded, $original, 'decode nested data structure');

    ok(defined(fileno $decoded_stdout_glob), 'decoded stdout glob has fileno');
    is(fileno($decoded_stdout_glob), fileno($original_stdout_glob), 'decoded stdout glob has correct fileno');

    is(ref(*{$decoded_overloaded_glob}{CODE}), 'CODE', 'overloaded glob code');
    is_deeply(*{$decoded_overloaded_glob}{SCALAR}, \$overloaded_glob, 'overloaded glob scalar');
    is_deeply(*{$decoded_overloaded_glob}{ARRAY}, \@overloaded_glob, 'overloaded glob array');
    is_deeply(*{$decoded_overloaded_glob}{HASH}, \%overloaded_glob, 'overloaded glob hash');
}

sub test_nested_with_duplicate_ref {
    my $nested_array = [ 1 ];
    my $original = [ $nested_array, $nested_array ];
    my $expected = {
        __reftype => 'ARRAY',
        __refaddr => refaddr($original),
        __value => [
            {
                __reftype => 'ARRAY',
                __refaddr => refaddr($nested_array),
                __value => [ 1 ],
            },
            {
                __reftype => 'ARRAY',
                __refaddr => refaddr($nested_array),
                __recursive => 1,
                __value => '$VAR->[0]',
            }
        ],
    };
    my $encoded = encode($original);
    is_deeply($encoded, $expected, 'encode array with duplicated element refs');

    my $decoded = decode($encoded);
    is_deeply($decoded, $original, 'decode array with duplicated element refs');
}
