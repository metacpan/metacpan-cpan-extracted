package Archive::Libarchive::FFI::Callback;

use strict;
use warnings;
use 5.008;

# ABSTRACT: Libarchive callbacks
our $VERSION = '0.0902'; # VERSION

package
  Archive::Libarchive::FFI;

BEGIN {

  if(eval { require FFI::Sweet })
  {
    FFI::Sweet->import;
  }
  else
  {
    require Archive::Libarchive::FFI::SweetLite;
    Archive::Libarchive::FFI::SweetLite->import;
  }
}
use FFI::Util qw( deref_ptr_set _size_t );

use constant {
  CB_DATA        => 0,
  CB_READ        => 1,
  CB_CLOSE       => 2,
  CB_OPEN        => 3,
  CB_WRITE       => 4,
  CB_SKIP        => 5,
  CB_SEEK        => 6,
  CB_SWITCH      => 7,
  CB_BUFFER      => 8,
};

my %callbacks;

do {
  no warnings 'redefine';
  sub _attach_function ($$$;$)
  {
    eval {
      attach_function($_[0], $_[1], $_[2], $_[3]);
    };
    warn $@ if $@ && $ENV{ARCHIVE_LIBARCHIVE_FFI_VERBOSE};
  }
};

my $myopen = FFI::Raw::Callback->new(sub {
  my($archive) = @_;
  my $status = eval {
    $callbacks{$archive}->[CB_OPEN]->($archive, $callbacks{$archive}->[CB_DATA]);
  };
  if($@)
  {
    warn $@;
    return ARCHIVE_FATAL();
  }
  $status;
}, _int, _ptr, _ptr);

my $mywrite = FFI::Raw::Callback->new(sub
{
  my($archive, $null, $ptr, $size) = @_;
  my $buffer = buffer_to_scalar($ptr, $size);
  my $status = eval {
    $callbacks{$archive}->[CB_WRITE]->($archive, $callbacks{$archive}->[CB_DATA], $buffer);
  };
  if($@)
  {
    warn $@;
    return ARCHIVE_FATAL();
  }
  $status;
}, _int, _ptr, _ptr, _ptr, _size_t);

my $myread = FFI::Raw::Callback->new(sub
{
  my($archive, $null, $optr) = @_;
  my($status, $buffer) = eval {
    $callbacks{$archive}->[CB_READ]->($archive, $callbacks{$archive}->[CB_DATA]);
  };
  if($@)
  {
    warn $@;
    return ARCHIVE_FATAL();
  }
  my($ptr, $size) = scalar_to_buffer($buffer);
  deref_ptr_set($optr, $ptr);
  $size;
}, _uint64, _ptr, _ptr, _ptr);

my $myskip = FFI::Raw::Callback->new(sub
{
  my($archive, $null, $request) = @_;
  my $status = eval {
    $callbacks{$archive}->[CB_SKIP]->($archive, $callbacks{$archive}->[CB_DATA], $request);
  };
  if($@)
  {
    warn $@;
    return ARCHIVE_FATAL();
  }
  $status;
}, _uint64, _ptr, _ptr, _uint64);

my $myseek = FFI::Raw::Callback->new(sub
{
  my($archive, $null, $offset, $whence) = @_;
  my $status = eval {
    $callbacks{$archive}->[CB_SEEK]->($archive, $callbacks{$archive}->[CB_DATA], $offset, $whence);
  };
  if($@)
  {
    warn $@;
    return ARCHIVE_FATAL();
  }
  $status;
}, _uint64, _ptr, _ptr, _uint64, _int);

my $myclose = FFI::Raw::Callback->new(sub
{
  my($archive) = @_;
  my $status = eval {
    $callbacks{$archive}->[CB_CLOSE]->($archive, $callbacks{$archive}->[CB_DATA]);
  };
  if($@)
  {
    warn $@;
    return ARCHIVE_FATAL();
  }
  $status;
}, _int, _ptr, _ptr);

