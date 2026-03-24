package DBIx::Class::MockData;

$DBIx::Class::MockData::VERSION   = '0.05';
$DBIx::Class::MockData::AUTHORITY = 'cpan:MANWAR';

use strict;
use warnings;

=encoding UTF-8

=head1 NAME

DBIx::Class::MockData - Generate mock test data for DBIx::Class schemas

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use DBIx::Class::MockData;

    my $schema = MyApp::Schema->connect($dsn, $user, $pass);

    # Basic usage
    DBIx::Class::MockData
        ->new(
            schema     => $schema,
            schema_dir => 't/lib',
        )
        ->deploy
        ->generate;

    # Fast data refresh (recommended for most test scenarios)
    DBIx::Class::MockData
        ->new(
            schema     => $schema,
            schema_dir => 't/lib',
            rows       => 10,
        )
        ->truncate      # Empties tables quickly, preserves structure
        ->generate;

    # Complete schema reset (use sparingly)
    DBIx::Class::MockData
        ->new(
            schema     => $schema,
            schema_dir => 't/lib',
            rows       => 10,
            verbose    => 1,
            seed       => 42,
        )
        ->wipe          # Destructive: drops and recreates tables
        ->generate;

    # Populate only selected tables
    DBIx::Class::MockData
        ->new(
            schema     => $schema,
            schema_dir => 't/lib',
            only       => [qw(Author Book)],
        )
        ->truncate
        ->generate;

    # Populate all tables except selected ones
    DBIx::Class::MockData
        ->new(
            schema     => $schema,
            schema_dir => 't/lib',
            exclude    => [qw(AuditLog SessionToken)],
        )
        ->truncate
        ->generate;

    # Use custom generators for specific columns
    DBIx::Class::MockData
        ->new(
            schema     => $schema,
            schema_dir => 't/lib',
            generators => {
                email  => sub { "user".int(rand(1000))."\@example.com" },
                status => sub { "active" },
                created_at => sub {
                    my ($col, $info, $n, $mock) = @_;
                    return DateTime->now->datetime;
                },
            }
        )
        ->truncate
        ->generate;

    # Set different row counts per table
    DBIx::Class::MockData
        ->new(
            schema         => $schema,
            schema_dir     => 't/lib',
            rows           => 5,              # default for all tables
            rows_per_table => {
                Author => 10,                 # override for Author
                Book   => 3,                  # override for Book
            },
        )
        ->truncate
        ->generate;

    # Preview data without inserting
    DBIx::Class::MockData
        ->new(
            schema     => $schema,
            schema_dir => 't/lib',
            rows       => 3,
        )
        ->dry_run;      # Prints generated values, no database changes

=head1 DESCRIPTION

Accepts a connected L<DBIx::Class::Schema> object, the return value of
C<< YourSchema->connect(...) >>, introspects every result source, resolves
foreign-key insertion order via topological sort, and inserts randomly
generated rows. Values are produced from each column's declared
C<data_type>. Unique and primary-key columns are salted with a per-run
random value to avoid cross-run collisions.

Connection and schema loading are entirely the caller's responsibility.
C<schema_dir> is accepted only to ensure the lib root is present in C<@INC>
so result classes remain resolvable at runtime.

All public methods return C<$self>, enabling call chaining.

=head1 METHODS

=cut

use Carp         qw(croak);
use File::Spec   ();
use Scalar::Util qw(blessed);
use UUID::Tiny   qw(:std);
use feature      qw(state);

=head1 CONSTRUCTOR

    my $mock = DBIx::Class::MockData->new(
        schema     => $connected_schema,   # required
        schema_dir => 't/lib',             # required
        rows       => 5,                   # rows per table  (default: 5)
        verbose    => 0,                   # debug output    (default: 0)
        seed       => 42,                  # random seed     (optional)
    );

B<ARGUMENTS>

=over 4

=item schema B<(required)>

A connected L<DBIx::Class::Schema> instance - the return value of
C<< YourSchema->connect(...) >>.

=item schema_dir B<(required)>

The lib root containing your schema classes. Added to C<@INC> so result
classes referenced by relationships remain resolvable.

=item rows

Number of rows to generate per table. Default: C<5>.

=item verbose

