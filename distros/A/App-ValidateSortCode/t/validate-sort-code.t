use 5.006;
use strict;
use warnings FATAL => 'all';
use Capture::Tiny ':all';
use App::ValidateSortCode;
use Test::More;

my $min_tcm = 0.46;
eval "use BankAccount::Validator::UK $min_tcm";
plan skip_all => "BankAccount::Validator::UK $min_tcm required" if $@;

is(capture_stdout { App::ValidateSortCode->new({ country => 'uk', sort_code => '10-79-99', account_number => '88837491' })->run },
   "10-79-99 is a valid sort code.\n");

done_testing();
