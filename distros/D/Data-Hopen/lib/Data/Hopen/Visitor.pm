# Data::Hopen::Visitor - abstract interface for a visitor.
package Data::Hopen::Visitor;
use strict;
use Data::Hopen::Base;

our $VERSION = '0.000019';

use Class::Tiny;

# Docs {{{1

=head1 NAME

Data::Hopen::Visitor - Abstract base class for DAG visitors

=head1 SYNOPSIS

This is an abstract base class for visitors provided to
L<Data::Hopen::G::Dag/run>.

=cut

# }}}1

=head1 FUNCTIONS

=head2 visit_goal

Process a L<Data::Hopen::G::Goal>.

=cut

sub visit_goal { ... }

=head2 visit_node

Process a graph node that is not a C<Data::Hopen::G::Goal>.

=cut

sub visit_node { ... }

1;
__END__
# vi: set fdm=marker: #
