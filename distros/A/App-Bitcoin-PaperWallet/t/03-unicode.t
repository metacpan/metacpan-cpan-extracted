use v5.12;
use warnings;

use Test::More;
use App::Bitcoin::PaperWallet;

use utf8;

my $hash = App::Bitcoin::PaperWallet->generate('another silly entropy that should never be used in a real wallet with ąść', 'ąśćź 1');

# seed should be 6f1a6e66b9c2a706a5f4c16bb0ea34a54577bda27d7a0900be9e8afc952e731e
is $hash->{mnemonic}, 'humor square often inform clerk local oak oblige hill mansion minor enhance first tell measure quantum animal album police bicycle sing now small that', 'mnemonic ok';

# those addresses take password into account
is $hash->{addresses}[0], '3NjcWMUFzw1oEobkFx9ggo2i6QuKaRbTfG', 'compat address ok';
is $hash->{addresses}[1], 'bc1qfm507lwuadw08c98eae862hv2jaesm2gwp8w02', 'native address 1 ok';
is $hash->{addresses}[2], 'bc1ql8kh0gh2gcrhjqu7dnnehlxvphsf5pajucspgr', 'native address 1 ok';
is $hash->{addresses}[3], 'bc1qplyhz7fzx0jledt7533afc6z4d2zk7zg4sjdhq', 'native address 2 ok';

is scalar @{$hash->{addresses}}, 4, 'address count ok';

# test data generated using https://iancoleman.io/bip39/

done_testing;

