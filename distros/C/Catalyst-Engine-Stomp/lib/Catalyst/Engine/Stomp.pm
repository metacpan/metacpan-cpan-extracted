package Catalyst::Engine::Stomp;
use Moose;
use List::MoreUtils qw/ uniq /;
use HTTP::Request;
use Net::Stomp;
use MooseX::Types::Moose qw/Str Int HashRef/;
use namespace::autoclean;
use Encode;

extends 'Catalyst::Engine::Embeddable';

our $VERSION = '0.17';

has connection => (is => 'rw', isa => 'Net::Stomp');
has conn_desc => (is => 'rw', isa => Str);
has destination_namespace_map => (is => 'rw', isa => HashRef, default => sub { { } } );

=head1 NAME

Catalyst::Engine::Stomp - write message handling apps with Catalyst.

=head1 SYNOPSIS

  # In a server script:

  BEGIN {
    $ENV{CATALYST_ENGINE} = 'Stomp';
    require Catalyst::Engine::Stomp;
  }

  MyApp->config(
    Engine::Stomp' = {
       tries_per_server => 3,
      'servers' => [
       {
         'hostname' => 'localhost',
         'port' => '61613'
         connect_headers => {
           login => 'myuser',
           passcode => 'mypassword',
         },
       },
       {
         'hostname' => 'stomp.yourmachine.com',
         'port' => '61613'
       },
       ],
       utf8             => 1,
       subscribe_headers => {
         transformation       => 'jms-to-json',
       }
    },
  );
  MyApp->run();

  # In a controller, or controller base class:
  use base qw/ Catalyst::Controller::MessageDriven /;

  # then create actions, which map as message types
  sub testaction : Local {
      my ($self, $c) = @_;

      # Reply with a minimal response message
      my $response = { type => 'testaction_response' };
      $c->stash->{response} = $response;
  }

=head1 DESCRIPTION

Write a Catalyst app connected to a Stomp messagebroker, not HTTP. You
need a controller that understands messaging, as well as this engine.

This is single-threaded and single process - you need to run multiple
instances of this engine to get concurrency, and configure your broker
to load-balance across multiple consumers of the same queue.

Controllers are mapped to Stomp queues or topics, and a controller
base class is provided, Catalyst::Controller::MessageDriven, which
implements YAML-serialized messages, mapping a top-level YAML "type"
key to the action.

=head1 QUEUES and TOPICS

The controller namespace (either derived from its name, or defined by
its C<action_namespace> attribute) defines what the controller is
subscribed to:

=over 4

=item C<queue/foo>

subscribes to the queue called C<foo>

=item C<topic/foo>

subscribes to the topic called C<foo>

=item C<foo>

subscribes to the queue called C<foo> (for simplicity and backward
compatibility)

=back

=head2 Connction and Subscription Headers

You can specify custom headers to send with the C<CONNECT> and
C<SUBSCRIBE> STOMP messages. You can specify them globally:

  MyApp->config(
    Engine::Stomp' = {
      'servers' => [
       {
         'hostname' => 'localhost',
         'port' => '61613'
       },
       ],
       subscribe_headers => {
         transformation       => 'jms-to-json',
       },
       connect_headers => {
         login => 'myuser',
         passcode => 'mypassword',
       },
    },
  );

per server:

  MyApp->config(
    Engine::Stomp' = {
      'servers' => [
       {
         'hostname' => 'localhost',
         'port' => '61613'
         subscribe_headers => {
           strange_stuff => 'something',
         },
         connect_headers => {
           login => 'myuser',
           passcode => 'mypassword',
         },
       },
       ],
    },
  );

or per-controller (subscribe headers only):

  package MyApp::Controller::Special;
  use Moose;
  BEGIN { extends 'Catalyst::Controller::MessageDriven' };

  has stomp_destination => (
    is => 'ro',
    isa => 'Str',
    default => '/topic/crowded',
  );

  has stomp_subscribe_headers => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{
        selector => q{custom_header = '1' or JMSType = 'test_foo'},
    } },
  );

This is very useful to set filters / selectors on the subscription.

There are a few caveats, mostly summarized by "if you do confusing
things, the program may not work".

