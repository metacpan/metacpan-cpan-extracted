package Crypt::SecretBuffer;
# VERSION
# ABSTRACT: Prevent accidentally leaking a string of sensitive data
$Crypt::SecretBuffer::VERSION = '0.016';

use strict;
use warnings;
use Carp;
use Scalar::Util ();
use parent qw( DynaLoader );
use overload '""' => \&stringify,
             'cmp' => \&memcmp;

sub dl_load_flags {0x01} # Share extern symbols with other modules
bootstrap Crypt::SecretBuffer;


{
   package Crypt::SecretBuffer::Exports;
$Crypt::SecretBuffer::Exports::VERSION = '0.016';
use Exporter 'import';
   @Crypt::SecretBuffer::Exports::EXPORT_OK= qw(
      secret_buffer secret unmask_secrets_to memcmp
      NONBLOCK AT_LEAST ISO8859_1 ASCII UTF8 UTF16LE UTF16BE HEX BASE64
      MATCH_MULTI MATCH_REVERSE MATCH_NEGATE MATCH_ANCHORED
   );
   *NONBLOCK=       *Crypt::SecretBuffer::NONBLOCK;
   *AT_LEAST=       *Crypt::SecretBuffer::AT_LEAST;
   *ISO8859_1=      *Crypt::SecretBuffer::ISO8859_1;
   *ASCII=          *Crypt::SecretBuffer::ASCII;
   *UTF8=           *Crypt::SecretBuffer::UTF8;
   *UTF16LE=        *Crypt::SecretBuffer::UTF16LE;
   *UTF16BE=        *Crypt::SecretBuffer::UTF16BE;
   *HEX=            *Crypt::SecretBuffer::HEX;
   *BASE64=         *Crypt::SecretBuffer::BASE64;
   *MATCH_MULTI=    *Crypt::SecretBuffer::MATCH_MULTI;
   *MATCH_REVERSE=  *Crypt::SecretBuffer::MATCH_REVERSE;
   *MATCH_NEGATE=   *Crypt::SecretBuffer::MATCH_NEGATE;
   *MATCH_ANCHORED= *Crypt::SecretBuffer::MATCH_ANCHORED;
}

sub import {
   splice(@_, 0, 1, 'Crypt::SecretBuffer::Exports');
   goto \&Crypt::SecretBuffer::Exports::import;
}

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
   my ($self, $handle, %options)= @_;
   my $echo_off= Crypt::SecretBuffer::ConsoleState->maybe_new(
      handle => $handle,
      echo => 0,
      auto_restore => 1
   );
   if (defined(my $prompt= delete $options{prompt})) {
      my $prompt_fh= delete $options{prompt_fh} || $handle;
      $prompt_fh->print($prompt);
      $prompt_fh->flush;
   }
   return $self->_append_console_line($handle);
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
   my $blocksize= -s $path;
   while (1) {
      my $got= $self->append_sysread($fh, $blocksize);
      defined $got or croak "sysread($path): $!";
      last if $got == 0;
      # should have read the whole thing first try, but file could be changing, so keep going
      # at 16K intervals until EOF.
      $blocksize= 16*1024 if $blocksize > 16*1024;
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
      $fh= File::Temp->new(DIR => File::Spec->catpath($vol, $dir, ''));
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
  print "Enter your password: ";
  $buf->append_console_line(STDIN)   # read TTY with echo disabled
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
It also guards against timing attacks by copying all the allocated buffer space instead of
just the length that is occupied by the secret.

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

Returns C<$self>, for chaining.  If you want to return the replaced span, use C<substr>.

=head2 assign

  $buf->assign($replacement);

Alias for C<< $buf->splice(0, $buf->length, $replacemenmt) >>.

=head2 append

  $buf->append($data)

Alias for C<< $buf->splice($buf->length, 0, $replacemenmt) >>.

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
requested).  Unlike C<index> or C<rindex>, on failure the return value will be
C<< (C<$ofs> + C<$len>, 0) >>, or with MATCH_REVERSE, C<< (C<$ofs>, 0) >>.
Also unlike C<rindex>, a reverse scan must fall entirely within the range of
C<< ($ofs, $len) >> rather than just starting before C<< $ofs+$len >>.

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
in the same manner as the C function C<memcmp>.  (returns C<< <0 >>, C<0>, or C<< >0 >>)

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

  $bool= $buf->append_console_line($handle);
  $bool= $buf->append_console_line($handle,
    prompt => "Enter Password: ",
    prompt_fh => $alternate_handle,   # optional
  );

This turns off TTY echo (if the handle is a Unix TTY or Windows Console) and reads and appends
characters until newline or EOF (and does not store the \r or \n characters).
It returns true if the read "completed" with a line terminator, or false on EOF, or
C<undef> on any OS error.  Characters may be added to the buffer even when it returns false.
There may also be no characters added when it returns true, if the user just hits <enter>.

When possible, this reads directly from the OS to avoid buffering the secret in libc or Perl,
but reads from the buffer if you already have input data in one of those buffers, or if the
file handle is a virtual Perl handle not backed by the OS.

If you specify a prompt (new in version 0.016), the TTY echo is disabled before printing the
prompt.  This helps prevent a race condition where a scripted interaction could start typing a
password in response to the prompt before the echo was disabled.

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

version 0.016

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
