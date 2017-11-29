package APISchema::Route;
use strict;
use warnings;

# lib
use APISchema::Resource;

# cpan
use Class::Accessor::Lite (
    new => 1,
    rw => [qw(route title description destination method option
              request_resource response_resource)],
);

sub _canonical_resource {
    my ($self, $method, $resource_root, $extra_args, $filter) = @_;

    $method = "${method}_resource";
    my $resource = $self->$method();
    for (@$extra_args) {
        last unless $resource && ref $resource eq 'HASH';
        last unless $resource->{$_};
        $resource = $resource->{$_};
    }
    $resource = { body => $resource } unless ref $resource;

    $filter = [qw(header parameter body)] unless scalar @$filter;
    my %filter = map { $_ => 1 } grep { $resource->{$_} } @$filter;
    return +{
        %$resource,
        map {
            my $name = $resource->{$_};
            $_ => APISchema::Resource->new(
                title => $name,
                definition => ,+{
                    %$resource_root,
                    '$ref' => sprintf '#/resource/%s', $name,
                },
            );
        } grep { $filter{$_} } qw(header parameter body),
    };
}

sub canonical_request_resource {
    my ($self, $resource_root, $extra_args, $filter) = @_;
    return $self->_canonical_resource(
        request => $resource_root,
        $extra_args // [], $filter // [],
    );
}

sub canonical_response_resource {
    my ($self, $resource_root, $extra_args, $filter) = @_;
    return $self->_canonical_resource(
        response => $resource_root,
        $extra_args // [], $filter // [],
    );
}

sub responsible_code_is_specified {
    my ($self) = @_;
    my $res = $self->response_resource;
    return unless $res && ref $res;

    my @codes = sort grep { $_ =~ qr!\A[0-9]+\z! } keys %$res;
    return @codes > 0;
}

sub responsible_codes {
    my ($self) = @_;

    return [200] unless $self->responsible_code_is_specified;

    my $res = $self->response_resource;
    my @codes = sort grep { $_ =~ qr!\A[0-9]+\z! } keys %$res;
    return @codes ? [@codes] : [200];
}

sub default_responsible_code {
    my ($self) = @_;

    $self->responsible_codes->[0];
}

1;
