use strict;
use warnings;
use lib 'lib';
use utf8;
use feature qw(say);
use Data::Dumper;
use Test::Exception;
use Test::More;

use Data::MoneyCurrency qw(get_currencies_for_country);

binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";
binmode Test::More->builder->output,         ":encoding(UTF-8)";
binmode Test::More->builder->failure_output, ":encoding(UTF-8)";
binmode Test::More->builder->todo_output,    ":encoding(UTF-8)";

is_deeply(get_currencies_for_country('fr'), ['eur'],        'Test France');
is_deeply(get_currencies_for_country('DE'), ['eur'],        'Test Germany');
is_deeply(get_currencies_for_country('us'), ['usd'],        'Test USA');
is_deeply(get_currencies_for_country('va'), ['eur'],        'Test Vatican');
is_deeply(get_currencies_for_country('cu'), ['cuc', 'cup'], 'Test Cuba');
is_deeply(get_currencies_for_country('lt'), ['eur'],        'Test Lithuania');
is_deeply(get_currencies_for_country('xk'), ['eur'],        'Test Kosovo');
is_deeply(get_currencies_for_country('sv'), ['usd', 'btc'], 'Test SV');

throws_ok {
    get_currencies_for_country();
}
qr/no arguments/, "get_currencies_for_country() throws exception";

done_testing();