_attach_function 'archive_write_open', [ _ptr, _ptr, _ptr, _ptr, _ptr ], _int, sub
{
  my($cb, $archive, $cd, $open, $write, $close) = @_;
  $callbacks{$archive}->[CB_DATA] = $cd;
  if(defined $open)
  {
    $callbacks{$archive}->[CB_OPEN] = $open;
    $open = $myopen;
  }
  if(defined $write)
  {
    $callbacks{$archive}->[CB_WRITE] = $write;
    $write = $mywrite;
  }
  if(defined $close)
  {
    $callbacks{$archive}->[CB_CLOSE] = $close;
    $close = $myclose;
  }
  $cb->($archive, undef, $open||0, $write||0, $close||0);
};

sub archive_read_open ($$$$$)
{
  my($archive, $data, $open, $read, $close) = @_;
  archive_read_open2($archive, $data, $open, $read, undef, $close);
}

_attach_function 'archive_read_open2', [ _ptr, _ptr, _ptr, _ptr, _ptr, _ptr ], _int, sub
{
  my($cb, $archive, $cd, $open, $read, $skip, $close) = @_;
  $callbacks{$archive}->[CB_DATA] = $cd;
  if(defined $open)
  {
    $callbacks{$archive}->[CB_OPEN] = $open;
    $open = $myopen;
  }
  if(defined $read)
  {
    $callbacks{$archive}->[CB_READ] = $read;
    $read = $myread;
  }
  if(defined $skip)
  {
    $callbacks{$archive}->[CB_SKIP] = $skip;
    $skip = $myskip;
  }
  if(defined $close)
  {
    $callbacks{$archive}->[CB_CLOSE] = $close;
    $close = $myclose;
  }
  $cb->($archive, undef, $open||0, $read||0, $skip||0, $close||0);
};

sub archive_read_set_callback_data ($$)
{
  my($archive, $data) = @_;
  $callbacks{$archive}->[CB_DATA] = $data;
  ARCHIVE_OK();
}

foreach my $name (qw( open read skip close seek ))
{
  my $const = 'CB_' . uc $name;
  my $wrapper = eval '# line '. __LINE__ . ' "' . __FILE__ . "\n" . qq{
    sub
    {
      my(\$cb, \$archive, \$callback) = \@_;
      \$callbacks{\$archive}->[$const] = \$callback;
      \$cb->(\$archive, \$my$name);
    }
  };die $@ if $@;

  _attach_function "archive_read_set_$name\_callback", [ _ptr, _ptr ], _int;
}

if(archive_version_number() >= 3000000)
{
  _attach_function 'archive_read_open_memory', [ _ptr, _ptr, _size_t ], _int, sub
  {
    my($cb, $archive, $buffer) = @_;
    my $length = do { use bytes; length $buffer };
    my $ptr = FFI::Raw::MemPtr->new_from_buf($buffer, $length);
    $callbacks{$archive}->[CB_BUFFER] = $ptr;  # TODO: CB_BUFFER or CB_DATA (or something else?)
    $cb->($archive, $ptr, $length);
  };
}
else
{
  sub _archive_read_open_memory_read
  {
    my($archive, $data) = @_;
    if($data->{done})
    {
      return (ARCHIVE_OK(), '');
    }
    else
    {
      $data->{done} = 1;
      return (ARCHIVE_OK(), $data->{buffer});
    }
  }

  *archive_read_open_memory = sub ($$) {
    my($archive, $buffer) = @_;
    my $r = archive_read_open($archive, { buffer => $buffer, done => 0 }, undef, \&_archive_read_open_memory_read, undef);
    unless($r == ARCHIVE_OK())
    {
      warn "error: " . archive_error_string($archive);
    }
    $r;
  };
}

