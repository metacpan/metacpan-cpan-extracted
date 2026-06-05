use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );

use App::karr::Git;

# Regression: a failed native pull must surface the real libgit2 error, not a
# meaningless shell "(exit code 0)". (Pre-Git::Native, a *successful* shelled
# `git pull` returned 0, which Perl read as false → "failed (exit code 0)".)

subtest 'last_error is empty before any failure' => sub {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  my $git = App::karr::Git->new( dir => $repo );
  is $git->last_error, undef, 'no error recorded initially';
};

subtest 'no remote => pull is a no-op success, no error' => sub {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  my $git = App::karr::Git->new( dir => $repo );
  ok $git->pull, 'pull returns true when there is no remote';
};

subtest 'failed pull returns false and records the real error' => sub {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  # A remote that cannot possibly be fetched.
  system( 'git', '-C', $repo, 'remote', 'add', 'origin', '/nonexistent/karr-bogus.git' );
  my $git = App::karr::Git->new( dir => $repo );

  ok !$git->pull, 'pull returns false on a broken remote';
  ok defined $git->last_error && length $git->last_error,
    'the libgit2 error text is captured';
  unlike $git->last_error, qr/exit code/, 'no bogus shell exit-code wording';
};

done_testing;
