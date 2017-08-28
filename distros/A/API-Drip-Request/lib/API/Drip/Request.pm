package API::Drip::Request;

use v5.14;
use strict;
use warnings;

use Params::ValidationCompiler qw( validation_for );
use Types::Standard qw( Str HashRef CodeRef);
use YAML;
use File::Spec;
use File::HomeDir;
use Readonly;
use Carp;
use LWP::UserAgent;
use HTTP::Request::Common;
use JSON;
use URI;
use Data::Printer;

Readonly our %DEFAULTS => (
    DRIP_TOKEN => undef,
    DRIP_ID    => undef,
    DRIP_URI   => 'https://api.getdrip.com/v2',
    DRIP_AGENT => 'API::Drip',
    DRIP_DEBUG => 0,
);

=head1 NAME

API::Drip::Request - Perl interface to api.getdrip.com

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use API::Drip::Request;

    my $drip = API::Drip::Request->new();

    $drip->do_request( POST => 'subscribers', { subscribers => [ { email => 'foo@example.com', ... }] } );

=head1 DESCRIPTION

Low-level perl interface to the Drip API as specified at https://www.getdrip.com/docs/rest-api

All of the methods in this module will throw exceptions on error. 

=head1 SUBROUTINES/METHODS

=head2 new()

Creates the API::Drip::Request object.  See L</"CONFIGURATION"> for accepted parameters.

Also accepts: 

=over 

=item debugger

A codref that should accept a list of diagnostic strings and log them somewhere
useful for debugging purposes.  Only used when DRIP_DEBUG is true.   

=back

=cut

my $config_validator = validation_for(
    params => {
        DRIP_CLIENT_CONF => { type => Str(), optional => 1 },
        map { $_ => { type => Str(), optional => 1 } } keys %DEFAULTS,
        debugger => { type => CodeRef(), optional => 1 },
    }
);

sub new {
    my $class = shift;
    my %OPT = $config_validator->(@_);

    my $self = _load_conf( \%OPT );

    # At this point, all configuration values should be set
    foreach my $key ( keys %DEFAULTS ) {
        confess "Missing configuration $key" unless defined $self->{$key};
    }

    $self->{debugger} = _mk_debugger( $self, %OPT );

    bless $self, $class;
    return $self;
}

sub _mk_debugger {
    my ($self, %OPT)  = @_;

    unless ($self->{DRIP_DEBUG}) { return sub {}; }
    if ( $OPT{debugger} ) { return $OPT{debugger} }

    return sub { warn join "\n", map { ref($_) ? np $_ : $_ } @_ };
}

=head2 do_request

Accepts the following positional parameters:

=over

=item HTTP Method (required)

May be 'GET', 'POST', 'DELETE', 'PATCH', etc..

=item Endpoint (requird)

Specifies the path of the REST enpoint you want to query.   Include everything after the account ID.   For example, "subscribers", "subscribers/$subscriber_id/campaign_subscriptions", etc...

=item Content (optional)

Perl hashref of data that will be sent along with the request.   

=back

On success, returns a Perl data structure corresponding to the data returned
from the server.    Some operations (DELETE), do not return any data and may
return undef on success.  On error, this method will die() with the
HTTP::Response object.

=cut

my $request_validator = validation_for( params => [ {type => Str()}, {type => Str()}, {type => HashRef(), optional => 1} ] );
sub do_request {
    my $self = shift;
    my ($method, $endpoint, $content) = $request_validator->(@_);

    my $uri = URI->new($self->{DRIP_URI});
    $uri->path_segments( $uri->path_segments, $self->{DRIP_ID}, split( '/', $endpoint) );

    $self->{debugger}->( 'Requesting: ' . $uri->as_string );
    my $request = HTTP::Request->new( $method => $uri->as_string, );
    if ( ref($content) ) {
        $request->content_type('application/vnd.api+json');
        $request->content( encode_json( $content ) );
    }
    $request->authorization_basic( $self->{DRIP_TOKEN}, '' );

    $self->{agent} //= LWP::UserAgent->new( agent => $self->{DRIP_AGENT} );
    my $result = $self->{agent}->request( $request );

    unless ( $result->is_success ) {
        $self->{debugger}->("Request failed", $result->content);
        die $result;
    }

    if ( $result->code == 204 ) {
        $self->{debugger}->("Success, no content");
        return undef;
    }
    my $decoded = eval {decode_json( $result->content )};
    if ( $@ ) {
        $self->{debugger}->('Failed to decode JSON:', $@, $result->content);
        die $result;
    }
    return $decoded;
}


=head1 CONFIGURATION

Configuration data may be passed in through a number of different ways, which are searched in the following order of preference:

=over

=item 1. As direct paramteters to new().

=item 2. As environment variables.

=item 3. As elments of the first YAML configuration file that is found and readable in the following locations: 

=over

=item 1. The location specified by the DRIP_CLIENT_CONF parameter supplied to new().

=item 2. The location specified by $ENV{DRIP_CLIENT_CONF}.

=item 3. $ENV{HOME}/.drip.conf

=back

=back

The following configuration data is accepted:

=over

=item * DRIP_TOKEN (required)

This is the user token assigned to you by drip.   When you are logged in, look for "API Token" at https://www.getdrip.com/user/edit

=item * DRIP_ID (required)

This is the numeric user id assigned to you by drip.   When logged in, find it in your settings under Account->General Info.

=item * DRIP_URI (optional)

This defaults to https://api.getdrip.com/v2.   You probably shouldn't change this.

=item * DRIP_AGENT (optional)

Defaults to "API::Drip".   Specifies the HTTP Agent header.

=item * DRIP_DEBUG (optional)

Defaults to 0.   Set to a true value to enable debugging.

=cut

sub _load_conf {
    my $OPT = shift();
    my $conf = {};

    KEY:
    foreach my $key ( keys %DEFAULTS ) {
        next KEY if defined $OPT->{$key};

        if ( defined $ENV{$key} ) { $conf->{$key} = $ENV{$key};  next KEY; }

        state $YAML_CONF //= _load_yaml_conf( $OPT );
        if ( defined $YAML_CONF->{$key} ) { $conf->{$key} = $YAML_CONF->{$key}; next KEY; }

        $conf->{$key} = $DEFAULTS{$key};
    }
    return $conf;
}

sub _load_yaml_conf {
    my $OPT = shift();

    FILE:
    foreach my $location( $OPT->{DRIP_CLIENT_CONF}, $ENV{DRIP_CLIENT_CONF}, File::Spec->catfile( File::HomeDir->my_home, '.drip.conf' )) {
        no warnings 'uninitialized';
        next FILE unless -f $location && -r _; 
        return YAML::LoadFile $location;
    }
}

=head1 AUTHOR

Dan Wright, C<< <Dan at DWright.Org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-api-drip at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=API-Drip>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc API::Drip::Request


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=API-Drip>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/API-Drip>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/API-Drip>

=item * Search CPAN

L<http://search.cpan.org/dist/API-Drip/>

=back


=head1 ACKNOWLEDGEMENTS

This code is written to help support my day job and is being released open
source thanks to pair Networks, Inc.

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Dan Wright.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of API::Drip::Request
