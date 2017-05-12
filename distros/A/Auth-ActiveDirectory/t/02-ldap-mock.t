use strict;
use warnings;
use Test::More tests => 13;
use Test::Net::LDAP;
use Test::Net::LDAP::Mock;
use Test::Net::LDAP::Util qw(ldap_mockify);
use Auth::ActiveDirectory;

Test::Net::LDAP::Mock->mock_target('ldap://127.0.0.1:389');
Test::Net::LDAP::Mock->mock_target(
    'localhost',
    port   => 389,
    schema => 'ldap'
);

my $ldap = Test::Net::LDAP::Mock->new( '127.0.0.1', 389 );

$ldap->add(
    'CN=Mario Zieschang,OU=mziescha,OU=users,OU=developers,DC=example,DC=org',
    attrs => [
        objectClass       => [ "top", "person", "organizationalPerson", "user" ],
        cn                => "Mario Zieschang",
        sn                => "Zieschang",
        description       => "Operations",
        givenName         => "Mario",
        distinguishedName => "CN=Mario Zieschang,OU=users,OU=developers,DC=example,DC=org",
        displayName       => "Mario Zieschang",
        memberOf          => [
            "CN=dockers,OU=Gruppen,DC=example,DC=org",    "CN=admin,OU=Gruppen,DC=example,DC=org",
            "CN=Operations,OU=Gruppen,DC=example,DC=org", "CN=developers,OU=Gruppen,DC=example,DC=org"
        ],
        name              => "Mario Zieschang",
        homeDrive         => "G:",
        sAMAccountName    => "mziescha",
        userPrincipalName => 'mziescha@example.org',
        objectCategory    => "CN=Person,CN=Schema,CN=Configuration,DC=example,DC=org",
        mail              => 'mziescha@cpan.org',
        pwdLastSet        => 131273426600000000,
        accountExpires    => 9223372036854775807,
    ]
);

$ldap->add(
    'CN=Dominic Sonntag,OU=dsonnta,OU=users,OU=developers,DC=example,DC=org',
    attrs => [
        objectClass       => [ "top", "person", "organizationalPerson", "user" ],
        cn                => "Dominic Sonntag",
        sn                => "Sonntag",
        description       => "Operations",
        givenName         => "Dominic",
        distinguishedName => "CN=Dominic Sonntag,OU=users,OU=developers,DC=example,DC=org",
        displayName       => "Dominic Sonntag",
        memberOf          => [
            "CN=dockers,OU=Gruppen,DC=example,DC=org",    "CN=admin,OU=Gruppen,DC=example,DC=org",
            "CN=Operations,OU=Gruppen,DC=example,DC=org", "CN=developers,OU=Gruppen,DC=example,DC=org"
        ],
        name              => "Dominic Sonntag",
        homeDrive         => "G:",
        sAMAccountName    => "dsonnta",
        userPrincipalName => 'dsonnta@example.org',
        objectCategory    => "CN=Person,CN=Schema,CN=Configuration,DC=example,DC=org",
        mail              => 'dsonnta@cpan.org',
        pwdLastSet        => 130273426600000000,
        accountExpires    => 9223372036854775807,
    ]
);

my $obj = Auth::ActiveDirectory->new( ldap => $ldap, domain => 'example', principal => 'org', );
my $user = $obj->authenticate( 'mziescha', 'password1' );

is( $user->firstname,    'Mario' );
is( $user->surname,      'Zieschang' );
is( $user->display_name, 'Mario Zieschang' );
is( $user->uid,          'mziescha' );
is( $user->mail,         'mziescha@cpan.org' );
is( $user->last_password_set, 1482869060 );
is( $user->account_expires,   undef );

is( scalar @{ $user->groups }, 4 );
ok( defined $_->name, 'Group name should be defined' ) foreach @{ $user->groups };

my $users = $obj->list_users( 'mziescha', 'password1', '' );
is( scalar @$users, 2 );
