package Test2AndUtils;
use strict;
use warnings;
use Test2::V0 '!subtest';
use Test2::Tools::Subtest 'subtest_streamed';
use IO::Handle;
use parent 'Test2::V0';

our @EXPORT= (
   @Test2::V0::EXPORT,
   qw( explain unindent pipe_with_data escape_nonprintable unescape_nonprintable
      pack_msg unpack_msg setup_tty_helper )
);

# Test2 runs async by default, which messes up the relation between warnings and the test
# that generated them.  Streamed generates output sequentially.
*subtest= \&subtest_streamed;

# Use Data::Printer if available, but fall back to Data::Dumper
eval q{
   use Data::Printer;
   sub explain { Data::Printer::np(@_) }
   1
} or eval q{
   use Data::Dumper;
   sub explain { Data::Dumper->new(\@_)->Terse(1)->Indent(1)->Sortkeys(1)->Dump }
   1
} or die $@;

# Perl didn't get <<~'x' until 5.28, so this lets you write an indented here-block and
# then remove the common indent from all lines.
sub unindent {
   my ($indent)= ($_[0] =~ /^(\s+)/);
   (my $x= $_[0]) =~ s/^$indent//mg;
   $x;
}

# Useful for preparing a pipe with data already loaded in it, and where the write handle
# already has autoflush enabled.
sub pipe_with_data {
   my $data = shift;
   pipe(my $r, my $w) or die "Cannot create pipe: $!";
   $w->autoflush(1);
   $w->print($data) if defined $data;
   return ($r, $w);
}

# Convert data strings to and from C / Perl backslash notation.
# Not exhaustive, just hit the most common cases and hex-escape the rest.

my %escape_to_char = ( "\\" => "\\", r => "\r", n => "\n", t => "\t" );
my %char_to_escape = reverse %escape_to_char;

sub escape_nonprintable {
   my $str = shift;
   $str =~ s/([^\x21-\x7E])/ defined $char_to_escape{$1}? "\\".$char_to_escape{$1} : sprintf("\\x%02X", ord $1) /ge;
   return $str;
}

sub unescape_nonprintable {
   my $str = shift;
   $str =~ s/\\(x([0-9A-F]{2})|.)/ defined $2? chr hex $2 : $escape_to_char{$1} /ge;
   return $str;
}

# Pack a small command message for the TTY helper.
sub pack_msg {
   my ($action, $data) = @_;
   $data = '' unless defined $data;
   return $action . ' ' . escape_nonprintable($data) . "\n";
}

# Unpack a command message from the TTY helper.
sub unpack_msg {
   my ($action, $data) = ($_[0] =~ /(\S+)\s+(.*)\n/);
   return ($action, unescape_nonprintable($data));
}

# Fork a helper process with a pseudo-tty and coordinate actions with it.
sub setup_tty_helper {
   my $code = shift;
   my $pty = IO::Pty->new;
   my $tty = $pty->slave;
   $tty->autoflush(1);
   $pty->autoflush(1);
   pipe(my $parent_read, my $child_write) or die "Cannot create pipe: $!";
   pipe(my $child_read, my $parent_write) or die "Cannot create pipe: $!";
   $parent_write->autoflush(1);
   $child_write->autoflush(1);

   defined(my $pid = fork()) or die "fork: $!";
   if (!$pid) {
      eval {
         local $SIG{ALRM} = sub { die "Child timeout" };
         alarm(10);
         close $parent_read;
         close $parent_write;
         close $tty;
         while (<$child_read>) {
            my ($action, $data) = unpack_msg($_);
            if ($action eq 'test_echo') {
               $pty->print("test\r");
               sysread($pty, my $buffer = '', 4096);
               warn "# Echo not working: " . escape_nonprintable($buffer)
                  unless $buffer eq "test\r\n";
            } elsif ($action eq 'type') {
               for (split //, $data) {
                  syswrite($pty, $_) or warn "# syswrite: $!";
                  sleep 0.05;
               }
            } elsif ($action eq 'sleep') {
               sleep $data;
            } elsif ($action eq 'read_pty') {
               sysread($pty, my $buffer = '', 4096);
               $child_write->print(pack_msg(read => $buffer));
            } elsif ($action eq 'exit') {
               POSIX::_exit(0);
            }
         }
      };
      warn "# child error: $@" if $@;
      POSIX::_exit(2);
   } else {
      local $SIG{ALRM} = sub { die "parent timeout" };
      alarm 20;
      close $child_read;
      close $child_write;
      close $pty;
      my $send = sub { $parent_write->print(pack_msg(@_)) };
      my $recv = sub { my $msg = <$parent_read>; unpack_msg $msg };
      $code->($send, $recv, $tty);
      $send->('exit');
      waitpid($pid, 0);
      alarm 0;
   }
}
1;
