package Catmandu::Store::File::BagIt;

our $VERSION = '0.260';

use Catmandu::Sane;
use Moo;
use Carp;
use Catmandu;
use Catmandu::Util;
use Catmandu::Store::File::BagIt::Index;
use Catmandu::Store::File::BagIt::Bag;
use namespace::clean;

with 'Catmandu::FileStore';
with 'Catmandu::Droppable';

has root    => (is => 'ro', required => '1');
has uuid    => (is => 'ro', trigger  => 1);
has keysize => (is => 'ro', default  => 9, trigger => 1);
has default_case => (is => 'ro', default => sub { 'upper'} , trigger => 1);

sub _trigger_keysize {
    my $self = shift;

    croak "keysize needs to be a multiple of 3"
        unless $self->keysize % 3 == 0;
}

sub _trigger_uuid {
    my $self = shift;

    $self->{keysize} = 36;
}

sub _trigger_default_case {
    my $self = shift;

    croak "default_case need to be `upper' or `lower`"
        unless $self->default_case =~ /^(upper|lower)$/;
}

sub path_string {
    my ($self, $key) = @_;

    my $keysize = $self->keysize;

    my $h;

    if ($self->default_case eq 'upper') {
        $h = "[0-9A-F]";
        $key = uc $key;
    }
    elsif ($self->default_case eq 'lower') {
        $h = "[0-9a-f]";
        $key = lc $key;
    }
    else {
        croak "unkown default_case found";
    }

    # If the key is a UUID then the matches need to be exact
    if ($self->uuid) {
        return undef unless $key =~ qr/\A${h}{8}-${h}{4}-${h}{4}-${h}{4}-${h}{12}\z/;
    }
    elsif ($key =~ qr/\A\d+\z/) {
        return undef unless length($key) && length($key) <= $keysize;
        $key =~ s/^0+//;
        $key = sprintf "%-${keysize}.${keysize}d", $key;
    }
    else {
        return undef;
    }

    my $path = $self->root . "/" . join("/", unpack('(A3)*', $key));

    $path;
}

sub drop {
    my ($self) = @_;

    $self->index->delete_all;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::File::BagIt - A Catmandu::FileStore to store files on disk in the BagIt format

=head1 SYNOPSIS

    # From the command line

    # Export a list of all file containers
    $ catmandu export File::BagIt --root t/data to YAML

    # Export a list of all files in container '1234'
    $ catmandu export File::BagIt --root t/data --bag 1234 to YAML

    # Add a file to the container '1234'
    $ catmandu stream /tmp/myfile.txt to File::BagIt --root t/data --bag 1234 --id myfile.txt

    # Download the file 'myfile.txt' from the container '1234'
    $ catmandu stream File::BagIt --root t/data --bag 1234 --id myfile.txt to /tmp/output.txt

    # Delete the file 'myfile.txt' from the container '1234'
    $ catmandu delete File::BagIt --root t/data --bag 1234 --id myfile.txt

    # From Perl
    use Catmandu;

    my $store = Catmandu->store('File::BagIt' , root => 't/data');

    my $index = $store->index;

    # List all folder
    $index->bag->each(sub {
        my $container = shift;

        print "%s\n" , $container->{_id};
    });

    # Add a new folder
    $index->add({ _id => '1234' });

    # Get the folder
    my $files = $index->files('1234');

    # Add a file to the folder
    $files->upload(IO::File->new('<foobar.txt'), 'foobar.txt');

    # Retrieve a file
    my $file = $files->get('foobar.txt');

    # Stream the contents of a file
    $files->stream(IO::File->new('>foobar.txt'), $file);

    # Delete a file
    $files->delete('foobar.txt');

    # Delete a folder
    $index->delete('1234');

=head1 DESCRIPTION

L<Catmandu::Store::File::BagIt> is a L<Catmandu::FileStore> implementation to
store files in a directory structure. Each L<Catmandu::FileBag> is
a deeply nested directory based on the numeric identifier of the bag. E.g.

    $store->bag(1234)

is stored as

    ${ROOT}/000/001/234

In this directory all the L<Catmandu::FileBag> items are stored as
flat files.

=head1 METHODS

=head2 new(root => $path , [ keysize => NUM , uuid => 1 , default_case => 'upper|lower'])

Create a new Catmandu::Store::File::BagIt with the following configuration
parameters:

=over

=item root

The root directory where to store all the files. Required.

=item keysize

By default the directory structure is 3 levels deep. With the keysize option
a deeper nesting can be created. The keysize needs to be a multiple of 3.
All the container keys of a L<Catmandu::Store::File::BagIt> must be integers.

=item uuid

If the to a true value, then the Simple store will require UUID-s as keys

=item default_case

When set to 'upper' all stored identifier paths will be translated to uppercase
(e.g. for UUID paths). When set to 'lower' all identifier paths will be
translated to lowercase. Default: 'upper'

=back

=head1 LARGE FILE SUPPORT

Streaming large files into a BagIt requires a large /tmp directory. The location
of the temp directory can be set with the TMPDIR environmental variable.

=head1 INHERITED METHODS

This Catmandu::FileStore implements:

=over 3

=item L<Catmandu::FileStore>

=item L<Catmandu::Droppable>

=back

The index Catmandu::Bag in this Catmandu::Store implements:

=over 3

=item L<Catmandu::Bag>

=item L<Catmandu::FileBag::Index>

=item L<Catmandu::Droppable>

=back

The file Catmandu::Bag in this Catmandu::Store implements:

=over 3

=item L<Catmandu::Bag>

=item L<Catmandu::FileBag>

=item L<Catmandu::Droppable>

=back

=head1 SEE ALSO

L<Catmandu::Store::File::BagIt::Index>,
L<Catmandu::Store::File::BagIt::Bag>,
L<Catmandu::Plugin::SideCar>,
L<Catmandu::FileStore>

=cut
