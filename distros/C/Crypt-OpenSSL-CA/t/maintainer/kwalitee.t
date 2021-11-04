#!/usr/bin/perl -w

=head1 NAME

kwalitee.t - Applies L<Test:Kwalitee> on the module.

=head1 DESCRIPTION

Code is basically copied and pasted from L<Test:Kwalitee>.  Note that you need
a tarball for this test (eg C<./Build dist>).


=cut

use Test2::V0;

# Dear Test::Kwalitee, kindly stop second-guessing my Build.PL regarding
# whether this test should run; and focus on doing your job:
$ENV{"AUTHOR_TESTING"} = 1;

eval { require Test::Kwalitee; Test::Kwalitee->import() };

skip_all('Test::Kwalitee not installed; skipping') if $@;

