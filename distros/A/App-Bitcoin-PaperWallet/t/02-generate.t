use v5.12;
use warnings;

use Test::More;
use App::Bitcoin::PaperWallet;

my $hash = App::Bitcoin::PaperWallet->generate('silly entropy that should never be used in a real wallet', 'sillypass');

# seed should be 76f30b114cb9165116a9b0a9e214e3ea4cfa9923adc8154e5d72b12e54b5a20a
is $hash->{mnemonic}, 'ivory obscure session offer multiply chuckle follow current prepare awful decline stand soul erode modify ribbon best indicate frequent girl torch food market evidence', 'mnemonic ok';

# those addresses take password into account
is $hash->{addresses}[0], '3QUyruDJ9oce8KNJELPWAxfcvcvESuGrds', 'compat address ok';
is $hash->{addresses}[1], 'bc1qngdesm3ljdfyxsskvsxz4034vlyk9cjm7r6k5p', 'native address ok';

# test data generated using https://iancoleman.io/bip39/

done_testing;

