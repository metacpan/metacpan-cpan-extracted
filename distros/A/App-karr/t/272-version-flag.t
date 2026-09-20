use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );

use App::karr;

# Ticket #272: `karr --version` prints "karr <version>" on standard output and
# exits 0. It is a flag only -- there is no `version` subcommand -- and it must
# answer before any board discovery, so it works in a plain directory with no
# repository at all.

# $TMP is a plain directory, not a git repository: every subtest below runs
# from it, so a version flag that needed a board or a repository would fail
# here instead of passing.
my $TMP = tempdir( CLEANUP => 1 );

subtest 'karr --version prints karr <version> and exits 0' => sub {
  my $rv = run_karr( $TMP, '--version' );
  is( $rv->{exit}, 0, 'karr --version exits 0' ) or diag $rv->{stderr};
  is( $rv->{stdout}, "karr $App::karr::VERSION\n",
    'stdout is exactly "karr <version>"' );
  is( $rv->{stderr}, '', 'nothing on stderr' );
};

subtest 'karr --help lists --version under OPTIONS' => sub {
  my $rv = run_karr( $TMP, '--help' );
  is( $rv->{exit}, 0, 'karr --help exits 0' ) or diag $rv->{stderr};
  ( my $plain = $rv->{stdout} ) =~ s/\x1b\[[0-9;]*m//g;
  like( $plain, qr/^  --version\s+Print the karr version and exit$/m,
    'help lists --version under OPTIONS' );
};

done_testing;
