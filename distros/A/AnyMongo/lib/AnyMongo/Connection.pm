package AnyMongo::Connection;
BEGIN {
  $AnyMongo::Connection::VERSION = '0.03';
}
# ABSTRACT: Asynchronous MongoDB::Connection
use strict;
use warnings;
use constant {
    DEBUG => $ENV{ANYMONGO_DEBUG},
    # bson type
    BSON_INT32 => 4,
    BSON_INT64 => 8,
    # msg header size
    STANDARD_HEADER_SIZE => 16,
    RESPONSE_HEADER_SIZE => 20,
    # opcode
    OP_REPLY    => 1,
    OP_MSG      => 1000, #generic msg command followed by a string
    OP_UPDATE	=> 2001, #update document
    OP_INSERT	=> 2002, #insert new document
    RESERVED	=> 2003, #formerly used for OP_GET_BY_OID
    OP_QUERY	=> 2004, #query a collection
    OP_GET_MORE	=> 2005, #Get more data from a query. See Cursors
    OP_DELETE	=> 2006, #Delete documents
    OP_KILL_CURSORS  => 2007,
    # flags
    REPLY_CURSOR_NOT_FOUND     => 1,
    REPLY_QUERY_FAILURE        => 2,
    REPLY_SHARD_CONFIG_STALE   => 4,
    REPLY_AWAIT_CAPABLE        => 8,
};

use Carp qw(croak);
use Data::Dumper;
use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyMongo::BSON qw(bson_decode);
use AnyMongo::MongoSupport qw(decode_bson_documents);
use AnyMongo::Cursor;
use namespace::autoclean;
use Any::Moose;

has find_master => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
    default  => 0,
);

has master_handle => (
    isa => 'Maybe[AnyEvent::Handle]',
    is  => 'rw',
    clearer  => 'clear_master_handle',
);

has secondary_nodes => (
    isa => 'ArrayRef',
    is  => 'rw',
);

has secondary_nodes => (
    isa => 'ArrayRef',
    is  => 'rw',
    lazy_build => 1,
    clearer  => 'clear_secondary_nodes',
);

sub _build_secondary_nodes {
    my ($self) = @_;
    [];
}

has arbitor_nodes => (
    isa => 'ArrayRef',
    is  => 'rw',
    lazy_build => 1,
    clearer  => 'clear_arbitor_nodes',
);

sub _build_arbitor_nodes {
    my ($self) = @_;
    [];
}


has ts => (
    is      => 'rw',
    isa     => 'Int',
    default => 0
);

has db_name => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => 'admin',
);

has query_timeout => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
    default  => sub { return $AnyMongo::Cursor::timeout; },
);

has auto_connect => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
    default  => 1,
);

has auto_reconnect => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
    default  => 1,
);

has host => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'mongodb://localhost:27017',
);

has w => (
    is      => 'rw',
    isa     => 'Int',
    default => 1,
);


has wtimeout => (
    is      => 'rw',
    isa     => 'Int',
    default => 1000,
);

has timeout => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    default  => 20000,
);

has username => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has password => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has connected => (
    isa => 'Bool',
    is  => 'rw',
    default  => 0,
);

has cv => (
    isa => 'AnyEvent::CondVar',
    is  => 'ro',
    lazy_build => 1,
    clearer  => 'clear_cv',
);

sub _build_cv {
    my ($self) = @_;
    AE::cv;
}

has _connection_error => (
    isa => 'Bool',
    is  => 'rw',
    default  => 0,
);


sub CLONE_SKIP { 1 }

sub BUILD { shift->_init }

sub _init {
    my ($self) = @_;
    eval "use ${_}" # no Any::Moose::load_class becase the namespaces already have symbols from the xs bootstrap
        for qw/AnyMongo::Database AnyMongo::Cursor AnyMongo::BSON::OID/;
    $self->_parse_servers();
    if ($self->auto_connect) {
        $self->connect;
        # if (defined $self->username && defined $self->password) {
        #     $self->authenticate($self->db_name, $self->username, $self->password);
        # }
    }

}