_attach_function archive_version_number() >= 3000000 ? 'archive_read_free' : [ archive_read_finish => 'archive_read_free' ], [ _ptr ], _int, sub
{
  my($cb, $archive) = @_;
  my $ret = $cb->($archive);
  delete $callbacks{$archive};
  $ret;
};

_attach_function archive_version_number() >= 3000000 ? 'archive_write_free' : [ archive_write_finish => 'archive_write_free' ], [ _ptr ], _int, sub
{
  my($cb, $archive) = @_;
  my $ret = $cb->($archive);
  delete $callbacks{$archive};
  $ret;
};

my %lookups;

use constant {
  CB_LOOKUP_USER  => 0,
  CB_LOOKUP_GROUP => 1,
};

my $mylook_write_user_lookup = FFI::Raw::Callback->new(sub {
  my($archive, $name, $id) = @_;
  my($data, $look_cb, $clean_cb) = @{ $lookups{$archive}->[CB_LOOKUP_USER] };
  return $id unless defined $look_cb;
  $look_cb->($data, $name, $id);
}, _int64, _ptr, _str, _int64);

my $mylook_write_group_lookup = FFI::Raw::Callback->new(sub {
  my($archive, $name, $id) = @_;
  my($data, $look_cb, $clean_cb) = @{ $lookups{$archive}->[CB_LOOKUP_GROUP] };
  return $id unless defined $look_cb;
  $look_cb->($data, $name, $id);
}, _int64, _ptr, _str, _int64);

my $mylook_read_user_lookup = FFI::Raw::Callback->new(sub {
  my($archive, $id) = @_;
  my($data, $look_cb, $clean_cb) = @{ $lookups{$archive}->[CB_LOOKUP_USER] };
  return undef unless defined $look_cb;
  my $name = $look_cb->($data, $id);
  return $name if defined $name;
  return;
}, _str, _ptr, _int64);

my $mylook_read_group_lookup = FFI::Raw::Callback->new(sub {
  my($archive, $id) = @_;
  my($data, $look_cb, $clean_cb) = @{ $lookups{$archive}->[CB_LOOKUP_GROUP] };
  return undef unless defined $look_cb;
  my $name = $look_cb->($data, $id);
  return $name if defined $name;
  return;
}, _str, _ptr, _int64);

my $mylook_user_cleanup = FFI::Raw::Callback->new(sub {
  my($archive) = @_;
  my($data, $look_cb, $clean_cb) = @{ $lookups{$archive}->[CB_LOOKUP_USER] };
  $clean_cb->($data) if defined $clean_cb;
  delete $lookups{$archive};
}, _void, _ptr);

my $mylook_group_cleanup = FFI::Raw::Callback->new(sub {
  my($archive) = @_;
  my($data, $look_cb, $clean_cb) = @{ $lookups{$archive}->[CB_LOOKUP_GROUP] };
  $clean_cb->($data) if defined $clean_cb;
  delete $lookups{$archive};
}, _void, _ptr);

_attach_function 'archive_write_disk_set_user_lookup', [ _ptr, _ptr, _ptr, _ptr ], _int, sub
{
  my($cb, $archive, $data, $look_cb, $clean_cb) = @_;
  if(defined $look_cb || defined $clean_cb)
  {
    $lookups{$archive}->[CB_LOOKUP_USER] = [ $data, $look_cb, $clean_cb ];
    return $cb->($archive, $archive, $mylook_write_user_lookup, $mylook_user_cleanup);
  }
  return $cb->($archive, undef, undef, undef);
};

_attach_function 'archive_write_disk_set_group_lookup', [ _ptr, _ptr, _ptr, _ptr ], _int, sub
{
  my($cb, $archive, $data, $look_cb, $clean_cb) = @_;
  if(defined $look_cb || defined $clean_cb)
  {
    $lookups{$archive}->[CB_LOOKUP_GROUP] = [ $data, $look_cb, $clean_cb ];
    return $cb->($archive, $archive, $mylook_write_group_lookup, $mylook_group_cleanup);
  }
  return $cb->($archive, undef, undef, undef);
};

