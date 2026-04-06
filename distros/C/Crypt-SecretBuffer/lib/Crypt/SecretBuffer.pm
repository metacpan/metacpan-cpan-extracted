package Crypt::SecretBuffer;
# VERSION
# ABSTRACT: Prevent accidentally leaking a string of sensitive data
$Crypt::SecretBuffer::VERSION = '0.023';

use strict;
use warnings;
use Carp;
use IO::Handle;
use Scalar::Util ();
use Fcntl ();
use parent qw( DynaLoader );
use overload '""' => \&stringify,
             'cmp' => \&memcmp;

sub dl_load_flags {0x01} # Share extern symbols with other modules
bootstrap Crypt::SecretBuffer;


{
   package Crypt::SecretBuffer::Exports;
$Crypt::SecretBuffer::Exports::VERSION = '0.023';
   use Exporter 'import';
   @Crypt::SecretBuffer::Exports::EXPORT_OK= qw(
      secret_buffer secret span unmask_secrets_to memcmp
      NONBLOCK AT_LEAST ISO8859_1 ASCII UTF8 UTF16LE UTF16BE HEX BASE64
      MATCH_MULTI MATCH_REVERSE MATCH_NEGATE MATCH_ANCHORED MATCH_CONST_TIME
   );
}

# Some of the exported functions are not methods, so instead of having them in the object's
# namespace I put them in the ::Exports namespace.  Importing from Crypt::SecretBuffer is
# equivalent to importing from Crypt::SecretBuffer::Exports.
sub import {
   splice(@_, 0, 1, 'Crypt::SecretBuffer::Exports');
   goto \&Crypt::SecretBuffer::Exports::import;
}

# For "use Inline -with => 'Crypt::SecretBuffer';" but lazy-load the data.
sub Inline {
   require Crypt::SecretBuffer::Install::Files;
   goto \&Crypt::SecretBuffer::Install::Files::Inline;
}


sub stringify_mask {
   my $self= shift;
   if (@_) {
      $self->{stringify_mask}= shift;
      return $self;
   }
   $self->{stringify_mask}
}


