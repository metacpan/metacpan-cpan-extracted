use strict;
use warnings;
use Test::More;

use App::karr::SyncGuard;

# Regression for ticket #18:
#   * SyncGuard reported "(exit code $?)" for push failures, but the native
#     Git::Native/libgit2 ops never set a shell exit code — the real error
#     channel is $git->last_error (see App::karr::Git). The message was
#     factually wrong and always meaningless.
#   * SyncGuard's DESTROY died on terminal push failure. During stack
#     unwinding (the exact scenario the guard insures against) a die inside
#     DESTROY is swallowed silently, so the "refs are intact" message never
#     reaches the operator. Prefer warn.

# A git double whose push always fails and exposes a distinctive libgit2-style
# error via last_error(). "PUSH-REJECTED" is the string we expect to surface;
# it must never be replaced by a bogus "exit code" phrasing.
{
  package FailGit;
  sub new { bless { pushes => 0 }, shift }
  sub push { my ($self) = @_; $self->{pushes}++; return 0 }
  sub last_error { 'PUSH-REJECTED: libgit2 remote hung up' }
}

# A git double whose push succeeds on the first try.
{
  package OkGit;
  sub new { bless { pushes => 0 }, shift }
  sub push { my ($self) = @_; $self->{pushes}++; return 1 }
  sub last_error { undef }
}

# Run $code with STDERR captured to an in-memory buffer. Returns
# ( $stderr_text, $error ) where $error is the exception if $code died,
# undef otherwise. STDERR stays redirected across the whole call, including
# object DESTROY that fires while an exception unwinds the stack.
sub capture_stderr {
  my ($code) = @_;
  my $buf = '';
  my $err;
  {
    local *STDERR;
    open STDERR, '>', \$buf or die "cannot redirect STDERR: $!";
    $err = do {
      local $@;
      eval { $code->(); 1 } ? undef : $@;
    };
  }
  return ( $buf, $err );
}

subtest 'push-failure error uses last_error, never a shell exit code' => sub {
  my $guard = App::karr::SyncGuard->new( git => FailGit->new );

  my ( $stderr, $err ) = capture_stderr( sub { $guard->DESTROY } );
  $guard->done;    # neutralise the second DESTROY at scope exit

  my @errs = $guard->errs;
  is scalar(@errs), 3, 'one recorded error per retry attempt';
  for my $e (@errs) {
    like $e, qr/PUSH-REJECTED/,
      'recorded error carries the real libgit2 last_error text';
    unlike $e, qr/exit code/,
      'recorded error has no bogus shell exit-code wording';
  }

  like $stderr, qr/PUSH-REJECTED/, 'real error surfaces on STDERR';
  unlike $stderr, qr/exit code/, 'no shell exit-code wording on STDERR';
};

subtest 'DESTROY warns on terminal failure and never dies' => sub {
  # Reproduce the documented insurance scenario: a command body dies while a
  # guard is still live, so DESTROY runs during stack unwinding.
  my ( $stderr, $err ) = capture_stderr( sub {
    my $guard = App::karr::SyncGuard->new( git => FailGit->new );
    die "BODY-died\n";
  } );

  is $err, "BODY-died\n", 'original exception is preserved, not masked';
  like $stderr, qr/Push failed after 3 attempts/,
    'terminal failure message reaches STDERR (warn, not a swallowed die)';
  unlike $stderr, qr/\(in cleanup\)/,
    'DESTROY warns instead of dying (no "(in cleanup)" die-during-unwind marker)';
  like $stderr, qr/PUSH-REJECTED/,
    'the underlying libgit2 error is included in the warning';
  unlike $stderr, qr/exit code/, 'no shell exit-code wording';
};

subtest 'successful push makes DESTROY a silent no-op' => sub {
  my $guard = App::karr::SyncGuard->new( git => OkGit->new );

  my ( $stderr, $err ) = capture_stderr( sub { $guard->DESTROY } );

  is $err, undef, 'DESTROY does not die on success';
  is scalar( $guard->errs ), 0, 'no errors recorded';
  unlike $stderr, qr/Push failed/, 'no failure message on success';
};

done_testing;
