=head1 NAME

DBIx::MyDatabaseMunger - MariaDB/MySQL Database Management Utility

=head1 SYNOPSIS

Normal interface is through the mydbmunger command, but this class can also
be used directly.

    use DBIx::MyDatabaseMunger ();
    $dbmunger = new DBIx::MyDatabaseMunger ({
        connect => {
            schema => 'database',
            host => 'mysql.example.com',
            user => 'username',
            password => 'p4ssw0rd',
        },
        colname => {
            ctime => 'create_datetime',
            mtime => 'tstmp',
        },
    });
    $dbmunger->pull();
    $dbmunger->make_archive();
    $dbmunger->push();

=head1 DESCRIPTION

A library and accompanying "mydbmunger" utility to simplify complex MySQL and
MariaDB database management tasks.

=cut

package DBIx::MyDatabaseMunger;
use strict;
use warnings;
use autodie;
use Storable qw(dclone freeze);
use SQL::QueryBuilder::Pretty ();

our $VERSION = 0.80;
our $DRYRUN = 0;
our $QUIET = 0;
our $VERBOSE = 0;
our $SQL_PRETTY = SQL::QueryBuilder::Pretty->new(
    '-database' => 'MySQL',
);

# When running the todo list, do these things in this order.
use constant TODO_ACTIONS => qw(
drop_constraint
drop_trigger
drop_procedure
drop_view
drop_key
drop_column
drop_table
create_table
add_column
modify_column
add_key
add_constraint
create_view
create_procedure
create_trigger
);

=head1 CONSTRUCTOR

The constructor C<new DBIx::MyDatabaseMunger()> takes a hash reference of
options. These options include.

=over 4

=item C<archive_name_pattern>

Naming convention for archive tables. Takes a wildcard, '%' that will be the
source table name.

Default: C<%Archive>

=item C<colname>

A hash of column names for special handling. Column names include:

=over 4

=item C<action>

Column used to record action in archive table. Column should be an enumeration
type with values 'insert', 'update', or 'delete'.

=item C<ctime>

Column used to record when a record is initially created. If not specified
then this functionality will not be implemented.

=item C<dbuser>

Column used to track dabase connection C<USER()>, which indicates the user and
host that is connected to the database.

=item C<mtime>

Column used to record when a record was last changed. If not specified then
this functionality will not be implemented.

=item C<revision>

Revision count column. Must be an integer type.

=item C<stmt>

The column used to track the SQL statement responsible for a table change.

=item C<updid>

The column used to store the value of the variable indicated by C<updidvar>.

=back

=item C<dir>

Directory in which to save table and trigger definitions.

Default: C<.>

=item C<updidvar>

Connection variable to be used by the calling application to track the reason
for table updates, inserts, and deletes.

Default: C<@updid>

=back

=cut

sub new
{
    my $class = shift;

    my $self = dclone( $_[0] );

    # Apply default values.
    $self->{dir} ||= '.';
    $self->{archive_name_pattern} ||= '%Archive';
    $self->{updidvar} ||= '@updid';
    $self->{colname}{action}      ||= 'action';
    $self->{colname}{dbuser}      ||= 'dbuser';
    $self->{colname}{revision}    ||= 'revision';
    $self->{colname}{stmt}        ||= 'stmt';
    $self->{colname}{updid}       ||= 'updid';

    # Initialize todo queues.
    $self->{todo} = { map {($_=>[])} TODO_ACTIONS };

    return bless $self, $class;
}

=head1 METHODS

=cut

#
# PRIVATE UTILITY FUNCTIONS
#

### $self->__dbi_connect ()
#
# Connect to database, set $self->{dbh}.
#
sub __dbi_connect : method
{
    my $self = shift;
    use DBI ();

    die "No database schema specified.\n"
        unless $self->{connect}{schema};

    # Build Perl DBI dsn
    my $dsn = "DBI:mysql:database=$self->{connect}{schema}";
    $dsn .= ";host=$self->{connect}{host}" if $self->{connect}{host};
    $dsn .= ";port=$self->{connect}{port}" if $self->{connect}{port};

    my $dbh = DBI->connect(
        $dsn,
        $self->{connect}{user},
        $self->{connect}{password},
        { PrintError => 0, RaiseError => 1 }
    );
    $self->{dbh} = $dbh;
}

### $self->__ignore_table ( $name )
#
# Determine whether a table should be ignored based on the tables setting.
#
sub __ignore_table : method
{
    my $self = shift;
    my($name) = @_;


    # Skip table if explicitly excluded.
    if( $self->{exclude_tables} ) {
        for my $t ( @{ $self->{exclude_tables} } ) {
            return 1 if $name eq $t;

            # On to the next table unless this one is a wildcard.
            next unless $t =~ m/%/;

	    # Build regex by splitting table specification on '%' and replacing
	    # it with '.*'. Make sure interemediate chunks of the specification
	    # are regex quoted with qr using \Q...\E. Then add beginning and
	    # end of string anchors, '^' and '$'.
            my $re = '^'.join('.*', map { qr/\Q$_\E/ } split '%', $t, -1 ).'$';

            # Ignore table if the regex matches.
            return 1 if $name =~ $re;
        }
    }

    # Don't skip any more tables if tables list is empty.
    return 0 unless @{ $self->{tables} };

    # Skip table if not listed expliitly in tables.
    for my $t ( @{ $self->{tables} } ) {
        return 0 if $name eq $t;

        # On to the next table unless this one is a wildcard.
        next unless $t =~ m/%/;

	# Build regex by splitting table specification on '%' and replacing
	# it with '.*'. Make sure interemediate chunks of the specification
	# are regex quoted with qr using \Q...\E. Then add beginning and end
	# of string anchors, '^' and '$'.
        my $re = '^'.join('.*', map { qr/\Q$_\E/ } split '%', $t, -1 ).'$';

        # Don't ignore table if the regex matches.
        return 0 if $name =~ $re;
    }
    return 1;
}

### $self->__ignore_view ( $name )
#
# Determine whether a view should be ignored based on the views setting.
#
sub __ignore_view : method
{
    my $self = shift;
    my($name) = @_;


    # Skip view if explicitly excluded.
    if( $self->{exclude_views} ) {
        for my $v ( @{ $self->{exclude_views} } ) {
            return 1 if $name eq $v;

            # On to the next view unless this one is a wildcard.
            next unless $v =~ m/%/;

	    # Build regex by splitting view specification on '%' and replacing
	    # it with '.*'. Make sure interemediate chunks of the specification
	    # are regex quoted with qr using \Q...\E. Then add beginning and
	    # end of string anchors, '^' and '$'.
            my $re = '^'.join('.*', map { qr/\Q$_\E/ } split '%', $v, -1 ).'$';

            # Ignore view if the regex matches.
            return 1 if $name =~ $re;
        }
    }

    # Don't skip any more views if views list is empty.
    return 0 unless @{ $self->{views} };

    # Skip view if not listed expliitly in views.
    for my $v ( @{ $self->{views} } ) {
        return 0 if $name eq $v;

        # On to the next view unless this one is a wildcard.
        next unless $v =~ m/%/;

	# Build regex by splitting view specification on '%' and replacing
	# it with '.*'. Make sure interemediate chunks of the specification
	# are regex quoted with qr using \Q...\E. Then add beginning and end
	# of string anchors, '^' and '$'.
        my $re = '^'.join('.*', map { qr/\Q$_\E/ } split '%', $v, -1 ).'$';

        # Don't ignore view if the regex matches.
        return 0 if $name =~ $re;
    }
    return 1;
}

