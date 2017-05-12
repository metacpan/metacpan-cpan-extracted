package Bag::Similarity;

use strict;
use warnings;

use 5.008_005;
our $VERSION = '0.021';

use Carp 'croak';

sub new {
  my $class = shift;
  # uncoverable condition false
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub similarity {
  my ($self, $any1, $any2, $width) = @_;

  return $self->from_tokens(
    $self->_any($any1,$width),
    $self->_any($any2,$width)
  );
}

sub _any {
  my ($self, $any, $width) = @_;

  if (ref($any) eq 'ARRAY') {
    return $any;
  }
  elsif (ref($any) eq 'HASH') {
    return [grep { $any->{$_} } keys %$any];
  }
  elsif (ref($any)) {
    return [];
  }
  else {
    return [$self->ngrams($any,$width)];
  }
}

sub ngrams {
  my ($self, $word, $width) = @_;

  $width = 1 unless ($width && $width =~ m/^[1-9][0-9]*$/x);
  $word ||= '';

  return ($word) unless ($width <= length($word));

  return map {substr $word,$_,$width;} (0..length($word)-$width);
}

sub from_tokens {
  my ($self, $tokens1, $tokens2) = @_;

  return 1 if (!(scalar @$tokens1 || scalar @$tokens2));
  return 0 unless (scalar @$tokens1 && scalar @$tokens2 );

  return $self->from_bags(
    $tokens1,
    $tokens2,
  );
}

sub from_bags { croak 'Method "from_bags" not implemented in subclass' }

sub intersection {
  my ($self, $tokens1, $tokens2) = @_;
  my %bag1;
  my %bag2;
  $bag1{$_}++ for @{$tokens1};
  $bag2{$_}++ for @{$tokens2};
  my $intersection = 0;
  for (keys %bag1) {
    next unless (exists $bag2{$_} );
    $intersection += ( $bag2{$_} < $bag1{$_}) ? $bag2{$_} : $bag1{$_};
  }
  return $intersection;
}

sub combined_length {
  scalar(@{$_[1]}) + scalar(@{$_[2]});
}

sub min {
  (scalar(@{$_[1]}) < scalar(@{$_[2]}))
    ? scalar(@{$_[1]}) : scalar(@{$_[2]});
}

1;

__END__

=encoding utf-8

=head1 NAME

Bag::Similarity - Similarity measures for bags

=begin html

<a href="https://travis-ci.org/wollmers/Bag-Similarity"><img src="https://travis-ci.org/wollmers/Bag-Similarity.png" alt="Bag-Similarity"></a>
<a href='https://coveralls.io/r/wollmers/Bag-Similarity?branch=master'><img src='https://coveralls.io/repos/wollmers/Bag-Similarity/badge.png?branch=master' alt='Coverage Status' /></a>
<a href='http://cpants.cpanauthors.org/dist/Bag-Similarity'><img src='http://cpants.cpanauthors.org/dist/Bag-Similarity.png' alt='Kwalitee Score' /></a>
<a href="http://badge.fury.io/pl/Bag-Similarity"><img src="https://badge.fury.io/pl/Bag-Similarity.svg" alt="CPAN version" height="18"></a>

=end html


=head1 SYNOPSIS

  use Bag::Similarity;

=head1 DESCRIPTION

Bag::Similarity is the base class for similarity measures of bags.

=head1 METHODS

All methods can be used as class or object methods.

=head2 new

  $object = Bag::Similarity->new();

=head2 similarity

  my $similarity = $object->similarity($any1,$any1,$width);

C<$any> can be an arrayref, a hashref or a string. Strings are tokenized into n-grams of width C<$width>.

C<$width> must be integer, or defaults to 1.

=head2 from_tokens

  my $similarity = $object->from_tokens(['a','b'],['b']);

=head2 from_bags

  my $similarity = $object->from_bags(['a'],['b']);

Croaks if called directly. This method should be implemented in a child module.

=head2 intersection

  my $intersection_size = $object->intersection(['a'],['b']);

=head2 combined_length

  my $set_size_sum = $object->combined_length(['a'],['b']);

=head2 min

  my $min_set_size = $object->min(['a'],['b']);

=head2 ngrams

  my @monograms = $object->ngrams('abc');
  my @bigrams = $object->ngrams('abc',2);

=head2 _any

  my $arrayref = $object->_any($any,$width);

=head1 AUTHOR

Helmut Wollmersdorfer E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=begin html

<a href='http://cpants.cpanauthors.org/author/wollmers'><img src='http://cpants.cpanauthors.org/author/wollmers.png' alt='Kwalitee Score' /></a>

=end html

=head1 COPYRIGHT

Copyright 2014-2015 Helmut Wollmersdorfer

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