sub connect {
    my ($self,%args) = @_;
    return if $self->connected || $self->{_trying_connect};
    # warn "connect...\n";
    $self->{_trying_connect} = 1;
    #setup connection timeout watcher
    my $timer; $timer = AnyEvent->timer( after => 5 ,cb => sub {
        undef $timer;
        unless ( $self->connected ) {
            $self->{_trying_connect} = 0;
            $self->cv->croak('Failed to connect to any mongodb servers,timeout');
        }
    });
    $self->cv->begin( sub {
        undef $timer;
        if ($self->connected) {
            $self->_connection_error(0);
            shift->send;
        }
        else {
            shift->croak("Failed to connect to any mongodb servers");
        }
    });

    my $servers = $self->{mongo_servers};
    my $seed_queue = $self->{_seed_queue} = [ keys %{ $servers } ];
    my $seed_tried = $self->{_seed_tried} = {};
    while (!$self->connected && @{$seed_queue} ) {
        while (my $h = shift @{$seed_queue}) {
            $seed_tried->{$h} = 1;
            $self->_check_master($h);
        }
    }
    $self->cv->recv;
    $self->{_trying_connect} = 0;
    # warn "connect done.\n";
}


sub _set_master {
    my ($self,$server_id,$h) = @_;
    $self->master_handle($h);
    $self->{mongo_servers}->{$server_id}->{is_master} = 1;
    $self->{master_id} = $server_id;
    $self->connected(1);
    # warn "master_id:$server_id\n";
}


sub _is_master {
    my ($config) = @_;
    $config && (ref($config) ne 'SCALAR') && ($config->{ismaster});
}

sub _check_master {
    my ($self,$server_id,$only_self) = @_;
    my $guards = $self->{_guards};
    return if $guards->{$server_id} or $self->connected;
    my $connect_cv = AE::cv;
    $self->_connect_to_host($server_id, sub { $connect_cv->send(shift) });
    # FIXME: as run_command also call "recv", this is
    # the easiest way to fight with recursive blocking wait.
    # Though,it's not a problem when conjunction with Coro.
    my $handle = $connect_cv->recv;
    if ($handle) {
        my $config = $self->admin->run_command({ismaster => 1},$handle);
        # warn "check ismaster:$server_id\n";
        if (ref $config ne 'SCALAR') {
            # if this is a replica set & we haven't renewed the host list in 1 sec
            my $servers = $self->{mongo_servers};
            if ($config->{hosts} && time() > $self->ts) {
                foreach my $h (@{$config->{hosts}}) {
                    $self->_add_host($h);
                }
                $self->ts(time);
            }
        }
        else {
            # got some error, close this handle
            warn $config;
            delete $self->{_handles}->{$server_id} || delete $guards->{$server_id};
            $handle->destroy();
            undef $handle;
        }
        if ($handle) {
            if (_is_master($config)) {
                # warn "set_master:$server_id\n";
                $self->_set_master($server_id,$handle);
                $self->cv->end;
            }
            # replica set, found primary
            elsif ($self->find_master && exists $config->{primary} && !$only_self) {
                my $primary_id = $self->_add_host($config->{primary});
                # warn 'double check_master of primary:'.$primary_id;
                # double check primary host, only itself.
                $self->_check_master($primary_id,1) if $server_id ne $primary_id;
            }
        }
    }
}

sub _add_host {
    my ($self,$host) = @_;
    my $servers = $self->{mongo_servers};
    my $seed_queue = $self->{_seed_queue};
    my $seed_tried = $self->{_seed_tried};
    my ($h,$p) = split ':',$host;
    my $server_id = $h.':'.( $p || 27017);
    unless (exists $servers->{$server_id}) {
        $servers->{$server_id} = {
            host => $h,
            port => $p,
            primary => 0,
        };
        push @{$seed_queue}, $server_id unless exists $seed_tried->{$server_id};
    }
    $server_id;
}

