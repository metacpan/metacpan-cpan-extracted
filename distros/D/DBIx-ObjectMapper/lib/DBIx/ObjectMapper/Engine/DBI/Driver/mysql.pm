package DBIx::ObjectMapper::Engine::DBI::Driver::mysql;
use strict;
use warnings;
use Try::Tiny;
use Carp::Clan qw/^DBIx::ObjectMapper/;
use base qw(DBIx::ObjectMapper::Engine::DBI::Driver);

sub init {
    my $self = shift;
    try {
        require DateTime::Format::DBIMAPPER_MySQL;
        DateTime::Format::DBIMAPPER_MySQL->import;
        $self->{datetime_parser} ||= 'DateTime::Format::DBIMAPPER_MySQL';
    } catch {
        confess "Couldn't load DateTime::Format::DBIMAPPER_MySQL: $_";
    };
}

sub last_insert_id {
    my ( $self, $dbh, $table, $column ) = @_;
    $dbh->{mysql_insertid};
}

sub get_primary_key {
    my $self = shift;
    my $primary = $self->_mysql_table_get_keys(@_)->{PRIMARY} || return;
    return @$primary;
}

sub get_table_uniq_info {
    my $self = shift;

    my @uniqs;
    my $keydata = $self->_mysql_table_get_keys(@_);
    foreach my $keyname (keys %$keydata) {
        next if $keyname eq 'PRIMARY';
        push(@uniqs, [ $keyname => $keydata->{$keyname} ]);
    }
    return \@uniqs;
}

#  mostly based on DBIx::Class::Schema::Loader::DBI::mysql
sub _mysql_table_get_keys {
    my ($self, $dbh, $table) = @_;

    if(!exists($self->{_cache}->{_mysql_keys}->{$table})) {
        my %keydata;
        my $sth = $dbh->prepare("SHOW INDEX FROM `$table`");
        $sth->execute;
        while(my $row = $sth->fetchrow_hashref) {
            next if $row->{Non_unique};
            push(@{$keydata{$row->{Key_name}}},
                [ $row->{Seq_in_index}, lc $row->{Column_name} ]
            );
        }
        foreach my $keyname (keys %keydata) {
            my @ordered_cols = map { $_->[1] } sort { $a->[0] <=> $b->[0] }
                @{$keydata{$keyname}};
            $keydata{$keyname} = \@ordered_cols;
        }
        $self->{_cache}->{_mysql_keys}->{$table} = \%keydata;
    }

    return $self->{_cache}->{_mysql_keys}->{$table};
}

sub get_table_fk_info {
    my ($self, $dbh, $table) = @_;

    my $table_def_ref = $dbh->selectrow_arrayref("SHOW CREATE TABLE `$table`")
        or croak ("Cannot get table definition for $table");
    my $table_def = $table_def_ref->[1] || '';

    my (@reldata) = ($table_def =~ /CONSTRAINT `.*` FOREIGN KEY \(`(.*)`\) REFERENCES `(.*)` \(`(.*)`\)/ig);

    my @rels;
    while (scalar @reldata > 0) {
        my $cols = shift @reldata;
        my $f_table = shift @reldata;
        my $f_cols = shift @reldata;

        my @cols   = map { s/\Q$self->{quote}\E//; lc $_ } ## no critic
            split(/\s*,\s*/, $cols);

        my @f_cols = map { s/\Q$self->{quote}\E//; lc $_ } ## no critic
            split(/\s*,\s*/, $f_cols);

        push(@rels, {
            keys  => \@cols,
            refs  => \@f_cols,
            table => $f_table
        });
    }

    return \@rels;
}

sub get_tables {
    my ( $self, $dbh ) = @_;
    return $self->_truncate_quote_and_sep(
        $dbh->tables(undef, $self->db_schema, undef, undef) );
}

sub set_time_zone_query {
    my ( $self, $dbh ) = @_;
    my $tz = $self->time_zone || return;
    return "SET time_zone = " . $dbh->quote($tz);
}

sub set_savepoint {
    my ($self, $dbh, $name) = @_;
    $dbh->do("SAVEPOINT $name");
}

sub release_savepoint {
    my ($self, $dbh, $name) = @_;
    $dbh->do("RELEASE SAVEPOINT $name");
}

sub rollback_savepoint {
    my ($self, $dbh, $name) = @_;
    $dbh->do("ROLLBACK TO SAVEPOINT $name");
}


1;
