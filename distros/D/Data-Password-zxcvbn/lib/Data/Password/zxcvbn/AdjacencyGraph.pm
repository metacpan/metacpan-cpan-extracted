package Data::Password::zxcvbn::AdjacencyGraph;
use strict;
use warnings;
use Data::Password::zxcvbn::AdjacencyGraph::Common;
use Data::Password::zxcvbn::AdjacencyGraph::English;
our $VERSION = '1.1.2'; # VERSION
# ABSTRACT: adjacency graphs for common English keyboards


our %graphs = (
    %Data::Password::zxcvbn::AdjacencyGraph::Common::graphs,
    %Data::Password::zxcvbn::AdjacencyGraph::English::graphs,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Password::zxcvbn::AdjacencyGraph - adjacency graphs for common English keyboards

=head1 VERSION

version 1.1.2

=head1 DESCRIPTION

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
