package t::lib::TestApp;

no warnings 'uninitialized';

use Dancer2;
use Dancer2::Plugin::Auth::ActiveDirectory;
use Test::Net::LDAP;
use Test::Net::LDAP::Mock;
use Test::Net::LDAP::Util qw(ldap_mockify);

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

set plugins => {
    'Auth::ActiveDirectory' => {
        host      => '127.0.0.1',
        principal => 'org',
        domain    => 'example',
        rights    => {
            check => 'ad_check',
            test  => 'dockers',
            git   => [ 'ad_check', 'ad_test' ],
        },
        ldap => $ldap,
    },
};

set logger => 'capture';
set log    => 'debug';

set show_errors => 1;

post '/login/:user/:pass' => sub {
    authenticate( route_parameters->get('user'), route_parameters->get('pass') );
    return 1;
};

post '/list_user/:user/:pass' => sub {
    return scalar @{ list_users( route_parameters->get('user'), route_parameters->get('pass'), '' ) };
};

post '/list_user/:user/:pass/:search' => sub {
    return scalar @{ list_users( route_parameters->get('user'), route_parameters->get('pass'), route_parameters->get('search') ) };
};

get '/rights/:right' => sub {
    to_json rights->{ route_parameters->get('right') };
};

get '/rights_by_user/:user/:pass' => sub {
    to_json rights_by_user( authenticate( route_parameters->get('user'), route_parameters->get('pass') ) );
};

get '/authenticate_config/:key' => sub {
    to_json { route_parameters->get('key') => authenticate_config->{ route_parameters->get('key') } };
};

get '/has_right/:user/:pass/:key' => sub {
    has_right( authenticate( route_parameters->get('user'), route_parameters->get('pass') ), route_parameters->get('key') );
};

1;
