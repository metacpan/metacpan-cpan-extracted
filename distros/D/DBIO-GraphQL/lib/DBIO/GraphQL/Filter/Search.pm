package DBIO::GraphQL::Filter::Search;
# ABSTRACT: Default filter adapter - per-source nested-DBIO-style filter
use strict;
use warnings;

use base 'DBIO::GraphQL::Filter';

# Inherits type_for / to_search / _compile / _compile_column from
# DBIO::GraphQL::Filter. This is the default adapter used by
# DBIO::GraphQL->to_graphql; the second adapter (Filter::Null) exists
# to prove the seam is real.

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::GraphQL::Filter::Search - Default filter adapter - per-source nested-DBIO-style filter

=head1 VERSION

version 0.900000

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
