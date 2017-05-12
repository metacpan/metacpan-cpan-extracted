package App::LDAP::LDIF::Sudoer;

use Modern::Perl;

use Moose;

extends qw(
    App::LDAP::ObjectClass::SudoRole
    App::LDAP::LDIF
);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    push @_, ( dn => "cn=" . {@_}->{sudoUser} . "," . {@_}->{base} ) if grep /^base$/, @_;
    $self->$orig(@_);
};

has '+objectClass' => (
    default => sub {
        [
            qw( top
                sudoRole )
        ]
    },
);

has '+cn' => (
    lazy    => 1,
    default => sub {
        [shift->sudoUser]
    },
);

has '+sudoUser' => (
    isa      => "Str",
    required => 1,
);

has ['+sudoHost', '+sudoRunAsUser', '+sudoCommand'] => (
    default => sub { ["ALL"] },
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=head1 NAME

App::LDAP::LDIF::Sudoer - the representation of sudoers in LDAP

=head1 SYNOPSIS

    my $sudoer = App::LDAP::LDIF::Sudoer->new(
        base     => "ou=Sudoer,dc=example,dc=com",
        sudoUser => "administrator",
    );

    my $entry = $sudoer->entry;
    # to be Net::LDAP::Entry;

    my $sudoer = App::LDAP::LDIF::Sudoer->new($entry);
    # new from a Net::LDAP::Entry;

=cut

