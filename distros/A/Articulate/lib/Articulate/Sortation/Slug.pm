package Articulate::Sortation::Slug;
use strict;
use warnings;

use Moo;
with 'Articulate::Role::Sortation::AllYouNeedIsCmp';

=head1 NAME

Articulate::Sortation::Slug - natural slug sorting

=head1 DESCRIPTION

This implements the L<Articulate::Role::Sortation::AllYouNeedIsCmp>
role to provide a sorter object which will break up

=head1 METHODS

One method provided here, the rest are as in
L<Articulate::Role::Sortation::AllYouNeedIsCmp>.

=head3 cmp

  $self->cmp('foo-1', 'bar');    # bar comes before foo
  $self->cmp('foo-2', 'foo-11'); # 2 comes before 11
  $self->cmp('foo-2',  'food');  # foo comes before food

Splits into numerical and alphabetical. Sorts the former numerically
and the latter alphabetically. All characters other than a-z and 0-9
are treated as 'word breaks' and divide up components but are otherwise
ignored.

=cut

sub _left { -1 }

sub _right { 1 }

sub cmp {
  my $self     = shift;
  my $left     = shift;
  my $right    = shift;
  my $re_break = qr/(?: # Breaks between groups of characters
  #  (?<=[a-z])|(?=[a-z]) # aa
    (?<=[a-z])(?![a-z]) # a0
  | (?<![a-z])(?=[a-z]) # 0a
  | (?<=[0-9])(?![0-9]) # 0_
  | (?<![0-9])(?=[0-9]) # _0
  )/ix;
  my $la = [ grep { $_ ne '' } split( $re_break, $left ) ];
  my $ra = [ grep { $_ ne '' } split( $re_break, $right ) ];

  #warn Dump {left => {$left, $la}, right => {$right,$ra}};
  while ( scalar @$la && scalar @$ra ) {
    my $l = shift @$la;
    my $r = shift @$ra;
    if ( $l =~ /^[^a-z0-9]/i ) {
      if ( $r =~ /^[a-z0-9]/i ) {

        # left is dash and right is not - left wins
        return _left;
      }
      next; # otherwise both are dash - continue
    }
    elsif ( $r =~ /^[^a-z0-9]/i ) {

      # right is dash and left is not - right wins
      return _right;
    }
    elsif ( $l =~ /^[0-9]/ ) {
      if ( $r =~ /^[0-9]/ ) {

        # both are numbers
        my $res = ( $l <=> $r );
        return $res if $res;
      }
      else {
        # left is number, right is alpha -  left wins
        return _left;
      }
    }
    else {
      # both are alphabetic
      my $res = ( $l cmp $r );
      return $res if $res;
    }
  }
  return @$ra ? _left : 0 if ( !@$la );
  return _right if ( !@$ra );
  die 'shouldn\'t be here' if $left ne $right;
  return $left cmp $right;
}

=head1 SEE ALSO

=over

=item * L<Articulate::Sortation::String>

=item * L<Articulate::Sortation::Numeric>

=back

=cut

1;
