# Copyright (c) 2023-2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2023-2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Extractor for identifiers from URIs

package Data::URIID::Colour;

use strict;
use warnings;

use overload '""' => \&rgb;

use Carp;
use UUID::Tiny ':std';

our $VERSION = v0.08;



sub new {
    my ($pkg, %opts) = @_;

    die 'No RGB value given' unless defined $opts{rgb};

    $opts{rgb} = uc($opts{rgb});
    $opts{rgb} =~ /^#[0-9A-F]{6}$/ or die 'Bad format';

    return bless \%opts, $pkg;
}


sub rgb {
    my ($self) = @_;
    return $self->{rgb} // croak 'No RGB value';
}


sub ise {
    my ($self) = @_;

    if (defined $self->{ise}) {
        return $self->{ise};
    } else {
        my $req = lc($self->rgb);

        $req = sprintf('#%s%s%s', $1 x 6, $2 x 6, $3 x 6) if $req =~ /^#([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})$/;

        if ($req =~ /^#[a-f0-9]{36}$/) {
            return $self->{ise} = create_uuid_as_string(UUID_SHA1, '88d3944f-a13b-4e35-89eb-e3c1fbe53e76', $req);
        } else {
            croak 'Bad format for colour';
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::URIID::Colour - Extractor for identifiers from URIs

=head1 VERSION

version v0.08

=head1 SYNOPSIS

    use Data::URIID::Colour;

    my $colour = Data::URIID::Colour->new(rgb => '#FF0000');

=head1 METHODS

=head2 new

    my $colour = Data::URIID::Colour->new( option => value, ... );

Returns a new object for the given colour.
The following options are defined:

=over

=item C<rgb>

The RGB value in hex notation. E.g. C<#FF0000>.

=back

=head2 rgb

    my $rgb = $colour->rgb;

Returns the colour in six digit hex notation with prepended pound (C<#>) if successful or C<die> otherwise.
The returned value is suitable for use in CSS.

=head2 ise

    my $ise = $colour->ise;

This method will return the ISE of the colour if successful or C<die> otherwise.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2024 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
