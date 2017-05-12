use Modern::Perl;
use Test::More;

BEGIN {

    my @modules = qw( App::LDAP::Command
                      App::LDAP::Command::Del
                      App::LDAP::Command::Del::User
                      App::LDAP::Command::Del::Group
                      App::LDAP::Command::Del::Host
                      App::LDAP::Command::Del::Sudoer
                      App::LDAP::Command::Del::Ou );

    for my $module (@modules) {
        use_ok $module;
    }

    for my $module (@modules) {
        ok (
            $module->can("dispatch"),
            "$module can dispatch",
        );
    }
}

done_testing;