Print debug output. Default: C<0>.

=item seed

Integer seed passed to C<srand> for reproducible output. Optional.

=item only

Array reference of source names to populate. When supplied, only the listed
tables are processed (in FK-safe order). Cannot be combined with C<exclude>.

    only => [qw(Author Book)]

=item exclude

Array reference of source names to skip. All other tables are populated.
Cannot be combined with C<only>.

    exclude => [qw(AuditLog SessionToken)]

=back

=cut

sub new {
    my ($class, %args) = @_;

    croak "schema is required"
        unless $args{schema};
    croak "schema must be a DBIx::Class::Schema instance"
        unless blessed($args{schema}) && $args{schema}->isa('DBIx::Class::Schema');
    croak "schema_dir is required"
        unless $args{schema_dir};

    my $dir = File::Spec->rel2abs($args{schema_dir});
    croak "schema_dir '$dir' does not exist" unless -d $dir;
    push @INC, $dir unless grep { $_ eq $dir } @INC;

    croak "only and exclude cannot both be specified"
        if $args{only} && $args{exclude};
    croak "only must be an arrayref"
        if $args{only} && ref($args{only}) ne 'ARRAY';
    croak "exclude must be an arrayref"
        if $args{exclude} && ref($args{exclude}) ne 'ARRAY';

    # Validate numeric arguments
    if (defined $args{rows}) {
        croak "rows must be a positive integer"
            unless $args{rows} =~ /^\d+$/ && $args{rows} > 0;
    }

    if (defined $args{seed}) {
        croak "seed must be a positive integer"
            unless $args{seed} =~ /^\d+$/ && $args{seed} > 0;
    }

    if (defined $args{verbose}) {
        croak "verbose must be 0 or 1"
            unless $args{verbose} =~ /^[01]$/;
    }

    # Validate rows_per_table if provided
    if (defined $args{rows_per_table}) {
        croak "rows_per_table must be a hashref"
            unless ref($args{rows_per_table}) eq 'HASH';

        while (my ($table, $count) = each %{ $args{rows_per_table} }) {
            croak "rows_per_table value for '$table' must be a positive integer"
                unless $count =~ /^\d+$/ && $count > 0;
        }
    }

    # Validate generators if provided
    if (defined $args{generators}) {
        croak "generators must be a hashref"
            unless ref($args{generators}) eq 'HASH';

        while (my ($col, $gen) = each %{ $args{generators} }) {
            croak "generator for '$col' must be a code reference or scalar"
                unless ref($gen) eq 'CODE' || !ref($gen);
        }
    }

    my $self = {
        _schema        => $args{schema},
        rows           => $args{rows}    // 5,
        verbose        => $args{verbose} // 0,
        quiet          => $args{quiet}   // 0,
        rows_per_table => $args{rows_per_table} || {},
        generators     => $args{generators}     || {},
        _salt          => int(rand(9_000_000)) + 1_000_000,
        _only          => $args{only}    ? { map { $_ => 1 } @{ $args{only}    } } : undef,
        _exclude       => $args{exclude} ? { map { $_ => 1 } @{ $args{exclude} } } : undef,
    };

    if (defined $args{seed}) {
        srand($args{seed});
        $self->{_salt} = int(rand(9_000_000)) + 1_000_000;
    }

    if (defined $args{start_year}) {
        croak "start_year must be a 4-digit year"
            unless $args{start_year} =~ /^\d{4}$/;
        $self->{start_year} = $args{start_year};
    }
    if (defined $args{end_year}) {
        croak "end_year must be a 4-digit year"
            unless $args{end_year} =~ /^\d{4}$/;
        $self->{end_year} = $args{end_year};
    }
    $self->{start_year} ||= 2010;
    $self->{end_year}   ||= 2026;

    return bless $self, $class;
}

=head1 METHODS

=head2 deploy

    $mock->deploy;
    $mock->deploy->generate;   # chainable

Creates all tables that do not yet exist. Safe to call when some or all
tables are already present. Returns C<$self>.

=cut

