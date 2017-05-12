package AnyMongo::Cursor;
BEGIN {
  $AnyMongo::Cursor::VERSION = '0.03';
}
#ABSTRACT: A asynchronous cursor/iterator for Mongo query results
use strict;
use warnings;
use namespace::autoclean;
use boolean;
use Tie::IxHash;
use AnyMongo::MongoSupport;
use Any::Moose;
use Carp qw(croak confess);

$AnyMongo::Cursor::slave_okay = 0;
$AnyMongo::Cursor::timeout = 30000;

has _connection => (
    is => 'ro',
    isa => 'AnyMongo::Connection',
    required => 1,
);

has _socket_handle => (
    isa => 'Maybe[AnyEvent::Handle]',
    is  => 'rw',
    lazy_build => 1,
);

sub _build__socket_handle {
    my ($self) = @_;
    $self->_connection->master_handle;
}

has tailable => (
    is => 'rw',
    isa => 'Bool',
    required => 0,
    default => 0,
);

has batch_size => (
    is => 'rw',
    isa => 'Int',
    required => 1,
    default => 0,
);

has _ns => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has _query => (
    is => 'rw',
    required => 1,
);

has _fields => (
    is => 'rw',
    isa => 'HashRef',
    required => 0,
);

has _limit => (
    is => 'rw',
    isa => 'Int',
    required => 0,
    default => 0,
);

has _skip => (
    is => 'rw',
    isa => 'Int',
    required => 0,
    default => 0,
);

has _cursor_id => (
    is => 'rw',
    isa => 'Int',
    required => 0,
    default => 0,
);


has _num_remain => (
    is => 'rw',
    isa => 'Int',
    required => 0,
    default => 0,
);

has _result_cache => (
    is => 'rw',
    isa => 'ArrayRef',
    required => 0,
    default => sub {[]}
);

has immortal => (
    is => 'rw',
    isa => 'Bool',
    required => 0,
    default => 0,
);


has slave_okay => (
    is => 'rw',
    isa => 'Bool',
    required => 0,
    default => 0,
);
# stupid hack for inconsistent database handling of queries
has _grrrr => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has _request_id => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has _print_debug => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

sub CLONE_SKIP { 1 }

sub BUILD { shift->_init_cursor }

sub _init_cursor {
    my ($self) = @_;
    $self->{query_run} = 0;
    $self->{closed} = 0;
    $self->{cursor_id} = 0;
    $self->{at} = 0;
}

sub _ensure_special {
    my ($self) = @_;

    if ($self->_grrrr) {
        return;
    }

    $self->_grrrr(1);
    $self->_query({'query' => $self->_query});
}

sub fields {
    my ($self, $f) = @_;
    $self->_check_modifiable;
    confess 'not a hash reference' unless ref $f eq 'HASH';

    $self->_fields($f);
    return $self;
}

sub sort {
    my ($self, $order) = @_;
    $self->_check_modifiable;
    confess 'not a hash reference' unless ref $order eq 'HASH' || ref $order eq 'Tie::IxHash';

    $self->_ensure_special;
    $self->_query->{'orderby'} = $order;
    return $self;
}

sub limit {
    my ($self, $num) = @_;
    $self->_check_modifiable;
    $self->_limit($num);
    return $self;
}

sub skip {
    my ($self, $num) = @_;
    $self->_check_modifiable;
    $self->_skip($num);
    return $self;
}

sub snapshot {
    my ($self) = @_;
    $self->_check_modifiable;
    $self->_ensure_special;
    $self->_query->{'$snapshot'} = 1;
    return $self;
}

sub hint {
    my ($self, $index) = @_;
    $self->_check_modifiable;
    confess 'not a hash reference' unless ref $index eq 'HASH';

    $self->_ensure_special;
    $self->_query->{'$hint'} = $index;
    return $self;
}

sub explain {
    my ($self) = @_;
    my $temp = $self->_limit;
    if ($self->_limit > 0) {
        $self->_limit($self->_limit * -1);
    }

    $self->_ensure_special;
    $self->_query->{'$explain'} = boolean::true;

    my $retval = $self->reset->next;
    $self->reset->limit($temp);

    return $retval;
}

sub count {
    my ($self, $all) = @_;

    my ($db, $coll) = $self->_ns =~ m/^([^\.]+)\.(.*)/;
    my $cmd = Tie::IxHash->new(count => $coll);

    if ($self->_grrrr) {
        $cmd->Push(query => $self->_query->{'query'});
    }
    else {
        $cmd->Push(query => $self->_query);
    }

    if ($all) {
        $cmd->Push(limit => $self->_limit) if $self->_limit;
        $cmd->Push(skip => $self->_skip) if $self->_skip;
    }

    my $result = $self->_connection->get_database($db)->run_command($cmd);

    # returns "ns missing" if collection doesn't exist
    return 0 unless ref $result eq 'HASH';
    return $result->{'n'};
}

