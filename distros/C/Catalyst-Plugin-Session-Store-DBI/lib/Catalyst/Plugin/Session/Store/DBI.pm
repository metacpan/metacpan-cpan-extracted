package Catalyst::Plugin::Session::Store::DBI;

use strict;
use warnings;
use base qw/Class::Data::Inheritable Catalyst::Plugin::Session::Store/;
use DBI;
use MIME::Base64;
use MRO::Compat;
use Storable qw/nfreeze thaw/;

our $VERSION = '0.16';

__PACKAGE__->mk_classdata('_session_sql');
__PACKAGE__->mk_classdata('_session_dbh');
__PACKAGE__->mk_classdata('_sth_get_session_data');
__PACKAGE__->mk_classdata('_sth_get_expires');
__PACKAGE__->mk_classdata('_sth_check_existing');
__PACKAGE__->mk_classdata('_sth_update_session');
__PACKAGE__->mk_classdata('_sth_insert_session');
__PACKAGE__->mk_classdata('_sth_update_expires');
__PACKAGE__->mk_classdata('_sth_delete_session');
__PACKAGE__->mk_classdata('_sth_delete_expired_sessions');

sub get_session_data {
    my ( $c, $key ) = @_;
    
    # expires:sid expects an expiration time
    if ( my ($sid) = $key =~ /^expires:(.*)/ ) {
        $key = "session:$sid";
        my $sth = $c->_session_sth('get_expires');
        $sth->execute($key);
        my ($expires) = $sth->fetchrow_array;
        return $expires;
    }
    else {
        my $sth = $c->_session_sth('get_session_data');
        $sth->execute($key);
        if ( my ($data) = $sth->fetchrow_array ) {
            return thaw( decode_base64($data) );
        }
    }
    return;
}

sub store_session_data {
    my ( $c, $key, $data ) = @_;
    
    # expires:sid keys only update the expiration time
    if ( my ($sid) = $key =~ /^expires:(.*)/ ) {
        $key = "session:$sid";
        my $sth = $c->_session_sth('update_expires');
        $sth->execute( $c->session_expires, $key );
    }
    else {
        # check for existing record
        my $sth = $c->_session_sth('check_existing');
        $sth->execute($key);
        my ($exists) = $sth->fetchrow_array;
    
        # update or insert as needed
        my $sta = ($exists)
            ? $c->_session_sth('update_session')
            : $c->_session_sth('insert_session');

        my $frozen = encode_base64( nfreeze($data) );
        my $expires = $key =~ /^(?:session|flash):/ 
                    ? $c->session_expires 
                    : undef;
        $sta->execute( $frozen, $expires, $key );
    }
    
    return;
}

sub delete_session_data {
    my ( $c, $key ) = @_;
    
    return if $key =~ /^expires/;

    my $sth = $c->_session_sth('delete_session');
    $sth->execute($key);

    return;
}

sub delete_expired_sessions {
    my $c = shift;

    my $sth = $c->_session_sth('delete_expired_sessions');
    $sth->execute(time);

    return;
}

sub prepare {
    my $c = shift;

    my $cfg = $c->_session_plugin_config;

    # If using DBIC/CDBI, always grab their dbh
    if ( $cfg->{dbi_dbh} ) {
        $c->_session_dbic_connect();
    }
    else {
        # make sure the database is still connected
        eval { $c->_session_dbh->ping or die "dbh->ping failed" };
        if ($@) {
            # reconnect
            $c->_session_dbi_connect();
        }
    }

    $c->maybe::next::method(@_);
}


sub session_store_dbi_table {
    return shift->_session_plugin_config->{'dbi_table'} || 'sessions';
}

sub session_store_dbi_id_field {
    return shift->_session_plugin_config->{'dbi_id_field'} || 'id';
}

sub session_store_dbi_data_field {
    return shift->_session_plugin_config->{'dbi_data_field'} || 'session_data';
}

sub session_store_dbi_expires_field {
    return shift->_session_plugin_config->{'dbi_expires_field'} || 'expires';
}

sub setup_session {
    my $c = shift;

    $c->maybe::next::method(@_);

    my $cfg = $c->_session_plugin_config;
    
    unless ( $cfg->{dbi_dbh} || $cfg->{dbi_dsn} ) {
        Catalyst::Exception->throw( 
            message => 'Session::Store::DBI: No session configuration found, '
                     . 'please configure dbi_dbh or dbi_dsn'
        );
    }
    
    # Pre-generate all SQL statements
    my ( $table, $id_field, $data_field, $expires_field ) =
        map { $c->${\"session_store_$_"} }
            qw/dbi_table dbi_id_field dbi_data_field dbi_expires_field/;
    $c->_session_sql( {
        get_session_data        =>
            "SELECT $data_field FROM $table WHERE $id_field = ?",
        get_expires             =>
            "SELECT $expires_field FROM $table WHERE $id_field = ?",
        check_existing          =>
            "SELECT 1 FROM $table WHERE $id_field = ?",
        update_session          =>
            "UPDATE $table SET $data_field = ?, $expires_field = ? WHERE $id_field = ?",
        insert_session          =>
            "INSERT INTO $table ($data_field, $expires_field, $id_field) VALUES (?, ?, ?)",
        update_expires          =>
            "UPDATE $table SET $expires_field = ? WHERE $id_field = ?",
        delete_session          =>
            "DELETE FROM $table WHERE $id_field = ?",
        delete_expired_sessions =>
            "DELETE FROM $table WHERE $expires_field IS NOT NULL AND $expires_field < ?",
    } );
}

