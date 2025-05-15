package CGI::Session::Driver::mariadb;

# $Id$

use strict;
use warnings;
use Carp;
use CGI::Session::Driver::DBI;

@CGI::Session::Driver::mariadb::ISA       = qw( CGI::Session::Driver::DBI );
$CGI::Session::Driver::mariadb::VERSION   = '4.43';

sub _mk_dsnstr {
    my ($class, $dsn) = @_;
    unless ( $class && $dsn && ref($dsn) && (ref($dsn) eq 'HASH')) {
        croak "_mk_dsnstr(): usage error";
    }

    my $dsnstr = $dsn->{DataSource};
    if ( $dsn->{Socket} ) {
        $dsnstr .= sprintf(";mysql_socket=%s", $dsn->{Socket});
    }
    if ( $dsn->{Host} ) {
        $dsnstr .= sprintf(";host=%s", $dsn->{Host});
    }
    if ( $dsn->{Port} ) {
        $dsnstr .= sprintf(";port=%s", $dsn->{Port});
    }
    return $dsnstr;
}

sub init {
    my $self = shift;
    if ( $self->{DataSource} && ($self->{DataSource} !~ /^dbi:MariaDB/i) ) {
        $self->{DataSource} = "dbi:MariaDB:database=" . $self->{DataSource};
    }

    if ( $self->{Socket} && $self->{DataSource} ) {
        $self->{DataSource} .= ';mysql_socket=' . $self->{Socket};
    }
    return $self->SUPER::init();
}

sub store {
    my $self = shift;
    my ($sid, $datastr) = @_;
    croak "store(): usage error" unless $sid && $datastr;

    my $dbh = $self->{Handle};
    $dbh->do("INSERT INTO " . $self->table_name .
             " ($self->{IdColName}, $self->{DataColName}) VALUES(?, ?) ON DUPLICATE KEY UPDATE $self->{DataColName} = ?",
             undef, $sid, $datastr, $datastr)
        or return $self->set_error( "store(): \$dbh->do failed " . $dbh->errstr );
    return 1;
}

sub table_name {
    my $self = shift;
    return $self->SUPER::table_name(@_);
}

1;

__END__

=pod

=head1 NAME

CGI::Session::Driver::mariadb - CGI::Session driver for MariaDB database

=head1 SYNOPSIS

    $s = CGI::Session->new('driver:mariadb', $sid);
    $s = CGI::Session->new('driver:mariadb', $sid, { DataSource  => 'dbi:MariaDB:test',
                                                    User        => 'sherzodr',
                                                    Password    => 'hello' });
    $s = CGI::Session->new('driver:mariadb', $sid, { Handle => $dbh });

=head1 DESCRIPTION

B<mariadb> stores session records in a MariaDB table. For details, see L<CGI::Session::Driver::DBI|CGI::Session::Driver::DBI>, its parent class.

It is important that the session ID column be defined as a primary key or unique:

 CREATE TABLE sessions (
     id CHAR(32) NOT NULL PRIMARY KEY,
     a_session TEXT NOT NULL
 );

To use different column names, adjust your CREATE TABLE statement accordingly, and then:

    $s = CGI::Session->new('driver:mariadb', undef, {
        TableName=>'session',
        IdColName=>'my_id',
        DataColName=>'my_data',
        DataSource=>'dbi:MariaDB:project',
    });

or

    $s = CGI::Session->new('driver:mariadb', undef, {
        TableName=>'session',
        IdColName=>'my_id',
        DataColName=>'my_data',
        Handle=>$dbh,
    });

=head2 DRIVER ARGUMENTS

B<mariadb> driver supports all the arguments documented in L<CGI::Session::Driver::DBI|CGI::Session::Driver::DBI>. Like the mariadb driver, you can optionally omit the "dbi:MariaDB:" prefix:

    $s = CGI::Session->new('driver:mariadb', $sid, { DataSource=>'shopping_cart' });

=head2 BACKWARDS COMPATIBILITY

Global variables like $CGI::Session::MySQL::TABLE_NAME are no longer used. Refer to the parent L<CGI::Session::Driver::DBI> documentation for new methods.

=head1 LICENSING

For support and licensing see L<CGI::Session|CGI::Session>.

=cut

