package App::LDAP::LDIF::User;

use Modern::Perl;

use Moose;

extends qw(
    App::LDAP::ObjectClass::PosixAccount
    App::LDAP::ObjectClass::ShadowAccount
    App::LDAP::ObjectClass::InetOrgPerson
    App::LDAP::LDIF
);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    push @_, (dn => "uid=".{@_}->{uid}.",".{@_}->{base}) if grep /^base$/, @_;
    $self->$orig(@_);
};

has '+cn' => (
    lazy    => 1,
    default => sub {
        [shift->uid]
    },
);

has '+objectClass' => (
    default => sub {
        [
            qw( inetOrgPerson
                posixAccount
                top
                shadowAccount )
        ],
    },
);

has '+userPassword' => (
    required => 1,
);

has '+loginShell' => (
    default => "/bin/bash",
);

has '+homeDirectory' => (
    lazy    => 1,
    default => sub {
        "/home/" . shift->uid;
    },
);

has '+shadowLastChange' => (
    default => sub {
        use Date::Calc qw(Today Delta_Days);
        Delta_Days(
            1970, 1, 1,
            Today()
        );
    },
);

has '+shadowMin' => (
    default => 0,
);

has '+shadowMax' => (
    default => 99999,
);

has '+shadowWarning' => (
    default => 7,
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=pod

=head1 NAME

App::LDAP::LDIF::User - the representation of users in LDAP

=head1 SYNOPSIS

    my $user = App::LDAP::LDIF::User->new(
        base         => $base,       # the OU (organization unit) which the user belongs to
        uid          => $name,       # user name
        userPassword => $password,   # the password used by the user
        uidNumber    => $uid,        # the uid of the user
        gidNumber    => $gid,        # the gid of the user
        sn           => [$sn],       # the surname of this user
    );
    # these 6 parameters are required
    # extra parameters of attributes such as title of User can be provided in constructor, too.

    $user->loginShell("/bin/zsh")
    # set zsh as the user's shell

    $uesr->gidNumber("27")
    # set the user to have 27 as group id

    my $entry = $user->entry
    # get the user as a instance of Net::LDAP::Entry

    my $from_entry = App::LDAP::LDIF::User->new($entry)
    # new from a Net::LDAP::Entry instance

=head1 DESCRIPTION

App::LDAP::LDIF::User is composed of objectClass top, posixAccount, shadowAccount and inetOrgPerson.

The objectClass top is described in RFC2256 (core.schema of OpenLDAP) indicating this kind of entry MUST have objectClass.

The early versions used objectClass account rather than inetOrgPerson. Both account and inetOrgPerson are STRUCTURAL so
that only one of them could be satisfied.

The objectClass posixAccount and shadowAccount are described in RFC2307 (nis.schema of OpenLDAP).

The objectClass inetOrgPerson is described in RFC2798 (inetorgperson.schema of OpenLDAP). The inetOrgPerson is derived
from organizationalPerson which is derived from person.

=head1 NOTES

=head2 userPassword

The objectClass posixAccount and shadowAccount define userPassword MAY be an attribute of a uesr. Because App::LDAP is
designed for working with pam_ldap, userPassword is defined as a required attribute here.

=head2 sn

The objectClass inetOrgPerson is derived from organizationalPerson which is derived from person. The person defines sn
MUST be a attribute of a user. Since the inetOrgPerson has sn as a required attribute.

=head2 cn

required attributes. default [ $self->uid ]

=head2 loginShell

default /bin/bash

=head2 shadowLastChange

the days from Unix Epoch that last time you changed password.

default value is calculated via Date::Calc::Delta_Days().

=head2 shadowMin

the minimum days that user can change their password.

default 0

=head2 shadowMax

the maximun days that user have to change their password.

default 99999

=head2 shadowWarning

the day that user would be warned before password to be expired

default 7

=head2 homeDirectory

default "/home/" . $self->uid

=cut
