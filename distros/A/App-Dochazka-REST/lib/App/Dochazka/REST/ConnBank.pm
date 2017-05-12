# ************************************************************************* 
# Copyright (c) 2014-2015, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 

# ------------------------
# store and dispense DBIx::Connector objects
# ------------------------

package App::Dochazka::REST::ConnBank;

use strict;
use warnings;
use feature "state";

use App::CELL qw( $log $site );
use DBIx::Connector;
use Try::Tiny;



=head1 NAME

App::Dochazka::REST::ConnBank - Provide DBIx::Connector objects



=head1 SYNOPSIS

    use App::Dochazka::REST::ConnBank qw( $dbix_conn conn_status );

    $dbix_conn->run( fixup => sub {
        ...
    } );

    print "Database connection status: " . conn_status() . "\n";

    # construct an arbitrary DBIx::Connector object
    my $conn = App::Dochazka::REST::ConnBank::get_arbitrary_dbix_conn(
        'mydb', 'myuser', 'mypass' 
    );



=head1 DESCRIPTION

This module contains routines relating to L<DBIx::Connector>. Mostly,
the application uses the C<$dbix_conn> singleton.

=cut



=head1 EXPORTS

=cut

use Exporter qw( import );
our @EXPORT_OK = qw( $dbix_conn conn_status conn_up );



=head1 PACKAGE VARIABLES

This module stores the L<DBIx::Connector> singleton object that is imported by
all modules that need to communicate with the database.

=cut

our $dbix_conn;



=head1 FUNCTIONS


=head2 get_arbitrary_dbix_conn

Wrapper for DBIx::Connector->new. Takes database name, database user and
password.  Returns a DBIx::Connector object (even if the database is
unreachable).

=cut

sub get_arbitrary_dbix_conn {
    my ( $dbname, $dbuser, $dbpass ) = @_;
    my $dbhost = $site->DOCHAZKA_DBHOST;
    my $dbport = $site->DOCHAZKA_DBPORT;
    my $dbsslmode = $site->DOCHAZKA_DBSSLMODE;

    my $data_source = "Dbi:Pg:dbname=\"$dbname\"";
    $data_source .= ";host=$dbhost" if $dbhost;
    $data_source .= ";port=$dbport" if $dbport;
    $data_source .= ";sslmode=$dbsslmode" if $dbsslmode;

    $log->debug( "Returning DBIx::Connector object for data source $data_source and user $dbuser" );

    return DBIx::Connector->new(
        $data_source, 
        $dbuser,
        $dbpass,
        {
            PrintError => 0,
            RaiseError => 1,
            AutoCommit => 1,
            AutoInactiveDestroy => 1,
        },
    );
}


=head2 init_singleton

Initialize the C<$dbix_conn> singleton using dbname, dbuser, and dbpass values
from site configuration. Also set the PGTZ environment variable to the
value of the DOCHAZKA_TIMEZONE config param.

Idempotent.

=cut

sub init_singleton {
    $ENV{'PGTZ'} = $site->DOCHAZKA_TIMEZONE;
    return if ref( $dbix_conn ) and $dbix_conn->can( 'dbh' );
    $dbix_conn = get_arbitrary_dbix_conn( 
        $site->DOCHAZKA_DBNAME,
        $site->DOCHAZKA_DBUSER,
        $site->DOCHAZKA_DBPASS,
    );
}


=head2 conn_up

Given a L<DBIx::Connector> object, call L<ping> on the associated 
database handle and return true or false based on the result.

If no argument is given, returns the status of the C<$dbix_conn>
singleton.

=cut

sub conn_up {
    my $arg = shift;
    my $conn = $arg || $dbix_conn;
    my $bool = 0;
    return $bool unless ref( $conn ) eq 'DBIx::Connector';
    
    # the ping command can and will throw and exception if the database server
    # is unreachable
    try {
        $bool = $conn->dbh->ping;
    };

    return $bool;
}


=head2 conn_status 

Given a L<DBIx::Connector> object, call L<ping> on the associated 
database handle and return either 'UP' or 'DOWN' based on the result.

If no argument is given, returns the status of the C<$dbix_conn>
singleton.

=cut

sub conn_status {
    my $arg = shift;
    return conn_up( $arg ) ? "UP" : "DOWN";
}

1;
