package App::LDAP::ObjectClass::IpHost;

use Modern::Perl;

use Moose;

extends qw(App::LDAP::ObjectClass::Top);

has cn => (
    is       => "rw",
    isa      => "ArrayRef[Str]",
    required => 1,
);

has ipHostNumber => (
    is       => "rw",
    isa      => "Str",
    required => 1,
);

has [qw( l description manager )] => (
    is  => "rw",
    isa => "Str",
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=head1 NAME

App::LDAP::ObjectClass::IpHost - schema of ipHost

=head1 DEFINITION

    objectclass (
        1.3.6.1.1.1.2.6
        NAME 'ipHost'
        DESC 'Abstraction of a host, an IP device'
        SUP top
        AUXILIARY
        MUST ( cn $ ipHostNumber )
        MAY ( l $ description $ manager )
    )

=cut

