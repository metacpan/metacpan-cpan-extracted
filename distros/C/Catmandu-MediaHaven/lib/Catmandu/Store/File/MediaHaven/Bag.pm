package Catmandu::Store::File::MediaHaven::Bag;

our $VERSION = '0.05';

use Catmandu::Sane;
use Moo;
use Carp;
use Date::Parse;
use POSIX qw(ceil);
use namespace::clean;

with 'Catmandu::Bag';
with 'Catmandu::FileBag';

sub generator {
    my ($self) = @_;

    my $mh  = $self->store->mh;

    my $res = $mh->record($self->name);

    sub {
        state $done = 0;

        return undef if $done;

        $done = 1;

        return $self->_get($res,$res->{originalFileName});
    };
}

sub _get {
    my ($self,$result,$key) = @_;

    my $mh  = $self->store->mh;

    return undef unless $result;

    return undef unless $result->{originalFileName} eq $key;

    my $md5;

    for my $prop (@{$result->{mdProperties}}) {
        if ($prop->{attribute} eq 'md5_viaa') {
            $md5 = $prop->{value};
        }
    }

    return +{
        _id          => $key,
        size         => -1,
        md5          => $md5 ? $md5 : 'none',
        created      => str2time($result->{archiveDate}),
        modified     => str2time($result->{lastModifiedDate}),
        content_type => 'application/zip',
        _stream      => sub {
            my $out   = $_[0];
            my $bytes = 0;
            $mh->export($self->name, sub {
                my $data = shift;
                # Support the Dancer send_file "write" callback
                if ($out->can('syswrite')) {
                    $bytes += $out->syswrite($data) || die "failed to write : $!";
                }
                else {
                    $bytes += $out->write($data) || die "failed to write : $!";;
                }
            });

            $out->close();

            $bytes;
        }
    };
}

sub exists {
    my ($self, $id) = @_;

    my $mh  = $self->store->mh;

    my $res = $mh->record($self->name);

    $res->{originalFileName} eq $id;
}

sub get {
    my ($self, $id) = @_;

    my $mh  = $self->store->mh;

    my $res = $mh->record($self->name);

    return $self->_get($res,$id);
}

sub add {
    my ($self, $data) = @_;
    croak "Add is not supported in the MediaHaven FileStore";
}

sub delete {
    my ($self, $id) = @_;
    croak "Delete is not supported in the MediaHaven FileStore";
}

sub delete_all {
    my ($self) = @_;
    croak "Delete is not supported in the MediaHaven FileStore";
}

sub commit {
    return 1;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::File::MediaHaven::Bag - Index of all "files" in a Catmandu::Store::File::MediaHaven "folder"

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

=item L<Catmandu::FileBag>

=back
