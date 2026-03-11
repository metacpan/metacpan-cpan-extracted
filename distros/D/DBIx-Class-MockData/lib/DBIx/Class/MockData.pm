package DBIx::Class::MockData;

$DBIx::Class::MockData::VERSION   = '0.02';
$DBIx::Class::MockData::AUTHORITY = 'cpan:MANWAR';

use strict;
use warnings;

=encoding UTF-8

=head1 NAME

DBIx::Class::MockData - Generate mock test data for DBIx::Class schemas

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use DBIx::Class::MockData;

    my $schema = MyApp::Schema->connect($dsn, $user, $pass);

    DBIx::Class::MockData
        ->new(
            schema     => $schema,
            schema_dir => 't/lib',
        )
        ->deploy
        ->generate;

With options:

    DBIx::Class::MockData
        ->new(
            schema     => $schema,
            schema_dir => 't/lib',
            rows       => 10,
            verbose    => 1,
            seed       => 42,
        )
        ->wipe
        ->generate;

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

    my $self = {
        _schema => $args{schema},
        rows    => $args{rows}    // 5,
        verbose => $args{verbose} // 0,
        _salt   => int(rand(9_000_000)) + 1_000_000,
    };

    if (defined $args{seed}) {
        srand($args{seed});
        $self->{_salt} = $args{seed};
    }

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

=head2 wipe

    $mock->wipe->generate;   # chainable

Drops B<all> tables then redeploys the schema.
B<Destructive -- for test environments only.> Returns C<$self>.

=cut

