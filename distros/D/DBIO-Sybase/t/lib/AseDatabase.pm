package AseDatabase;

# DROP DATABASE for the live tests that make a database of their own
# (karr k74).
#
# ASE refuses the statement while anything is in the database:
#
#   Msg 3702: Cannot drop or replace the database '..' because it is currently
#   in use.
#
# and what is in it need not be a session of the test. A full live run lost
# t/63-uniqueidentifier-live.t that way, at the drop that follows the
# disconnect of a section; the server's own checkpoint process was seen inside
# a database no client was connected to. What is in the way leaves by itself,
# so the drop is repeated -- on Msg 3702, and on nothing else -- until the
# server takes it, a fixed number of times.
#
# Nothing of lib/ is used here: how a test cleans up does not depend on the
# code it tests. DBIO::Sybase::Deploy repeats the drop of its temporary
# database the same way, in its own code. t/65-drop-database-in-use.t and
# t/66-drop-database-in-use-live.t pin both.

use strict;
use warnings;

use Time::HiRes ();

# AseDatabase::drop($dbh, $name)
# AseDatabase::drop($dbh, $name, tries => 3, wait => 0.1)
#
# Drops the database on $dbh, which is in master. Returns '' once it is gone,
# and otherwise what the server said, as "Msg <number>: <text>" -- after
# `tries` tries `wait` seconds apart (40 and 0.25: ten seconds) if that was
# Msg 3702, at once if it was anything else. It does not die of the server's
# refusal: the caller has tests to run after this one, and says by name what
# was left.
sub drop {
  my ($dbh, $name, %opt) = @_;
  my $tries = $opt{tries} // 40;
  my $wait  = $opt{wait}  // 0.25;

  local $dbh->{RaiseError} = 0;
  local $dbh->{PrintError} = 0;

  while (1) {
    return '' if defined $dbh->do("drop database $name");

    my $number = $dbh->err // 0;
    if ($number != 3702 or --$tries < 1) {
      my $said = $dbh->errstr // '(no message)';
      $said =~ s/\s+/ /g;
      return $said =~ /\btext=(.*?)\s*\z/ ? "Msg $number: $1" : $said;
    }

    Time::HiRes::sleep($wait);
  }
}

1;
