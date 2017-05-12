#
# This file is part of DBIx-Class-Graph
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package DBIx::Class::ResultSet::Graph;
{
  $DBIx::Class::ResultSet::Graph::VERSION = '1.05';
}

use Moose;

use DBIx::Class::Graph::Wrapper;
extends 'DBIx::Class::ResultSet';
with 'DBIx::Class::Graph::Role::ResultSet';

sub get_graph { return shift->_graph }    # backwards compat

*graph = \&get_graph;


1;


=pod

=head1 NAME

DBIx::Class::ResultSet::Graph

=head1 VERSION

version 1.05

=head1 DESCRIPTION

See L<DBIx::Class::Graph>

=head1 NAME

DBIx::Class::ResultSet::Graph

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Moritz Onken

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__
# Below is stub documentation for your module. You'd better edit it!

