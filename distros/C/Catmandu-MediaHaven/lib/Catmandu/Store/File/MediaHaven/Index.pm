package Catmandu::Store::File::MediaHaven::Index;

our $VERSION = '0.06';

use Catmandu::Sane;
use Moo;
use Carp;
use POSIX qw(ceil);
use Catmandu::Store::File::MediaHaven::Searcher;
use namespace::clean;

with 'Catmandu::Bag';
with 'Catmandu::Searchable';
with 'Catmandu::FileBag::Index';

sub generator {
    my ($self) = @_;

    my $searcher = Catmandu::Store::File::MediaHaven::Searcher->new(
                        bag   => $self ,
                        limit => undef ,
                        start => 0 ,
                        sort  => undef ,
                        query => undef ,
                    );

    return $searcher->generator;
}

sub exists {
    my ($self, $id) = @_;

    croak "Need a key" unless defined $id;

    my $res = $self->store->mh->record($id);

    defined($res);
}

sub add {
    my ($self, $data) = @_;

    croak "Add is not supported in the MediaHaven FileStore";
}

sub get {
    my ($self, $id) = @_;

    my $res = $self->store->mh->record($id);

    if ($res) {
        return +{_id => $id};
    }
    else {
        return undef;
    }
}

sub delete {
    my ($self, $id) = @_;

    croak "Delete is not supported in the MediaHaven FileStore";
}

sub delete_all {
    my ($self) = @_;

    croak "Delete is not supported in the MediaHaven FileStore";
}

sub delete_by_query {
    my ($self, %args) = @_;

    croak "Delete is not supported in the MediaHaven FileStore";
}

sub search {
    my ($self, %args) = @_;

    croak "Search is not supported in the MediaHaven FileStore";
}

sub searcher {
    my ($self, %args) = @_;

    Catmandu::Store::File::MediaHaven::Searcher->new(%args, bag => $self);
}

sub count {
    my ($self)    = @_;

    my $mh    = $self->store->mh;

    my $res   = $mh->search(undef);

    $res->{totalNrOfResults};
}

sub commit {
    return 1;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::File::MediaHaven::Index - Index of all "Folders" in a MediaHaven database

=head1 SYNOPSIS

    use Catmandu;

    my $store = Catmandu->store('File::MediaHaven' ,
        url => '...' ,
        username => '...' ,
        password => '...' ,
    );

    my $index = $store->index;

    # List all containers
    $index->each(sub {
        my $container = shift;

        print "%s\n" , $container->{_id};
    });

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

    # Retrieve a file
    my $file = $files->get("data.dat");

    # Stream a file to an IO::Handle
    $files->stream(IO::File->new(">data.dat"),$file);

=head1 INHERITED METHODS

This Catmandu::Bag implements:

=over 3

=item L<Catmandu::Bag>

=item L<Catmandu::FileBag::Index>

=back
