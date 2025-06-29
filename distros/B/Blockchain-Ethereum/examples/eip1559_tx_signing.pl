use strict;
use warnings;

use Blockchain::Ethereum::ABI::Encoder;
use Blockchain::Ethereum::Transaction::EIP1559;
use Blockchain::Ethereum::Keystore::Key;

my $encoder = Blockchain::Ethereum::ABI::Encoder->new;
$encoder->function('transfer')->append('address' => '0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F')->append('uint256' => '1000');
my $encoded = $encoder->encode;

my $transaction = Blockchain::Ethereum::Transaction::EIP1559->new(
    nonce                    => '0x0',
    max_fee_per_gas          => '0x1127A5278',
    max_priority_fee_per_gas => '0x79000000',
    gas_limit                => '0x1DE2B9',
    value                    => '0x0',
    data                     => $encoded,
    chain_id                 => '0x1'
);

my $key = Blockchain::Ethereum::Keystore::Key->new(
    private_key => pack "H*",
    '4646464646464646464646464646464646464646464646464646464646464646'
);

$key->sign_transaction($transaction);

my $raw_transaction = $transaction->serialize;

printf("0x%s", unpack "H*", $raw_transaction);
