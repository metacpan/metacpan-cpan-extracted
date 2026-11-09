# ABSTRACT: A stack trace thrown by a schema masks the password its storage holds
use strict;
use warnings;

BEGIN { $ENV{DBIO_TRACE} = 0 }

use Test::More;

use DBIO::Exception;
use DBIO::Schema;
use DBIO::Test::Storage;
use DBIO::AccessBroker::Static;

# OFFLINE (karr k311, maintainer's decision 2026-10-12). A stack trace finds
# the connect info in the arguments of the live frames. A password the storage
# holds -- set on it with connect_info, its frames long returned -- and that a
# frame of the caller passes around as an argument of its own is known to the
# storage only. DBIO::Schema::throw_exception hands the trace the connect info
# the storage already holds.
#
# What this file claims:
#   1. A password held by the storage is masked in a trace thrown through
#      throw_exception, as an argument of a frame of the caller.
#   2. Without a storage on the schema the trace is what it was, and building
#      it creates none.
#   3. With an AccessBroker attached the storage holds no answer of the
#      broker, and the error path asks the broker nothing: not for the
#      connect info, not for a refresh. The trace is built all the same.
#   4. A schema without stacktrace throws no trace.
#
# THE SUBSTITUTIONS: DBIO::Test::Storage for the storage; a broker that counts
# every call made to it.

my $SECRET = 'k311-secret-held-by-the-storage';
my @INFO   = ('dbi:K311:dbname=app', 'k311-user', $SECRET);

{
  package T::K311::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+DBIO::Test::Storage');

  package T::K311::CountingBroker;
  use base 'DBIO::AccessBroker::Static';
  our $CALLS = 0;
  sub connect_info_for                 { $CALLS++; [ @INFO ] }
  sub connect_info_for_storage         { $CALLS++; shift->next::method(@_) }
  sub current_connect_info_for         { $CALLS++; shift->next::method(@_) }
  sub current_connect_info_for_storage { $CALLS++; shift->next::method(@_) }
  sub needs_refresh                    { $CALLS++; 0 }
  sub refresh                          { $CALLS++; 1 }
}

# the password is the argument of a frame of its own, as the caller's code
# passes it around
sub passes_around {
  my ($schema, $password) = @_;
  $schema->throw_exception("boom");
}

sub trace_of (&) {
  my $code = shift;
  return eval { $code->(); 1 } ? undef : "$@";
}

# 1.
{
  my $schema = T::K311::Schema->clone;
  $schema->stacktrace(1);
  $schema->connection(@INFO);

  my $trace = trace_of { passes_around($schema, $SECRET) };
  like $trace, qr/^\tmain::passes_around\(\S+, "\*\*\*"\) called at /m,
    '1. the password is masked in the argument of the caller frame';
  unlike $trace, qr/\Q$SECRET\E/, '1. ... nowhere left in the trace';
}

# 2.
{
  my $schema = T::K311::Schema->clone;
  $schema->stacktrace(1);
  my $trace = trace_of { passes_around($schema, 'plain') };
  like $trace, qr/\bcalled at\b/, '2. there is a trace';
  ok !$schema->storage, '2. building the trace created no storage';

  ok defined trace_of { T::K311::Schema->throw_exception('x') },
    '2. a class throws as before';
}

# 3.
{
  my $broker = T::K311::CountingBroker->new;
  my $schema = T::K311::Schema->clone;
  $schema->stacktrace(1);
  $schema->connection($broker);
  my $calls = $T::K311::CountingBroker::CALLS;

  my $trace = trace_of { passes_around($schema, 'plain') };
  like $trace, qr/\bcalled at\b/, '3. a trace is built with a broker attached';
  is $T::K311::CountingBroker::CALLS, $calls,
    '3. the error path made no call to the broker';
}

# 4.
{
  my $schema = T::K311::Schema->clone;
  $schema->connection(@INFO);
  my $err = trace_of { passes_around($schema, 'plain') };
  unlike $err, qr/called at \S+ line \d+\n\t/, '4. without stacktrace there is no trace';
}

done_testing;
