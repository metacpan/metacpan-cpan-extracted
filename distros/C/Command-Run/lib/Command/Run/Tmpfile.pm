package Command::Run::Tmpfile;

use v5.14;
use warnings;
use utf8;
use Carp;
use Fcntl;
use IO::File;
use IO::Handle;

my $fdpath;

sub new {
    my $class = shift;
    my $fh = new_tmpfile IO::File or die "new_tmpfile: $!\n";
    $fh->fcntl(F_SETFD, 0) or die "fcntl F_SETFD: $!\n";
    binmode $fh, ':encoding(utf8)';
    # Determine usable fd-path on first instantiation, using the fd we
    # just allocated.  Checking only "$path/0" is insufficient on
    # FreeBSD where /dev/fd/0,1,2 always exist as device nodes but
    # /dev/fd/N (N>2) requires fdescfs to be mounted.
    $fdpath //= do {
	my $fd = $fh->fileno;
	my $found;
	for my $path (qw(/proc/self/fd /dev/fd)) {
	    -r "$path/$fd" and do { $found = $path; last };
	}
	$found // '';
    };
    bless { FH => $fh }, $class;
}

sub write {
    my $obj = shift;
    my $fh = $obj->fh;
    if (@_) {
	my $data = join '', @_;
	$fh->print($data);
    }
    $obj;
}

sub flush {
    my $obj = shift;
    $obj->fh->flush;
    $obj;
}

sub rewind {
    my $obj = shift;
    $obj->fh->seek(0, 0) or die "seek: $!\n";
    $obj;
}

sub reset {
    my $obj = shift;
    $obj->rewind;
    $obj->fh->truncate(0);
    $obj;
}

sub fh {
    my $obj = shift;
    $obj->{FH};
}

sub fd {
    my $obj = shift;
    $obj->fh->fileno;
}

sub path {
    my $obj = shift;
    return undef unless $fdpath;
    sprintf "%s/%d", $fdpath, $obj->fd;
}

1;

__END__

=encoding utf-8

=head1 NAME

Command::Run::Tmpfile - Temporary file with /dev/fd path access

=head1 SYNOPSIS

    use Command::Run::Tmpfile;

    my $tmp = Command::Run::Tmpfile->new;
    $tmp->write("some data")->flush;

    # Pass to external command as file argument
    system("cat", $tmp->path);  # /dev/fd/N

    # Read back
    $tmp->rewind;
    my $data = do { local $/; my $fh = $tmp->fh; <$fh> };

=head1 DESCRIPTION

This module provides an anonymous temporary file that can be accessed
via C</dev/fd/N> or C</proc/self/fd/N> path.  The file is
automatically deleted when the object is destroyed.

This is useful when you need to pass data to external commands that
require file arguments rather than stdin.

=head1 METHODS

=over 4

=item B<new>()

Create a new temporary file object.

=item B<write>(I<@data>)

Write data to the temporary file.
Returns the object for method chaining.

=item B<flush>()

Flush the file buffer.
Returns the object for method chaining.

=item B<rewind>()

Seek to the beginning of the file.
Returns the object for method chaining.

=item B<reset>()

Rewind and truncate the file (clear contents).
Returns the object for method chaining.

=item B<fh>()

Return the underlying file handle.

=item B<fd>()

Return the file descriptor number.

=item B<path>()

Return the file descriptor path (e.g., C</dev/fd/3>).
On the first call to C<new>, the module probes for a usable file
descriptor path by checking C</proc/self/fd/N> and C</dev/fd/N> for
the just-allocated fd.  If neither is available (for example on
FreeBSD without C<fdescfs> mounted), C<path> returns C<undef>.

=back

=head1 SEE ALSO

L<Command::Run>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