sub append_console_line {
   my $self= shift;
   my ($input_fh, %options);
   # First argument can be input_fh, or just straight key/value list.
   if (@_ && ref($_[0]) && (ref $_[0] eq 'GLOB' || ref($_[0])->can('getc'))) {
      croak "Expected even-length list of options" unless @_ & 1;
      ($input_fh, %options)= @_;
   } else {
      croak "Expected even-length list of options" if @_ & 1;
      %options= @_;
      $input_fh= delete $options{input_fh};
   }
   my ($prompt, $prompt_fh, $char_mask, $char_count, $char_max, $char_class)
      = delete @options{qw( prompt prompt_fh char_mask char_count char_max char_class )};
   warn "unknown option: ".join(', ', keys %options)
      if keys %options;
   my ($reading_from, $writing_to)= ('supplied handle', 'supplied handle');
   if (!defined $input_fh) {
      # user is requesting a read from the controlling terminal
      if ($^O eq 'MSWin32') {
         open $input_fh, '+<', 'CONIN$' or croak 'open(CONIN$): '.$!;
         open $prompt_fh, '>', 'CONOUT$' or croak 'open(CONOUT$): '.$!
            unless defined $prompt_fh;
         $reading_from= 'CONIN$';
         $writing_to= 'CONOUT$';
      } else {
         open $input_fh, '+<', '/dev/tty' or croak "open(/dev/tty): $!";
         $prompt_fh= $input_fh unless defined $prompt_fh;
         $reading_from= $writing_to= '/dev/tty';
      }
   }
   if (!defined $prompt_fh && (defined $prompt || defined $char_mask)) {
      # Determine default prompt_fh
      # For terminals, if it was STDIN then the underlying descriptors or libc FILE handle
      # are probably read-only, so open a new writeable handle.  Also MSWin32 only has one
      # console, so do this even if it isn't currently set as STDIN.
      my $fd= fileno($input_fh);
      if (-t $input_fh && ((defined $fd && $fd == 0) || \*STDIN == $input_fh || $^O eq 'MSWin32')) {
         if ($^O eq 'MSWin32') {
            open $prompt_fh, '>', 'CONOUT$' or croak 'open(CONOUT$): '.$!;
            $writing_to= 'CONOUT$';
         } else {
            open $prompt_fh, '+<', '/dev/tty' or croak "open(/dev/tty): $!";
            $writing_to= '/dev/tty';
         }
      }
      # For sockets or tty, default to the same file descriptor as input_fh.
      # If the descriptor is read-only, things will fail, and it's the caller's
      # job to fix the bug.
      elsif (-S $input_fh || -t $input_fh) {
         $prompt_fh= $input_fh;
         $writing_to= 'input handle';
      }
      # Suppress prompt unless the handle looks like a TTY or Socket.  e.g. input from file
      # or pipe can't usefully be prompted.  It could be that the parent process created a
      # return pipe on STDOUT and wants to see the prompt there, but it would be too bold to
      # take a guess at that.  The caller can supply prompt_fh => \*STDOUT if they want to.
      else {
         $prompt= $char_mask= undef;
      }
   }
   # If the user wants control over the keypresses, need to disable line-editing mode.
   # ConsoleState obj with auto_restore restores the console state when it goes out of scope.
   my $input_by_chars= defined $char_mask || defined $char_count || defined $char_class;
   my $ttystate= Crypt::SecretBuffer::ConsoleState->maybe_new(
      handle => $input_fh,
      echo => 0,
      (line_input => 0)x!!$input_by_chars,
      auto_restore => 1
   );
   # Write the initial prompt
   if (defined $prompt) {
      $prompt_fh->print($prompt) && $prompt_fh->flush
         or croak "Failed to write $writing_to: $!";
   }
   my $start_len= $self->length;
   my $ret;
   if ($input_by_chars) {
      while (1) {
         $ret= $self->append_read($input_fh, 1)
            or last;
         # Handle control characters
         my $end_pos= $self->length - 1;
         if ($self->index(qr/[\0-\x1F\x7F]/, $end_pos) == $end_pos) {
            # If it is \r or \n, end.  If char_count was requested, and we didn't
            # end by that logic, then we don't have the requested char count, so
            # return false.
            if ($self->index(qr/[\r\n]/, $end_pos) == $end_pos) {
               $self->length($end_pos); # remove CR or LF
               last;
            }
            # handle backspace
            elsif ($self->index(qr/[\b\x7F]/, $end_pos) == $end_pos) {
               $self->length($end_pos); # remove backspace
               if ($self->length > $start_len) {
                  $self->length($self->length-1); # remove previous char
                  # print a backspace + space + backspace to erase the final mask character
                  if (length $char_mask) {
                     $prompt_fh->print(
                        ("\b" x length $char_mask)
                       .(" "  x length $char_mask)
                       .("\b" x length $char_mask))
                     && $prompt_fh->flush
                        or croak "Failed to write $writing_to: $!";
                  }
               }
            }
            # just ignore any other control char
            else {
               $self->length($end_pos);
            }
         }
         elsif ($char_class && $self->index($char_class, $end_pos) == -1) {
            # not part of the permitted char class
            $self->length($end_pos);
         }
         elsif ($char_max && $self->length - $start_len > $char_max) {
            # refuse to add more characters
            $self->length($end_pos);
         }
         else {
            # char added
            if (length $char_mask) {
               $prompt_fh->print($char_mask) && $prompt_fh->flush
                  or croak "Failed to write $writing_to: $!";
            }
            # If reached the char_count, return success
            last if $char_count && $self->length - $start_len == $char_count;
         }
      }
   }
   else {
      $ret= $self->_append_console_line($input_fh);
      if ($char_max && $self->length - $start_len > $char_max) {
         # truncate the input if char_max requested
         $self->length($start_len + $char_max);
      }
   }
   # If we're responsible for the prompt, also echo the newline to the user so that the caller
   # doesn't need to figure out what to use for $prompt_fh.
   $prompt_fh->print("\n") && $prompt_fh->flush
      if defined $prompt;

   return !$ret? $ret
      : $char_count? $self->length - $start_len == $char_count
      : 1;
}


sub as_pipe {
   my $self= shift;
   pipe(my ($r, $w)) or die "pipe: $!";   
   $self->write_async($w);
   close($w); # XS dups the file handle if it is writing async from a thread
   return $r;
}


sub load_file {
   my ($self, $path)= @_;
   open my $fh, '<', $path or croak "open($path): $!";
   my $chunksize= -s $fh;
   if (!$chunksize) {
      $chunksize= sysseek($fh, 0, Fcntl::SEEK_END());
      sysseek($fh, 0, Fcntl::SEEK_SET());
   }
   $chunksize ||= 64*1024; # if stat doesn't report size and not seekable, just try 64K
   while (1) {
      my $got= $self->append_sysread($fh, $chunksize);
      defined $got or croak "sysread($path): $!";
      last if $got == 0;
      # should have read the whole thing first try, but file could be changing, so keep going
      # at 64K intervals until EOF.
      $chunksize= 64*1024;
   }
   close($fh) or croak "close($path): $!";
   return $self;
}


