# NAME

Amazon::DynamoDB::Simple - Simple to use and highly available

# SYNOPSIS

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

# DESCRIPTION

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

# DATA REDUNDANCY

TODO

# ACKNOWLEDGEMENTS

Thanks to [DuckDuckGo](http://duckduckgo.com) for making this module possible by donating developer time.

# LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Eric Johnson <eric.git@iijo.org>
