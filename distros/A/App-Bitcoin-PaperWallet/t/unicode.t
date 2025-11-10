use Test2::V0;
use App::Bitcoin::PaperWallet;

my $hash = App::Bitcoin::PaperWallet->generate('another silly entropy that should never be used in a real wallet with ąść', 'ąśćź 1');

# seed should be 6f1a6e66b9c2a706a5f4c16bb0ea34a54577bda27d7a0900be9e8afc952e731e
is $hash->{mnemonic}, 'humor square often inform clerk local oak oblige hill mansion minor enhance first tell measure quantum animal album police bicycle sing now small that', 'mnemonic ok';

# those addresses take password into account
is $hash->{addresses}[0], '3NjcWMUFzw1oEobkFx9ggo2i6QuKaRbTfG', 'compat address ok';
is $hash->{addresses}[1], 'bc1pn9qatrfphg8w68spchwlhm8sl3wfgt9j3tzn4rltu2umhnna9g6qshecay', 'taproot address 1 ok';
is $hash->{addresses}[2], 'bc1pdw9xq22udfmfkgtltl5fpg9ey228vanvv68mwvtzjhze4m3nv9psu404mx', 'taproot address 1 ok';
is $hash->{addresses}[3], 'bc1p0njp6cju5zncf5etc0azd6kgk2les83ush7a8y7hc3t2j77ylajq87528l', 'taproot address 2 ok';

is scalar @{$hash->{addresses}}, 4, 'address count ok';

# test data generated using https://gugger.guru/cryptography-toolkit/#!/hd-wallet

done_testing;