=over 4

=item *

you can have the C<stomp_destination> and the C<action_namespace>
different in a single controller, but this may become confusing if you
have more than one controller subscribed to the same destination; you
can remove some of the confusion by restricting the kind of messages
that each subscription receives

=item *

if you filter out some messages, don't be surprised if they are never
received by your application

=item *

you can set persistent topic subscriptions, to prevent message loss
during reconnects (the broker will remember your subscription and keep
the messages while you are not connected):

  MyApp->config(
    Engine::Stomp' = {
      'servers' => [
       {
         'hostname' => 'localhost',
         'port' => '61613'
       },
       ],
       connect_headers => {
         'client-id' => 'myapp',
       },
    },
  );

  package MyApp::Controller::Persistent;
  use Moose;
  BEGIN { extends 'Catalyst::Controller::MessageDriven' };

  has stomp_destination => (
    is => 'ro',
    isa => 'Str',
    default => '/topic/important',
  );

  has stomp_subscribe_headers => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{
      'activemq.subscriptionName' => 'important-subscription',
    } },
  );

According to the ActiveMQ docs, the C<client-id> must be globally
unique, and C<activemq.subscriptionName> must be unique within the
client. Non-ActiveMQ brokers may use different headers to specify the
subscription name.

=back

=head1 FAILOVER

You can specify one or more servers in a list for the apps config.
This enables fail over if an error occurs, like the broker or network
connection disappears.

It will try to use a server a set number of times, as determined by
tries_per_server in the config before failing on to the next server
in the list. It cycle through each server in turn, going back to the
start of the list if need be.

=head1 UTF-8

By default STOMP messages are assumed to be in UTF-8. This module can
automatically convert a Perl string into a UTF-8 set of octets to be
sent over the wire instead. This is a Good Thing, especially if you 
use the function Load() from the package YAML::XS to un-serialize
it in your client - it assumes it is in UTF-8.

If you do want this behaviour, set 'utf8' to '1' in your config.

=head1 Simplified configuration

Instead of using the complete config layout as shown in the synopsis,
you can

=over 4

=item *

not specify a C<tries_per_server> (defaults to 1)

=item *

specify a single server:

  server => { hostname => $host, port => $port }

=item *

use the old-style (pre 0.14) config having C<hostname> and C<port>
directly in the C<Engine::Stomp> block, without a C<server> key in
between.

=back

=cut

=head1 METHODS

=head2 _see_ya

Set to run when signal USR1 is received. Simply sets the stop flag.

=cut

my $stop = 0;

sub _see_ya {
    $stop = 1;
    delete $SIG{'USR1'};
}


=head2 run

App entry point. Starts a loop listening for messages.

If the stop flag is set (see _see_ya above) then no more requests are processed.
Keep in mind this is a blocking server and it will wait for a STOMP message forever.
Only after handling a request does it check the flag.

=cut

sub _qualify_destination {
    my ($self,$unq_dest) = @_;

    my $q_dest = $unq_dest;
    if ($unq_dest !~ m{^ /? (?: queue | topic ) / }x) {
        $q_dest = "/queue/$unq_dest";
    }

    # normalize slashes
    $unq_dest =~ s{^/}{};
    $q_dest =~ s{/+}{/};
    $q_dest = "/$q_dest" unless $q_dest =~ m{^/};

    return ($unq_dest,$q_dest);
}

sub _collect_destinations {
    my ($self,$app) = @_;

    my $sub_id=1;

    my @dests;
    for my $ctrl_name ($app->controllers) {
        my $ctrl = $app->controller($ctrl_name);
        my $dest_call = $ctrl->can('stomp_destination');
        my $subh_call = $ctrl->can('stomp_subscribe_headers');
        my ($unq_dest,$q_dest,$subh);
        $unq_dest = $dest_call ? $ctrl->$dest_call() : $ctrl->action_namespace();
        ($unq_dest,$q_dest) = $self->_qualify_destination($unq_dest);
        $subh = $subh_call ? $ctrl->$subh_call() : { };

        push @dests,{
            destination => $q_dest,
            subscribe_headers => {
                %$subh,
                id => $sub_id,
            }
        };

        $self->destination_namespace_map->{$q_dest} =
        $self->destination_namespace_map->{"/subscription/$sub_id"} =
            $ctrl->action_namespace();
        ++$sub_id;
    }

    return @dests;
}

