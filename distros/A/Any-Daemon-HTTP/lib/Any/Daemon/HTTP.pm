# Copyrights 2013-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Any-Daemon-HTTP. Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Any::Daemon::HTTP;
use vars '$VERSION';
$VERSION = '0.29';


use Log::Report      'any-daemon-http';
use parent 'Any::Daemon';

use warnings;
use strict;

use Any::Daemon::HTTP::VirtualHost ();
use Any::Daemon::HTTP::Session     ();
use Any::Daemon::HTTP::Proxy       ();

use HTTP::Daemon     ();
use HTTP::Status     qw/:constants :is/;
use Socket           qw/inet_aton PF_INET AF_INET/;
use IO::Socket       qw/SOCK_STREAM SOMAXCONN SOL_SOCKET SO_LINGER/;
use IO::Socket::IP   ();
use IO::Select       ();
use File::Basename   qw/basename/;
use File::Spec       ();
use Scalar::Util     qw/blessed/;
use Errno            qw/EADDRINUSE/;

use constant   # default ports
  { PORT_HTTP  => 80
  , PORT_HTTPS => 443
  };

# To support IPv6, replace ::INET by ::IP
@HTTP::Daemon::ClientConn::ISA = qw(IO::Socket::IP);


sub _to_list($) { ref $_[0] eq 'ARRAY' ? @{$_[0]} : defined $_[0] ? $_[0] : () }

sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    my $listen = $args->{listen} || $args->{socket} || $args->{host};
    my (@sockets, @hosts);
    foreach my $conn (_to_list $listen)
    {   my ($socket, @host) = $self->_create_socket($conn
          , protocol => $args->{protocol}
          );

        push @sockets, $socket if $socket;
        push @hosts, @host;
    }

    @sockets or error __x"host or socket required for {pkg}::new()"
      , pkg => ref $self;

    $self->{ADH_sockets} = \@sockets;
    $self->{ADH_hosts}   = \@hosts;

    $self->{ADH_session_class}
      = $args->{session_class} || 'Any::Daemon::HTTP::Session';
    $self->{ADH_vhost_class}
      = $args->{vhost_class}   || 'Any::Daemon::HTTP::VirtualHost';
    $self->{ADH_proxy_class}
      = $args->{proxy_class}   || 'Any::Daemon::HTTP::Proxy';

    $self->{ADH_vhosts}  = {};
    $self->addVirtualHost($_) for _to_list($args->{vhosts}  || $args->{vhost});

    $self->{ADH_proxies} = [];
    $self->addProxy($_)       for _to_list($args->{proxies} || $args->{proxy});

    !$args->{docroot}
        or error __x"docroot parameter has been removed in v0.11";

    $self->{ADH_server}  = $args->{server_id} || basename($0);
    $self->{ADH_headers} = $args->{standard_headers} || [];
    $self->{ADH_error}   = $args->{on_error}  || sub { $_[1] };
    $self->{ADH_show_ps} = exists $args->{show_in_ps} ? $args->{show_in_ps} : 1;

    # "handlers" is probably a common typo
    my $handler = $args->{handlers} || $args->{handler};

    my $host      = shift @hosts;
    $self->addVirtualHost
      ( name      => $host
      , aliases   => [@hosts, 'default']
      , documents => $args->{documents}
      , handler   => $handler
      ) if $args->{documents} || $handler;

    $self;
}

sub _create_socket($%)
{   my ($self, $listen, %args) = @_;
    defined $listen or return;

    return ($listen, $listen->sockhost.':'.$listen->sockport)
        if blessed $listen && $listen->isa('IO::Socket');

    my $port  = $listen =~ s/\:([0-9]+)$// ? $1 : PORT_HTTP;
    my $host  = $listen;
    my $proto = $self->{ADH_protocol}
      = $args{protocol} || ($port==PORT_HTTPS ? 'HTTPS' : 'HTTP');

    my $sock_class;
    if($proto eq 'HTTPS')
    {   $sock_class = 'IO::Socket::SSL';
        eval "require IO::Socket::SSL; require HTTP::Daemon::SSL" or panic $@;
    }
    elsif($proto eq 'HTTP')
    {   $sock_class = 'IO::Socket::IP';
    }
    elsif($proto eq 'FCGI')
    {   $sock_class = 'IO::Socket::IP';
        eval "require Any::Daemon::FCGI" or panic $@;
    }
    else
    {   error __x"Unsupported protocol '{proto}'", proto => $proto;
    }

    # Wait max 60 seconds to get the socket
    # You should be able to reduce the time to wait by setting linger
    # on the socket in the process which has opened the socket before.
    my ($socket, $elapse);
    foreach my $retry (1..60)
    {   $elapse = $retry -1;

        $socket = $sock_class->new
          ( LocalHost => $host
          , LocalPort => $port
          , Listen    => SOMAXCONN
          , Reuse     => 1
          , Type      => SOCK_STREAM
          , Proto     => 'tcp'
          );

        last if $socket || $! != EADDRINUSE;

        notice __x"waiting for socket at {address} to become available"
          , address => "$host:$port"
            if $retry==1;

        sleep 1;
    }

    $socket
        or fault __x"cannot create socket at {address}"
             , address => "$host:$port";

    notice __x"got socket after {secs} seconds", secs => $elapse
        if $elapse;

    ($socket, "$listen:$port", $socket->sockhost.':'.$socket->sockport);
}

