package AnyEvent::Radius::Server;
# AnyEvent-based radius server
use strict;
use warnings;
use AnyEvent;
use AnyEvent::Handle::UDP;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(handler packer));

use Data::Radius v1.2.8;
use Data::Radius::Constants qw(:all);
use Data::Radius::Dictionary ();
use Data::Radius::Packet ();

use constant {
    READ_TIMEOUT_SEC => 5,
    WRITE_TIMEOUT_SEC => 5,
    RADIUS_PORT => 1812,
};

my %DEFAUL_REPLY = (
    &ACCESS_REQUEST => ACCESS_REJECT,
    &ACCOUNTING_REQUEST => ACCOUNTING_RESPONSE,
    &DISCONNECT_REQUEST => DISCONNECT_REJECT,
    &COA_REQUEST => COA_REJECT,
);

# new 'server'
# args:
#   ip
#   port
#   secret
#   dictionary
#- callbacks:
#    on_read
#    on_read_raw
#    on_wrong_request
#    on_error
sub new {
    my ($class, %h) = @_;

    die "No IP argument" if (! $h{ip});
    # either pre-created packer obect, or need radius secret to create new one
    # dictionary is optional
    die "No radius secret" if (! $h{packer} && ! $h{secret});

    my $obj = bless {}, $class;

    my $on_read_cb = sub {
        my ($data, $handle, $from) = @_;

        if ($h{on_read_raw}) {
            # dump raw data
            $h{on_read_raw}->($obj, $data, $from);
        }

        # how to decoded $from
        # my($port, $host) = AnyEvent::Socket::unpack_sockaddr($from);
        # my $ip = format_ipv4($host);

        my ($type, $req_id, $authenticator, $av_list) = $obj->packer()->parse($data);

        if (! $obj->packer()->is_request($type)) {
            # we expect only requests in server
            if ($h{on_wrong_request}) {
                 $h{on_wrong_request}->($obj, {
                            type => $type,
                            request_id => $req_id,
                            av_list => $av_list,
                            # from is sockaddr binary data
                            from => $from,
                        });
            }

            # Do not reply
            warn "Ignore wrong request type " . $type;
            return
        }

        my ($reply_type, $reply_av_list) = ();

        if($h{on_read}) {
            # custom-reply
            ($reply_type, $reply_av_list) = $h{on_read}->($obj, {
                        type => $type,
                        request_id => $req_id,
                        av_list => $av_list,
                        # from is sockaddr binary data
                        from => $from,
                    });
        }

        if (! $reply_type) {
            # reject by default
            $reply_type = $DEFAUL_REPLY{ $type };
            $reply_av_list = [{Name => 'Reply-Message', Value => 'Default rule: reject'}];
        }

        my ($reply, $r_id, $r_auth) = $obj->packer()->build(
                                type => $reply_type,
                                av_list => $reply_av_list,
                                authenticator => $authenticator,
                                request_id => $req_id,
                            );
        if(! $reply) {
            warn "Failed to build reply";
            return
        }

        $obj->handler()->push_send($reply, $from);

        return;
    };

    # low-level socket errors
    my $on_error_cb = sub {
        my ($handle, $fatal, $error) = @_;
        if ($h{on_error}) {
            $h{on_error}->($obj, $error);
        }
        else {
            warn "Error occured: $error";
        }
    };

    my $server = AnyEvent::Handle::UDP->new(
            bind => [$h{ip}, $h{port} // RADIUS_PORT ],
            on_recv => $on_read_cb,
            on_error => $on_error_cb,
        );
    $obj->handler($server);

    # allow to pass custom object
    my $packer = $h{packer} || Data::Radius::Packet->new(dict => $h{dictionary}, secret => $h{secret});
    $obj->packer($packer);

    return $obj;
}

sub load_dictionary {
    my ($class, $path) = @_;
    my $dict = Data::Radius::Dictionary->load_file($path);

    if(ref($class)) {
        $class->packer()->dict($dict);
    }

    return $dict;
}

1;

__END__

=head1 NAME

AnyEvent::Radius::Server - module to implement AnyEvent based RADIUS server

=head1 SYNOPSYS

    use AnyEvent;
    use AnyEvent::Radius::Server;

    sub radius_reply {
        # $h is hash-ref { request_id, type, av_list }
        my ($self, $h) = @_;
        ...
        return ($reply_type, $reply_av_list);
    }

    my $dict = AnyEvent::Radius::Server->load_dictionary('radius/dictionary');

    my $server = AnyEvent::Radius::Server->new(
                    ip => $ip,
                    port => $port,
                    read_timeout => 60,
                    on_read => \&radius_reply,
                    dictionary => $dict,
                    secret => 'topsecret',
                );
    AnyEvent->condvar->recv;

=head1 DESCRIPTION

The L<AnyEvent::Radius::Server> module allows to handle RADIUS requests in non-blocking way


=head1 CONSTRUCTOR

=over

=item new (...options hash ...)

=over

=item ip - listen on ip, mandatory

=item port - listen on port (default 1812)

=item secret - RADIUS secret string

=item dictionary - optional, dictionary loaded by L<load_dictionary()> method

=item on_read - called with parsed packed, in hash-ref {type, request_id, av_list, from}

=item on_read_raw - called with raw binary packet as an argument

=item on_wrong_request - received packet is not of request type (no reply sent)

=item on_error - low-lever socket error occured

=back

=back

=head1 METHODS

=over

=item load_dictionary ($dictionary-file)

Class method to load dictionary - returns the object to be passed to constructor

=back

=head1 SEE ALSO

L<AnyEvent::Radius::Client>

=head1 AUTHOR

Sergey Leschenko <sergle.ua at gmail.com>

PortaOne Development Team <perl-radius at portaone.com> is the current module's maintainer at CPAN.

=cut
