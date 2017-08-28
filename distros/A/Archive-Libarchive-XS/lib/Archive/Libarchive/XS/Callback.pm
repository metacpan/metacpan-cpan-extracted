package Archive::Libarchive::XS::Callback;

use strict;
use warnings;

# ABSTRACT: libarchive callback functions
our $VERSION = '0.0902'; # VERSION


package
  Archive::Libarchive::XS;

use constant {
  CB_DATA        => 0,
  CB_READ        => 1,
  CB_CLOSE       => 2,
  CB_OPEN        => 3,
  CB_WRITE       => 4,
  CB_SKIP        => 5,
  CB_SEEK        => 6,
  CB_BUFFER      => 7,
};
    
my %callbacks;

sub ARCHIVE_FATAL ();
sub ARCHIVE_OK    ();

sub archive_read_set_callback_data ($$)
{
  my($archive, $data) = @_;
  $callbacks{$archive}->[CB_DATA] = $data;
  ARCHIVE_OK;
}

foreach my $name (qw( open read skip close seek ))
{
  my $const = 'CB_' . uc $name;
  eval '# line '. __LINE__ . ' "' . __FILE__ . "\n" . qq{
    sub archive_read_set_$name\_callback (\$\$)
    {
      my(\$archive, \$callback) = \@_;
      \$callbacks{\$archive}->[$const] = \$callback;
      _archive_read_set_$name\_callback(\$archive, \$callback);
    }
  }; die $@ if $@;
}

foreach my $name (qw( open skip close seek ))
{
  my $uc_name = uc $name;
  eval '# line '. __LINE__ . ' "' . __FILE__ . "\n" . qq{
    sub _my$name
    {
      my \$archive = shift;
      my \$status = eval { \$callbacks{\$archive}->[CB_$uc_name]->(\$archive, \$callbacks{\$archive}->[CB_DATA],\@_) };
      if(\$\@)
      {
        warn \$\@;
        return ARCHIVE_FATAL;
      }
      \$status;
    }
  }; die $@ if $@;
}

sub _myread
{
  my($archive) = @_;
  my ($status, $buffer) = eval {
    $callbacks{$archive}->[CB_READ]->(
      $archive, 
      $callbacks{$archive}->[CB_DATA],
    )
  };
  if($@)
  {
    warn $@;
    return (ARCHIVE_FATAL, undef);
  }
  $callbacks{$archive}->[CB_BUFFER] = \$buffer;
  ($status, $callbacks{$archive}->[CB_BUFFER]);
}

sub _mywrite
{
  my($archive, $buffer) = @_;
  my $status = eval {
    $callbacks{$archive}->[CB_WRITE]->(
      $archive, 
      $callbacks{$archive}->[CB_DATA],
      $buffer,
    )
  };
  if($@)
  {
    warn $@;
    return ARCHIVE_FATAL;
  }
  $status;
}

sub archive_read_open ($$$$$)
{
  my($archive, $data, $opencb, $readcb, $closecb) = @_;
  $callbacks{$archive}->[CB_DATA]  = $data    if defined $data;
  $callbacks{$archive}->[CB_OPEN]  = $opencb  if defined $opencb;
  $callbacks{$archive}->[CB_READ]  = $readcb  if defined $readcb;
  $callbacks{$archive}->[CB_CLOSE] = $closecb if defined $closecb;
  my $ret = _archive_read_open($archive, $data, $opencb, $readcb, $closecb);
  $ret;
}

sub archive_read_open2 ($$$$$$)
{
  my($archive, $data, $opencb, $readcb, $skipcb, $closecb) = @_;
  $callbacks{$archive}->[CB_DATA]  = $data    if defined $data;
  $callbacks{$archive}->[CB_OPEN]  = $opencb  if defined $opencb;
  $callbacks{$archive}->[CB_READ]  = $readcb  if defined $readcb;
  $callbacks{$archive}->[CB_SKIP]  = $skipcb  if defined $skipcb;
  $callbacks{$archive}->[CB_CLOSE] = $closecb if defined $closecb;
  my $ret = _archive_read_open2($archive, $data, $opencb, $readcb, $skipcb, $closecb);
  $ret;
}

sub archive_write_open ($$$$$)
{
  my($archive, $data, $opencb, $writecb, $closecb) = @_;
  $callbacks{$archive}->[CB_DATA]  = $data    if defined $data;
  $callbacks{$archive}->[CB_OPEN]  = $opencb  if defined $opencb;
  $callbacks{$archive}->[CB_WRITE] = $writecb if defined $writecb;
  $callbacks{$archive}->[CB_CLOSE] = $closecb if defined $closecb;
  my $ret = _archive_write_open($archive, $data, $opencb, $writecb, $closecb);
  $ret;
}

sub archive_read_free ($)
{
  my($archive) = @_;
  my $ret = _archive_read_free($archive);
  delete $callbacks{$archive};
  $ret;
}

sub archive_write_free ($)
{
  my($archive) = @_;
  my $ret = _archive_write_free($archive);
  delete $callbacks{$archive};
  $ret;
}

sub archive_set_error
{
  my($archive, $errno, $format, @args) = @_;
  my $string = sprintf $format, @args;
  _archive_set_error($archive, $errno, $string);
}

sub archive_read_disk_entry_from_file ($$$$)
{
  my($archive, $entry, $fh, $stat) = @_;
  my $fd = fileno $fh;
  $fd = -1 unless defined $fd;
  _archive_read_disk_entry_from_file($archive, $entry, $fd, $stat);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::Libarchive::XS::Callback - libarchive callback functions

=head1 VERSION

version 0.0902

=head1 SYNOPSIS

 use Archive::Libarchive::XS qw( :all );
 
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
L<Archive::Libarchive::XS::Function>.

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
L<archive_read_set_callback_data|Archive::Libarchive::XS::Function#archive_read_set_callback_data>,
or by passing the data argument when you "open" the archive using
L<archive_read_open|Archive::Libarchive::XS::Function#archive_read_open>,
L<archive_read_open2|Archive::Libarchive::XS::Function#archive_read_open2> or
L<archive_write_open|Archive::Libarchive::XS::Function#archive_write_open>.

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
L<archive_read_open|Archive::Libarchive::XS::Function#archive_read_open>,
L<archive_read_open2|Archive::Libarchive::XS::Function#archive_read_open2> or
L<archive_write_open|Archive::Libarchive::XS::Function#archive_write_open>.

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
L<archive_read_open|Archive::Libarchive::XS::Function#archive_read_open> or
L<archive_read_open2|Archive::Libarchive::XS::Function#archive_read_open2>.

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
L<archive_read_open2|Archive::Libarchive::XS::Function#archive_read_open2>.

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
L<archive_read_open|Archive::Libarchive::XS::Function#archive_read_open>,
L<archive_read_open2|Archive::Libarchive::XS::Function#archive_read_open2> or
L<archive_write_open|Archive::Libarchive::XS::Function#archive_write_open>.

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
L<archive_write_disk_set_group_lookup|Archive::Libarchive::XS::Function#archive_write_disk_set_group_lookup>,
L<archive_read_disk_set_uname_lookup|Archive::Libarchive::XS::Function#archive_read_disk_set_uname_lookup>,
and
L<archive_read_disk_set_gname_lookup|Archive::Libarchive::XS::Function#archive_read_disk_set_gname_lookup>.

=head1 SEE ALSO

=over 4

=item L<Archive::Libarchive::XS>

=item L<Archive::Libarchive::XS::Constant>

=item L<Archive::Libarchive::XS::Function>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
