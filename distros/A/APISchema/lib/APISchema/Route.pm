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

1;
