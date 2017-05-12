package Alzabo::Driver::PostgreSQL;

use strict;
use vars qw($VERSION);

use Alzabo::Driver;

use DBD::Pg;
use DBI;

use Params::Validate qw( :all );
Params::Validate::validation_options( on_fail => sub { Alzabo::Exception::Params->throw( error => join '', @_ ) } );

$VERSION = 2.0;

use base qw(Alzabo::Driver);

sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;

    return bless {}, $class;
}

sub connect
{
    my $self = shift;

    $self->{tran_count} = undef;

    # This database handle is stale or nonexistent, so we need to (re)connect
    $self->disconnect if $self->{dbh};
    $self->{dbh} = $self->_make_dbh( @_,
                                     name => $self->{schema}->db_schema_name
                                   );
}

sub supports_referential_integrity { 1 }

sub schemas
{
    my $self = shift;

    my %p = validate( @_, { user => { type => SCALAR | UNDEF,
                                      optional => 1 },
                            password => { type => SCALAR | UNDEF,
                                          optional => 1 },
                            host => { type => SCALAR | UNDEF,
                                   optional => 1 },
                            port => { type => SCALAR | UNDEF,
                                      optional => 1 },
                            options => { type => SCALAR | UNDEF,
                                         optional => 1 },
                            tty => { type => SCALAR | UNDEF,
                                     optional => 1 },
                          } );

    local %ENV;
    foreach ( grep { defined $p{$_} && length $p{$_} } keys %p )
    {
        my $key = uc "pg$_";
        $ENV{$key} = $p{$_};
    }

    my @schemas = ( map { if ( defined )
                          {
                              /dbi:\w+:dbname="?(\w+)"?/i;
                              $1 ? $1 : ();
                          }
                          else
                          {
                              ();
                          }
                        }
                    DBI->data_sources( $self->dbi_driver_name ) );

    return @schemas;

}

sub tables
{
    my $self = shift;

    # It seems that with DBD::Pg 1.31 & 1.32 you can't just the
    # database's table, you also get the system tables back
    return grep { ! /^(?:pg_catalog|information_schema)\./ } $self->SUPER::tables( @_ );
}

sub create_database
{
    my $self = shift;

    # Obviously we can't connect to the main database if it doesn't
    # exist yet, but postgres doesn't let us be databaseless, so we
    # connect to something else.  "template1" should always be there.
    my $dbh = $self->_make_dbh( @_, name => 'template1' );

    eval { $dbh->do( "CREATE DATABASE " . $dbh->quote_identifier( $self->{schema}->db_schema_name ) ); };

    my $e = $@;

    eval { $dbh->disconnect; };

    Alzabo::Exception::Driver->throw( error => $e ) if $e;
    Alzabo::Exception::Driver->throw( error => $@ ) if $@;
}

sub drop_database
{
    my $self = shift;

    # We can't drop the current database, so we have to connect to
    # something else.  "template1" should always be there.
    $self->disconnect;

    my $dbh = $self->_make_dbh( @_, name => 'template1' );

    eval { $dbh->do( "DROP DATABASE " . $dbh->quote_identifier( $self->{schema}->db_schema_name ) ); };
    my $e = $@;

    eval { $dbh->disconnect; };
    $e ||= $@;

    Alzabo::Exception::Driver->throw( error => $e ) if $e;
}

sub _connect_params
{
    my $self = shift;
    my %p = @_;

    %p = validate( @_, { name => { type => SCALAR },
                         user => { type => SCALAR | UNDEF,
                                   optional => 1 },
                         password => { type => SCALAR | UNDEF,
                                       optional => 1 },
                         host => { type => SCALAR | UNDEF,
                                   optional => 1 },
                         port => { type => SCALAR | UNDEF,
                                   optional => 1 },
                         options => { type => SCALAR | UNDEF,
                                      optional => 1 },
                         tty => { type => SCALAR | UNDEF,
                                  optional => 1 },
                         service => { type => SCALAR | UNDEF,
                                      optional => 1 },
                         sslmode => { type => SCALAR | UNDEF,
                                      optional => 1 },
                         map { $_ => 0 } grep { /^pg_/ } keys %p,
                       } );

    my $dsn = "dbi:Pg:dbname=$p{name}";
    foreach ( qw( host port options tty service sslmode ) )
    {
        $dsn .= ";$_=$p{$_}" if grep { defined && length } $p{$_};
    }

    my %pg_keys = map { $_ => $p{$_} } grep { /^pg_/ } keys %p;

    return [ $dsn, $p{user}, $p{password},
             { RaiseError => 1,
               AutoCommit => 1,
               PrintError => 0,
               %pg_keys,
             },
           ];
}

sub next_sequence_number
{
    my $self = shift;
    my $col = shift;

    $self->_ensure_valid_dbh;

    Alzabo::Exception::Params->throw
        ( error => "This column (" . $col->name . ") is not sequenced" )
            unless $col->sequenced;

    my $seq_name;

    if ( $col->type =~ /SERIAL/ )
    {
        $seq_name = join '_', $col->table->name, $col->name;
        my $maxlen = $self->identifier_length;
        $seq_name = substr( $seq_name, 0, $maxlen - 4 ) if length $seq_name > ($maxlen - 4);

        $seq_name .= '_seq';
    }
    else
    {
        $seq_name = join '___', $col->table->name, $col->name;
    }

    $seq_name = $self->{dbh}->quote_identifier($seq_name)
        if $self->{schema}->quote_identifiers;

    $self->{last_id} = $self->one_row( sql => "SELECT NEXTVAL('$seq_name')" );

    return $self->{last_id};
}

sub get_last_id
{
    my $self = shift;
    return $self->{last_id};
}

sub driver_id
{
    return 'PostgreSQL';
}

sub dbi_driver_name
{
    return 'Pg';
}

sub rdbms_version
{
    my $self = shift;

    my $version_string = $self->one_row( sql => 'SELECT version()' );
    my ($version) = $version_string =~ /^PostgreSQL ([\d.]+)/
        or die "Couldn't determine version number from version string '$version_string'";

    return $version;
}

sub identifier_length
{
    my $self = shift;

    return $self->{identifier_length} if $self->{identifier_length};

    return
        $self->{identifier_length} = $self->rdbms_version ge '7.3' ? 63 : 31;
}

1;

__END__

=head1 NAME

Alzabo::Driver::PostgreSQL - PostgreSQL specific Alzabo driver subclass

=head1 SYNOPSIS

  use Alzabo::Driver::PostgreSQL;

=head1 DESCRIPTION

This provides some PostgreSQL specific implementations for the virtual
methods in Alzabo::Driver.

=head1 METHODS

=head2 connect, create_database, drop_database

Besides the parameters listed in L<the Alzabo::Driver
docs|Alzabo::Driver/Parameters for connect(),
create_database(), and drop_database()>, the following parameters
are accepted:

=over 4

=item * options

=item * tty

=back

=head2 schemas

This method accepts the same parameters as the C<connect()> method.

=head2 get_last_id

Returns the last id created for a sequenced column.

=head2 identifier_length

Returns the maximum identifier length allowed by the database.  This
is really a guess based on the server version, since the actual value
is set when the server is compiled.

=head1 BUGS

In testing, I found that there were some problems using Postgres in a
situation where you start the app, connect to the database, get some
data, fork, reconnect, and and then get more data.  I suspect that
this has more to do with the DBD::Pg driver and/or Postgres itself
than Alzabo.  I don't believe this would be a problem with an app
which forks before ever connecting to the database (such as mod_perl).

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
