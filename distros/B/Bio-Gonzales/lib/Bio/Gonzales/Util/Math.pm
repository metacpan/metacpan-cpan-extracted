package Bio::Gonzales::Util::Math;

use warnings;
use strict;
use Carp;

use 5.010;

use Math::Combinatorics;
use List::Util;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(combine_alphabet shuffle);

sub combine_alphabet {
  my ($len) = @_;
  $len //= 2;
  my @n = ( 'a' .. 'z' );
  my @c = combine( $len, @n );
  return map { join "", @$_ } @c;
}

sub shuffle {
  my $d = shift;
  if ( ref $d eq 'HASH' ) {

    my %shuffled;

    my @keys = keys %$d;

    my @key_idcs = List::Util::shuffle( 0 .. $#keys );
    for ( my $i = 0; $i < @keys; $i++ ) {

      $shuffled{ $keys[ $key_idcs[$i] ] } = $d->{ $keys[$i] };
    }
    return \%shuffled;
  } elsif ( ref $d eq 'ARRAY' ) {
    return [ List::Util::shuffle @$d ];
  }

}

1;

__END__

=head1 NAME

Bio::Gonzales::Util::Math::Util

=head1 SYNOPSIS

    use Bio::Gonzales::Util::Math::Util qw/combine_alphabet/;

=head1 DESCRIPTION

=head1 SUBROUTINES

=over 4

=item B<< @character_combinations = combine_alphabet($length) >>

Combine alphabetic characters from a-z into a sequence of strings, e.g.

    @c = combine_alphabet(3);

results in

    abc
    aca
    aac
    ...
    zzz

=back

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
