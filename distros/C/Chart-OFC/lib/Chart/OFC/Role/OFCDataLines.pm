package Chart::OFC::Role::OFCDataLines;
$Chart::OFC::Role::OFCDataLines::VERSION = '0.12';
use strict;
use warnings;

use Moose::Role;

requires '_ofc_data_lines';

sub _data_line    ## no critic RequireArgUnpacking
{
    my $self  = shift;
    my $label = shift;
    my @vals  = @_;

    $label =~ s/color/colour/;

    my $line = q{&} . $label . q{=};

    $line .=
        join ',', map { $self->_format_value($_) } @vals;

    $line .= q{&};

    return $line;
}

sub _format_value
{
    my $self  = shift;
    my $value = shift;

    return 'null' unless defined $value;

    # nested array ref values attr for things like scatter charts
    if ( ref $value eq 'ARRAY' )
    {
        return '[' . ( join ',', @{ $value } ) . ']';
    }
    else
    {
        return $self->_escape($value);
    }
}

sub _escape
{
    shift;
    my $string = shift;

    $string =~ s/,/#comma#/g;

    return $string;
}

no Moose::Role;

1;

# ABSTRACT: helper for classes which generate OFC data

__END__

=pod

=head1 NAME

Chart::OFC::Role::OFCDataLines - helper for classes which generate OFC data

=head1 VERSION

version 0.12

=head1 DESCRIPTION

This class provides a common helper method for classes which generate
OFC data (which is most classes in the Chart::OFC distro).

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