#----------------

sub sockets()  { @{shift->{ADH_sockets}} }
sub hosts()    { @{shift->{ADH_hosts}} }
sub protocol() { shift->{ADH_protocol} }

#-------------

sub addVirtualHost(@)
{   my $self   = shift;
    my $config = @_ > 1 ? +{@_} : !defined $_[0] ? return : shift;

    my $vhost;
    if(blessed $config && $config->isa('Any::Daemon::HTTP::VirtualHost'))
         { $vhost = $config }
    elsif(ref $config eq 'HASH')
         { $vhost = $self->{ADH_vhost_class}->new($config) }
    else { error __x"virtual host configuration not a valid object nor HASH" }

    info __x"adding virtual host {name}", name => $vhost->name;

    $self->{ADH_vhosts}{$_} = $vhost
        for $vhost->name, $vhost->aliases;

    $vhost;
}


sub addProxy(@)
{   my $self   = shift;
    my $config = @_ > 1 ? +{@_} : !defined $_[0] ? return : shift;
    my $proxy;
    if(UNIVERSAL::isa($config, 'Any::Daemon::HTTP::Proxy'))
         { $proxy = $config }
    elsif(UNIVERSAL::isa($config, 'HASH'))
         { $proxy = $self->{ADH_proxy_class}->new($config) }
    else { error __x"proxy configuration not a valid object nor HASH" }

    $proxy->forwardMap
        or error __x"proxy {name} has no map, so needs inside vhost"
             , name => $proxy->name;

    info __x"adding proxy {name}", name => $proxy->name;

    push @{$self->{ADH_proxies}}, $proxy;
}


sub removeVirtualHost($)
{   my ($self, $id) = @_;
    my $vhost = blessed $id && $id->isa('Any::Daemon::HTTP::VirtualHost')
       ? $id : $self->virtualHost($id);
    defined $vhost or return;

    delete $self->{ADH_vhosts}{$_}
        for $vhost->name, $vhost->aliases;
    $vhost;
}


sub virtualHost($) { $_[0]->{ADH_vhosts}{$_[1]} }


sub proxies() { @{shift->{ADH_proxies}} }


sub findProxy($$$)
{   my ($self, $session, $req, $host) = @_;
    my $uri = $req->uri->abs("http://$host");
    foreach my $proxy ($self->proxies)
    {   my $mapped = $proxy->forwardRewrite($session, $req, $uri) or next;
        return ($proxy, $mapped);
    }

    ();
}

#-------------------

