#   belongs to t/run/90ensure_class_loaded.tl
package DBIO::Test::ErrorComponent;
# ABSTRACT: Test component that fails to load due to missing true value
use warnings;

our $VERSION = '0.900005';

use strict;

# DO NOT "FIX" THIS TO 1 — and do not delete it.
#
# This fixture exists to make load_optional_class() die with Perl's
# "did not return a true value" error (t/90ensure_class_loaded.t). Perl emits
# that same error both for a module with no trailing true value and for one
# that explicitly returns false, so returning 0 here is what the test needs.
#
# The explicit 0 is also load-bearing against version sweeps: without a final
# statement, whatever the sweep stamps last — e.g. our $VERSION = '...' —
# becomes the file's return value, which is TRUE, the module loads cleanly and
# the test silently breaks. Keep this 0 as the last statement in the file.
0;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::ErrorComponent - Test component that fails to load due to missing true value

=head1 VERSION

version 0.900005

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