sub _connect_to_host {
    my ($self,$server_id,$cb) = @_;
    my $guards = $self->{_guards};
    return if $guards->{$server_id};
    my ($host,$port) = @{$self->{mongo_servers}->{$server_id}}{'host','port'};
    $guards->{$server_id} = tcp_connect $host,$port, sub {
        my ($fh, $host, $port) = @_;
        my ($h,$config);

        if (!$fh) {
            warn "failed to connect to $server_id\n";
            delete $guards->{$server_id};
        }
        else {
            $h = AnyEvent::Handle->new(
                fh => $fh,
                on_eof => sub {
                    my $h = delete $self->{_handles}->{$server_id};
                    delete $guards->{$server_id};
                    warn "Eof of connection to $server_id\n";
                    if ($self->{master_id} eq $server_id) {
                        delete $self->{master_id};
                        $self->clear_master_handle;
                        $self->connected(0);
                    }
                    $h->{cv}->send if $h->{cv};
                    $h->destroy();
                },
                on_error => sub {
                    my ($hdl, $fatal, $msg) = @_;
                    warn "on_error:$server_id\n";
                    warn "got error $msg\n";
                    my $h = delete $self->{_handles}->{$server_id};
                    delete $guards->{$server_id};
                    if ($self->{master_id} eq $server_id) {
                        delete $self->{master_id};
                        $self->clear_master_handle;
                        $self->connected(0);
                    }
                    $h->{cv}->croak($msg) if $h->{cv};
                    $h->destroy();
                },
            );
            $self->{_handles}->{$server_id} = $h;
        }
        # return.
        if (ref $cb eq 'CODE') {
            $cb->($h);
        }
        else {
            $self->cv->end;
        }
    };
}

sub _parse_servers {
    my ($self) = @_;
    my $str = $self->host;
    $str = substr $self->host, 10 if $str =~ /^mongodb:\/\//;
    my @pairs = split ",", $str;
    my $servers = {};
    my $server_seeds_cnt = 0;
    for my $h (@pairs) {
        my ($host,$port) = split ':',$h;
        $port ||= 27017;
        $servers->{$host.':'.$port} = {
            connected => 0,
            handle => undef,
            host => $host,
            port => $port,
            is_master => 0,
        };
    }
    # $self->_servers($servers);
    $self->{mongo_servers} = $servers;
}

sub send_message {
    my ($self,$data,$hd) = @_;
    croak 'connection lost' unless $hd or $self->_check_connection;
    $hd ||= $self->master_handle;
    $hd->push_write($data);
}

sub _check_connection {
    my ($self) = @_;
    $self->connected or ($self->auto_reconnect and $self->connect);
    $self->connected;
}

sub recv_message {
    my ($self,$hd) = @_;
    my ($message_length,$request_id,$response_to,$op) = $self->_receive_header($hd);
    my ($response_flags,$cursor_id,$starting_from,$number_returned) = $self->_receive_response_header($hd);
    $self->_check_respone_flags($response_flags);
    my $results =  $self->_read_documents($message_length-36,$cursor_id,$hd);
    return ($number_returned,$cursor_id,$results);
}

sub _check_respone_flags {
    my ($self,$flags) = @_;
    if (($flags & REPLY_CURSOR_NOT_FOUND) != 0) {
        croak("cursor not found");
    }
}

sub receive_data {
    my ($self,$size,$hd) = @_;
    $hd ||= $self->master_handle;
    croak 'connection lost' unless $hd or $self->_check_connection;
    my $cv = AE::cv;
    my $timer; $timer = AnyEvent->timer( after => $self->query_timeout ,cb => sub {
        undef $timer;
        $cv->croak('receive_data timeout');
    });
    $hd->push_read(chunk => $size, sub {
        my ($hdl, $bytes) = @_;
        $cv->send($_[1]);
    });
    $hd->{cv} = $cv;
    my $data = $cv->recv;
    delete $hd->{cv};
    $data;
}


sub _receive_header {
    my ($self,$hd) = @_;
    my $header_buf = $self->receive_data(STANDARD_HEADER_SIZE,$hd);
    croak 'Short read for DB response header; length:'.length($header_buf) unless length $header_buf == STANDARD_HEADER_SIZE;
    return unpack('V4',$header_buf);
}

