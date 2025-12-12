package Bitcoin::Crypto::Transaction::Signer::P2SH;
$Bitcoin::Crypto::Transaction::Signer::P2SH::VERSION = '4.003';
use v5.14;
use warnings;

use Mooish::Base -standard;

use Bitcoin::Crypto::Exception;
use Bitcoin::Crypto::Constants;
use Bitcoin::Crypto::Types -types;

extends 'Bitcoin::Crypto::Transaction::Signer::Legacy';
with 'Bitcoin::Crypto::Transaction::Signer::Role::ScriptHash';

1;

