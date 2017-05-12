package App::LDAP::ObjectClass::Device;

use Modern::Perl;

use Moose;

extends qw(App::LDAP::ObjectClass::Top);

has cn => (
    is  => "rw",
    isa => "ArrayRef[Str]",
);

has [qw(serialNumber seeAlso owner ou o l description)] => (
    is  => "rw",
    isa => "Str",
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=head1 NAME

App::LDAP::ObjectClass::Device - schema of device

=head1 DEFINITION

    objectclass ( 2.5.6.14 NAME 'device'
        DESC 'RFC2256: a device'
        SUP top
        STRUCTURAL
        MUST cn
        MAY ( serialNumber $ seeAlso $ owner $ ou $ o $ l $ description )
    )

=cut

