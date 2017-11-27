package Catmandu::Store::File::MediaHaven;

our $VERSION = '0.06';

use Catmandu::Sane;
use Moo;
use Carp;
use Catmandu;
use Catmandu::Store::File::MediaHaven::Index;
use Catmandu::Store::File::MediaHaven::Bag;
use Catmandu::MediaHaven;
use namespace::clean;

with 'Catmandu::FileStore';

has 'url'           => (is => 'ro' , required => 1);
has 'username'      => (is => 'ro' , required => 1);
has 'password'      => (is => 'ro' , required => 1);
has 'record_query'  => (is => 'ro' , default => sub { "q=%%2B(MediaObjectFragmentId:%s)"; });

has id_fixer        => (is => 'ro' , init_arg => 'record_id_fix', coerce => sub {Catmandu->fixer($_[0])},);
has 'mh'            => (is => 'lazy');

sub _build_mh {
    my $self = shift;
    return Catmandu::MediaHaven->new(
        url      => $self->url,
        username     => $self->username,
        password     => $self->password,
        record_query => $self->record_query,
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::File::MediaHaven - A Catmandu::FileStore to access files in the Zeticon MediaHaven server

=head1 SYNOPSIS

    # From the command line

    $ cat catmandu.yml
    ---
    store:
         mh:
             package: MediaHaven
             options:
                 url: https://archief.viaa.be/mediahaven-rest-api/resources/media
                 username: ...
                 password: ...

    # Export a list of all file containers
    $ catmandu export mh to YAML

    # Export a list of all file containers based on a query
    $ catmandu export mh --query "+(MediaObjectFragmentTitle:data)"
    $ catmandu export mh --query "+(MediaObjectFragmentTitle:data)"  --sort "+=MediaObjectFragmentTitle"

    $ Count all file containers
    $ catmandu count mh

    # Export a list of all files in container '1234'
    $ catmandu export mh --bag 1234 to YAML

    # Download the file 'myfile.txt' from the container '1234'
    $ catmandu stream mh --bag 1234 --id myfile.txt to /tmp/output.txt


    # From Perl
    use Catmandu;

    my $store = Catmandu->store('File::MediaHaven' ,
        url      => '...' ,
        username => '...' ,
        password => '...' ,
    );

    my $index = $store->index;

    # List all folder
    $index->bag->each(sub {
        my $container = shift;

        print "%s\n" , $container->{_id};
    });

    # Get the folder
    my $files = $index->files('1234');

    # Retrieve a file
    my $file = $files->get('foobar.txt');

    # Stream the contents of a file
    $files->stream(IO::File->new('>foobar.txt'), $file);

=head1 METHODS

=head2 new(%connection_parameters)

Create a new Catmandu::Store::File::MediaHaven with the following connection
parameters:

=over

=item url

Required. The URL to the MediaHaven REST endpoint.

=item username

Required. Username used to connect to MediaHaven.

=item password

Required. Password used to connect to MediaHaven.

=item record_query

Optional. MediaHaven query to extract a given identifier from the database.
Default: "q=%%2B(MediaObjectFragmentId:%s)"

=item record_id_fix

Optional. One or more L<Catmandu::Fix> commands or a Fix script used to
extract the C<_id> bag identifier from the MediaHaven record.

=back


=head1 INHERITED METHODS

This Catmandu::FileStore implements:

=over 3

=item L<Catmandu::FileStore>

=back

The index Catmandu::Bag in this Catmandu::Store implements:

=over 3

=item L<Catmandu::Bag>

=item L<Catmandu::Searchable>

=item L<Catmandu::FileBag::Index>

=back

The file Catmandu::Bag in this Catmandu::Store implements:

=over 3

=item L<Catmandu::Bag>

=item L<Catmandu::FileBag>

=back

=head1 SEE ALSO

L<Catmandu::Store::File::MediaHaven::Index>,
L<Catmandu::Store::File::MediaHaven::Bag>,
L<Catmandu::FileStore>

=cut