sub _receive_response_header {
    my ($self,$hd) = @_;
    my $header_buf = $self->receive_data(RESPONSE_HEADER_SIZE,$hd);
    croak 'Short read for DB response header' unless length $header_buf == RESPONSE_HEADER_SIZE;
    my ($response_flags) = unpack 'V',substr($header_buf,0,BSON_INT32);
    my ($cursor_id) = unpack 'j',substr($header_buf,BSON_INT32,BSON_INT64);
    my ($starting_from,$number_returned) = unpack 'V2',substr($header_buf,BSON_INT32+BSON_INT64);
    return ($response_flags,$cursor_id,$starting_from,$number_returned);
}

sub _read_documents {
    my ($self,$doc_message_length,$cursor_id,$hd) = @_;
    my $remaining = $doc_message_length;
    my $bson_buf;
    # do {
    #     my $buf_len = $remaining > 4096? 4096:$remaining;
    #     $bson_buf .= $self->receive_data($buf_len);
    #     $remaining -= $buf_len;
    # } while ($remaining >0 );
    $bson_buf = $self->receive_data($doc_message_length,$hd);
    return unless $bson_buf;
    # warn "#_read_documents:bson_buf size:".length($bson_buf);
    # my $docs = decode_bson_documents($bson_buf,length($bson_buf));
    # warn '#_read_documents decode_bson_documents ...';
    my $docs = decode_bson_documents($bson_buf);
    # warn "docs:$docs";
    # warn "#_read_documents:".Dumper($docs)."\n";
    return $docs;
}

sub database_names {
    my ($self) = @_;
    my $ret = $self->admin->run_command({ listDatabases => 1 });
    return map { $_->{name} } @{ $ret->{databases} };
}


sub get_database {
    my ($self, $database_name) = @_;
    return AnyMongo::Database->new(
        _connection => $self,
        name        => $database_name,
    );
}

sub authenticate {
    my ($self, $dbname, $username, $password, $is_digest) = @_;
    my $hash = $password;

    # create a hash if the password isn't yet encrypted
    if (!$is_digest) {
        $hash = Digest::MD5::md5_hex("${username}:mongo:${password}");
    }

    # get the nonce
    my $db = $self->get_database($dbname);
    my $result = $db->run_command({getnonce => 1});
    if (!$result->{'ok'}) {
        return $result;
    }

    my $nonce = $result->{'nonce'};
    my $digest = Digest::MD5::md5_hex($nonce.$username.$hash);

    # run the login command
    my $login = tie(my %hash, 'Tie::IxHash');
    %hash = (authenticate => 1,
             user => $username,
             nonce => $nonce,
             key => $digest);
    $result = $db->run_command($login);

    return $result;
}

sub admin { shift->get_database('admin') }

sub disconnect {
    my ($self) = @_;
    $self->clear_master_handle;
    my $guards = $self->{_guards};
    my $handles = $self->{_handles};
    map { delete $guards->{$_} } keys %{ $guards };
    map { (delete $handles->{$_})->destroy } keys %{$handles};
    $self->{mongo_servers} = {};
    $self->{_is_connected} = 0;
    $self->connected(0);
}

sub DEMOLISH {
    shift->disconnect;
}

__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

AnyMongo::Connection - Asynchronous MongoDB::Connection

=head1 VERSION

version 0.03

=head1 SYNOPSIS

=head1 DESCRIPTION

=for connection flow
    1. create connection to seed list in parallel
    2. check every connection and do follow:
    2.1 call ismaster check the node
    2.2 if node is master, connect will be success
    2.3 if node is secondary
    2.3.1 update hosts(full member list) if possible
    2.3.2 double check primary ismaster
    3. if connection success, connection done.
    3.1 else, check if seed queue not empty, goto 1
    4. can't connect to master,failed.

=head1 AUTHORS

=over 4

=item *

Pan Fan(nightsailer) <nightsailer at gmail.com>

=item *

Kristina Chodorow <kristina at 10gen.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Pan Fan(nightsailer).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

