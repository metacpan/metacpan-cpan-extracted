use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use Crypt::SecretBuffer qw( secret NONBLOCK );
use IO::Handle;
use File::Temp qw(tempfile);
use Time::HiRes qw( sleep );

# Test normal file handle reading
subtest 'append_console_line with file' => sub {
   my ($fh, $filename) = tempfile();
   print $fh "test data\nmore test data\nwindows newline\r\nline afterward\r\n";
   seek($fh, 0, 0); # Rewind

   my $buf = secret;
   $buf->{stringify_mask}= undef;

   my $result = $buf->append_console_line($fh);
   is($result, T, 'append_console_line returns true for complete line');

   is("$buf", "test data", 'Buffer contains expected data');
   is($buf->length, 9, 'Buffer length is correct');

   # Test reading another line
   $result = $buf->append_console_line($fh);
   ok($result, 'Second append_console_line returns true');

   is("$buf", "test datamore test data", 'Buffer contains appended data');
   is($buf->length, 23, 'Updated buffer length is correct');

   # Test reading with windows line ending
   $result = $buf->clear->append_console_line($fh);
   ok($result, 'Third append_console_line returns true');

   is("$buf", "windows newline", 'Buffer contains appended data');
   is($buf->length, 15, 'Updated buffer length is correct');

   # Test reading following windows line ending
   $result = $buf->append_console_line($fh);
   ok($result, 'Fourth append_console_line returns true');

   is("$buf", "windows newlineline afterward", 'Buffer contains appended data');
   is($buf->length, 29, 'Updated buffer length is correct');

   # Test EOF condition
   $result = $buf->append_console_line($fh);
   is($result, DF, 'append_console_line returns false on EOF');
};

# Test with an in-memory file handle using a reference to a scalar
subtest 'append_console_line with scalar ref handle' => sub {
   my $data = "password\n";
   open my $fh, '<', \$data or die "Cannot open scalar ref: $!";

   my $buf = Crypt::SecretBuffer->new;
   my $result = $buf->append_console_line($fh);
   ok($result, 'append_console_line returns true with scalar ref handle');

   $buf->{stringify_mask} = undef;
   is("$buf", "password", 'Buffer contains expected password');
   is($buf->length, 8, 'Buffer length matches password length');
};

# Test with empty line
subtest 'append_console_line with empty line' => sub {
   my ($r, $w)= pipe_with_data("\n");
   $w->close;

   my $buf = Crypt::SecretBuffer->new;
   my $result = $buf->append_console_line($r);
   ok($result, 'append_console_line returns true with empty line');
   is($buf->length, 0, 'Buffer length is zero for empty line');
};

# Test with no newline
subtest 'append_console_line with no newline' => sub {
   skip_all "Nonblocking doesn't work on Win32"
      if $^O eq 'MSWin32';

   my ($r, $w)= pipe_with_data("incomplete");
   $r->blocking(0);

   my $buf = Crypt::SecretBuffer->new;
   $buf->{stringify_mask} = undef;

   my $result = $buf->append_console_line($r);
   is($result, undef, 'append_console_line returns undef on nonblocking incomplete line');

   is("$buf", "incomplete", 'Buffer contains partial data');
   is($buf->length, 10, 'Buffer length matches input length');
};

subtest 'parent/child pipe communication' => sub {
   my ($read_fh, $write_fh)= pipe_with_data();
   
   my $pid = fork();
   die "Cannot fork: $!" unless defined $pid;
   
   if ($pid == 0) {
      # Child process
      print $write_fh "secret from child process\n";
      exit(0);
   }
   
   # Parent process
   my $buf = Crypt::SecretBuffer->new();
   my $result = $buf->append_console_line($read_fh);
   
   is($result, T, 'append_console_line returns true when reading from child process pipe');
   is($buf->length, 25, 'buffer contains correct number of characters from child process');
   
   $buf->{stringify_mask} = undef;
   is("$buf", 'secret from child process', 'content from child process is correct');
   
   waitpid($pid, 0);
   close($read_fh);
};


# Main test block for TTY functionality
subtest 'TTY functionality' => sub {
   # Skip tests if IO::Pty is not available
   skip_all("IO::Pty required for TTY tests")
      unless eval { require POSIX; require IO::Pty; IO::Pty->new(); 1 };
   skip_all("Test not working on freebsd yet, but feature does...")
      if $^O =~ /bsd/i;

   # Test 1: Basic TTY input - read until newline
   subtest "input until newline" => sub {
      setup_tty_helper(sub{
         my ($send_msg, $recv_msg, $tty)= @_;
         my $buf= secret();
         $tty->print("Enter Password: ");
         $send_msg->(sleep => .1);
         $send_msg->(type => "password123\n");
         is( $buf->append_console_line($tty), T, 'received full line' );
         is( $buf->length, 11, 'got 11 chars' );
         is( do { local $buf->{stringify_mask}= undef; "$buf" }, "password123", 'got password' );
         $send_msg->('read_pty');
         is( [ $recv_msg->() ], ['read', "Enter Password: "], 'Saw prompt, and no echo' );
         $send_msg->(type => "x\r");
         $send_msg->(sleep => .1);
         $send_msg->('read_pty');
         is( [ $recv_msg->() ], ['read', "x\r\n"], 'Echo resumed' );
      });
      done_testing;
   };
};

subtest 'PerlIO buffer interaction' => sub {
   my ($read_fh, $write_fh)= pipe_with_data("line one");
   
   my $buf = Crypt::SecretBuffer->new();
   $buf->{stringify_mask} = undef;

   # Trigger perl's internal I/O buffering by reading less than is available on the pipe
   $read_fh->read(my $temp, 5);  # Read "line ", leave "one" in perls buffer

   # write the rest of the line into the pipe
   $write_fh->print("\nline two\n");

   # The getline function will now read "one" from perl's buffer and then "\n" from a sysread
   is($buf->append_console_line($read_fh), T, 'append_console_line got a line');
   is($buf->length, 3, 'buffer->len');
   is("$buf", 'one', 'first line is correct');
};

subtest 'multiple buffers with append_console_line' => sub {
   my ($read_fh, $write_fh)= pipe_with_data("line1\nline2\nline3\n");
   close($write_fh);
   
   my $buf1 = Crypt::SecretBuffer->new();
   my $buf2 = Crypt::SecretBuffer->new();
   my $buf3 = Crypt::SecretBuffer->new();
   
   my $result1 = $buf1->append_console_line($read_fh);
   my $result2 = $buf2->append_console_line($read_fh);
   my $result3 = $buf3->append_console_line($read_fh);
   
   is($result1, T, 'first buffer got true result');
   is($result2, T, 'second buffer got true result');
   is($result3, T, 'third buffer got true result');
   
   {
      local $buf1->{stringify_mask} = undef;
      local $buf2->{stringify_mask} = undef;
      local $buf3->{stringify_mask} = undef;
      
      is("$buf1", 'line1', 'first buffer got first line');
      is("$buf2", 'line2', 'second buffer got second line');
      is("$buf3", 'line3', 'third buffer got third line');
   }
   
   # Try reading when no more lines (should be EOF)
   my $buf4 = Crypt::SecretBuffer->new();
   my $result4 = $buf4->append_console_line($read_fh);
   
   is($result4, DF, 'reading when no more lines returns "EOF"');
   is($buf4->length, 0, 'buffer is empty when EOF reached');
   
   close($read_fh);
};

done_testing;
