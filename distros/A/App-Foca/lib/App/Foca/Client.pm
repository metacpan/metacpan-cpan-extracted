#
# App::Foca::Client
#
# Author(s): Pablo Fischer (pablo@pablo.com.mx)
# Created: 06/19/2012 08:53:33 PM UTC 08:53:33 PM
package App::Foca::Client;

=head1 NAME

App::Foca::Client - Foca client

=head1 DESCRIPTION

L<App::Foca::Client> is the client used to send I<foca> requests to
a set of hosts. I<foca> requests are basically HTTP requests that go to each
given host and execute a command via the running I<foca> server (see
L<App::Foca::Server>).

=head1 EXAMPLE

    my $command         = shift @ARGV || 'true';
    my $port            = 6666;
    my $debug           = 1;

    my $client = App::Foca::Client->new(
                port                => $port,
                debug               => $debug);

    my @hosts = qw(localhost);
    my @result = $client->run(\@hosts, $command);

    die "Not able to collect any data" unless @result;

    foreach my $host (@result) {
        my $status = $host->{'ok'} ? 'OK' : 'ERROR';
        print "$status: $host->{'hostname'}: $host->{'output'}\n";
    }

    # or..

    $client->run(\@hosts, $command, {
            on_host => \&parse_host});

    sub parse_host {
        my ($host) = @_;

        my $status = $host->{'ok'} ? 'OK' : 'ERROR';
        print "$status: $host->{'hostname'}: $host->{'output'}\n";
    }

=cut
use strict;
use warnings;
use Data::Dumper;
use FindBin;
use HTTP::Response;
use Moose;
use Parallel::ForkManager;
use WWW::Curl::Easy;
use YAML::Syck qw(LoadFile);
# Foca libs/modules
use App::Foca::Tools::Logger;

=head1 Attributes

=over 4

=item B<maxflight>

Max number of connections to do at a time. Defaults 15.

=cut
has 'maxflight' => (
    is          => 'rw',
    isa         => 'Int',
    default     => 15);

=item B<timeout>

Timeout per host in seconds. Defaults 60 seconds.

=cut
has 'timeout' => (
    is          => 'rw',
    isa         => 'Int',
    default     => 60);

=item B<connect_timeout>

TCP/connection timeout. Defaults to 5 seconds.

=cut
has 'connect_timeout' => (
    is          => 'rw',
    isa         => 'Int',
    default     => 5);

=item B<port>

TCP port where foca server is running.

=cut
has 'port' => (
    is          => 'rw',
    isa         => 'Int');

=item B<debug>

Turn on debug. Turned off by default.

=cut
has 'debug' => (
    is          => 'rw',
    isa         => 'Bool',
    default     => 0);

=back

=head1 Methods

=head2 B<run($hosts, $command, %options)>

Runs the HTTP request (C<$command>) to the given foca servers (C<$hosts>).
C<$hosts> should be an array reference, use FQDN.

By default the method returns an array of hashes. Each hash having the following
keys:

=over 4

=item B<ok> Boolean. True if command went well or false otherwise.

=item B<output> output of the command

=item B<hostname> Hostname.

=back

In addition the method offers a third parameter, C<%options> that can be used to
tie the collection of data of each host and send it to a subroutine. Options are:

=over 4

=item B<on_good> A CODE reference. Called on every host that succeeded.

=item B<on_bad> A CODE reference. Called on every host that failed

=item B<on_host> A CODE reference. Called on every host, succeeded or not.

=back

Each one of the CODE references will get one argument: the hash described before.

Command should be the full command, just as if you were executing it from your
shell (for example: I<uptime> or I<uptime -V>). This method will take care of
getting the basename of the command you are calling and look for any extra
parameters/arguments, if any parameters/arguments are found then they get
sent as a HTTP header, header would be I<Foca-Cmd-Params>.

