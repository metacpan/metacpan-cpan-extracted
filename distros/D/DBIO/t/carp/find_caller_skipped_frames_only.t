# ABSTRACT: A caller outside DBIO is named even when only skipped frames lead to it
use strict;
use warnings;

use Test::More;

use DBIO::Exception;

# An exception raised in an anonymous sub of a DBIO package, called from an
# eval in the program, has between DBIO and the program only frames that
# __find_caller skips (__ANON__, (eval)). The caller outside DBIO is still
# the place to name ("at FILE line N"), not a full stack trace: a callback
# run by a future looks exactly like this.
{
  package DBIO::Demo::Lib;
  sub run { DBIO::Exception->throw('refused') }
  sub cb  { sub { run() } }
}

my $cb = DBIO::Demo::Lib::cb();
my $line = __LINE__; eval { $cb->() };
my $err = "$@";

like $err, qr/\ADBIO::Demo::Lib::run\(\): refused  ?at \S+ line $line\n\z/,
  'the caller outside DBIO is named, no stack trace';

done_testing;
