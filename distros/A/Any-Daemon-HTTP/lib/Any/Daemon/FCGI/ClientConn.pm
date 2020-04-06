# Copyrights 2013-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Any-Daemon-HTTP. Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Any::Daemon::FCGI::ClientConn;
use vars '$VERSION';
$VERSION = '0.30';


use warnings;
use strict;

use Log::Report      'any-daemon-http';

use HTTP::Request ();
use Time::HiRes   qw(usleep);
use Errno         qw(EAGAIN EINTR EWOULDBLOCK);
use IO::Select    ();
use Socket        qw/inet_aton PF_INET AF_INET SHUT_RD SHUT_WR/;

use Any::Daemon::FCGI::Request ();

use constant
  { FCGI_VERSION    => 1
  , FCGI_KEEP_CONN  => 1    # flag bit
  , MAX_FRAME_SEND  => 32 * 1024   # may have 65535 bytes content
  , MAX_READ_CHUNKS => 16 * 1024
  , CRLF            => "\x0D\x0A"
  , RESERVED        => 0
  };

# Implementation heavily based on Net::Async::FastCGI::Request and
# Mojo::Server::FastCGI

my %server_role_name2id =
  ( RESPONDER          => 1
  , AUTHORIZER         => 2
  , FILTER             => 3
  );

my %frame_name2id =
  ( BEGIN_REQUEST      => 1
  , ABORT_REQUEST      => 2
  , END_REQUEST        => 3
  , PARAMS             => 4
  , STDIN              => 5
  , STDOUT             => 6
  , STDERR             => 7
  , DATA               => 8
  , GET_VALUES         => 9
  , GET_VALUES_RESULT  => 10
  , UNKNOWN_TYPE       => 11
  );

my %end_status2id =
  ( REQUEST_COMPLETE   => 0
  , CANT_MPX_CONN      => 1
  , OVERLOADED         => 2
  , UNKNOWN_ROLE       => 3
  );

my %server_role_id2name = reverse %server_role_name2id;
my %frame_id2name       = reverse %frame_name2id;


sub new($%) { (bless {}, $_[0])->init($_[1]) }

sub init($)
{   my ($self, $args) = @_;
    $self->{ADFC_requests}  = {};
    $self->{ADFC_max_conns} = $args->{max_childs} or panic;
    $self->{ADFC_max_reqs}  = $args->{max_childs};

    $self->{ADFC_select}    = my $select = IO::Select->new;
    $self->{ADFC_socket}    = my $socket = $args->{socket} or panic;
    $self->{ADFC_stdin}     = \my $stdin;
    $self->{ADFC_keep_conn} = 0;
    $select->add($socket);

    $self;
}

#----------------

sub socket() { shift->{ADFC_socket} }

#----------------

sub _next_record()
{   my $self = shift;
    my $leader = $self->_read_chunk(8);
    length $leader==8 or return;

    my ($version, $type_id, $req_id, $clen, $plen) = unpack 'CCnnC', $leader;
    my $body = $self->_read_chunk($clen + $plen);

    substr $body, -$plen, $plen, '' if $plen;   # remove padding bytes
    length $body==$clen or return;

    ($frame_id2name{$type_id} || 'UNKNOWN_TYPE', $req_id, \$body);
}

sub _reply_record($$$)
{   my ($self, $type, $req_id, $body) = @_;
    my $type_id = $frame_name2id{$type} or panic $type;
    my $empty   = ! length $body;  # write one empty frame

    while(length $body || $empty)
    {   my $chunk  = substr $body, 0, MAX_FRAME_SEND, '';
        my $size   = length $chunk;
        my $pad    = (-$size) % 8;    # advise to pad on 8 bytes
        my $frame  = pack "CCnnCxa${size}x${pad}"
          , FCGI_VERSION, $type_id, $req_id, $size, $pad, $chunk;

        while(length $frame)
        {   my $wrote = syswrite $self->socket, $frame;
            if(defined $wrote)
            {   substr $frame, 0, $wrote, '';
                next;
            }

            return unless $! == EAGAIN || $! == EINTR || $! == EWOULDBLOCK;
            usleep 1000;  # 1 ms
        }

        last if $empty;
    }
}