sub all {
    my ($self) = @_;
    my @ret;

    while (my $entry = $self->next) {
        push @ret, $entry;
    }

    return @ret;
}
# Run query the first time we request an object from the wire
sub send_initial_query {
    my ($self) = @_;

    if ($self->{query_run}) {
        return 0;
    }

    # warn "#send_initial_query ...\n" if $self->_print_debug;

    my $opts = $AnyMongo::Cursor::slave_okay | ($self->tailable << 1) |
        ($self->slave_okay << 2) | ($self->immortal << 4);

    my $query = AnyMongo::MongoSupport::build_query_message($self->_next_request_id,$self->_ns,
        $opts, $self->_skip, $self->_limit, $self->_query, $self->_fields);
    $self->_connection->send_message($query,$self->_socket_handle);
    my ($number_received,$cursor_id,$result) = $self->_connection->recv_message($self->_socket_handle);
    # warn "#send_initial_query number_received:$number_received cursor_id:".sprintf('%x',$cursor_id)." result#:".@{$result} if $self->_print_debug;
    # warn "#send_initial_query number_received:$number_received cursor_id:".sprintf('%x',$cursor_id);
    push @{$self->{_result_cache}},@{$result} if $result;
    $self->{number_received} = $number_received;
    $self->{cursor_id} = $cursor_id;
    $self->{query_run} = 1;
    $self->close_cursor_if_query_complete;

    return 1;
}


sub next {
    my ($self) = @_;
     # warn "#next ...\n" if $self->_print_debug;
    return $self->next_document if $self->has_next && ( $self->{_limit} <= 0
         || $self->{at} < $self->{_limit} );

    return;
}

sub next_document {
    my ($self) = @_;

    # warn "refill_via_get_more ...\n" if $self->_print_debug;

    $self->refill_via_get_more if $self->num_remaining == 0;

    # warn "refill_via_get_more done.\n" if $self->_print_debug;

    my $doc = shift @{ $self->{_result_cache} };

    if ($doc and $doc->{'$err'}) {
        my $err = $doc->{'$err'};
        # todo:"not master"
        Carp::croak "query error: $err";
    }
    # warn 'leave next_document' if $self->_print_debug;
    $self->{at}++;
    $doc;
}

sub has_next { shift->num_remaining > 0 }

sub reset {
    my ($self) = @_;
    # warn "#reset ...\n" if $self->_print_debug;
    $self->{query_run} = 0;
    $self->{closed} = 0;
    $self->kill_cursor;
    $self->{at} = 0;
    $self->{_result_cache} = [];
    $self;
}

sub refill_via_get_more {
    my ($self) = @_;

    # warn "#refill_via_get_more...\n" if $self->_print_debug;

    return if $self->send_initial_query || $self->{cursor_id} == 0;

    my $request_id = $self->_next_request_id;
    # warn "#refill_via_get_more > build_get_more_message<
    #     request_id:$request_id
    #     _ns: ".$self->_ns."
    #     cursor_id:".$self->{cursor_id}."
    #     batch_size:".$self->batch_size."
    # >...\n" if $self->_print_debug;
    # get_more
    my $get_more_message = AnyMongo::MongoSupport::build_get_more_message(
        $request_id,
        $self->_ns,
        $self->{cursor_id},
        $self->batch_size);
    # warn "#refill_via_get_more > send_message...\n" if $self->_print_debug;
    $self->_connection->send_message($get_more_message,$self->_socket_handle);

    # warn "#refill_via_get_more > recv_message...\n" if $self->_print_debug;
    my ($number_received,$cursor_id,$result) = $self->_connection->recv_message($self->_socket_handle);

    # warn "#refill_via_get_more > got number_received:$number_received cursor_id:$cursor_id...\n" if $self->_print_debug;

    $self->{cursor_id} = $cursor_id;

    push @{$self->{_result_cache}},@{$result} if $result;
    $self->{number_received} = $number_received;
    $self->{cursor_id} = $cursor_id;
    $self->{query_run} = 1;
    $self->close_cursor_if_query_complete;
}

sub close_cursor_if_query_complete {
    my ($self) = @_;
    # warn "#close_cursor_if_query_complete ...\n" if $self->_print_debug;
    $self->close if $self->_limit >0 && $self->{number_received} >= $self->_limit;
}

sub num_remaining {
    my ($self) = @_;
    # warn "#num_remaining ...\n" if $self->_print_debug;
    $self->refill_via_get_more if @{$self->{_result_cache}} == 0;
    return scalar @{$self->{_result_cache}};
}

sub close {
    my ($self) = @_;
    # warn "#close ...\n" if $self->_print_debug;
    $self->kill_cursor if $self->{cursor_id};
    $self->{cursor_id} = 0;
    $self->{closed} = 1;
    $self->{at} = 0;
}

sub kill_cursor {
    my ($self) = @_;
    # warn "#kill_cursor ...\n" if $self->_print_debug;
    return unless $self->{cursor_id};
    my $message = AnyMongo::MongoSupport::build_kill_cursor_message($self->_next_request_id,$self->{cursor_id});
    $self->_connection->send_message($message,$self->_socket_handle);
    $self->{cursor_id} = 0;
}

sub _check_modifiable {
    my ($self) = @_;
    confess 'Cannot modify the query once it has been run or closed.'
        if $self->{query_run} || $self->{closed};
}

sub _next_request_id {
    my ($self) = @_;
    $self->_request_id(AnyMongo::MongoSupport::make_request_id());
    $self->_request_id;
}

__PACKAGE__->meta->make_immutable;
1;


=pod

=head1 NAME

AnyMongo::Cursor - A asynchronous cursor/iterator for Mongo query results

=head1 VERSION

version 0.03

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHORS

=over 4

=item *

Pan Fan(nightsailer) <nightsailer at gmail.com>

=item *

Kristina Chodorow <kristina at 10gen.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Pan Fan(nightsailer).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