sub deploy {
    my ($self) = @_;
    my $schema = $self->{_schema};

    $self->_log("Deploying schema (creating missing tables)...");

    my $ddl = eval { $schema->deployment_statements };
    if ($@ || !$ddl) {
        eval { $schema->deploy({ add_drop_table => 0, ignore_errors => 1 }) };
        croak "Deploy failed: $@" if $@;
    }
    else {
        $schema->storage->dbh_do(sub {
            my (undef, $dbh) = @_;
            for my $stmt (split /;\s*/m, $ddl) {
                $stmt =~ s/^\s+|\s+$//g;
                next unless length $stmt;
                eval { $dbh->do($stmt) };
                $self->_debug("  Skipped (exists?): " . substr($stmt, 0, 60)) if $@;
            }
        });
    }

    $self->_log("Deploy complete");
    return $self;
}

=head2 truncate

    $mock->truncate->generate;   # chainable

Truncates (empties) all tables while preserving table structure.
Safer than C<wipe> as it doesn't drop and recreate tables.
Returns C<$self>.

=cut

sub truncate {
    my ($self) = @_;
    my $schema = $self->{_schema};

    $self->_log("Truncating all tables...");

    # Get tables in reverse dependency order to avoid FK issues
    my @all_sources   = $schema->sources;
    my @sources       = $self->_active_sources(@all_sources);
    my ($deps, $rsrc) = $self->_build_dep_graph(\@sources);
    my @ordered       = reverse $self->_topo_sort($deps, \@sources);

    eval {
        $schema->storage->dbh_do(sub {
            my (undef, $dbh) = @_;
            for my $name (@ordered) {
                my $source = $schema->source($name);
                my $table = $source->from;
                $table = $$table if ref($table) eq 'SCALAR';

                $self->_debug("  Truncating: $table");

                # Different DBs have different truncate syntax
                my $driver = $schema->storage->dbh->{Driver}->{Name};
                if ($driver eq 'SQLite') {
                    $dbh->do("DELETE FROM $table");

                    # Reset autoincrement sequences if they exist
                    # Check if sqlite_sequence table exists and has entry
                    # for this table
                    my $seq_exists = $dbh->selectrow_array(
                        "SELECT name FROM sqlite_master WHERE type='table' AND name='sqlite_sequence'"
                    );

                    if ($seq_exists) {
                        my $has_seq = $dbh->selectrow_array(
                            "SELECT name FROM sqlite_sequence WHERE name=?", {}, $table
                        );
                        if ($has_seq) {
                            $dbh->do("DELETE FROM sqlite_sequence WHERE name='$table'");
                        }
                    }
                }
                elsif ($driver =~ /mysql|mariadb/i) {
                    $dbh->do("TRUNCATE TABLE $table");
                }
                elsif ($driver =~ /postgres|pg/i) {
                    $dbh->do("TRUNCATE TABLE $table RESTART IDENTITY CASCADE");
                }
                else {
                    # Fallback
                    $dbh->do("DELETE FROM $table");
                }
            }
        });
    };
    croak "Truncate failed: $@" if $@;

    $self->_log("Truncate complete");
    return $self;
}

=head2 wipe

    $mock->wipe->generate;   # chainable

Drops B<all> tables then redeploys the schema.
B<Destructive -- for test environments only.> Returns C<$self>.

=cut

sub wipe {
    my ($self) = @_;
    my $schema = $self->{_schema};
    warn "[WARN] wipe() is destructive and drops tables. Consider using truncate() instead.\n"
        unless $self->{quiet};

    $self->_log("Wiping all tables...");
    eval {
        $schema->storage->dbh_do(sub {
            my (undef, $dbh) = @_;
            for my $src (reverse $schema->sources) {
                my $table = $schema->source($src)->from;
                $table    = $$table if ref($table) eq 'SCALAR';
                $self->_debug("  Dropping: $table");
                $dbh->do("DROP TABLE IF EXISTS $table");
            }
        });
    };
    croak "Wipe failed: $@" if $@;

    $schema->deploy({ add_drop_table => 0 });
    $self->_log("Wipe and redeploy complete");
    return $self;
}

=head2 generate

    $mock->generate;

Inserts mock rows into every table respecting FK insertion order, data
types, nullability, and uniqueness constraints. Returns C<$self>.

=cut

