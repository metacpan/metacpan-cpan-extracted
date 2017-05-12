package Archive::Har::Entry;

use warnings;
use strict;
use Carp();
use Archive::Har::Entry::Request();
use Archive::Har::Entry::Response();
use Archive::Har::Entry::Cache();
use Archive::Har::Entry::Timings();

our $VERSION = '0.21';

sub _DOES_NOT_APPLY { return -1 }

sub new {
    my ( $class, $params ) = @_;
    my $self = {};
    bless $self, $class;
    if ( defined $params ) {
        if ( defined $params->{pageref} ) {
            $self->pageref( $params->{pageref} );
        }
        $self->started_date_time( $params->{startedDateTime} );
        $self->request(
            Archive::Har::Entry::Request->new( $params->{request} ) );
        $self->response(
            Archive::Har::Entry::Response->new( $params->{response} ) );
        $self->cache( Archive::Har::Entry::Cache->new( $params->{cache} ) );
        $self->timings(
            Archive::Har::Entry::Timings->new( $params->{timings} ) );
        if ( defined $params->{serverIPAddress} ) {
            $self->server_ip_address( $params->{serverIPAddress} );
        }
        if ( defined $params->{connection} ) {
            $self->connection( $params->{connection} );
        }
        if ( defined $params->{comment} ) {
            $self->comment( $params->{comment} );
        }
        foreach my $key ( sort { $a cmp $b } keys %{$params} ) {
            if ( $key =~ /^_[[:alnum:]]+$/smx ) {    # private fields
                $self->$key( $params->{$key} );
            }
        }
    }
    return $self;
}

sub pageref {
    my ( $self, $new ) = @_;
    my $old = $self->{pageref};
    if ( @_ > 1 ) {
        $self->{pageref} = $new;
    }
    return $old;
}

sub started_date_time {
    my ( $self, $new ) = @_;
    my $old = $self->{startedDateTime};
    if ( @_ > 1 ) {
        if ( defined $new ) {
            my $date_regex = qr/\d{4}[-]\d{2}[-]\d{2}/smx;
            my $time_regex = qr/\d{2}:\d{2}:\d{2}[.]\d+/smx;
            my $zone_regex = qr/(?:[+]\d{2}:\d{2}|Z)/smx;
            if ( $new =~ /^${date_regex}T${time_regex}${zone_regex}$/smx ) {
                $self->{startedDateTime} = $new;
            }
            else {
                Carp::croak('started_date_time is not formatted correctly');
            }
        }
        else {
            $self->{startedDateTime} = '0000-00-00T00:00:00.0+00:00';
        }
    }
    if ( ( defined $old ) && ( $old eq '0000-00-00T00:00:00.0+00:00' ) ) {
        return;
    }
    else {
        return $old;
    }
}

sub time {
    my ($self)  = @_;
    my $timings = $self->timings();
    my $total   = 0;
    my $found   = 0;
    foreach my $timing (
        $timings->blocked(), $timings->dns(),
        $timings->connect(), $timings->send(),
        $timings->wait(),    $timings->receive(),
        $timings->ssl(),
      )
    {
        if ( defined $timing ) {
            $found = 1;
            $total += $timing;
        }
    }
    if ($found) {
        return $total;
    }
    else {
        return _DOES_NOT_APPLY();
    }
}

sub request {
    my ( $self, $new ) = @_;
    my $old = $self->{request};
    if ( @_ > 1 ) {
        $self->{request} = $new;
    }
    if ( defined $old ) {
        return $old;
    }
    else {
        return Archive::Har::Entry::Request->new();
    }
}

sub response {
    my ( $self, $new ) = @_;
    my $old = $self->{response};
    if ( @_ > 1 ) {
        $self->{response} = $new;
    }
    if ( defined $old ) {
        return $old;
    }
    else {
        return Archive::Har::Entry::Response->new();
    }
}

sub cache {
    my ( $self, $new ) = @_;
    my $old = $self->{cache};
    if ( @_ > 1 ) {
        $self->{cache} = $new;
    }
    if ( defined $old ) {
        return $old;
    }
    else {
        return Archive::Har::Entry::Cache->new();
    }
}

sub timings {
    my ( $self, $new ) = @_;
    my $old = $self->{timings};
    if ( @_ > 1 ) {
        $self->{timings} = $new;
    }
    if ( defined $old ) {
        return $old;
    }
    else {
        return Archive::Har::Entry::Timings->new();
    }
}

sub server_ip_address {
    my ( $self, $new ) = @_;
    my $old = $self->{serverIPAddress};
    if ( @_ > 1 ) {
        $self->{serverIPAddress} = $new;
    }
    return $old;
}

sub connection {
    my ( $self, $new ) = @_;
    my $old = $self->{connection};
    if ( @_ > 1 ) {
        $self->{connection} = $new;
    }
    return $old;
}