sub save_file {
   my ($self, $path, $overwrite)= @_;
   my $fh;
   my $cur_path= "$path";
   if (!$overwrite) {
      -e $path and croak "File '$path' already exists";
      # I don't think there's an atomic way to create-without-overwrite in perl, so try this..
      open $fh, '>>', $path or croak "open($path): $!";
      croak "File '$path' already exists"
         if -s $fh > 0;
   } elsif ($overwrite eq 'rename') {
      require File::Temp;
      require File::Spec;
      my ($vol, $dir, $file)= File::Spec->splitpath($path);
      my $dest_dir= File::Spec->catpath($vol, $dir, '');
      $fh= File::Temp->new(DIR => (length($dest_dir)? $dest_dir : File::Spec->curdir));
      $cur_path= "$fh";
   } else {
      open $fh, '>', $path or croak "open($path): $!";
   }
   my $wrote= 0;
   while ($wrote < $self->length) {
      my $w= $self->syswrite($fh, $self->length - $wrote);
      defined $w or croak "syswrite($cur_path): $!";
      $wrote += $w;
   }
   close($fh) or croak "close($cur_path): $!";
   if ($overwrite eq 'rename') {
      rename($cur_path, $path) or croak "rename($cur_path -> $path): $!";
      $fh->unlink_on_destroy(0);
   }
   return $self;
}


# avoid depending on namespace::clean
delete @{Crypt::SecretBuffer::}{qw( carp croak confess )};

require Crypt::SecretBuffer::Span;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::SecretBuffer - Prevent accidentally leaking a string of sensitive data

=head1 SYNOPSIS

  use Crypt::SecretBuffer 'secret';
  $buf= secret;
  # read TTY with echo disabled
  $buf->append_console_line(STDIN, prompt => 'password: ')
    or die "Aborted";
  say $buf;                          # prints "[REDACTED]"
  
  my @cmd= qw( openssl enc -e -aes-256-cbc -md sha512 -pbkdf2 -iter 239823 -pass fd:3 );
  IPC::Run::run(\@cmd,
    '0<', \$data,
    '1>', \$ciphertext,
    '3<', $buf->as_pipe   # Feed the password to an external command
  );                      # without it ever being copied into a Perl scalar
  
  undef $buf;             # no copies of password remain in memory.
  
  # pass secret directly to a XS function without copying a scalar
  use Crypt::SecretBuffer 'unmask_secrets_to';
  unmask_secrets_to(\&c_function, $buf);
  $buf->unmask_to(\&c_function)

=head1 DESCRIPTION

