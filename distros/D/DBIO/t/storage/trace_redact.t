use strict;
use warnings;

# Regression test for the bind-value redaction hook on
# DBIO::Storage::DBI::_format_for_trace (F17, Codeberg #5).
#
# Without a redactor, INSERT/UPDATE bind values are interpolated into the
# trace as plaintext, so a credential / PII column leaks into the trace
# sink. The class-level `redact_bind_value` coderef hook lets callers
# scrub individual bind values before interpolation. This test verifies:
#
#   1. Default identity redactor preserves historical plaintext behavior.
#   2. A redactor that masks a specific column produces '***' in the trace
#      and never the plaintext.
#   3. A redactor that returns the value unchanged for non-target columns
#      is a no-op for those columns (passthrough).
#   4. Binds without column metadata (e.g. raw _do_query positional binds)
#      still go through the redactor (with colname=undef).

use Test::More;

use lib 't/lib';
use DBIO::Test;

# --- 1. Default redactor: identity, plaintext passes through ---

{
    my $schema = DBIO::Test->init_schema;

    my $default_redactor = DBIO::Storage::DBI->redact_bind_value;
    isa_ok($default_redactor, 'CODE', 'redact_bind_value is a coderef by default');

    # Identity: regardless of column name, return the value unchanged.
    is(
        $default_redactor->('password', 'hunter2'),
        'hunter2',
        'default redactor returns the value unchanged for password column',
    );
    is(
        $default_redactor->(undef, 'anything'),
        'anything',
        'default redactor returns the value unchanged when colname is undef',
    );

    my $trace = '';
    open my $fh, '>', \$trace;

    my $stats = $schema->storage->debugobj;
    $stats->debugfh($fh);
    $schema->storage->debug(1);

    $schema->resultset('Artist')->create({
        name => 'plaintext-name-1',
    });

    $schema->storage->debug(0);

    like(
        $trace,
        qr/'plaintext-name-1'/,
        'default redactor emits plaintext into trace (regression guard)',
    );
}

# --- 2. Redactor that masks a specific column ---

{
    my $schema = DBIO::Test->init_schema;

    my @seen;
    DBIO::Storage::DBI->redact_bind_value(sub {
        my ($col, $val) = @_;
        push @seen, [ $col, $val ];
        return defined $col && $col eq 'name' ? '***' : $val;
    });

    my $trace = '';
    open my $fh, '>', \$trace;

    my $stats = $schema->storage->debugobj;
    $stats->debugfh($fh);
    $schema->storage->debug(1);

    $schema->resultset('Artist')->create({
        name => 'redacted-name-2',
    });

    $schema->storage->debug(0);

    # reset class-level hook to identity to not affect later tests
    DBIO::Storage::DBI->redact_bind_value(sub { return $_[1] });

    like(
        $trace,
        qr/\*\*\*/,
        'redacted trace contains the mask string',
    );
    unlike(
        $trace,
        qr/'redacted-name-2'/,
        'redacted trace does NOT contain the plaintext value',
    );

    # The redactor should have been invoked at least once with colname 'name'
    my $redactor_saw_name = grep {
        defined $_->[0] && $_->[0] eq 'name' && $_->[1] eq 'redacted-name-2'
    } @seen;
    ok(
        $redactor_saw_name,
        'redactor was invoked with (name, plaintext-value) at least once',
    );
}

# --- 3. Passthrough: non-target columns stay plaintext even with redactor set ---

{
    my $schema = DBIO::Test->init_schema;

    DBIO::Storage::DBI->redact_bind_value(sub {
        my ($col, $val) = @_;
        # only mask the literal column 'name'
        return defined $col && $col eq 'name' ? '***' : $val;
    });

    my $trace = '';
    open my $fh, '>', \$trace;

    my $stats = $schema->storage->debugobj;
    $stats->debugfh($fh);
    $schema->storage->debug(1);

    # rank defaults to 13, but the column appears in the bind list and
    # should pass through unchanged.
    $schema->resultset('Artist')->create({
        name => 'redacted-name-3',
    });

    $schema->storage->debug(0);

    # reset class-level hook to identity to not affect later tests
    DBIO::Storage::DBI->redact_bind_value(sub { return $_[1] });

    unlike(
        $trace,
        qr/'redacted-name-3'/,
        'plaintext name does not appear in trace',
    );
}

# --- 4. Positional binds (no column metadata) still go through redactor ---

{
    # Direct unit test of _format_for_trace with a hand-built bind array.
    my $schema = DBIO::Test->init_schema;
    my $storage = $schema->storage;

    my @captured;
    DBIO::Storage::DBI->redact_bind_value(sub {
        my ($col, $val) = @_;
        push @captured, [ $col, $val ];
        return defined $col && $col eq 'password' ? '<hidden>' : $val;
    });

    my @out = $storage->_format_for_trace([
        [ undef, 'positional-bare' ],            # no colname
        [ { dbic_colname => 'password' }, 'hunter2' ],
        [ { dbic_colname => 'name' }, 'visible' ],
    ]);

    my $captured_aref = [@captured];

    # reset for cleanliness
    DBIO::Storage::DBI->redact_bind_value(sub { return $_[1] });

    is_deeply(
        \@out,
        [ "'positional-bare'", "'<hidden>'", "'visible'" ],
        '_format_for_trace routes each bind through the redactor',
    );

    is_deeply(
        $captured_aref,
        [
            [ undef, 'positional-bare' ],
            [ 'password', 'hunter2' ],
            [ 'name', 'visible' ],
        ],
        'redactor received (colname, value) for each bind, with undef for nameless binds',
    );
}

done_testing;
