#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.

package Bio::Gonzales::Util::Text;

use warnings;
use strict;
use Carp;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(ccount ccount_iter);

sub ccount_iter {
    my ($args) = @_;

    my %counts;

    return sub {
        my ($string) = @_;

        return \%counts unless($string);

        my @counts;

        for ( my $i = length($string) - 1; $i >= 0; $i-- ) {
            $counts[ ord( substr( $string, $i, 1 ) ) ]++;
        }

        for my $idx ( 0 .. $#counts ) {
            if ( $args->{ignore_case} ) {
                $counts{ lc( chr($idx) ) } += $counts[$idx] if exists $counts[$idx];
            } else {
                $counts{ chr($idx) } += $counts[$idx] if exists $counts[$idx];

            }
        }

        return \%counts;
    };
}

sub ccount {
    my ( $string, $args ) = @_;
    my $counter = ccount_iter($args);

    return $counter->($string);
}

1;

__END__

=head1 NAME

Bio::Gonzales::Util::Text - text and string functions

=head1 SYNOPSIS

    use Bio::Gonzales::Util::Text qw(ccount);

=head1 DESCRIPTION

Text and string functions that can be useful in a bioinformaticians daily life.

=head1 SUBROUTINES

=over 4

=item B<< $counts = ccount($string) >>

counts the character occurrences in C<$string> and returns a hash with
characters as keys and their corresponding counts as values.

    $counts = {
        'A' => 34,
        'G' => 234234,
        'a' => 12,
        'C' => 234234,
        'T' => 46
    };

=back

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