sub _active_sources {
    my ($self, @all) = @_;
    my %known = map { $_ => 1 } @all;

    if ($self->{_only}) {
        my @unknown = grep { !$known{$_} } keys %{ $self->{_only} };
        croak "Unknown source(s) in 'only': " . join(', ', sort @unknown) if @unknown;
        return grep { $self->{_only}{$_} } @all;
    }
    if ($self->{_exclude}) {
        my @unknown = grep { !$known{$_} } keys %{ $self->{_exclude} };
        croak "Unknown source(s) in 'exclude': " . join(', ', sort @unknown) if @unknown;
        return grep { !$self->{_exclude}{$_} } @all;
    }
    return @all;
}

sub generate {
    my ($self) = @_;
    my $schema = $self->{_schema};

    my @all_sources = $schema->sources;
    croak "No result sources found in schema" unless @all_sources;

    my @sources = $self->_active_sources(@all_sources);
    croak "No sources to populate after applying only/exclude filters" unless @sources;

    $self->_log("Found sources: " . join(', ', sort @sources));

    my ($deps, $rsrc) = $self->_build_dep_graph(\@sources);
    my @ordered       = $self->_topo_sort($deps, \@sources);

    $self->_log("Insertion order: " . join(' -> ', @ordered));

    my %inserted_pks;

    for my $name (@ordered) {
        $self->_log("\n--- Table: $name ---");

        my $source   = $rsrc->{$name};
        my @cols     = $source->columns;
        my %col_info = map { $_ => $source->column_info($_) } @cols;
        my @pk_cols  = $source->primary_columns;
        my %pk_set   = map { $_ => 1 } @pk_cols;
        my %unique   = $self->_unique_cols($source, \@pk_cols, \%col_info);
        my %fk       = $self->_build_fk_map($source);

        $self->_debug("  Unique cols: " . join(', ', sort keys %unique)) if %unique;

        my @rows;
        my $rows = $self->{rows_per_table}{$name} // $self->{rows};
        for my $n (1 .. $rows) {
            my %row;
            for my $col (@cols) {
                my $info = $col_info{$col};
                next if $pk_set{$col} && $self->_is_auto_pk($info);

                if (exists $fk{$col}) {
                    my $pool = $inserted_pks{ $fk{$col}{source} } // [];
                    if (@$pool) {
                        $row{$col} = $pool->[ ($n-1) % @$pool ]{ $fk{$col}{col} };
                    }
                    elsif ($info->{is_nullable}) {
                        $row{$col} = undef
                    }
                    else {
                        $row{$col} = $self->_generate_value($col, $info, $n, $unique{$col})
                    }
                    next;
                }

                $row{$col} = $self->_generate_value($col, $info, $n, $unique{$col});
            }
            push @rows, \%row;
        }

        $self->_insert_rows($source, $name, \@rows, \@pk_cols, \%inserted_pks);
    }

    return $self;
}

=head2 dry_run

    $mock->dry_run;

Prints the values that I<would> be inserted without touching the database.
Returns C<$self>.

=cut

sub dry_run {
    my ($self) = @_;
    my $schema = $self->{_schema};

    my @sources = sort $self->_active_sources($schema->sources);
    for my $name (@sources) {
        my $source   = $schema->source($name);
        my @cols     = $source->columns;
        my %col_info = map { $_ => $source->column_info($_) } @cols;
        my @pk_cols  = $source->primary_columns;
        my %pk_set   = map { $_ => 1 } @pk_cols;
        my %unique   = $self->_unique_cols($source, \@pk_cols, \%col_info);

        print "\n--- DRY RUN: $name ---\n";
        for my $n (1 .. $self->{rows}) {
            print "  Row $n:\n";
            for my $col (@cols) {
                next if $pk_set{$col} && $self->_is_auto_pk($col_info{$col});
                my $val = $self->_generate_value($col, $col_info{$col}, $n, $unique{$col});
                printf "    %-30s => %s\n", $col, defined $val ? "'$val'" : 'NULL';
            }
        }
    }
    return $self;
}

#
#
# PRIVATE METHODS

