package CGI::Wiki::Setup::Pg;

use strict;

use vars qw( $VERSION );
$VERSION = '0.08';

use DBI;
use Carp;

my %create_sql = (
    node => [ qq|
CREATE TABLE node (
  name      varchar(200) NOT NULL DEFAULT '',
  version   integer      NOT NULL default 0,
  text      text         NOT NULL default '',
  modified  timestamp without time zone    default NULL
)
|, qq|
CREATE UNIQUE INDEX node_pkey ON node (name)
| ],

    content => [ qq|
CREATE TABLE content (
  name      varchar(200) NOT NULL default '',
  version   integer      NOT NULL default 0,
  text      text         NOT NULL default '',
  modified  timestamp without time zone    default NULL,
  comment   text         NOT NULL default ''
)
|, qq|
CREATE UNIQUE INDEX content_pkey ON content (name, version)
| ],

    internal_links => [ qq|
CREATE TABLE internal_links (
  link_from varchar(200) NOT NULL default '',
  link_to   varchar(200) NOT NULL default ''
)
|, qq|
CREATE UNIQUE INDEX internal_links_pkey ON internal_links (link_from, link_to)
| ],

    metadata => [ qq|
CREATE TABLE metadata (
  node           varchar(200) NOT NULL DEFAULT '',
  version        integer      NOT NULL default 0,
  metadata_type  varchar(200) NOT NULL DEFAULT '',
  metadata_value text         NOT NULL DEFAULT ''
)
|, qq|
CREATE INDEX metadata_index ON metadata (node, version, metadata_type, metadata_value)
| ]

);

=head1 NAME

CGI::Wiki::Setup::Pg - Set up tables for a CGI::Wiki store in a Postgres database.

=head1 SYNOPSIS

  use CGI::Wiki::Setup::Pg;
  CGI::Wiki::Setup::Pg::setup($dbname, $dbuser, $dbpass, $dbhost);

Omit $dbhost if the database is local.

=head1 DESCRIPTION

Set up a Postgres database for use as a CGI::Wiki store.

=head1 FUNCIONS

=over 4

=item B<setup>

  use CGI::Wiki::Setup::Pg;
  CGI::Wiki::Setup::Pg::setup($dbname, $dbuser, $dbpass, $dbhost);

or

  CGI::Wiki::Setup::Pg::setup( $dbh );

You can either provide an active database handle C<$dbh> or connection
parameters.                                                                    

If you provide connection parameters the following arguments are
mandatory -- the database name, the username and the password. The
username must be able to create and drop tables in the database.

The $dbhost argument is optional -- omit it if the database is local.

B<NOTE:> If a table that the module wants to create already exists,
C<setup> will leave it alone. This means that you can safely run this
on an existing L<CGI::Wiki> database to bring the schema up to date
with the current L<CGI::Wiki> version. If you wish to completely start
again with a fresh database, run C<cleardb> first.

=cut

