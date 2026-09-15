use v5.36;
package Archive::Asar 0.01;
use Carp qw(croak);
use Fcntl qw(SEEK_SET SEEK_END);
use JSON::PP ();

use constant {
    _JSON     =>
        do { local $@; eval { require Cpanel::JSON::XS } }
            ? 'Cpanel::JSON::XS'
            : 'JSON::PP'
};

sub new_from_file($class, $file) {
    open my $fh, '<', $file or croak "Can't open $file for reading: $!";
    $class->new_from_fh($file, $fh)
}

sub new_from_string($class, $data) {
    utf8::downgrade $data;
    open my $fh, '<', \$data or die "Can't open scalar as a file: $!";
    $class->new_from_fh('(buffer)', $fh)
}

sub _xread($self, $n) {
    my $buf = '';
    while (length($buf) < $n) {
        my $r = $self->{_fh}->read($buf, $n - length($buf), length($buf)) // croak "Can't read from $self->{_name}: $!";
        $r > 0 or croak "Bad ASAR file: Unexpected EOF while reading $n bytes from $self->{_name}";
    }
    $buf
}

sub new_from_fh($class, $name, $fh) {
    $fh->binmode;

    $fh->seek(0, SEEK_END) or croak "Can't seek to end of $name: $!";
    my $size = $fh->tell;
    $size >= 0 or croak "Can't tell size of $name: $!";
    $fh->seek(0, SEEK_SET) or croak "Can't seek to start of $name: $!";

    my $self = bless {
        _fh   => $fh,
        _name => $name,
        _size => $size,
    }, $class;

    my @header = unpack 'V4', $self->_xread(16);
    $header[0] == 4
    && $header[1] == $header[2] + 4
    && $header[2] == $header[3] + (-$header[3] % 4) + 4
        or croak "Bad ASAR file: Unrecognized header (@header) in $name";

    my $index_end = $header[2] + 12;
    $index_end <= $size or croak "Bad ASAR file: Truncated index (got " . ($size - 8) . ", want $header[1]) in $name";
    my $index_json = $self->_xread($header[2] - 4);
    while (length($index_json) > $header[3]) {
        chop $index_json;
    }

    my $index = _JSON->new->utf8->decode($index_json);

    $self->{_index}      = $index;
    $self->{_blob_start} = $index_end;

    $self
}

sub index_raw($self) {
    $self->{_index}
}

sub get_entry($self, $path) {
    my sub _json_type_name($x) {
        !defined $x ? 'null' :
        JSON::PP::is_bool($x) ? ($x ? 'true' : 'false') :
        ref($x) eq 'ARRAY' ? 'array' :
        ref($x) eq 'HASH' ? 'object' :
        do { no warnings qw(experimental::builtin); builtin::created_as_number $x } ? 'number' :
        'string'
    }

    my sub _assert_hashref($x, $path) {
        ref $x eq 'HASH'
            or croak "Bad ASAR file: Malformed index at $path (got " . _json_type_name($x) . ", want object) in $self->{_name}";
    }

    unless (ref $path) {
        $path = [split m{[/\\]}, $path, -1];
    }

    my $node = $self->index_raw;
    my $traversed_path = '';
    my $display_path = '(root)';
    for my $p (@$path) {
        _assert_hashref $node, $display_path;
        exists $node->{files} or croak "Can't access [${\join '/', @$path}] in $self->{_name}: $display_path is not a directory";
        $traversed_path .= (length $traversed_path ? '/' : '') . $p;
        $display_path = $traversed_path;
        _assert_hashref my $files = $node->{files}, "$display_path:files";
        exists $files->{$p} or croak "Can't access [${\join '/', @$path}] in $self->{_name}: $display_path does not exist";
        $node = $files->{$p};
    }
    _assert_hashref $node, $display_path;

    if (exists $node->{link}) {
        my $target = $node->{link};
        defined $target && !ref $target
            or croak "Bad ASAR file: Malformed index at $display_path:link (got " . _json_type_name($target) . ", want string) in $self->{_name}";
        return { type => 'link', target => $target, $node->%{grep exists $node->{$_}, qw<unpacked>} };
    }

    if (exists $node->{files}) {
        _assert_hashref my $files = $node->{files}, "$display_path:files";
        my @entries = sort keys %$files;
        return { type => 'directory', entries => \@entries, $node->%{grep exists $node->{$_}, qw<unpacked>} };
    }

    exists $node->{size}
        or croak "Bad ASAR file: Malformed index at $display_path (missing size) in $self->{_name}";
    my $size = $node->{size};
    !ref($size) && $size =~ /\A\d+\z/a
        or croak "Bad ASAR file: Malformed index at $display_path:size (got " . _json_type_name($size) . ", want integer) in $self->{_name}";

    if ($node->{unpacked}) {
        return { type => 'file', unpacked => $node->{unpacked}, $node->%{grep exists $node->{$_}, qw<integrity executable>} };
    }

    exists $node->{offset}
        or croak "Bad ASAR file: Malformed index at $display_path (missing offset) in $self->{_name}";
    my $offset = $node->{offset};
    !ref($offset) && $offset =~ /\A\d+\z/a
        or croak "Bad ASAR file: Malformed index at $display_path:offset (got " . _json_type_name($offset) . ", want integer) in $self->{_name}";

    my $offset_abs = $self->{_blob_start} + $offset;
    $offset_abs + $size <= $self->{_size}
        or croak "Bad ASAR file: Truncated file data (got $self->{_size}, want " . ($offset_abs + $size) . ") in $self->{_name}";

    $self->{_fh}->seek($offset_abs, SEEK_SET) or croak "Can't seek to $offset_abs in $self->{_name}: $!";
    my $contents = $self->_xread($size);
    return { type => 'file', contents => $contents, $node->%{grep exists $node->{$_}, qw<integrity executable>} };
}


