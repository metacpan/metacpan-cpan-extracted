package Clutch::Client;
use strict;
use warnings;
use Clutch::Utils;
use IO::Select;
use Carp ();

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    Carp::croak "Mandatory parameter 'servers'" unless $args{servers};

    my $rr = delete $args{rr} || 'Clutch::Client::RR';

    bless {
        servers => undef,
        timeout => 10,
        rr      => $rr->new($args{servers}),
        %args,
    }, $class;
}

sub request_background {
    my ($self, $function, $args) = @_;
    $self->_request('request_background', $function, $args);
}

sub request {
    my ($self, $function, $args) = @_;
    $self->_request('request', $function, $args);
}

sub _request {
    my ($self, $cmd_name, $function, $args) = @_;

    my $server = $self->{rr}->next;
    my $sock = Clutch::Utils::new_client($server);

    my $msg = Clutch::Utils::make_request($cmd_name, $function, $args);
    Clutch::Utils::write_all($sock, $msg, $self->{timeout}, $self);

    my $buf='';
    while (1) {
        my $rlen = Clutch::Utils::read_timeout(
            $sock, \$buf, $MAX_REQUEST_SIZE - length($buf), length($buf), $self->{timeout}, $self
        ) or return;

        Clutch::Utils::verify_buffer($buf) and last;
    }
    $sock->close();
    return $buf ? Clutch::Utils::json->decode($buf) : undef;
}

sub request_multi {
    my ($self, $args) = @_;
    $self->_verify_multi_args($args);
    $self->_request_multi('request', $args);
}

sub request_background_multi {
    my ($self, $args) = @_;
    $self->_verify_multi_args($args);
    $self->_request_multi('request_background', $args);
}

sub _verify_multi_args {
    my ($self, $args) = @_;

    for my $arg (@$args) {
        if ($arg->{function} eq '') {
            Carp::croak "there is no function to the argument of multi_request";
        }
    }
}

sub _request_multi {
    my ($self, $cmd_name, $args) = @_;

    my $request_count = scalar(@$args);
    my $is = IO::Select->new;

    my %sockets_map;
    for my $i (0 .. ($request_count - 1)) {
        my $server = $self->{rr}->next;
        my $sock = Clutch::Utils::new_client($server);
        $is->add($sock);
        $sockets_map{$sock}=$i;

        my $msg = Clutch::Utils::make_request($cmd_name, $args->[$i]->{function}, ($args->[$i]->{args}||''));
        Clutch::Utils::write_all($sock, $msg, $self->{timeout}, $self);
    }

    my @res;
    while ($request_count) {
        if (my @ready = $is->can_read($self->{timeout})) {
            for my $sock (@ready) {
                my $buf='';
                while (1) {
                    my $rlen = Clutch::Utils::read_timeout(
                        $sock, \$buf, $MAX_REQUEST_SIZE - length($buf), length($buf), $self->{timeout}, $self
                    ) or return;

                    Clutch::Utils::verify_buffer($buf) and last;
                }
                my $idx = $sockets_map{$sock};

                $request_count--;
                $is->remove($sock);
                $sock->close();

                $res[$idx] = $buf ? Clutch::Utils::json->decode($buf) : undef;
            }
        }
    }
    wantarray ? @res : \@res;
}

package
 Clutch::Client::RR;

sub new {
    my ($class, $servers) = @_;
    bless +{
        servers => $servers,
    }, $class;
} 

sub next {
    my $self = shift;
    push(@{$self->{servers}}, shift(@{$self->{servers}}));
    $self->{servers}[0];
}

1;

__END__

=head1 NAME

Clutch::Client - distributed job system's client class

=head1 SYNOPSIS

    # client script
    use strict;
    use warnings;
    use Clutch::Client;
    my $args = shift || die 'missing args';
    my $client = Clutch::Client->new(
        servers => [ "$worker_ip:$worker_port" ],
    );
    my $res = $client->request('echo', $args);
    print $res, "\n";

=head1 METHOD

=head2 my $client = Clutch::Client->new(%opts);

=over

=item $opts{servers}

The value is a reference to an array of worker addresses.

The server address is in the form host:port for network TCP connections

Client will distribute basic RoundRobin.

=item $opts{timeout}

seconds until timeout (default: 10)

=back

=head2 my $res = $client->request($function_name, $args);

=over

=item $function_name

worker process function name.

=item $args

get over client argument for worker process.

$args must be single line data.

=back

=head2 my $res = $client->request_background($function_name, $args);

=over

=item $function_name

worker process function name.

=item $args

get over client argument for worker process.

$args must be single line data.

=item $res

When the worker accepts the background request and returns the "OK"

=back

=head2 my $res = $client->request_multi(\@args);

=over

=item $args->[$i]->{function}

worker process function name.

=item $args->[$i]->{args}

get over client argument for worker process.

$args must be single line data.

=item $res

worker response here.
The result is order request.

=back

=head2 my $res = $client->request_background_multi(\@args);

=over

=item $args->[$i]->{function}

worker process function name.

=item $args->[$i]->{args}

get over client argument for worker process.

$args must be single line data.

=item $res

worker response here.
The result is order request.

=back

=cut

