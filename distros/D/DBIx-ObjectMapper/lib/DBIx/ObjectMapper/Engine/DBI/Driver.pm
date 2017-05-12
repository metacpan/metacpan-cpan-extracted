package DBIx::ObjectMapper::Engine::DBI::Driver;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;
use DBIx::ObjectMapper::Utils;
use DBI;

sub new {
    my $class  = shift;
    my $driver = shift;
    my $dbh    = shift;
    my %attr   = @_;
    $attr{__cache} = undef;
    $attr{namesep} ||= $dbh->get_info(41) || q{.};
    $attr{quote}   ||= $dbh->get_info(29) || q{"};

    my $klass;
    if ( __PACKAGE__ eq $class ) {
        $klass = __PACKAGE__ . "::$driver";
    }
    else {
        $klass = $class;
    }

    DBIx::ObjectMapper::Utils::load_class($klass);

    my $self = bless \%attr, $klass;
    $self->init($dbh);

    return $self;
}

sub db_schema { $_[0]->{db_schema} }
sub query     { $_[0]->{query} }
sub log       { $_[0]->{log} }
sub namesep   { $_[0]->{namesep} }
sub quote     { $_[0]->{quote} }
sub time_zone { $_[0]->{time_zone} }

sub init { }

sub get_primary_key {
    my ( $self, $dbh, $table ) = @_;
    my @primary_key = $dbh->primary_key( undef, $self->db_schema, $table );
    @primary_key = $dbh->primary_key( undef, undef, $table )
        unless @primary_key;
    return @primary_key;
}

# mostly based on DBIx::Class::Loader::DBI
sub get_column_info {
    my ( $self, $dbh, $table ) = @_;

    if ( $dbh->can('column_info') ) {
        my @result;
        eval {
            my $sth
                = $dbh->column_info( undef, $self->db_schema, $table, '%' );
            while ( my $info = $sth->fetchrow_hashref() ) {
                my %column_info;
                $column_info{type}        = lc( $info->{TYPE_NAME} );
                $column_info{size}        = $info->{COLUMN_SIZE};
                $column_info{is_nullable} = $info->{NULLABLE} ? 1 : 0;
                $column_info{default}     = $info->{COLUMN_DEF};
                my $col_name = $info->{COLUMN_NAME};
                $col_name =~ s/^\"(.*)\"$/$1/;
                $column_info{name} = $col_name;
                push @result, \%column_info;
            }

            $sth->finish;
        };
        return \@result if !$@ && @result;
    }

    if ( $self->db_schema ) {
        $table = $self->db_schema . $self->namesep . $table;
    }

    my @result;
    my $sql = $self->query->select(
        from  => $table,
        where => [ 1, 0 ],
    );

    my $sth = $dbh->prepare( $sql->as_sql );
    $sth->execute;
    my @columns = @{ $sth->{NAME_lc} };
    for my $i ( 0 .. $#columns ) {
        my %column_info;
        $column_info{type}        = $sth->{TYPE}->[$i];
        $column_info{size}        = $sth->{PRECISION}->[$i];
        $column_info{is_nullable} = $sth->{NULLABLE}->[$i] ? 1 : 0;

        if ( $column_info{type} =~ m/^(.*?)\((.*?)\)$/ ) {
            $column_info{type} = $1;
            $column_info{size} = $2;
        }
        $column_info{name} = $columns[$i];
        push @result, \%column_info;
    }
    $sth->finish;

    foreach my $colinfo (@result) {
        my $type_num = $colinfo->{type};
        my $type_name;
        if ( defined $type_num && $dbh->can('type_info') ) {
            my $type_info = $dbh->type_info($type_num);
            $type_name = lc( $type_info->{TYPE_NAME} ) if $type_info;
            $colinfo->{type} = $type_name if $type_name;
        }
    }

    return \@result;
}

sub get_table_uniq_info {
    my ( $self, $dbh, $table ) = @_;

    unless ( $dbh->can('statistics_info') ) {
        $self->log->warn('Can not get UNIQUE constraint this vendor.');
        return [];
    }

    my $sth = $dbh->statistics_info( undef, $self->db_schema, $table, 1, 1 );
    my %uniq_info;
    while ( my $ref = $sth->fetchrow_hashref ) {
        next
            unless $ref->{COLUMN_NAME}
                and $ref->{TYPE} ne 'table'
                and $ref->{INDEX_NAME}
                and !defined( $ref->{FILTER_CONDITION} );
        $uniq_info{ $ref->{INDEX_NAME} }->{ $ref->{ORDINAL_POSITION} }
            = $ref->{COLUMN_NAME};
    }
    $sth->finish;

    my @uniq_info;
    for my $name ( keys %uniq_info ) {
        push @uniq_info,  [
            $name => [
                map { $uniq_info{$name}->{$_} }
                sort keys %{ $uniq_info{$name} }
            ]
        ];
    }

    return \@uniq_info;
}

sub get_table_fk_info {
    my ( $self, $dbh, $table ) = @_;

    my $sth = $dbh->foreign_key_info( '', $self->db_schema, '', '',
        $self->db_schema, $table );
    return [] if !$sth;

    my %rels;
    my $quote = $self->quote;

    my $i = 1;    # for unnamed rels, which hopefully have only 1 column ...
    while ( my $raw_rel = $sth->fetchrow_arrayref ) {
        my $uk_tbl = $raw_rel->[2];
        my $uk_col = lc $raw_rel->[3];
        my $fk_col = lc $raw_rel->[7];
        my $relid  = ( $raw_rel->[11] || ( "__dcsld__" . $i++ ) );
        $uk_tbl =~ s/\Q$quote\E//g;
        $uk_col =~ s/\Q$quote\E//g;
        $fk_col =~ s/\Q$quote\E//g;
        $relid  =~ s/\Q$quote\E//g;
        $rels{$relid}->{tbl} = $uk_tbl;
        $rels{$relid}->{cols}->{$uk_col} = $fk_col;
    }
    $sth->finish;

    my @rels;
    foreach my $relid ( keys %rels ) {
        push(
            @rels,
            {   refs  => [ keys %{ $rels{$relid}->{cols} } ],
                keys  => [ values %{ $rels{$relid}->{cols} } ],
                table => $rels{$relid}->{tbl},
            }
        );
    }

    return \@rels;
}

sub get_tables {
    my ( $self, $dbh ) = @_;
    $self->_truncate_quote_and_sep(
        $dbh->tables(undef, $self->db_schema, '%', '%') );
}

sub _truncate_quote_and_sep {
    my ( $self, @str ) = @_;
    my $quote   = $self->quote;
    my $namesep = $self->namesep;
    s/\Q$quote\E//g for @str;
    s/^.*\Q$namesep\E// for @str;
    return @str;
}

sub last_insert_id { }

sub datetime_parser {
    my $self = shift;
    return $self->{__cache}{datetime_parser} || do {
        my $parser = $self->{datetime_parser};
        $self->{__cache}{datetime_parser} = $parser;
    };
}

sub set_time_zone_query { }

sub escape_binary_func {
    my $self = shift;
    my $dbh  = shift;
    return sub {
        my $val = shift;
        return \$dbh->quote($val, DBI::SQL_BLOB);
    };
}

sub set_savepoint {}

sub release_savepoint {}

sub rollback_savepoint {}

1;