### $self->__queue_sql ( $action, $desc, $sql )
#
# Queue SQL action for later execution.
#
sub __queue_sql : method
{
    my $self = shift;
    my( $action, $desc, $sql ) = @_;

    push @{$self->{todo}{$action}}, {
        desc => $desc,
        sql => $sql,
    };
}

sub __beautify_view
{
    my $self = shift;
    my($sql) = @_;
    $sql =~ s/` `/` AS `/g;
    $sql = $SQL_PRETTY->print($sql);
    $sql =~ s/ ALGORITHM=/\n  ALGORITHM=/;
    $sql =~ s/ DEFINER=/\n  DEFINER=/;
    $sql =~ s/ SQL SECURITY /\n  SQL SECURITY /;
    $sql =~ s/ VIEW `([^`]+)` AS /\nVIEW `$1` AS\n/;
    $sql =~ s/` *AS /` AS /g;
    $sql =~ s/^(select) /SELECT\n/im;
    $sql =~ s/ from \(/\nFROM (/i;
    $sql .= "\n";
    return $sql;
}

=over 4

=item C<table_names ()>

Return a list of all saved table names.

=cut

sub table_names : method
{
    my $self = shift;
    my @names;

    opendir my $dh, "$self->{dir}/table";
    while( my $table_sql = readdir $dh ) {
        my($name) = $table_sql =~ m/^(.*)\.sql$/
            or next;
        push @names, $name;
    };

    return @names;
}

=item $o->parse_create_table_sql ( $sql )

Parse a CREATE TABLE statement generated by mysql "SHOW CREATE TABLE ..."

This function is very particular about the input format.

=cut

sub parse_create_table_sql : method
{
    my $self = shift;
    my($sql) = @_;

    my @create_sql = split "\n", $sql;

    # Read the table name from the "CREATE TABLE `<NAME>` (
    shift( @create_sql ) =~ m/CREATE TABLE `(.*)`/
        or die "Create table SQL does not begin with CREATE TABLE!\n";
    my $name = $1;

    # The last line should have the table options
    # ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COMMENT='App User'
    # We don't need to understand every last option, but let's extract at least
    # the ENGINE and COMMENT.
    my $line = pop @create_sql;
    my($table_options) = $line =~ m/\)\s*(.*)/;

    # Extract the ENGINE= from the table options.
    $table_options =~ s/ENGINE=(\S+)\s*//
        or die "Table options lack ENGINE specification?!";
    my $engine = $1;

    # Drop data about AUTO_INCREMENT
    $table_options =~ s/AUTO_INCREMENT=(\d+)\s*//;

    # Extract the COMMENT and undo mysql ' quoting. We shouldn't have to deal
    # with weird characters or backslashes in comments, so let's keep it
    # simple.
    my $comment;
    if( $table_options =~ s/\s*COMMENT='(([^']|'')*)'// ) {
        $comment = $1;
        $comment =~ s/''/'/g;
    }

    # The remaining lines should be column definitions followed by keys.
    my @columns;
    my %column_definition;
    my @constraints;
    my %constraint_definition;
    my @keys;
    my %key_definition;
    my @primary_key;

    for my $line ( @create_sql ) {
        $line =~ s/,$//; # Strip trailing commas

        # Strip out DEFAULT NULL so that it is easier to compare column
        # definitions.
        $line =~ s/ DEFAULT NULL//;

        if( $line =~ m/^\s*`([^`]+)`\s*(.*)/ ) {
            my($col, $def) = ($1, $2);
            push @columns, $col;
            $column_definition{ $col } = $def;
        } elsif( $line =~ m/^\s*PRIMARY KEY \(`(.*)`\)/ ) {
            @primary_key = split( '`,`', $1 );
        } elsif( $line =~ m/^\s*((UNIQUE )?KEY `([^`]+)`.*)/ ) {
            my($key, $def) = ($3, $1);
            push @keys, $key;
            $key_definition{ $key } = $def;
        } elsif( $line =~ m/^\s*
            CONSTRAINT\s+`(.*)`\s+
            FOREIGN\s+KEY\s+\(`(.*)`\)\s+
            REFERENCES\s+`(.*)`\s+\(`(.*)`\)\s+(.*)
        /x ) {
            my($name, $cols, $reftable, $refcols, $cascade_opt) =
                ($1, $2, $3, $4, $5);
            my @cols = split '`,`', $cols;
            my @refcols = split '`,`', $refcols;
            push @constraints, $name;
            $constraint_definition{ $name } = {
                name => $name,
                columns => \@cols,
                reference_table => $reftable,
                reference_columns => \@refcols,
                cascade_opt => $cascade_opt,
            };
        } else {
            warn "Don't understand line in CREATE TABLE:\n$line";
        }
    }

    return {
        name => $name,
        comment => $comment,
        engine => $engine,
        table_options => $table_options,
        columns => \@columns,
        column_definition => \%column_definition,
        keys => \@keys,
        key_definition => \%key_definition,
        constraints => \@constraints,
        constraint_definition => \%constraint_definition,
        primary_key => \@primary_key,
    };
}

=item $o->read_table_sql ( $table_name )

Given a table name, retrieve the table definition SQL.

=cut

sub read_table_sql : method
{
    my $self = shift;
    my($name) = @_;

    # File slurp mode.
    local $/;

    open my $fh, "$self->{dir}/table/$name.sql";
    my $sql = <$fh>;
    close $fh;

    return $sql;
}

=item $o->get_table_desc ( $table_name )

Given a table name, retrieve the parsed table definition.

=cut

sub get_table_desc : method
{
    my $self = shift;
    my($name) = @_;

    my $sql = $self->read_table_sql( $name );
    my $desc;
    eval {
        $desc = $self->parse_create_table_sql( $sql );
    };
    die "Error parsing SQL for table `$name`:\n$@" if $@;
    die "Table name mismatch while reading SQL for `$name`, " .
        "got `$desc->{name}` instead!\n"
        unless $name eq $desc->{name};

    return $desc;
}

=item $o->find_data_tables_with_revision ()

Return table definitions that have a revision column.

=cut

sub find_data_tables_with_revision ($)
{
    my $self = shift;

    my $archive_name_regexp = $self->{archive_name_pattern};
    $archive_name_regexp =~ s/%/.*/;
    $archive_name_regexp = qr/^$archive_name_regexp$/;

    my @tables = ();

    for my $name ( $self->table_names ) {
        # Skip tables that are archive_tables
        next if $name =~ $archive_name_regexp;

        my $table = $self->get_table_desc( $name );
        push @tables, $table
            if $table->{column_definition}{ $self->{colname}{revision} };
    }

    return @tables;
}

=item $o->check_table_is_archive_capable ( $table )

Check that a table has bare minimum support required to have an archive
table.

=cut

sub check_table_is_archive_capable : method
{
    my $self = shift;
    my ( $table ) = @_;

    die "$table->{name} lacks a primary key."
        unless @{$table->{primary_key}};

    my($col, $coldef);

    $col = $self->{colname}{revision};
    $coldef = $table->{column_definition}{$col}
        or die "$table->{name} lacks $col column.\n";
    $coldef =~ m/\b(int|bigint)\b/
        or die "$table->{name} column $col is not an integer type.\n";

    $col = $self->{colname}{updid};
    if( $table->{col_definition}{$col} ) {
        $coldef =~ m/\b(varchar)\b/
            or die "$table->{name} column $col is not a string type.\n";
    }

    for my $timecol (qw(mtime ctime)) {
        my $col = $self->{colname}{$timecol} or next;
        $coldef = $table->{column_definition}{$col}
            or next;
        $coldef =~ m/\b(timestamp|datetime)\b/
            or die "$table->{name} column $col is neither a timestamp or " .
                   "datetime field.\n";
    }

    # Check for obvious name conflicts.
    for my $col (qw(dbuser action stmt)) {
        die "Archive table column conflict, souce table `$table->{name}` has " .
            "column `$col`.\n"
            if $table->{column_definition}{$col};
    }

    # FIXME - There are probably other engines that are okay, but which?
    die "I can't promise this will work for table $table->{name} with " .
        "ENGINE=$table->{engine}\n"
        unless $table->{engine} eq 'InnoDB';
}

=item $o->check_table_updatable( $current, $desired )

Check that the current table could be updated to the desired state.

=cut

sub check_table_updatable : method
{
    my $self = shift;
    my( $current, $desired ) = @_;
    my $name = $current->{name};

    die "Table `$name` lacks a primary key."
        unless @{$current->{primary_key}};

    my $desired_pkstr = '`' . join('`,`', @{$desired->{primary_key}}) . '`';
    my $current_pkstr = '`' . join('`,`', @{$current->{primary_key}}) . '`';
    die "Table `$name` primary key is ($current_pkstr) not ($desired_pkstr)\n"
        unless $current_pkstr eq $desired_pkstr;

    # Check for update paths between column definitions...
    for my $col ( @{$desired->{columns}} ) {
        my $cdef = $current->{column_definition}{$col};
        my $ddef = $desired->{column_definition}{$col};

        # It should be okay to add a column... though it may fail if it is
        # part of a unique index.
        next unless $cdef;

        my $num_type = qr/^(
            (|tiny|small|medium|big)int |
            decimal |
            numeric |
            float   |
            double)\b/x;
        my $datetime_type = qr/^(date|datetime|timestamp)\b/;
        my $string_type = qr/^(
            (|var)(char|binary) |
            (|tiny|medium|long)(blob|text) |
            enum | set)\b/x;
        if( $ddef =~ $num_type ) {
            $cdef =~ $num_type
                 or die "Table $name column $col is not a numeric type.\n";
        } elsif( $ddef =~ $datetime_type ) {
            $cdef =~ $datetime_type
                 or die "Table $name column $col is not a date or time type.\n";
        } elsif( $ddef =~ $string_type ) {
            $cdef =~ $string_type
                 or die "Table $name column $col is not a string type.\n";
        }
    }

    die "Unable Table `$current->{name}`, engine mismatch " .
        "$current->{engine} vs. $desired->{engine}\n"
        unless $current->{engine} eq $desired->{engine};
}


=item $o->make_archive_table_desc ( $table_desc )

Make a archive table description for the given source table description.

=cut

sub make_archive_table_desc : method
{
    my $self = shift;
    my( $table ) = @_;

    # Use name pattern to generate archive table names.
    my $name = $self->{archive_name_pattern};
    $name =~ s/%/$table->{name}/;

    my %archive_table = (
        name => $name,
        comment => "$table->{name} archive.",
        engine => $table->{engine},
        table_options => $table->{table_options},
        primary_key => [ @{$table->{primary_key}}, $self->{colname}{revision} ],
    );

    # Column definitions required for audit fields.
    my %column_definition = (
        $self->{colname}{dbuser} =>
            "varchar(256) NOT NULL COMMENT 'Database user & host that made " .
            "this change.'",
        $self->{colname}{updid} =>
            "varchar(256) NOT NULL COMMENT 'Application user that made this " .
            "change.'",
        $self->{colname}{action} =>
            "enum('insert','update','delete') NOT NULL COMMENT 'SQL action.'",
        $self->{colname}{stmt} =>
            "longtext NOT NULL COMMENT 'SQL Statement that initiated this " .
            "change.'",
    );

    my @columns;
    for my $col ( @{ $table->{columns} } ) {
        push @columns, $col;
        my $def = $table->{column_definition}{$col};

        # Drop properties not appropriate for archive tables.
        $def =~ s/ AUTO_INCREMENT//;

        # Adjust timestamp defaults and update properties to remove
        # CURRENT_TIMESTAMP behavior.
        if( $def =~ m/^timestamp\b/ ) {
            $def =~ s/ ON UPDATE CURRENT_TIMESTAMP//;
            $def =~ s/ DEFAULT CURRENT_TIMESTAMP/ DEFAULT '0000-00-00 00:00:00'/;
        } elsif( ! grep { $col eq $_ } @{ $archive_table{primary_key} } ) {
            # Allow NULL and strip defaults for columns not part of the primary
            # key.
            $def =~ s/ DEFAULT '([^']|'')+'//;
            $def =~ s/ NOT NULL//;
        }

        $column_definition{ $col } = $def;
    }

    # Add columns required for archive fields.
    # Column definitions were given above.
    for my $col (qw(action updid dbuser stmt)) {
        my $colname = $self->{colname}{$col};
        # Skip columns already defined in the parent table.
        next if $table->{column_definition}{$colname};
        push @columns, $colname;
    }

    $archive_table{columns} = \@columns;
    $archive_table{column_definition} = \%column_definition;

    my @keys;
    my %key_definition;
    for my $key ( @{ $table->{keys} } ) {
        push @keys, $key;
        my $def = $table->{key_definition}{$key};

        # Strip unique property from keys.
        $def =~ s/^UNIQUE\s*//;

        $key_definition{$key} = $def;
    }

    $archive_table{keys} = \@keys;
    $archive_table{key_definition} = \%key_definition;

    return \%archive_table;
}

=item $o->write_table_sql( $name, $sql )

Save create table SQL for a table.

=cut

sub write_table_sql : method
{
    my $self = shift;
    my( $name, $sql ) = @_;
    my $fh;

    # Make table directory if required.
    mkdir "$self->{dir}/table"
        unless -d "$self->{dir}/table";

    open $fh, ">", "$self->{dir}/table/$name.sql";
    print $fh $sql;
    close $fh;
}

=item $o->remove_table_sql( $name )

Remove create table SQL for a table.

=cut

sub remove_table_sql : method
{
    my $self = shift;
    my( $name ) = @_;
    unlink "$self->{dir}/table/$name.sql";
}

=item $o->write_table_definition( $table )

Write create table SQL for given table description.

=cut

sub write_table_definition : method
{
    my $self = shift;
    my( $table ) = @_;

    my $sql = "CREATE TABLE `$table->{name}` (\n";

    for my $col ( @{ $table->{columns} } ) {
        $sql .= "  `$col` $table->{column_definition}{$col},\n";
    }

    for my $key ( @{ $table->{keys} } ) {
        $sql .= "  $table->{key_definition}{$key},\n";
    }

    # Quote in a lazy way... to do it proper would require a database
    # connection.
    my $comment = $table->{comment} || $table->{name};
    $comment =~ s/'/''/g;

    $sql .= "  PRIMARY KEY (`" .
            join('`,`', @{$table->{primary_key}} ) .
            "`)\n";
    $sql .= ") ENGINE=$table->{engine} $table->{table_options} " .
            "COMMENT='$comment'\n";

    $self->write_table_sql( $table->{name}, $sql );
}

