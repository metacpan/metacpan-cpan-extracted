#   belongs to t/05components.t
package DBIO::Test::ForeignComponent;
# ABSTRACT: Test class for foreign component loading
use warnings;
use strict;

use base qw/ DBIO::Base /;

__PACKAGE__->load_components( qw/ +DBIO::Test::ForeignComponent::TestComp / );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::ForeignComponent - Test class for foreign component loading

=head1 VERSION

version 0.900002

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
