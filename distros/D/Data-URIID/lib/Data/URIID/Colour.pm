# Copyright (c) 2023-2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2023-2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Extractor for identifiers from URIs

package Data::URIID::Colour;

use strict;
use warnings;

use overload '""' => \&rgb;

use Carp;
use Scalar::Util qw(weaken blessed);

our $VERSION = v0.16;

use parent 'Data::URIID::Base';

my %_registered;



sub new {
    my ($pkg, %opts) = @_;
    my __PACKAGE__ $self;

    if (defined(my $from = delete($opts{from}))) {
        if (blessed $from) {
            if ($from->isa('Data::URIID::Base')) {
                $opts{extractor} //= $from->extractor(default => undef);
            }

            if ($from->isa(__PACKAGE__)) {
                $opts{rgb} //= $from->rgb;
            } else {
                $from = $from->ise;
            }
        }

        $opts{rgb} //= $_registered{$from};
    }

    croak 'No RGB value given' unless defined $opts{rgb};

    $opts{rgb} = uc($opts{rgb});
    $opts{rgb} =~ /^#[0-9A-F]{6}$/ or die 'Bad format';

    weaken($opts{extractor});

    $self = bless \%opts, $pkg;

    if (delete $opts{register}) { # not (yet) part of public API
        $_registered{$self->ise} //= $opts{rgb};
    }

    return $self;
}


sub rgb {
    my ($self) = @_;
    return $self->{rgb} // croak 'No RGB value';
}

# --- Overrides for Data::URIID::Base ---

sub ise {
    my ($self, %opts) = @_;

    unless (defined $self->{ise}) {
        require Data::Identifier::Generate;
        $self->{ise} = Data::Identifier::Generate->colour($self->rgb)->ise;
    }

    return $self->SUPER::ise(%opts);
}

sub displayname {
    my ($self, %opts) = @_;
    return $self->SUPER::displayname(%opts, _fallback => $self->rgb);
}

# ---- Private helpers ----

# Private for now.
sub displaycolour {
    my ($self) = @_;
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::URIID::Colour - Extractor for identifiers from URIs

=head1 VERSION

version v0.16

=head1 SYNOPSIS

    use Data::URIID::Colour;

    my $colour = Data::URIID::Colour->new(rgb => '#FF0000');

This module represents a single colour.

This package inherits from L<Data::URIID::Base>.

=head1 METHODS

=head2 new

    my $colour = Data::URIID::Colour->new( option => value, ... );

Returns a new object for the given colour.
The following options are defined:

=over

=item C<rgb>

The RGB value in hex notation. E.g. C<#FF0000>.

=item C<extractor>

optionally, an instance of L<Data::URIID>.

=item C<from>

optionally, an instance of any colour provider.
The provider might be used to fill defaults for the other options (such as C<rgb> or C<extractor>).

Currently the value must be one of
L<Data::URIID::Colour>,
or L<Data::URIID::Result>.
But other types might also be supported.

If using L<Data::URIID::Result> this might not be what you want. See also L<Data::URIID::Result/displaycolour>.

=back

=head2 rgb

    my $rgb = $colour->rgb;

Returns the colour in six digit hex notation with prepended pound (C<#>) if successful or C<die> otherwise.
The returned value is suitable for use in CSS.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