=item $o->remove_trigger_fragment( $fragment )

Remove trigger fragment SQL.

=cut

sub remove_trigger_fragment : method
{
    my $self = shift;
    my( $fragment ) = @_;
    unlink "$self->{dir}/trigger/$fragment->{file}";
}

=item $o->write_trigger_fragment_sql( $name, $time, $action, $table, $sql )

Write trigger fragement SQL to a file.

=cut

sub write_trigger_fragment_sql : method
{
    my $self = shift;
    my( $name, $time, $action, $table, $sql ) = @_;
    my $fh;

    # Make trigger directory if required.
    mkdir "$self->{dir}/trigger"
        unless -d "$self->{dir}/trigger";

    open $fh, ">", "$self->{dir}/trigger/$name.$time.$action.$table.sql";
    print $fh $sql;
    close $fh;
}

=item $o->write_archive_trigger_fragments( $table, $archive_table_desc )

Write trigger fragment sql for archive table management.

=cut

sub write_archive_trigger_fragments : method
{
    my $self = shift;
    my( $table, $archive_table ) = @_;
    my $colname = $self->{colname};
    my $fragment;
    my $fh;

    # Make trigger directory if required.
    mkdir "$self->{dir}/trigger"
        unless -d "$self->{dir}/trigger";


    # Before insert
    #$fragment = "SET NEW.`$colname->{revision}` = 0;\n";
    $fragment =
        "SET NEW.`$colname->{revision}` = (\n" .
        "  SELECT IFNULL( MAX(`$colname->{revision}`) + 1, 0 )\n" .
        "  FROM `$archive_table->{name}`\n" .
        "  WHERE " .
            join(" AND ", map {
                "`$_` = NEW.`$_`"
            } @{$table->{primary_key}}) .
        "\n);\n";
    $fragment .= "SET NEW.`$colname->{ctime}` = CURRENT_TIMESTAMP;\n"
        if $colname->{ctime} and $table->{column_definition}{$colname->{ctime}};
    $fragment .= "SET NEW.`$colname->{mtime}` = CURRENT_TIMESTAMP;\n"
        if $colname->{mtime} and $table->{column_definition}{$colname->{mtime}};
    $fragment .= "SET NEW.`$colname->{updid}` = $self->{updidvar};\n"
        if $table->{column_definition}{ $colname->{updid} };
    $self->write_trigger_fragment_sql(
       "20-archive", "before", "insert", $table->{name}, $fragment
    );


    # Before update
    $fragment =
        "SET NEW.`$colname->{revision}` = OLD.`$colname->{revision}` + 1;\n";
    $fragment .= "SET NEW.`$colname->{ctime}` = OLD.`$colname->{ctime}`;\n"
        if $colname->{ctime} and $table->{column_definition}{$colname->{ctime}};
    $fragment .= "SET NEW.`$colname->{mtime}` = CURRENT_TIMESTAMP;\n"
        if $colname->{mtime} and $table->{column_definition}{$colname->{mtime}};
    $fragment .= "SET NEW.`$colname->{updid}` = $self->{updidvar};\n"
        if $table->{column_definition}{ $colname->{updid} };
    $self->write_trigger_fragment_sql(
        "20-archive", "before", "update", $table->{name}, $fragment
    );


    # Columns that don't receive special treatment.
    # Exclude columns with special names.
    my %namecol = map {
        $colname->{$_} ? ($colname->{$_} => $_) : ()
    } keys %$colname;
    my @cols = grep { not $namecol{$_} } @{ $table->{columns} };

    # Special columns
    my @scols = grep { $colname->{$_} } sort keys %$colname;
    # Drop handling of ctime if not is table.
    if( $colname->{ctime}
        and not $table->{column_definition}{$colname->{ctime}}
    ) {
        @scols = grep { $_ ne 'ctime' } @scols;
    }

    $fragment =
        "BEGIN DECLARE stmt longtext;\n" .
        "SET stmt = ( SELECT info FROM INFORMATION_SCHEMA.PROCESSLIST " .
        "WHERE id = CONNECTION_ID() );\n" .
        "INSERT INTO `$archive_table->{name}` (\n" .
        "  `" . join( '`, `', @cols, map { $colname->{$_} } @scols ) . "`\n".
        ") VALUES (\n";

    # After insert
    $self->write_trigger_fragment_sql(
        "40-archive", "after", "insert", $table->{name},
        $fragment . "  NEW.`" . join('`, NEW.`', @cols) . "`,\n" .
        "  " . join(', ', map {
            m/^(ctime|mtime|revision)$/ ? "NEW.`$colname->{$_}`" :
            $_ eq 'action'  ? "'insert'" :
            $_ eq 'updid'   ? $self->{updidvar} :
            $_ eq 'dbuser'  ? "USER()" :
            $_ eq 'stmt'    ? 'stmt' : die "BUG! $_ unhandled!"
        } @scols) . "\n);\nEND;\n"
    );

    # After update
    $self->write_trigger_fragment_sql(
        "40-archive", "after", "update", $table->{name},
        $fragment . "  NEW.`" . join('`, NEW.`', @cols) . "`,\n" .
        "  " . join(', ', map {
            m/^(ctime|mtime|revision)$/ ? "NEW.`$colname->{$_}`" :
            $_ eq 'action'  ? "'update'" :
            $_ eq 'updid'   ? $self->{updidvar} :
            $_ eq 'dbuser'  ? "USER()" :
            $_ eq 'stmt'    ? 'stmt' : die "BUG! $_ unhandled!"
        } @scols) . "\n);\nEND;\n"
    );

    # After delete
    $self->write_trigger_fragment_sql(
        "40-archive", "after", "delete", $table->{name},
        $fragment . "  OLD.`" . join('`, OLD.`', @cols) . "`,\n" .
        "  " . join(', ', map {
            $_ eq 'action'   ? "'delete'" :
            $_ eq 'updid'    ? $self->{updidvar} :
            $_ eq 'ctime'    ? "OLD.`$colname->{ctime}`" :
            $_ eq 'dbuser'   ? "USER()" :
            $_ eq 'mtime'    ? "CURRENT_TIMESTAMP" :
            $_ eq 'revision' ? "1 + OLD.`$colname->{revision}`" :
            $_ eq 'stmt'     ? 'stmt' : die "BUG! $_ unhandled!"
        } @scols) . "\n);\nEND;\n"
    );

}