sub _connection($$)
{   my ($self, $client, $args) = @_;

    my $nr_req   = 0;
    my $max_req  = $args->{max_req_per_conn} ||= 100;
    my $start    = time;
    my $deadline = $start + ($args->{max_time_per_conn} ||= 120);
    my $bonus    = $args->{req_time_bonus} //= 2;

    my $conn;
    if($self->protocol eq 'FCGI')
    {   $args->{socket} = $client;
        $conn = Any::Daemon::FCGI::ClientConn->new($args);
    }
    else
    {   # Ugly hack, steal HTTP::Daemon's HTTP/1.1 implementation
        $conn = bless $client, $client->isa('IO::Socket::SSL')
          ? 'HTTP::Daemon::ClientConn::SSL'
          : 'HTTP::Daemon::ClientConn';

        ${*$conn}{httpd_daemon} = $self;
    }

    my $ip   = $client->peerhost;
    my $host =
      ( $client->sockdomain == PF_INET
      ? gethostbyaddr inet_aton($ip), AF_INET
      : undef
      ) || $ip;

    my $session = $self->{ADH_session_class}->new;
    $session->set(peer => { ip => $ip, host => $host });
    info __x"new client from {host} on {ip}" , host => $host, ip => $ip;

    my $init_conn = $args->{new_connection};
    $self->$init_conn($session);

    # Change title in ps-table
    my $title = $0 =~ /^(\S+)/ ? basename($1) : $0;
    $self->psTitle("$title http from $host");

    $SIG{ALRM} = sub {
        notice __x"connection from {host} lasted too long, killed after {time%d} seconds"
          , host => $host, time => $deadline - $start;
        exit 0;
    };

    alarm $deadline - time;
    while(my $req  = $conn->get_request)
    {   my $vhostn = $req->header('Host') || 'default';
		my $vhost  = $self->virtualHost($vhostn);

        # Fallback to vhost without specific port number
        $vhost ||= $self->virtualHost($1)
            if $vhostn =~ /(.*)\:[0-9]+$/;

        my $resp;
        if($vhost)
        {   $self->{ADH_host_base}
              = (ref($conn) =~ /SSL/ ? 'https' : 'http').'://'.$vhost->name;
            $resp = $vhost->handleRequest($self, $session, $req);
        }
        elsif(my ($proxy, $where) = $self->findProxy($session, $req, $vhostn))
        {   $resp = $proxy->forwardRequest($session, $req, $where);
        }
        elsif(my $default = $self->virtualHost('default'))
        {   $resp = HTTP::Response->new(HTTP_TEMPORARY_REDIRECT);
            $resp->header(Location => 'http://'.$default->name);
        }
        else
        {   $resp = HTTP::Response->new(HTTP_NOT_ACCEPTABLE,
               "virtual host $vhostn is not available");
        }

        unless($resp)
        {   notice __x"no response produced for {uri}", uri => $req->uri;
            $resp = HTTP::Response->new(HTTP_SERVICE_UNAVAILABLE);
        }

        $resp->push_header(@{$self->{ADH_headers}});
        $resp->request($req);

        # No content, then produce something better than an empty page.
        if(is_error($resp->code))
        {   $resp = $self->{ADH_error}->($self, $resp, $session, $req);
            $resp->content or $resp->content($resp->status_line);
        }
        $deadline += $bonus;
        alarm $deadline - time;

        my $close = $nr_req++ >= $max_req;

        $resp->header(Connection => ($close ? 'close' : 'open'));
        $conn->send_response($resp);

        last if $close;
    }

    alarm 0;
    $nr_req;
}

sub run(%)
{   my ($self, %args) = @_;

    my $new_child = $args{new_child} || 'newChild';
    $args{new_connection} ||= 'newConnection';

    my $vhosts = $self->{ADH_vhosts};
    unless(keys %$vhosts)
    {   my ($host, @aliases) = $self->hosts;
        $self->addVirtualHost(name => $host, aliases => ['default', @aliases]);
    }

    # option handle_request is deprecated in 0.11
    if(my $handler = delete $args{handle_request})
    {   my (undef, $first) = %$vhosts;
        $first->addHandler('/' => $handler);
    }

    my $title      = $0 =~ /^(\S+)/ ? basename($1) : $0;

    my ($req_count, $conn_count) = (0, 0);
    my $max_conn   = $args{max_conn_per_child} || 10_000;
    $max_conn      = int(0.9 * $max_conn + rand(0.2 * $max_conn))
        if $max_conn > 10;

    my $max_req    = $args{max_req_per_child}  || 100_000;
    my $linger     = $args{linger};

    $self->psTitle("$title manager\x00\x00");
    $args{child_task} ||= sub {
        $self->psTitle("$title not used yet");
        # even with one port, we still select...
        my $select = IO::Select->new($self->sockets);

        $self->$new_child($select);

      CONNECTION:
        while(my @ready = $select->can_read)
        {
            foreach my $socket (@ready)
            {   my $client = $socket->accept or next;
                $client->sockopt(SO_LINGER, (pack "II", 1, $linger))
                    if defined $linger;

                $self->psTitle("$title handling "
                   . $client->peerhost.":".$client->peerport . " at "
                   . $client->sockhost.':'.$client->sockport);

                $req_count += $self->_connection($client, \%args);
                $client->close;

                last CONNECTION
                    if $conn_count++ >= $max_conn
                    || $req_count    >= $max_req;
            }
            $self->psTitle("$title idle after $conn_count");
        }
        0;
    };

    info __x"start running the webserver";
    $self->SUPER::run(%args);
}


sub newConnection($)
{   my ($self, $session) = @_;
    return $self;
}


sub newChild($)
{   my ($self, $select) = @_;
    return $self;
}


sub psTitle($)
{   my ($self, $string) = @_;
    $0 = $string if $self->{ADH_show_ps};
}

# HTTP::Daemon methods used by ::ClientConn.  We steal that parent role,
# but need to mimic the object a little.  The names are not compatible
# with MarkOv's convention, so hidden for the users of this module
sub url() { shift->{ADH_host_base} }
sub product_tokens() {shift->{ADH_server}}

1;

__END__
