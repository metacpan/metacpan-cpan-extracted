package App::LDAP::ObjectClass::Top;

use Modern::Perl;

use Moose;

has objectClass => (
    is       => "rw",
    isa      => "ArrayRef[Str]",
    required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=head1 NAME

App::LDAP::ObjectClass::Top - schema of top

=head1 DEFINITION

    objectclass (
        2.5.6.0
        NAME 'top'
        DESC 'RFC2256: top of the superclass chain'
	    ABSTRACT
	    MUST objectClass
    )

=cut