sub run {
    my ($self, $app, $oneshot) = @_;

    $SIG{'USR1'} = \&_see_ya;

    die 'No Engine::Stomp configuration found'
        unless ref $app->config->{'Engine::Stomp'} eq 'HASH';

    my @destinations = $self->_collect_destinations($app);

    # connect up
    my $config = $app->config->{'Engine::Stomp'};
    my $index  = 0;

    # munge the configuration to make it easier to write
    $config->{tries_per_server} ||= 1;
    $config->{connect_retry_delay} ||= 15;
    for my $h (qw(connect subscribe)) {
        $config->{"${h}_headers"} ||= {};
        die("${h}_headers config for Engine::Stomp must be a hashref!\n")
            if (ref($config->{"${h}_headers"}) ne 'HASH');
    }

    if (! $config->{servers} ) {
        $config->{servers} = [ {
            hostname => (delete $config->{hostname}),
            port => (delete $config->{port}),
        } ];
    }
    elsif (ref $config->{servers} eq 'HASH') {
        $config->{servers} = [ $config->{servers} ];
    }

    QUITLOOP:
    while (1) {
        # Go to next server in list
        my %template = %{ $config->{servers}->[$index] };
        $config->{hostname} = $template{hostname};
        $config->{port}     = $template{port};

        ++$index;

        if ($index >= (scalar( @{$config->{servers}} ))) {
            $index = 0; # go back to first server in list
        }

        my $tries = 0;

        while ($tries < $config->{tries_per_server}) {
            ++$tries;

            eval {
                for my $h (qw(connect subscribe)) {
                    $template{"${h}_headers"} ||= {};
                    die("${h}_headers config for for server $config->{hostname}:$config->{port} in Engine::Stomp must be a hashref!\n")
                        if (ref($template{"${h}_headers"}) ne 'HASH');
                }

                my $per_server_connect_headers = {
                    %{$config->{connect_headers}},
                    %{$template{connect_headers}},
                };

                my $per_server_subscribe_headers = {
                    %{$config->{subscribe_headers}},
                    %{$template{subscribe_headers}},
                };

                $app->log->debug("Connecting to STOMP Q at " . $template{hostname}.':'.$template{port})
                    if $app->debug;

                $self->connection(Net::Stomp->new(\%template));
                $self->connection->connect($per_server_connect_headers);
                $self->conn_desc($template{hostname}.':'.$template{port});

                # subscribe, with client ack.
                foreach my $destination (@destinations) {
                    my $dest_name = $destination->{destination};
                    my $local_subscribe_headers =
                        $destination->{subscribe_headers};
                    my $id = $local_subscribe_headers->{id};
                    $app->log->debug(
                        "subscribing to $dest_name ($id) ".
                        'which is mapped to '.
                        $self->destination_namespace_map->{"/subscription/$id"}
                    )
                        if $app->debug;

                    $self->connection->subscribe({
                        %$per_server_subscribe_headers,
                        %$local_subscribe_headers,
                        destination => $dest_name,
                        ack         => 'client',
                    });
                }

                # Since we might block for some time, lets flush the log messages
                $app->log->_flush() if $app->log->can('_flush');

                # enter loop...
                while (1) {
                    my $frame = $self->connection->receive_frame(); # block
                    $self->handle_stomp_frame($app, $frame);

                    if ( $ENV{ENGINE_ONESHOT} || $stop ){
                        # Perl does not like 'last QUITLOOP' inside an eval, hence we die and do it
                        die "QUITLOOP\n";
                    }
                }
            };

            if (my $err=$@) {
                # although it looks like a lot of pointless flush()ing we need
                # to make sure the user(s) can see any new messages; we
                # sometimes die before we flush() in the loop above

                if ($err eq "QUITLOOP\n") {
                    last QUITLOOP;
                }
                else {
                    $app->log->error(" Problem dealing with STOMP : $err");
                    $app->log->_flush() if $app->log->can('_flush');
                }

                # don't loop continuously if we can't connect; take a break;
                # give the service a chance to come back
                if ($err =~ m{Connection refused}) {
                    $app->log->info(
                          'Unable to connect to '
                        . $template{hostname}.':'.$template{port}
                        . '; sleeping before next retry'
                    );
                    $app->log->_flush() if $app->log->can('_flush');
                    sleep $config->{connect_retry_delay};
                }
            }
        }
    }
}

