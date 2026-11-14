package DBIO::Test::Slow;
# ABSTRACT: Mark a test file as slow so DBIO_TEST_FAST skips it
our $VERSION = '0.900005';
use strict;
use warnings;

use Test::More ();


sub import {
  return unless $ENV{DBIO_TEST_FAST};
  return if $ENV{RELEASE_TESTING} || $ENV{AUTOMATED_TESTING};
  Test::More::plan(skip_all => 'slow test, skipped under DBIO_TEST_FAST');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Slow - Mark a test file as slow so DBIO_TEST_FAST skips it

=head1 VERSION

version 0.900005

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Test::More;
  use DBIO::Test::Slow;

  # ... the rest of the test file

=head1 DESCRIPTION

A developer working on one corner of DBIO wants a quick run of the suite. A
test file that marks itself with C<use DBIO::Test::Slow;> directly after
C<use Test::More;> is skipped as a whole when the environment variable
C<DBIO_TEST_FAST> is true: on import the module calls
C<< Test::More::plan(skip_all => 'slow test, skipped under DBIO_TEST_FAST') >>.
Without the variable it does nothing and the file runs as any other.

=head1 ENVIRONMENT

=over 4

=item DBIO_TEST_FAST

A true value skips every file marked with this module.

=item RELEASE_TESTING

=item AUTOMATED_TESTING

Either one set to a true value wins over C<DBIO_TEST_FAST>: the marker then
never skips, so a release run and a smoker always run the full suite.

=back

=head1 WHEN TO MARK A FILE

Mark a file when it runs longer than about 5 seconds on an idle machine
(measure with C<prove -l --timer F<file>>) B<and> its subject is also touched
by a faster file, or is rarely the thing under development. A slow file that
is the only guard of its subject, or that is often the subject of a change,
stays unmarked.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
