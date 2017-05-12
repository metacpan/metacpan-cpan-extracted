use lib qw(lib);

use Modern::Perl;
use Test::More;

use App::LDAP::Config;

{
    package App::LDAP::Config;
    our @locations = qw(
        ./t/data/ldap.conf
    );
}

my $config = App::LDAP::Config->read;

is (
    $config->{base},
    "dc=example,dc=com",
    "can get correct base",
);

is (
    $config->{uri},
    "ldap://localhost",
    "can get correct uri",
);

is (
    $config->{port},
    389,
    "can get correct port",
);

is_deeply (
    $config->{nss_base_passwd},
    ["ou=People,dc=example,dc=com", "one"],
    "can get correct nss base of passwd",
);

is_deeply (
    $config->{nss_base_shadow},
    ["ou=People,dc=example,dc=com", "one"],
    "can get correct nss base of shadow",
);

is_deeply (
    $config->{nss_base_group},
    ["ou=Group,dc=example,dc=com", "one"],
    "can get correct nss base of group",
);

is_deeply (
    $config->{nss_base_hosts},
    ["ou=Hosts,dc=example,dc=com", "one"],
    "can get correct nss base of hosts",
);

is_deeply (
    $config->{sudoers_base},
    ["ou=SUDOers,dc=example,dc=com"],
    "can get correct nss base of sudoers",
);


done_testing;
