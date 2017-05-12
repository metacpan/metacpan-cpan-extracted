package Data::Riak::Async;
{
  $Data::Riak::Async::VERSION = '2.0';
}

use Moose;
use Data::Riak::ResultSet;
use Data::Riak::Async::HTTP;
use Data::Riak::Async::Bucket;
use namespace::autoclean;

with 'Data::Riak::Role::Frontend';

sub _build_request_classes {
    return +{
        (map {
            ($_ => 'Data::Riak::Async::Request::' . $_),
        } qw(MapReduce Ping GetBucketProps StoreObject GetObject
             ListBucketKeys RemoveObject LinkWalk Status ListBuckets
             SetBucketProps)),
    }
}

sub _build_bucket_class { 'Data::Riak::Async::Bucket' }

sub send_request {
    my ($self, $request_data) = @_;

    my $request = $self->_create_request($request_data);

    my $cb = $request->cb;
    $self->transport->send(
        $request,
        sub {
            my ($response) = @_;

            my @results = $response->create_results($self, $request);
            return $cb->() unless @results;

            if (@results == 1 && $results[0]->does('Data::Riak::Result::Single')) {
                return $cb->($request->_mangle_retval($results[0]));
            }

            $cb->($request->_mangle_retval(
                Data::Riak::ResultSet->new({ results => \@results }),
            ));
        },
        $request->error_cb,
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Riak::Async

=head1 VERSION

version 2.0

=head1 AUTHORS

=over 4

=item *

Andrew Nelson <anelson at cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
