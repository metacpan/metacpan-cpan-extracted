package Data::Password::zxcvbn::French::AdjacencyGraph;
use strict;
use warnings;
use Data::Password::zxcvbn::AdjacencyGraph::Common;
use Data::Password::zxcvbn::AdjacencyGraph::French;
our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: adjacency graphs for common French keyboards


our %graphs = (
    %Data::Password::zxcvbn::AdjacencyGraph::Common::graphs,
    %Data::Password::zxcvbn::AdjacencyGraph::French::graphs,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Password::zxcvbn::French::AdjacencyGraph - adjacency graphs for common French keyboards

=head1 VERSION

version 1.0.2

=head1 DESCRIPTION

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