=item $o->query_table_sql ( $name )

=cut

sub query_table_sql : method
{
    my $self = shift;
    my( $name ) = @_;
    my $dbh = $self->{dbh};

    my $sth = $dbh->prepare( "SHOW CREATE TABLE `$name`" );
    $sth->execute();
    my @row = $sth->fetchrow_array;

    return "$row[1]\n";
}

=item $o->pull_table_definition ( $name )

=cut

sub pull_table_definition : method
{
    my $self = shift;
    my( $name ) = @_;

    print "Pulling table definition for `$name`\n" if $VERBOSE;

    # Get MySQL create table sql
    my $sql = $self->query_table_sql( $name );

    # Parse create table sql to local representation.
    my $table = $self->parse_create_table_sql( $sql );

    # Regenerate SQL from local representation.
    $sql = $self->create_table_sql( $table );

    # Save table sql.
    $self->write_table_sql( $name, $sql );
}

=item $o->pull_table_definitions ()

=cut

sub pull_table_definitions : method
{
    my $self = shift;
    my $dbh = $self->{dbh};

    # Make table directory if required.
    mkdir "$self->{dir}/table"
        unless -d "$self->{dir}/table";

    # Variable to keep track of tables in the database.
    my %db_table = ();

    for my $name ( $self->query_table_names ) {

        next if $self->__ignore_table( $name );

        $db_table{ $name } = 1;
        pull_table_definition( $self, $name );
    }

    if( $self->{remove}{table} ) {
        for my $name ( $self->table_names ) {
            next if $self->__ignore_table( $name );

            # Don't remove this table, it was found in the database.
            next if $db_table{$name};

            $self->remove_table_sql( $name );
        }
    }
}

