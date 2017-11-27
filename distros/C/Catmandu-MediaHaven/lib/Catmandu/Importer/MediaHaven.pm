package Catmandu::Importer::MediaHaven;

use Catmandu::Sane;

our $VERSION = '0.06';

use Moo;
use Cpanel::JSON::XS;
use Catmandu::MediaHaven;
use namespace::clean;

with 'Catmandu::Importer';

has 'url'           => (is => 'ro' , required => 1);
has 'username'      => (is => 'ro' , required => 1);
has 'password'      => (is => 'ro' , required => 1);
has 'mediahaven'    => (is => 'lazy');

sub _build_mediahaven {
    my ($self) = @_;
    Catmandu::MediaHaven->new(
        url      => $self->url,
        username => $self->username,
        password => $self->password,
    );
}

sub generator {
    my ($self) = @_;

    my $res = $self->mediahaven->search();

    sub {
        state $results = $res->{mediaDataList};
        state $total   = $res->{totalNrOfResults};
        state $index   = 0;

        $index++;

        if (@$results > 0) {
            return shift @$results;
        }
        elsif ($index < $total) {
            my $res = $self->mediahaven->search(undef, start => $index+1);
            $results = $res->{mediaDataList};
            $index++;
            return shift @$results;
        }
        return undef;
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Importer::MediaHaven - a importer that extracts Zeticon MediaHaven records

=head1 SYNOPSIS

    # From the commandline
    $ cat catmandu.yml
    ---
    importer:
         mh:
             package: MediaHaven
             options:
                 url: https://archief.viaa.be/mediahaven-rest-api/resources/media
                 username: ...
                 password: ...
                 fix:  |
                    ...
                    <fixes required to translate MediaHaven records to metadata>
                    ...

    $ catmandu convert YAML to mh < records.yml

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

=back

=head1 INHERITED METHODS

This Catmandu::Exporter::MediaHaven implements

=over 3

=item L<Catmandu::Importer>

=item L<Catmandu::Logger>

=item L<Catmandu::Iterable>

=item L<Catmandu::Fixable>

=item L<Catmandu::Serializer>

=back

=head1 SEE ALSO

L<Catmandu::Exporter::MediaHaven>

=cut
