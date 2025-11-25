# Copyright (c) 2023-2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2023-2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Extractor for identifiers from URIs

package Data::URIID::Base;

use v5.10;
use strict;
use warnings;

use Carp;

use Data::Identifier v0.25;

our $VERSION = v0.19;




#@returns Data::URIID
sub extractor {
    my ($self, %opts) = @_;
    return $self->{extractor} if defined $self->{extractor};
    return $opts{default} if exists $opts{default};
    croak 'Invalid access: No extractor (instance of Data::URIID) known';
}


sub ise {
    my ($self, %opts) = @_;
    return $self->_cast_ise($self->{ise}, 'ise', %opts) if defined $self->{ise};
    return $opts{default} if exists $opts{default};
    croak 'No ISE known';
}


sub displayname {
    my ($self, %opts) = @_;

    unless ($opts{no_defaults}) {
        return $opts{_fallback} if defined $opts{_fallback}; # fallback defined by overriding method.

        {
            my $v = $self->ise(default => undef, no_defaults => 1);
            return $v if defined $v;
        }
    }

    return $opts{default} if exists $opts{default};

    croak 'No displayname known';
}


sub as {
    my ($self, $as, %opts) = @_;
    $opts{extractor} //= $self->{extractor};
    return $self->Data::Identifier::as($as, %opts);
}

# ---- Private helpers ----

sub _as_lookup {
    my ($self, $lookup_args, %opts) = @_;
    my Data::URIID $extractor = $self->extractor;
    my $res;
    my $old_online;

    if (exists $opts{online}) {
        $old_online = $extractor->online;
        $extractor->online($opts{online});
    }

    $res = $extractor->lookup(@{$lookup_args});

    if (exists $opts{online}) {
        $extractor->online($old_online);
    }

    return $res;
}

sub _cast_ise {
    my ($self, $src, $src_type, %opts) = @_;
    my $as = $opts{as} // 'raw';

    $as = 'raw' if $as eq 'string'; # compatibility with <= v0.09

    if ($as eq 'raw' || $as eq 'ise' || $as eq $src_type) {
        return $src;
    } elsif ($as eq 'Data::Identifier') {
        return Data::Identifier->new($src_type => $src);
    } elsif ($as eq 'Data::URIID::Result') {
        return $self->_as_lookup([$src_type => $src], %opts);
    } elsif ($as eq 'Data::URIID::Service') {
        return $self->extractor->service($src);
    }

    {
        my $val = Data::Identifier->new($src_type => $src)->as($as, %opts{'no_defaults'}, default => undef);
        return $val if defined $val;
    }

    croak sprintf('Cannot convert identifier to type "%s"', $as);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::URIID::Base - Extractor for identifiers from URIs

=head1 VERSION

version v0.19

=head1 SYNOPSIS

    use Data::URIID;

    use parent 'Data::URIID::Base';

This module is the base package for a number of other packages.
Common methods are defined in here.

B<Note:>
Functionality marked with B<Experimental> may or may not work as expected
(e.g. may contain bugs or may change behaviour in future versions without warning).

=head1 METHODS

=head2 extractor

    my Data::URIID $extractor = $object->extractor( [ %opts ] );

Returns the L<Data::URIID> object used to create this object (if any).
If the extractor is not/no longer available this method C<die>s.

The following options are defined:

=over

=item C<default>

Returns the given value if no value is found.
This can also be set to C<undef> to allow returning C<undef> in case of no value found instead of C<die>-ing.

=back

=head2 ise

    my $ise = $object->ise( [ %opts ] );

Returns the ISE of this object. If no ISE is known
this method will C<die>.

The following options are defined:

=over

=item C<as>

Return the value as the given type.
This is the package name of the type, C<ise> for pain ISE perl string.
If the given type is not supported or cannot be constructed the method C<die>s.

At least the following types are supported:
L<Data::URIID::Result>,
L<Data::URIID::Service>,
L<Data::Identifier>.

=item C<default>

Returns the given value if no value is found.
This can also be set to C<undef> to allow returning C<undef> in case of no value found instead of C<die>-ing.

=item C<no_defaults>

B<Experimental:>
If set to true this will avoid calculating identifiers from others if C<as> does not match what is available.

=item C<online>

Overrides the L<Data::URIID/"online"> flag used for the lookup if C<as> is set to L<Data::URIID::Result>.
This is very useful to prevent network traffic for auxiliary lookups.

=back

=head2 displayname

    my $displayname = $object->displayname( [ %opts ] );

This method is for compatibility with other moduls such as L<Data::Identifier> and L<Data::TagDB::Tag>.
This methods C<die>s if no value can be found.

The following options are supported:

=over

=item C<default>

B<Experimental:>
Returns the given value if no value is found.
This can also be set to C<undef> to allow returning C<undef> in case of no value found instead of C<die>-ing.

=item C<no_defaults>

B<Experimental:>
If set to true this will avoid returning an identifier or any other default value.

=back

=head2 as

    my $xxx = $base->as($as, [ %opts ] );

Proxy for L<Data::Identifier/as>.

Automatically adds C<extractor> to C<%opts> if any is known (see L</extractor>).

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
