package AnyMongo::Collection;
BEGIN {
  $AnyMongo::Collection::VERSION = '0.03';
}
# ABSTRACT: Asynchronous MongoDB::Collection
use strict;
use warnings;
use namespace::autoclean;
use Tie::IxHash;
use boolean;
use Any::Moose;

has _database => (
    is       => 'ro',
    isa      => 'AnyMongo::Database',
    required => 1,
);

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has full_name => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_full_name',
);

sub _build_full_name {
    my ($self) = @_;
    my $name    = $self->name;
    my $db_name = $self->_database->name;
    return "${db_name}.${name}";
}

sub to_index_string {
    my $keys = shift;

    my @name;
    if (ref $keys eq 'ARRAY' || ref $keys eq 'HASH' ) {

        while ((my $idx, my $d) = each(%$keys)) {
            push @name, $idx;
            push @name, $d;
        }
    }
    elsif (ref $keys eq 'Tie::IxHash') {
        my @ks = $keys->Keys;
        my @vs = $keys->Values;

        @vs = $keys->Values;
        for (my $i=0; $i<$keys->Length; $i++) {
            push @name, $ks[$i];
            push @name, $vs[$i];
        }
    }
    else {
        confess 'expected Tie::IxHash, hash, or array reference for keys';
    }

    return join("_", @name);
}

sub find {
    my ($self, $query, $attrs) = @_;
    # old school options - these should be set with MongoDB::Cursor methods
    my ($limit, $skip, $sort_by) = @{ $attrs || {} }{qw/limit skip sort_by/};

    $limit   ||= 0;
    $skip    ||= 0;

    my $q = {};
    if ($sort_by) {
        $q->{'query'} = $query;
	$q->{'orderby'} = $sort_by;
    }
    else {
        $q = $query ? $query : {};
    }

    my $conn = $self->_database->_connection;
    my $ns = $self->full_name;
    my $cursor = AnyMongo::Cursor->new(
	    _connection => $conn,
	    _ns => $ns,
	    _query => $q,
	    _limit => $limit,
	    _skip => $skip
    );
    return $cursor;
}

sub query {
    my ($self, $query, $attrs) = @_;

    return $self->find($query, $attrs);
}

sub find_one {
    my ($self, $query, $fields) = @_;
    $query ||= {};
    $fields ||= {};

    return $self->find($query)->limit(-1)->fields($fields)->next;
}

sub insert {
    my ($self, $object, $options) = @_;
    my ($id) = $self->batch_insert([$object], $options);

    return $id;
}

sub batch_insert {
    my ($self, $object, $options) = @_;
    confess 'not an array reference' unless ref $object eq 'ARRAY';

     my $ns = $self->full_name;
     my ($insert, $ids) = AnyMongo::MongoSupport::build_insert_message(
         AnyMongo::MongoSupport::make_request_id(),
         $ns, $object);

     my $conn = $self->_database->_connection;

     if (defined($options) && $options->{safe}) {
         my $ok = $self->_make_safe($insert);
         if (!$ok) {
             return 0;
         }
     }
     else {
         $conn->send_message($insert);
     }

     return @$ids;
}

sub update {
    my ($self, $query, $object, $opts) = @_;

    # there used to be one option: upsert=0/1
    # now there are two, there will probably be
    # more in the future.  So, to support old code,
    # passing "1" will still be supported, but not
    # documentd, so we can phase that out eventually.
    #
    # The preferred way of passing options will be a
    # hash of {optname=>value, ...}
    my $flags = 0;
    if ($opts && ref $opts eq 'HASH') {
        $flags |= $opts->{'upsert'} << 0
            if exists $opts->{'upsert'};
        $flags |= $opts->{'multiple'} << 1
            if exists $opts->{'multiple'};
    }
    else {
        $flags = !(!$opts);
    }

    my $conn = $self->_database->_connection;
    my $ns = $self->full_name;

    if ($opts->{safe}) {
        return $self->_make_safe(AnyMongo::MongoSupport::build_update_message(
            AnyMongo::MongoSupport::make_request_id(),
            $ns, $query, $object, $flags));
    }

    $conn->send_message(AnyMongo::MongoSupport::build_update_message(
        AnyMongo::MongoSupport::make_request_id(),
        $ns, $query, $object, $flags));

    return 1;
}

sub remove {
    my ($self, $query, $options) = @_;
    my $just_one;
    my $conn = $self->_database->_connection;
    my $ns = $self->full_name;

    $query ||= {};

    if (defined $options && ref $options eq 'HASH') {
        $just_one = exists $options->{just_one} ? $options->{just_one} : 0;

        if ($options->{safe}) {
            my $ok = $self->_make_safe(AnyMongo::MongoSupport::build_remove_message(
                AnyMongo::MongoSupport::make_request_id(),
                $ns, $query, $just_one));
            return $ok;
        }
    }
    else {
        $just_one = $options || 0;
    }

    $conn->send_message(AnyMongo::MongoSupport::build_remove_message(
        AnyMongo::MongoSupport::make_request_id(),
        $ns, $query, $just_one));

    return 1;
}

