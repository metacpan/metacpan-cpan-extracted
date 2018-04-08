use strict;
use warnings;
use Test::More;
use App::diceware;

{
    my $diceware = App::diceware->new();
    isa_ok $diceware, 'App::diceware';
    can_ok $diceware, qw(_dice _init _load_wordlist passphrase);
    is $diceware->{language}, 'en', 'default language';
    is $diceware->{wordlist}->{11111}, 'abacus', 'got wordlist';
    like $diceware->passphrase(), qr/\w+/, 'got passphrase';
    like $diceware->passphrase({pretty => 1}), qr/(\w+-)+/,
        'got pretty passphrase';
    like $diceware->passphrase({pretty => 1, length => 2}), qr/\w+-\w+/,
        'set passphrase length';
}

{
    my $diceware = App::diceware->new({language => 'de'});
    is $diceware->{wordlist}->{12155}, 'aachen', 'got German wordlist';
}

done_testing;