=cut
sub run {
    my ($self, $hosts, $command, $options) = @_;

    # Some basic verification
    log_die("No hosts were given") unless $hosts;
    log_die("Hosts are not an array ref") unless (ref $hosts eq 'ARRAY');
    log_die("No command was given") unless $command;
    
    # Ok, get the command args and params
    my ($foca_cmd, $foca_args) = ($command, '');
    if ($command =~ /(.+?)\s+(.+?)$/) {
        ($foca_cmd, $foca_args) = ($1, $2);
    }

    $options = {} unless $options;
    $options->{'on_good'} = '' unless $options->{'on_good'};
    $options->{'on_bad'}  = '' unless $options->{'on_bad'};
    $options->{'on_host'} = '' unless $options->{'on_host'};

    my @results = ();
    my $pm = new Parallel::ForkManager($self->{'maxflight'});
    $pm->run_on_finish(
            sub {
                my ($pid, $exit_code, $id, $exit, $core, $data) = @_;
                
                my $item;
                if ($data->{'got_response'}) {
                    my $response = $data->{'response'};
                    if ($response->is_success) {
                        my $data = $response->decoded_content;
                        chomp($data);
                        $item = {
                            'hostname'  => $id,
                            'ok'        => 1,
                            'output'    => $data};
                        $options->{'on_good'}->($item) if
                            ref $options->{'on_good'} eq 'CODE';
                    } else {
                        my $msg = $response->decoded_content || $response->status_line;
                        chomp($msg);
                        if ($msg eq "500 Can't connect to $id:12346 (connect: timeout)") {
                            $msg = "Connect timeout";
                        }
                        $item = {
                            'hostname'  => $id,
                            'ok'        => 0,
                            'output'    => $msg};
                        $options->{'on_bad'}->($item) if
                            ref $options->{'on_bad'} eq 'CODE';
                    }
                } else {
                    $item = {
                        'hostname'      => $id,
                        'ok'            => 0,
                        'output'        => $data->{'reason'}};
                }
                push(@results, $item);
                $options->{'on_host'}->($item) if
                    ref $options->{'on_host'} eq 'CODE';
            });

    foreach my $host (@{$hosts}) {
        $pm->start($host) and next;

        my $url = 'http://' . $host . ':' . $self->{'port'} . '/foca/' . $foca_cmd;

        my ($response_body, $response_headers) = ('', '');

        open(my $response_body_fh, ">", \$response_body);
        open(my $response_headers_fh, ">", \$response_headers);

        my @headers = ();
        push(@headers, 'Foca-Cmd-Params:' . $foca_args) if $foca_args;
        
        my $curl = new WWW::Curl::Easy;
        $curl->setopt(CURLOPT_VERBOSE, $self->{'debug'});
        $curl->setopt(CURLOPT_HEADER, 0);
        $curl->setopt(CURLOPT_URL, $url);
        $curl->setopt(CURLOPT_WRITEDATA, $response_body_fh);
        $curl->setopt(CURLOPT_WRITEHEADER, $response_headers_fh);
        $curl->setopt(CURLOPT_TIMEOUT, $self->{'timeout'});
        $curl->setopt(CURLOPT_CONNECTTIMEOUT, $self->{'connect_timeout'});
        $curl->setopt(CURLOPT_HTTPHEADER, \@headers);

        log_debug("$host - Requesting $url");

        my $retcode = $curl->perform;
        my $data    = {};
        if ($retcode == 0) {
             my $full_response = $response_headers;
             $full_response .= $response_body if $response_body;
             my $response = HTTP::Response->parse($full_response);
             $pm->finish(1, {
                     'got_response' => 1,
                     'response'     => $response});
        } else {
            $pm->finish(1, {
                    'got_response'  => 0,
                    'reason'        => $curl->strerror($retcode)});
        }
    }
    $pm->wait_all_children;
    return @results;
}

###################### PRIVATE/PROTECTED METHODS ##########################
sub BUILD {
    my ($self) = @_;

    init_logger();
    use_debug(1) if $self->{'debug'};
    
    $self->port(6666) unless defined $self->{'port'};
}

=head1 COPYRIGHT

Copyright (c) 2010-2012 Yahoo! Inc. All rights reserved.

=head1 LICENSE

This program is free software. You may copy or redistribute it under
the same terms as Perl itself. Please see the LICENSE file included
with this project for the terms of the Artistic License under which 
this project is licensed.

=head1 AUTHORS

Pablo Fischer (pablo@pablo.com.mx)

=cut
1;

