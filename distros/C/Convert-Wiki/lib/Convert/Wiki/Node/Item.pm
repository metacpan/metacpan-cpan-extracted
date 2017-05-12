#############################################################################
# (c) by Tels 2004. Part of Convert::Wiki
#
# represents an item in a list (aka <li> or *)
#############################################################################

package Convert::Wiki::Node::Item;

use 5.006001;
use strict;
use warnings;

use Convert::Wiki::Node;

use vars qw/$VERSION @ISA/;

@ISA = qw/Convert::Wiki::Node/;

$VERSION = '0.03';

#############################################################################

sub _as_wiki
  {
  my ($self,$txt) = @_;

  # "* Foo bar is baz.\n"
  my $trailing = "\n";

  # add a new line if the next node is not an item
  my $next = $self->{next};
  $trailing .= "\n" if defined $next && $next->type() ne 'item';

  '* ' . $txt . $trailing;
  }

1;
__END__

=head1 NAME

Convert::Wiki::Node::Item - Represents an item in a list (aka <li> or *)

=head1 SYNOPSIS

	use Convert::Wiki::Node::Item;

	my $para = Convert::Wiki::Node->new( txt => 'Foo is a foobar.', type => 'item' );

	print $para->as_wiki();		# print something like "* Foo is a foorbar\n"

=head1 DESCRIPTION

A C<Convert::Wiki::Node::Item> represents an item in a list (aka the equivalent of
C<< <li> >> or C<*>.

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Convert::Wiki::Node>.

=head1 AUTHOR

Tels L<http://bloodgate.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Tels

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL. See the LICENSE file for more details.

=cut
