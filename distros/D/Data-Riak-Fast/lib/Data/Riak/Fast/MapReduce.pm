package Data::Riak::Fast::MapReduce;

# ABSTRACT: A map/reduce query

use Mouse;
use Data::Riak::Fast::MapReduce::Phase::Link;
use Data::Riak::Fast::MapReduce::Phase::Map;
use Data::Riak::Fast::MapReduce::Phase::Reduce;

use JSON::XS qw/encode_json/;

with 'Data::Riak::Fast::Role::HasRiak';

=head1 DESCRIPTION

A map/reduce query.

=head1 SYNOPSIS

    my $riak = Data::Riak::Fast->new;

    my $mr = Data::Riak::Fast::MapReduce->new({
        riak => $riak,
        inputs => [ [ "products8", $arg ] ],
        phases => [
            Data::Riak::Fast::MapReduce::Phase::Map->new(
                language => "javascript",
                source => "
                function(v) {
                  var m = v.values[0].data.toLowerCase().match(/\w*/g);
                  var r = [];
                  for(var i in m) {
                    if(m[i] != '') {
                      var o = {};
                      o[m[i]] = 1;
                      r.push(o);
                    }
                  }
                  return r;
                }
                ",
            ),
            Data::Riak::Fast::MapReduce::Phase::Reduce->new(
                language => "javascript",
                source => "
                function(v) {
                  var r = {};
                  for(var i in v) {
                    for(var w in v[i]) {
                      if(w in r) r[w] += v[i][w];
                      else r[w] = v[i][w];
                    }
                  }
                  return [r];
                }
                ",
            ),
        ]
    });

    my $results = $mr->mapreduce;

=head2 inputs

Inputs to this query.  There are few allowable forms.

For a single bucket:

  inputs => "bucketname"

For a bucket and key (or many!):

  inputs => [ [ "bucketname", "keyname" ] ]

  inputs => [ [ "bucketname", "keyname" ], [ "bucketname", "keyname2" ] ]
  
And finally:

  inputs => [ [ "bucketname", "keyname", "keyData" ] ]

=cut

has inputs => (
    is => 'ro',
    isa => 'ArrayRef | Str | HashRef',
    required => 1
);

=head2 phases

An arrayref of phases that will be executed in order.  The phases should be
one of L<Data::Riak::Fast::MapReduce::Phase::Link>,
L<Data::Riak::Fast::MapReduce::Phase::Map>, or L<Data::Riak::Fast::MapReduce::Phase::Reduce>.

=cut

has phases => (
    is => 'ro',
    isa => 'ArrayRef[Data::Riak::Fast::MapReduce::Phase]',
    required => 1
);

=head1 METHOD
=head2 mapreduce

Execute the mapreduce query.

To enable streaming, do the following:

    my $results = $mr->mapreduce(chunked => 1);

=cut

sub mapreduce {
    my ($self, %options) = @_;
  
    return $self->riak->send_request({
        content_type => 'application/json',
        method => 'POST',
        uri => 'mapred',
        data => encode_json({
            inputs => $self->inputs,
            query => [ map { { $_->phase => $_->pack } } @{ $self->phases } ]
        }),
        ($options{'chunked'}
            ? (query => { chunked => 'true' })
            : ()),
    });
}

__PACKAGE__->meta->make_immutable;
no Mouse;

1;

__END__
