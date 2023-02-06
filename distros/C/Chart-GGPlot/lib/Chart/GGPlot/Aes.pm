package Chart::GGPlot::Aes;

# ABSTRACT: Aesthetic mappings

use Chart::GGPlot::Setup;
use Function::Parameters qw(classmethod);
use namespace::autoclean;

our $VERSION = '0.002003'; # VERSION

use parent qw(Chart::GGPlot::Params);

use List::AllUtils qw(pairmap);

my @all_aesthetics = (
    "adj",    "alpha",    "angle",      "bg",
    "cex",    "col",      "color",      "colour",
    "fg",     "fill",     "group",      "hjust",
    "label",  "linetype", "lower",      "lty",
    "lwd",    "max",      "middle",     "min",
    "pch",    "radius",   "sample",     "shape",
    "size",   "srt",      "upper",      "vjust",
    "weight", "width",    "x",          "xend",
    "xmax",   "xmin",     "xintercept", "y",
    "yend",   "ymax",     "ymin",       "yintercept",
    "z"
);

my %base_to_ggplot = (
    "col"    => "color",
    "colour" => "color",
    "pch"    => "shape",
    "cex"    => "size",
    "lty"    => "linetype",
    "lwd"    => "size",
    "srt"    => "angle",
    "adj"    => "hjust",
    "bg"     => "fill",
    "fg"     => "color",
    "min"    => "ymin",
    "max"    => "ymax"
);

# Overrides the same method in Chart::GGPlot::Params.
classmethod transform_key ($key) {
    return ( $base_to_ggplot{$key} // $key );
}

classmethod all_aesthetics () { \@all_aesthetics; }

method keys () { [ sort( @{ $self->SUPER::keys() } ) ]; }


classmethod check_aesthetics ($aes, $n=undef) {
    unless ( defined $n ) {
        $n = List::AllUtils::max(
            @{ $aes->names->map( sub { $aes->at($_)->length } ) } );
    }

    my @bad_keys = grep {
        my $length = $aes->at($_)->length();
        !( $length == 1 or $length == $n )
    } @{ $aes->names };

    return unless @bad_keys;

    die(
        sprintf(
"Aesthetics must be either length 1 or the same as the data (%s): %s.",
            $n, join( ', ', map { qq{"$_"} } @bad_keys )
        )
    );
}


method string () {
    my @assoc = pairmap {
        $a => $b->$_DOES('Eval::Quosure') ? $b->expr : $b;
    } $self->flatten;
    return join(", ", pairmap { qq{$a => $b} } @assoc);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Aes - Aesthetic mappings

=head1 VERSION

version 0.002003

=head1 DESCRIPTION

This class inherits L<Chart::GGPlot::Params> to accept various names of
same concept, like color/colour/fg, fill/bg, etc.
Unlike L<Chart::GGPlot::Params>, this class has its object keys
alphabetically sorted.

It is designed for holding aesthetics-specific data. It can usually
be used in either of below two ways:

=over 4

=item * Created by the C<aes()> function.

For specifying how the aesthetics, like x/y variables (column names),
colors, etc., are mapped to data in your data frame input to C<ggplot()>.

=item * Used only for its key alias feature.

See L<Chart::GGPlot::Labels>.

=back

=head1 CLASS METHODS

=head2 check_aesthetics

    check_aesthetics($aes, $n=undef)

Checks if all values in the C<$aes> object are of length C<$n> or C<1>.
Dies on check failure. C<$aes> can be either a L<Chart::GGPlot::Aes> object
or a data frame object. If C<$n> is not specified, it defaults to the max
length of values (or columns) of C<$aes>. 

=head1 METHODS

=head2 string

    string()

=head1 SEE ALSO

L<Chart::GGPlot::Aes::Functions>,
L<Chart::GGPlot::Params>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