=item $o->queue_create_table ( $table )

=cut

sub queue_create_table : method
{
    my $self = shift;
    my( $table ) = @_;

    $self->__queue_sql( 'create_table',
        "Create table $table->{name}.",
        $self->create_table_sql( $table, { no_constraints => 1 } ),
    );

    for my $constraint ( @{$table->{constraints}} ) {
        $self->queue_add_table_constraint($table, $constraint);
    }
}

=item $o->create_table_sql ( $table )

=cut

sub create_table_sql : method
{
    my $self = shift;
    my( $table, $opt ) = @_;

    my $sql = "CREATE TABLE `$table->{name}` (\n";

    for my $col ( @{ $table->{columns} } ) {
        $sql .= "  `$col` $table->{column_definition}{$col},\n";
    }

    for my $key ( sort @{ $table->{keys} } ) {
        $sql .= "  $table->{key_definition}{$key},\n";
    }

    unless( $opt->{no_constraints} ) {
        for my $constraint ( sort @{$table->{constraints}} ) {
            $sql .= "  " . $self->constraint_sql(
                $table->{constraint_definition}{$constraint}
            ) . ",\n";
        }
    }

    $sql .= "  PRIMARY KEY (`" . join('`,`', @{$table->{primary_key}}) . "`)\n";
    $sql .= ") ENGINE=$table->{engine} $table->{table_options}";
    if( $table->{comment} ) {
        my $comment = $table->{comment};
        $comment =~ s/'/''/g;
        $sql .= " COMMENT='$comment'";
    }
    $sql .= "\n";

    return $sql;
}

=item $o->constraint_sql ( $constraint )

=cut

sub constraint_sql : method
{
    my $self = shift;
    my($constraint) = @_;
    return "CONSTRAINT `$constraint->{name}` FOREIGN KEY (`"
        . join('`,`', @{$constraint->{columns}})
        . "`) REFERENCES `$constraint->{reference_table}` (`"
        . join('`,`', @{$constraint->{reference_columns}})
        . "`)" . (
            $constraint->{cascade_opt} ? " $constraint->{cascade_opt}" : ''
        );
}

=item $o->queue_add_table_constraint ( $table, $constraint )

=cut

sub queue_add_table_constraint : method
{
    my $self = shift;
    my($table, $constraint) = @_;

    my $def = $table->{constraint_definition}{$constraint};

    $self->__queue_sql( 'add_constraint',
        "Add constraint $constraint on $table->{name}.",
        "ALTER TABLE `$table->{name}` ADD ".$self->constraint_sql( $def ),
    );

    return $self;
}

=item $o->queue_drop_table_constraint ( $table, $constraint )

=cut

sub queue_drop_table_constraint : method
{
    my $self = shift;
    my($table, $constraint) = @_;

    $self->__queue_sql( 'drop_constraint',
        "Drop constraint $constraint on $table->{name}.",
        "ALTER TABLE `$table->{name}` DROP FOREIGN KEY `$constraint`",
    );

    return $self;
}

=item $o->queue_table_updates( $current, $desired )

=cut

sub queue_table_updates : method
{
    my $self = shift;
    my($current, $new) = @_;

    for( my $i=0; $i < @{ $new->{columns} }; ++$i ) {
        my $col = $new->{columns}[$i];
        if( $current->{column_definition}{$col} ) {
            unless( $current->{column_definition}{$col}
                 eq $new->{column_definition}{$col}
            ) {
                $self->__queue_sql( 'modify_column',
                    "Modify column $col in $current->{name}\n",
                    "ALTER TABLE `$current->{name}` " . 
                    "MODIFY COLUMN `$col` $new->{column_definition}{$col}",
                );
            }
        } else {
            $self->__queue_sql( 'add_column',
                "Add column $col to $current->{name}.",
                "ALTER TABLE `$current->{name}`" .
                " ADD COLUMN `$col` $new->{column_definition}{$col} " .
                ( $i == 0 ?
                    + "BEFORE `$new->{columns}[1]`"
                    : "AFTER `".$new->{columns}[$i-1]."`"
                )
            );
        }
    }

    # Look for unmatched columns to drop if drop_tables is set.
    if( $self->{drop_columns} ) {
        for my $col ( @{ $current->{columns} } ) {
            next if $new->{column_definition}{$col};

            $self->__queue_sql( 'drop_column',
                "Drop column $col from $current->{name}.",
                "ALTER TABLE `$current->{name}` DROP COLUMN `$col`",
            );
        }
    }

    for my $key ( @{ $new->{keys} } ) {
        my $new_keydef = $new->{key_definition}{$key};
        my $current_keydef = $current->{key_definition}{$key};

        if( $current_keydef ) {
            unless( $current_keydef eq $new_keydef ) {
                $self->__queue_sql( 'drop_key',
                    "Drop key $key on $current->{name}.",
                    "ALTER TABLE `$current->{name}` DROP KEY `$key`",
                );
                $self->__queue_sql( 'add_key',
                    "Add key $key on $current->{name}.",
                    "ALTER TABLE `$current->{name}` ADD $new_keydef",
                );
            }
        } else {
            $self->__queue_sql( 'add_key',
                "Create key $key on $current->{name}.",
                "ALTER TABLE `$current->{name}` ADD $new_keydef",
            );
        }
    }

    for my $constraint ( @{$new->{constraints}} ) {
        if( ! $current->{constraint_definition}{$constraint}
            or freeze($current->{constraint_definition}{$constraint})
            ne freeze($new->{constraint_definition}{$constraint})
        ) {
            $self->queue_drop_table_constraint($current, $constraint)
                if $current->{constraint_definition}{$constraint};
            $self->queue_add_table_constraint($new, $constraint);
        }
    }
    for my $constraint ( @{$current->{constraints}} ) {
        next if $new->{constraint_definition}{$constraint};
        $self->queue_drop_table_constraint($current, $constraint);
    }
}

