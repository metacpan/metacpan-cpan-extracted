package Data::Riak::Result::WithLocation;
{
  $Data::Riak::Result::WithLocation::VERSION = '2.0';
}
# ABSTRACT: Results with a Location

use Moose::Role;
use namespace::autoclean;


has location => (
    is       => 'ro',
    isa      => 'URI',
    required => 1,
);


has bucket => (
    is      => 'ro',
    does    => 'Data::Riak::Role::Bucket',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->riak->bucket( $self->bucket_name )
    }
);


has bucket_name => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my @uri_parts = split /\//, $self->location->path;
        return $uri_parts[$#uri_parts - 2];
    }
);


has key => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my @uri_parts = split /\//, $self->location->path;
        return $uri_parts[$#uri_parts];
    }
);

sub BUILD {}
after BUILD => sub {
    my ($self) = @_;
    $self->bucket_name;
    $self->key;
};


# if it's been changed on the server, discard those changes and update the
# object
my %warned_for;
sub sync {
    my ($self, %opts) = @_;

    my $new_result = $self->bucket->get( $self->key, \%opts );
    if (!defined wantarray) {
        my $caller = caller;
        warn "${caller} is using the deprecated ->sync in void context"
            unless $warned_for{$caller};
        $_[0] = $new_result;
    }

    return $new_result;
}


# if it's been changed locally by cloning, save those changes to the server
sub save {
    my ($self, %opts) = @_;
    return $self->bucket->add(
        $self->key, (exists $opts{new_value} ? $opts{new_value} : $self->value),
        {
            links => (exists $opts{new_links} ? $opts{new_links} : $self->links),
            return_body  => 1,
            vector_clock => $self->vector_clock,
            (exists $opts{cb} ? (cb => $opts{cb}) : ()),
            (exists $opts{error_cb} ? (error_cb => $opts{error_cb}) : ()),
        },
    );
}


sub save_unless_modified {
    my ($self, %opts) = @_;
    return $self->bucket->add(
        $self->key, (exists $opts{new_value} ? $opts{new_value} : $self->value),
        {
            links => (exists $opts{new_links} ? $opts{new_links} : $self->links),
            return_body  => 1,
            vector_clock => $self->vector_clock,
            if_unmodified_since => $self->last_modified . '',
            if_match => $self->etag,
            (exists $opts{cb} ? (cb => $opts{cb}) : ()),
            (exists $opts{error_cb} ? (error_cb => $opts{error_cb}) : ()),
        },
    );
}


sub linkwalk {
    my ($self, $params, $cb, $error_cb) = @_;
    return $self->riak->linkwalk({
        bucket   => $self->bucket_name,
        object   => $self->key,
        params   => $params,
        cb       => $cb,
        error_cb => $error_cb,
    });
}

1;

__END__

=pod

=head1 NAME

Data::Riak::Result::WithLocation - Results with a Location

=head1 VERSION

version 2.0

=head1 ATTRIBUTES

=head2 location

The location URI as provided by Riak.

=head2 bucket

The L<Data::Riak::Bucket> this result was retrieved from.

=head2 bucket_name

The name of the bucket this result was retrieved from.

=head2 key

The key this object is stored under within its bucket.

=head1 METHODS

=head2 sync

Re-fetches the object from its bucket and returns a new instance representing
the latest version of the object in storage.

=head2 save (%opts)

  $obj->save(
       new_value => $new_value,
       new_links => $new_links,
  );

Saves the object back into its bucket, possibly with a different set of links or
a different value.

If the C<new_value> option isn't given, the current C<-E<gt>value> won't be
altered.

If the C<new_links> option isn't given, the current C<-E<gt>links> won't be
altered.

The updated object is returned.

=head2 save_unless_modified

  $obj->save_unless_modified(
       new_value => $new_value,
       new_links => $new_links,
  );

Line L</save>, but will throw an exception when attempting to overwrite changes
that have been made to this object within Riak since the current C<$obj> has
been retrieved.

=head2 linkwalk

See L<Data::Riak/LINKWALKING>.

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
