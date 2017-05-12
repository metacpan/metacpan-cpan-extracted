package Business::MaxMind::HTTPBase;

use 5.006;

use strict;

use LWP::Protocol::https;
use LWP::UserAgent;
use URI::Escape;

our $VERSION = '1.60';

my $API_VERSION = join( '/', 'Perl', $VERSION );

# default minfraud servers
my @defaultservers = (
    'minfraud.maxmind.com', 'minfraud-us-east.maxmind.com',
    'minfraud-us-west.maxmind.com'
);

sub new {
    my $i = 0;
    my ($class) = shift;
    if ( $class eq 'Business::MaxMind::HTTPBase' ) {
        die
            "Business::MaxMind::HTTPBase is an abstract class - use a subclass instead";
    }
    my $self = {@_};
    bless $self, $class;
    $self->{isSecure} = 1 unless exists $self->{isSecure};
    for my $server (@defaultservers) {
        $self->{servers}->[$i] = $server;
        $i++;
    }
    $self->{ua} = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 } );
    $self->_init;
    return $self;
}

sub getServers {
    return [ @{ $_[0]->{servers} || [] } ];
}

sub setServers {
    my ( $self, $serverarrayref ) = @_;
    $self->{servers} = [@$serverarrayref];
}

sub query {
    my ($self) = @_;
    my $s = $self->{servers};
    my $datetime;

    for my $server (@$s) {
        my $result = $self->querySingleServer($server);
        return $result if $result;
    }
    return 0;
}

sub input {
    my $self = shift;
    my %vars = @_;
    while ( my ( $k, $v ) = each %vars ) {
        unless ( exists $self->{allowed_fields}->{$k} ) {
            die "invalid input $k - perhaps misspelled field?";
        }
        $self->{queries}->{$k} = $self->filter_field( $k, $v );
    }
}

# sub-class should override this if it needs to filter inputs
sub filter_field {
    my ( $self, $name, $value ) = @_;
    return $value;
}

sub output {
    my $self = shift;
    return $self->{output};
}

# if possible send the escaped string as latin1 for backward compatibility.
# That makes a difference for chars 128..255
# otherwise use utf8 encoding.
#
sub _mm_uri_escape {
    return uri_escape( $_[0] ) if $] < 5.007;
    return utf8::downgrade( my $t = $_[0], 1 )
        ? uri_escape( $_[0] )
        : uri_escape_utf8( $_[0] );
}

sub querySingleServer {
    my ( $self, $server ) = @_;
    my $url
        = ( $self->{isSecure} ? 'https' : 'http' ) . '://'
        . $server . '/'
        . $self->{url};
    my $check_field  = $self->{check_field};
    my $queries      = $self->{queries};
    my $query_string = join(
        '&',
        map { "$_=" . _mm_uri_escape( $queries->{$_} ) } keys %$queries
    );
    $query_string .= "&clientAPI=$API_VERSION";
    if ( $self->{"timeout"} > 0 ) {
        $self->{ua}->timeout( $self->{"timeout"} );
    }
    my $request = HTTP::Request->new( 'POST', $url );
    $request->content_type('application/x-www-form-urlencoded');
    $request->content($query_string);
    if ( $self->{debug} ) {
        print STDERR "sending HTTP::Request: " . $request->as_string;
    }
    my $response = $self->{ua}->request($request);
    if ( $response->is_success ) {
        my $content = $response->content;
        my @kvpair = split( ';', $content );
        my %output;
        for my $kvp (@kvpair) {
            my ( $key, $value ) = split( '=', $kvp, 2 );
            $output{$key} = $value;
        }
        unless ( exists $output{$check_field} ) {
            return 0;
        }
        $self->{output} = \%output;
        return 1;
    }
    else {
        if ( $self->{debug} ) {
            print STDERR "Error querying $server code: " . $response->code;
        }
        return 0;
    }
}

1;

=pod

=head1 NAME

Business::MaxMind::HTTPBase - Base class for accessing HTTP web services

=head1 VERSION

version 1.60

=head1 DESCRIPTION

This is an abstract base class for accessing MaxMind web services.

=head1 METHODS

=over 4

=item new

Class method that returns a new object that is a subclass of Business::MaxMind::HTTPBase.
Will die if you attempt to call this for the Business::MaxMind::HTTPBase class, instead
you should call it on one of its subclasses.

=item input

Sets input fields.  See subclass for details on fields that should be set.
Returns 1 on success, 0 on failure.

=item query

Sends out query to MaxMind server and waits for response.  If the primary
server fails to respond, it sends out a request to the secondary server.
Returns 1 on success, 0 on failure.

=item output

Returns the output returned by the MaxMind server as a hash reference.

=back

=head1 SEE ALSO

L<Business::MaxMind::CreditCardFraudDetection>

L<https://www.maxmind.com/en/minfraud-services>

=head1 AUTHORS

=over 4

=item *

TJ Mather <tjmather@maxmind.com>

=item *

Frank Mather <frank@maxmind.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by MaxMind, Inc..

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

__END__

# ABSTRACT: Base class for accessing HTTP web services

