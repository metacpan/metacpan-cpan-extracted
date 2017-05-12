# $Id: Logical.pm,v 1.13 2004/06/11 21:50:53 claes Exp $

use strict;

our $VERSION = "1.00";

package Array::Stream::Transactional::Matcher::Logical;
our @ISA = qw(Array::Stream::Transactional::Matcher::Rule);

sub new {
  my ($class, @args) = @_;
  $class = ref $class || $class;
  bless [@args], $class;
}

sub match {
  1;
}

package Array::Stream::Transactional::Matcher::Logical::and;
our @ISA = qw(Array::Stream::Transactional::Matcher::Logical);

sub match {
  my ($self, $stream, @passthru) = @_;
  
  $stream->commit;
  my $match = 0;
  my $start_pos = $stream->pos;
  my $end_pos = $start_pos;
  if(@$self) {   
  RULES: foreach my $rule (@$self) {
      $match = $rule->match($stream, @passthru);
      unless($match) {
	$stream->rollback;
	return 0;
      }
      
      if($stream->pos > $end_pos) {
	$end_pos = $stream->pos;
      }
    }
  }
  
  $stream->rollback;
  my $move = $end_pos - $start_pos;
  $stream->next while($move--);
  return $match;
}

package Array::Stream::Transactional::Matcher::Logical::or;
our @ISA = qw(Array::Stream::Transactional::Matcher::Logical);

sub match {
  my ($self, $stream, @passthru) = @_;
  
  $stream->commit;
  
  if(@$self) {
    my $match = 0;
  RULES: foreach my $rule (@$self) {
      $match = $rule->match($stream, @passthru);
      if($match) {
	$stream->regret;
	return $match;
      }

    }
  }
  
  $stream->rollback;
  return 0;
}

package Array::Stream::Transactional::Matcher::Logical::xor;
our @ISA = qw(Array::Stream::Transactional::Matcher::Logical);

sub match {
  my ($self, $stream, @passthru) = @_;
  
  $stream->commit;
  
  my $match = 1;
  if (@$self) {
    my @rules = @$self;
    $match = $rules[0]->match($stream);
    @rules = @rules[1..$#rules];
  RULES: foreach my $rule (@rules) {
      my $next = $rule->match($stream, @passthru);
      unless(abs($match) ^ abs($next)) {
	$stream->rollback;
	return 0;
      }
      $stream->commit;
      $match ^= abs($next);
    }
  }
  
  unless($match) {
    $stream->rollback;
    return 0;
  }

  $stream->regret;
  return $match;
}

package Array::Stream::Transactional::Matcher::Logical::not;
our @ISA = qw(Array::Stream::Transactional::Matcher::Logical);

sub match {
  my ($self, $stream, @passthru) = @_;
  
  $stream->commit;
  
  my $match = 1;
  if(@$self) {
  RULES: foreach my $rule (@$self) {
      $match = $rule->match($stream, @passthru);
      if($match) {
	$stream->rollback;
	return 0;
      }
    }
  }

  $stream->regret;
  return 1;
}

1;
__END__
=head1 NAME

Array::Stream::Transactional::Matcher::Logical - Rules implementing logical operators

=head1 DESCRIPTION

Array::Stream::Transactional::Matcher::Logical implements the standard logical operators 
and, or, xor and not.

=head1 RULES

=head2 Array::Stream::Transactional::Matcher::Logical::and

N-ary logical AND.

=over 4

=item new ( @RULES )

Creates a new AND rule where each rule in @RULES must be true for this rule to be true.

=back

=head2 Array::Stream::Transactional::Matcher::Logical::or

N-ary logical OR.

=over 4

=item new ( @RULES )

Creates a new OR rule where one or more rules in @RULES must be true for this rule to be true.

=back

=head2 Array::Stream::Transactional::Matcher::Logical::xor

N-ary logical XOR.

=over 4

=item new ( @RULES )

Creates a new XOR rule. If first rule in @RULES is true, then the followingrule must be false. 
If the first rule in @RULES is false, then the following must be true. If there are more than 
two rules, the following rule must be the inverse of the previous otherwise this rule will be false.

=back

=head2 Array::Stream::Transactional::Matcher::Logical::not

N-ary logical NOT.

=over 4

=item new ( @RULES )

Creates a new NOT rule. All rules in @RULES must be false for this rule to be true.

=back

=head1 EXPORT

None by default.

=head1 AUTHOR

Claes Jacobsson, E<lt>claesjac@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Claes Jacobsson

This library is free software; you can redistribute it and/or modify it 
under the same license terms as Perl itself.

=cut