sub extract_to($self, $target_dir, $options = {}) {
    length $target_dir or croak "Target directory name cannot be empty";

    my $unpacked_dir = $options->{unpacked_dir};

    local $\;

    my @queue = [];

    ENTRY: while (@queue) {
        my $path = shift @queue;
        my $entry = $self->get_entry($path);

        my $output = join '/', $target_dir, @$path;
        if ($entry->{type} eq 'directory') {
            mkdir $output or $!{EEXIST}
                or croak "Can't mkdir $output: $!";
            for my $name ($entry->{entries}->@*) {
                if ($name =~ m{\A\.{0,2}\z} || $name =~ m{[/\\\0]}) {
                    croak 'Cowardly refusing to extract suspicious ' . join('/', @$path) . ' entry "' . $name =~ s/([\\"])/\\$1/gr =~ s/\0/\\x00/gr . '"';
                }
                push @queue, [@$path, $name];
            }
        } elsif ($entry->{type} eq 'link') {
            my $target = $entry->{target};
            if ($target eq '' || $target =~ m{\A[/\\]} || $target =~ /\0/) {
                croak "Cowardly refusing to extract ${\join '/', @$path} link to $target";
            }
            my @abs_path = @$path;
            my @parts = split m{[/\\]+}, $target;
            my $synthetic_target = join '/', @parts;
            while (@parts && $parts[0] eq '..') {
                @abs_path or croak "Cowardly refusing to extract ${\join '/', @$path} link to $target";
                pop @abs_path;
            }
            for my $part (@parts) {
                if ($part eq '.' || $part eq '..') {
                    croak "Cowardly refusing to extract ${\join '/', @$path} link to $target";
                }
                push @abs_path, $part;
            }
            symlink $synthetic_target, $output or croak "Can't symlink $output to $synthetic_target: $!";
        } elsif ($entry->{type} eq 'file') {
            my $contents;
            if ($entry->{unpacked}) {
                defined $unpacked_dir or next ENTRY;
                my $infile = join '/', $unpacked_dir, @$path;
                open my $in_fh, '<', $infile or croak "Can't open unpacked file $infile for reading: $!";
                binmode $in_fh;
                local $/;
                $contents = readline $in_fh;
            } else {
                $contents = $entry->{contents};
            }
            open my $fh, '>', $output or croak "Can't open $output for writing: $!";
            binmode $fh;
            print $fh $entry->{contents} and close $fh or croak "Can't write $output: $!";
            if ($entry->{executable}) {
                chmod 0755, $output or croak "Can't make $output executable: $!";
            }
        } else {
            croak "Internal error: unhandled entry type '$entry->{type}'";
        }
    }
}

'ok'
__END__

=encoding utf-8

=head1 NAME

Archive::Asar - list and extract Electron ASAR (Atom Shell Archive) files

=head1 SYNOPSIS

=for highlighter language=perl

    use Archive::Asar;

    my $asar = Archive::Asar->new_from_file('app.asar');
    # or
    my $asar = Archive::Asar->new_from_string($blob);
    # or
    my $asar = Archive::Asar->new_from_fh('(stdin)', \*STDIN);

    my $index_structure = $asar->index_raw;

    my $info = $asar->get_entry('file/foo.txt');

    $asar->extract_to($target_directory);

=head1 DESCRIPTION

Archive::Asar provides an object-oriented interface for handling Electron
F<.asar> files ("Atom Shell Archive").

=head2 Constructors

=over

=item new_from_fh

Usage: C<< my $asar = Archive::Asar->new_from_fh($name, $handle); >>

C<$name> is the name of the archive (used in error messages). C<$handle> is the
filehandle to read from (must be seekable, i.e. not a pipe, terminal, socket,
etc).

C<$handle> need not be a built-in Perl filehandle; it can be any object that
responds to the required methods C<binmode>, C<seek>, C<tell>, and C<read>. 

Returns the initialized object or throws an exception on error.

=item new_from_file

Usage: C<< my $asar = Archive::Asar->new_from_file($file); >>

Like L</new_from_fh>, but opens C<$file> first (and automatically uses C<$file>
as the name of the archive in error messages).

=item new_from_string

Usage: C<< my $asar = Archive::Asar->new_from_string($blob); >>

Like L</new_from_fh>, but reads the archive data directly from a scalar, not a
filehandle.

=back

=head2 Methods

=over

=item index_raw

Usage: C<< my $index = $asar->index_raw; >>

Returns the parsed index data structure stored as JSON in the ASAR file.

The returned data structure must not be modified.

=item get_entry

Usage: C<< my $entry = $asar->get_entry($path); >>

Returns information about the archive member stored at C<$path>.

C<$path> is either a reference to an array of path components (e.g. C<['foo',
'bar', 'hello.txt']>) or a string with path components separated by C</> (e.g.
C<'foo/bar/hello.txt'>) or (for Windows compatibility) by C<\> (e.g.
C<'foo\\bar\\hello.txt'>).

Use an empty path (C<[]> or C<''>) to get information about the root level of
the archive, which should be of type C<directory>.

If the specified path doesn't exist or anything else goes wrong, an exception
is thrown.

The return value is a hash reference with a C<type> field. There are three
possible types:

=over

=item directory

C<< { type => 'directory', entries => [...], unpacked? => true } >>

An entry of type C<directory> has an C<entries> field (an arrayref of strings)
listing the entries in that directory. It may also have an C<unpacked> field
(normally set to C<true> if present).

=item link

C<< { type => 'link', target => '...', unpacked? => true } >>

An entry of type C<link> has a C<target> field (a string) specifying the target
of the symbolic link.

I<Beware:> The C<target> field is not validated! It may be any string provided
by the archive. It may refer to a file outside of the archive or it may not be
a valid filename at all.

=item file

C<< { type => 'file', unpacked => true } >>

C<< { type => 'file', contents => '...', executable? => true, integrity? => {...} } >>

An entry of type C<file> has either a true C<unpacked> field, indicating that
the file is stored externally (outside of the packed archive), or a C<contents>
field giving the contents of the file as a string.

In the latter case, it may also have an C<executable> field, which (if true)
indicates that the file is executable, and/or an C<integrity> field, which
contains checksum information in the following format:

    {
        algorithm => 'SHA256',
        hash      => '...', # lowercase hex
        blockSize => ...,
        blocks    => [...],
    }

C<algorithm> is the hashing algorithm to use (currently always C<SHA256>; see
L<Digest::SHA>). C<hash> is the result of hashing the file contents (in
lowercase hex format, two hex digits per byte).

C<blockSize> is an integer. The C<blocks> field is an array of the results of
splitting the file contents into chunks of (at most) C<blockSize> bytes and
hashing each chunk separately, in the same format as C<hash>.

For example, an empty file may appear as:

    {
        type      => 'file',
        contents  => '',
        integrity => {
            algorithm => 'SHA256',
            hash      => 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
            blockSize => 0x400000,
            blocks    => ['e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'],
        },
    }

=back

=item extract_to

Usage: C<< $asar->extract_to($target_directory, $options = {}); >>

Extracts the contents of the archive into the given C<$target_directory>, which
is automatically created if it doesn't exist yet.

The C<$options> argument is optional, but must be a hash reference if given.
Currently only one option is supported:

=over

=item unpacked_dir

If C<unpacked_dir> is set to a defined value, files marked C<unpacked> in the
archive will be read from this directory (and copied to C<$target_directory>).

Otherwise C<unpacked> files will be skipped when extracting.

=back

=back

=head1 BUGS AND LIMITATIONS

=over

=item *

Creating and modifying archives is not supported.

=item *

Support for "unpacked" archive members is rudimentary.

=item *

Tests are incomplete.

=back

=begin :README

=head1 INSTALLATION

To install this module, run the following commands:

=for highlighter language=sh

    perl Makefile.PL
    make
    make test
    make install

=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Archive::Asar

You can also look for information at:

=over

=item *

MetaCPAN: L<https://metacpan.org/pod/Archive::Asar>

=item *

The source repository on Codeberg:
L<https://codeberg.org/mauke/Archive-Asar>

=item *

The module's bug tracker: L<https://codeberg.org/mauke/Archive-Asar/issues>

=back

=end :README

=head1 AUTHOR

Lukas Mai, C<< <lmai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2026 Lukas Mai.

This module is free software: you can redistribute it and/or modify it under
the terms of the L<GNU General Public License|https://www.gnu.org/licenses/gpl-3.0.html>
as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