=head2 prepare_request

Overridden to add the source broker to the request, in place of the
client IP address.

=cut

sub prepare_request {
    my ($self, $c, $req, $res_ref) = @_;
    shift @_;
    $self->next::method(@_);
    $c->req->address($self->conn_desc);
}

=head2 finalize_headers

Overridden to dump out any errors encountered, since you won't get a #'
"debugging" message as for HTTP.

=cut

sub finalize_headers {
    my ($self, $c) = @_;
    my $error = join "\n", @{$c->error};
    if ($error) {
        $c->log->debug($error);
    }
    return $self->next::method($c);
}

=head2 handle_stomp_frame

Dispatch according to Stomp frame type.

=cut

sub handle_stomp_frame {
    my ($self, $app, $frame) = @_;

    my $command = $frame->command();
    if ($command eq 'MESSAGE') {
        $self->handle_stomp_message($app, $frame);
    }
    elsif ($command eq 'ERROR') {
        $self->handle_stomp_error($app, $frame);
    }
    else {
        $app->log->debug("Got unknown Stomp command: $command");
    }
}

=head2 handle_stomp_message

Dispatch a Stomp message into the Catalyst app.

=cut

sub handle_stomp_message {
    my ($self, $app, $frame) = @_;

    # destination -> controller
    my $destination = $frame->headers->{destination};
    my $subscription = $frame->headers->{subscription};

    $app->log->debug("message from $destination ($subscription)")
        if $app->debug;

    my $controller = $self->destination_namespace_map->{"/subscription/$subscription"}
        || $self->destination_namespace_map->{$destination};

    # set up request
    my $config = $app->config->{'Engine::Stomp'};
    my $url = 'stomp://'.$config->{hostname}.':'.$config->{port}.'/'.$controller;
    my $request_headers = HTTP::Headers->new(%{$frame->headers});
    my $req = HTTP::Request->new(POST => $url, $request_headers);
    $req->content($frame->body);
    $req->content_length(length $frame->body);

    # dispatch
    my $response;
    $app->handle_request($req, \$response);

    # reply, if header set
    if (my $reply_to = $response->headers->header('X-Reply-Address')) {
        my $reply_queue = '/remote-temp-queue/' . $reply_to;
        my $content     = $response->content;

        if ($config->{utf8}) {
            $content = encode("utf8", $response->content); # create octets
        }

        my $reply_headers = $response->headers->clone;
        $reply_headers->remove_content_headers;
        my %reply_hh =
            map {
                lc($_), scalar($reply_headers->header($_)),
            }
            grep { !/^X-/i }
            $reply_headers->header_field_names();

        $self->connection->send({
            %reply_hh,
            destination => $reply_queue,
            body => $content
        });
    }

    # ack the message off the destination now we've replied / processed
    $self->connection->ack( { frame => $frame } );
}

=head2 handle_stomp_error

Log any Stomp error frames we receive.

=cut

sub handle_stomp_error {
    my ($self, $app, $frame) = @_;

    my $error = $frame->headers->{message};
    $app->log->debug("Got Stomp error: $error");
}

__PACKAGE__->meta->make_immutable;

=head1 CONFIGURATION

=head2 subscribe_header

Add additional header key/value pairs to the subscribe message sent to the
message broker.

=cut

=head1 DEVELOPMENT

The source to Catalyst::Engine::Stomp is in github:

  http://github.com/pmooney/catalyst-engine-stomp

=head1 AUTHOR

Chris Andrews C<< <chris@nodnol.org> >>

=head1 CONTRIBUTORS

Tomas Doran (t0m) C<< <bobtfish@bobtfish.net> >>

Jason Tang

Paul Mooney

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2009 Venda Ltd

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

