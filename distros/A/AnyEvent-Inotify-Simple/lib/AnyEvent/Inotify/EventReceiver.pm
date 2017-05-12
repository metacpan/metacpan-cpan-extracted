package AnyEvent::Inotify::EventReceiver;
$AnyEvent::Inotify::EventReceiver::VERSION = '0.03';
use Moose::Role;

requires 'handle_access';
requires 'handle_modify';
requires 'handle_attribute_change';
requires 'handle_close';
requires 'handle_open';
requires 'handle_move';
requires 'handle_delete';
requires 'handle_create';

sub handle_close_write  {
    my ($self, $f) = @_;
    $self->handle_close($f);
}

sub handle_close_nowrite  {
    my ($self, $f) = @_;
    $self->handle_close($f);
}

# requires 'handle_close_write';
# requires 'handle_close_nowrite';

1;

__END__

=head1 NAME

AnyEvent::Inotify::EventReceiver - interface of event-receiving classes

=head1 VERSION

version 0.03

=head1 METHODS

Event receivers must implement these methods.  All files and
directories passed to these methods are actually
L<Path::Class|Path::Class> objects.  The paths provided are always
relative to the directory that was given to the constructor of the
C<AnyEvent::Inotify::Simple> object.

Note: "file" below means "file or directory" where that makes sense.

=head2 handle_create

Called when a new file, C<$file>, appears in the watched directory.
If it's a directory, we automatically start watching it and calling
callbacks for files in that directory, still relative to the original
directory. C<IN_CREATE>.

=head2 handle_access($file)

Called when C<$file> is accessed. C<IN_ACCESS>.

=head2 handle_modify($file)

Called when C<$file> is modified. C<IN_MODIFY>.

=head2 handle_attribute_change($file)

Called when metadata like permissions, timestamps,
extended attributes, link count (since Linux 2.6.25), UID, GID,
and so on, changes on C<$file>. C<IN_ATTRIB>.

=head2 handle_open($file)

Called when something opens C<$file>. C<IN_OPEN>.

=head2 handle_close($file)

Called when something closes C<$file>. C<IN_CLOSE_WRITE> and
C<IN_CLOSE_NOWRITE>.

=head2 handle_close_write($file)

C<IN_CLOSE_WRITE> only.  By default, just calls C<handle_close>, but
you can override this method and handle it separately.

=head2 handle_close_nowrite($file)

C<IN_CLOSE_NOWRITE> only.  By default, just calls C<handle_close>, but
you can override this method and handle it separately.

=head2 handle_move($from, $to)

Called when C<$from> is moved to C<$to>.  (This does not map to a
single inotify event; we wait for both the C<IN_MOVED_FROM> and
C<IN_MOVED_TO> events, and call this when we have both.)

=head2 handle_delete($file)

Called when C<$file> is deleted.  C<IN_DELETE>.  (Never called for
C<IN_DELETE_SELF>, however.)
