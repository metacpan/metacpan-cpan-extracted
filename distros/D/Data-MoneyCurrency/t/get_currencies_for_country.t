#!perl -T
use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use Data::MoneyCurrency qw(get_currencies_for_country);

binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";
binmode Test::More->builder->output, ":encoding(UTF-8)";
binmode Test::More->builder->failure_output, ":encoding(UTF-8)"; 
binmode Test::More->builder->todo_output, ":encoding(UTF-8)";

is_deeply(get_currencies_for_country('fr'), ['eur'], 'Test France');
is_deeply(get_currencies_for_country('us'), ['usd'], 'Test USA');
is_deeply(get_currencies_for_country('cu'), ['cuc', 'cup'], 'Test Cuba');
is_deeply(get_currencies_for_country('lt'), ['eur'], 'Test Lithuania');

done_testing();
