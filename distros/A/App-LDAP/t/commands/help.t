use Modern::Perl;
use Test::More;

BEGIN {
    my @modules = qw( App::LDAP::Command::Help );

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
