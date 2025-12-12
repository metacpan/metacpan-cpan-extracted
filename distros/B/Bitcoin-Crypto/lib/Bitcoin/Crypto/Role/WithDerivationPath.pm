package Bitcoin::Crypto::Role::WithDerivationPath;
$Bitcoin::Crypto::Role::WithDerivationPath::VERSION = '4.003';
use v5.14;
use warnings;

use Mooish::Base -standard, -role;

requires qw(get_derivation_path);

1;