sub _session_dbi_connect {
    my $c = shift;

    my $cfg = $c->_session_plugin_config;

    if ( $cfg->{dbi_dsn} ) {

        # Allow user-supplied options.
        my %options = (
            AutoCommit => 1,
            RaiseError => 1,
            %{ $cfg->{dbi_options} || {} }
        );

        my $dbh = DBI->connect(
            $cfg->{'dbi_dsn'},
            $cfg->{'dbi_user'},
            $cfg->{'dbi_pass'},
            \%options,
        ) or Catalyst::Exception->throw( message => $DBI::errstr );
        $c->_session_dbh($dbh);
    }
}

sub _session_dbic_connect {
    my $c = shift;

    my $cfg = $c->_session_plugin_config;

    if ( $cfg->{dbi_dbh} ) {
        if ( ref $cfg->{dbi_dbh} ) {

            # use an existing db handle
            if ( !$cfg->{dbi_dbh}->{Active} ) {
                Catalyst::Exception->throw( message =>
                        'Session: Database handle supplied is not active' );
            }
            $c->_session_dbh( $cfg->{dbi_dbh} );
        }
        else {

            # use a DBIC/CDBI/RDBO class
            my $class = $cfg->{dbi_dbh};
            my $dbh;
            
            # DBIC Schema support
            if (   $c->model($class) 
                && $c->model($class)->isa('Catalyst::Model::DBIC::Schema')
            ) {
                eval { $dbh = $c->model($class)->schema->storage->dbh };
                if ($@) {
                    Catalyst::Exception->throw( 
                        message => "Unable to get a handle from "
                                 . "DBIx::Class Schema model '$class': $@"
                    );
                }
            }
            
            # Class-based DBIC support
            elsif ( $c->model($class)
                 && $c->model($class)->isa('DBIx::Class::DB')
            ) {
                eval { $dbh = $c->model($class)->storage->dbh };
                if ($@) {
                    Catalyst::Exception->throw( 
                        message => "Unable to get a handle from "
                                 . "DBIx::Class model '$class': $@"
                    );
                }
            }
            
            # CDBI support
            elsif ( $class->isa('Class::DBI') ) {
                eval { $dbh = $class->db_Main };
                if ($@) {
                    Catalyst::Exception->throw( 
                        message => "Unable to get a handle from "
                                 . "Class::DBI model '$class': $@"
                    );
                }
            }
            
            # RDBO support
            elsif ( $class->isa('Rose::DB::Object') ) {
                eval { $dbh = $class->new->db->retain_dbh };
                if ($@) {
                    Catalyst::Exception->throw(
                        message => "Unable to get a handle from "
                                 . "Rose::DB::Object '$class': $@"
                    );
                }
            }

            # Model::DBI support
            elsif ( $c->model($class)
                 && $c->model($class)->isa('Catalyst::Model::DBI')
            ) {
                eval { $dbh = $c->model($class)->dbh };
                if ($@) {
                    Catalyst::Exception->throw(
                        message => "Unable to get a handle from "
                                 . "DBI model '$class': $@"
                    );
                }
            }
            
            else {
                Catalyst::Exception->throw( 
                    message => "Unable to get a handle from "
                             . "model '$class': Does not appear "
                             . "to be a DBIx::Class, Class::DBI, "
                             . "or Rose::DB::Object class"
                );
            }
            
            $c->_session_dbh($dbh);
        }
    }
}

# Prepares SQL statements as needed
sub _session_sth {
    my ( $c, $key ) = @_;

    if ( my $sql = $c->_session_sql->{$key} ) {
        my $accessor = "_sth_$key";
        
        if ( defined $c->$accessor ) {
            
            # Check for the 'morning bug', where the dbh may have gone away
            # while we still have cached sth's using it.
            if ( $c->$accessor->{Database} ne $c->_session_dbh ) {
                # The sth has an old dbh, so we need to prepare it again
                if ( $c->$accessor->{Active} ) {
                    $c->$accessor->finish;
                }
            }
            else {
                return $c->$accessor;
            }
        }
        
        return $c->$accessor( $c->_session_dbh->prepare( $sql ) );
    }
    
    return;
}

# close any active sth's to avoid warnings
sub DESTROY {
    my $c = shift;
    $c->maybe::next::method(@_);
    
    for my $key ( keys %{ $c->_session_sql } ) {
        my $accessor = "_sth_$key";
        if ( defined $c->$accessor && $c->$accessor->{Active} ) {
            $c->$accessor->finish;
        }
    }
}