_attach_function 'archive_read_disk_set_uname_lookup', [ _ptr, _ptr, _ptr, _ptr ], _int, sub
{
  my($cb, $archive, $data, $look_cb, $clean_cb) = @_;
  if(defined $look_cb || defined $clean_cb)
  {
    $lookups{$archive}->[CB_LOOKUP_USER] = [ $data, $look_cb, $clean_cb ];
    return $cb->($archive, $archive, $mylook_read_user_lookup, $mylook_user_cleanup);
  }
  return $cb->($archive, undef, undef, undef);
};

_attach_function 'archive_read_disk_set_gname_lookup', [ _ptr, _ptr, _ptr, _ptr ], _int, sub
{
  my($cb, $archive, $data, $look_cb, $clean_cb) = @_;
  if(defined $look_cb || defined $clean_cb)
  {
    $lookups{$archive}->[CB_LOOKUP_GROUP] = [ $data, $look_cb, $clean_cb ];
    return $cb->($archive, $archive, $mylook_read_group_lookup, $mylook_group_cleanup);
  }
  return $cb->($archive, undef, undef, undef);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::Libarchive::FFI::Callback - Libarchive callbacks

=head1 VERSION

version 0.0902

=head1 SYNOPSIS

 use Archive::Libarchive::FFI qw( :all );
 
 # read
 my $archive = archive_read_new();
 archive_read_open($archive, $data, \&myopen, \&myread, \&myclose);
 
 # write
 my $archive = archive_write_new();
 archive_write_open($archive, $data, \&myopen, \&mywrite, \&myclose);

=head1 DESCRIPTION

This document provides information of callback routines for writing
custom input/output interfaces to the libarchive perl bindings.  The
first two arguments passed into all callbacks are:

=over 4

=item $archive

The archive object (actually a pointer to the C structure that managed
the archive object).

=item $data

The callback data object (any legal Perl data structure).

=back

For the variable name / types conventions used in this document, see
L<Archive::Libarchive::FFI::Function>.

The expected return value for all callbacks EXCEPT the read callback
is a standard integer libarchive status value (example: C<ARCHIVE_OK>
or C<ARCHIVE_FATAL>).

If your callback dies (throws an exception), it will be caught at the
Perl level.  The error will be sent to standard error via L<warn|perlfunc#warn>
and C<ARCHIVE_FATAL> will be passed back to libarchive.

=head2 data

There is a data field for callbacks associated with each $archive object.
It can be any native Perl type (example: scalar, hashref, coderef, etc).
You can set this by calling
L<archive_read_set_callback_data|Archive::Libarchive::FFI::Function#archive_read_set_callback_data>,
or by passing the data argument when you "open" the archive using
L<archive_read_open|Archive::Libarchive::FFI::Function#archive_read_open>,
L<archive_read_open2|Archive::Libarchive::FFI::Function#archive_read_open2> or
L<archive_write_open|Archive::Libarchive::FFI::Function#archive_write_open>.

The data field will be passed into each callback as its second argument.

=head2 open

 my $status1 = archive_read_set_open_callback($archive, sub {
   my($archive, $data) = @_;
   ...
   return $status2;
 });

According to the libarchive, this is never needed, but you can register
a callback to happen when you open.

Can also be set when you call
L<archive_read_open|Archive::Libarchive::FFI::Function#archive_read_open>,
L<archive_read_open2|Archive::Libarchive::FFI::Function#archive_read_open2> or
L<archive_write_open|Archive::Libarchive::FFI::Function#archive_write_open>.

=head2 read

 my $status1 = archive_read_set_read_callback($archive, sub {
   my($archive, $data) = @_;
   ...
   return ($status2, $buffer)
 });

This callback is called whenever libarchive is ready for more data to
process.  It doesn't take in any additional arguments, but it expects
two return values, a status and a buffer containing the data.

Can also be set when you call
L<archive_read_open|Archive::Libarchive::FFI::Function#archive_read_open> or
L<archive_read_open2|Archive::Libarchive::FFI::Function#archive_read_open2>.

=head2 write

 my $mywrite = sub {
   my($archive, $data, $buffer) = @_;
   ...
   return $bytes_written_or_status;
 };
 my $status2 = archive_write_open($archive, undef, $mywrite, undef);

This callback is called whenever libarchive has data it wants to send
to output.  The callback itself takes one additional argument, a
buffer containing the data to write.

It should return the actual number of bytes written by you, or an
status value for an error.

=head2 skip

 my $status1 = archive_read_set_skip_callback($archive, sub {
   my($archive, $data, $request) = @_;
   ...
   return $status2;
 });

The skip callback takes one additional argument, $request.

Can also be set when you call
L<archive_read_open2|Archive::Libarchive::FFI::Function#archive_read_open2>.

=head2 seek

 my $status1 = archive_read_set_seek_callback($archive, sub {
   my($archive, $data, $offset, $whence) = @_;
   ...
   return $status2;
 });

The seek callback should implement an interface identical to the UNIX
C<fseek> function.

=head2 close

 my $status1 = archive_read_set_close_callback($archive, sub {
   my($archive, $data) = @_;
   ...
   return $status2;
 });

Called when the archive (either input or output) should be closed.

Can also be set when you call
L<archive_read_open|Archive::Libarchive::FFI::Function#archive_read_open>,
L<archive_read_open2|Archive::Libarchive::FFI::Function#archive_read_open2> or
L<archive_write_open|Archive::Libarchive::FFI::Function#archive_write_open>.

=head2 user id lookup

 my $status = archive_write_disk_set_user_lookup($archive, $data, sub {
   my($data, $name, $uid) = @_;
   ... # should return the UID for $name or $uid if it can't be found
 }, undef);

Called by archive_write_disk_uid to determine appropriate UID.

=head2 group id lookup

 my $status = archive_write_disk_set_group_lookup($archive, $data, sub {
   my($data, $name, $gid) = @_;
   ... # should return the GID for $name or $gid if it can't be found
 }, undef);

Called by archive_write_disk_gid to determine appropriate GID.

=head2 user name lookup

 my $status = archive_read_disk_set_uname_lookup($archive, $data, sub
   my($data, $uid) = @_;
   ... # should return the name for $uid, or undef
 }, undef);

