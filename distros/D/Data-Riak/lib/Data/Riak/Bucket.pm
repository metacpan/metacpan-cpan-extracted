package Data::Riak::Bucket;
{
  $Data::Riak::Bucket::VERSION = '2.0';
}
# ABSTRACT: A Data::Riak bucket, used for storing keys and values.

use strict;
use warnings;

use Moose;

use Data::Riak::Link;
use Data::Riak::Util::MapCount;
use Data::Riak::Util::ReduceCount;

use Data::Riak::MapReduce;
use Data::Riak::MapReduce::Phase::Reduce;

use HTTP::Headers::ActionPack::LinkList;

use JSON::XS qw/decode_json encode_json/;

use namespace::autoclean;

with 'Data::Riak::Role::Bucket';


sub remove_all {
    my $self = shift;
    my $keys = $self->list_keys;
    foreach my $key ( @$keys ) {
        $self->remove( $key );
    }
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Riak::Bucket - A Data::Riak bucket, used for storing keys and values.

=head1 VERSION

version 2.0

=head1 SYNOPSIS

    my $bucket = Data::Riak::Bucket->new({
        name => 'my_bucket',
        riak => $riak
    });

    # Sets the value of "foo" to "bar", in my_bucket.
    $bucket->add('foo', 'bar');

    # Gets the Result object for "foo" in my_bucket.
    my $foo = $bucket->get('foo');

    # Returns "bar"
    my $value = $foo->value;

    $bucket->create_alias({ key => 'foo', as => 'alias_to_foo' });
    $bucket->create_alias({ key => 'foo', as => 'alias_to_foo', in => $another_bucket });

    # Returns "bar"
    my $value = $bucket->resolve_alias('alias_to_foo');
    my $value = $another_bucket->resolve_alias('alias_to_foo');

    $bucket->add('baz, 'value of baz', { links => [$bucket->create_link( riaktag => 'buddy', key =>'foo' )] });
    my $resultset = $bucket->linkwalk('baz', [[ 'buddy', '_' ]]);
    my $value = $resultset->first->value;   # Will be "bar", the value of foo

=head1 DESCRIPTION

Data::Riak::Bucket is the primary interface that most people will use for Riak.
Adding and removing keys and values, adding links, querying keys; all of those
happen here.

=head1 METHODS

=head2 add ($key, $value, $opts)

This will insert a key C<$key> into the bucket, with value C<$value>. The C<$opts>
can include links, allowed content types, or queries.

=head2 remove ($key, $opts)

This will remove a key C<$key> from the bucket.

=head2 get ($key, $opts)

This will get a key C<$key> from the bucket, returning a L<Data::Riak::Result> object.

=head2 list_keys

List all the keys in the bucket. Warning: This is expensive, as it has to scan
every key in the system, so don't use it unless you mean it, and know what you're
doing.

=head2 count

Count all the keys in a bucket. This uses MapReduce to figure out the answer, so
it's expensive; Riak does not keep metadata on buckets for reasons that are beyond
the scope of this module (but are well documented, so if you are interested, read up).

=head2 remove_all

Remove all the keys from a bucket. This involves a list_keys call, so it will be
slow on larger systems.

=head2 search_index

Searches a Secondary Index to find results.

=head2 create_alias ($opts)

Creates an alias for a record using links. Helpful if your primary ID is a UUID or
some other automatically generated identifier. Can cross buckets, as well.

    $bucket->create_alias({ key => '123456', as => 'foo' });
    $bucket->create_alias({ key => '123456', as => 'foo', in => $other_bucket });

=head2 resolve_alias ($alias)

Returns the L<Data::Riak::Result> that $alias points to.

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
