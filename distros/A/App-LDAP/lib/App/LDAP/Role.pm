package App::LDAP::Role;

use Modern::Perl;

use Moose::Role;

use App::LDAP::Config;
sub config {
    App::LDAP::Config->instance;
}

use App::LDAP::Secret;
sub secret {
    App::LDAP::Secret->instance->secret;
}

use App::LDAP::Connection;
sub ldap {
    App::LDAP::Connection->instance;
}

sub find_user {
    my ( $attr, $value ) = @_;
    my $search = ldap()->search(
        base   => config()->{nss_base_passwd}->[0],
        scope  => config()->{nss_base_passwd}->[1],
        filter => "$attr=$value",
    );
    if ($search->count > 0) {
        return $search->entry(0);
    } else {
        die "user $attr=$value not found";
    }
}

no Moose::Role;

1;

=pod

=head1 NAME

App::LDAP::Role - base of all roles in App::LDAP

=head1 DESCRIPTION

This role provides common helpers for almost all packages in App::LDAP, including ldap() for getting singleton of
App::LDAP::Connection, config() for getting singleton of App::LDAP::Config and secret() for getting singleton of
App::LDAP::Secret.

=cut

