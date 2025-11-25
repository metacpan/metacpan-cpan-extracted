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

our $VERSION = v0.19;

use parent qw(Data::URIID::Base Data::Identifier::Interface::Known);

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
            } elsif ($from->isa('Data::Identifier')) {
                if (!defined($opts{rgb}) && eval {$from->generator->eq('55febcc4-6655-4397-ae3d-2353b5856b34')}) {
                    if (defined(my $v = $from->request)) {
                        if ($v =~ /^#[0-9a-fA-F]{6}$/) {
                            $opts{rgb} //= $v;
                        }
                    }
                }
                $from = $from->ise;
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
        Data::Identifier::Generate->colour($opts{rgb})->register;
    }

    return $self;
}


sub rgb {
    my ($self) = @_;
    return $self->{rgb} // croak 'No RGB value';
}


sub known {
    my ($pkg, $class, %opts) = @_;
    $opts{extractor} //= $pkg->extractor(default => undef) if ref $pkg;
    return $pkg->SUPER::known($class, %opts);
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

# --- Overrides for Data::URIID::Base ---
sub _known_provider {
    my ($pkg, $class, %opts) = @_;
    croak 'Unsupported options passed' if scalar(keys %opts);
    return ([keys %_registered], rawtype => 'ise') if $class eq ':all';
    croak 'Unsupported class';
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

version v0.19

=head1 SYNOPSIS

    use Data::URIID::Colour;

    my $colour = Data::URIID::Colour->new(rgb => '#FF0000');

This module represents a single colour.

This package inherits from L<Data::URIID::Base>, and L<Data::Identifier::Interface::Known> (experimental).

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
L<Data::URIID::Result>, or
L<Data::Identifier> (only supported for some objects, including those generated with L<Data::Identifier::Generate/colour>).
But other types might also be supported.

If using L<Data::URIID::Result> this might not be what you want. See also L<Data::URIID::Result/displaycolour>.

=back

=head2 rgb

    my $rgb = $colour->rgb;

Returns the colour in six digit hex notation with prepended pound (C<#>) if successful or C<die> otherwise.
The returned value is suitable for use in CSS.

=head2 known

    my @list = Data::URIID::Colour->known($class [, %opts ]);
    # or:
    my @list = $colour->known($class [, %opts ]);

(B<experimental>, since v0.17)

Returns the list of known objects for the given C<$class>.
Currently no specific classes are supported, so the only valid value is C<:all>.
See L<Data::Identifier::Interface::Known/known> for details.

If called on a instance of this package C<extractor> is filled in automatically if one is known by this instance.

B<Note:>
This is an experimental feature! It may be removed or altered at any future version!

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
