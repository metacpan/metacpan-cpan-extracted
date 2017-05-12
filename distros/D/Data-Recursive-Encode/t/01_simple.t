use strict;
use warnings;
use Test::More;
use Data::Recursive::Encode;
use Encode;

# utility functions
sub U($) { decode_utf8($_[0]) }
sub u($) { encode_utf8($_[0]) }
sub E($) { decode('euc-jp', $_[0]) }
sub e($) { encode('euc-jp', $_[0]) }
sub eU($) { e(U($_[0])) }

# -------------------------------------------------------------------------

subtest "decode_utf8" => sub {
    my $D = sub { Data::Recursive::Encode->decode_utf8(@_) };

    is_deeply([$D->('あいう')], [U('あいう')], 'scalar');
    is_deeply([$D->(\('あいう'))], [\(U('あいう'))], 'scalarref');
    is_deeply($D->(['あいう']), [U('あいう')], 'arrayref');
    is_deeply($D->({'あいう' => 'えお'}), {U('あいう'), U 'えお'}, 'hashref');

    {
        my $code = sub { };
        is_deeply(
            $D->(
                [
                    'あいう', $code,
                    bless( ['おや'], 'Foo' )
                ]
            ),
            [ U('あいう'), $code, bless( ['おや'], 'Foo' ) ],
            'coderef,blessed'
        );
    }
    done_testing;
};

# -------------------------------------------------------------------------

subtest "encode_utf8" => sub {
    my $E = sub { Data::Recursive::Encode->encode_utf8(@_) };

    is_deeply([$E->(U 'あいう')], [('あいう')], 'scalar');
    is_deeply([$E->(\(U 'あいう'))], [\(('あいう'))], 'scalarref');
    is_deeply($E->([U 'あいう']), [('あいう')], 'arrayref');
    is_deeply($E->({U('あいう') , U('えお')}), {('あいう'),  'えお'}, 'hashref');

    {
        my $code = sub { };
        is_deeply(
            $E->(
                [
                    U('あいう'), $code,
                    bless( [U('おや')], 'Foo' )
                ]
            ),
            [ ('あいう'), $code, bless( [U('おや')], 'Foo' ) ],
            'coderef,blessed'
        );
    }
    done_testing;
};

# -------------------------------------------------------------------------

subtest "decode" => sub {
    my $D = sub { Data::Recursive::Encode->decode('euc-jp', @_) };

    is_deeply([$D->(eU('あいう'))], [U('あいう')], 'scalar');
    is_deeply([$D->(\(eU('あいう')))], [\(U('あいう'))], 'scalarref');
    is_deeply($D->([eU('あいう')]), [U('あいう')], 'arrayref');
    is_deeply($D->({eU('あいう') => eU('えお')}), {U('あいう'), U 'えお'}, 'hashref');

    {
        my $code = sub { };
        is_deeply(
            $D->(
                [
                    eU('あいう'), $code,
                    bless( [eU('おや')], 'Foo' )
                ]
            ),
            [ U('あいう'), $code, bless( [eU('おや')], 'Foo' ) ],
            'coderef,blessed'
        );
    }
    done_testing;
};

# -------------------------------------------------------------------------

subtest "encode" => sub {
    my $E = sub { Data::Recursive::Encode->encode('euc-jp', @_) };

    is_deeply([$E->(U 'あいう')], [eU('あいう')], 'scalar');
    is_deeply([$E->(\(U 'あいう'))], [\(eU('あいう'))], 'scalarref');
    is_deeply($E->([U 'あいう']), [eU('あいう')], 'arrayref');
    is_deeply($E->({U('あいう') , U('えお')}), {eU('あいう'),  eU('えお')}, 'hashref');

    {
        my $code = sub { };
        is_deeply(
            $E->(
                [
                    U('あいう'), $code,
                    bless( [U('おや')], 'Foo' )
                ]
            ),
            [ eU('あいう'), $code, bless( [U('おや')], 'Foo' ) ],
            'coderef,blessed'
        );
    }
    done_testing;
};

# -------------------------------------------------------------------------

subtest "from_to" => sub {
    my $src = e(U('あいう'));
    my $utf8 = Data::Recursive::Encode->from_to($src, 'euc-jp', 'utf-8');
    ok !utf8::is_utf8($utf8), 'not flagged';
    is $utf8, 'あいう';

    done_testing;
};

done_testing;
