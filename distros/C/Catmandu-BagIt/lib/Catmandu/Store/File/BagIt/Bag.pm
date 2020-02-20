package Catmandu::Store::File::BagIt::Bag;

use Catmandu::Sane;

our $VERSION = '0.250';

use Moo;
use Carp;
use IO::File;
use Path::Tiny;
use File::Spec;
use Catmandu::Sane;
use Catmandu::BagIt;
use Catmandu::Util qw(content_type);
use URI::Escape;
use POSIX qw(strftime);
use namespace::clean;

with 'Catmandu::Bag';
with 'Catmandu::FileBag';
with 'Catmandu::Droppable';

has _path  => (is => 'lazy');
has _bagit => (is => 'lazy');

sub _build__path {
    my $self = shift;
    $self->store->path_string($self->name);
}

sub _build__bagit {
    my $self = shift;
    my $bag = Catmandu::BagIt->read($self->_path);
    $bag->{escape} = 0 if $bag; # This implementation does its own file escaping...
    $bag;
}

sub generator {
    my ($self) = @_;
    my $path  = $self->_path;
    my $bagit = $self->_bagit;

    sub {
        state $children = [$bagit->list_files];

        my $child = shift @$children;

        return undef unless $child;

        my $file = $child->filename;

        my $unpacked_key = $self->unpack_key($file);

        return $self->get($unpacked_key);
    };
}

sub exists {
    my ($self, $id) = @_;
    my $path  = $self->_path;
    my $bagit = $self->_bagit;

    my $packed_key = $self->pack_key($id);

    $bagit->get_checksum($packed_key) ? 1 : 0;
}

sub get {
    my ($self, $id) = @_;

    my $path  = $self->_path;
    my $bagit = $self->_bagit;

    my $packed_key = $self->pack_key($id);

    my $file = $bagit->get_file($packed_key);

    return undef unless $file;

    my $stat     = [stat $file->path];

    my $size     = $stat->[7];
    my $modified = $stat->[9];
    my $created  = $stat->[10];    # no real creation time exists on Unix

    my $content_type = content_type($id);

    return {
        _id          => $id,
        size         => $size,
        md5          => $bagit->get_checksum($packed_key) // undef,
        content_type => $content_type,
        created      => $created,
        modified     => $modified,
        _stream      => sub {
            $self->file_streamer($file->path,shift);
        }
    };
}

sub add {
    my ($self, $data) = @_;
    my $path  = $self->_path;
    my $bagit = $self->_bagit;

    my $update = 1;

    unless ($bagit) {
        $update = 0;
        $bagit  = Catmandu::BagIt->new(algorithm => 'md5', escape => 0);
        $self->{_bagit} = $bagit;
    }

    my $id = $data->{_id};
    my $io = $data->{_stream};

    return $self->get($id) unless $io;

    my $packed_key = $self->pack_key($id);

    $bagit->add_file($packed_key,$io,overwrite => 1);

    unless ($update) {
        $bagit->remove_info('Bagging-Date');
        $bagit->add_info('Bagging-Date', strftime("%Y-%M-%D", gmtime));
    }

    $bagit->remove_info('Bagging-Update');
    $bagit->add_info('Bagging-Update', strftime("%Y-%m-%d", gmtime));

    $bagit->write($path, overwrite => 1);

    my $new_data = $self->get($id);

    $data->{$_} = $new_data->{$_} for keys %$new_data;

    1;
}

sub delete {
    my ($self, $id) = @_;
    my $path  = $self->_path;
    my $bagit = $self->_bagit;

    my $packed_key = $self->pack_key($id);

    my $file = $bagit->get_file($packed_key);

    return undef unless $file;

    $bagit->remove_file($packed_key);

    $bagit->write($path, overwrite => 1);
}

sub delete_all {
    my ($self) = @_;

    $self->each(
        sub {
            my $key = shift->{_id};
            $self->delete($key);
        }
    );

    1;
}

sub drop {
    $_[0]->delete_all;
}

sub commit {
    return 1;
}

sub pack_key {
    my $self = shift;
    my $key  = shift;
    utf8::encode($key);
    uri_escape($key);
}

sub unpack_key {
    my $self = shift;
    my $key  = shift;
    my $str  = uri_unescape($key);
    utf8::decode($str);
    $str;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::File::BagIt::Bag - Index of all "files" in a Catmandu::Store::File::BagIt "folder"

=head1 SYNOPSIS

    use Catmandu;

    my $store = Catmandu->store('File::BagIt' , root => 't/data');

    my $index = $store->index;

    # List all containers
    $index->each(sub {
        my $container = shift;

        print "%s\n" , $container->{_id};
    });

    # Add a new folder
    $index->add({_id => '1234'});

    # Delete a folder
    $index->delete(1234);

    # Get a folder
    my $folder = $index->get(1234);

    # Get the files in an folder
    my $files = $index->files(1234);

    $files->each(sub {
        my $file = shift;

        my $name         = $file->_id;
        my $size         = $file->size;
        my $content_type = $file->content_type;
        my $created      = $file->created;
        my $modified     = $file->modified;

        $file->stream(IO::File->new(">/tmp/$name"), file);
    });

    # Add a file
    $files->upload(IO::File->new("<data.dat"),"data.dat");

    # Retrieve a file
    my $file = $files->get("data.dat");

    # Stream a file to an IO::Handle
    $files->stream(IO::File->new(">data.dat"),$file);

    # Delete a file
    $files->delete("data.dat");

    # Delete a folders
    $index->delete("1234");

=head1 INHERITED METHODS

This Catmandu::Bag implements:

=over 3

=item L<Catmandu::Bag>

=item L<Catmandu::FileBag>

=item L<Catmandu::Droppable>

=back

=cut
