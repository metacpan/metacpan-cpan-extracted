use strict;

package Blatte::Ws;

sub new {
  my($type, $ws, $obj) = @_;
  bless [$ws, $obj], $type;
}

sub ws  { $_[0]->[0] }
sub obj { $_[0]->[1] }

sub transform {
  use Blatte::Syntax;

  my $self = shift;
  &Blatte::Syntax::transform($self->obj(), @_);
}

1;

__END__

=head1 NAME

Blatte::Ws - whitespace wrapper for Blatte objects

=head1 SYNOPSIS

You probably don't want to use this module directly.  Instead, use the
ws functions (C<wrapws>, C<unwrapws>, C<wsof>) in Blatte.pm.

=head1 DESCRIPTION

Blatte objects are frequently nested inside of whitespace objects,
representing the whitespace that preceded the object on input, or that should
precede the object on output.  The outermost whitespace wrapper takes
precedence.

=head1 AUTHOR

Bob Glickstein <bobg@zanshin.com>.

Visit the Blatte website, <http://www.blatte.org/>.

=head1 LICENSE

Copyright 2001 Bob Glickstein.  All rights reserved.

Blatte is distributed under the terms of the GNU General Public
License, version 2.  See the file LICENSE that accompanies the Blatte
distribution.

=head1 SEE ALSO

L<Blatte(3)>.
