use strict;
use warnings;

use Test::More;
use Test::Exception;

throws_ok {
    package BadTestProvider;
    use Moo;
    with 'Dancer2::Plugin::Auth::Extensible::Role::Provider';
    use namespace::clean;
}
qr/missing.+authenticate_user/,
  "test provider class does not supply any required methods";

lives_ok {
    package TestProvider;
    use Moo;
    with 'Dancer2::Plugin::Auth::Extensible::Role::Provider';
    use namespace::clean;
    sub authenticate_user { }
    sub get_user_details  { }
    sub get_user_roles    { }
}
"test provider class provides all required methods";

my ( $password, $provider );

lives_ok { $provider = TestProvider->new( plugin => undef ) }
"TestProvider->new lives";

ok $provider->match_password( 'password', 'password' ),
  "good plain password";

ok $provider->match_password( 'password',
    '{SSHA}ljxuwXYQH3BDNZjg+VXBrkw6Sh6sta3l' ),
  "good SHA password";

ok !$provider->match_password( 'bad', 'password' ),
  "bad plain password";

ok !$provider->match_password( 'bad',
    '{SSHA}ljxuwXYQH3BDNZjg+VXBrkw6Sh6sta3l' ),
  "bad SHA password";

lives_ok { $password = $provider->encrypt_password() }
"encrypt_password(undef)";

like $password, qr/^{SSHA512}.+$/, "password looks good";

lives_ok { $password = $provider->encrypt_password( 'password' ) }
"encrypt_password('password')";

like $password, qr/^{SSHA512}.+$/, "password looks good";

lives_ok {
    $password = $provider->encrypt_password( 'password', 'SHA-512' )
}
"encrypt_password('password', 'SHA-512')";

like $password, qr/^{SSHA512}.+$/, "password looks good";

done_testing;
