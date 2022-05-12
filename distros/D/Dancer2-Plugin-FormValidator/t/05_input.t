use strict;
use warnings;

use Test::More tests => 1;
use Dancer2::Plugin::FormValidator::Input;

eval {
    Dancer2::Plugin::FormValidator::Input->new(input => []);
};

like(
    $@,
    qr/Not a HASH reference/,
    'Check input',
);
