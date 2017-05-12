
package CGI::Session::Driver::pure_sql;
use strict;
use vars qw($VERSION @ISA $SERIALIZER);

require CGI::Session::Driver::DBI;
@ISA = qw( CGI::Session::Driver::DBI ); # provides 'table_name'
#use base 'CGI::Session::Driver::DBI';

$VERSION = '0.70';

$SERIALIZER = 'CGI::Session::Serialize::sql_abstract';
require CGI::Session::Serialize::sql_abstract;

sub init {
    my $self = shift;
    return $self->SUPER::init()
}

sub store {
    my ($self, $sid, $data_href) = @_;

    my $dbh = $self->{Handle};

    my $session_exists;
    eval {
        ($session_exists) = $dbh->selectrow_array(
            ' SELECT session_id   FROM '.$self->table_name.
            ' WHERE session_id = ? FOR UPDATE',{},$sid);

    };
    if( $@ ) {
        $self->error("Couldn't acquire data on id '$sid'");
        return undef;
    }

    eval { require SQL::Abstract; };
    if ($@) {
        $self->error('SQL::Abstract required but not found.');
        return undef;
    }
    my $sa = SQL::Abstract->new();

    eval {
        if ($session_exists) {
             my($stmt, @bind) =
                $sa->update(
                    $self->table_name,
                    $data_href,
                    { session_id => $sid });
            $dbh->do($stmt,{},@bind);
        }
        else {
            my($stmt, @bind) = $sa->insert( $self->table_name, $data_href  );

            $dbh->do($stmt,{},@bind);

        }

    };

    if( $@ ) {
        $self->error("Error in session update on id '$sid'. $@");
        warn("Error in session update on id '$sid'. $@");
        return undef;
    }

    return 1;


}


sub retrieve {
    my ($self, $sid ) = @_;
    my $dbh = $self->{Handle};
    my $drv = $dbh->{Driver}->{Name};

    my $data;

    my $epoch_func;
    if ($dbh->{Driver}->{Name} eq 'mysql') {
        $epoch_func = sub { sprintf 'UNIX_TIMESTAMP(%s)', $_[0] };
    }
    elsif ($dbh->{Driver}->{Name} eq 'Pg') {
        $epoch_func = sub { sprintf 'EXTRACT(EPOCH FROM %s)', $_[0] };
    }
    else {
        $self->error('Unsupported DBI driver. Currently only Pg and mysql are supported.');
        return undef;
    }


    eval {
        $data = $dbh->selectrow_hashref(
            ' SELECT  *
                , '.$epoch_func->('creation_time')              .' as creation_time
                , '.$epoch_func->('last_access_time')           .' as last_access_time
                , '.$epoch_func->("last_access_time + duration").'as end_time
              FROM '.$self->table_name.
            ' WHERE session_id = '.$dbh->quote($sid)
        );
    };
    if( $@ ) {
        $self->error("Couldn't acquire data on id '$sid'");
        return undef;
    }

    return 0 unless $data;

    my $thawed_data  = $SERIALIZER->thaw( $data );
    unless ( defined $thawed_data ) {
        return $self->set_error( "couldn't freeze data: " . $SERIALIZER->errstr() );
    }

    return $thawed_data;
}



sub remove {
    my ($self, $sid, $options) = @_;
    my $dbh = $self->{Handle};

    eval { $dbh->do( 'DELETE FROM '.$self->table_name.' WHERE session_id = '.$dbh->quote($sid)) };
    if( $@ ) {
        warn $@;
        $self->error("Couldn't delete session row for: '$sid'");
        return undef;
    }
    else {
        return 1;
    }

    die "testing!";

}

# Called right before the object is destroyed to do cleanup
sub DESTROY {
    my ($self, $sid, $options) = @_;

    my $dbh = $self->{Handle};

    # Call commit if we are in control of the handle
    # /and/ AutoCommit is not in effect
    # /and/ the object is modified or deleted.
    if ($self->{_disconnect} &&
        !$dbh->{AutoCommit} &&
        (($self->{_STATUS} == MODIFIED() ) or ($self->{_STATUS} == DELETED()))) {
        $dbh->commit();
    }

    if ( $self->{_disconnect} ) {
        $dbh->disconnect();
    }

    return 1;
}

