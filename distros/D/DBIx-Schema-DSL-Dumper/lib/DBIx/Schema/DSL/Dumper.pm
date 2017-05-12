package DBIx::Schema::DSL::Dumper;
use 5.008001;
use strict;
use warnings;
use DBIx::Inspector;
use DBIx::Inspector::Iterator;
use Carp ();

our $VERSION = "0.07";

# XXX copy from SQL::Translator::Parser::DBI-1.59
use constant DRIVERS => {
    mysql            => 'MySQL',
    odbc             => 'SQLServer',
    oracle           => 'Oracle',
    pg               => 'PostgreSQL',
    sqlite           => 'SQLite',
    sybase           => 'Sybase',
    pg               => 'PostgreSQL',
    db2              => 'DB2',
};

sub dump {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    my $dbh = $args{dbh} or Carp::croak("missing mandatory parameter 'dbh'");

    my $inspector = DBIx::Inspector->new(dbh => $dbh);

    my $ret = "";

    if ( ref $args{tables} eq "ARRAY" ) {
        for my $table_name (@{ $args{tables} }) {
            $ret .= _render_table($inspector->table($table_name), \%args);
        }
    }
    elsif ( $args{tables} ) {
        $ret .= _render_table($inspector->table($args{tables}), \%args);
    }
    else {
        my $pkg = $args{pkg} or Carp::croak("missing mandatory parameter 'pkg'");

        $ret .= "package ${pkg};\n";
        $ret .= "use strict;\n";
        $ret .= "use warnings;\n";
        $ret .= "use DBIx::Schema::DSL;\n";
        $ret .= "\n";

        my $db_type = $dbh->{'Driver'}{'Name'} or die 'Cannot determine DBI type';
        my $driver  = DRIVERS->{ lc $db_type } or warn "$db_type not supported";
        $ret .= sprintf("database '%s';\n", $driver) if $driver;
        $ret .= "default_unsigned;\n" if $args{default_unsigned};
        $ret .= "default_not_null;\n" if $args{default_not_null};
        $ret .= "\n";

        if ($args{table_options}) {
            $ret .= "add_table_options\n";
            my @table_options;
            for my $key (keys %{$args{table_options}}) {
                push @table_options => sprintf("    '%s' => '%s'", $key, $args{table_options}->{$key})
            }
            $ret .= join ",\n", @table_options;
            $ret .= ";\n\n";
        }

        for my $table_info (sort { $a->name cmp $b->name } $inspector->tables) {
            $ret .= _render_table($table_info, \%args);
        }
        $ret .= "1;\n";
    }

    return $ret;
}


sub _render_table {
    my ($table_info, $args) = @_;

    my $ret = "";

    $ret .= sprintf("create_table '%s' => columns {\n", $table_info->name);

    for my $col ($table_info->columns) {
        $ret .= _render_column($col, $table_info, $args);
    }

    $ret .= _render_index($table_info, $args);

    $ret .= "};\n\n";

    return $ret;
}

