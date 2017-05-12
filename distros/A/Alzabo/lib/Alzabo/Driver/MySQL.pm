package Alzabo::Driver::MySQL;

use strict;
use vars qw($VERSION);

use Alzabo::Driver;
use Alzabo::Utils;

use DBD::mysql;
use DBI;

use Params::Validate qw( :all );
Params::Validate::validation_options( on_fail => sub { Alzabo::Exception::Params->throw( error => join '', @_ ) } );


$VERSION = 2.0;

use base qw(Alzabo::Driver);

sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $self = bless {}, $class;

    return $self;
}

sub connect
{
    my $self = shift;

    $self->disconnect if $self->{dbh};
    $self->{dbh} = $self->_make_dbh( @_,
                                     name => $self->{schema}->db_schema_name
                                   );

    foreach ( $self->rows( sql => 'SHOW VARIABLES' ) )
    {
        if ( $_->[0] eq 'sql_mode' )
        {
            # some versions of mysql may return '' for sql_mode
            $self->{mysql_ansi_mode} = ( $_->[1] ? $_->[1] : 0 ) & 4;
            last;
        }
    }
}

sub quote_identifier
{
    my $self = shift;
    my @ids = @_;

    my $quote = $self->{mysql_ansi_mode} ? '"' : '`';

    foreach (@ids)
    {
        next unless defined;
        s/$quote/$quote$quote/g;
        $_ = "$quote$_$quote";
    }

    return join '.', @ids;
}

sub supports_referential_integrity
{
    my $self = shift;

    my ($maj, $min, $p) = $self->_version_components;

    if ( $maj == 3 )
    {
        return 0 if $min < 23;

        # 3.23.50 && 4.0.2 are the first versions where InnoDB
        # actually honored CASCADE, SET NULL, and SET DEFAULT
        return 0 if $p < 50;
    }

    # same deal
    return 0 if $maj == 4 && $min == 0 && $p < 2;

    foreach my $row ( $self->rows_hashref( sql => 'SHOW TABLE STATUS' ) )
    {
        return 0 if $row->{TYPE} !~ /innodb/i;
    }
}

sub _version_components
{
    my $self = shift;
    return split /\./, $self->rdbms_version;
}

sub rdbms_version
{
    my $self = shift;

    $self->_ensure_valid_dbh;
    my $version = $self->{dbh}{mysql_serverinfo};

    $version =~ s/[^\d\.]//g;

    return $version;
}

sub major_version { ($_[0]->_version_components)[0] }

sub schemas
{
    my $self = shift;

    my $dbh = $self->_make_dbh( name => '',
                                @_ );

    my @schemas = $dbh->func('_ListDBs');

    Alzabo::Exception::Driver->throw( error => $dbh->errstr )
        if $dbh->errstr;

    return @schemas;
}

sub create_database
{
    my $self = shift;

    my $db = $self->{schema}->db_schema_name;

    my $dbh = $self->_make_dbh( name => '',
                                @_ );

    $dbh->func( 'createdb', $db, 'admin' );
    Alzabo::Exception::Driver->throw( error => $dbh->errstr )
        if $dbh->errstr;

    $dbh->disconnect;
}

sub drop_database
{
    my $self = shift;

    my $db = $self->{schema}->db_schema_name;

    my $dbh = $self->_make_dbh( name => '',
                                @_ );

    $dbh->func( 'dropdb', $db, 'admin' );
    Alzabo::Exception::Driver->throw( error => $dbh->errstr )
        if $dbh->errstr;

    $dbh->disconnect;
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
                         map { $_ => 0 } grep { /^mysql_/ } keys %p,
                       } );

    my $dsn = "DBI:mysql:$p{name}";
    $dsn .= ";host=$p{host}" if $p{host};
    $dsn .= ";port=$p{port}" if $p{port};

    foreach my $k ( grep { /^mysql_/ } keys %p )
    {
        $dsn .= ";$k=$p{$k}";
    }

    return [ $dsn, $p{user}, $p{password},
             { RaiseError => 1,
               AutoCommit => 1,
               PrintError => 0,
             }
           ];
}

sub next_sequence_number
{
    # This will cause an auto_increment column to go up (because we're
    # inserting a NULL into it).
    return undef;
}

sub rollback
{
    my $self = shift;

    eval { $self->SUPER::rollback };

    if ( my $e = $@ )
    {
        unless ( $e->error =~ /Some non-transactional changed tables/ )
        {
            if ( Alzabo::Utils::safe_can( $e, 'rethrow' ) )
            {
                $e->rethrow;
            }
            else
            {
                Alzabo::Exception->throw( error => $e );
            }
        }
    }
}

sub get_last_id
{
     my $self = shift;

     return $self->{dbh}->{mysql_insertid};
}

sub driver_id
{
    return 'MySQL';
}

sub dbi_driver_name
{
    return 'mysql';
}

1;

__END__

=head1 NAME

Alzabo::Driver::MySQL - MySQL specific Alzabo driver subclass

=head1 SYNOPSIS

  use Alzabo::Driver::MySQL;

=head1 DESCRIPTION

This provides some MySQL specific implementations for the virtual
methods in Alzabo::Driver.

=head1 METHODS

=head2 connect, create_database, drop_database

Besides the parameters listed in L<the Alzabo::Driver
docs|Alzabo::Driver/Parameters for connect(),
create_database(), and drop_database()>, these methods will also
include any parameter starting with C<mysql_> in the DSN used to
connect to the database.  This allows you to pass parameters such as
"mysql_default_file".  See the DBD::mysql docs for more details.

=head2 schemas

This method accepts optional "host" and "port" parameters.

=head2 get_last_id

Returns the last id created via an AUTO_INCREMENT column.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
