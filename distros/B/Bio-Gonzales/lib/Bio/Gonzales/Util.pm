#Copyright (c) 2011 Joachim Bargsten <code at bargsten dot org>. All rights reserved.

package Bio::Gonzales::Util;

use warnings;
use strict;
use Carp;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(undef_slice slice invslice flatten hash_merge as_arrayref);

sub slice {
  my ( $hr, @k ) = @_;

  my $kk;
  if ( @k == 1 && ref( $k[0] ) eq 'ARRAY' ) {
    $kk = $k[0];
  } else {
    $kk = \@k;
  }

  my @valid_keys = grep { exists( $hr->{$_} ) } @$kk;

  return undef_slice( $hr, \@valid_keys );
}

sub invslice {
  my ( $hr, @k ) = @_;

  my $kk;
  if ( @k == 1 && ref( $k[0] ) eq 'ARRAY' ) {
    $kk = $k[0];
  } else {
    $kk = \@k;
  }

  my %inv = map { $_ => 1 } @$kk;

  my %ret;
  for my $k ( keys %$hr ) {
    next if ( exists( $inv{$k} ) );
    $ret{$k} = $hr->{$k};
  }

  return wantarray ? %ret : \%ret;
}

sub undef_slice {
  my ( $hr, @k ) = @_;

  my $kk;
  if ( @k == 1 && ref( $k[0] ) eq 'ARRAY' ) {
    $kk = $k[0];
  } else {
    $kk = \@k;
  }

  my %ret;
  @ret{@$kk} = @$hr{@$kk};

  return wantarray ? %ret : \%ret;
}

sub flatten {
  return map { ref eq 'ARRAY' ? flatten(@$_) : $_ } @_;
}

sub hash_merge {
  my ( $target, $source ) = @_;

  for ( keys %$source ) {
    if ( 'ARRAY' eq ref $target->{$_} ) {
      push @{ $target->{$_} }, @{ $source->{$_} };
    } elsif ( 'HASH' eq ref $target->{$_} ) {
      merge( $source->{$_}, $target->{$_} );
    } else {
      $target->{$_} = $source->{$_};
    }
  }
}

sub as_arrayref {
  my ($item) = @_;

  return unless ( defined($item) );

  if ( ref $item eq 'ARRAY' ) {
    return $item;
  } elsif ( !ref $item ) {
    return [$item];
  } else {
    return $item;
  }
}

1;

__END__

=head1 NAME

Bio::Gonzales::Util - Utility functions for common tasks

=head1 SYNOPSIS

    use Bio::Gonzales::Util qw(undef_slice slice invslice flatten hash_merge as_arrayref);

=head1 SUBROUTINES

=over 4

=item B<< %sliced_hash = slice(\%hash, @keys_to_slice) >>

=item B<< $sliced_hash = slice(\%hash, \@keys_to_slice) >>

return a new hash with all keys removed that are not in C<@keys_to_slice>.

=item B<< $sliced_hash = undef_slice(\%hash, \@keys_to_slice) >>

=item B<< %sliced_hash = undef_slice(\%hash, @keys_to_slice) >>

same as slice, but if a key in C<@keys_to_slice> does not exist in C<%hash>,
it will result in a additional entry with its value undefined
  
  my %hash = (
    a => 1,
    b => 2,
    c => 3
  );

  my %sliced_hash = undef_slice(\%hash, qw/a b d/);

  # will result in
  %sliced_hash = (
    a => 1,
    b => 2,
    d => undef
  );

=item B<< %sliced_hash = invslice(\%hash, @keys_to_exclude) >>

=item B<< \%sliced_hash = invslice(\%hash, \@keys_to_exclude) >>

=item B<< @elements = flatten($nested_array1, $nested_array2) >>

=back

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
