package DBIx::MySQL::Replication::Slave;
BEGIN {
  $DBIx::MySQL::Replication::Slave::VERSION = '0.02';
}

use Moose;

=head1 NAME

DBIx::MySQL::Replication::Slave - Stop, start and monitor your slaves.

=head1 VERSION

version 0.02

=head1 SYNOPSIS

This module gives you an OO interface for stopping, starting and monitoring
the status and health of your MySQL slaves. It doesn't do anything you can't
already do for yourself, but it makes some basic tasks just a little bit
easier.

    use DBIx::MySQL::Replication::Slave;

    my $slave = DBIx::MySQL::Replication::Slave->new( dbh => $dbh );

    if ( $slave->is_stopped ) {
    
        $slave->start;
    
        if ( $slave->is_running ) {
            print "slave now running\n";
        }
        else {
            print "cannot start stopped slave.\n";
        }
    
    }

If you need a quick monitor script:

    $slave->max_seconds_behind_master( 30 );

    if ( !$slave->slave_ok ) {
        # send an alert to the administrator...
    }

For some quick debugging:

    use Data::Dump qw( dump );
    print dump( $slave->status );

    print "seconds behind: " . $slave->status->{seconds_behind_master};

=head1 CONSTRUCTOR AND STARTUP

=head2 new( dbh => $dbh )

Creates and returns a new DBIx::MySQL::Replication::Slave object.

    my $slave = DBIx::MySQL::Replication::Slave->new( dbh => $dbh );

=over 4

=item * C<< dbh => $dbh >>

A valid database handle to your slave server is required.  You'll need to pass
it to the constructor:

    my $slave = DBIx::MySQL::Replication::Slave->new( dbh => $dbh );

Generally, the user will need to have the following MySQL privileges:

SUPER,REPLICATION CLIENT

=item * C<< lc => 0|1 >>

By default, the status variables returned by MySQL are converted to lower case.
This is for readability. You may turn this off if you wish, by explicitly
turning it off when you create the object:

    my $slave = DBIx::MySQL::Replication::Slave->new( dbh => $dbh, lc => 0 );

=item * C<< max_seconds_behind_master => $seconds >>

By default this is set to a very generous number (86400 seconds). Set this
value if you'd like to take a shorter amount of time into account when
checking on your health. This is strongly recommended:

    # Anything longer than 30 seconds is not acceptable
    my $slave = DBIx::MySQL::Replication::Slave->new(
        dbh => $dbh,
        seconds_behind_master => 30
    );

If you think it's cleaner, you can also set this value *after* object creation.

    $slave->max_seconds_behind_master(30);

=back

=head1 SUBROUTINES/METHODS

=head2 status

Returns a HASHREF of the MySQL slave status variables.  These vars will, by
default, be converted to lower case, unless you have turned this off when you
construct the object.  See the lc option to new() for more info.

=head2 refresh_status

Issues a fresh "SLOW SLAVE STATUS" query and returns the new results of
$slave->status to you.

=head2 start

Issues a "START SLAVE" query and returns DBI's raw return value directly to
you.

=head2 stop

Issues a "STOP SLAVE" query and returns DBI's raw return value directly to
you.

=head2 slave_ok

This method returns true if slave_io_running and slave_sql_running are both
equal to 'Yes' AND if seconds_behind_master is <= max_seconds_behind master.

=head2 is_running

Returns true if both slave_io_running and slave_sql_running are set to 'Yes'

=head2 is_stopped

Returns true if both slave_io_running and slave_sql_running are set to 'No'.
If only one of these values returns 'Yes', it's probably fair to say that the
slave is in some transitional state. Neither stopped nor running may be an
accurate description in this case.

=head1 AUTHOR

Olaf Alders, C<< <olaf at wundercounter.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-dbix-mysql-replication-slave at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-MySQL-Replication-Slave>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 TESTING

Have a look at the source of t/connect.t if you'd like to do more extensive
testing of your install. This will require that you already have a fully
functional slave set up in order for the tests to pass. These tests are
skipped by default, but you are encouraged to run them as part of your install
process.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::MySQL::Replication::Slave


You can also look for information at:

=over 4

=item * GitHub Source Repository

L<http://github.com/oalders/dbix-mysql-replication-slave>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-MySQL-Replication-Slave>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-MySQL-Replication-Slave>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-MySQL-Replication-Slave>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-MySQL-Replication-Slave/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Raybec Communications L<http://www.raybec.com> for funding my
work on this module and for releasing it to the world.


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Olaf Alders.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

has 'dbh' => (
    isa      => 'DBI::db',
    is       => 'rw',
    required => 1,
);

has 'lc' => (
    default  => 1,
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has 'max_seconds_behind_master' => (
    default  => 86400,
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has '_lc_status' => (
    is  => 'rw',
    isa => 'HashRef',
);

has '_status' => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub status {
    my $self = shift;
    return $self->_status if !$self->lc;
    return $self->_get_lc_status;
}

sub slave_ok {

    my $self   = shift;
    my $status = $self->_get_lc_status;

    if (   $status->{slave_io_running} eq 'Yes'
        && $status->{slave_sql_running} eq 'Yes'
        && $status->{seconds_behind_master}
        <= $self->max_seconds_behind_master )
    {
        return 1;
    }

    return 0;

}

sub stop {

    my $self = shift;
    return $self->dbh->do("STOP SLAVE");

}

sub is_stopped {

    my $self = shift;
    $self->refresh_status;

    my $status = $self->_get_lc_status;

    if (   $status->{slave_io_running} eq 'No'
        && $status->{slave_sql_running} eq 'No' )
    {
        return 1;
    }

    return 0;
}

sub start {

    my $self = shift;
    return $self->dbh->do("START SLAVE");

}

sub is_running {

    my $self = shift;

    # allow some time to connect, if need be
    foreach (1..10) {
        $self->refresh_status;
        if ( $self->status->{slave_io_state} ne 'Connecting to master' ) {
            last;
        }
        else {
            sleep 1;
        }
    }

    my $status = $self->_get_lc_status;

    if (   $status->{slave_io_running} eq 'Yes'
        && $status->{slave_sql_running} eq 'Yes' )
    {
        return 1;
    }

    return 0;
}

sub refresh_status {

    my $self = shift;
    $self->status( $self->_build__status );
    return $self->status;

}

sub _build__status {

    my $self   = shift;
    my $status = $self->dbh->selectrow_hashref( "SHOW SLAVE STATUS" );

    my $lc = {};
    foreach my $col ( keys %{$status} ) {
        $lc->{ lc $col } = $status->{$col};
    }

    $self->_lc_status( $lc );
    return $status;

}

sub _get_lc_status {

    my $self = shift;
    $self->_status;
    return $self->_lc_status;

}

1;