=item $o->push_table_definition( $table )

=cut

sub queue_push_table_definition : method
{
    my $self = shift;
    my($name) = @_;

    my $new_sql = $self->read_table_sql( $name );
    my $new = $self->parse_create_table_sql( $new_sql );

    my( $current, $current_sql );
    eval {
        $current_sql = $self->query_table_sql( $name );
        $current = $self->parse_create_table_sql( $current_sql );
    };

    if( $current ) {
        $self->queue_table_updates( $current, $new );
    } else {
        $self->queue_create_table( $new );
    }

}

=item $o->push_table_definitions()

=cut

sub queue_push_table_definitions : method
{
    my $self = shift;

    my @tables = $self->table_names;

    for my $name ( @tables ) {

        next if $self->__ignore_table( $name );

        $self->queue_push_table_definition( $name );
    }

    if( $self->{remove}{table} ) {
        for my $name ( $self->query_table_names ) {

            next if $self->__ignore_table( $name );

            # Skip tables that are defined locally
            next if grep { $name eq $_ } @tables;

            $self->queue_drop_table( $name );
        }
    }
}

=item $o->queue_drop_table ( $name )

=cut

sub queue_drop_table : method
{
    my $self = shift;
    my($name) = @_;
    $self->__queue_sql( 'drop_table',
        "Drop table $name\n",
        "DROP TABLE `$name`",
    );
}


### VIEW ###

=item C<view_names ()>

Return a list of all saved view names.

=cut

sub view_names : method
{
    my $self = shift;
    my @names;

    my $viewdir = "$self->{dir}/view";
    return () unless -d $viewdir;

    my $dh;
    opendir $dh, $viewdir;
    for my $view_sql ( sort readdir $dh ) {
        my($name) = $view_sql =~ m/^(.*)\.sql$/
            or next;
        $name =~ s/^\d\d-//;
        push @names, $name;
    };

    return @names;
}

=item $o->read_view_sql ( $table_name )

Given a table name, retrieve the table definition SQL.

=cut

sub read_view_sql : method
{
    my $self = shift;
    my($name) = @_;

    # File slurp mode.
    local $/;

    # Look for file with numeric prefix.
    my($file) = glob "$self->{dir}/view/[0-9][0-9]-$name.sql";
    $file ||= "$self->{dir}/view/$name.sql";
    open(my $fh, $file);
    my $sql = <$fh>;
    close $fh;

    return $sql;
}

=item $o->write_view_sql( $name, $sql )

Save create view SQL for a view.

=cut

sub write_view_sql : method
{
    my $self = shift;
    my( $name, $sql ) = @_;
    my $fh;

    # Make view directory if required.
    mkdir "$self->{dir}/view"
        unless -d "$self->{dir}/view";

    my($file) = glob "$self->{dir}/view/[0-9][0-9]-$name.sql";
    $file ||= "$self->{dir}/view/$name.sql";

    open $fh, ">", $file;
    print $fh $sql;
    close $fh;
}

=item $o->remove_view_sql( $name )

Remove create view SQL for a view.

=cut

sub remove_view_sql : method
{
    my $self = shift;
    my( $name ) = @_;
    unlink "$self->{dir}/view/$name.sql";
}

=item $o->query_table_names ()

=cut

sub query_table_names : method
{
    my $self = shift;
    my $dbh = $self->{dbh};

    my $sth = $dbh->prepare( "SHOW FULL TABLES WHERE Table_type='BASE TABLE'" );
    $sth->execute();

    my @tables = ();
    while( my($name) = $sth->fetchrow_array ) {
        push @tables, $name;
    }

    return @tables;
}

=item $o->query_view_sql ( $name )

=cut

sub query_view_sql : method
{
    my $self = shift;
    my( $name ) = @_;
    my $dbh = $self->{dbh};

    my $sth = $dbh->prepare( "SHOW CREATE VIEW `$name`" );
    $sth->execute();
    my @row = $sth->fetchrow_array;

    return $self->__beautify_view($row[1]);
}

=item $o->pull_view_definition ( $name )

=cut

sub pull_view_definition : method
{
    my $self = shift;
    my( $name ) = @_;

    print "Pulling view definition for `$name`\n" if $VERBOSE;

    # Get MySQL create view sql
    my $sql = $self->query_view_sql( $name );

    # Save view sql.
    $self->write_view_sql( $name, $sql );
}

=item $o->query_view_names ()

=cut

sub query_view_names : method
{
    my $self = shift;
    my $dbh = $self->{dbh};

    my $sth = $dbh->prepare( "SHOW FULL TABLES WHERE Table_type='VIEW'" );
    $sth->execute();

    my @views = ();
    while( my($name) = $sth->fetchrow_array ) {
        push @views, $name;
    }

    return @views;
}

=item $o->queue_create_view( $new_sql )

=cut

sub queue_create_view : method
{
    my $self = shift;
    my( $name, $sql ) = @_;
    $sql =~ s/^CREATE/CREATE OR REPLACE/i;

    $self->__queue_sql( 'create_view',
        "Create view $name.",
        $sql
    );
}

=item $o->push_view_definition( $view )

=cut

sub queue_push_view_definition : method
{
    my $self = shift;
    my($name) = @_;

    my $new_sql = $self->read_view_sql( $name );

    my( $current_sql );
    eval {
        $current_sql = $self->query_view_sql( $name );
    };

    if( $current_sql and $current_sql ne $new_sql) {
        $self->queue_drop_view( $name );
    }

    $self->queue_create_view( $name, $new_sql );
}

=item $o->push_view_definitions()

=cut

sub queue_push_view_definitions : method
{
    my $self = shift;

    my @views = $self->view_names;

    for my $name ( @views ) {

        next if $self->__ignore_view( $name );

        $self->queue_push_view_definition( $name );
    }

    if( $self->{remove}{view} ) {
        for my $name ( $self->query_view_names ) {

            next if $self->__ignore_view( $name );

            # Skip views that are defined locally
            next if grep { $name eq $_ } @views;

            $self->queue_drop_view( $name );
        }
    }
}

=item $o->queue_drop_view ( $name )

=cut

sub queue_drop_view : method
{
    my $self = shift;
    my($name) = @_;
    $self->__queue_sql( 'drop_view',
        "Drop view $name\n",
        "DROP VIEW `$name`",
    );
}

=item $o->pull_view_definitions ()

=cut

sub pull_view_definitions : method
{
    my $self = shift;
    my $dbh = $self->{dbh};

    # Make view directory if required.
    mkdir "$self->{dir}/view"
        unless -d "$self->{dir}/view";

    # Variable to keep track of views in the database.
    my %db_view = ();

    for my $name ( $self->query_view_names ) {

        next if $self->__ignore_view( $name );

        $db_view{ $name } = 1;
        pull_view_definition( $self, $name );
    }

    if( $self->{remove}{view} ) {
        for my $name ( $self->view_names ) {
            next if $self->__ignore_view( $name );

            # Don't remove this view, it was found in the database.
            next if $db_view{$name};

            $self->remove_view_sql( $name );
        }
    }
}

### TRIGGER ###

=item $o->trigger_fragments ()

Return list of trigger fragment names.

=cut