sub wipe {
    my ($self) = @_;
    my $schema = $self->{_schema};

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

sub generate {
    my ($self) = @_;
    my $schema = $self->{_schema};

    my @sources = $schema->sources;
    croak "No result sources found in schema" unless @sources;

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
        for my $n (1 .. $self->{rows}) {
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

    for my $name (sort $schema->sources) {
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
            my $info = $source->relationship_info($rel);
            next unless $self->_is_belongs_to($info);
            my $parent = eval { $source->related_source($rel)->source_name } or next;
            next if $parent eq $name;
            push @{ $deps{$name} }, $parent
                unless grep { $_ eq $parent } @{ $deps{$name} };
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

    # Append remaining nodes (cycle members -- best effort)
    my %seen = map { $_ => 1 } @result;
    push @result, $_ for grep { !$seen{$_} } @$nodes;
    return @result;
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

    if ($dtype =~ /\b(int|integer|bigint|smallint|tinyint|serial|bigserial)\b/) {
        return $is_unique ? $salt + $n : int(rand(999_999)) + 1;
    }
    if ($dtype =~ /\b(numeric|decimal|float|double|real|money)\b/) {
        return sprintf '%.2f', rand(10_000);
    }
    if ($dtype =~ /\b(bool|boolean|tinyint\(1\))\b/) {
        return int(rand(2));
    }
    if ($dtype =~ /\b(datetime|timestamp)\b/) {    # before bare 'date'
        return $self->_rand_datetime;
    }
    if ($dtype =~ /\bdate\b/) {
        return $self->_rand_date;
    }
    if ($dtype =~ /\btime\b/) {
        return sprintf '%02d:%02d:%02d', int(rand(24)), int(rand(60)), int(rand(60));
    }
    if ($dtype =~ /\buuid\b/) {
        return sprintf '%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
            map { int(rand(65536)) } 1 .. 8;
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
    my $u    = $is_unique ? "_${salt}" : '';

    my @templates = (
        [ qr/\b(first_?name|fname)\b/i,
            sub { (qw(Alice Bob Carol Dave Eve Frank Grace Hank Iris Jack))[$_[0]%10].$u }],
        [ qr/\b(last_?name|lname|surname)\b/i,
            sub { (qw(Smith Jones Taylor Brown Wilson Davies Evans Thomas Roberts))[$_[0]%9].$u }],
        [ qr/\bname\b/i,
            sub { "Name $_[0]$u" }],
        [ qr/\b(username|login)\b/i,
            sub { "user$_[0]$u" }],
        [ qr/\bemail\b/i,
            sub { "user$_[0]${u}\@example.com" }],
        [ qr/\b(phone|mobile|fax)\b/i,
            sub { sprintf '+1555%04d%04d', $salt%10000, $_[0] }],
        [ qr/\b(street|address|addr)\b/i,
            sub { "$_[0]$u Main Street" }],
        [ qr/\b(city|town)\b/i,
            sub { (qw(London Paris Berlin Madrid Rome Amsterdam Brussels Vienna))[$_[0]%8] }],
        [ qr/\bcountry\b/i,
            sub { (qw(UK US DE FR ES IT NL AT))[$_[0]%8] }],
        [ qr/\b(zip|postcode|postal)\b/i,
            sub { sprintf '%05d', (10000+$_[0]+$salt)%99999 }],
        [ qr/\b(state|province|region)\b/i,
            sub { (qw(CA NY TX FL WA IL PA OH))[$_[0]%8] }],
        [ qr/\b(description|desc|summary|notes?|comment|body|content)\b/i,
            sub { "Sample text for record $_[0] (run $salt)." }],
        [ qr/\b(title|heading|subject)\b/i,
            sub { "Title $_[0]$u" }],
        [ qr/\bslug\b/i,
            sub { "slug-$_[0]$u" }],
        [ qr/\b(code|ref|reference)\b/i,
            sub { sprintf 'CODE%04d%s', $_[0], $u }],
        [ qr/\bsku\b/i,
            sub { sprintf 'SKU%04d%s',  $_[0], $u }],
        [ qr/\b(token|secret|key|hash)\b/i,
            sub { sprintf '%016x%08x', $salt, $_[0] }],
        [ qr/\b(url|link|href|website)\b/i,
            sub { "https://example.com/item/$_[0]$u" }],
        [ qr/\b(status|state)\b/i,
            sub { (qw(active inactive pending approved rejected))[$_[0]%5] }],
        [ qr/\b(type|kind|category|cat)\b/i,
            sub { (qw(typeA typeB typeC typeD))[$_[0]%4] }],
        [ qr/\b(colour|color)\b/i,
            sub { (qw(red green blue yellow purple orange))[$_[0]%6] }],
        [ qr/\b(lang|language|locale)\b/i,
            sub { (qw(en fr de es it nl pt))[$_[0]%7] }],
        [ qr/\b(version|ver)\b/i,
            sub { "1.$_[0].0" }],
    );

    for my $t (@templates) {
        return substr($t->[1]->($n), 0, $max) if $col =~ $t->[0];
    }
    return substr("${col}_${n}${u}", 0, $max);
}

sub _insert_rows {
    my ($self, $source, $name, $rows, $pk_cols, $inserted_pks) = @_;
    my $rs = $self->{_schema}->resultset($name);
    my ($ok, $failed) = (0, 0);

    for my $i (0 .. $#$rows) {
        my $row = eval { $rs->create($rows->[$i]) };
        if ($@) {
            warn "  [WARN] Insert failed for $name: $@\n";
            $failed++;
            next;
        }

        push @{ $inserted_pks->{$name} },
            { map { $_ => $row->get_column($_) } @$pk_cols };
        $ok++;

        my $summary = join ', ', map {
            my $v = $row->get_column($_);
            defined $v ? "$_=" . (length($v) > 30 ? substr($v,0,27).'...' : $v)
                       : "$_=NULL"
        } $source->columns;
        $self->_log(sprintf '  Row %d: %s', $i+1, $summary);
    }

    if    ($failed && !$ok) { $self->_log("  [ERROR] All $failed insert(s) failed for $name") }
    elsif ($failed)         { $self->_log("  Inserted $ok row(s) into $name ($failed failed)") }
    else                    { $self->_log("  Inserted $ok row(s) into $name") }
}

sub _rand_date {
    my @y = (2020..2024);
    sprintf '%d-%02d-%02d', $y[rand@y], rand(12)+1, rand(28)+1;
}

sub _rand_datetime {
    my @y = (2020..2024);
    sprintf '%d-%02d-%02d %02d:%02d:%02d',
        $y[rand@y], rand(12)+1, rand(28)+1, rand(24), rand(60), rand(60);
}

sub _log   { print "[INFO]  $_[1]\n" }
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
