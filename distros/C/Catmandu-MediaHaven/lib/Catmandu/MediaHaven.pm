package Catmandu::MediaHaven;

=head1 NAME

Catmandu::MediaHaven - Tools to communicate with the Zeticon MediaHaven server

=head1 SYNOPSIS

    use Catmandu::MediaHaven;

    my $mh = Catmandu::MediaHaven->new(
                    url      => '...' ,
                    username => '...' ,
                    password => '...');

    my $result = $mh->search('nature', start => 0 , num => 100);

    die "search failed" unless defined($result);

    for my $res (@{$result->mediaDataList}) {
        my $id = $res->{externalId};
        my $date = $res->{data};

        print "$id $date\n";
    }

    my $record = $mh->record('q2136s817');
    my $date   = $record->{date};

    print "q2136s817 $date\n";

    $mh->export($id, sub {
       my $data = shift;
       print $data;
    });

=head1 DESCRIPTION

The L<Catmandu::MediaHaven> module is a low end interface to the MediaHaven
REST api. See also: https://archief.viaa.be/mediahaven-rest-api

=head1 METHODS

=head2 new(url => ... , username => ... , password => ...)

Create a new connection to the MediaHaven server.

=cut
use Moo;
use LWP::Simple;
use URI::Escape;
use JSON;
use LWP;
use Carp;
use Catmandu;
use Cache::LRU;
use REST::Client;

our $VERSION = '0.03';

with 'Catmandu::Logger';

has 'url'          => (is => 'ro' , required => 1);
has 'username'     => (is => 'ro' , required => 1);
has 'password'     => (is => 'ro' , required => 1);
has 'record_query' => (is => 'ro' , default => sub { "q=%%2B(MediaObjectExternalId:%s)"; });
has 'sleep'        => (is => 'ro' , default => sub { 1 });

has 'cache'        => (is => 'lazy');
has 'cache_size'   => (is => 'ro' , default => '1000');

sub _build_cache {
    my $self = shift;

    return Cache::LRU->new(size => $self->cache_size);
}

=head2 search($query, start => ... , num => ...)

Execute a search query against the MediaHaven server and return the result_list
as a HASH

=cut
sub search {
    my ($self,$query,%opts) = @_;

    my @param = ();

    if (defined($query) && length($query)) {
        push @param , sprintf("q=%s",uri_escape($query));
    }

    if ($opts{start}) {
        push @param , sprintf("startIndex=%d",$opts{start});
    }

    if ($opts{num}) {
        push @param , sprintf("nrOfResults=%d",$opts{num});
    }

    if (my $sort = $opts{sort}) {
        my $direction;

        if ($sort =~ /^[+]/) {
            $direction = 'up';
            $sort = substr($sort,1);
        }
        elsif ($sort =~ /^[-]/) {
            $direction = 'down';
            $sort = substr($sort,1);
        }
        else {
            $direction = 'up';
        }
        push @param , sprintf("sort=%s",uri_escape($sort));
        push @param , sprintf("direction=%s",uri_escape($direction));
    }

    $self->log->info("searching with params: " . join("&",@param));

    my $res = $self->_rest_get(@param);

    if (! defined $res) {
        $self->log->error("got a null response");
        return undef;
    }
    elsif ($res->{code}) {
        $self->log->error("got an error response: " . $res->{message});
        return undef;
    }

    $self->log->info("found: " . $res->{totalNrOfResults} . " hits");

    for my $hit (@{$res->{mediaDataList}}) {
        my $id;

        INNER: for my $prop (@{ $hit->{mdProperties} }) {
           if ($prop->{attribute} eq 'dc_identifier_localid') {
                $id = $prop->{value};
                        $id =~ s{^\S+:}{};
                last INNER;
           }
        }

        $self->cache->set($id => $hit) if defined($id);
    }

    $res;
}

=head2 record($id)

Retrieve one record from the MediaHaven server based on an identifier. Returns
a HASH of results.

=cut
sub record {
    my ($self,$id) = @_;

    croak "need an id" unless defined($id);

    if (my $hit = $self->cache->get($id)) {
        return $hit;
    }

    my $query = sprintf $self->record_query , $id;

    $self->log->info("retrieve query: $query");

    my $res = $self->_rest_get($query);

    if (exists $res->{code}) {
        $self->log->error("retrieve query '$query' failed: " . $res->{message});

        return undef;
    }

    if ($res->{mediaDataList}) {
        return $res->{mediaDataList}->[0];
    }
    else {
        return undef;
    }
}

=head2 export($id, $callback)

Export the binary content of a record from the MediaHaven server. The callback
will retrieve a stream of data when the download is available,

=cut
sub export {
    my ($self,$id,$callback) = @_;

    croak "need an id and callback" unless defined($id) && defined($callback);

    $self->log->info("export record $id");

    my $record = $self->record($id);

    return undef unless $record;

    my $mediaObjectId = $record->{mediaObjectId};

    return undef unless $mediaObjectId;

    my $media_url = sprintf "%s/%s/export" , $self->_rest_base , $mediaObjectId;

    $self->log->info("posting $media_url");

    my ($export_job,$next) = $self->_post_json($media_url);

    return undef unless $export_job;

    my $downloadUrl;

    while (1) {
        my $exportId = $export_job->[0]->{exportId};
        my $status   = $export_job->[0]->{status};

        $self->log->debug("exportId = $exportId ; status = $status");

        last if $status =~ /^(failed|cancelled)$/;

        $downloadUrl  = $export_job->[0]->{downloadUrl};

        if ($downloadUrl =~ /^htt/) {
            last;
        }

        $self->log->debug("sleep " . $self->sleep);
        sleep $self->sleep;

        $export_job = $self->_get_json($next);
    }

    my $rest_url = $self->_rest_base($downloadUrl);

    $self->log->debug("download: $rest_url");

    my $browser  = LWP::UserAgent->new();

    my $response = $browser->get($rest_url, ':content_cb' => $callback);

    if ($response->is_success) {
        return 1;
    }
    else {
        $self->log->error("failed to contact the download url $rest_url");
        return undef;
    }
}

sub _get_json {
    my ($self,$url) = @_;

    $self->log->debug($url);

    my $client = REST::Client->new();
    $client->GET($url);
    my $json = $client->responseContent();

    decode_json $json;
}

sub _post_json {
    my ($self,$url) = @_;

    $self->log->debug($url);

    my $client = REST::Client->new();
    $client->POST($url);
    my $json = $client->responseContent();

    my $location = $self->_rest_base( $client->responseHeader('Location') );

    my $perl = decode_json $json;

    ($perl,$location);
}

sub _rest_base {
    my ($self,$url) = @_;

    my $authen    = sprintf "%s:%s" , uri_escape($self->username) , uri_escape($self->password);
    my $media_url = $url // $self->url;

    $media_url =~ s{https://}{};
    $media_url = 'https://' . $authen . '@' . $media_url;

    $media_url;
}

sub _rest_get {
    my ($self,@param) = @_;

    my $media_url = $self->_rest_base . '?';

    $media_url .= join("&",@param);

    $self->_get_json($media_url);
}


=head1 MODULES

L<Catmandu::Importer::MediaHaven>

L<Catmandu::Store::File::MediaHaven>

L<Catmandu::Store::File::MediaHaven::Bag>

L<Catmandu::Store::File::MediaHaven::Index>

=head1 AUTHOR

=over

=item * Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=back

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the terms
of either: the GNU General Public License as published by the Free Software Foundation;
or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
