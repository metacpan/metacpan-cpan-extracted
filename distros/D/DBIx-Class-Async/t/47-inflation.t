#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw( tempfile );
use JSON::MaybeXS;
use DateTime;

use lib 't/lib';
use IO::Async::Loop;
use DBIx::Class::Async;

my (undef, $filename) = tempfile(UNLINK => 1);
my $loop = IO::Async::Loop->new;
my $json = JSON::MaybeXS->new(utf8 => 1, sort_by => 1);

my $db = DBIx::Class::Async->new(
    schema_class => 'TestSchema',
    connect_info => ["dbi:SQLite:dbname=$filename", '', ''],
    loop         => $loop,
);

# 1. JSON Inflation & Deflation
$db->inflate_column('Product', 'metadata', {
    inflate => sub {
        my $val = shift;
        return {} unless defined $val;

        return $val if ref $val;

        # If it's a string, try to decode it
        if ($val !~ /^HASH\(0x/) {
            my $decoded = eval { $json->decode($val) };
            return $decoded if $decoded;
        }

        # If we got here, it's bad JSON
        return {};
    },
    deflate => sub {
        my $hashref = shift;
        return undef unless defined $hashref;
        # Turn the HashRef back into a JSON string for the DB
        return ref($hashref) ? $json->encode($hashref) : $hashref;
    },
});

# 2. Register DateTime Inflation
$db->inflate_column('Product', 'created_at', {
    inflate => sub {
        my $raw = shift;
        return undef unless $raw;
        if ($raw =~ /^(\d{4})-(\d{2})-(\d{2})\s(\d{2}):(\d{2}):(\d{2})$/) {
            return DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6);
        }
        return $raw;
    },
    deflate => sub {
        my $dt = shift;
        return undef unless $dt;
        return ref($dt) ? $dt->strftime('%Y-%m-%d %H:%M:%S') : $dt;
    },
});

my $now = DateTime->now(time_zone => 'UTC');
$now->set_nanosecond(0);

my $test = $db->deploy->then(sub {
    # 3. Create Product with complex objects
    return $db->create('Product', {
        name       => 'Async Phone',
        sku        => 'ASYNC-PH-001',
        metadata   => { color => 'blue', tags => ['tech', 'mobile'] },
        created_at => $now,
    });
})->then(sub {
    my $row = shift;

    # 4. Verify JSON Inflation
    my $metadata = $row->metadata;
    is( ref($metadata), 'HASH', 'Metadata inflated to HashRef' );
    is( $metadata->{color}, 'blue', 'JSON data preserved' );

    # 5. Verify DateTime Inflation
    isa_ok($row->created_at, 'DateTime');
    is($row->created_at->iso8601, $now->iso8601, "DateTime round-trip match");

    # Check internal storage format
    is($row->{_data}{created_at}, $now->strftime('%Y-%m-%d %H:%M:%S'), "Internal date is raw string");

    # 6. Test Update with objects
    my $meta = $row->metadata;
    $meta->{in_stock} = 1;

    # We set the column with a new HashRef
    $row->metadata($meta);
    $row->created_at($now->clone->add(days => 1));

    return $row->update;
})->then(sub {
    my $row = shift;
    # Ensure the update didn't crash and returned the object
    return $db->find('Product', $row->id);
})->then(sub {
    my $fresh = shift;

    # 7. Final Assertions
    is(ref($fresh->metadata), 'HASH', 'Fresh metadata is HASH');
    is($fresh->metadata->{in_stock}, 1, "Updated JSON persists");
    is($fresh->created_at->day, $now->day + 1, "Updated DateTime persists");

    $loop->stop;
    return Future->done;
})->on_fail(sub {
    diag "Complex Inflation Fail: @_";
    $loop->stop;
});

$loop->run;
done_testing;