sub trigger_fragments : method
{
    my $self = shift;

    my $dir = "$self->{dir}/trigger";
    return () unless -d $dir;
    my $dh;
    opendir $dh, $dir;

    my @fragments = ();
    for my $file ( sort readdir $dh ) {
        my($name, $time, $action, $table) =
            $file =~ m/^
                (.+)\.(before|after)\.(insert|update|delete)\.(.+)\.sql$
            /x or next;
        push @fragments, {
            action => $action,
            file => $file,
            name => $name,
            table => $table,
            time => $time,
        };
    }

    return @fragments;
}

=item $o->assemble_triggers ()

Assemble trigger fragments into nested hash of triggers.

=cut

sub assemble_triggers : method
{
    my $self = shift;

    my %triggers = ();
    for my $fragment ( $self->trigger_fragments ) {

        my $sql = $self->read_trigger_fragment_sql( $fragment );
        my($table, $action, $time, $name) =
            @{$fragment}{'table', 'action', 'time', 'name'};

        $triggers{$table}{$action}{$time} ||= '';
        $triggers{$table}{$action}{$time} .=
            "/** begin $name */\n$sql/** end $name */\n";
    }

    return %triggers;
}

=item $o->read_trigger_fragment_sql ( \%fragment )

=cut

sub read_trigger_fragment_sql : method
{
    my $self = shift;
    my( $fragment ) = @_;

    # Slurp file.
    local $/;
    my $dir = "$self->{dir}/trigger";
    open my $fh, "<", "$dir/$fragment->{file}";
    my $sql = <$fh>;
    close $fh;

    return $sql;
}

=item $o->queue_push_trigger_definitions()

=cut

sub queue_push_trigger_definitions : method
{
    my $self = shift;

    my %triggers = $self->assemble_triggers();
    my %current_triggers = $self->pull_trigger_definitions();

    for my $table ( sort keys %triggers ) {

        next if $self->__ignore_table( $table );

        for my $action ( sort keys %{$triggers{$table}} ) {
            for my $time ( sort keys %{$triggers{$table}{$action}} ) {
                my $new = $triggers{$table}{$action}{$time};
                my $current = $current_triggers{$table}{$action}{$time};

                my $create_sql =
                    "CREATE TRIGGER `${time}_${action}_${table}` " .
                    "$time $action ON `$table` FOR EACH ROW BEGIN\n${new}END";

                if( not $current ) {
                    $self->__queue_sql( 'create_trigger',
                        "Create $time $action on $table trigger.",
                        $create_sql,
                    );
                } elsif( $current->{sql} ne $new ) {
                    $self->__queue_sql( 'drop_trigger',
                        "Drop $time $action on $table trigger.",
                        "DROP TRIGGER IF EXISTS `$current->{name}`",
                    );
                    $self->__queue_sql( 'create_trigger',
                        "Create $time $action on $table trigger.",
                        $create_sql,
                    );
                }
            }
        }
    }

    # Check if any triggers should be dropped.
    if( $self->{remove}{trigger} ) {
        for my $table ( sort keys %current_triggers ) {

            next if $self->__ignore_table( $table );

            for my $action ( sort keys %{$current_triggers{$table}} ) {
                for my $time (
                    sort keys %{$current_triggers{$table}{$action}}
                ) {
                    next if $triggers{$table}{$action}{$time};
                    my $trigger = $current_triggers{$table}{$action}{$time};

                    $self->__queue_sql( 'drop_trigger',
                        "Drop $time $action on $table trigger.",
                        "DROP TRIGGER IF EXISTS `$trigger->{name}`",
                    );
                }
            }
        }
    }
}

=item $o->pull_trigger_definitions ()

=cut

sub pull_trigger_definitions : method
{
    my $self = shift;
    my $dbh = $self->{dbh};

    my $list_sth = $dbh->prepare( 'SHOW TRIGGERS' );
    $list_sth->execute();

    my %triggers;
    while( my($trigger_name, $action, $table, $sql, $time) =
        $list_sth->fetchrow_array()
    ) {
        next if $self->__ignore_table( $table );

        # Strip off BEGIN and END from trigger body
        $sql =~ s/^\s*BEGIN\s*(.*)END\s*$/$1/s;

        # Lowercase is easier to read
        $action = lc $action;
        $time = lc $time;

        $triggers{$table}{$action}{$time} = {
            sql => $sql,
            name => $trigger_name,
        };
    }

    return %triggers;
}

=item $o->pull_trigger_fragments : method

=cut

sub pull_trigger_fragments : method
{
    my($self) = @_;

    my %triggers = pull_trigger_definitions( $self );

    # Variable to track fragments.
    my %found_fragments = ();

    for my $table ( sort keys %triggers ) {

        next if $self->__ignore_table( $table );

        for my $action ( sort keys %{$triggers{$table}} ) {
            for my $time ( sort keys %{$triggers{$table}{$action}} ) {
                my $trigger_sql = $triggers{$table}{$action}{$time}{sql};

                # Parse all tagged trigger fragments
                while( $trigger_sql =~ s{
                    /\*\*\s+begin\s+(\S+)\s+\*/\s*(.*)/\*\*\s+end\s+\1\s+\*/\s*
                }{}sx ) {
                    my( $name, $sql ) = ($1, $2);
                    $self->write_trigger_fragment_sql(
                        $name, $time, $action, $table, $sql
                    );
                    $found_fragments{$table}{$action}{$time}{$name} = 1;
                }

                # Handle any untagged trigger SQL?
                $trigger_sql =~ s/\s*$//;
                if( $trigger_sql ) {
                    if( $self->{init_trigger_name} ) {
                        my $name = $self->{init_trigger_name};
                        $self->write_trigger_fragment_sql(
                            $name, $time, $action, $table, $trigger_sql
                        );
                        $found_fragments{$table}{$action}{$time}{$name} = 1;
                    } else {
                        die "Found unlabeled trigger code for " .
                        "$time $action `$table`!\n$trigger_sql\n" .
                        "Do you need to specify --init-trigger-name=NAME?\n";
                    }
                }
            }
        }
    }

    # Remove trigger fragment not found during pull.
    if( $self->{remove}{trigger} ) {
        for my $fragment ( $self->trigger_fragments ) {
            my($table, $action, $time, $name) =
                @{$fragment}{'table', 'action', 'time', 'name'};
            next if $found_fragments{$table}{$action}{$time}{$name};

            $self->remove_trigger_fragment( $fragment );
        }
    }
}

### PROCEDURE ###

=item $o->procedure_names()

=cut

sub procedure_names
{
    my $self = shift;
    my @names;
    return () unless -d "$self->{dir}/procedure";

    opendir my $dh, "$self->{dir}/procedure";
    while( my $sql = readdir $dh ) {
        my($name) = $sql =~ m/^(.*)\.sql$/
            or next;
        push @names, $name;
    };

    return @names;
}

=item $o->read_procedure_sql ( $name )

=cut

sub read_procedure_sql
{
    my $self = shift;
    my($name) = @_;

    # File slurp mode.
    local $/;

    open my $fh, "$self->{dir}/procedure/$name.sql";
    my $sql = <$fh>;
    close $fh;

    return $sql;
}

=item $o->queue_push_procedure ( $name )

=cut