This module helps you protect a secret value from getting copied around unintentionally or
lingering in memory of a long-running program.  It is very much like SecureString from .NET,
but with a better name.   (preventing accidental copies does not make something "secure", and
"string" sometimes implies text or immutability)  While a scripting language in general is a
poor choice for managing sensitive data in a long-lived app instance, this at least gives you
some measure of control over how long secrets remain in memory, and how easy it is to
accidentally expose them to other code, such as log messages.  When you free a SecretBuffer,
you can be fairly sure that the secret does not remain anywhere in your process address space.
(with the exception of when it's being fed into a pipe in the background; see L</as_pipe>)

This module exists because in standard OpenSSL examples they always wipe the buffers before
exiting a function, but with Perl's exception behavior (C<croak>) there was no way to ensure
that the buffers got wiped before exiting a function.  By putting all the secrets into
Crypt::SecretBuffer objects, it at least ensures that the buffers are always wiped according to
standard practices for C code.  Passing around SecretBuffer objects perl-side is just an added
benefit.

The SecretBuffer is a blessed reference, and the buffer itself is stored in XS in a way that
the Perl interpreter has no knowledge of.  Any time the buffer needs reallocated, a new buffer
is allocated, the secret is copied, and the old buffer is wiped clean before freeing it.

The API also provides you with a few ways to read or write the secret, since any read/write code
implemented directly in Perl would potentially expose your secret to having copies made in
temporary buffers.  But, for interoperability with other Perl code, you can also toggle whether
stringification of the buffer reveals the secret or not.  For instance:

  say $buf;                            # stringifies as [REDACTED]
  {
    local $buf->{stringify_mask}= undef;
    some_xs_function($buf);            # stringifies as the secret
  }
  say $buf;                            # stringifies as [REDACTED]

or:

  $buf->unmask_to(\&some_xs_function);

or:

  unmask_secrets_to($buf, \&some_xs_function);

There is no guarantee that the XS function in that example wouldn't make a copy of your secret,
but this at least provides the secret buffer directly to the XS code that calls C<SvPV> without
making a copy.  If an XS module is aware of Crypt::SecretBuffer, it can use a more official
L</C API> that doesn't rely on perl stringification behavior.

=head2 Supporting SecretBuffer Without a Dependency

If you have a module where you'd like to optionally receive secrets via SecretBuffer objects,
but don't want your module to depend on Crypt::SecretBuffer, here are some useful recipes:

=over

=item unmask a single variable with duck-typing

  sub connect($self, $dsn, $user, $password) {
    local $password->{stringify_mask}= undef
      if blessed $password && $password->can('stringify_mask');
    my $dbh= DBI->connect($dsn, $user, $password);
    ...
  }

=item use unmask_secrets_to with a fallback if SecretBuffer is not installed

  BEGIN {
    eval 'use Crypt::SecretBuffer qw/unmask_secrets_to/; 1'
    or eval 'sub unmask_secrets_to { shift->(@_) }'
  }
  sub connect($self, $dsn, $user, $password) {
    my $dbh= unmask_secrets_to \&DBI::connect, $dsn, $user, $password;
    ...
  }

=item In C code, perform the 'local' technique and overloaded stringification

  const char *actual_pass= NULL;
  STRLEN actual_pass_len;
  if (sv_isobject(password) && sv_derived_from(password, "Crypt::SecretBuffer")) {
    HV *hv= (HV*) SvRV(password);
    SV **svp= hv_fetchs(hv, "stringify_mask", 0);
    if (svp) {
      SAVESPTR(*svp);
      *svp= &PL_sv_undef;
    } else {
      hv_stores(hv, "stringify_mask", newSVsv(&PL_sv_undef));
      SAVEDELETE(hv, savepv("stringify_mask"), 14);
    }
  }
  actual_pass= SvPV(password, actual_pass_len);

=item In C code, conditionally access the SecretBuffer C API

(secret_buffer_SvPVbyte is a handy function that gives you a pointer to the
buffer, and even handles Span objects for you, and works like SvPVbyte even on
things that are not SecretBuffer objects)

  typedef const char * (*sb_SvPVbyte_p)(SV *, STRLEN *);
  ...
  const char *actual_pass= NULL;
  STRLEN actual_pass_len;
  SV *sv= get_sv("Crypt::SecretBuffer::C_API::const char * secret_buffer_SvPVbyte(SV *, STRLEN *)", 0);
  if (sv)
    actual_pass= ((sb_SvPVbyte_p)SvIV(sv))(password, &actual_pass_len);
  else
    actual_pass= SvPV(password, &actual_pass_len);
  ...

=back

=head1 CONSTRUCTORS

=head2 new

  $buf= Crypt::SecretBuffer->new($assign_value);
  $buf= Crypt::SecretBuffer->new(%attrs);

If you pass one value to the constructor, it L</assign>s that to the buffer.  If you pass a list
of key/value pairs, it assigns those attributes, such as C<< ->new(capacity => 20) >>.
Technically it just calls each key as a method with the value as a single argument, so you could
also do things like C<< ->new(append_random => 16) >>.

=head2 secret_buffer / secret

The functions C<secret_buffer> and C<secret> can be exported from this module as a shorthand
for C<< Crypt::SecretBuffer->new(...) >>.

=head1 ATTRIBUTES

=head2 capacity

  say $buf->capacity;
  $buf->capacity($n_bytes)->...
  $buf->capacity($n_bytes, AT_LEAST)->...
  $buf->capacity($n_bytes, 'AT_LEAST')->...

This reads or writes the allocated length of the buffer, presumably because you know how much
space you need for an upcoming read operation, but it can also free up space you know you no
longer need.  In the third example, a second parameter 'AT_LEAST' is passed to indicate that
the buffer does not need reallocated if it is already large enough.

=head2 length

  say $buf->length;
  $buf->length(0);    # wipes buffer
  $buf->length(32);   # fills with zeroes

This gets or sets the length of the string in the buffer.  If you set it to a smaller value,
the string is truncated.  If you set it to a larger value, the L</capacity> is raised as needed
and the bytes are initialized with zeroes.

=head2 stringify_mask

  $buf->stringify_mask;           # "[REDACTED]"
  $buf->stringify_mask("*****");  # now stringifies as "*****"
  $buf->stringify_mask(undef);    # exposes secret

Get or set the stringification mask.  Setting it to C<undef> causes L</stringify> to expose the
secret.  In order to restore the default C<"[REDACTED]"> you have to delete the attribute:
C<< delete $buf->{stringify_mask} >>.  This attribute is mainly intended to allow cusomizing the
mask during the constructor.  The preferred way to expose the secret is with C<local> on the
hash key directly.

=head1 METHODS

=head2 clear

Erases the buffer.  Equivalent to C<< $buf->length(0) >>.  Returns C<$self> for chaining.

=head2 splice

  $buf->splice($offset, $length, $replacement);

Replace a span of bytes in the buffer with a new value.  C<$offset> and C<$length> may be
negative to reference backward from the end of the buffer.  The replacement may be another
C<SecretBuffer>, a L<Span|Crypt::SecretBuffer::Span>, a scalar, a scalar-ref.
This copies raw bytes even if the replacement is a Span with an encoding.

Returns C<$self>, for chaining.  If you want to return the replaced span, use C<substr>.

=head2 assign

  $buf->assign($replacement, ...);

Replace contents of buffer with bytes of C<$replacement>, concatenating multiple arguments.
This copies raw bytes even if the replacement is a Span with an encoding.

=head2 append

  $buf->append($data, ...)

Append contents of buffer with bytes of C<$data>, concatenating multiple arguments.
This copies raw bytes even if the replacement is a Span with an encoding.

=head2 substr

  $buf->substr(1);            # New SecretBuffer minus the first character
  $buf->substr(0,5);          # First 5 characters of buffer
  $buf->substr(0,5,$buf2);    # replace first 5 characters with content of $buf2

This is exactly like Perl's C<substr> function, but it returns
C<Crypt::SecretBuffer> objects, and they are not an lvalue that alters the
original.  The offset and length are always bytes.

=head2 span

  $span= $buf->span($pos= 0, $len= $buf->len, $encoding=undef);
  $span= $buf->span(pos => $p0, lim => $p1, encoding => UTF8);

Like substr, but returns a L<Crypt::SecretBuffer::Span> which holds a reference back to the
original SecretBuffer.  The Span object has various methods convenient for parsing.

=head2 stringify

  $buf->stringify;               # returns "[REDACTED]"
  $buf->{stringify_mask}= "***";
  $buf->stringify;               # returns "***"
  $buf->{stringify_mask}= undef;
  $buf->stringify;               # returns secret value
  
  do { local $buf->{stringify_mask}= undef; "$buf" } # expose secret once

SecretBuffer tries not to expose the secret, so the default behavior of this function is to
return the string C<< "[REDACTED]" >> or whatever custom string you store in C<stringify_mask>.
If you set C<stringify_mask> to C<undef>, it exposes the secret.  You can use C<local> to limit
the scope of this exposure.

=head2 unmask_to

  @ret= $buf->unmask_to(sub{
    # use $_[0]
  });

Pass the secret value as an argument to a code-ref, and propagate the return value.
(C<wantarray> is propagated to the coderef).

If you want to prevent the secret from leaking into perl's heap, the coderef should be an XS
function, or strictly use C<< $_[0] >> without copying it to a 'my' variable.

See also: L</unmask_secrets_to>.

=head2 index

  $ofs= $buf->index($str_or_charclass, $from_offset=0);

Like Perl's C<index> function, it scans the string from an optional offset and returns the
location the string was found, or -1 if it doesn't exist.  This can also scan for a character
class provided in a C<< qr// >> expression, like the L</scan> function supports.
C<$from_offset> may be negative to count backward from the end of the buffer.

=head2 rindex

  $ofs= $buf->index($str_or_charclass, $from_offset=-1);

Like L</index> but in reverse, where the default C<$from_offset> is -1 (end of buffer).

=head2 scan

  ($ofs, $len)= $buf->scan($s, $flags=0, $ofs=0, $len=undef);

This function scans through the buffer looking for the first match of a string
or a character class.  The scan can optionally be limited to an offset and
length describing a substring of the buffer.  The return value is the position
of the start of the match and number of I<bytes> matched (which can be greater
than one when matching a character class in UTF-8, or if C<MATCH_MULTI> flag is
requested).  On failure, the return value is an empty list. (versions before
0.19 returned C<< $len == 0 >> and a seldom-useful C<$ofs>)
Unlike C<rindex>, a reverse scan match must fall entirely within the range of
C<< ($ofs .. $ofs+$len) >> rather than just starting before the ending offset.

Eventually, this function may be enhanced with full regex support, but for now
it is limited to one character class and optionally a '+' modifier as an alias
for flag C<MATCH_MULTI>.  Until that enhancement occurs, your regex notation must
start with C<[> and must end with either C<]> or C<+>.

  ($ofs, $len)= $buf->scan(qr/[\w]+/); # implies MATCH_MULTI

The C<$flags> may be a bitwise OR of the L</Match Flags> and one
L<Character Encoding|/Character Encodings>.
Note that C<$ofs> and C<$len> are still byte positions, and still suitable for
L</substr> on the buffer, which is different from Perl's substr on a unicode
string which works in terms of codepoint counts.

For a more convenient interface to this functionality, use L</span> to create a
L<Span object|Crypt::SecretBuffer::Span> and then call its methods.

=head2 memcmp

  $cmp= $buf->memcmp($buf2);

Compare contents of the buffer byte-by-byte to another SecretBuffer (or Span, or plain scalar)
in the same manner as the C function C<memcmp> but in constant time. (iterating the full length
of the shortest string to prevent timing attacks)

=head2 append_lenprefixed

  $buf->append_lenprefixed(@byte_strings);

Append one or more strings (which can be a SecretBuffer, L<Span|Crypt::SecretBuffer::Span>, or
plain scalar of bytes) to the buffer, prefixing each with a variable-length encoding of the
number of bytes that follows.
The variable length encoding is base128 big-endian, the same as implemented in
C<< pack('w',...) >>.  In other words,

  for (@byte_strings) {
    my $len= ref($_)? $_->length : length($_);
    $buf->append(pack("w", $len))->append($_);
  }

See L<Crypt::SecretBuffer::Span/parse_lenprefixed> for the decoding routine.

=head2 append_base128be

Append a variable-length integer encoded as base128 big-endian.  (same as C<< pack('w') >>)

=head2 append_base128le

Append a variable-length integer encoded as base128 little-endian.

=head2 append_asn1_der_length

Append a variable-length integer encoded as the format used by ASN.1 DER for element lengths.

=head2 append_random

  $byte_count= $buf->append_random($n_bytes);
  $byte_count= $buf->append_random($n_bytes, NONBLOCK);
  $byte_count= $buf->append_random($n_bytes, 'NONBLOCK');

Append N cryptographic-quality random bytes.  On POSIX systems, this uses either the C library
C<getrandom> call with C<GRND_RANDOM>, or if that isn't available, it reads from C</dev/random>.
The C<NONBLOCK> flag can be used to avoid blocking on insufficient entropy.  On Windows, this
uses C<CryptGenRandom> and the flag has no effect because it always returns the requested number
of bytes and never blocks.

=head2 append_console_line

  $bool= $buf->append_console_line($input_fh);
  $bool= $buf->append_console_line($input_fh, %options);
  $bool= $buf->append_console_line(%options);
  # Options:
  # prompt     => "Enter Password: "    print prompt after disabling echo
  # input_fh   => $readable_handle      handle for reading chars
  # prompt_fh  => $writeable_handle     handle for writing prompt
  # char_mask  => "*"                   show each char typed as '*'
  # char_count => $n                    return success only at exactly N characters
  # char_max   => $n                    stop adding characters after $n added
  # char_class => qr/[...]/             limit to members of character class

This turns off TTY echo (if the handle is a Unix TTY or Windows Console) and reads and appends
characters until newline or EOF (and does not store the \r or \n characters).
It returns true if the read "completed" with a line terminator, or false on EOF, or
C<undef> on any OS error.  Characters may be added to the buffer even when it returns false.
There may also be no characters added when it returns true, if the user just hits <enter>.

When possible, this reads directly from the OS to avoid buffering the secret in libc or Perl,
but reads from the buffer if you already have input data in one of those buffers, or if the
file handle is a virtual Perl handle not backed by the OS.

Options:

=over

=item prompt

This message is printed and flushed after disabling TTY echo.  This helps prevent a race
condition where a scripted interaction could start typing a password in response to the prompt
before the echo was disabled.  A defined value for this setting also echoes back a C<"\n">
to the user on completion.

=item input_fh

The file handle from which this function reads characters.  The default is C<< /dev/tty >> on
Unix and C<CONIN$> on MSWin32.  If this file handle is not writeable (such as C<< \*STDIN >>) and
you requested a prompt, you should probably also specify C<prompt_fh>.

=item prompt_fh

The file handle for writing the prompt and/or C<char_mask>.  If C<$input_fh> defaulted to
C</dev/tty> this defaults to the same (or C<CONOUT$> on MSWin32).  If C<$input_fh> is exactly
C<< \*STDIN >>, the default is to try opening C<< /dev/tty >> or C<CONOUT$> for writing.
Else the default for a terminal or socket is to write to C<$input_fh>, and if none of these
cases is true then the default is to suppress all prompting.  These defaults should allow you
to pass C<< input_fh => \*STDIN >> for the behavior of simply allowing the password to be piped
into the command when it isn't a terminal without having to test those conditions yourself.

=item char_mask

Display this static string every time the user types a key, for feedback.  A common choice would
be C<'*'> or C<'* '>.

=item char_count

Change the completion condition to having added exactly C<$n> characters to the buffer.
The method returns true as soon as this count is reached.  Pressing C<Enter> before the
required count is treated as an incomplete read and returns false, even though input was
successfully read.

Note that unicode is not supported yet, so this really means C<$n> bytes.

=item char_max

Stop appending characters when C<$n> have been added to the buffer, but don't return until the
user presses newline.  This should only be used with C<char_mask> so that the user can see that
additional keys are not being accepted.

=item char_class

Restrict the permitted characters.  This must be a Regexp-ref of a single character class.
Any character the user enters which is not in this class will be ignored and not added to the
buffer.

=back

When using options C<char_mask>, C<char_count>, or C<char_class>, the TTY line-input mode is
disabled and the code processes each character as it is received, manually handling backspace
etc.  The code does I<not> handle TTY geometry or unicode, and will display incorrectly if the
user's input reaches the edge of the terminal.  This won't usually be a problem if you just
want some fancy handling of N-digit codes where you want to return as soon as they reach the
limit:

  $buf->append_console_line(STDIN,
    prompt => "PIN: [             ]\b\b\b\b\b\b\b\b\b\b\b\b\b",
    char_mask  => "* ",
    char_count => 6,
    char_class => qr/[0-9]/,
  );

If this method doesn't have quite the behavior you were looking for, the read loop is perl
(not XS) and the cross-platform handling of console modes happens in
L<Crypt::SecretBuffer::ConsoleState>, so it should be reasonably easy to copy/paste and make
your own.

=head2 append_sysread

  $byte_count= $buf->append_sysread($fh, $count);

This performs a low-level read from the file handle and appends the bytes to the buffer.
It must be a real file handle with an underlying file descriptor number (C<fileno>).
Like C<sysread>, on error it returns C<undef> and on success it returns the count added.
This ignores Perl I/O layers.

=head2 append_read

  $byte_count= $buf->append_read($fh, $count);

This is a relaxed version of C<append_sysread> that when possible, reads directly from the OS
to avoid buffering the secret in libc or Perl, but reads from the Perl buffer if you already
have input data in one of those buffers, or if the file handle is a virtual Perl handle not
backed by the OS.

=head2 syswrite

  $byte_count= $buf->syswrite($fh); # one syswrite attempt of whole buffer
  $byte_count= $buf->syswrite($fh, $count); # prefix of buffer
  $byte_count= $buf->syswrite($fh, $count, $offset); # substr of buffer

This performs a low-level write from the buffer into a file handle.  It must be a real file
handle with an underlying file descriptor (C<fileno>).  If the handle has pending bytes in its
IO buffer, those are flushed first.  Like C<syswrite>, this returns C<undef> on an OS error,
and otherwise returns the number of bytes written.  It only makes one write attempt, which may
be shorter than the requested C<$count>. This ignores Perl I/O layers.

=head2 write_async

  $async_result= $buf->write_async($fh);                  # whole buffer
  $async_result= $buf->write_async($fh, $count);          # prefix of buffer
  $async_result= $buf->write_async($fh, $count, $offset); # substr of buffer
  ($wrote, $errno)= $async_result->wait;
  ($wrote, $errno)= $async_result->wait($seconds);

Write data into a file handle, using a background thread if needed.  Most likely, you will be
writing into a pipe, and your secret will be smaller than the OS pipe buffer, so this will
complete immediately without spawning a thread.  It also immediately returns if there was a
fatal error attempting to write the handle.  But if you have a large secret, or are writing into
a type of handle that can't buffer it, this function will duplicate your file handle and copy
the secret and pass them to a background thread to do the writing.

You can check the status or wait for its completion using the
L<$async_result|Crypt::SecretBuffer::AsyncResult> object.

=head2 as_pipe

  $fh= $buf->as_pipe

This creates a pipe, then calls C<< $self->write_async($pipe) >> into the write-end of the pipe.
You can then pass this pipe to other processes without needing to "pump" the pipe like you would
with L<IPC::Run>.

The C<$async_result> from L</write_async> is ignored, allowing the background thread to complete
(or error on a closed pipe) on its own time.

=head2 load_file

  $buf= secret(load_file => $path);
  # or
  $buf->load_file($path);

This is a simple wrapper around C<open> and C<append_sysread> and C<close>, checking for errors
at each step.

=head2 save_file

  $buf->save_file($path);
  $buf->save_file($path, $overwrite); # bool, overwrite existing file
  $buf->save_file($path, 'rename'); # overwrite using 'rename' of a temp file

This writes the contents of the buffer to a file at C<$path>, checking for errors at each step.
The file must not previously exist unless C<$overwrite> is true.  C<$overwrite> may be the
special value C<'rename'> to write to a temp file and then rename it into place.

=head1 EXPORTS

=over 15

=item AT_LEAST

Parameter for setting the L</capacity>.

=item NONBLOCK

Parameter for L</append_random>.

=item secret_buffer

Shorthand function for calling L</new>.

=item secret

Shorthand function for calling L</new>.

=item span

  $span= span($secret_buffer_or_span_or_scalar, $pos, $len, $encoding);
  $span= span($secret_buffer_or_span_or_scalar, %attributes);

This is sort of a coercion function that takes the first argument and makes it
into a buffer of bytes from which a span can be returned.  If the first argument
is a Span object, the return value is a clone rather than a pass-through.
The equivalent perl would be roughly:

  my $thing= shift;
  return $thing->isa('Crypt::SecretBuffer')? $thing->span(@_)
       : $thing->isa('Crypt::SecretBuffer::Span')? $thing->subspan(@_)
       : secret($thing)->span(@_);

See L<Crypt::SecretBuffer::Span/new> for a list of attributes.

=item unmask_secrets_to

  @ret= unmask_secrets_to \&coderef, $arg1, $arg2, ...;

Call a coderef with a list of arguments, and any argument which is a SecretBuffer will be
replaced by a scalar referencing the actual secret.  The return values are passed through,
as well as the C<wantarray> context.

=item memcmp

  $cmp= memcmp($thing1, $thing2);

This function always compares bytes, and the arguments can be L<SecretBuffer|Crypt::SecretBuffer>
objects, L<Span|Crypt::SecretBuffer::Span> objects, scalar-refs, and scalars.

=back

There are also constants for various character encodings, used by L</scan> and
L<Crypt::SecretBuffer::Span/encoding>.

=head2 Character Encodings

=over 20

=item ISO8859_1

The default; bytes are treated as the first 256 codepoints of Unicode.

=item ASCII

Bytes are restricted to 7-bit ASCII.  High bytes throw an exception.

=item HEX

Decode hexadecimal from the buffer before comparing to bytes in the search string.
Hex is case-insensitive and whitespace is ignored, allowing the data to be line-wraped.
There must be a multiple of two hex characters, and each byte's characters must be adjacent.

=item BASE64

Decode Base64 (C<< A-Za-z0-9+/= >>, with '=' used to pad to a multiple of 4 characters) from the
buffer before comparing to bytes in the search string.  The decoder skips across whitespace and
control characters.

=item UTF8

=item UTF16BE

=item UTF16LE

Treat the buffer as the specified character encoding, and die if any character
scanned is not valid.  (unpaired surrogates, overlong encodings, etc).

=back

=head2 Match Flags

=over

=item MATCH_REVERSE

Walk backward from the end of the buffer (or specified span) looking for a
match.

=item MATCH_MULTI

Once found, keep scanning until the buffer does I<not> match.  This is the same
as using a regex that ends with C<'+'>, but applies to the string searches as
well.

=item MATCH_NEGATE

Invert the result of each comparison.  This saves you the trouble of creating a
new regex with a negated character class.  It also works with plain-string searches,
so e.g. C<< scan($str, MATCH_MULTI) >> will start at the first character that wasn't
the start of a C<$str> match and include all characters until the first match or end
of buffer.

=item MATCH_ANCHORED

Require the match begin at the start of the specified span of the buffer.
(or with C<MATCH_REVERSE>, end at the end of the span of the buffer).

=item MATCH_CONST_TIME

Don't shortcut any loops on a non-matching byte/character.  This helps prevent timing attacks
by making all searches take the same length of time, but beware that this guarantees you always
get the worst-case performance of C<< O(N*M) >> when searching for a string within a secret.

NOTE: currently there is still about 15% difference in speed between the different code paths
of L</scan> between matching the start of the buffer vs. matching the end, due to complex
branching with all these match options.  An attacker would likely only be able to measure this
for particularly large buffers, though.  Patches welcome.

=back

=head1 C API

This module is intended for C code as much as it is for Perl code.  To write an XS module that
uses SecretBuffer, your XS module should use L<ExtUtils::Depends> to add the headers and linkage
needed for the C API:

  my $dep= ExtUtils::Depends->new('Your::Module', 'Crypt::SecretBuffer');
  ...
  WriteMakefile(
    'NAME' => 'Mymodule',
    $dep->get_makefile_vars()
  );

You can also just use it with L<Inline::C> if you want to skip the hassle of an XS module:

  package TestSecretBufferWithInline;
  use strict;
  use warnings;
  use Inline with => 'Crypt::SecretBuffer';
  use Inline C => <<END_C;
  
  #include <SecretBuffer.h>
  
  int test(secret_buffer *buf) {
    return buf->len;
  }
  
  END_C
  
  print test(Crypt::SecretBuffer->new(length => 10))."\n";
  1;

You can also look up individual functions at runtime to avoid depending on SecretBuffer being
installed.  Every function pointer is stored by name in C<< %Crypt::SecretBuffer::C_API >>
and also individually by their full prototype in global SVs for convenient and reliable access:

  typedef const char * (*sb_SvPVbyte_p)(SV *, STRLEN *);
  SV *sv= get_sv("Crypt::SecretBuffer::C_API::const char * secret_buffer_SvPVbyte(SV *, STRLEN *)", 0);
  if (sv) {
    sb_SvPVbyte_p sb_SvPVbyte= (sb_SvPVbyte_p) SvIV(sv);
    ...
  }

The complete API documentation is found in
L<SecretBuffer.h|https://metacpan.org/dist/Crypt-SecretBuffer/source/SecretBuffer.h>

=head1 Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website.  Please see
L<SECURITY.md|https://metacpan.org/dist/Crypt-SecretBuffer/source/SECURITY.md> for
instructions how to report security vulnerabilities.

=head1 VERSION

version 0.023

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