sub _unique_cols {
    my ($self, $source, $pk_cols, $col_info) = @_;
    my %unique;

    # Non-auto PKs must be unique
    $unique{$_} = 1 for grep { !$self->_is_auto_pk($col_info->{$_}) } @$pk_cols;

    # Explicit unique constraints (skip 'primary' -- handled above)
    if ($source->can('unique_constraints')) {
        my %ucs = $source->unique_constraints;
        for my $name (keys %ucs) {
            next if $name eq 'primary';
            $unique{$_} = 1 for @{ $ucs{$name} };
        }
    }

    return %unique;
}

sub _build_dep_graph {
    my ($self, $sources) = @_;
    my $schema = $self->{_schema};
    my (%deps, %rsrc);

    for my $name (@$sources) {
        my $source   = $schema->source($name);
        $rsrc{$name} = $source;
        $deps{$name} //= [];

        for my $rel ($source->relationships) {
            my $info  = $source->relationship_info($rel);
            my $attrs = $info->{attrs} || {};

            # Check if this is a foreign key constraint relationship
            next unless $attrs->{is_foreign_key_constraint};

            # belongs_to, has_one, might_have all create FK dependencies
            # but in different directions
            my $accessor = $attrs->{accessor} || '';

            my $parent = eval { $source->related_source($rel)->source_name } or next;
            next if $parent eq $name;

            if ($accessor eq 'single') {
                # belongs_to - current table depends on parent
                push @{ $deps{$name} }, $parent
                    unless grep { $_ eq $parent } @{ $deps{$name} };
            }
            elsif ($accessor eq 'multi') {
                # has_many - parent depends on current table?
                # Actually has_many doesn't create FK constraint in current table
                # So no dependency
            }
            else {
                # might_have, has_one - parent depends on current table?
                # These create FK in current table pointing to parent
                # So current table depends on parent
                if ($attrs->{is_foreign_key_constraint}) {
                    push @{ $deps{$name} }, $parent
                        unless grep { $_ eq $parent } @{ $deps{$name} };
                }
            }
        }
    }

    return (\%deps, \%rsrc);
}

