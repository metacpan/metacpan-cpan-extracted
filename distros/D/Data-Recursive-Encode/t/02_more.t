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

    is_deeply([$D->('あいう'), undef],    [U('あいう'), undef], 'undef');
    is_deeply([$D->('あいう'), \*ok ],    [U('あいう'), \*ok],  'globref');
    is_deeply([$D->('あいう'), \&ok ],    [U('あいう'), \&ok],  'coderef');
    is_deeply([\\$D->('あいう') ],        [\\U('あいう')],      'ref to ref');

    done_testing;
};

# -------------------------------------------------------------------------

subtest "encode_utf8" => sub {
    my $E = sub { Data::Recursive::Encode->encode_utf8(@_) };

    is_deeply([$E->(U 'あいう'), undef],    [('あいう'), undef], 'undef');
    is_deeply([$E->(U 'あいう'), \*ok ],    [('あいう'), \*ok],  'globref');
    is_deeply([$E->(U 'あいう'), \&ok ],    [('あいう'), \&ok],  'coderef');
    is_deeply([\\$E->(U 'あいう') ],        [\\('あいう')],      'ref to ref');

    done_testing;
};

# -------------------------------------------------------------------------

subtest "decode" => sub {
    my $D = sub { Data::Recursive::Encode->decode('euc-jp', @_) };

    is_deeply([$D->(eU('あいう')), undef],    [U('あいう'), undef], 'undef');
    is_deeply([$D->(eU('あいう')), \*ok ],    [U('あいう'), \*ok],  'globref');
    is_deeply([$D->(eU('あいう')), \&ok ],    [U('あいう'), \&ok],  'coderef');
    is_deeply([\\$D->(eU('あいう')) ],        [\\U('あいう')],      'ref to ref');

    done_testing;
};

# -------------------------------------------------------------------------

subtest "encode" => sub {
    my $E = sub { Data::Recursive::Encode->encode('euc-jp', @_) };

    is_deeply([$E->(U 'あいう'), undef],    [eU('あいう'), undef], 'undef');
    is_deeply([$E->(U 'あいう'), \*ok ],    [eU('あいう'), \*ok],  'globref');
    is_deeply([$E->(U 'あいう'), \&ok ],    [eU('あいう'), \&ok],  'coderef');
    is_deeply([\\$E->(U 'あいう') ],        [\\eU('あいう')],      'ref to ref');

    done_testing;
};

done_testing;
