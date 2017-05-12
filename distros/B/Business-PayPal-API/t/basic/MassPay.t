use Test::More;
if ( !$ENV{WPP_TEST} || !-f $ENV{WPP_TEST} ) {
    plan skip_all =>
        'No WPP_TEST env var set. Please see README to run tests';
}
else {
    plan tests => 3;
}

use_ok('Business::PayPal::API::MassPay');
#########################

require 't/API.pl';

my %args = do_args();

my $pp = new Business::PayPal::API::MassPay(%args);

#$Business::PayPal::API::Debug = 1;
my %resp = $pp->MassPay(
    EmailSubject => "This is the subject; nice eh?",
    MassPayItems => [
        {
            ReceiverEmail => 'joe@test.tld',
            Amount        => '24.00',
            UniqueID      => "123456",
            Note => "Enjoy the money. Don't spend it all in one place."
        }
    ]
);

like( $resp{Ack}, qr/Success/, "successful payment" );

%resp = $pp->MassPay(
    EmailSubject => "This is the subject; nice eh?",
    MassPayItems => [
        {
            ReceiverEmail => 'bob@test.tld',
            Amount        => '25.00',
            UniqueID      => "123457",
            Note => "Enjoy the money. Don't spend it all in one place."
        },
        {
            ReceiverEmail => 'foo@test.tld',
            Amount        => '42.00',
            UniqueID      => "123458",
            Note => "Enjoy the money. Don't spend it all in one place."
        }
    ]
);

like( $resp{Ack}, qr/Success/, "successful payments" );
