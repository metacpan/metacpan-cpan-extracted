package Data::Riak::Fast;

use Mouse;

use JSON::XS qw/decode_json/;
use URI;

use Data::Riak::Fast::Result;
use Data::Riak::Fast::ResultSet;
use Data::Riak::Fast::Bucket;
use Data::Riak::Fast::MapReduce;

use Data::Riak::Fast::HTTP;

our $VERSION = '0.03';

has transport => (
    is       => 'ro',
    isa      => 'Data::Riak::Fast::HTTP',
    required => 1,
    handles  => {
        'ping'     => 'ping',
        'base_uri' => 'base_uri',
    },
);

sub send_request {
    my ($self, $request) = @_;

    my ($response, $uri) = $self->transport->send($request);

    if ($response->is_error) {
        die $response;
    }

    my @parts = @{ $response->parts };

    return unless @parts;
    return Data::Riak::Fast::ResultSet->new(
        {
            results => [
                map {
                    Data::Riak::Fast::Result->new(
                        {
                            riak         => $self,
                            http_message => $_,
                            location     => (
                                $_->header('location')
                                ? URI->new( $_->header('location') )
                                : $uri
                            )
                        }
                    );
                } @parts
            ],
        }
    );
}

sub _buckets {
    my $self = shift;

    return decode_json(
        $self->send_request({
            method => 'GET',
            uri => '/buckets',
            query => { buckets => 'true' }
        })->first->value
    );
}

sub bucket {
    my ($self, $bucket_name) = @_;

    return Data::Riak::Fast::Bucket->new({
        riak => $self,
        name => $bucket_name,
    });
}

sub resolve_link {
    my ($self, $link) = @_;

    $self->bucket( $link->bucket )->get( $link->key );
}

sub linkwalk {
    my ($self, $args) = @_;

    my $object = $args->{object} || die 'You must have an object to linkwalk';
    my $bucket = $args->{bucket} || die 'You must have a bucket for the original object to linkwalk';

    my $request_str = "buckets/$bucket/keys/$object/";
    my $params = $args->{params};

    foreach my $depth (@$params) {
        if(scalar @{$depth} == 2) {
            unshift @{$depth}, $bucket;
        }
        my ($buck, $tag, $keep) = @{$depth};
        $request_str .= "$buck,$tag,$keep/";
    }

    return $self->send_request({
            method => 'GET',
            uri => $request_str
    });
}

sub stats {
    my $self = shift;

    return decode_json(
        $self->send_request({
            method => 'GET',
            uri => '/stats',
        })->first->value
    );
}

__PACKAGE__->meta->make_immutable;
no Mouse;

1;
__END__

=head1 NAME

Data::Riak::Fast - more fast interface to a Riak Server

=head1 SYNOPSIS

  use Data::Riak::Fast;

=head1 DESCRIPTION

Data::Riak::Fast is more fast interface to a Riak Server.

=head1 AUTHOR

Tatsuro Hisamori E<lt>myfinder@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