sub _render_column {
    my ($column_info, $table_info, $args) = @_;

    my $ret = "";
    $ret .= sprintf("    column '%s'", $column_info->name);

    my ($type, @opt) = split / /, $column_info->type_name;

    if ($column_info->{MYSQL_TYPE_NAME}) {
        push @opt => split / /, $column_info->{MYSQL_TYPE_NAME};
    }

    $ret .= sprintf(", '%s'", $type);

    my %opt = map { lc($_) => 1 } @opt;

    if (lc($type) =~ /^(enum|set)$/) {
        # XXX
        $ret .= sprintf(" => ['%s']", join "','", @{$column_info->{MYSQL_VALUES}});
    }

    $ret .= ", signed"   if $opt{signed};
    $ret .= ", unsigned" if $opt{unsigned} && !$args->{default_unsigned};

    if (defined $column_info->column_size) {
        my $column_size;

        if (lc($type) eq 'decimal') {
            # XXX
            $column_size = sprintf("[%d, %d]", $column_info->column_size, $column_info->{DECIMAL_DIGITS});
        }
        elsif (lc($type) =~ /^(enum|set)$/) {
            ;;
        }
        # TODO use DBIx::Schema::DSL->context->default_varchar_size
        elsif (lc($type) eq 'varchar' && $column_info->column_size == 255) {
            ;;
        }
        elsif (
            lc($type) =~ /^(int|integer)$/ &&
            (
                $opt{unsigned} && $column_info->column_size == 10
                or
                !$opt{unsigned} && $column_info->column_size == 11
            )
        ) {
            ;;
        }
        elsif ($column_info->{MYSQL_TYPE_NAME} && $column_info->{MYSQL_TYPE_NAME} !~ $column_info->column_size) {
            ;;
        }
        else {
            $column_size = $column_info->column_size;
        }


        $ret .= sprintf(", size => %s", $column_size) if $column_size;
    }

    $ret .= ", null"     if $column_info->nullable;
    $ret .= ", not_null" if !$column_info->nullable && !$args->{default_not_null};

    if (defined $column_info->column_def) {
        my $column_def = $column_info->column_def;

        if ($type =~ /^(TIMESTAMP|DATETIME)$/ && $column_def eq 'CURRENT_TIMESTAMP') {
            $ret .= sprintf(", default => \\'%s'", $column_def)
        }
        else {
            $ret .= sprintf(", default => '%s'", $column_def)
        }
    }

    if (
        $opt{auto_increment} or
        # XXX
        ($args->{dbh}->{'Driver'}{'Name'} eq 'mysql' && $column_info->{MYSQL_IS_AUTO_INCREMENT})
    ) {
        $ret .= ", auto_increment"
    }

    $ret .= ";\n";

    return $ret;
}

# FIXME not supported UPDATE_RULE, DELETE_RULE
sub _render_index {
    my ($table_info, $args) = @_;

    my $ret = "";

    # index
    my $ret_primary_key = "";
    my $ret_index_key   = "";
    my $ret_foreign_key = "";

    my @fk_list = $table_info->fk_foreign_keys(+{ pk_schema => $table_info->schema });
    for my $fk (@fk_list) {

        if ($fk->fkcolumn_name eq sprintf('%s_id', $fk->pktable_name)) {
            $ret_foreign_key .= sprintf("    belongs_to '%s';\n", $fk->pktable_name)
        }
        elsif ($fk->fkcolumn_name eq 'id' && $fk->pkcolumn_name eq sprintf('%s_id', $fk->fktable_name)) {

            my $itr = _statistics_info($args->{dbh}, $table_info->schema, $fk->pktable_name);
            while (my $index_key = $itr->next) {
                if ($index_key->column_name eq $fk->pkcolumn_name) {
                    my $has = $index_key->non_unique ? 'has_many' : 'has_one';
                    $ret_foreign_key .= sprintf("    %s '%s'\n", $has, $fk->pktable_name);
                    last;
                }
            }
        }
        elsif ($fk->pktable_name && $fk->pkcolumn_name) {
            $ret_foreign_key .= sprintf("    foreign_key '%s' => '%s','%s'\n", $fk->fkcolumn_name, $fk->pktable_name, $fk->pkcolumn_name);
        }
    }

    my %fkcolumn_map = map { $_->fkcolumn_name => $_ } @fk_list;
    my %statistics_info_map;
    my $statistics_info = _statistics_info($args->{dbh}, $table_info->schema, $table_info->name);
    while (my $statistics = $statistics_info->next) {
        push @{$statistics_info_map{$statistics->index_name}} => $statistics;
    }

    for my $index_name (sort keys %statistics_info_map) {
        my @statistics_list = @{$statistics_info_map{$index_name}};
        my @column_names = map { $_->column_name } sort { $a->{ORDINAL_POSITION} <=> $b->{ORDINAL_POSITION} } @statistics_list;

        if (lc($index_name) eq 'primary') {
            $ret_primary_key .= sprintf("    set_primary_key '%s';\n", join "','", @column_names);
        }
        else {
            # fkcolumn is index automatically
            next if @column_names == 1 && $fkcolumn_map{$column_names[0]};

            $ret_index_key .= sprintf("    add_%sindex '%s' => [%s]%s;\n",
                                $statistics_list[0]->non_unique ? '' : 'unique_',
                                $index_name,
                                (join ",", (map { q{'}.$_.q{'} } @column_names)),
                                $statistics_list[0]->non_unique &&
                                $statistics_list[0]->type && lc($statistics_list[0]->type) ne 'btree' ? sprintf(", '%s'", $statistics_list[0]->type) : '',
                            );
        }
    }

    if ($ret_primary_key or $ret_index_key or $ret_foreign_key) {
        $ret .= "\n";
        $ret .= $ret_primary_key if $ret_primary_key;
        $ret .= $ret_index_key   if $ret_index_key;
        $ret .= $ret_foreign_key if $ret_foreign_key;
    }

    return $ret;
}

