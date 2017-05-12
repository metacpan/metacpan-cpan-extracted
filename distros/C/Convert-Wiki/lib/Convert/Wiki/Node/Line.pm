#############################################################################
# (c) by Tels 2004. Part of Convert::Wiki
#
# represents a horizontal line (or ruler)
#############################################################################

package Convert::Wiki::Node::Line;

use 5.006001;
use strict;
use warnings;

use Convert::Wiki::Node;

use vars qw/$VERSION @ISA/;

@ISA = qw/Convert::Wiki::Node/;
$VERSION = '0.03';

#############################################################################

sub _init
  {
  my ($self,$args) = @_;

  $self->SUPER::_init($args);

  $self->{txt} = "----\n\n";

  $self;
  }

sub _remove_me
  {
  # if we are the first node, or a headline follows us, skip
  my $self = shift;

  my $next = $self->next();

  if (!defined $self->prev() || (defined $next && $next->type() =~ /head/))
    {
    return 1;
    }
  0;
  }

1;
__END__

=head1 NAME

Convert::Wiki::Node::Line - Represents a horizontal line (aka ruler)

=head1 SYNOPSIS

	use Convert::Wiki::Node::Line;

	my $hr = Convert::Wiki::Node::Line->new( );

	print $hr->as_wiki();

=head1 DESCRIPTION

A C<Convert::Wiki::Node::Line> represents a horizontal line (aka ruler).

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
