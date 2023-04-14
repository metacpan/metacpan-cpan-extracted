package Data::Password::zxcvbn::German::AdjacencyGraph;
use strict;
use warnings;
use Data::Password::zxcvbn::AdjacencyGraph::Common;
use Data::Password::zxcvbn::AdjacencyGraph::German;
our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: adjacency graphs for common German keyboards


our %graphs = (
    %Data::Password::zxcvbn::AdjacencyGraph::Common::graphs,
    %Data::Password::zxcvbn::AdjacencyGraph::German::graphs,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Password::zxcvbn::German::AdjacencyGraph - adjacency graphs for common German keyboards

=head1 VERSION

version 1.0.2

=head1 DESCRIPTION

This merges the common graphs from the C<Data::Password::zxcvbn>
distribution, and German keyboards.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
