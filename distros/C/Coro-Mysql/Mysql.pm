=head1 NAME

Coro::Mysql - let other threads run while doing mysql requests

=head1 SYNOPSIS

 use Coro::Mysql;

 my $DBH = Coro::Mysql::unblock DBI->connect (...);

=head1 DESCRIPTION

(Note that in this manual, "thread" refers to real threads as implemented
by the Coro module, not to the built-in windows process emulation which
unfortunately is also called "threads")

This module replaces the I/O handlers for a database connection, with the
effect that "patched" database handles no longer block the all threads of
a process, but only the thread that does the request.

This can be used to make parallel sql requests using Coro, or to do other
stuff while mysql is rumbling in the background.

=head2 CAVEAT

Note that this module must be linked against exactly the same (shared,
possibly not working with all OSes) F<libmysqlclient> library as
DBD::mysql, otherwise it will not work.

Also, this module requires a header file that apparently isn't installed
everywhere (F<violite.h>), and therefore comes with it's own copy, which
might or might not be compatible to the F<violite.h> of your library -
when in doubt, make sure all the libmysqlclient header files are installed
and delete the F<violite.h> header that comes with this module.

On the good side, this module does a multitude of checks to ensure that
the libray versions match on the binary level, so on incompatibilities you
should expect an exception when trying to unblock a handle, rather than
data corruption.

Also, while this module makes database handles non-blocking, you still
cannot run multiple requests in parallel on the same database handle. If
you want to run multiple queries in parallel, you have to create multiple
database connections, one for each thread that runs queries. Not doing
so can corrupt your data - use a Coro::Semaphore to protetc access to a
shared database handle when in doubt.

If you make sure that you never run two or more requests in parallel, you
can freely share the database handles between threads, of course.

=head2 SPEED

This module is implemented in XS, and as long as mysqld replies quickly
enough, it adds no overhead to the standard libmysql communication
routines (which are very badly written, btw.). In fact, since it has a
more efficient buffering and allows requests to run in parallel, it often
decreases the actual time to run many queries considerably.

For very fast queries ("select 0"), this module can add noticable overhead
(around 15%, 7% when EV can be used) as it tries to switch to other
coroutines when mysqld doesn't deliver the data immediately, although,
again, when running queries in parallel, they will usually execute faster.

For most types of queries, there will be no extra latency, especially on
multicore systems where your perl process can do other things while mysqld
does its stuff.

=head2 LIMITATIONS

This module only supports "standard" mysql connection handles - this
means unix domain or TCP sockets, and excludes SSL/TLS connections, named
pipes (windows) and shared memory (also windows). No support for these
connection types is planned, either.

=head1 CANCELLATION

Cancelling a thread that is within a mysql query will likely make the
handle unusable. As far as Coro::Mysql is concerned, the handle can be
safely destroyed, but it's not clear how mysql itself will react to a
cancellation.

=head1 FUNCTIONS

Coro::Mysql offers a single user-accessible function:

=over 4

=cut

package Coro::Mysql;

use strict qw(vars subs);
no warnings;

use Scalar::Util ();
use Carp qw(croak);

use Guard;
use AnyEvent ();
use Coro ();
use Coro::AnyEvent (); # not necessary with newer Coro versions

# we need this extra indirection, as Coro doesn't support
# calling SLF-like functions via call_sv.

sub readable { &Coro::Handle::FH::readable }
sub writable { &Coro::Handle::FH::writable }

BEGIN {
   our $VERSION = 1.27;

   require XSLoader;
   XSLoader::load Coro::Mysql::, $VERSION;
}

=item $DBH = Coro::Mysql::unblock $DBH

This function takes a DBI database handles and "patches" it
so it becomes compatible to Coro threads.

After that, it returns the patched handle - you should always use the
newly returned database handle.

It is safe to call this function on any database handle (or just about any
value), but it will only do anything to L<DBD::mysql> handles, others are
returned unchanged. That means it is harmless when applied to database
handles of other databases.

It is also safe to pass C<undef>, so code like this is works as expected:

   my $dbh = DBI->connect ($database, $user, $pass)->Coro::Mysql::unblock
      or die $DBI::errstr;

=cut

sub unblock {
   my ($DBH) = @_;

   if ($DBH && $DBH->{Driver}{Name} eq "mysql") {
      my $sock = $DBH->{sock};

      open my $fh, "+>&" . $DBH->{sockfd}
         or croak "Coro::Mysql unable to clone mysql fd";

      if (AnyEvent::detect ne "AnyEvent::Impl::EV" || !_use_ev) {
         require Coro::Handle;
         $fh = Coro::Handle::unblock ($fh);
      }

      _patch $sock, $DBH->{sockfd}, $DBH->{mysql_clientversion}, $fh, tied *$$fh;
   }

   $DBH
}

1;

=back

=head1 USAGE EXAMPLE

This example uses L<PApp::SQL> and L<Coro::on_enter> to implement a
function C<with_db>, that connects to a database, uses C<unblock> on the
resulting handle and then makes sure that C<$PApp::SQL::DBH> is set to the
(per-thread) database handle when the given thread is running (it does not
restore any previous value of $PApp::SQL::DBH, however):

   use Coro;
   use Coro::Mysql;
   use PApp::SQL;

   sub with_db($$$&) {
      my ($database, $user, $pass, $cb) = @_;

      my $dbh = DBI->connect ($database, $user, $pass)->Coro::Mysql::unblock
         or die $DBI::errstr;

      Coro::on_enter { $PApp::SQL::DBH = $dbh };

      $cb->();
   }  

This function makes it possible to easily use L<PApp::SQL> with
L<Coro::Mysql>, without worrying about database handles.

   # now start 10 threads doing stuff
   async {

      with_db "DBI:mysql:test", "", "", sub {
         sql_exec "update table set col = 5 where id = 7";

         my $st = sql_exec \my ($id, $name),
                           "select id, name from table where name like ?",
                           "a%";

         while ($st->fetch) {
            ...
         }

         my $id = sql_insertid sql_exec "insert into table values (1,2,3)";
         # etc.
      };

   } for 1..10;

=head1 SEE ALSO

L<Coro>, L<PApp::SQL> (a user friendly but efficient wrapper around DBI).

=head1 HISTORY

This module was initially hacked together within a few hours on a long
flight to Malaysia, and seems to have worked ever since, with minor
adjustments for newer libmysqlclient libraries.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