# EXPERIMENTAL: https://metacpan.org/pod/DBI#statistics_info
sub _statistics_info {
    my ($dbh, $schema, $table_name) = @_;

    my $sth;
    if ($dbh->{'Driver'}{'Name'} eq 'mysql') {
        # TODO p-r DBD::mysqld ??
        my $sql = q{
            SELECT
                TABLE_CATALOG AS TABLE_CAT,
                TABLE_SCHEMA  AS TABLE_SCHEM,
                TABLE_NAME,
                NON_UNIQUE,
                NULL          AS INDEX_QUALIFIER,
                INDEX_NAME,
                INDEX_TYPE    AS TYPE,
                SEQ_IN_INDEX  AS ORDINAL_POSITION,
                COLUMN_NAME,
                NULL          AS ASC_OR_DESC,
                CARDINALITY,
                NULL          AS PAGES,
                NULL          AS FILTER_CONDITION,

                SUB_PART,
                PACKED,
                NULLABLE,
                INDEX_TYPE,
                COMMENT
            FROM
                INFORMATION_SCHEMA.STATISTICS
            WHERE
                table_schema = ?
                AND table_name = ?
        };
        $sth = $dbh->prepare($sql);
        $sth->execute($schema, $table_name);
    }
    else {
        $sth = $dbh->statistics_info(undef, undef, $table_name, undef, undef);
    }

    DBIx::Inspector::Iterator->new(
        sth => $sth,
        callback => sub {
            # TODO p-r DBIx::Inspector ??
            my $row = shift;
            DBIx::Inspector::Statics->new($row);
        },
    );
}

package # hide from PAUSE
    DBIx::Inspector::Statics;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;
    bless {%args}, $class;
}

{
    no strict 'refs';
    for my $k (
        qw/
            TABLE_CAT
            TABLE_SCHEM
            TABLE_NAME
            NON_UNIQUE
            INDEX_QUALIFIER
            INDEX_NAME
            TYPE
            ORDINAL_POSITION
            COLUMN_NAME
            ASC_OR_DESC
            CARDINALITY
            PAGES
            FILTER_CONDITION
        /
      )
    {
        *{ __PACKAGE__ . "::" . lc($k) } = sub { $_[0]->{$k} };
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

DBIx::Schema::DSL::Dumper - DBIx::Schema::DSL generator

=head1 SYNOPSIS

    use DBIx::Schema::DSL::Dumper;

    print DBIx::Schema::DSL::Dumper->dump(
        dbh => $dbh,
        pkg => 'Foo::DSL',

        # Optional. Default values is same as follows.
        default_not_null => 0,
        default_unsigned => 0,

        # Optional.
        table_options => +{
            'mysql_table_type' => 'InnoDB',
            'mysql_charset'    => 'utf8',
        }
    );

    # or

    print DBIx::Schema::DSL::Dumper->dump(
        dbh    => $dbh,
        tables => [qw/foo bar/],
    );

=head1 DESCRIPTION

This module generates the Perl code to generate DBIx::Schema::DSL.

=head1 SEE ALSO

L<DBIx::Schema::DSL>, L<Teng::Schema::Dumper>

=head1 LICENSE

Copyright (C) Kenta, Kobayashi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kenta, Kobayashi E<lt>kentafly88@gmail.comE<gt>

=cut