Called by archive_read_disk_uname to determine appropriate user name.

=head2 group name lookup

 my $status = archive_read_disk_set_gname_lookup($archive, $data, sub
   my($data, $gid) = @_;
   ... # should return the name for $gid, or undef
 }, undef);

Called by archive_read_disk_gname to determine appropriate group name.

=head2 lookup cleanup

 sub mycleanup
 {
   my($data) = @_;
   ... # any cleanup necessary
 }
 
 my $status = archive_write_disk_set_user_lookup($archive, $data, \&mylookup, \&mcleanup);
 
 ...
 
 archive_write_disk_set_user_lookup($archive, undef, undef, undef); # mycleanup will be called here

Called when the lookup is registered (can also be passed into
L<archive_write_disk_set_group_lookup|Archive::Libarchive::FFI::Function#archive_write_disk_set_group_lookup>,
L<archive_read_disk_set_uname_lookup|Archive::Libarchive::FFI::Function#archive_read_disk_set_uname_lookup>,
and
L<archive_read_disk_set_gname_lookup|Archive::Libarchive::FFI::Function#archive_read_disk_set_gname_lookup>.

=head1 SEE ALSO

=over 4

=item L<Archive::Libarchive::FFI>

=item L<Archive::Libarchive::FFI::Constant>

=item L<Archive::Libarchive::FFI::Function>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
