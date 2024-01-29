package CrowdSec::Client;

use strict;
use Date::Parse;
use HTTP::Request::Common;
use JSON;
use LWP::UserAgent;
use Moo;
use POSIX "strftime";

our $VERSION = '0.04';

# Default alert template
our %DEFAULTS = (
    duration  => '4h',
    labels    => undef,
    origin    => 'CrowdSec::Client',
    reason    => 'Banned by CrowdSec::Client',
    scenario  => 'Banned by CrowdSec::Client',
    simulated => JSON::false,
    type      => 'ban',
);

# Watcher accessors
has machineId => ( is => 'ro' );
has password  => ( is => 'ro' );
has token     => ( is => 'rw' );
has tokenVal  => ( is => 'rw' );
has strictSsl => ( is => 'ro', default => 1, );
has baseUrl   => ( is => 'ro' );

# Bouncer accessors
has apiKey => ( is => 'ro' );

# Common accessors
has userAgent => (
    is      => 'ro',
    default => sub {
        return LWP::UserAgent->new(
            $_[0]->strictSsl
            ? ()
            : (
                ssl_opts => {
                    verify_hostname => 0,
                    SSL_verify_mode => 0
                }
            )
        );
    }
);

has autoLogin => ( is => 'ro' );

has error => ( is => 'rw' );

sub login {
    my ($self) = @_;
    my $error = 0;
    return 1 if $self->tokenIsvalid;
    foreach my $k (qw(machineId password baseUrl)) {
        unless ( $self->{$k} ) {
            $self->error("Missing parameter: $k");
            $error++;
        }
    }
    return if $error;
    my $request = POST(
        $self->baseUrl . '/v1/watchers/login',
        Accept       => 'application/json',
        Content_Type => 'application/json',
        Content      => JSON::to_json(
            {
                machine_id => $self->machineId,
                password   => $self->password,
                scenarios  => [],
            }
        )
    );
    my $response = $self->userAgent->request($request);
    if ( $response->is_success ) {
        eval {
            my $tmp = JSON::from_json( $response->content );
            $self->token( $tmp->{token} );
            $self->tokenVal( str2time( $tmp->{expire} ) );
        };
        if ($@) {
            $self->error("Bad response content from CrowdSec server: $@");
            return;
        }
        if ( !$self->token and !$self->tokenVal ) {
            $self->error(
                "Missing token and expire fields in CrowdSec response: "
                  . $response->content );
        }
        return 1;
    }
    else {
        $self->error(
            "Bad response from CrowdSec server: " . $response->status_line );
        return;
    }
}

sub banIp {
    my ( $self, $ip, %params ) = @_;
    unless ( $ip ) {
        $self->error('Usage: banIp($ip, \%options)');
        return;
    }
    if ( $self->autoLogin ) {
        unless ( $self->login ) {
            return;
        }
    }
    unless ( $self->token ) {
        $self->error("No valid token");
        return;
    }
    my %prm = ( %DEFAULTS, %params );
    $prm{simulated} = $prm{simulated} ? JSON::true : JSON::false;
    my $stamp    = strftime "%Y-%m-%dT%H:%M:%SZ", gmtime(time);
    my $decision = [
        {
            capacity   => 0,
            created_at => $stamp,
            decisions  => [
                {
                    duration => $prm{duration},
                    origin   => $prm{origin},
                    scenario => $prm{scenario},
                    scope    => 'Ip',
                    type     => $prm{type},
                    value    => $ip,
                }
            ],
            events           => [],
            events_count     => 1,
            labels           => $prm{labels},
            leakspeed        => '0',
            message          => $prm{reason},
            scenario         => $prm{reason},
            scenario_hash    => '',
            scenario_version => '',
            simulated        => $prm{simulated},
            source           => {
                ip    => $ip,
                scope => 'Ip',
                value => $ip,
            },
            start_at => $stamp,
            stop_at  => $stamp,
        }
    ];
    my $request = POST(
        $self->baseUrl . '/v1/alerts',
        Authorization => 'Bearer ' . $self->token,
        Content_Type  => 'application/json',
        Content       => JSON::to_json($decision),
    );
    my $response = $self->userAgent->request($request);
    if ( $response->is_success ) {
        my $response_content = $response->content;
        my $res              = eval { JSON::from_json($response_content)->[0] };
        if ($@) {
            $self->error(
                "CrowdSec didn't return an array: " . $response->content );
            return;
        }
        return $res;
    }
    else {
        print "Échec de la requête : " . $response->status_line . "\n";
        return;
    }
}

