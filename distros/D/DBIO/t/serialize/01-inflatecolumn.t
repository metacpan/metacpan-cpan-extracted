use strict;
use warnings;

use Test::More;
use Test::Exception;
use Scalar::Util qw(blessed reftype);

use DBIO::InflateColumn::Serializer;
use DBIO::InflateColumn::Serializer::JSON;
use DBIO::InflateColumn::Serializer::YAML;
use DBIO::InflateColumn::Serializer::MessagePack;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Build a freezer/unfreezer pair for a backend by directly invoking the
# backend's get_freezer / get_unfreezer, exactly as register_column would
# have done at column-registration time. This stays at the unit level
# (no real DB) per the core "mock only" rule.
sub backend_pair {
    my ($backend_class, %info) = @_;
    $info{serializer_class} = $backend_class; # kept for parity; not used by backends
    my $freezer   = $backend_class->get_freezer('col', \%info, {});
    my $unfreezer = $backend_class->get_unfreezer('col', \%info, {});
    return ($freezer, $unfreezer);
}

# Round-trip helper: encode $value with the freezer, decode with the
# unfreezer, return ($encoded, $decoded). For binary backends (MessagePack)
# the encoded payload is bytes, not text.
sub round_trip {
    my ($freezer, $unfreezer, $value) = @_;
    my $encoded = $freezer->($value);
    my $decoded = $unfreezer->($encoded);
    return ($encoded, $decoded);
}

# Shared fixtures
my $simple   = { name => 'Caterwauler McCrae', rank => 13 };
my $nested   = { a => 1, b => [1, 2, 3], c => { d => 'e' } };
my $arrayref = [1, 2, 3];

# ---------------------------------------------------------------------------
# JSON backend
# ---------------------------------------------------------------------------

subtest 'JSON backend' => sub {
    lives_ok {
        eval { require JSON::MaybeXS; 1 } or die "JSON::MaybeXS required";
    } 'JSON::MaybeXS is loadable';

    my ($freezer, $unfreezer) = backend_pair('DBIO::InflateColumn::Serializer::JSON');

    # 1. Simple hashref round-trip
    {
        my ($enc, $dec) = round_trip($freezer, $unfreezer, $simple);
        is(ref($enc), '', 'JSON simple: encoded payload is a string');
        like($enc, qr/"name"/, 'JSON simple: encoded payload contains "name" key');
        is_deeply($dec, $simple, 'JSON simple: round-trip yields equivalent hashref');
    }

    # 2. Nested round-trip
    {
        my ($enc, $dec) = round_trip($freezer, $unfreezer, $nested);
        is_deeply($dec, $nested, 'JSON nested: round-trip yields equivalent nested structure');
    }

    # 3. Arrayref round-trip
    {
        my ($enc, $dec) = round_trip($freezer, $unfreezer, $arrayref);
        is(reftype($dec), 'ARRAY', 'JSON arrayref: decoded value is an arrayref');
        is_deeply($dec, $arrayref, 'JSON arrayref: round-trip yields equivalent arrayref');
    }

    # 4. Undef round-trip — JSON::MaybeXS rejects non-refs by default;
    #    build a dedicated freezer with allow_nonref => 1. The standard
    #    freezer (no options) would die with "hash- or arrayref expected".
    {
        my ($anon_freezer, $anon_unfreezer) = backend_pair(
            'DBIO::InflateColumn::Serializer::JSON',
            serializer_options => { allow_nonref => 1 },
        );
        my ($enc, $dec) = round_trip($anon_freezer, $anon_unfreezer, undef);
        is($enc, 'null', 'JSON undef: encodes to literal "null"');
        ok(!defined($dec), 'JSON undef: decode round-trips to undef');
    }

    # 6. Size overflow throws
    {
        my ($small_freezer) = backend_pair(
            'DBIO::InflateColumn::Serializer::JSON',
            size => 4,
        );
        throws_ok { $small_freezer->($simple) }
            qr/serialization too big/i,
            'JSON: size overflow throws "serialization too big"';
    }
};

# ---------------------------------------------------------------------------
# YAML backend
# ---------------------------------------------------------------------------

subtest 'YAML backend' => sub {
    SKIP: {
        eval { require YAML; 1 }
            or skip "YAML not available: $@", 10;

        my ($freezer, $unfreezer) = backend_pair('DBIO::InflateColumn::Serializer::YAML');

        # 1. Simple hashref round-trip
        {
            my ($enc, $dec) = round_trip($freezer, $unfreezer, $simple);
            like($enc, qr/name:\s*Caterwauler/, 'YAML simple: encoded payload looks like YAML');
            is_deeply($dec, $simple, 'YAML simple: round-trip yields equivalent hashref');
        }

        # 2. Nested round-trip
        {
            my ($enc, $dec) = round_trip($freezer, $unfreezer, $nested);
            is_deeply($dec, $nested, 'YAML nested: round-trip yields equivalent nested structure');
        }

        # 3. Arrayref round-trip
        {
            my ($enc, $dec) = round_trip($freezer, $unfreezer, $arrayref);
            is(reftype($dec), 'ARRAY', 'YAML arrayref: decoded value is an arrayref');
            is_deeply($dec, $arrayref, 'YAML arrayref: round-trip yields equivalent arrayref');
        }

        # 4. Undef round-trip — YAML::Dump(undef) yields the empty string;
        #    YAML::Load("") yields undef. Document the actual behaviour.
        {
            my ($enc, $dec) = round_trip($freezer, $unfreezer, undef);
            ok(!defined($dec), 'YAML undef: decode round-trips to undef');
        }

        # 5. YAML safety: decode result is a plain (unblessed) hashref, and
        #    the source file uses YAML::Load (not LoadFile or similar).
        {
            my $dec = $unfreezer->("name: foo\nrank: 13\n");
            is(ref($dec), 'HASH', 'YAML safety: decoded scalar doc is a hashref');
            ok(!blessed($dec),
                'YAML safety: decoded value is not blessed (F04 risk-surface: LoadBlessed off)');

            my $src = _read_source(
                'DBIO::InflateColumn::Serializer::YAML',
                '/storage/raid/home/getty/dev/perl/dbio-dev/dbio/lib/DBIO/InflateColumn/Serializer/YAML.pm',
            );
            like($src, qr/\bYAML::Load\b/,
                'YAML safety: source uses YAML::Load (not LoadFile / LoadString)');
            unlike($src, qr/\bYAML::LoadFile\b/,
                'YAML safety: source does NOT use YAML::LoadFile');
        }

        # 6. Size overflow throws
        {
            my ($small_freezer) = backend_pair(
                'DBIO::InflateColumn::Serializer::YAML',
                size => 4,
            );
            throws_ok { $small_freezer->($simple) }
                qr/serialization too big/i,
                'YAML: size overflow throws "serialization too big"';
        }
    }
};

