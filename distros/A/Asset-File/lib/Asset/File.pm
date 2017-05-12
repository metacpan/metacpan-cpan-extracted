package Asset::File;
use Moo;
use Carp 'croak';
use Errno 'EEXIST';
use Fcntl qw(O_APPEND O_CREAT O_EXCL O_RDONLY O_RDWR);
use File::Copy 'move';
use File::Spec::Functions 'catfile';
use File::Temp;
use File::Path;
use File::Basename;
use Digest::MD5 'md5_hex';
use Digest::SHA1;
use IO::File;
our $VERSION = '1.03';

has [qw/cleanup path end_range ro/] => ( 
    is => 'rw',
);

has start_range => (
    is => 'rw',
    default => sub { 0 },
);

has handle => ( 
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;

        # Open existing file
        my $handle = IO::File->new;
        my $path   = $self->path;
        if (defined $path && -f $path) {
            $handle->open($path, -w $path ? ($self->ro ? O_RDONLY : O_RDWR) : O_RDONLY) 
                or croak qq{Can't open file "$path": $!};
            return $handle;
        }

        # Open new or temporary file
        my $out = File::Temp->new(UNLINK => $self->cleanup);
        $out->autoflush(1);
        my $base = $out->filename;
        my $name = $path // $base;
        until ($handle->open($name, O_CREAT | O_RDWR)) {
            croak qq{Can't open file "$name": $!} if defined $path || $! != $!{EEXIST};
            $name = "$base." . md5_hex(time . $$ . rand 999);
        }
        $self->path($name);

        # Enable automatic cleanup
        $self->cleanup(1) unless defined $self->cleanup;

        return $handle;
    }
);


sub DESTROY {
    my $self = shift;
    return unless $self->cleanup && defined(my $path = $self->path);
    close $self->handle;
    unlink $path if -w $path;
}

sub is_range { !!($_[0]->end_range || $_[0]->start_range) };

sub add_chunk {
    my ($self, $chunk) = @_;
    $chunk //= '';
    my $handle = $self->handle;
    if ($self->start_range) {
        $handle->sysseek($self->start_range, SEEK_SET);
    }
    else {
        $handle->sysseek(0, SEEK_END);
    }
    croak "Can't write to asset: $!"
        unless defined $handle->syswrite($chunk, length $chunk);
    return $self;
}

sub contains {
    my ($self, $str) = @_;

    my $handle = $self->handle;
    $handle->sysseek($self->start_range, SEEK_SET);

    # Calculate window size
    my $end  = $self->end_range // $self->size;
    my $len  = length $str;
    my $size = $len > 131072 ? $len : 131072;
    $size = $end - $self->start_range if $size > $end - $self->start_range;

    # Sliding window search
    my $offset = 0;
    my $start = $handle->sysread(my $window, $len);
    while ($offset < $end) {

        # Read as much as possible
        my $diff = $end - ($start + $offset);
        my $read = $handle->sysread(my $buffer, $diff < $size ? $diff : $size);
        $window .= $buffer;

        # Search window
        my $pos = index $window, $str;
        return $offset + $pos if $pos >= 0;
        return -1 if $read == 0 || ($offset += $read) == $end;

        # Resize window
        substr $window, 0, $read, '';
    }

    return -1;
}

sub get_chunk {
    my ($self, $offset, $max) = @_;
    $max //= 131072;

    $offset += $self->start_range;
    my $handle = $self->handle;
    $handle->sysseek($offset, SEEK_SET);

    my $buffer;
    if (defined(my $end = $self->end_range)) {
        return '' if (my $chunk = $end + 1 - $offset) <= 0;
        $handle->sysread($buffer, $chunk > $max ? $max : $chunk);
    }
    else { $handle->sysread($buffer, $max) }

    return $buffer;
}

sub first_line_of {
    my $fh = shift->handle; 
    my $line = <$fh>;
    chomp $line;
    $line =~ s/^\s+|\s+$//g;

    return $line;
}

sub md5sum {
    my $self = shift;
    my $content = shift;
    my $md5 = Digest::MD5->new;
    if ($content) {
        $md5->add($content);
        return $md5->hexdigest, 
    }
    my $handle = $self->handle;
    $handle->sysseek(0, SEEK_SET);
    while ($handle->sysread(my $buffer, 131072, 0)) { 
        $md5->add($buffer);
    }   
    return $md5->hexdigest, 
}

sub sha1sum {
    my $self = shift;
    my $content = shift;
    my $sha1 = Digest::SHA1->new;
    if ($content) {
        $sha1->add($content);
        return $sha1->hexdigest, 
    }
    my $handle = $self->handle;
    $handle->sysseek(0, SEEK_SET);
    while ($handle->sysread(my $buffer, 131072, 0)) { 
        $sha1->add($buffer);
    }   
    return $sha1->hexdigest, 
}

sub crc32 {
    my $self = shift;
    my $content = shift;
    eval q{ require Digest::CRC } or die 'Could not require Digest::CRC';
    my $crc = Digest::CRC->new( type => "crc32" );
    my $handle = $self->handle;
    $handle->sysseek(0, SEEK_SET);
    if ($content) {
        $crc->add($content);
        return $crc->hexdigest, 
    }
    while ($handle->sysread(my $buffer, 131072, 0)) { 
        $crc->add($buffer);
    }   
    return $crc->hexdigest, 
}

sub is_file {1}

sub move_to {
    my ($self, $to) = @_;

    # Windows requires that the handle is closed
    close $self->handle;
    delete $self->{handle};

    my $dir  = File::Basename::dirname( $to );
    if (! -e $dir ) {
        if (! File::Path::make_path( $dir ) || ! -d $dir ) {
            my $e = $!;
        }
    }

    # Move file and prevent clean up
    my $from = $self->path;
    move($from, $to) or croak qq{Can't move file "$from" to "$to": $!};
    $self->cleanup(0);
    $self->path($to);
    return $self;
}

sub mtime { (stat shift->handle)[9] }

sub size { -s shift->handle }

sub slurp {
    return '' unless defined (my $path = shift->path);
    croak qq{Can't open file "$path": $!} unless open my $file, '<', $path;
    my $content = '';
    while ($file->sysread(my $buffer, 131072, 0)) { $content .= $buffer }
    return $content;
}

1;

=encoding utf8

=head1 NAME

Asset::File - File Operation interface 

=head1 SYNOPSIS

  use Asset::File;
  
  # Temporary file
  my $file = Asset::File->new;
  $file->add_chunk('foo bar baz');
  say 'File contains "bar"' if $file->contains('bar') >= 0;
  say $file->slurp;
  
  # Existing file
  my $file = Asset::File->new(path => '/home/sri/foo.txt');
  $file->move_to('/yada.txt');
  say $file->slurp;

=head1 DESCRIPTION

L<Asset::File> is a file content interface.

=head1 ATTRIBUTES

=head2 cleanup

  my $bool = $file->cleanup;
  $file    = $file->cleanup($bool);

Delete L</"path"> automatically once the file is not used anymore.

=head2 handle

  my $handle = $file->handle;
  $file      = $file->handle(IO::File->new);

Filehandle, created on demand.

=head2 path

  my $path = $file->path;
  $file    = $file->path('/home/sri/foo.txt');

File path used to create L</"handle">, can also be automatically generated if
necessary.

=head1 METHODS

=head2 add_chunk

  $file = $file->add_chunk('foo bar baz');

Add chunk of data, if there is range from range position to start writing.

=head2 contains

  my $position = $file->contains('bar');

Check if asset contains a specific string, if there is range from range position to start checking.

=head2 get_chunk

  my $bytes = $file->get_chunk($offset);
  my $bytes = $file->get_chunk($offset, $max);

Get chunk of data starting from a specific position, defaults to a maximum
chunk size of C<131072> bytes (128KB).

=head2 is_file

  my $true = $file->is_file;

True.

=head2 move_to

  $file = $file->move_to('/home/sri/bar.txt');

Move asset data into a specific file and disable L</"cleanup">.

=head2 mtime

  my $mtime = $file->mtime;

Modification time of asset.

=head2 size

  my $size = $file->size;

Size of asset data in bytes.

=head2 md5sum

  my $md5 = $file->md5sum;

return the md5 digest in hexadecimal form file;

=head2 sha1sum

  my $sha1 = $file->sha1sum;

return the sha1 digest in hexadecimal form file;

=head2 slurp

  my $bytes = $file->slurp;

Read all asset data at once.

=head1 SEE ALSO

L<Mojo::Asset::File>

=cut
