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

my $E = sub { Data::Recursive::Encode->encode_utf8(@_) };

my $data = {
    'foo' => { key => U('あいう'), qux => 42 }
};
$data->{bar} = $data->{foo};

my $got = Data::Recursive::Encode->encode_utf8($data);

is $got->{bar}->{qux}, 42;
is $got->{bar}->{key}, 'あいう';

$got->{foo}{qux}++;
is $got->{bar}{qux}, 43, 'cyclic refs';

ok !utf8::is_utf8($got->{foo}->{key});

done_testing;
