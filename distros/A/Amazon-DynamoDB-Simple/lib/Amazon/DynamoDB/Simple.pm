package Amazon::DynamoDB::Simple;
use Amazon::DynamoDB;
use Carp qw/cluck confess carp croak/;
use DDP;
use JSON::XS;
use Moo;
use Try::Tiny;

our $VERSION="0.01";

=head1 NAME

Amazon::DynamoDB::Simple - Simple to use and highly available

=head1 SYNOPSIS

    use Amazon::DynamoDB::Simple;

    my $table = Amazon::DynamoDB::Simple->new(
        table             => $table,       # required
        primary_key       => $primary_key, # required
        access_key_id     => ..., # default: $ENV{AWS_ACCESS_KEY_ID};
        secret_access_key => ..., # default: $ENV{AWS_SECRET_ACCESS_KEY};
    );

    # returns a hash
    my %item = $table->get($key);

    # create or update an item
    $table->put(%item);

    # mark item as deleted
    $table->delete($key);

    # returns a hash representing the whole table as key value pairs
    $table->items();

    # returns all the keys in the table
    $table->keys();

    # delete $old_key, create $new_key
    $table->rename($old_key, $new_key);

    # sync data between AWS regions using the 'last_updated' field to select
    # the newest data.  This method will permanently delete any items marked as
    # 'deleted'.
    $table->sync_regions();

    # This sets the value of the hosts attribute.  The value shown is the
    # default value.  You must use exactly two hosts for stuff to work atm.
    # Sorry.
    $table->hosts([qw/
            dynamodb.us-east-1.amazonaws.com
            dynamodb.us-west-1.amazonaws.com
    /]);

=head1 DESCRIPTION

DynamoDB is a simple key value store.  A Amazon::DynamoDB::Simple object
represents a single table in DynamoDB.

This module provides a simple UI layer on top of Amazon::DynamoDB.  It also
makes your data highly available across exactly 2 AWS regions.  In other words
it provides redundancy in case one region goes down.  It doesn't do async.  It
doesn't (currently) support secondary keys.

Note Amazon::DynamoDB can't handle complex data structures.  But this module
can because it serializes yer stuff to JSON if needed.

At the moment you cannot use this module against a single dynamodb server.  The
table must exist in 2 regions.  I want to make the high availability part
optional in the future.  It should not be hard.  Patches welcome.

=head1 DATA REDUNDANCY

TODO

=cut

has table             => (is => 'rw', required => 1);
has primary_key       => (is => 'rw', required => 1);
has dynamodbs         => (is => 'lazy');
has hosts             => (is => 'rw', lazy => 1, builder => 1);
has access_key_id     => (is => 'rw', lazy => 1, builder => 1);
has secret_access_key => (is => 'rw', lazy => 1, builder => 1);

sub _build_access_key_id     { $ENV{AWS_ACCESS_KEY_ID}     }
sub _build_secret_access_key { $ENV{AWS_SECRET_ACCESS_KEY} }

sub _build_hosts {
    return [qw/
        dynamodb.us-east-1.amazonaws.com
        dynamodb.us-west-1.amazonaws.com
    /];
}

sub _build_dynamodbs {
    my $self = shift;

    my @dynamodbs;
    my $hosts = $self->hosts();

    for my $host (@$hosts) {
        push @dynamodbs, 
            Amazon::DynamoDB->new(
                access_key     => $self->access_key_id,
                secret_key     => $self->secret_access_key,
                ssl            => 1,
                version        => '20120810',
                implementation => 'Amazon::DynamoDB::MojoUA',
                host           => $host,
            );
    }

    return \@dynamodbs;
}

sub put {
    my ($self, %item) = @_;

    # timestamp this transaction
    $item{last_updated} = DateTime->now . ""; # stringify datetime
    $item{deleted}    ||= 0;

    %item         = $self->deflate(%item);
    my $dynamodbs = $self->dynamodbs();
    my $success   = 0;

    for my $dynamodb (@$dynamodbs) {
        try { 
            $dynamodb->put_item(
                TableName => $self->table,
                Item      => \%item,
            )->get;
            $success++;
        }
        catch {
            warn "caught error: " . p $_;
        };
    }

    # make sure at least one put_item() was successful
    confess "unable to save to any dynamodb" unless $success;
}

sub delete {
    my ($self, $key) = @_;

    my %item = $self->get($key);

    return unless keys %item;

    $self->put(%item, deleted => 1);
}

# Amazon::DynamoDB can't handle anything other than simple scalars
sub inflate {
    my ($self, %item) = @_;
    my %new;

    for my $key (keys %item) {
        my $value   = $item{$key};
        $new{$key} = $self->is_valid_json($value)
            ? JSON::XS->new->utf8->pretty->decode($value)
            : $value;
    }

    return %new;
}

# Amazon::DynamoDB can't handle anything other than simple scalars
sub deflate {
    my ($self, %item) = @_;
    my %new;

    for my $key (keys %item) {
        my $value  = $item{$key};
        $new{$key} = ref $value
            ? JSON::XS->new->utf8->pretty->encode($value)
            : $item{$key};
    }

    return %new;
}

sub is_valid_json {
    my ($self, $json) = @_;
    eval { JSON::XS->new->utf8->pretty->decode($json) };
    return 0 if $@;
    return 1;
}

