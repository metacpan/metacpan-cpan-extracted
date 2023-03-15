package Bot::BasicBot::Pluggable::Store::DBI;
$Bot::BasicBot::Pluggable::Store::DBI::VERSION = '1.30';
use warnings;
use strict;
use Carp qw( croak );
use Data::Dumper;
use DBI;
use Storable qw( nfreeze thaw );
use Try::Tiny;

use base qw( Bot::BasicBot::Pluggable::Store );

sub init {
    my $self = shift;
    $self->{dsn}   ||= 'dbi:SQLite:bot-basicbot.sqlite';
    $self->{table} ||= 'basicbot';
    $self->create_table;
}

sub dbh {
    my $self     = shift;
    my $dsn      = $self->{dsn} or die "I need a DSN";
    my $user     = $self->{user};
    my $password = $self->{password};
    return DBI->connect_cached( $dsn, $user, $password );
}

sub create_table {
    my $self  = shift;
    my $table = $self->{table} or die "Need DB table";
    my $sth   = $self->dbh->table_info( '%', '%', $table, "TABLE" );

	$table = $self->dbh->quote_identifier($table);

    if ( !$sth->fetch ) {
        $self->dbh->do(
            "CREATE TABLE $table (
			    id INT PRIMARY KEY,
			    namespace TEXT,
			    store_key TEXT,
			    store_value LONGBLOB )"
        );
        if ( $self->{create_index} ) {
            try {
                $self->dbh->do(
"CREATE INDEX lookup ON $table ( namespace(10), store_key(10) )"
                );
            };
        }
    }
}

sub get {
    my ( $self, $namespace, $key ) = @_;
    my $table = $self->{table} or die "Need DB table";

	$table = $self->dbh->quote_identifier($table);

    my $sth = $self->dbh->prepare_cached(
        "SELECT store_value FROM $table WHERE namespace=? and store_key=?");
    $sth->execute( $namespace, $key );
    my $row = $sth->fetchrow_arrayref;
    $sth->finish;
    return unless $row and @$row;
    return try { thaw( $row->[0] ) } catch { $row->[0] };
}

sub set {
    my ( $self, $namespace, $key, $value ) = @_;
    my $table = $self->{table} or die "Need DB table";

	$table = $self->dbh->quote_identifier($table);

    $value = nfreeze($value) if ref($value);
    if ( defined( $self->get( $namespace, $key ) ) ) {
        my $sth = $self->dbh->prepare_cached(
            "UPDATE $table SET store_value=? WHERE namespace=? AND store_key=?"
        );
        $sth->execute( $value, $namespace, $key );
        $sth->finish;
    }
    else {
        my $sth = $self->dbh->prepare_cached(
"INSERT INTO $table (id, store_value, namespace, store_key) VALUES (?, ?, ?, ?)"
        );
        $sth->execute( $self->new_id($table), $value, $namespace, $key );
        $sth->finish;
    }
    return $self;
}

sub unset {
    my ( $self, $namespace, $key ) = @_;
    my $table = $self->{table} or die "Need DB table";

	$table = $self->dbh->quote_identifier($table);

    my $sth = $self->dbh->prepare_cached(
        "DELETE FROM $table WHERE namespace=? and store_key=?");
    $sth->execute( $namespace, $key );
    $sth->finish;
}

sub new_id {
    my $self  = shift;
    my $table = shift;
    my $sth   = $self->dbh->prepare_cached("SELECT MAX(id) FROM $table");
    $sth->execute();
    my $id = $sth->fetchrow_arrayref->[0] || "0";
    $sth->finish();
    return $id + 1;
}

sub keys {
    my ( $self, $namespace, %opts ) = @_;
    my $table = $self->{table} or die "Need DB table";

	$table = $self->dbh->quote_identifier($table);

    my @res = ( exists $opts{res} ) ? @{ $opts{res} } : ();

    my $sql = "SELECT store_key FROM $table WHERE namespace=?";

    my @args = ($namespace);

    foreach my $re (@res) {
        my $orig = $re;

        # h-h-h-hack .... convert to SQL and limit terms if too general
        $re = "%$re"               if $re !~ s!^\^!!;
        $re = "$re%"               if $re !~ s!\$$!!;
        $re = "${namespace}_${re}" if $orig =~ m!^[^\^].*[^\$]$!;

        $sql .= " AND store_key LIKE ?";
        push @args, $re;
    }
    if ( exists $opts{limit} ) {
        $sql .= " LIMIT ?";
        push @args, $opts{limit};
    }

    my $sth = $self->dbh->prepare_cached($sql);
    $sth->execute(@args);

    return $sth->rows if $opts{_count_only};

    my @keys = map { $_->[0] } @{ $sth->fetchall_arrayref };
    $sth->finish;
    return @keys;
}

sub namespaces {
    my ($self) = @_;
    my $table = $self->{table} or die "Need DB table";

	$table = $self->dbh->quote_identifier($table);

    my $sth =
      $self->dbh->prepare_cached("SELECT DISTINCT namespace FROM $table");
    $sth->execute();
    my @keys = map { $_->[0] } @{ $sth->fetchall_arrayref };
    $sth->finish;
    return @keys;
}

1;

__END__

=head1 NAME

Bot::BasicBot::Pluggable::Store::DBI - use DBI to provide a storage backend

=head1 VERSION

version 1.30

=head1 SYNOPSIS

  my $store = Bot::BasicBot::Pluggable::Store::DBI->new(
    dsn          => "dbi:mysql:bot",
    user         => "user",
    password     => "password",
    table        => "brane",

    # create indexes on key/values?
    create_index => 1,
  );

  $store->set( "namespace", "key", "value" );
  
=head1 DESCRIPTION

This is a L<Bot::BasicBot::Pluggable::Store> that uses a database to store
the values set by modules. Complex values are stored using Storable.

=head1 AUTHOR

Mario Domgoergen <mdom@cpan.org>

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