1;

=pod

=head1 NAME

CGI::Session::Driver::pure_sql - Pure SQL driver with no embedded Perl stored in the database

=head1 SYNOPSIS

    use CGI::Session::Driver::pure_sql;
    $session = CGI::Session->new("driver:pure_sql;serializer:sql_abstract", undef, {Handle=>$dbh});

For more examples, consult L<CGI::Session> manual

=head1 DESCRIPTION

*Disclaimer* While this software is complete and includes a working test suite,
I'm marking it as a development release to leave room for feedback on the
interface. Until that happens, it's possible I may make changes that aren't
backwards compatible. You can help things along by communicating by providing
feedback about the module yourself.

CGI::Session::Driver::pure_sql is a CGI::Session driver to store session
data in a SQL table. Unlike the C<CGI::Session::Driver::postgresql> driver, this
"pure SQL" driver does not serialize any Perl data structures to the database.

The means that you can access all the data in the session easily using standard
SQL syntax.

The downside side is that you have create the columns for any data you want to
store, and each field will have just one value: You can't store arbitrary data
like you can with the L<CGI::Session::Driver::postgresql> driver. However, you may already be in
the habit of writing applications which use standard SQL structures, so this
may not be much of a drawback. :)

It currently requires the sql_abstract serializer to work, which is included in
the distribution.

=head1 STORAGE

To store session data in SQL  database, you first need
to create a suitable table for it with the following command:

    -- This syntax for for Postgres; flavor to taste
    CREATE TABLE sessions (
        session_id       CHAR(32) NOT NULL,
        remote_addr      inet,
        creation_time    timestamp,
        last_access_time timestamp,
        duration         interval
    );

You can also add any number of additional columns to the table,
but the above fields are required.

For any additional columns you add, if you would like to
expire that column individually, you need to an additional
column to do that. For example, to add a column named C<order_id>
which you want to allow to be expired, you would add these two columns:

    order_id            int,
    order_id_exp_secs   int,

If you want to store the session data in other table than "sessions",
you will also need to specify B<TableName> attribute as the
first argument to new():

    use CGI::Session;

    $session = CGI::Session->new("driver:pure_sql;serializer:sql_abstract", undef,
                        {Handle=>$dbh, TableName=>'my_sessions'});

Every write access to session records is done through PostgreSQL own row locking mechanism,
enabled by `FOR UPDATE' clauses in SELECTs or implicitly enabled in UPDATEs and DELETEs.

To write your own drivers for B<CGI::Session> refere L<CGI::Session> manual.

=head1 COPYRIGHT

Copyright (C) 2003-2010 Mark Stosberg. All rights reserved.

This library is free software and can be modified and distributed under the same
terms as Perl itself.

=head1 CONTRIBUTING

Patches, questions and feedback are welcome. Please use the bug tracker to submit
bugs and patches, and e-mail directly with questions and feedback.

https://rt.cpan.org/Public/Dist/Display.html?Name=CGI-Session-Driver-pure_sql

=head1 AUTHOR

Mark Stosberg <mark@summersault.com>

=head1 SEE ALSO

=over 4

=item *

L<CGI::Session|CGI::Session> - CGI::Session manual

=item *

L<CGI::Session::Tutorial|CGI::Session::Tutorial> - extended CGI::Session manual

=item *

L<CGI::Session::CookBook|CGI::Session::CookBook> - practical solutions for real life problems

=item *

B<RFC 2965> - "HTTP State Management Mechanism" found at ftp://ftp.isi.edu/in-notes/rfc2965.txt

=item *

L<CGI|CGI> - standard CGI library

=item *

L<Apache::Session|Apache::Session> - another fine alternative to CGI::Session

=back

=cut



