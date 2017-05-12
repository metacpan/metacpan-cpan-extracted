#############################################################################
# (c) by Tels 2004. Part of Convert::Wiki
#
# represents a headline node
#############################################################################

package Convert::Wiki::Node::Head;

use 5.006001;
use strict;
use warnings;

use Convert::Wiki::Node;

use vars qw/$VERSION @ISA/;

@ISA = qw/Convert::Wiki::Node/;
$VERSION = '0.04';

#############################################################################

sub _init
  {
  my ($self,$args) = @_;

  $self->{level} ||= 1; 

  $self->SUPER::_init($args);
  }

sub _as_wiki
  {
  my ($self,$txt) = @_;

  # if we are the first headline, we get level 1
  if (!defined $self->prev_by_type('head'))
    {
    $self->{level} = 1;
    }
  # if we follow right on another headline, take it's level plus 1
  my $prev = $self->prev();
  if (defined $prev && $prev->type() eq 'head')
    {
    $self->{level} = $prev->{level} + 1;
    }

  my $p = '=' x ($self->{level} + 1);		# level 1: ==

  # "== Foo ==\n\n"
  $p . ' ' . $txt . ' ' . $p . "\n\n";
  }

1;
__END__

=head1 NAME

Convert::Wiki::Node::Head - Represents a headline node

=head1 SYNOPSIS

	use Convert::Wiki::Node::Head;

	my $head = Convert::Wiki::Node->new( txt => 'About Foo', type => 'head1' );

	print $head->as_wiki();

=head1 DESCRIPTION

A C<Convert::Wiki::Node::Head> represents a headline node in a text.

=head1 EXPORT

None by default.

=head1 SEE ALSO

The base class L<Convert::Wiki::Node>.

=head1 AUTHOR

Tels L<http://bloodgate.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Tels

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL. See the LICENSE file for more details.

=cut
