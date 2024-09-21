package Bitcoin::Crypto::Role::WithDerivationPath;
$Bitcoin::Crypto::Role::WithDerivationPath::VERSION = '3.000';
use v5.10;
use strict;
use warnings;

use Moo::Role;

requires qw(get_derivation_path);

1;