sub comment {
    my ( $self, $new ) = @_;
    my $old = $self->{comment};
    if ( @_ > 1 ) {
        $self->{comment} = $new;
    }
    return $old;
}

sub AUTOLOAD {
    my ( $self, $new ) = @_;

    my $name = $Archive::Har::Entry::AUTOLOAD;
    $name =~ s/.*://smx;    # strip fully-qualified portion

    my $old;
    if ( $name =~ /^_[[:alnum:]]+$/smx ) {    # private fields
        $old = $self->{$name};
        if ( @_ > 1 ) {
            $self->{$name} = $new;
        }
    }
    elsif ( $name eq 'DESTROY' ) {
    }
    else {
        Carp::croak(
"$name is not specified in the HAR 1.2 spec and does not start with an underscore"
        );
    }
    return $old;
}

sub TO_JSON {
    my ($self) = @_;
    my $json = {};
    if ( defined $self->pageref() ) {
        $json->{pageref} = $self->pageref();
    }
    if ( defined $self->started_date_time() ) {
        $json->{startedDateTime} = $self->started_date_time();
    }
    else {
        $json->{startedDateTime} = '0000-00-00T00:00:00.0+00:00';
    }
    $json->{time}     = $self->time();
    $json->{request}  = $self->request();
    $json->{response} = $self->response();
    $json->{cache}    = $self->cache();
    $json->{timings}  = $self->timings();
    if ( defined $self->server_ip_address() ) {
        $json->{serverIPAddress} = $self->server_ip_address();
    }
    if ( defined $self->connection() ) {
        $json->{connection} = $self->connection();
    }
    if ( defined $self->comment() ) {
        $json->{comment} = $self->comment();
    }
    foreach my $key ( sort { $a cmp $b } keys %{$self} ) {
        next if ( !defined $self->{$key} );
        if ( $key =~ /^_[[:alnum:]]+$/smx ) {    # private fields
            $json->{$key} = $self->{$key};
        }
    }
    return $json;
}

1;
__END__

=head1 NAME

Archive::Har::Entry - Represents a single http request/response pair inside the HTTP Archive

=head1 VERSION

Version '0.21'

=for stopwords HAR pageref IP DNS perldoc CPAN AnnoCPAN 

=head1 SYNOPSIS

    use Archive::Har();

    my $http_archive_string = '"log": { "version": "1.1", .... ';
    my $har = Archive::Har->new();
    $har->string($http_archive_string);
    foreach my $entry ($har->entries()) {
        print "PageRef: " . $entry->pageref() . "\n";
        print "DateTime: " . $entry->started_date_time() . "\n";
        print "Total Elasped Time: " . $entry->time() . "\n";
        my $request = $entry->request();
        my $response = $entry->response();
        my $cache = $entry->cache();
        my $timing = $entry->pageTimings();
        print "Server IP Address: " . $entry->server_ip_address() . "\n";
        print "Connection: " . $entry->connection() . "\n";
        print "Comment: " . $entry->comment() . "\n";
        $entry->comment("Something interesting here");
    }

=head1 DESCRIPTION
 
This Module is intended to provide an interface to create/read/update
Entry objects in HTTP Archive (HAR) files.

=head1 SUBROUTINES/METHODS

=head2 new

returns a new Entry object

=head2 pageref

returns the L<reference|Archive::Har::Page/"id"> to the parent L<page|Archive::Har::Page>.  This may be null.

=head2 started_date_time

returns the date and time stamp for the beginning of the request (ISO 8601 format)

=head2 time

returns the total elapsed time of the request in milliseconds.  It is the sum of all the timings available in the L<timings|Archive::Har::Entry::Timings> object (not including undefined values).

=head2 request

returns the L<request|Archive::Har::Entry::Request> object

=head2 response

returns the L<response|Archive::Har::Entry::Response> object

=head2 cache

returns the L<cache|Archive::Har::Entry::Cache> object

=head2 timings

returns the entry L<timings|Archive::Har::Entry::Timings> object

=head2 server_ip_address

returns the IP address of the server that was connected (result of DNS resolution)

=head2 connection

returns the unique ID of the parent TCP/IP connection.  This can be the client port number.

=head2 comment

returns the comment about the Entry

=head1 DIAGNOSTICS

=over

=item C<< started_date_time is not formatted correctly >>

The started_date_time field must be formatted like so

0000-00-00T00:00:00.0+00:00

=item C<< %s is not specified in the HAR 1.2 spec and does not start with an underscore >>

The HAR 1.2 specification allows undocumented fields, but they must start with an underscore

=back

=head1 CONFIGURATION AND ENVIRONMENT

Archive::Har::Entry requires no configuration files or environment variables.  

=head1 DEPENDENCIES

Archive::Har::Entry requires no additional non-core Perl modules

=head1 INCOMPATIBILITIES

None reported

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-archive-har at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Archive-Har>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
