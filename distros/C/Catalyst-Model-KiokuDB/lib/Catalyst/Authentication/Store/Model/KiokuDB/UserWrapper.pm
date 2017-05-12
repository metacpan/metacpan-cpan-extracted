package Catalyst::Authentication::Store::Model::KiokuDB::UserWrapper;
use Moose;

use namespace::clean -except => 'meta';

# FIXME massively cargo culted

has directory => (
    isa => "KiokuDB",
    is  => "ro",
    required => 1,
);

has 'user_object' => (
    does     => 'KiokuX::User',
    reader   => 'get_object',
    required => 1,
    handles  => [qw(id check_password)],
);

sub roles { @{ shift->get_object->roles } };

has [qw(auth_realm store)] => (
    is => 'rw',
);

my %supports = (
    password => 'self_check',
    roles   => ["roles"],
    session => 1,
);

sub supports {
    my ($self, @spec) = @_;

    my $cursor = \%supports;

    return 1 if @spec == 1 and $self->can($spec[0]);

    # XXX is this correct?
    for (@spec) {
        return if ref($cursor) ne "HASH";
        $cursor = $cursor->{$_};
    }

    if (ref $cursor) {
        die "Bad feature spec: '@spec'" unless ref $cursor eq "ARRAY";
        foreach my $key (@$cursor) {
            return undef unless $self->can($key);
        }
        return 1;
    }
    else {
        return $cursor;
    }
}

sub for_session {
    my $self = shift;

    # FIXME if session isa KiokuDB, no need to do anything
    return $self->directory->object_to_id($self->get_object);
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=head1 NAME

Catalyst::Authentication::Store::Model::KiokuDB::UserWrapper - L<KiokuX::User>
wrapper for L<Catalyst::Plugin::Authentication>.

=head1 METHODS

=over 4

=item for_session

=item get_object

Returns the model level object.

=back

=cut