# ---------------------------------------------------------------------------
# MessagePack backend
# ---------------------------------------------------------------------------

subtest 'MessagePack backend' => sub {
    SKIP: {
        eval { require Data::MessagePack; 1 }
            or skip "Data::MessagePack not available: $@", 7;

        my ($freezer, $unfreezer) = backend_pair('DBIO::InflateColumn::Serializer::MessagePack');

        # 1. Simple hashref round-trip (payload is binary)
        {
            my ($enc, $dec) = round_trip($freezer, $unfreezer, $simple);
            ok(length($enc) > 0, 'MessagePack simple: encoded payload is non-empty bytes');
            is_deeply($dec, $simple, 'MessagePack simple: round-trip yields equivalent hashref');
        }

        # 2. Nested round-trip
        {
            my ($enc, $dec) = round_trip($freezer, $unfreezer, $nested);
            is_deeply($dec, $nested, 'MessagePack nested: round-trip yields equivalent nested structure');
        }

        # 3. Arrayref round-trip
        {
            my ($enc, $dec) = round_trip($freezer, $unfreezer, $arrayref);
            is(reftype($dec), 'ARRAY', 'MessagePack arrayref: decoded value is an arrayref');
            is_deeply($dec, $arrayref, 'MessagePack arrayref: round-trip yields equivalent arrayref');
        }

        # 4. Undef round-trip — Data::MessagePack encodes undef as the
        #    nil marker and decodes it back to Perl undef.
        {
            my ($enc, $dec) = round_trip($freezer, $unfreezer, undef);
            ok(!defined($dec), 'MessagePack undef: decode round-trips to undef');
        }

        # 6. Size overflow throws
        {
            my ($small_freezer) = backend_pair(
                'DBIO::InflateColumn::Serializer::MessagePack',
                size => 4,
            );
            throws_ok { $small_freezer->($simple) }
                qr/serialization too big/i,
                'MessagePack: size overflow throws "serialization too big"';
        }
    }
};

# ---------------------------------------------------------------------------
# Unknown backend — register_column path
# ---------------------------------------------------------------------------

# Build a minimal Result class with the InflateColumn::Serializer component
# loaded, attach a column whose serializer_class has no matching backend,
# and assert that the resulting error names the missing backend. We do NOT
# need real storage for this — DBIO::Test::Storage (mock only) per CLAUDE.md.
subtest 'Unknown backend throws with clear message' => sub {
    eval { require DBIO::Test::Storage; 1 } or BAIL_OUT("DBIO::Test::Storage required");

    # The exception is thrown synchronously from inside add_columns (via
    # InflateColumn::Serializer::register_column), so we must eval the
    # column declaration itself — not a downstream call. Package blocks
    # do not trap die, only eval does.
    my $err;
    {
        package _SerializerUnknown::Schema;
        use base 'DBIO::Schema';
    }
    {
        package _SerializerUnknown::Schema::Result::Row;
        use base 'DBIO::Core';
        __PACKAGE__->load_components(qw/InflateColumn::Serializer/);
        __PACKAGE__->table('row');
        eval {
            __PACKAGE__->add_columns(
                id => { data_type => 'integer', is_auto_increment => 1 },
                payload => {
                    data_type         => 'varchar',
                    size              => 255,
                    serializer_class  => 'TotallyMadeUpBackend',
                },
            );
            __PACKAGE__->set_primary_key('id');
        };
        $err = $@;
    }

    like(
        $err,
        qr/Failed to use serializer_class 'DBIO::InflateColumn::Serializer::TotallyMadeUpBackend'/i,
        'unknown serializer_class: add_columns throws a clear "Failed to use serializer_class ..." error',
    );
};

done_testing;

# ---------------------------------------------------------------------------
# Tiny helper: read the source file for a given module, falling back to the
# absolute path passed in $_[1]. We prefer %INC so the test is hermetic and
# does not depend on the lib path of whoever is running prove.
# ---------------------------------------------------------------------------
sub _read_source {
    my ($module, $fallback) = @_;
    my $path = $INC{$module} || $INC{$module . '.pm'} || $fallback;
    open my $fh, '<', $path or return '';
    local $/;
    my $src = <$fh>;
    close $fh;
    return $src // '';
}
