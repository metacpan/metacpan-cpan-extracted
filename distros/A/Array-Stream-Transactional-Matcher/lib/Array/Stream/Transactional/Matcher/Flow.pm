# $Id: Flow.pm,v 1.14 2004/06/11 20:29:32 claes Exp $

use strict;

our $VERSION = "1.00";

package Array::Stream::Transactional::Matcher::Flow;
use Carp qw(croak confess);

our @ISA = qw(Array::Stream::Transactional::Matcher::Rule);

sub new {
  my ($class, @args) = @_;
  $class = ref $class || $class;
  
  croak "Can't instansiate abstract class Array::Stream::Transactional::Matcher::Flow" if($class eq "Array::Stream::Transactional::Matcher::Flow");
  
  my $self = bless [@args], $class;
  return $self;
}

package Array::Stream::Transactional::Matcher::Flow::sequence;
our @ISA = qw(Array::Stream::Transactional::Matcher::Flow);

sub match {
  my ($self, $stream, @passthru) = @_;
  
  $stream->commit;
  
  my @rules = @$self;
  my $match = 0;
 TEST: while(defined (my $rule = shift @rules)) {
    $match = $rule->match($stream, @passthru);
    unless($match) {
      $stream->rollback;
      return 0;
    }
    last TEST unless(@rules);
    $stream->next if($match > 0);
  }
  
  $stream->regret;
  return $match;
}


package Array::Stream::Transactional::Matcher::Flow::repetition;
use Carp qw(croak);
our @ISA = qw(Array::Stream::Transactional::Matcher::Flow);

sub match {
  my ($self, $stream, @passthru) = @_;

  $stream->commit;

  my ($rule, $min, $max) = @$self;

  # Take care of 0 as minmum
  unless($rule->match($stream, @passthru)) {
    $stream->rollback;
    if($min == 0) {
      return -1;
    }

    return 0;
  }

  my $match = 0;
  my $failure = 0;
  # Run while we have items in the stream
 TEST: while($stream->has_more) {
    if($rule->match($stream, @passthru)) {
      $match++;
      if(defined $max && $match == $max) {
	last TEST;
      }
      $stream->next;
    } else {
      $failure = 1;
      last TEST;
    }
  }
  
  if($match >= $min) {
    $stream->regret;
    return $failure ? -1 : 1;
  }

  # Report failure
  $stream->rollback;
  return 0;
}

package Array::Stream::Transactional::Matcher::Flow::optional;
our @ISA = qw(Array::Stream::Transactional::Matcher::Flow::repetition);

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_, 0, 1);
  return $self;
}

1;
__END__
=head1 NAME

Array::Stream::Transactional::Matcher::Flow - Rules implementing sequences and repetitions.

=head1 DESCRIPTION

Array::Stream::Transactional::Matcher::Flow implements standard flow rules such as an ordered sequence, a repetition and optional rules

=head1 RULES

=head2 Array::Stream::Transactional::Matcher::Flow::sequence

Implements a sequence of rules which must match in the order they are defined.

=over 4

=item new ( @RULES )

Creates a sequence of rules passed to the constructor. 

=back

=head2 Array::Stream::Transactional::Matcher::Flow::repetition

Implements a repetition of a specific rule that must match a specified number of times.

=over 4

=item new ( $RULE, $MIN, $MAX )

Creates a repetition rule that must match minimum $MIN times and maximum $MAX times. If $MAX is ommited, the rule must match at least $MIN times. 

=back

=head2 Array::Stream::Transactional::Matcher::Flow::optional

Implements an optional rule that may match.

=over 4

=item new ( $RULE )

Creates an optional rule.

=back

=head1 EXPORT

None by default.

=head1 AUTHOR

Claes Jacobsson, claesjac@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Claes Jacobsson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
