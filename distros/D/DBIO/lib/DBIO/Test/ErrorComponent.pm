#   belongs to t/run/90ensure_class_loaded.tl
package DBIO::Test::ErrorComponent;
# ABSTRACT: Test component that fails to load due to missing true value
use warnings;
use strict;

# this is missing on purpose
# 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::ErrorComponent - Test component that fails to load due to missing true value

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
