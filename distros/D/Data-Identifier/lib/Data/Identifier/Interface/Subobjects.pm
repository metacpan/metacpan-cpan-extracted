# Copyright (c) 2023-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: format independent identifier object


package Data::Identifier::Interface::Subobjects;

use v5.20;
use strict;
use warnings;

use parent 'Data::Identifier::Interface::Userdata';

use Carp;
use Scalar::Util qw(weaken);

our $VERSION = v0.17;

my %_types = (
    db          => 'Data::TagDB',
    extractor   => 'Data::URIID',
    fii         => 'File::Information',
    store       => 'File::FStore',
    parent      => __PACKAGE__,
);


sub so_attach {
    my ($self, %opts) = @_;
    my $storage = $self->_subobject_provider;
    my $weak = delete $opts{weak};

    delete $opts{allow_registered}; # for future use, not yet documented.

    foreach my $key (keys %_types) {
        my $v = delete $opts{$key};
        next unless defined $v;
        croak 'Invalid type for key: '.$key unless eval {$v->isa($_types{$key})};
        $storage->{$key} //= $v;
        croak 'Missmatch for key: '.$key unless $storage->{$key} == $v;
        weaken($storage->{$key}) if $weak;
    }

    croak 'Stray options passed' if scalar keys %opts;

    return $self;
}


sub so_get {
    my ($self, $name, %opts) = @_;
    my $storage = $self->_subobject_provider;

    return $storage->{$name} if defined $storage->{$name};

    foreach my $value (values %{$storage}) {
        next unless defined $value;
        return $value if $value->isa($name);
    }

    if (defined(my $parent = $storage->{parent})) {
        local $storage->{parent} = undef;
        my $v = $parent->so_get($name, default => undef);
        return $v if defined $v;
    }

    return $opts{default} if exists $opts{default};
    croak 'No such subobject attached';
}


sub _subobject_provider {
    my ($self) = @_;
    return $self->{subobjects} //= {};
}



sub KEYS {
    return keys %_types;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Identifier::Interface::Subobjects - format independent identifier object

=head1 VERSION

version v0.17

=head1 SYNOPSIS

    use parent 'Data::Identifier::Interface::Subobjects';

(since v0.16, experimental)

Interface for modules implementing C<so_*()>.

B<Note:>
This interface reserves all method (and constant) names C<so_*> and C<SO_*>.

B<Note:>
This interface is experimental. Details may change or it may be removed completely.

This package inherits from L<Data::Identifier::Interface::Userdata>.

=head1 METHODS

=head2 so_attach

    $obj->so_attach(key => $obj, ...);
    # or:
    $obj->so_attach(key => $obj, ..., weak => 1);

Attaches objects of the given type.

If an object is allready attached for the given key this method C<die>s unless the object is actually the same.

If C<weak> is set to a true value the object reference becomes weak.

Returns itself.

=head2 so_get

    my $so = $obj->so_get($name [, %opts ]);

Get a subobject by the given C<$name>.

If no such subobject is known, this method C<die>s.

The following, all optional, options are supported:

=over

=item C<default>

The default value to return if no other value is available.
This can be set to C<undef> to change the method from C<die>ing in failture to returning C<undef>.

=item C<no_defaults>

This option has currently no effect and is ignored.

=back

=head2 _subobject_provider

    my $userdata = $obj->_subobject_provider;

This method is used by the default implementation of L</so_attach> and L</so_get>.
It provides the backend storage for subobjects.

For every passed object it returns an instance of a hashref (initially empty) that is kept inside the object.

The default implementation expects the object to be a (blessed) hashref. It uses the key C<subobjects> to store the hashref.
It is equivalent to:

    return $obj->{subobjects} //= {};

If all other methods are overridden this method can stay unimplemented.

=head1 CONSTANTS

=head2 KEYS

    my @list = Data::Identifier::Interface::Subobjects->KEYS;

Returns the keys supported for subobjects.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
