package Test::App;

use Dancer2;
use Dancer2::Plugin::CryptPassphrase;

set plugins => {
    CryptPassphrase => {
        encoder    => 'Argon2',
        validators => ['+Test::Encoder'],
    }
};

true;