sub get_request()
{   my $self = shift;
    my $requests = $self->{ADFC_requests};
    my $reqdata;

    ### At the moment, we will only support processing of whole requests
    #   and full replies: no chunking inside the server.

    while(1)
    {   my ($type, $req_id, $body) = $self->_next_record
            or return;

        if($req_id==0)
        {   $self->_management_record($body);
            next;
        }

        if($type eq 'BEGIN_REQUEST')
        {   my ($role_id, $flags) = unpack 'nC', $$body;
            my $role = $server_role_id2name{$role_id}
                or $self->_fcgi_end_request(UNKNOWN_ROLE => $req_id);

            $requests->{$req_id} =
              { request_id      => $req_id
              , data_complete   => $role ne 'FILTER'
              , stdin_complete  => $role eq 'AUTHORIZER'
              , params_complete => 0
              , role            => $role
              , params          => undef,
              , stdin           => undef,
              , data            => undef,
              };

            unless($flags & FCGI_KEEP_CONN)
            {   # Actually, this flag is incorrectly: more threads may still be
                # active.  So, let's close when they all have ceased to exist.
                info __x"fcgi {id} is last request", id => $req_id;
                $self->{ADFC_keep_conn} = 0;
            }

            next;
        }

        defined $req_id or panic;
        $reqdata = $requests->{$req_id};
        unless($reqdata)
        {   notice __x"fcgi received {type} for {id} which does not exist now"
              , type => $type, id => $req_id;
            next;
        }

        if($type eq 'ABORT_REQUEST')
        {   delete $requests->{$req_id};
        }
        elsif($type eq 'PARAMS')
        {   if(length $$body) { $reqdata->{params} .= $$body }
            else { $reqdata->{params_complete} = 1 }
        }
        elsif($type eq 'STDIN')  # Not for Authorizer
        {   if(length $$body) { $reqdata->{stdin}  .= $$body }
            else { $reqdata->{stdin_complete} = 1 }
        }
        elsif($type eq 'DATA')   # Filter only
        {   if(length $$body) { $reqdata->{data}   .= $$body }
            else { $reqdata->{data_complete} = 1 }
        }

        last if $reqdata->{params_complete}
             && $reqdata->{stdin_complete}
             && $reqdata->{data_complete};
    }

    # We still have this record in $reqdata
    my $req_id = $reqdata->{request_id};
    delete $requests->{$req_id};

    my $enc_params = delete $reqdata->{params};
    my $p = $reqdata->{params} = eval { $self->_body2hash(\$enc_params) };
    if($@)
    {    notice __x"fcgi {id} params error: {err}", id => $req_id, err => $@;
         delete $requests->{$req_id};
         return $self->get_request;
    }

    my $expected_stdin = $p->{CONTENT_LENGTH} || 0;
    $expected_stdin == length $reqdata->{stdin}
        or error __x"fcgi {id} received {got} bytes on stdin, expected {need}"
             , id   => $req_id
             , got  => length $reqdata->{stdin}
             , need => $expected_stdin;

    my $expected_data = $p->{FCGI_DATA_LENGTH} || 0;
    $expected_data == length $reqdata->{data}
        or error __x"fcgi {id} received {got} bytes for data, expected {need}"
            , id   => $req_id
            , got  => length $reqdata->{data}
            , need => $expected_data;

    my $request     = Any::Daemon::FCGI::Request->new($reqdata);

    my $remote_ip   = $request->param('REMOTE_ADDR');
    my $remote_host = gethostbyaddr inet_aton($remote_ip), AF_INET;
    info __x"fcgi {id} request from {host}"
      , id   => $req_id
      , host => $remote_host || $remote_ip;

    $self->keep_connection
        or $self->socket->shutdown(SHUT_RD);

    $request;
}

sub send_response($;$)
{   my ($self, $response, $stderr) = @_;

    #XXX Net::Async::FastCGI::Request demonstrates how to catch stdout and
    #XXX stderr via ties.  We don't use that here: cleanly work with
    #XXX HTTP::Message objects... errors are logged locally.

    my $req_id = $response->request->request_id;

    # Simply "Status: " in front of the Response header will make the whole
    # message HTTP::Response into a valid CGI response.
    $self->_reply_record(STDOUT => $req_id
      , 'Status: '.$response->as_string(CRLF));
    $self->_reply_record(STDOUT => $req_id, '');

    if($stderr && length $$stderr)
    {   $self->_reply_record(STDERR => $req_id, $$stderr);
        $self->_reply_record(STDERR => $req_id, '');
    }

    $self->_fcgi_end_request(REQUEST_COMPLETE => $req_id);

    $self->keep_connection
        or $self->socket->shutdown(SHUT_WR);

    $self;
}

