package DBIx::JSON;

use warnings;
use strict;

=head1 NAME

DBIx::JSON - Perl extension for creating JSON from existing DBI datasources

=head1 DESCRIPTION

This module is perl extension for creating JSON from existing DBI datasources.

One use of this module might be to extract data on the web
server, and send the raw data (in JSON format) to a client's
browser, and then JavaScript do eval it to generate dynamic HTML.

This module was inspired by DBIx::XML_RDB.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    my $dsn = "dbname=$dbname;host=$host;port=$port";
    print DBIx::JSON->new( $dsn, "mysql", $dbusername, $dbpasswd )
        ->do_select("select * from table;")->get_json;

    or

    my $dsn = "dbname=$dbname;host=$host;port=$port";
    my $obj = DBIx::JSON->new($dsn, "mysql", $dbusername, $dbpasswd);
    $obj->do_select("select * from table;", "colmun1", 1);
    $obj->err && die $obj->errstr;
    print $obj->get_json;

=head1 EXPORT

None.

=cut

use DBI 1.15 ();
use Carp ();
use JSON::Syck;

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    $self->_init(@_) || return ();
    return $self;
}

sub _init {
    my $self   = shift;
    my $dsn    = shift;
    my $driver = shift;
    my $userid = shift;
    my $passwd = shift;

    eval {
        $self->{dbh} =
          DBI->connect( "dbi:$driver:$dsn", $userid, $passwd,
            { PrintWarm => 0, PrintError => 1 } );
      }
      or $@ && Carp::croak $@;
    if ( !$self->{dbh} ) {
        return ();
    }
    else {
        $self->{dbh}->{PrintError} = 0;
    }
    1;
}

sub do_select {
    my $self       = shift;
    my $sql        = shift;
    my $key_field  = shift;
    my $hash_array = shift;
    if ($key_field) {
        eval {
            $self->{data} = $self->{dbh}->selectall_hashref( $sql, $key_field );
          }
          or $@ && Carp::croak $@;
        if ( $self->{dbh}->err ) {
            Carp::carp $self->{dbh}->errstr;
        }
        if ($hash_array) {
            $self->{data} = [ values( %{ $self->{data} } ) ];
        }
    }
    else {
        eval { $self->{data} = $self->{dbh}->selectall_arrayref($sql); }
          or $@ && Carp::croak $@;
        if ( $self->{dbh}->err ) {
            Carp::carp $self->{dbh}->errstr;
        }
    }
    return $self;
}

sub do_sql {
    my $self = shift;
    my $sql  = shift;
    eval { $self->{dbh}->do($sql); }
      or $@ && Carp::croak $@;
    if ( $self->{dbh}->err ) {
        Carp::carp $self->{dbh}->errstr;
    }
    return $self;
}

sub has_data {
    my $self = shift;
    if ( ref $self->{data} ) {
        return 1;
    }
    return ();
}

sub get_json {
    my $self = shift;
    if ( $self->has_data ) {
        return JSON::Syck::Dump( $self->{data} );
    }
    return ();
}

sub clear_data {
    my $self = shift;
    $self->{data} = ();
    1;
}

sub errstr {
    my $self = shift;
    if ( $self->{dbh} ) {
        return $self->{dbh}->errstr;
    }
    else {
        return ();
    }
}

sub err {
    my $self = shift;
    if ( $self->{dbh} ) {
        return $self->{dbh}->err;
    }
    else {
        return ();
    }
}

sub DESTROY {
    my $self = shift;
    if ( $self->{dbh} ) {
        $self->{dbh}->disconnect;
    }
    else {
        return ();
    }
}

1;    # End of DBIx::JSON

__END__

=head1 METHODS

=head2 new

    DBIx::JSON->new( $dsn, $dbidriver, $dbusername, $dbpasswd );

This method is a constructor.
See the DBI documentation for what each of these means.

=head2 do_select

    $obj->do_select( $sql [, $key_field [, $hash_array] ] );

This takes a SELECT command string, and calls DBI::selectall_arrayref
method. If $key_field is given, this calls DBI::selectall_hashref method.
See the DBI documentation for details. $hash_array affects get_json method.

This doesn't do any checking if the sql is valid. Subsequent calls
to do_select do overwrite the output.

=head2 do_sql

    $obj->do_sql( $sql );

This takes a non SELECT command string (e.g. UPDATE/INSERT/DELETE),
and calls DBI::do method. See the DBI documentation for details.

=head2 get_json

    $obj->get_json;

Simply returns the JSON generated from the previous SQL call.
The format of the JSON output is something like this:

    # default
    [
        ["user1", "data1"],
        ["user2", "data2"],
        ["user3", "data3"],
        ...
    ]

    # if do_select was called with $key_field
    {
        "user1":{"data":"data1", "name":"user1"},
        "user2":{"data":"data2", "name":"user2"},
        "user3":{"data":"data3", "name":"user3"},
        ...
    }

    # if do_select was called with $hash_array
    [
        {"data":"data1", "name":"user1"},
        {"data":"data2", "name":"user2"},
        {"data":"data3", "name":"user3"},
        ...
    ]

=head2 has_data

    $obj->has_data;

This returns whether get_json method can be called or not.

=head2 clear_data

    $obj->clear_data;

This clears the results from the previous SQL call.

=head2 err

    $obj->err;

This returns $DBI::err.

=head2 errstr

    $obj->errstr;

This returns $DBI::errstr.

=head1 AUTHOR

JSON::Syck by Tatsuhiko Miyagawa, C<< <miyagawa@bulknews.net> >>
Tweaked by Koji Komatsu, C<< <yosty@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dbix-json at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-JSON>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::JSON

You can also look for information at:

=head1 SEE ALSO

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-JSON>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-JSON>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-JSON>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-JSON>

=back

=head1 ACKNOWLEDGEMENTS

None.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Koji Komatsu, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

