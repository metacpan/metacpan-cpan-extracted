package Algorithm::HowSimilar;

use 5.006;
use strict;
use warnings;
use Algorithm::Diff qw(traverse_sequences);
use Carp;
require Exporter;
use vars qw( @ISA @EXPORT_OK $VERSION );
our @ISA = qw(Exporter);
@EXPORT_OK = qw( compare );
$VERSION = '0.01';

sub compare {
    my $is_array = ref $_[0] eq 'ARRAY' ? 1 : 0;
    my $i = 0;
    if ( $is_array ) {
        my $seq1 = $_[0];
        my $seq2 = $_[1];
        my (@match,@d1, @d2) = ((),(),());
        traverse_sequences( $seq1, $seq2, {
            MATCH     => sub { push @match, $seq1->[$_[0]] },
            DISCARD_A => sub { push @d1, $seq1->[$_[0]] },
            DISCARD_B => sub { push @d2, $seq2->[$_[1]] },
        });
        my $m1 = @match/(@match+@d1);
        my $m2 = @match/(@match+@d2);
        my $mav = ($m1+$m2)/2;
      return $mav, $m1, $m2, \@match, \@d1, \@d2;
    }
    else {
        my ( $seq1, $seq2 );
        if ( $_[2] and ref $_[2] eq 'CODE' ) {
            local $_ = $_[0]; $seq1 = &{$_[2]};
            local $_ = $_[1]; $seq2 = &{$_[2]};
            carp "Did not get an array ref from callback!\n"
                unless ref $seq1 eq 'ARRAY' and ref $seq2 eq 'ARRAY';
        }
        else {
            $seq1 = _tokenize($_[0]);
            $seq2 = _tokenize($_[1]);
        }
        my ($match,$d1, $d2) = ('','','');
        traverse_sequences( $seq1, $seq2, {
            MATCH     => sub { $match .= $seq1->[$_[0]] },
            DISCARD_A => sub { $d1 .= $seq1->[$_[0]] },
            DISCARD_B => sub { $d2 .= $seq2->[$_[1]] },
        });
        my $m1 = length($match)/(length($match)+length($d1));
        my $m2 = length($match)/(length($match)+length($d2));
        my $mav = ($m1+$m2)/2;
      return $mav, $m1, $m2, $match, $d1, $d2;
    }

}

sub _tokenize { return [split //, $_[0]] }

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Algorithm::HowSimilar - Perl extension for quantifying similarites between things

=head1 SYNOPSIS

  use Algorithm::HowSimilar qw(compare);
  @res = compare( $str1, $str2, sub { s/\s+//g; [split //] } );
  @res = compare( \@ary1, \@ary2 );

=head1 DESCRIPTION

This module leverages Algorithm::Diff to let you compare the degree of sameness
of array or strings. It returns a result set that defines exactly how similar
these things are.

=head1 METHODS

=head2 compare( ARG1, ARG2, OPTIONAL_CALLBACK )

You can call compare with either two strings compare( $str1, $str2 ):

    my ( $av_similarity,
         $sim_str1_to_str2,
         $sim_str2_to_str1,
         $matches,
         $in_str1_but_not_str2,
         $in_str2_but_not_str1
       ) = compare( 'this is a string-a', 'this is a string bbb' );

Note that the mathematical similarities of one string to another will be
different unless the strings have the same length. The first result returned
is the average similarity. Totally dissimilar strings will return 0. Identical
strings will return 1. The degree of similarity therefore ranges from 0-1 and
is reported as the biggest float your OS/Perl can manage.

You can also compare two array refs compare( \@ary1, \@ary2 ):

    my ( $av_similarity,
         $sim_ary1_to_ary2,
         $sim_ary2_to_ary1,
         $ref_ary_matches,
         $ref_ary_in_ary1_but_not_ary2,
         $ref_ary_in_ary2_but_not_ary1
       ) = compare( [ 1,2,3,4 ], [ 3,4,5,6,7 ] );


When called with two string you can specify an optional callback that changes
the default tokenization of strings (a simple split on null) to whatever you
need. The strings are passed to you callback in $_ and the sub is expected to
return an array ref. So for example to ignore all
whitespace you could:

    @res = compare( 'this is a string',
                    'this is a string ',
                    sub { s/\s+//g; [split //] }
                  );

You already get the intersection of the strings or arrays. You can get the
union like this:

    @res = compare( $str1, $str2 );
    $intersection = $res[3];
    $union = $res[3].$res[4].$res[5];
    @res = compare( \@ary1, \@ary2 );
    @intersection = @{$res[3]};
    @union = ( @{$res[3]}, @{$res[4]}, @{$res[5]} );

=head2 EXPORT

None by default.

=head1 AUTHOR

Dr James Freeman <james.freeman@id3.org.uk>

=head1 SEE ALSO

L<perl>.

=cut