sub keep_connection()
{   my $self = shift;
    $self->{ADFC_keep_conn} || keys %{$self->{ADFC_requests}}
}

#### MANAGEMENT RECORDS
# have req_id==0

sub _management_record($$)
{   my ($self, $type, $body) = @_;
      $type eq 'GET_VALUES' ? $self->_fcgi_get_values($body)
    :                         $self->_fcgi_unknown($body);
}

# Request record FCGI_GET_VALUES may be used by the front-end server to
# collect back_end settings.  In Apache, you have to configure it manually.

sub _fcgi_get_values($)
{   my $self = shift;
    my %need = $self->_body2hash(shift);

    # The maximum number of concurrent transport connections this
    # application will accept.
    $need{FCGI_MAX_CONNS} = $self->{ADFC_max_conns}
        if exists $need{FCGI_MAX_CONNS};

    # The maximum number of concurrent requests this application will accept.
    $need{FCGI_MAX_REQS} = $self->{ADFC_max_reqs}
        if exists $need{FCGI_MAX_REQS};

    # "0" if this application does not multiplex connections (i.e. handle
    # concurrent requests over each connection), "1" otherwise.
    $need{FCGI_MPXS_CONNS} = 0
        if exists $need{FCGI_MPXS_CONNS};

    $self->_reply_record(GET_VALUES_RESULT => 0, $self->hash2body(\%need));
}

# Reply record FCGI_UNKNOWN_TYPE is designed for protocol upgrades: to 
# respond to unknown record types.

sub _fcgi_unknown($)
{   my ($self, $body) = @_;
    $self->_reply_record(UNKNOWN_TYPE => 0, '');
}

# Reply END_REQUEST is used for all ways to close a BEGIN_REQUEST session.
# It depends on the $status code which additionals fields were sent.

sub _fcgi_end_request($$;$)
{   my ($self, $status, $req_id, $rc) = @_;
    my $body = pack "nCCCC", $rc || 0, $end_status2id{$status}
      , RESERVED, RESERVED, RESERVED;

    $self->_reply_record(END_REQUEST => $req_id, $body);
}

# Convert the FGCI request into a full HTTP::Request object
sub _body2hash($$)
{   my ($self, $body) = @_;
    my %h;

    while(length $$body)
    {   my $name_len  = $self->_take_encoded_nv($body);
        my $value_len = $self->_take_encoded_nv($body);
 
        my $name  = substr $$body, 0, $name_len,  '';
        $h{$name} = substr $$body, 0, $value_len, '';
    }

    \%h;
}

sub _hash2body($)
{   my ($self, $h) = @_;
    my @params;
    foreach my $name (sort keys %$h)
    {    my $name_len = length $name;
         my $val_len  = length $h->{$name};
         push @params, pack "NNxa{$name_len}xa{$val_len}"
           , $name_len, $val_len, $name, $h->{$name};
    }
    join '', @params;
}

# Numerical values are 1 or 4 bytes.  Long when first bit == 1
sub _take_encoded_nv($)
{   my ($self, $body) = @_;
    my $short = unpack 'C', substr $$body, 0, 1, '';
    $short & 0x80 or return $short;

    my $long  = pack('C', $short & 0x7F) . substr($$body, 0, 3, '');
    unpack 'N', $long;
}

sub _read_chunk($)
{   my ($self, $need) = @_;
    my $stdin = $self->{ADFC_stdin};

    return substr $$stdin, 0, $need, ''
       if length $$stdin > $need;

    my $select = $self->{ADFC_select};

    while(length $$stdin < $need)
    {   $select->can_read or next;

        my $bytes_read = sysread $self->socket, my $more, MAX_READ_CHUNKS, 0;
        if(defined $bytes_read)
        {   $bytes_read or last;
            $$stdin .= $more;
            next;
        }

        last unless $! == EAGAIN || $! == EINTR || $! == EWOULDBLOCK;

        usleep 1000;   # 1 ms
    }

    substr $$stdin, 0, $need, '';
}

1;
