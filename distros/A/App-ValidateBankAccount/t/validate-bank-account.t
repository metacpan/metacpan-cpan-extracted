use 5.006;
use strict;
use warnings FATAL => 'all';
use Capture::Tiny ':all';
use App::ValidateBankAccount;
use Test::More;

my $min_tcm = 0.46;
eval "use BankAccount::Validator::UK $min_tcm";
plan skip_all => "BankAccount::Validator::UK $min_tcm required" if $@;

my $sort_code      = '10-79-99';
my $account_number = '88837491';
is(capture_stdout { App::ValidateBankAccount->new({ country => 'uk', sort_code => $sort_code, account_number => $account_number })->run },
   "[$sort_code][$account_number] is a valid bank account.\n");

done_testing();
