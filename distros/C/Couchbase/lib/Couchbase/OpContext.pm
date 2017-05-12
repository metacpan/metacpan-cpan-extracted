package Couchbase::OpContext;
use strict;
use warnings;
use Couchbase::_GlueConstants;
use Data::Dumper;

our $AUTOLOAD;

sub AUTOLOAD {
    my $meth = (split(/::/, $AUTOLOAD))[-1];
    my $self = $_[0];
    my @args = @_;

    $args[0] = $self->_cbo; # CBO
    $args[3] = $self;
    @_ = @args;

    no strict 'refs';
    goto &{"Couchbase::Bucket::".$meth};
}

sub callback {
    if (scalar @_ == 2) {
        goto &set_callback;
    } else {
        goto &get_callback;
    }
}


# Note, there is no new() method because this must be instantiated
# via XS directly.
1;

__END__

=head1 NAME


Couchbase::OpContext - Operation context


=head1 SYNOPSIS


    my $ctx = $bucket->batch();

    # Create a bunch of documents
    my @docs = map { Couchbase::Document->new($_, {name=>$_}) } (qw(foo bar baz));
    $ctx->upsert($_) for @docs;
    $ctx->wait_all();

    # Get them back, reading each result as it arrives
    $ctx = $bucket->batch();
    $ctx->get($_) for @docs;

    while ((my $cur = $ctx->wait_one)) {
        printf("Got document ID %s with name %s\n", $doc->id, $doc->value->{name});
    }


=head1 DESCRIPTION

The C<OpContext> class is used to schedule multiple operations and
send them over the network as a single group.

To schedule operations on the context object, simply invoke the requested
operation as a method of the context object itself (rather than the bucket).

Once all the operations have been scheduled, the results should be submitted
to the cluster and waited for.

Once all operations have been completed, the batch object is no longer valid
and must be recreated using the C<batch()> method on L<Couchbase::Bucket>.

=head2 METHODS

=head3 wait_all()

Waits for all the scheduled operations to complete. When this method returns,
all documents passed to the operations will have completed and their contents
will be updated with new data from the server.


=head3 wait_one()

Waits for the next scheduled operation to complete. This method is an alternative
to waiting for all the operations to complete. This allows your application to deal
with each response as it arrives, rather than waiting for them all to complete.

This method returns the next document whose operation has been completed, and
a false value when no more outstanding operations remain.
