use Modern::Perl;
use Test::More;

BEGIN {
    my @modules = qw( App::LDAP::Command
                      App::LDAP::Command::Migrate
                      App::LDAP::Command::Migrate::User
                      App::LDAP::Command::Migrate::Group
                      App::LDAP::Command::Migrate::Host
                      App::LDAP::Command::Migrate::Sudoer );

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
