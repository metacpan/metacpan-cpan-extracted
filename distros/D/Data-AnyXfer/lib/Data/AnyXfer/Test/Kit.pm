package Data::AnyXfer::Test::Kit;

use Test::Kit;
use Carp;

# Basically, Test::Most

include 'strict';
include 'warnings';
include 'Test::More';
include 'Test::Exception';
include 'Test::Deep';
include 'Test::Differences';
include 'Test::Warn';

# More tests

include 'Test::LongString';
include 'Test::Moose';
include 'Test::Warnings';

# Utilities

include 'Data::Printer';
include 'Data::Dumper::Concise';
include 'File::Slurp';
include 'Path::Class';
include 'Sys::Hostname';

BEGIN {
    include 'Data::AnyXfer';
    Data::AnyXfer->test(1);
}

include 'lib' => { import => [qw{ lib t/lib }] };

=head1 NAME

Data::AnyXfer::Test::Kit - a test kit for Data::AnyXfer

=head1 SYNOPSIS

  use Data::AnyXfer::Test::Kit;

  ...

=head2 Usage with C<Test::Aggregate::Nested>

  use Data::AnyXfer::Test::Kit;
  use Test::Aggregate::Nested;

  subtest 'nested tests' => sub {
    my @dirs = qw/st/;
    my $tests = Test::Aggregate::Nested->new( {
       dirs    => \@dirs,
       verbose => $ENV{TEST_VERBOSE} ? 2 : 1,
    } )->run;
  };

  done_testing;

As a result of C<Data::AnyXfer::Test::Kit> using C<Test::Warnings>, an extra
test is always run. C<Test::Aggregate::Nested> creates it's own test plan,
excluding the extra test, and subsequently fails. It is therefore necessary to
define the test plan.

=head1 DESCRIPTION

This module provides a L<Test::Kit> for Foxtons modules.

Use this in place of L<Test::Most>. It also includes the following:

=over

=item L<Data::Printer>

=item L<Data::Dumper::Concise>

Note: an alternative to C<Dumper> is the C<explain> function
from L<Test::More>.

=item L<File::Slurp>

=item L<Path::Class>

=item L<Sys::Hostname>

=item L<Test::LongString>

=item L<Test::Warnings>

=item L<Data::AnyXfer>

=back

=cut

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