sub setup {
    my @args = @_;
    my $dbh = _get_dbh( @args );
    my $disconnect_required = _disconnect_required( @args );

    # Check whether tables exist, set them up if not.
    my $sql = "SELECT tablename FROM pg_tables
               WHERE tablename in ("
            . join( ",", map { $dbh->quote($_) } keys %create_sql ) . ")";
    my $sth = $dbh->prepare($sql) or croak $dbh->errstr;
    $sth->execute;
    my %tables;
    while ( my $table = $sth->fetchrow_array ) {
        $tables{$table} = 1;
    }

    foreach my $required ( keys %create_sql ) {
        if ( $tables{$required} ) {
            print "Table $required already exists... skipping...\n";
        } else {
            print "Creating table $required... done\n";
            foreach my $sql ( @{ $create_sql{$required} } ) {
                $dbh->do($sql) or croak $dbh->errstr;
            }
        }
    }

    # Clean up if we made our own dbh.
    $dbh->disconnect if $disconnect_required;
}

=item B<cleardb>

  use CGI::Wiki::Setup::Pg;

  # Clear out all CGI::Wiki tables from the database.
  CGI::Wiki::Setup::Pg::cleardb($dbname, $dbuser, $dbpass, $dbhost);

or

  CGI::Wiki::Setup::Pg::cleardb( $dbh );

You can either provide an active database handle C<$dbh> or connection
parameters.                                                                    

If you provide connection parameters the following arguments are
mandatory -- the database name, the username and the password. The
username must be able to drop tables in the database.

The $dbhost argument is optional -- omit it if the database is local.

Clears out all L<CGI::Wiki> store tables from the database. B<NOTE>
that this will lose all your data; you probably only want to use this
for testing purposes or if you really screwed up somewhere. Note also
that it doesn't touch any L<CGI::Wiki> search backend tables; if you
have any of those in the same or a different database see
L<CGI::Wiki::Setup::DBIxFTS> or L<CGI::Wiki::Setup::SII>, depending on
which search backend you're using.

=cut

sub cleardb {
    my @args = @_;
    my $dbh = _get_dbh( @args );
    my $disconnect_required = _disconnect_required( @args );

    print "Dropping tables... ";
    my $sql = "SELECT tablename FROM pg_tables
               WHERE tablename in ("
            . join( ",", map { $dbh->quote($_) } keys %create_sql ) . ")";
    foreach my $tableref (@{$dbh->selectall_arrayref($sql)}) {
        $dbh->do("DROP TABLE $tableref->[0]") or croak $dbh->errstr;
    }
    print "done\n";

    # Clean up if we made our own dbh.
    $dbh->disconnect if $disconnect_required;
}

sub _get_dbh {
    # Database handle passed in.
    if ( ref $_[0] and ref $_[0] eq 'DBI::db' ) {
        return $_[0];
    }

    # Args passed as hashref.
    if ( ref $_[0] and ref $_[0] eq 'HASH' ) {
        my %args = %{$_[0]};
        if ( $args{dbh} ) {
            return $args{dbh};
	} else {
            return _make_dbh( %args );
        }
    }

    # Args passed as list of connection details.
    return _make_dbh(
                      dbname => $_[0],
                      dbuser => $_[1],
                      dbpass => $_[2],
                      dbhost => $_[3],
                    );
}

sub _disconnect_required {
    # Database handle passed in.
    if ( ref $_[0] and ref $_[0] eq 'DBI::db' ) {
        return 0;
    }

    # Args passed as hashref.
    if ( ref $_[0] and ref $_[0] eq 'HASH' ) {
        my %args = %{$_[0]};
        if ( $args{dbh} ) {
            return 0;
	} else {
            return 1;
        }
    }

    # Args passed as list of connection details.
    return 1;
}

sub _make_dbh {
    my %args = @_;
    my $dsn = "dbi:Pg:dbname=$args{dbname}";
    $dsn .= ";host=$args{dbhost}" if $args{dbhost};
    my $dbh = DBI->connect($dsn, $args{dbuser}, $args{dbpass},
			   { PrintError => 1, RaiseError => 1,
			     AutoCommit => 1 } )
      or croak DBI::errstr;
    return $dbh;
}

=back

=head1 ALTERNATIVE CALLING SYNTAX

As requested by Podmaster.  Instead of passing arguments to the methods as

  ($dbname, $dbuser, $dbpass, $dbhost)

you can pass them as

  ( { dbname => $dbname,
      dbuser => $dbuser,
      dbpass => $dbpass,
      dbhost => $dbhost
    }
  )

or indeed as

  ( { dbh => $dbh } )

Note that's a hashref, not a hash.

=head1 AUTHOR

Kake Pugh (kake@earth.li).

=head1 COPYRIGHT

     Copyright (C) 2002-2004 Kake Pugh.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Wiki>, L<CGI::Wiki::Setup::DBIxFTS>, L<CGI::Wiki::Setup::SII>

=cut

1;