1;
__END__

=head1 NAME

Catalyst::Plugin::Session::Store::DBI - Store your sessions in a database

=head1 SYNOPSIS

    # Create a table in your database for sessions
    CREATE TABLE sessions (
        id           char(72) primary key,
        session_data text,
        expires      int(10)
    );

    # In your app
    use Catalyst qw/Session Session::Store::DBI Session::State::Cookie/;
    
    # Connect directly to the database
    MyApp->config('Plugin::Session' => {
        expires   => 3600,
        dbi_dsn   => 'dbi:mysql:database',
        dbi_user  => 'foo',
        dbi_pass  => 'bar',
        dbi_table => 'sessions',
        dbi_id_field => 'id',
        dbi_data_field => 'session_data',
        dbi_expires_field => 'expires',
    });
    
    # Or use an existing database handle from a DBIC/CDBI class
    MyApp->config('Plugin::Session' => {
        expires   => 3600,
        dbi_dbh   => 'DBIC', # which means MyApp::Model::DBIC
        dbi_table => 'sessions',
        dbi_id_field => 'id',
        dbi_data_field => 'session_data',
        dbi_expires_field => 'expires',
    });

    # ... in an action:
    $c->session->{foo} = 'bar'; # will be saved

=head1 DESCRIPTION

This storage module will store session data in a database using DBI.

=head1 CONFIGURATION

These parameters are placed in the configuration hash under the C<Plugin::Session>
key.

=head2 expires

The expires column in your table will be set with the expiration value.
Note that no automatic cleanup is done on your session data, but you can use
the delete_expired_sessions method to perform clean up.  You can make use of
the L<Catalyst::Plugin::Scheduler> plugin to schedule automated session
cleanup.

=head2 dbi_dbh

Set this to an existing $dbh or the class name of a L<DBIx::Class>,
L<Class::DBI>, L<Rose::DB::Object>, or L<Catalyst::Model::DBI> model. 
DBIx::Class schema is also supported by setting dbi_dbh to the name of
your schema model.

This method is recommended if you have other database code in your
application as it will avoid opening additional connections.

=head2 dbi_dsn

=head2 dbi_user

=head2 dbi_pass

=head2 dbi_options

To connect directly to a database, specify the necessary dbi_dsn, dbi_user,
and dbi_pass options.  If you need to supply your own options to DBI, you
may do so by passing a hashref to dbi_options.  The default options are
AutoCommit => 1 and RaiseError => 1.

=head2 dbi_table

Enter the table name within your database where sessions will be stored.
This table must have at least 3 columns, id, session_data, and expires.
See the Schema section below for additional details.  The table name defaults
to 'sessions'.

=head2 dbi_id_field

The name of the field on your sessions table which stores the session ID.
Defaults to C<id>.

=head2 dbi_data_field

The name of the field on your sessions table which stores session data.
Defaults to C<session_data>.

=head2 dbi_expires_field

The name of the field on your sessions table which stores the expiration
time of the session. Defaults to C<expires>.

=head1 SCHEMA

Your 'sessions' table must contain at minimum the following 3 columns:

    id           char(72) primary key
    session_data text
    expires      int(10)

The 'id' column should probably be 72 characters. It needs to handle the
longest string that can be returned by
L<Catalyst::Plugin::Authentication/generate_session_id>, plus another 8
characters for internal use. This is less than 72 characters in practice when
SHA-1 or MD5 are used, but SHA-256 will need all those characters.

The 'session_data' column should be a long text field.  Session data is
encoded using Base64 before being stored in the database.

Note that MySQL TEXT fields only store 64KB, so if your session data
will exceed that size you'll want to move to MEDIUMTEXT, MEDIUMBLOB,
or larger.

The 'expires' column stores the future expiration time of the session.  This
may be null for per-user and flash sessions.

NOTE: Your column names do not need to match with this schema, use config to
set custom column names.

=head1 METHODS

=head2 get_session_data

=head2 store_session_data

=head2 delete_session_data

=head2 delete_expired_sessions

=head2 setup_session

These are implementations of the required methods for a store. See
L<Catalyst::Plugin::Session::Store>.

=head2 session_store_dbi_table

Return the configured table name.

=head2 session_store_dbi_id_field

Return the configured ID field name.

=head2 session_store_dbi_data_field

Return the configured data field name.

=head2 session_store_dbi_expires_field

Return the configured expires field name.

=head1 INTERNAL METHODS

=head2 prepare

=head2 setup_actions

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Session>, L<Catalyst::Plugin::Scheduler>

=head1 AUTHOR

Andy Grundman, <andy@hybridized.org>

=head1 COPYRIGHT

Copyright (c) 2005 - 2009
the Catalyst::Plugin::Session::Store::DBI L</AUTHOR>
as listed above.

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
