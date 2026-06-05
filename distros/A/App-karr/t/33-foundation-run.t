use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

use App::karr::Foundation;

my $f = App::karr::Foundation->new;

subtest 'captures output and exit code, appends to .karr.log' => sub {
  my $repo = path( tempdir( CLEANUP => 1 ) );
  my ( $code, $out ) = $f->_run_command( $repo, { max_runtime => 60 }, 'echo hello-karr' );
  is $code, 0, 'exit code 0';
  like $out, qr/hello-karr/, 'stdout captured into in-memory buffer';
  like $repo->child('.karr.log')->slurp_utf8, qr/hello-karr/, 'output also appended to .karr.log';
};

subtest 'non-zero exit code propagates' => sub {
  my $repo = path( tempdir( CLEANUP => 1 ) );
  my ( $code, $out ) = $f->_run_command( $repo, { max_runtime => 60 }, 'exit 7' );
  is $code, 7, 'exit code 7 propagated';
};

subtest 'merges stderr into the captured output' => sub {
  my $repo = path( tempdir( CLEANUP => 1 ) );
  my ( $code, $out ) = $f->_run_command( $repo, { max_runtime => 60 }, 'echo oops >&2' );
  like $out, qr/oops/, 'stderr merged into output';
};

subtest 'max_runtime: 0 disables the timeout' => sub {
  my $repo = path( tempdir( CLEANUP => 1 ) );
  my ( $code, $out ) = $f->_run_command( $repo, { max_runtime => 0 }, 'echo nolimit' );
  is $code, 0, 'runs to completion with no deadline';
  like $out, qr/nolimit/, 'output captured under undef-timeout path';
};

subtest 'timeout sends SIGKILL and reports exit -1' => sub {
  my $repo = path( tempdir( CLEANUP => 1 ) );
  my $start = time;
  my ( $code, $out ) = $f->_run_command( $repo, { max_runtime => 1 }, 'sleep 30' );
  is $code, -1, 'timed-out run reports exit -1';
  ok time - $start < 10, 'killed promptly, not after the full sleep';
};

done_testing;