sub ensure_index {
    my ($self, $keys, $options, $garbage) = @_;
    my $ns = $self->full_name;

    # we need to use the crappy old api if...
    #  - $options isn't a hash, it's a string like "ascending"
    #  - $keys is a one-element array: [foo]
    #  - $keys is an array with more than one element and the second 
    #    element isn't a direction (or at least a good one)
    #  - Tie::IxHash has values like "ascending"
    if (($options && ref $options ne 'HASH') ||
        (ref $keys eq 'ARRAY' &&
         ($#$keys == 0 || $#$keys >= 1 && !($keys->[1] =~ /-?1/))) ||
        (ref $keys eq 'Tie::IxHash' && $keys->[2][0] =~ /(de|a)scending/)) {
        Carp::croak("you're using the old ensure_index format, please upgrade");
    }

    my $obj = Tie::IxHash->new("ns" => $ns, "key" => $keys);

    if (exists $options->{name}) {
        $obj->Push("name" => $options->{name});
    }
    else {
        $obj->Push("name" => AnyMongo::Collection::to_index_string($keys));
    }

    if (exists $options->{unique}) {
        $obj->Push("unique" => ($options->{unique} ? boolean::true : boolean::false));
    }
    if (exists $options->{drop_dups}) {
        $obj->Push("dropDups" => ($options->{drop_dups} ? boolean::true : boolean::false));
    }
    if (exists $options->{background}) {
        $obj->Push("background" => ($options->{background} ? boolean::true : boolean::false));
    }

    my ($db, $coll) = $ns =~ m/^([^\.]+)\.(.*)/;

    my $indexes = $self->_database->get_collection("system.indexes");
    return $indexes->insert($obj, $options);
}

sub _make_safe {
    my ($self, $req) = @_;
    my $conn = $self->_database->_connection;
    my $db = $self->_database->name;

    my $last_error = Tie::IxHash->new(getlasterror => 1, w => $conn->w, wtimeout => $conn->wtimeout);
    my $request_id = AnyMongo::MongoSupport::make_request_id();
    my $query = AnyMongo::MongoSupport::build_query_message(
        $request_id, $db.'.$cmd', 0, 0, -1, $last_error);
    # $conn->recv($cursor);
    $conn->send_message("$req$query");

    my ($number_received,$cursor_id,$result) = $conn->recv_message();
    # use Data::Dumper;
    # warn "_make_safe getlasterror number_received:$number_received cursor_id:$cursor_id result=> ".Dumper($result);

    if ( $number_received == 1 ) {
        my $ok = $result->[0];
        # $result->{ok} is 1 if err is set
        Carp::croak $ok->{err} if $ok->{err};
        # $result->{ok} == 0 is still an error
        if (!$ok->{ok}) {
            Carp::croak $ok->{errmsg};
        }
    }
    return 1;
}

sub save {
    my ($self, $doc, $options) = @_;

    if (exists $doc->{"_id"}) {

        if (!$options || !ref $options eq 'HASH') {
            $options = {"upsert" => boolean::true};
        }
        else {
            $options->{'upsert'} = boolean::true;
        }

        return $self->update({"_id" => $doc->{"_id"}}, $doc, $options);
    }
    else {
        return $self->insert($doc, $options);
    }
}

sub count {
    my ($self, $query) = @_;
    $query ||= {};

    my $obj;
    eval {
        $obj = $self->_database->run_command({
            count => $self->name,
            query => $query,
        });
    };

    # if there was an error, check if it was the "ns missing" one that means the
    # collection hasn't been created or a real error.
    if ($@) {
        # if the request timed out, $obj might not be initialized
        if ($obj && $obj =~ m/^ns missing/) {
            return 0;
        }
        else {
            die $@;
        }
    }

    return $obj->{n};
}

sub validate {
    my ($self, $scan_data) = @_;
    $scan_data = 0 unless defined $scan_data;
    my $obj = $self->_database->run_command({ validate => $self->name });
}

sub drop_indexes {
    my ($self) = @_;
    return $self->drop_index('*');
}

sub drop_index {
    my ($self, $index_name) = @_;
    my $t = tie(my %myhash, 'Tie::IxHash');
    %myhash = ("deleteIndexes" => $self->name, "index" => $index_name);
    return $self->_database->run_command($t);
}

sub get_indexes {
    my ($self) = @_;
    return $self->_database->get_collection('system.indexes')->query({
        ns => $self->full_name,
    })->all;
}

sub drop {
    my ($self) = @_;
    $self->_database->run_command({ drop => $self->name });
    return;
}

__PACKAGE__->meta->make_immutable;
1;


=pod

=head1 NAME

AnyMongo::Collection - Asynchronous MongoDB::Collection

=head1 VERSION

version 0.03

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

