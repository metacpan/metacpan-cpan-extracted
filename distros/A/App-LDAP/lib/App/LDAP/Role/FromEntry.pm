package App::LDAP::Role::FromEntry;

use Modern::Perl;

use Moose::Role;

with qw( App::LDAP::Role );

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    @_ = $self->entry_to_args(@_) if ref($_[0]) eq 'Net::LDAP::Entry';
    $self->$orig(@_);
};

sub entry_to_args {
    my ($self, $entry) = @_;

    my %attrs = map {
        my $asref = $self->meta->find_attribute_by_name($_)->type_constraint->name ~~ /Ref/;
        $_, $entry->get_value($_, asref => $asref);
    } $entry->attributes;

    return (dn => $entry->dn, %attrs);
}

no Moose::Role;

1;
