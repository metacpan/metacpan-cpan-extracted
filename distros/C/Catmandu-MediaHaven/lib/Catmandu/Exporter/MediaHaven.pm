package Catmandu::Exporter::MediaHaven;

use Catmandu::Sane;

our $VERSION = '1.0603';

use Moo;
use Cpanel::JSON::XS;
use Catmandu::MediaHaven;
use Carp;
use namespace::clean;

with 'Catmandu::Exporter';

has 'url'           => (is => 'ro' , required => 1);
has 'username'      => (is => 'ro' , required => 1);
has 'password'      => (is => 'ro' , required => 1);
has 'json_key'      => (is => 'ro' , required => 1);
has 'record_query'  => (is => 'ro' , default => sub { "q=%%2B(MediaObjectFragmentId:%s)"; });
has 'mediahaven'    => (is => 'lazy');

sub _build_mediahaven {
    my ($self) = @_;
    Catmandu::MediaHaven->new(
        url          => $self->url,
        username     => $self->username,
        password     => $self->password,
        record_query => $self->record_query,
    );
}

sub add {
    my ($self,$data) = @_;
    my $id     = $data->{_id};

    croak "add needs id" unless $id;

    my $key    = $self->json_key;
    my $json   = encode_json($data);

    my $result = $self->mediahaven->edit($id,$key,$json);

    if (defined($result) && $result->{ok}) {
        return 1;
    }
    else {

        $self->log->error("failed to update $id");
        return 0;
    }
}

sub commit { 1 }

1;

__END__

=pod

=head1 NAME

Catmandu::Exporter::MediaHaven - a exporter that updates Zeticon MediaHaven records

=head1 SYNOPSIS

    # From the commandline
    $ cat catmandu.yml
    ---
    exporter:
         mh:
             package: MediaHaven
             options:
                 url: https://archief.viaa.be/mediahaven-rest-api/resources/media
                 username: ...
                 password: ...
                 json_key: description

    $ catmandu convert YAML to mh < records.yml

=head2 DESCRIPTION

This Exporter will convert metadata records into a JSON encoded field in the
MediaHaven database. A `json_key` is required. This is the field were the JSON
encoded data is stored.

Attn: take some seconds/minutes to have the metadata updates available and
indexed in the backend database.
 
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

=item json_key

Required. The metdata field where the record data as a JSON blob is stored

=item record_query

Optional. MediaHaven query to extract a record '_id' from the database.
Default: "q=%%2B(MediaObjectFragmentId:%s)"

=back

=head1 INHERITED METHODS

This Catmandu::Exporter::MediaHaven implements

=over 3

=item L<Catmandu::Exporter>

=item L<Catmandu::Logger>

=item L<Catmandu::Addable>

=item L<Catmandu::Fixable>

=item L<Catmandu::Counter>

=back

=head1 SEE ALSO

L<Catmandu::Importer::MediaHaven>

=cut