sub queue_push_procedure : method
{
    my $self = shift;
    my( $name ) = @_;

    my $new_sql = $self->read_procedure_sql( $name );

    my($current_sql);
    eval {
        $current_sql = $self->pull_procedure_sql( $name );
    };

    if( $current_sql ) {
        if( $new_sql ne $current_sql ) {
            $self->queue_drop_procedure( $name, $new_sql );
            $self->queue_create_procedure( $name, $new_sql );
        }
    } else {
        $self->queue_create_procedure( $name, $new_sql );
    }
}

=item $o->queue_drop_procedure ( $name )

=cut

sub queue_drop_procedure : method
{
    my $self = shift;
    my($name) = @_;

    $self->__queue_sql( 'drop_procedure',
        "Drop procedure $name\n",
        "DROP PROCEDURE `$name`",
    );
}

=item $o->queue_create_procedure ( $name, $sql )

=cut

sub queue_create_procedure : method
{
    my $self = shift;
    my( $name, $sql ) = @_;

    $self->__queue_sql( 'create_procedure',
        "Create procedure $name\n",
        $sql,
    );
}

=item $o->queue_push_procedures ()

=cut

sub queue_push_procedures
{
    my $self = shift;

    my @procedures = $self->procedure_names;
    for my $procedure ( @procedures ) {
        $self->queue_push_procedure( $procedure );
    }

    if( $self->{remove}{procedure} ) {
        for my $name ( $self->query_procedure_names ) {
            next if grep { $_ eq $name } @procedures;
            $self->queue_drop_procedure( $name );
        }
    }
}

=item $o->query_procedure_names ()

=cut

sub query_procedure_names : method
{
    my $self = shift;
    my $dbh = $self->{dbh};

    my $sth = $dbh->prepare( 'SHOW PROCEDURE STATUS WHERE Db=?' );
    $sth->execute($self->{connect}{schema});

    my @names = ();
    while( my $procedure = $sth->fetchrow_hashref() ) {
        push @names, $procedure->{Name};
    }

    return @names;
}

=item $o->remove_procedure_sql( $name )

=cut

sub remove_procedure_sql : method
{
    my $self = shift;
    my( $name ) = @_;
    unlink "$self->{dir}/procedure/$name.sql";
}

=item $o->pull_procedure_sql ( $name )

=cut

sub pull_procedure_sql : method
{
    my $self = shift;
    my($name) = @_;
    my $dbh = $self->{dbh};

    my $desc_sth = $dbh->prepare( "SHOW CREATE PROCEDURE `$name`" );
    $desc_sth->execute();
    my $desc = $desc_sth->fetchrow_hashref();
    my $sql = $desc->{'Create Procedure'};
    $sql .= "\n" unless $sql =~ m/\n$/;
    return $sql;
}

=item $o->pull_procedures ()

=cut

sub pull_procedures : method
{
    my $self = shift;

    # Keep track of procedure names found on the database to support
    # remove feature.
    my %found_procedure;

    for my $name ( $self->query_procedure_names ) {
        $found_procedure{$name} = 1;

        my $sql = $self->pull_procedure_sql( $name );

        $self->write_procedure_sql( $name, $sql );
    }

    if( $self->{remove}{procedure} ) {
        for my $procedure ( $self->procedure_names ) {
            next if $found_procedure{ $procedure };
            $self->remove_procedure_sql( $procedure );
        }
    }
}

=item $o->write_procedure_sql( $name, $sql )

=cut

sub write_procedure_sql : method
{
    my $self = shift;
    my($name, $sql) = @_;
    my $fh;

    # Make table directory if required.
    mkdir "$self->{dir}/procedure"
        unless -d "$self->{dir}/procedure";

    open $fh, ">", "$self->{dir}/procedure/$name.sql";
    print $fh $sql;
    close $fh;
}

### GENERAL ###

=item $o->pull ()

Handle the pull command.

=cut

sub pull : method
{
    my $self = shift;

    $self->__dbi_connect() unless $self->{dbh} and $self->{dbh}->ping;

    $self->pull_table_definitions();
    $self->pull_view_definitions();
    $self->pull_trigger_fragments();
    $self->pull_procedures();
}

=item $o->push ()

Handle the push command.

=cut

sub push : method
{
    my $self = shift;

    $self->__dbi_connect() unless $self->{dbh} and $self->{dbh}->ping;

    $self->queue_push_table_definitions();
    $self->queue_push_view_definitions();
    $self->queue_push_trigger_definitions();
    $self->queue_push_procedures();

    $self->run_queue();
}

=item $o->run_queue()

Process any actions in todo queue. Returns number of actions executed.

=cut

sub run_queue : method
{
    my $self = shift;

    my $count = 0;
    for my $action ( TODO_ACTIONS ) {
        while( @{ $self->{todo}{$action} } ) {
            my $task = shift @{ $self->{todo}{$action} };
            ++$count;
            print $task->{desc}, "\n" unless $QUIET;
            print "\n$task->{sql}\n\n" if $VERBOSE or $DRYRUN;
            eval {
                $self->{dbh}->do( $task->{sql} ) unless $DRYRUN;
            };
            die "Error executing SQL: $@\n$task->{sql}\n" if $@;
        }
    }

    return $count;
}

=item $o->make_archive ()

Handle the make-archive command.

=cut

sub make_archive : method
{
    my $self = shift;

    # Detect tables by presence of revision column if option wasn't provided on
    # the command-line.
    my @tables_desc;
    if( @{ $self->{tables} } ) {
        # Get table information for all tables for which we will create/update
        # archive tables.
        @tables_desc = map { $self->get_table_desc( $_ ) } @{ $self->{tables} };
    } else {
        @tables_desc = $self->find_data_tables_with_revision( );
    }

    # Check that all source tables have required columns.
    for my $table ( @tables_desc ) {
        $self->check_table_is_archive_capable( $table );
    }

    # Basic checks done, we should be good to go to start making and updating
    # tables.
    for my $table ( @tables_desc ) {

        # Make archive table description from source data table
        my $archive_table = $self->make_archive_table_desc( $table );

        # Check if there is a current archive table.
        my $current_archive_table;
        eval { $current_archive_table = $self->get_table_desc(
            $archive_table->{name}
        ) };

        if( $current_archive_table ) {
            # Check if any updates are required.
            print "Archive table `$current_archive_table->{name}` " .
                  "found for `$table->{name}`.\n" if $VERBOSE;

            # Verify that the current archive table could be updated to new
            # requirements.
            $self->check_table_updatable(
                $current_archive_table,
                $archive_table
            );

            # Update the archive table definition.
            $self->write_table_definition( $archive_table );
        } else {
            print "Writing archive table `$archive_table->{name}` " .
                  "definition for `$table->{name}`.\n" if $VERBOSE;
            $self->write_table_definition( $archive_table );
        }

        $self->write_archive_trigger_fragments( $table, $archive_table );
    }
}

=item $o->set_dbh ()

Explicitly set the database handle.

=cut

sub set_dbh : method
{
    my $self = shift;
    my($dbh) = @_;
    $self->{dbh} = $dbh;
}

=back

=head1 AUTHOR

Johnathan Kupferer <jtk@uic.edu>

=head1 COPYRIGHT

Copyright (C) 2015 The University of Illinois at Chicago. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