sub testIp {
    my ( $self, $ip ) = @_;
    my $error = 0;;
    foreach my $k (qw(apiKey baseUrl)) {
        unless ( $self->{$k} ) {
            $self->error("Missing parameter: $k");
            $error++;
        }
    }
    unless ($ip) {
        $self->error('Missing IP');
        $error++;
    }
    return (0, $self->error) if $error;
    my $response = $self->userAgent->get(
        $self->baseUrl . "/v1/decisions?ip=$ip",
        Accept      => 'application/json',
        'X-Api-Key' => $self->apiKey,
    );
    if ( $response->is_success ) {
        my @decisions;
        return 0 if !$response->content or $response->content eq 'null';
        eval {
            my $tmp = JSON::from_json( $response->content );
            @decisions = @$tmp;
        };
        if ($@) {
            $self->error("Bad response content from CrowdSec server: $@");
            return (0, $self->error);
        }
        return 0 unless @decisions;
        foreach my $decision (@decisions) {
            if ( $decision->{type} and $decision->{type} eq 'ban' ) {
                return 1;
            }
        }
        return 0;
    };
}

sub tokenIsvalid {
    my ($self) = @_;
    return ( $self->tokenVal and ( $self->tokenVal > time ) );
}

1;
__END__

=head1 NAME

CrowdSec::Client - CrowdSec client

=head1 SYNOPSIS

  # Bouncer
  use CrowdSec::Client;
  my $client = CrowdSec::Client->new({
    apiKey => "myApiKey",
    baseUrl   => "http://127.0.0.1:8080",
  });
  if ( $client->testIp('1.2.3.4') ) {
    print STDERR "IP banned by crowdsec\n";
  }

  # Watcher
  use CrowdSec::Client;
  my $client = CrowdSec::Client->new({
    machineId => "myid",
    password  => "mypass",
    baseUrl   => "http://127.0.0.1:8080",
    autoLogin => 1;
  });
  $client->banIp('2.3.4.5') or die( $client->error );
  $client->banIp('1.2.3.4', duration => '5h', reason => 'Ban by my app')
    or die( $client->error );

=head1 DESCRIPTION

CrowdSec::Client is a simple CrowdSec Client. It permits one to query Crowdsec
database or to ban an IP.

=head2 Constructor

CrowdSec::Client requires a hashref as argument with the following keys:

=over

=item B<Common parameters>

=over

=item B<baseUrl> I<(required) to ban>: the base URL to connect to local CrowdSec
server. Example: B<http://localhost:8080>.

=item B<userAgent> I<(optional)>: a L<LWP::UserAgent> object. If noone is
given, a new LWP::UserAgent will be created.

=item B<autoLogin>: indicates that CrowdSec::Client has to login automatically
when C<banIp()> is called. Else you should call manually C<login()> method.

=item B<strictSsl>: I<(default: 1)>. If set to 0, and if B<userAgent> isn't
set, the internal LWP::UserAgent will ignore SSL errors.

=back

=item B<Watcher parameters>

=over

=item B<machineId> I<(required)>: the watcher identifier given by Crowdsec
I<(see L</Enrollment>)>.

=item B<password> I<(required)>: the watcher password

=back

=item B<Bouncer parameters>

=over

=item B<apiKey> I<(required)>: the Crowdsec API key

=back

=back

=head2 Methods

=head3 banIp()

banIp adds the given IP into decisions. Usage:

  $client->banIp( $ip, %parameters );

Parameters:

=over

=item B<duration> I<(default: 4h)>: the duration of the decision

=item B<origin> I<(default: "CrowdSec::Client")>

=item B<reason> I<(default: "Banned by CrowdSec::Client")>

=item B<scenario> I<(default: "Banned by CrowdSec::Client"))>

=item B<simulated> I<(default: 0)>: if set to 1, the flag "simulated" is added

=item B<type> I<(default: "ban")>

=back

=head1 Enrollment

=head2 Bouncer

To get a Crowdsec API key, you can use:

  $ sudo cscli bouncers add myBouncerName

=head2 Watcher

To get a Watcher password, you can use:

  $ sudo cscli machines add MyId --password myPassword

=head1 SEE ALSO

L<CrowdSec|https://crowdsec.net/>

=head1 AUTHOR

Xavier Guimard E<lt>xguimard@linagora.muE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by L<Linagora|https://linagora.com>

License: AGPL-3.0 (see LICENSE file)

=cut