sub permanent_delete {
    my ($self, $key) = @_;

    my $dynamodbs = $self->dynamodbs();
    my $success   = 0;

    for my $dynamodb (@$dynamodbs) {
        try { 
            $dynamodb->delete_item(
                TableName => $self->table,
                Key       => { $self->primary_key => $key },
            )->get;
            $success++;
        }
        catch {
            warn "caught error: " . p $_;
        };
    }

    confess "unable to permanently delete item from any dynamodb" unless $success;
}

sub get {
    my ($self, $key) = @_;

    my $dynamodbs = $self->dynamodbs();
    my $success   = 0;
    my @items;

    for my $dynamodb (@$dynamodbs) {
        try { 
            push @items, $dynamodb->get_item(
                sub { shift },
                TableName => $self->table,
                Key       => { $self->primary_key => $key },
            )->get();
            $success++;
        }
        catch {
            warn "caught error: " . p $_;
        };
    }

    confess "unable to connect and get item from any dynamodb" unless $success;

    my $most_recent;
    for my $item (@items) {
        next unless $item;

        $most_recent = $item 
            if !$most_recent ||
                $most_recent->{last_updated} le $item->{last_updated};
    }

    return if $most_recent->{deleted};

    return $self->inflate(%$most_recent);
}

sub scan {
    my ($self) = @_;

    my $dynamodbs = $self->dynamodbs();
    my $success   = 0;
    my @items;

    for my $dynamodb (@$dynamodbs) {
        my $res;

        try { 
            $res = $dynamodb->scan(
                sub { shift },
                TableName => $self->table,
            )->get();
        }
        catch {
            warn "caught error: " . p $_;
        };

        return $res if $res;
    }

    confess "unable to connect and scan from any dynamodb";
}

sub sync_regions {
    my ($self) = @_;

    my $dynamodb0 = $self->dynamodbs->[0];
    my $dynamodb1 = $self->dynamodbs->[1];

    my $scan0 = $dynamodb0->scan(sub { shift }, TableName => $self->table)->get->{Items};
    my $scan1 = $dynamodb1->scan(sub { shift }, TableName => $self->table)->get->{Items};

    my $items0 = $self->_process_items($scan0);
    my $items1 = $self->_process_items($scan1);

    # sync from $dynamodb0 -> $dynamodb1
    $self->_sync_items($dynamodb0 => $dynamodb1, $items0 => $items1);

    # sync from $dynamodb1 -> $dynamodb0
    $self->_sync_items($dynamodb1 => $dynamodb0, $items1 => $items0);
}

sub _process_items {
    my ($self, $items) = @_;

    my $key = $self->primary_key;
    my $definitions;

    for my $item (@$items) {
        my $primary_key = delete($item->{$key})->{S};

        for my $attr (keys %$item) {
            my $type_value = $item->{$attr};
            my ($type) = keys %$type_value;
            $definitions->{$primary_key}->{$attr} = $item->{$attr}->{$type};
        }

        $definitions->{$primary_key}->{$key} = $primary_key;
    }


    return $definitions;
}

sub _sync_items {
    my ($self, $from_ddb, $to_ddb, $from_items, $to_items) = @_;

    my $primary_key_name = $self->primary_key;

    for my $from_key (keys %$from_items) {
        my $from_value = $from_items->{$from_key};
        my $to_value = $to_items->{$from_key};
        if (!$to_value) {
            $to_value = {last_updated => '1900-01-01T00:00:00'};
            $to_items->{$from_key} = $to_value;
        }

        my $updated0 = $from_value->{last_updated};
        my $updated1 = $to_value->{last_updated};

        # don't need to sync if the items are the same age and not deleted
        next if $updated0 eq $updated1 && !$to_value->{deleted};

        # find the newest item
        my $newest = $updated0 gt $updated1
            ? $from_value
            : $to_value;

        # sync newest item to the other region
        if ($newest->{deleted}) {
            $self->permanent_delete( $newest->{$primary_key_name} );
        }
        else {
            # TODO: this could be more efficient by syncing to just the ddb
            # that needs it
            $self->put(%$newest);
        }

        # Lets say we are syncing from $dynamodb0 -> $dynamodb1. This prevents
        # us from re syncing this item when we sync in the other direction from
        # $dynamodb1 -> $dynamodb0
        $to_value->{last_updated} = $from_value->{last_updated};
    }
}

sub items {
    my ($self) = @_;

    my $human_items = {};

    my $items = $self->scan->{Items};
    my $primary_key_name = $self->primary_key;

    # convert $items to something more human readable
    for my $item (@$items) {
        my $primary_key = delete($item->{$primary_key_name})->{S};

        for my $attr (keys %$item) {
            my $type_value = $item->{$attr};
            my ($type) = keys %$type_value;
            $human_items->{$primary_key}->{$attr} = $item->{$attr}->{$type};
        }

        # inflate json values
        my $new_item                 = $human_items->{$primary_key};
        my %inflated_item            = $self->inflate(%$new_item);
        $human_items->{$primary_key} = \%inflated_item;

        delete $human_items->{$primary_key}
            if $human_items->{$primary_key}->{deleted};
    }

    return %$human_items;
}

sub keys {
    my ($self) = @_;
    my %items = $self->items;
    return keys %items;
}

1;
__END__

=head1 ACKNOWLEDGEMENTS

Thanks to L<DuckDuckGo|http://duckduckgo.com> for making this module possible by donating developer time.

=head1 LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Eric Johnson E<lt>eric.git@iijo.orgE<gt>

=cut

