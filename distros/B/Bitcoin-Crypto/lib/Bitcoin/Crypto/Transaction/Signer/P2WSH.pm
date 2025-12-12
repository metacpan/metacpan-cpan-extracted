package Bitcoin::Crypto::Transaction::Signer::P2WSH;
$Bitcoin::Crypto::Transaction::Signer::P2WSH::VERSION = '4.003';
use v5.14;
use warnings;

use Mooish::Base -standard;

use Bitcoin::Crypto qw(btc_script);
use Bitcoin::Crypto::Exception;
use Bitcoin::Crypto::Constants;
use Bitcoin::Crypto::Types -types;

extends 'Bitcoin::Crypto::Transaction::Signer::Segwit';
with 'Bitcoin::Crypto::Transaction::Signer::Role::ScriptHash';

1;

