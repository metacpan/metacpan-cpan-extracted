package DBIO::GraphQL::Filter::Null;
# ABSTRACT: No-op filter adapter - disables filtering entirely
use strict;
use warnings;

use base 'DBIO::GraphQL::Filter';

use GraphQL::Type::InputObject;

# A real second adapter for the Filter seam. type_for returns an empty
# InputObject (no per-column fields, no AND/OR combinators), and
# to_search always returns undef. When this adapter is wired into a
# GraphQL schema, filter args are syntactically permitted (a value
# of {} or null satisfies the type) but have no effect on the query.

sub type_for {
  my ($self, $moniker) = @_;
  return GraphQL::Type::InputObject->new(
    name   => "${moniker}Filter",
    fields => {},
  );
}

sub to_search {
  return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::GraphQL::Filter::Null - No-op filter adapter - disables filtering entirely

=head1 VERSION

version 0.900001

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