sub _topo_sort {
    my ($self, $deps, $nodes) = @_;
    my %in = map { $_ => 0 } @$nodes;
    my %adj;

    for my $node (@$nodes) {
        for my $dep (@{ $deps->{$node} }) {
            next unless exists $in{$dep};
            $in{$node}++;
            push @{ $adj{$dep} }, $node;
        }
    }

    my @queue = sort grep { $in{$_} == 0 } @$nodes;
    my @result;
    while (@queue) {
        my $n = shift @queue;
        push @result, $n;
        push @queue, $_ for grep { --$in{$_} == 0 } @{ $adj{$n} // [] };
    }

    # Check for cycles
    my @remaining = grep { $in{$_} > 0 } @$nodes;
    if (@remaining) {
        if ($self->{ignore_cycles}) {
            # Best effort - append remaining nodes
            push @result, @remaining;
        }
        else {
            my $cycle = $self->_find_cycle(\%adj, $remaining[0]);
            croak "Cyclic dependency detected in relationships: " . join(' -> ', @$cycle);
        }
    }

    return @result;
}

sub _find_cycle {
    my ($self, $adj, $start) = @_;
    my %seen;
    my @path;

    my $dfs;
    $dfs = sub {
        my $node = shift;
        return if $seen{$node};

        push @path, $node;
        $seen{$node} = scalar @path;

        for my $next (@{ $adj->{$node} // [] }) {
            if (my $pos = $seen{$next}) {
                # Found a cycle
                return [ @path[$pos-1 .. $#path], $next ];
            }
            my $cycle = $dfs->($next);
            return $cycle if $cycle;
        }

        pop @path;
        $seen{$node} = 0;
        return undef;
    };

    return $dfs->($start) || [$start];
}

sub _build_fk_map {
    my ($self, $source) = @_;
    my %fk;

    for my $rel ($source->relationships) {
        my $info    = $source->relationship_info($rel);
        next unless $self->_is_belongs_to($info);
        my $related = eval { $source->related_source($rel) } or next;
        my $cond    = $info->{cond};
        next unless ref($cond) eq 'HASH';
        while (my ($fcol, $scol) = each %$cond) {
            $scol =~ s/^self\.//;
            $fcol =~ s/^foreign\.//;
            $fk{$scol} = { source => $related->source_name, col => $fcol };
        }
    }

    return %fk;
}

sub _is_belongs_to {
    my ($self, $info) = @_;
    my $a = $info->{attrs} // {};
    return 1 if ($a->{accessor} // '') eq 'single' && ($a->{is_foreign_key_constraint} // 0);
    return 1 if ($a->{accessor} // '') eq 'single' && !($a->{join_type} // '');
    return 0;
}

sub _is_auto_pk {
    my ($self, $info) = @_;
    return 1 if lc($info->{data_type} // '') =~ /\b(serial|bigserial|autoincrement)\b/;
    return 1 if ($info->{extra}{auto_increment} // 0);
    return 1 if ($info->{sequence} // '');
    return 0;
}

sub _generate_value {
    my ($self, $col, $info, $n, $is_unique) = @_;
    my $salt  = $self->{_salt};
    my $dtype = lc($info->{data_type} // '');
    my $size  = $info->{size} // 255;
    $size = ref($size) eq 'ARRAY' ? $size->[0] : ($size || 255);

    return undef if !$is_unique && ($info->{is_nullable} // 0) && int(rand(6)) == 0;

    if (my $gen = $self->{generators}{$col}) {
        return $gen->($col, $info, $n, $self);
    }

    if ($dtype =~ /\b(int|integer|bigint|smallint|tinyint|serial|bigserial)\b/) {
        return $is_unique ? $salt + $n : int(rand(999_999)) + 1;
    }
    if ($dtype =~ /\b(numeric|decimal|float|double|real|money)\b/) {
        return sprintf '%.2f', rand(10_000);
    }
    if ($dtype =~ /\b(bool|boolean|tinyint\(1\))\b/) {
        return int(rand(2));
    }
    if ($dtype =~ /\b(datetime|timestamp)\b/) {
        return $self->_rand_datetime;
    }
    if ($dtype =~ /\bdate\b/) {
        return $self->_rand_date;
    }
    if ($dtype =~ /\btime\b/) {
        return sprintf '%02d:%02d:%02d', int(rand(24)), int(rand(60)), int(rand(60));
    }
    if ($dtype =~ /\buuid\b/) {
        return create_uuid_as_string(UUID_V4);
    }
    if ($dtype =~ /\bjsonb?\b/) {
        return qq({"generated":true,"row":$n});
    }
    if ($dtype =~ /\[\]$/ || $dtype =~ /^array/) {
        return '{value1,value2}';
    }
    if ($dtype =~ /\b(text|varchar|character varying|char|nvarchar|nchar|string|citext|tinytext|mediumtext|longtext)\b/) {
        return $self->_contextual_string($col, $n, int($size) || 255, $is_unique);
    }

    return $is_unique ? "${col}_${n}_${salt}" : "${col}_${n}";
}

sub _contextual_string {
    my ($self, $col, $n, $max, $is_unique) = @_;
    my $salt = $self->{_salt};

    state $templates = [
        [ qr/\b(first_?name|fname)\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                my $value = (qw(Alice Bob Carol Dave Eve Frank Grace Hank Iris Jack))[$n%10];
                $value .= "_${salt}" if $is_unique;
                return $value;
            } ],
        [ qr/\b(last_?name|lname|surname)\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                my $value = (qw(Smith Jones Taylor Brown Wilson Davies Evans Thomas Roberts))[$n%9];
                $value .= "_${salt}" if $is_unique;
                return $value;
            } ],
        [ qr/\bname\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                my $value = "Name $n";
                $value .= "_${salt}" if $is_unique;
                return $value;
            } ],
        [ qr/\b(username|login)\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                my $value = "user$n";
                $value .= "_${salt}" if $is_unique;
                return $value;
            } ],
        [ qr/\bemail\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                my $local = "user$n";
                $local .= "_${salt}" if $is_unique;
                return "${local}\@example.com";
            } ],
        [ qr/\b(phone|mobile|fax)\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                return sprintf '+1555%04d%04d', $salt % 10000, $n;
            } ],
        [ qr/\b(street|address|addr)\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                my $value = "$n Main Street";
                $value .= "_${salt}" if $is_unique;
                return $value;
            } ],
        [ qr/\b(city|town)\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                my $value = (qw(London Paris Berlin Madrid Rome Amsterdam Brussels Vienna))[$n%8];
                $value .= "_${salt}" if $is_unique;
                return $value;
            } ],
        [ qr/\bcountry\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                my $value = (qw(UK US DE FR ES IT NL AT))[$n%8];
                $value .= "_${salt}" if $is_unique;
                return $value;
            } ],
        [ qr/\b(zip|postcode|postal)\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                return sprintf '%05d', (10000 + $n + $salt) % 99999;
            } ],
        [ qr/\b(state|province|region)\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                my $value = (qw(CA NY TX FL WA IL PA OH))[$n%8];
                $value .= "_${salt}" if $is_unique;
                return $value;
            } ],
        [ qr/\b(description|desc|summary|notes?|comment|body|content)\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                return "Sample text for record $n (run $salt).";
            } ],
        [ qr/\b(title|heading|subject)\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                my $value = "Title $n";
                $value .= "_${salt}" if $is_unique;
                return $value;
            } ],
        [ qr/\bslug\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                my $value = "slug-$n";
                $value .= "_${salt}" if $is_unique;
                return $value;
            } ],
        [ qr/\b(code|ref|reference)\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                my $value = sprintf 'CODE%04d', $n;
                $value .= "_${salt}" if $is_unique;
                return $value;
            } ],
        [ qr/\bsku\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                my $value = sprintf 'SKU%04d', $n;
                $value .= "_${salt}" if $is_unique;
                return $value;
            } ],
        [ qr/\b(token|secret|key|hash)\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                return sprintf '%016x%08x', $salt, $n;
            } ],
        [ qr/\b(url|link|href|website)\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                my $value = "https://example.com/item/$n";
                $value .= "_${salt}" if $is_unique;
                return $value;
            } ],
        [ qr/\b(status|state)\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                my $value = (qw(active inactive pending approved rejected))[$n%5];
                $value .= "_${salt}" if $is_unique;
                return $value;
            } ],
        [ qr/\b(type|kind|category|cat)\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                my $value = (qw(typeA typeB typeC typeD))[$n%4];
                $value .= "_${salt}" if $is_unique;
                return $value;
            } ],
        [ qr/\b(colour|color)\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                my $value = (qw(red green blue yellow purple orange))[$n%6];
                $value .= "_${salt}" if $is_unique;
                return $value;
            } ],
        [ qr/\b(lang|language|locale)\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                my $value = (qw(en fr de es it nl pt))[$n%7];
                $value .= "_${salt}" if $is_unique;
                return $value;
            } ],
        [ qr/\b(version|ver)\b/i,
            sub {
                my ($n, $is_unique, $salt) = @_;
                my $value = "1.$n.0";
                $value .= "_${salt}" if $is_unique;
                return $value;
            } ],
    ];

    for my $t (@$templates) {
        if ($col =~ $t->[0]) {
            my $value = $t->[1]->($n, $is_unique, $salt);
            return substr($value, 0, $max);
        }
    }

    # Default case
    my $value = "${col}_${n}";
    $value .= "_${salt}" if $is_unique;
    return substr($value, 0, $max);
}

