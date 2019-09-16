package Chart::GGPlot::Aes::Functions;

# ABSTRACT: Function interface for aesthetics mappings

use Chart::GGPlot::Setup qw(:base :pdl);

our $VERSION = '0.0007'; # VERSION

use Eval::Quosure;
use List::AllUtils qw(pairmap);
use Scalar::Util qw(looks_like_number);
use Type::Params;
use Types::Standard qw(ArrayRef);

use Chart::GGPlot::Aes;
use Chart::GGPlot::Types qw(:all);

use parent qw(Exporter::Tiny);

our @EXPORT_OK = qw(
  aes aes_all aes_to_scale is_position_aes
);
our %EXPORT_TAGS = (
    'all'    => \@EXPORT_OK,
    'ggplot' => [qw(aes aes_all)],
);


fun aes (%mapping) { _aes( \%mapping ); }

my $aes_level_default = 3;

fun _aes ($mapping, $level=$aes_level_default) {
    my %params = pairmap {
        my $val;

        # TODO: Shall we also support coderef sub { my ($df) = @_; } ?
        #  Thing is, is that really needed?

        if ( $b->$_DOES('Eval::Quosure') ) {
            $val = $b;
        }
        else {
            $val = Eval::Quosure->new( $b . '', $level );
        }
        $a => $val;
    }
    %$mapping;
    return Chart::GGPlot::Aes->new(%params);
}

# Look up the scale that should be used for a given aesthetic
fun aes_to_scale ($aesthetic) {
    $aesthetic = Chart::GGPlot::Aes->transform_key($aesthetic);
    return 'x' if ( $aesthetic =~ /^x(?:|min|max|end|intercept)$/ );
    return 'y' if ( $aesthetic =~ /^y(?:|min|max|end|intercept)$/ );
    return $aesthetic;
}

# Figure out if an aesthetic is a position aesthetic or not
fun is_position_aes ($aes_names) {
    my @new_names = map { aes_to_scale($_) } @$aes_names;
    return ( List::AllUtils::all { $_ eq 'x' or $_ eq 'y' } @new_names );
}


fun aes_all (@names) {
    return _aes( { map { $_ => $_ } @names }, $aes_level_default );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Aes::Functions - Function interface for aesthetics mappings

=head1 VERSION

version 0.0007

=head1 METHODS

=head2 aes_all

    aes_all(@aes_names)

Given a array of aes names, create a set of identity mappings, that is
like C<aes(x =E<gt> 'x', y =E<gt> 'y', ...)>.

=head1 FUNCTIONS

=head2 aes

    aes(%aesthetics_mapping);

This function is not exactly same as C<Chart::GGPlot::Aes-E<gt>new()>. This
function is specifically for creating aesthetics mapping which specifies
the mapping from data to aesthetics. Returned aes object from this function
is usually used for the C<mapping> attr of C<Chart::GGPlot::Plot> objects or
C<Chart::GGPlot::Geom> objects.

Values of C<%aesthetics_mapping> need to be one of the following:

=over 4

=item *

An C<Eval::Quosure> object.

=item *

Anything else would be stringified and converted to an C<Eval::Quosure>

object with enviroment be caller of the C<aes()> function.

=back

=head1 SEE ALSO

L<Chart::GGPlot::Aes>, L<Eval::Quosure>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
