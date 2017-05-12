package App::LDAP::LDIF::OrgUnit;

use Modern::Perl;

use Moose;

extends qw(
    App::LDAP::ObjectClass::OrganizationalUnit
    App::LDAP::LDIF
);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    push @_, ( dn => "ou=" .{@_}->{ou} ."," . {@_}->{base} ) if grep /^base$/, @_;
    $self->$orig(@_);
};

has '+objectClass' => (
    default => sub {
        [
            qw( organizationalUnit )
        ]
    },
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=head1 NAME

App::LDAP::LDIF::OrgUnit - the representation of organization unit in LDAP

=head1 SYNOPSIS

    my $ou = App::LDAP::LDIF::OrgUnit->new(
        base => $base,
        ou   => $name,
    );

=cut