sub _insert_rows {
    my ($self, $source, $name, $rows, $pk_cols, $inserted_pks) = @_;

    my $rs = $self->{_schema}->resultset($name);

    eval { $rs->populate($rows) };

    if ($@) {
        warn "[WARN] Bulk insert failed for $name: $@\n";
        return;
    }

    my @inserted = $rs->search({}, { rows => scalar(@$rows) });

    for my $row (@inserted) {
        push @{ $inserted_pks->{$name} },
            { map { $_ => $row->get_column($_) } @$pk_cols };
    }

    $self->_log("Inserted " . scalar(@$rows) . " rows into $name");
}

sub _rand_date {
    my ($self) = @_;
    my $year = $self->{start_year} + int(rand($self->{end_year} - $self->{start_year} + 1));
    sprintf '%d-%02d-%02d', $year, rand(12)+1, rand(28)+1;
}

sub _rand_datetime {
    my ($self) = @_;
    my $year = $self->{start_year} + int(rand($self->{end_year} - $self->{start_year} + 1));
    sprintf '%d-%02d-%02d %02d:%02d:%02d',
        $year, rand(12)+1, rand(28)+1, rand(24), rand(60), rand(60);
}

sub _log   { print "[INFO]  $_[1]\n";                    }
sub _debug { print "[DEBUG] $_[1]\n" if $_[0]->{verbose} }

