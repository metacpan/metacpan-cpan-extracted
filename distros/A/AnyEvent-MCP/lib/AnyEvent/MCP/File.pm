=head1 NAME

AnyEvent::MCP::File - private state file locking and replacement

=head1 DESCRIPTION

Internal utility for small state files shared by MCP processes,
such as the workdir ID registry. C<lock> obtains a lock on the current
pathname; C<replace> writes a complete new version atomically. The caller
owns serialization, validation and the lock's lifetime.

For example, after building a new complete file body:

   use AnyEvent::MCP::File ();

   my $lock = AnyEvent::MCP::File::lock $path;
   # read and validate the current state under this lock
   AnyEvent::MCP::File::replace $path, $new_bytes;
   close $lock;

The lock protects cooperating writers, not other programs that write the
file without this protocol. Use L<AnyEvent::MCP::Workdirs> for the workdir
registry rather than implementing its update rules here.

=head1 FUNCTIONS

=over

=item $lock = AnyEvent::MCP::File::lock $file

Create the parent directory and file if necessary, and lock the current file
exclusively. Retries if an atomic replacement changed the pathname while waiting for the lock.
Keep the returned handle alive through reading, modifying and replacing
the file. All writers must use this locking protocol.

=item AnyEvent::MCP::File::replace $file, $bytes

Write bytes to a temporary file beside C<$file>, preserve the mode of an
existing file, then atomically rename over C<$file>. The caller holds the lock.
Removes the temporary file on failure. This provides atomic visibility,
not crash durability.

=back

=cut

package AnyEvent::MCP::File;

use common::sense;
use File::Path ();
use File::Basename ();
use Fcntl qw(O_RDWR O_WRONLY O_CREAT O_EXCL LOCK_EX);
use Errno qw(ENOENT EEXIST);

sub lock {
   my ($file) = @_;

   File::Path::mkpath (File::Basename::dirname ($file), 0, 0700);

   while (1) {
      my $fh;
      sysopen $fh, $file, O_RDWR | O_CREAT | O_EXCL, 0600 or do {
         die "$file: $!\n" unless $! == EEXIST;
         sysopen $fh, $file, O_RDWR or die "$file: $!\n";
      };

      my @stat = stat $fh;
      flock $fh, LOCK_EX or die "$file: $!\n";
      my @current = stat $file;

      return $fh if @current && $stat[0] == $current[0] && $stat[1] == $current[1];

      die "$file: $!\n" unless @current || $! == ENOENT;

      close $fh;
   }
}

sub replace {
   my ($file, $bytes) = @_;

   my @stat = stat $file;
   die "$file: $!\n" unless @stat || $! == ENOENT;

   my $temporary = "$file.$$~";
   sysopen my $fh, $temporary, O_WRONLY | O_CREAT | O_EXCL, 0600 or die "$temporary: $!\n";

   my $ok = eval {
      print {$fh} $bytes or die "$temporary: $!\n";
      if (@stat) {
         my $mode = $stat[2] & 07777;
         chmod $mode, $fh or die "$temporary: $!\n";
      }
      close $fh or die "$temporary: $!\n";
      rename $temporary, $file or die "$file: $!\n";
      1
   };

   my $error = $@;
   unlink $temporary unless $ok;
   die $error unless $ok;
}

1;
