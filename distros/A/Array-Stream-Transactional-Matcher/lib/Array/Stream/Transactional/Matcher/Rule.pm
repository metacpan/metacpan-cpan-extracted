# $Id: Rule.pm,v 1.4 2004/06/11 20:57:51 claes Exp $

package Array::Stream::Transactional::Matcher::Rule;
use strict;

our $VERSION = "1.00";

sub match { 0; }

1;
__END__
=head1 NAME

Array::Stream::Transactional::Matcher::Rule - Base class for rules

=head1 SYNOPSIS

  package MyRule;
  our @ISA = qw(Array::Stream::Transactional::Matcher::Rule);

  sub match {
    my ($class, $stream) = @_;
  
    $stream->commit;

    my $obj = $stream->current;
    if(ref $obj eq 'TestObject') {
      if(exists $obj->{description} && $obj->{description} =~ /Foo/) {
        $stream->regret;
        return 1;
      }
    }
  
    $stream->rollback;
    return 0;
  }

=head1 DESCRIPTION

Array::Stream::Transactional::Matcher::Rule is the base class of all rules. This document describes how to subclass it to provide more complex value matchers.

=head1 SUBCLASSING

Creating a custom rule is actually quite simple. All one have to do is to create declare a package that inherits from B<Array::Stream::Transactional::Matcher::Rule> and overriding the B<match> method. When match is called it is supplied with two arguments. The first is the rule object ($self) and the second is the stream we are currently iterating over. If the rule matches the method should return the value 1. If the rule does not match it should return 0. There is also a special case when the match method returns -1. In this case the top-iterator will not try to retrieve the next item in the stream before running the matchers again.

As seen in the synopsis a match should first B<commit> the stream before attempting any checks. If the rule is a match the method should call B<regret> on the stream to pop the commit from the commit stack. If the rule did not match it should B<rollback> the stream to the last commit. If this is done improperly the matcher will not work as expected.

=head1 EXPORT

None by default.

=head1 AUTHOR

Claes Jacobsson, E<lt>claesjac@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Claes Jacobsson

This library is free software; you can redistribute it and/or modify it 
under the same license terms as Perl itself.

=cut
