use strict;
use warnings;

use Test::More tests => 8;
use Data::Dumper;
BEGIN { use_ok('Cookie::XS'); }

$Data::Dumper::Sortkeys = 1;

{
    my $cookie = 'foo=a%20phrase;haha; bar=yes%2C%20a%20phrase; baz=%5Ewibble&leiyh; qux=%27';
    my $res = Cookie::XS->parse($cookie);
    is Dumper($res), <<'_EOC_';
$VAR1 = {
          'bar' => [
                     'yes, a phrase'
                   ],
          'baz' => [
                     '^wibble',
                     'leiyh'
                   ],
          'foo' => [
                     'a phrase'
                   ],
          'qux' => [
                     '\''
                   ]
        };
_EOC_
}

{
    my $cookie = 'foo=a%3A; ';
    my $res = Cookie::XS->parse($cookie);
    ok $res, 'res is not null';
    ok $res->{foo}, 'var foo defined';
    is $res->{foo}->[0], 'a:';
}

{
    my $cookie = 'foo=a%3A ';
    my $res = Cookie::XS->parse($cookie);
    ok $res, 'res is not null';
    ok $res->{foo}, 'var foo defined';
    is $res->{foo}->[0], 'a: ';
}

