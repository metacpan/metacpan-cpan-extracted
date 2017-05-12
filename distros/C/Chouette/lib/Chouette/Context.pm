package Chouette::Context;

use common::sense;

use Plack::Request::WithEncoding;
use Plack::Response;
use Log::Defer;
use JSON::XS;
use Data::Dumper;


sub new {
    my ($class, %args) = @_;

    my $self = \%args;
    bless $self, $class;

    $self->{req} = Plack::Request::WithEncoding->new($self->{env});
    $self->{req}->env->{'plack.request.withencoding.encoding'} = 'utf-8';


    my $raw_logger = $self->{chouette}->{raw_logger};

    $self->{log_defer_obj} = Log::Defer->new({ cb => sub {
        my $msg = shift;

        my $encoded_msg = eval { encode_json($msg) };

        if ($@) {
            $encoded_msg = eval { encode_json(_json_clean($msg)) };

            if ($@) {
                $encoded_msg = "Failed to JSON clean: " . Dumper($msg);
            }
        }

        $raw_logger->log("$encoded_msg\n");
    }});

    return $self;
}


sub config { shift->{chouette}->{config} }
sub logger { shift->{log_defer_obj} }
sub req { shift->{req} }
sub res { die "Plack response object not yet supported" }
sub route_params { shift->{route_params} // {} }


sub respond_raw {
    my ($self, $http_code, $mime_type, $body) = @_;

    if (defined $self->{responder}) {
        $self->logger->info("HTTP response: $http_code (" . length($body) . " bytes of $mime_type)");
        $self->{responder}->([$http_code, ["Content-Type" => $mime_type], [$body]]);
        undef $self->{responder};
    } else {
        $self->logger->info("Not replying with $http_code because something else already replied.");
    }

    return $self->{chouette}->{_done_gensym};
}


sub DESTROY {
    my $self = shift;

    if (defined $self->{responder}) {
        $self->logger->error("no response was sent, sending 500");
        $self->respond({ error => 'internal server error' }, 500);
    }
}


sub respond {
    my ($self, $body, $http_code) = @_;

    if (defined $http_code && $http_code != 200 && ref($body) eq 'HASH' && exists $body->{error}) {
        $self->logger->warn("sending JSON error: $body->{error}");
    }

    return $self->respond_raw($http_code // 200, 'application/json', encode_json($body));
}



sub done {
    die shift->{chouette}->{_done_gensym};
}


sub generate_token {
    shift->{chouette}->generate_token();
}



sub task {
    my ($self, $task_name, %checkout_opts) = @_;

    return $self->{task_checkouts}->{$task_name} if $self->{task_checkouts}->{$task_name};

    my $client = $self->{chouette}->{task_clients}->{$task_name} // die "no such task: '$task_name'";
    my $checkout = $client->checkout(log_defer_object => $self->logger, %checkout_opts);

    $self->{task_checkouts}->{$task_name} = $checkout if $self->{chouette}->{task_checkout_caching}->{$task_name};

    return $checkout;
}





########


sub _json_clean {
    my $x = shift;

    if (ref $x) {
        if (ref $x eq 'ARRAY') {
            $x->[$_] = _json_clean($x->[$_]) for 0 .. @$x-1;
        } elsif (ref $x eq 'HASH') {
            $x->{$_} = _json_clean($x->{$_}) for keys %$x;
        } else {
            $x = "Unable to JSON encode: " . Dumper($x);
        }
    }

    return $x;
}



1;
