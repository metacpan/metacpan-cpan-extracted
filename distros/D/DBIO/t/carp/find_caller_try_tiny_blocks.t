# ABSTRACT: Try::Tiny block frames are not the origin of a message
use strict;
use warnings;

use Test::More;
use Try::Tiny;

use DBIO::Exception;

# OFFLINE (karr k311, maintainer's decision 2026-10-12). The origin a
# DBIO::Carp message or an exception without stack trace names is the sub
# that raised it. The blocks of try, catch and finally are subs of Try::Tiny's
# making, shown by caller() as "PACKAGE::try {...}", "PACKAGE::catch {...}" and
# "PACKAGE::finally {...}"; they are no origin, like an (eval) or an __ANON__
# frame.
#
# What this file claims:
#   1. An exception thrown inside a catch block names the sub around the
#      try, not the block.
#   2. The same for the try block and the finally block. A finally block runs
#      from Try::Tiny::ScopeGuard::DESTROY, which is no origin either (karr
#      k339, maintainer's decision 2026-10-13): the sub around the try is.
#   3. A named sub that is called from a block still is the origin.

{
  package T::K311::Origin;
  use Try::Tiny;

  sub in_catch   { try { die "x\n" } catch { DBIO::Exception->throw('caught') } }
  sub in_try     { try { DBIO::Exception->throw('tried') } catch { die $_ } }
  our $fin;
  sub in_finally { try { 1 } finally { $fin = eval { DBIO::Exception->throw('finally') } ? "" : "$@" }; die $fin }
  sub helper     { DBIO::Exception->throw('helped') }
  sub via_block  { try { helper() } catch { die $_ } }
}

for my $case (
  [ 'catch',   'in_catch',   'caught'  ],
  [ 'try',     'in_try',     'tried'   ],
  [ 'finally', 'in_finally', 'finally' ],
  [ 'a named sub called from a block', 'via_block', 'helped' ],
) {
  my ($what, $sub, $msg) = @$case;
  my $err = eval { T::K311::Origin->can($sub)->(); 1 } ? '' : "$@";
  my $origin = $what =~ /named/ ? 'helper' : $sub;

  like $err, qr/^\S+\(\): \Q$msg\E at /, "$what: there is an origin";
  like $err, qr/^T::K311::Origin::\Q$origin\E\(\): /, "$what: the origin is the sub, not the block";
  unlike $err, qr/(?:try|catch|finally) \{\.\.\.\}/, "$what: no Try::Tiny block named";
}

done_testing;
