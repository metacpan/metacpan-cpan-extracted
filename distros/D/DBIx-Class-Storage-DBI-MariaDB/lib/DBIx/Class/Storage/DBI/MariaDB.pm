package DBIx::Class::Storage::DBI::MariaDB;

use strict;
use warnings;

use DBI;
use base qw/DBIx::Class::Storage::DBI/;

our $VERSION = '0.1.1';

__PACKAGE__->sql_maker_class('DBIx::Class::SQLMaker::MySQL');
__PACKAGE__->sql_limit_dialect('LimitXY');
__PACKAGE__->sql_quote_char('`');

__PACKAGE__->_use_multicolumn_in(1);

sub with_deferred_fk_checks {
    my ( $self, $sub ) = @_;

    $self->_do_query('SET FOREIGN_KEY_CHECKS = 0');
    $sub->();
    $self->_do_query('SET FOREIGN_KEY_CHECKS = 1');
}

sub connect_call_set_strict_mode {
    my $self = shift;

    # the @@sql_mode puts back what was previously set on the session handle
    $self->_do_query(
q|SET SQL_MODE = CONCAT('ANSI,TRADITIONAL,ONLY_FULL_GROUP_BY,', @@sql_mode)|
    );
    $self->_do_query(q|SET SQL_AUTO_IS_NULL = 0|);
}

sub _dbh_last_insert_id {
    my ( $self, $dbh, $source, $col ) = @_;
    $dbh->{mariadb_insertid};
}

sub _prep_for_execute {
    my $self = shift;

    # Only update and delete need special double-subquery treatment
    # Insert referencing the same table (i.e. SELECT MAX(id) + 1) seems
    # to work just fine on MariaDB
    return $self->next::method(@_)
      if ( $_[0] eq 'select' or $_[0] eq 'insert' );

   # FIXME FIXME FIXME - this is a terrible, gross, incomplete, MariaDB-specific
   # hack but it works rather well for the limited amount of actual use cases
   # which can not be done in any other way on MariaDB. This allows us to fix
   # some bugs without breaking MariaDB support in the process and is also
   # crucial for more complex things like Shadow to be usable
   #
   # This code is just a pre-analyzer, working in tandem with ::SQLMaker::MySQL,
   # where the possibly-set value of {_modification_target_referenced_re} is
   # used to demarcate which part of the final SQL to double-wrap in a subquery.
   #
   # This is covered extensively by "offline" tests, so that competing SQLMaker
   # implementations could benefit from the existing tests just as well.

    # extract the source name, construct modification indicator re
    my $sm = $self->sql_maker;

    my $target_name = $_[1]->from;

    if ( ref $target_name ) {
        if (
            ref $target_name eq 'SCALAR'
            and $$target_name =~ /^ (?:
          \` ( [^`]+ ) \` #`
        | ( [\w\-]+ )
      ) $/x
          )
        {
            # this is just a plain-ish name, which has been literal-ed for
            # whatever reason
            $target_name = ( defined $1 ) ? $1 : $2;
        } else {

     # this is something very complex, perhaps a custom result source or whatnot
     # can't deal with it
            undef $target_name;
        }
    }

    local $sm->{_modification_target_referenced_re} =
qr/ (?<!DELETE) [\s\)] (?: FROM | JOIN ) \s (?: \` \Q$target_name\E \` | \Q$target_name\E ) [\s\(] /xi
      if $target_name;

    $self->next::method(@_);
}

# here may seem like an odd place to override, but this is the first
# method called after we are connected *and* the driver is determined
# ($self is reblessed). See code flow in ::Storage::DBI::_populate_dbh
sub _run_connection_actions {
    my $self = shift;

    # default mariadb_auto_reconnect to off unless explicitly set
    if ( $self->_dbh->{mariadb_auto_reconnect}
        and !exists $self->_dbic_connect_attributes->{mariadb_auto_reconnect} )
    {
        $self->_dbh->{mariadb_auto_reconnect} = 0;
    }

    $self->next::method(@_);
}

# we need to figure out what mysql version we're running
sub sql_maker {
    my $self = shift;

    # it is critical to get the version *before* calling next::method
    # otherwise the potential connect will obliterate the sql_maker
    # next::method will populate in the _sql_maker accessor
    my $mariadb_ver = $self->_server_info->{normalized_dbms_version};

    my $sm = $self->next::method(@_);

    # mysql 3 does not understand a bare JOIN
    $sm->{_default_jointype} = 'INNER' if $mariadb_ver < 4;

    $sm;
}

sub sqlt_type {
    # used by SQL::Translator
    return 'MySQL';
}

sub deployment_statements {
    my $self = shift;
    my ( $schema, $type, $version, $dir, $sqltargs, @rest ) = @_;

    $sqltargs ||= {};

    if (   !exists $sqltargs->{producer_args}{mysql_version}
        and my $dver = $self->_server_info->{normalized_dbms_version} )
    {
        $sqltargs->{producer_args}{mysql_version} = $dver;
    }

    $self->next::method( $schema, $type, $version, $dir, $sqltargs, @rest );
}

sub _exec_svp_begin {
    my ( $self, $name ) = @_;

    $self->_dbh->do("SAVEPOINT $name");
}

sub _exec_svp_release {
    my ( $self, $name ) = @_;

    $self->_dbh->do("RELEASE SAVEPOINT $name");
}

sub _exec_svp_rollback {
    my ( $self, $name ) = @_;

    $self->_dbh->do("ROLLBACK TO SAVEPOINT $name");
}

sub is_replicating {
    my $status = shift->_get_dbh->selectrow_hashref('show slave status');
    return ( $status->{Slave_IO_Running} eq 'Yes' )
      && ( $status->{Slave_SQL_Running} eq 'Yes' );
}

sub lag_behind_master {
    return
      shift->_get_dbh->selectrow_hashref('show slave status')
      ->{Seconds_Behind_Master};
}

sub bind_attribute_by_data_type {
    if ( $_[1] = ~ /^(?:tiny|medium|long)blob$/i ) {
        return DBI::SQL_BINARY;
    }
    return;
}

1;

=head1 NAME

DBIx::Class::Storage::DBI::MariaDB - Storage::DBI class implementing MariaDB specifics

=head1 DESCRIPTION

This module adds support for MariaDB in the DBIx::Class ORM. It supports
exactly the same parameters as the L<DBIx::Class::Storage::DBI::mysql>
module, so check that for further documentation.

=head1 USAGE

Similar to other storage modules that are builtin to DBIx::Class, all you need
to do is ensure DBIx::Class::Storage::DBI::MariaDB is loaded and specify
MariaDB in the DSN. For example:

    package MyApp::Schema;
    use base 'DBIx::Class::Schema';

    # register classes
    # ...
    # load mariadb storage
    __PACKAGE__->ensure_class_loaded('DBIx::Class::Storage::DBI::MariaDB');

    package MyApp;
    use MyApp::Schema;

    my $dsn = "dbi:MariaDB:database=mydb";
    my $user = "noone";
    my $pass = "topsecret";
    my $schema = MyApp::Schema->connect($dsn, $user, $pass);

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 Siemplexus

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Antonis Kalou E<lt>a.kalou@shadowcat.co.ukE<gt>
Jess Robinson E<lt>j.robinson@shadowcat.co.ukE<gt>