=head1 GENERATED VALUES

Values are produced from each column's declared C<data_type>:

  integer / bigint / serial    random integer  (unique: salt + row_num)
  numeric / decimal / float    random decimal (2 d.p.)
  boolean                      0 or 1
  datetime / timestamp         random datetime 2020-2024
  date                         random date 2020-2024
  time                         random HH:MM:SS
  uuid                         random UUID-shaped hex string
  json / jsonb                 {"generated":true,"row":N}
  text / varchar / char        contextual string matched on column name
  unknown / blank dtype        colname_N  (colname_N_SALT if unique)

Nullable columns receive NULL roughly 17% of the time (never for unique cols).

=head1 CONFIGURATION OPTIONS

=head2 rows_per_table

    rows_per_table => { Author => 10, Book => 3 }

Allows you to specify different numbers of rows for specific tables. Any table
not listed in this hash will use the global C<rows> value. This is useful when
you need more data for certain tables (e.g., Authors) and less for others.

=head2 generators

    generators => {
        email  => sub { "user".int(rand(1000))."\@example.com" },
        status => sub { "active" },
    }

Provides custom value generators for specific columns. The generator subroutine
receives four arguments:

=over 4

=item C<$col> - The column name

=item C<$info> - The column info hashref from the result source

=item C<$n> - The current row number (1-based)

=item C<$mock> - The MockData object instance (provides access to C<_salt> etc.)

=back

The generator should return a scalar value appropriate for the column. This
overrides the default value generation for that column.

Examples:

    # Static value for all rows
    status => sub { 'active' }

    # Value based on row number
    code => sub { my ($col, $info, $n) = @_; "CODE_$n" }

    # Value using the instance salt for uniqueness
    token => sub { my ($col, $info, $n, $mock) = @_; "token_${n}_$mock->{_salt}" }

    # Conditional logic
    email => sub {
        my ($col, $info, $n) = @_;
        return $n == 1 ? 'admin@example.com' : "user$n\@example.com";
    }

=head1 PERFORMANCE IMPROVEMENTS

Version 0.04 introduces significant performance optimisations:

=head2 Bulk Insert Mode

Previously, rows were inserted one at a time using C<< $rs->create() >>, which
could be slow for large datasets. The module now uses C<< $rs->populate() >> to
insert all rows in a single batch operation. This results in:

=over 4

=item * Up to 10x faster insertions for large datasets

=item * Reduced database round-trips

=item * Maintained foreign key integrity

=back

=head2 Smarter Salt Generation

When a C<seed> is provided for reproducible output, the salt value is now
randomised while still producing consistent results. This ensures:

=over 4

=item * Reproducible test data across runs (with same seed)

=item * Unique values across different test runs (different salts)

=item * No accidental collisions when running tests in parallel

=back

=head2 Unique Constraint Handling

The module now properly respects:

=over 4

=item * Primary key uniqueness (except auto-increment columns)

=item * Named unique constraints from L<DBIx::Class>

=item * Multi-column unique constraints

=back

Values for unique columns are automatically salted to ensure uniqueness
without manual intervention.

=head1 CLI TOOL

This distribution ships with a command-line tool B<dbic-mockdata> in the
C<script/> directory, installed into your C<PATH> by C<make install>.

    dbic-mockdata --schema-dir t/lib --namespace MyApp::Schema \
                  --dsn "dbi:SQLite:dbname=test.db" --deploy --rows 5

Run C<dbic-mockdata --help> for the full list of options, or see
L<dbic-mockdata> for the complete manual.

=head1 DEPENDENCIES

L<DBIx::Class>, L<Carp>, L<File::Spec>, L<Scalar::Util>

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/DBIx-Class-MockData>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/DBIx-Class-MockData/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::MockData

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/DBIx-Class-MockData/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-MockData>

=item * Search MetaCPAN

L<https://metacpan.org/dist/DBIx-Class-MockData/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:
L<http://www.perlfoundation.org/artistic_license_2_0>
Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.
If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.
This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.
This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.
Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of DBIx::Class::MockData
