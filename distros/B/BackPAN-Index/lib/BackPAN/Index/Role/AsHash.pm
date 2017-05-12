package BackPAN::Index::Role::AsHash;

use Mouse::Role;

requires qw(data_methods);

sub as_hash {
    my $self = shift;

    my %data;
    for my $method ($self->data_methods) {
        $data{$method} = $self->$method;
    }

    return \%data;
}


=head1 NAME

BackPAN::Index::Role::AsHash - Role to dump object data as a hash

=head1 SYNOPSIS

    use BackPAN::Index::Role::AsHash;

    sub data_methods { return qw(list of data methods) }

=head1 DESCRIPTION

A role to implement C<<as_hash>> in result objects.

=head2 Requires

The receiving class must implement...

=head3 data_methods

    my @methods = $self->data_methods;

Returns a list of methods which get data about the object.

=head2 Implements

=head3 as_hash

    my $hash = $self->as_hash;

Produces a hash reference representing the object's data based on
C<<$self->data_methods>>.  Each key is a method name, the value is
C<<$self->$method>>.

=cut

1;
