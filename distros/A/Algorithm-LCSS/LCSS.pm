package Algorithm::LCSS;

use 5.006;
use strict;
use warnings;
use Algorithm::Diff qw(traverse_sequences);
require Exporter;
use vars qw( @ISA @EXPORT_OK $VERSION );
our @ISA = qw(Exporter);
@EXPORT_OK = qw( LCSS CSS CSS_Sorted );
$VERSION = '0.01';

sub _tokenize { [split //, $_[0]] }

sub CSS {
    my $is_array = ref $_[0] eq 'ARRAY' ? 1 : 0;
    my ( $seq1, $seq2, @match, $from_match );
    my $i = 0;
    if ( $is_array ) {
        $seq1 = $_[0];
        $seq2 = $_[1];
        traverse_sequences( $seq1, $seq2, {
            MATCH => sub { push @{$match[$i]}, $seq1->[$_[0]]; $from_match = 1 },
            DISCARD_A => sub { do{$i++; $from_match = 0} if $from_match },
            DISCARD_B => sub { do{$i++; $from_match = 0} if $from_match },
        });
    }
    else {
        $seq1 = _tokenize($_[0]);
        $seq2 = _tokenize($_[1]);
        traverse_sequences( $seq1, $seq2, {
            MATCH => sub { $match[$i] .= $seq1->[$_[0]]; $from_match = 1 },
            DISCARD_A => sub { do{$i++; $from_match = 0} if $from_match },
            DISCARD_B => sub { do{$i++; $from_match = 0} if $from_match },
        });
    }
  return \@match;
}

sub CSS_Sorted {
    my $match = CSS(@_);
    if ( ref $_[0] eq 'ARRAY' ) {
       @$match = map{$_->[0]}sort{$b->[1]<=>$a->[1]}map{[$_,scalar(@$_)]}@$match
    }
    else {
       @$match = map{$_->[0]}sort{$b->[1]<=>$a->[1]}map{[$_,length($_)]}@$match
    }
  return $match;
}

sub LCSS {
    my $is_array = ref $_[0] eq 'ARRAY' ? 1 : 0;
    my $css = CSS(@_);
    my $index;
    my $length = 0;
    if ( $is_array ) {
        for( my $i = 0; $i < @$css; $i++ ) {
            next unless @{$css->[$i]}>$length;
            $index = $i;
            $length = @{$css->[$i]};
        }
    }
    else {
        for( my $i = 0; $i < @$css; $i++ ) {
            next unless length($css->[$i])>$length;
            $index = $i;
            $length = length($css->[$i]);
        }
    }
  return $css->[$index];
}

1;
__END__

=head1 NAME

Algorithm::LCSS - Perl extension for getting the Longest Common Sub-Sequence

=head1 SYNOPSIS

    use Algorithm::LCSS qw( LCSS CSS CSS_Sorted );
    my $lcss_ary_ref = LCSS( \@SEQ1, \@SEQ2 );  # ref to array
    my $lcss_string  = LCSS( $STR1, $STR2 );    # string
    my $css_ary_ref = CSS( \@SEQ1, \@SEQ2 );    # ref to array of arrays
    my $css_str_ref = CSS( $STR1, $STR2 );      # ref to array of strings
    my $css_ary_ref = CSS_Sorted( \@SEQ1, \@SEQ2 );  # ref to array of arrays
    my $css_str_ref = CSS_Sorted( $STR1, $STR2 );    # ref to array of strings

=head1 DESCRIPTION

This module uses Algoritm::Diff to implement LCSS and is orders of magnitude
faster than String::LCSS.

If you pass the methods array refs you get back array (ref) format data. If
you pass strings you get a string or a ref to an array of strings.

=head1 METHODS

=head2 LCSS

Returns the longest common sub sequence. If there may be more than one (with
exactly the same length) and it matters use CSS instead.

    my $lcss_ary_ref = LCSS( \@SEQ1, \@SEQ2 );  # ref to array
    my $lcss_string  = LCSS( $STR1, $STR2 );    # string

=head2 CSS

Returns all the common sub sequences, unsorted.

    my $css_ary_ref = CSS( \@SEQ1, \@SEQ2 );  # ref to array of arrays
    my $css_str_ref = CSS( $STR1, $STR2 );    # ref to array of strings

=head2 CSS_Sorted

Returns all the common sub strings, sorted from longest to shortest CSS.

    my $css_ary_ref = CSS_Sorted( \@SEQ1, \@SEQ2 );  # ref to array of arrays
    my $css_str_ref = CSS_Sorted( $STR1, $STR2 );    # ref to array of strings

=head1 EXPORT

None by default.

=head1 AUTHOR

Dr James Freeman <james.freeman@id3.org.uk>

=head1 SEE ALSO

L<perl>.

=cut
