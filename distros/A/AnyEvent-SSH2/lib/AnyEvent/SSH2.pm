# $Id: SSH2.pm,v 1.47 2009/01/26 01:50:38 turnstep Exp $
package AnyEvent::SSH2;
use strict;
use AE;
use AnyEvent::Handle;
use Net::SSH::Perl::Kex;
use Net::SSH::Perl::ChannelMgr;
use Net::SSH::Perl::Packet;
use Net::SSH::Perl::Buffer;
use Net::SSH::Perl::Constants qw( :protocol :msg2 :compat :hosts :channels :proposal :kex
                                  CHAN_INPUT_CLOSED CHAN_INPUT_WAIT_DRAIN );
use Net::SSH::Perl::Cipher;
use Net::SSH::Perl::AuthMgr;
use Net::SSH::Perl::Comp;
use Net::SSH::Perl::Util qw(:hosts);
use Scalar::Util qw(blessed weaken);
use Carp qw( croak );

use base qw( Net::SSH::Perl );
our $VERSION = '0.04';

use Errno qw( EAGAIN EWOULDBLOCK );
use vars qw( $VERSION $CONFIG $HOSTNAME @PROPOSAL );
use vars qw( @PROPOSAL );
@PROPOSAL = ( 
        KEX_DEFAULT_KEX,
        KEX_DEFAULT_PK_ALG,
        KEX_DEFAULT_ENCRYPT,
        KEX_DEFAULT_ENCRYPT,
        KEX_DEFAULT_MAC,
        KEX_DEFAULT_MAC,
        KEX_DEFAULT_COMP,
        KEX_DEFAULT_COMP,
        KEX_DEFAULT_LANG,
        KEX_DEFAULT_LANG,
        );

$CONFIG = {};

BEGIN {
    use Net::SSH::Perl::Packet;
    no warnings qw(redefine);
    *Net::SSH::Perl::Packet::send_ssh2 = sub  {
        my $pack = shift;
        my $buffer = shift || $pack->{data};
        my $ssh = $pack->{ssh};

        my $kex = $ssh->kex;
        my($ciph, $mac, $comp);
        if ($kex) {
            $ciph = $kex->send_cipher;
            $mac  = $kex->send_mac;
            $comp = $kex->send_comp;
        }
        my $block_size = 8;

        if ($comp && $comp->enabled) {
            my $compressed = $comp->compress($buffer->bytes);
            $buffer->empty;
            $buffer->append($compressed);
        }

        my $len = $buffer->length + 4 + 1;
        my $padlen = $block_size - ($len % $block_size);
        $padlen += $block_size if $padlen < 4;
        my $junk = $ciph ? (join '', map chr rand 255, 1..$padlen) : ("\0" x $padlen);
        $buffer->append($junk);

        my $packet_len = $buffer->length + 1;
        $buffer->bytes(0, 0, pack("N", $packet_len) . pack("c", $padlen));

        my($macbuf);
        if ($mac && $mac->enabled) {
            $macbuf = $mac->hmac(pack("N", $ssh->{session}{seqnr_out}) . $buffer->bytes);
        }
        my $output = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
        $output->append( $ciph && $ciph->enabled ? $ciph->encrypt($buffer->bytes) : $buffer->bytes );
        $output->append($macbuf) if $mac && $mac->enabled;

        $ssh->{session}{seqnr_out}++;

        my $handle = $ssh->sock;
        my $stat = $handle->push_write($output->bytes);
    };
    *Net::SSH::Perl::Packet::read_expect = sub {
        my $class = shift;
        my($ssh, $type, $cb) = @_;
        my $pack = $class->read($ssh, sub{
            my ($ssh, $pack) = @_;
            if ($pack->type != $type) {
                $ssh->fatal_disconnect(sprintf
                  "Protocol error: expected packet type %d, got %d",
                    $type, $pack->type);
            }
            $cb->($ssh, $pack);
        });
    };

    *Net::SSH::Perl::Packet::read = sub {
        my $class = shift;
        my $ssh = shift;
        my $cb  = shift;
        my $sock = $ssh->sock;
        if (my $packet = $class->read_poll($ssh)) {
            $cb->($ssh, $packet);
        }
        else {
            $sock->push_read(chunk => 4 => sub {
                my ($hdl, $buf) = @_;
                if (length($buf) == 0) {
                    croak "Connection closed by remote host." if !$buf;
                }
                if (!defined $buf) {
                    next if $! == EAGAIN || $! == EWOULDBLOCK;
                    croak "Read from socket failed: $!";
                }
                # Untaint data read from sshd. This is binary data,
                # so there's nothing to taint-check against/for.
                ($buf) = $buf =~ /(.*)/s;
                $ssh->incoming_data->append($buf);
                $class->read($ssh, $cb);
            })
        }
    };
    use Net::SSH::Perl::Kex;
    *Net::SSH::Perl::Kex::exchange_kexinit = sub {
        my $kex = shift;
        my $ssh = $kex->{ssh};
        my $received_packet = shift;
        my $cb = shift;
        my $packet;
    
        $packet = $ssh->packet_start(SSH2_MSG_KEXINIT);
        $packet->put_chars($kex->client_kexinit->bytes);
        $packet->send;
    
        if ( defined $received_packet ) {
    	    $ssh->debug("Received key-exchange init (KEXINIT), sent response.");
    	    $packet = $received_packet;
        }
        else {
    	    $ssh->debug("Sent key-exchange init (KEXINIT), wait response.");
    	    Net::SSH::Perl::Packet->read_expect($ssh, SSH2_MSG_KEXINIT, sub{
                my ($ssh, $packet) = @_;
                $kex->{server_kexinit} = $packet->data;
    
                $packet->get_char for 1..16;
                my @s_props = map $packet->get_str, 1..10;
                $packet->get_int8;
                $packet->get_int32;
                $cb->($ssh, \@s_props);
            });
        }
    };
    *Net::SSH::Perl::Kex::exchange = sub {
        my $kex = shift;
        my $ssh = $kex->{ssh};
        my $packet = shift;
        my $cb     = shift;
    
        my @proposal = @PROPOSAL;
        if (!$ssh->config->get('ciphers')) {
            if (my $c = $ssh->config->get('cipher')) {
                $ssh->config->set('ciphers', $c);
            }
        }
        if (my $cs = $ssh->config->get('ciphers')) {
            # SSH2 cipher names are different; for compatibility, we'll map
            # valid SSH1 ciphers to the SSH2 equivalent names
            if($ssh->protocol eq PROTOCOL_SSH2) {
                my %ssh2_cipher = reverse %Net::SSH::Perl::Cipher::CIPHERS_SSH2;
                $cs = join ',', map $ssh2_cipher{$_} || $_, split(/,/, $cs);
            }
            $proposal[ PROPOSAL_CIPH_ALGS_CTOS ] =
            $proposal[ PROPOSAL_CIPH_ALGS_STOC ] = $cs;
        }
        if ($ssh->config->get('compression')) {
            $proposal[ PROPOSAL_COMP_ALGS_CTOS ] =
            $proposal[ PROPOSAL_COMP_ALGS_STOC ] = "zlib";
        }
        else {
            $proposal[ PROPOSAL_COMP_ALGS_CTOS ] =
            $proposal[ PROPOSAL_COMP_ALGS_STOC ] = "none";
        }
        if ($ssh->config->get('host_key_algorithms')) {
            $proposal[ PROPOSAL_SERVER_HOST_KEY_ALGS ] =
                $ssh->config->get('host_key_algorithms');
        }
    
        $kex->{client_kexinit} = $kex->kexinit(\@proposal);
        $kex->exchange_kexinit($packet, sub{
            my ($ssh, $sprop) = @_;
            $kex->choose_conf(\@proposal, $sprop);
            $ssh->debug("Algorithms, c->s: " .
                "$kex->{ciph_name}[0] $kex->{mac_name}[0] $kex->{comp_name}[0]");
            $ssh->debug("Algorithms, s->c: " .
                "$kex->{ciph_name}[1] $kex->{mac_name}[1] $kex->{comp_name}[1]");
    
            bless $kex, $kex->{class_name};
            $kex->exchange(sub{
                my $ssh = shift;
                $ssh->debug("Waiting for NEWKEYS message.");
                Net::SSH::Perl::Packet->read_expect($ssh, SSH2_MSG_NEWKEYS, sub{
                    my ($ssh, $packet) = @_;
                    $ssh->debug("Send NEWKEYS.");
                    $packet = $ssh->packet_start(SSH2_MSG_NEWKEYS);
                    $packet->send;
    
                    $ssh->debug("Enabling encryption/MAC/compression.");
                    $ssh->{kex} = $kex;
                    for my $att (qw( mac ciph comp )) {
                        $kex->{$att}[0]->enable if $kex->{$att}[0];
                        $kex->{$att}[1]->enable if $kex->{$att}[1];
                    }
                    $cb->($ssh);
                });
            });
    
        });
    };
    use Net::SSH::Perl::Kex::DH1;
    no strict "subs";
    *Net::SSH::Perl::Kex::DH1::exchange = sub {
        package Net::SSH::Perl::Kex::DH1;
        my $kex = shift;
        my $ssh = $kex->{ssh};
        my $packet;
        my $dh = _dh_new_group1;
        my $cb = shift;

        $ssh->debug("Entering Diffie-Hellman Group 1 key exchange.");
        $packet = $ssh->packet_start(SSH2_MSG_KEXDH_INIT);
        $packet->put_mp_int($dh->pub_key);
        $packet->send;

        $ssh->debug("Sent DH public key, waiting for reply.");
        Net::SSH::Perl::Packet->read_expect($ssh,
            SSH2_MSG_KEXDH_REPLY, sub {
            my ($ssh, $packet) = @_;
            my $host_key_blob = $packet->get_str;
            my $s_host_key = Net::SSH::Perl::Key->new_from_blob($host_key_blob,
                \$ssh->{datafellows});
            $ssh->debug("Received host key, type '" . $s_host_key->ssh_name . "'.");

            $ssh->check_host_key($s_host_key);

            my $dh_server_pub = $packet->get_mp_int;
            my $signature = $packet->get_str;

            $ssh->fatal_disconnect("Bad server public DH value")
                unless _pub_is_valid($dh, $dh_server_pub);

            $ssh->debug("Computing shared secret key.");
            my $shared_secret = $dh->compute_key($dh_server_pub);

            my $hash = $kex->kex_hash(
                $ssh->client_version_string,
                $ssh->server_version_string,
                $kex->client_kexinit,
                $kex->server_kexinit,
                $host_key_blob,
                $dh->pub_key,
                $dh_server_pub,
                $shared_secret);

            $ssh->debug("Verifying server signature.");
            croak "Key verification failed for server host key"
                unless $s_host_key->verify($signature, $hash);

            $ssh->session_id($hash);

            $kex->derive_keys($hash, $shared_secret, $ssh->session_id);
            $cb->($ssh);
        });
    };
    use Net::SSH::Perl::AuthMgr;
    no warnings qw(redefine);
    #no strict "refs";
    *Net::SSH::Perl::AuthMgr::new = sub {
        my $class = shift;
        my $ssh = shift;
        my $amgr = bless { ssh => $ssh }, $class;
        weaken $amgr->{ssh};
        $amgr;
    };
    *Net::SSH::Perl::AuthMgr::run = sub {
        my $amgr = shift;
        my $cb = pop @_;
        my($end, @args) = @_;
        Net::SSH::Perl::Packet->read($amgr->{ssh}, sub{
            my ($ssh, $packet) = @_;
            my $code = $amgr->handler_for($packet->type);
            unless (defined $code) {
                $code = $amgr->error_handler ||
                    sub { croak "Protocol error: received type ", $packet->type };
            }
            $code->($amgr, $packet, @args);
            if ($$end) {
                $cb->($amgr);
                return;
            }
            $amgr->run($end, $cb);
        });
    };
    *Net::SSH::Perl::AuthMgr::authenticate = sub {
        package Net::SSH::Perl::AuthMgr;
        my $amgr = shift;
        my $cb   = shift;
        $amgr->init(sub{
            my ($ssh, $amgr) = @_;
            my($packet);
    
            my $valid = 0;
            $amgr->{_done} = 0;
            $amgr->register_handler(SSH2_MSG_USERAUTH_SUCCESS, sub {
                $valid++;
                $amgr->{_done}++
            });
            $amgr->register_handler(SSH2_MSG_USERAUTH_BANNER, sub {
                my $amgr = shift;
                my($packet) = @_;
                if ($amgr->{ssh}->config->get('interactive')) {
                    print $packet->get_str, "\n";
                }
            });
            $amgr->register_handler(SSH2_MSG_USERAUTH_FAILURE, \&auth_failure);
            $amgr->register_error(
                sub { croak "userauth error: bad message during auth" } );
            $amgr->run( \$amgr->{_done}, sub{
                my ($amgr) = shift;
                $amgr->{agent}->close_socket if $amgr->{agent};
    
                $cb->($ssh, $amgr, $valid);
            } );
    
        });
    };

    *Net::SSH::Perl::AuthMgr::init = sub {
        package Net::SSH::Perl::AuthMgr;
        my $amgr = shift;
        my $cb   = shift;
        my $ssh = $amgr->{ssh};
        my($packet);
    
        $ssh->debug("Sending request for user-authentication service.");
        $packet = $ssh->packet_start(SSH2_MSG_SERVICE_REQUEST);
        $packet->put_str("ssh-userauth");
        $packet->send;
    
        Net::SSH::Perl::Packet->read($ssh, sub {
            my ($ssh, $packet) = @_;
            croak "Server denied SSH2_MSG_SERVICE_ACCEPT: ", $packet->type
                unless $packet->type == SSH2_MSG_SERVICE_ACCEPT;
            $ssh->debug("Service accepted: " . $packet->get_str . ".");
    
            $amgr->{agent} = Net::SSH::Perl::Agent->new(2);
            $amgr->{service} = "ssh-connection";
    
            $amgr->send_auth_none;
            $cb->($ssh, $amgr);
        });
    
    };
};
use Carp qw( croak );

sub VERSION { $VERSION }

sub new {
    my $class = shift;
    my $host = shift;
    croak "usage: ", __PACKAGE__, "->new(\$host)"
        unless defined $host;
    my $ssh = bless { host => $host }, $class;
    my %p = @_;
    $ssh->{_test} = delete $p{_test};
    $ssh->_init(%p);
    $ssh;
}

sub _init {
    my $ssh = shift;

    my %arg = @_;
    my $user_config = delete $arg{user_config} || "$ENV{HOME}/.ssh/config";
    my $sys_config  = delete $arg{sys_config}  || "/etc/ssh_config";

    my $directives = delete $arg{options} || [];

    if (my $proto = delete $arg{protocol}) {
        push @$directives, "Protocol $proto";
    }

    my $cfg = Net::SSH::Perl::Config->new($ssh->{host}, %arg);
    $ssh->{config} = $cfg;

    # Merge config-format directives given through "options"
    # (just like -o option to ssh command line). Do this before
    # reading config files so we override files.
    for my $d (@$directives) {
        $cfg->merge_directive($d);
    }

    for my $f (($user_config, $sys_config)) {
        $ssh->debug("Reading configuration data $f");
        $cfg->read_config($f);
    }

    if (my $real_host = $ssh->{config}->get('hostname')) {
        $ssh->{host} = $real_host;
    }

    my $user = _current_user();
    if ($user && $user eq "root" &&
      !defined $ssh->{config}->get('privileged')) {
        $ssh->{config}->set('privileged', 1);
    }

    unless ($ssh->{config}->get('protocol')) {
        $ssh->{config}->set('protocol',
            PROTOCOL_SSH1 | PROTOCOL_SSH2 | PROTOCOL_SSH1_PREFERRED);
    }

    unless (defined $ssh->{config}->get('password_prompt_login')) {
        $ssh->{config}->set('password_prompt_login', 1);
    }
    unless (defined $ssh->{config}->get('password_prompt_host')) {
        $ssh->{config}->set('password_prompt_host', 1);
    }

    unless (defined $ssh->{config}->get('number_of_password_prompts')) {
        $ssh->{config}->set('number_of_password_prompts', 3);
    }

    # login
    if (!defined $ssh->{config}->get('user')) {
        $ssh->{config}->set('user',
            defined $arg{user} ? $arg{user} : _current_user());
    }
    if (!defined $arg{pass} && exists $CONFIG->{ssh_password}) {
        $arg{pass} = $CONFIG->{ssh_password};
    }
    $ssh->{config}->set('pass', $arg{pass});

    #my $suppress_shell = $_[2];
}

sub _current_user {
    my $user;
    eval { $user = scalar getpwuid $> };
    return $user;
}

sub set_protocol {
    my $ssh = shift;
    my $proto = shift;
    $ssh->{use_protocol} = $proto;
    $ssh->debug($ssh->version_string);
    $ssh->_proto_init;
}


sub _dup {
    my($fh, $mode) = @_;
    my $dup = Symbol::gensym;
    my $str = "${mode}&$fh";
    open ($dup, $str) or die "Could not dupe: $!\n"; ## no critic
    $dup;
}

sub version_string {
    my $class = shift;
    sprintf "Net::SSH::Perl Version %s, protocol version %s.%s.",
        $class->VERSION, PROTOCOL_MAJOR_2, PROTOCOL_MINOR_2;
}

sub _exchange_identification {
    my $ssh = shift;
    my $remote_id = $ssh->_read_version(@_); 
    ($ssh->{server_version_string} = $remote_id) =~ s/\cM?$//;
    my($remote_major, $remote_minor, $remote_version) = $remote_id =~
        /^SSH-(\d+)\.(\d+)-([^\n]+)$/;
    $ssh->debug("Remote protocol version $remote_major.$remote_minor, remote software version $remote_version");

    my $proto = $ssh->config->get('protocol');
    my($mismatch, $set_proto);
    if ($remote_major == 1) {
        if ($remote_minor == 99 && $proto & PROTOCOL_SSH2 &&
            !($proto & PROTOCOL_SSH1_PREFERRED)) {
            $set_proto = PROTOCOL_SSH2;
        }
        elsif (!($proto & PROTOCOL_SSH1)) {
            $mismatch = 1;
        }
        else {
            $set_proto = PROTOCOL_SSH1;
        }
    }
    elsif ($remote_major == 2) {
        if ($proto & PROTOCOL_SSH2) {
            $set_proto = PROTOCOL_SSH2;
        }
    }
    if ($mismatch) {
        croak sprintf "Protocol major versions differ: %d vs. %d",
            ($proto & PROTOCOL_SSH2) ? PROTOCOL_MAJOR_2 :
            PROTOCOL_MAJOR_1, $remote_major;
    }
    my $compat20 = $set_proto == PROTOCOL_SSH2;
    my $buf = sprintf "SSH-%d.%d-%s\n",
        $compat20 ? PROTOCOL_MAJOR_2 : PROTOCOL_MAJOR_1,
        $compat20 ? PROTOCOL_MINOR_2 : PROTOCOL_MINOR_1,
        $VERSION;
    $ssh->{client_version_string} = substr $buf, 0, -1;
    my $handle = $ssh->{session}{sock};
    $handle->push_write($buf);
    $ssh->set_protocol($set_proto);
    $ssh->_compat_init($remote_version);
}

sub _proto_init {
    my $ssh = shift;
    my $home = $ENV{HOME} || (getpwuid($>))[7];
    unless ($ssh->{config}->get('user_known_hosts')) {
        defined $home or croak "Cannot determine home directory, please set the environment variable HOME";
        $ssh->{config}->set('user_known_hosts', "$home/.ssh/known_hosts2");
    }
    unless ($ssh->{config}->get('global_known_hosts')) {
        $ssh->{config}->set('global_known_hosts', "/etc/ssh_known_hosts2");
    }
    unless (my $if = $ssh->{config}->get('identity_files')) {
        defined $home or croak "Cannot determine home directory, please set the environment variable HOME";
        $ssh->{config}->set('identity_files', [ "$home/.ssh/id_dsa" ]);
    }

    for my $a (qw( password dsa kbd_interactive )) {
        $ssh->{config}->set("auth_$a", 1)
            unless defined $ssh->{config}->get("auth_$a");
    }
}

sub kex { $_[0]->{kex} }

sub register_handler {
    my($ssh, $type, $sub, @extra) = @_;
    $ssh->{client_handlers}{$type} = { code => $sub, extra => \@extra };
}

sub connect {
    my $ssh = shift;
    my($type, @args) = @_;
    $ssh->{session}{sock} = new AnyEvent::Handle
        connect  => [
          $ssh->{host} => $ssh->{config}->get('port') || 'ssh'
        ],
        on_error => sub {
            my ($hdl, $fatal, $msg) = @_;
            $ssh->debug("Can't connect to $ssh->{host}, port $ssh->{config}->get('port'): $msg");
            $hdl->destroy;
        },
        on_connect_error => sub {
            $ssh->debug("Can't connect to $ssh->{host}, port $ssh->{config}->get('port'): $!");
        }, 
        on_eof   => sub {
            shift->destroy; # explicitly destroy handle
        };
    $ssh->{session}{sock}->push_read( line => sub {
        my ($handle, $line) = @_;
        $ssh->_exchange_identification($line);
        $ssh->debug("Connection established.");
        $ssh->_login();


    });
}

sub _login {
    my $ssh = shift;

    my $kex = Net::SSH::Perl::Kex->new($ssh);
    $kex->exchange(undef, sub{
        my $ssh = shift;
        my $amgr = Net::SSH::Perl::AuthMgr->new($ssh);
        $amgr->authenticate(sub{
            my ($ssh, $amgr, $valid) = @_; 
            $ssh->debug("Login completed, opening dummy shell channel.");
            my $cmgr = $ssh->channel_mgr;
            my $channel = $cmgr->new_channel(
                ctype => 'session', local_window => 0,
                local_maxpacket => 0, remote_name => 'client-session');
            $channel->open;

            Net::SSH::Perl::Packet->read_expect($ssh,
                SSH2_MSG_CHANNEL_OPEN_CONFIRMATION, sub{
                my ($ssh, $packet) = @_;
                $cmgr->input_open_confirmation($packet);

                #my $suppress_shell = $_[2];
                #unless ($suppress_shell) {
                #    $ssh->debug("Got channel open confirmation, requesting shell.");
                #    $channel->request("shell", 0);
                #}

                $ssh->client_loop;
            });
        });
    })
}

sub emit {
  my ($self, $name) = (shift, shift);

  if (my $s = $self->{events}{$name}) {
    $self->debug("-- Emit $name in @{[blessed $self]} (@{[scalar @$s]})\n");
    my $arg = shift @$s;
    $self->$name(@$arg);
  }
  else {
    $self->debug("-- Emit $name in @{[blessed $self]} (0)\n");
    die "@{[blessed $self]}: $_[0]" if $name eq 'error';
  }

  return $self;
}

sub _session_channel {
    my $ssh = shift;
    my $cmgr = $ssh->channel_mgr;

    my $channel = $cmgr->new_channel(
        ctype => 'session', local_window => 32*1024,
        local_maxpacket => 16*1024, remote_name => 'client-session',
        rfd => _dup('STDIN', '<'), wfd => _dup('STDOUT', '>'),
        efd => _dup('STDERR', '>'));

    $channel;
}

sub _make_input_channel_req {
    my($r_exit) = @_;
    return sub {
        my($channel, $packet) = @_;
        my $rtype = $packet->get_str;
        my $reply = $packet->get_int8;
        $channel->{ssh}->debug("input_channel_request: rtype $rtype reply $reply");
        if ($rtype eq "exit-status") {
            $$r_exit = $packet->get_int32;
        }
        if ($reply) {
            my $r_packet = $channel->{ssh}->packet_start(SSH2_MSG_CHANNEL_SUCCESS);
            $r_packet->put_int($channel->{remote_id});
            $r_packet->send;
        }
    };
}

sub on { push @{$_[0]->{events}{$_[1]}}, [$_[-2], $_[-1]] }

sub send {
    my ($ssh, $cmd, $cb) = @_;
    $ssh->on(cmd => $cmd => $cb);
    $ssh;
}


#sub shell {
#    my $ssh = shift;
#    my $cb  = shift;
#    $ssh->on(_shell => '');
#    $ssh->on(on_fininsh => $cb);
#    $ssh;
#}
#
#sub _shell {
#    my $ssh = shift;
#    my $cmgr = $ssh->channel_mgr;
#    my $channel = $ssh->_session_channel;
#    $channel->open;
#
#    $channel->register_handler(SSH2_MSG_CHANNEL_OPEN_CONFIRMATION, sub {
#        my($channel, $packet) = @_;
#        my $r_packet = $channel->request_start('pty-req', 0);
#        my($term) = $ENV{TERM} =~ /(\S+)/;
#        $r_packet->put_str($term);
#        my $foundsize = 0;
#        if (eval "require Term::ReadKey") {
#            my @sz = Term::ReadKey::GetTerminalSize($ssh->sock);
#            if (defined $sz[0]) {
#                $foundsize = 1;
#                $r_packet->put_int32($sz[1]); # height
#                $r_packet->put_int32($sz[0]); # width
#                $r_packet->put_int32($sz[2]); # xpix
#                $r_packet->put_int32($sz[3]); # ypix
#            }
#        }
#        if (!$foundsize) {
#            $r_packet->put_int32(0) for 1..4;
#        }
#        $r_packet->put_str("");
#        $r_packet->send;
#        $channel->{ssh}->debug("Requesting shell.");
#        $channel->request("shell", 0);
#    });
#
#    my($exit);
#    $channel->register_handler(SSH2_MSG_CHANNEL_REQUEST,
#        _make_input_channel_req(\$exit));
#
#    $channel->register_handler("_output_buffer", sub {
#        syswrite STDOUT, $_[1]->bytes;
#    });
#    $channel->register_handler("_extended_buffer", sub {
#        syswrite STDERR, $_[1]->bytes;
#    });
#
#    $ssh->debug("Entering interactive session.");
#}

sub cmd {
    my $ssh = shift;
    my($cmd, $cb) = @_;

    my $cmgr = $ssh->channel_mgr;
    my $channel = $ssh->_session_channel;
    $channel->open;


    $channel->register_handler(SSH2_MSG_CHANNEL_OPEN_CONFIRMATION, sub {
        my($channel, $packet) = @_;

        ## Experimental pty support:
        if ($ssh->{config}->get('use_pty')) {
		    $ssh->debug("Requesting pty.");

		    my $packet = $channel->request_start('pty-req', 0);

		    my($term) = $ENV{TERM} =~ /(\w+)/;
		    $packet->put_str($term);
		    my $foundsize = 0;
		    if (eval "require Term::ReadKey") {
		    	my @sz = Term::ReadKey::GetTerminalSize($ssh->sock);
		    	if (defined $sz[0]) {
		    		$foundsize = 1;
		    		$packet->put_int32($sz[1]); # height
		    		$packet->put_int32($sz[0]); # width
		    		$packet->put_int32($sz[2]); # xpix
		    		$packet->put_int32($sz[3]); # ypix
		    	}
		    }
		    if (!$foundsize) {
		    	$packet->put_int32(0) for 1..4;
		    }

            # Array used to build Pseudo-tty terminal modes; fat commas separate opcodes from values for clarity.
            my $terminal_mode_string;
            if(!defined($ssh->{config}->get('terminal_mode_string'))) {
                my @terminal_modes = (
                   5 => 0,0,0,4,      # VEOF => 0x04 (^d)
                   0                  # string must end with a 0 opcode
                );
                for my $char (@terminal_modes) {
                    $terminal_mode_string .= chr($char);
                }
            }
            else {
                $terminal_mode_string = $ssh->{config}->get('terminal_mode_string');
            }
            $packet->put_str($terminal_mode_string);
            $packet->send;
        }

        my $r_packet = $channel->request_start("exec", 0);
        $r_packet->put_str($cmd);
        $r_packet->send;

    });

    my($exit);
    $channel->register_handler(SSH2_MSG_CHANNEL_REQUEST,
        _make_input_channel_req(\$exit));

    my $h = $ssh->{client_handlers};
    my($stdout, $stderr);
    if (my $r = $h->{stdout}) {
        $channel->register_handler("_output_buffer",
            $r->{code}, @{ $r->{extra} });
    }
    else {
        $channel->register_handler("_output_buffer", sub {
            $stdout .= $_[1]->bytes;
        });
    }
    if (my $r = $h->{stderr}) {
        $channel->register_handler("_extended_buffer",
            $r->{code}, @{ $r->{extra} });
    }
    else {
        $channel->register_handler("_extended_buffer", sub {
            $stderr .= $_[1]->bytes;
        });
    }

    $ssh->debug("Entering interactive session.");
    $channel->{cb} = sub {
        $cb->($ssh, $stdout, $stderr);
    }
    
}

sub break_client_loop { $_[0]->{ek_client_loopcl_quit_pending} = 1 }
sub restore_client_loop { $_[0]->{_cl_quit_pending} = 0 }
sub _quit_pending { $_[0]->{_cl_quit_pending} }

sub client_loop {
    my $ssh = shift;
    return unless scalar @{$ssh->{events}{cmd}} > 0;
    $ssh->emit('cmd');
    $ssh->{_cl_quit_pending} = 0;

    # 取所有频道
    my $cmgr = $ssh->channel_mgr;
    
    # 处理每个频道的事件
    my $h = $cmgr->handlers;
    $ssh->event_loop($cmgr, $h);
}

sub event_loop {
    my ($ssh, $cmgr, $h, $cb) = @_;
    return $ssh->client_loop if $ssh->_quit_pending;
    while (my $packet = Net::SSH::Perl::Packet->read_poll($ssh)) {
        if (my $code = $h->{ $packet->type }) {
            $code->($cmgr, $packet);
        }
        else {
            $ssh->debug("Warning: ignore packet type " . $packet->type);
        }
    }

    return $ssh->client_loop if $ssh->_quit_pending;

    $cmgr->process_output_packets;

    # 如果处理完了. 关掉所有的连接
    # 之所以在这进行这个操作是因为主 channel 也需要操作
    for my $c (@{ $cmgr->{channels} }) {
        next unless defined $c;
        if ($c->{wfd} &&
            $c->{extended}->length == 0 &&
            $c->{output}->length == 0 &&
            $c->{ostate} == CHAN_OUTPUT_WAIT_DRAIN ) { 
                $c->obuf_empty;
        }
        # 上面 obuf_empty 会给 ostate 变成 CHAN_OUTPUT_CLOSED
        # 下面这个就会发关闭给远程
        if ($c->delete_if_full_closed) {
            defined $c->{cb} ? $c->{cb}->() : '';
            $cmgr->remove($c->{id});
        }
    }
        
    my $oc = grep { defined } @{ $cmgr->{channels} };
    return $ssh->client_loop unless $oc > 1;

    my $cv = AE::cv sub {
        my $result = shift->recv;
        delete $ssh->{watcher};
        $ssh->event_loop($cmgr, $h, $cb);
    };

    # 这是处理频道上的输出, 客户端的输入
    for my $c (@{ $cmgr->{channels} }) {
        next unless defined $c;
        my $id = $c->{id};
        if ($c->{rfd} && $c->{istate} == CHAN_INPUT_OPEN &&
            $c->{remote_window} > 0 &&
            $c->{input}->length < $c->{remote_window}) {
            $ssh->{watcher}{$id}{rfd} = AE::io $c->{rfd}, 0, sub {
                # 顺序记录 - 频道 - rfd
                my $buf;
                sysread $c->{rfd}, $buf, 8192;
                ($buf) = $buf =~ /(.*)/s;
                $c->send_data($buf);
                $cv->send('rfd');
                delete $ssh->{watcher}{$id}{rfd}
            };
        } 

        # 给内容输出
        if (defined $c->{wfd} &&
            $c->{ostate} == CHAN_OUTPUT_OPEN ||
            $c->{ostate} == CHAN_OUTPUT_WAIT_DRAIN) {
            if ($c->{output} and $c->{output}->length > 0) {
                $ssh->{watcher}{$id}{wfd} = AE::io $c->{wfd}, 1, sub {
                   if (my $r = $c->{handlers}{"_output_buffer"}) {
                       $r->{code}->( $c, $c->{output}, @{ $r->{extra} } );
                   }
                   $c->{local_consumed} += $c->{output}->length;
                   $c->{output}->empty;
                   $cv->send('wfd');
                    delete $ssh->{watcher}{$id}{wfd}
                }
            }
        }
        
        if ($c->{efd} && $c->{extended}->length > 0) {
            my $c->{watcher}{$id}{efd} = AE::io $c->{efd}, 1, sub {
                if (my $r = $c->{handlers}{"_extended_buffer"}) {
                    $r->{code}->( $c, $c->{extended}, @{ $r->{extra} } );
                }
                $c->{local_consumed} += $c->{extended}->length;
                $c->{extended}->empty;
                $cv->send('efd');
                delete $ssh->{watcher}{$id}{efd}
            };
        }

        
        # 原进程
        $c->check_window;
        if ($c->delete_if_full_closed) {
            defined $c->{cb} ? $c->{cb}->() : '';
            $cmgr->remove($c->{id});
        }
    }


    # 这是主连接的句柄
    my $handle = $ssh->{session}{sock};
    $handle->push_read( chunk => 4 => sub {
        my ($handle, $buf) = @_;
        if (!length($buf)) {
            croak "Connection failed: $!\n";
        }
        $ssh->break_client_loop if length($buf) == 0;
        ($buf) = $buf =~ /(.*)/s;  ## Untaint data. Anything allowed.
        $ssh->incoming_data->append($buf);
        $cv->send('main');
    });
}

sub channel_mgr {
    my $ssh = shift;
    unless (defined $ssh->{channel_mgr}) {
        $ssh->{channel_mgr} = Net::SSH::Perl::ChannelMgr->new($ssh);
    }
    $ssh->{channel_mgr};
}
sub _read_version {
    my $ssh = shift;
    my $line = shift;;
    my $len = length $line;
    unless(defined($len)) {
        next if $! == EAGAIN || $! == EWOULDBLOCK;
        croak "Read from socket failed: $!";
    }
    croak "Connection closed by remote host" if $len == 0;
    croak "Version line too long: $line"
     if substr($line, 0, 4) eq "SSH-" and length($line) > 255;
    croak "Pre-version line too long: $line" if length($line) > 4*1024;
    if (substr($line, 0, 4) ne "SSH-") {
        $ssh->debug("Remote version string: $line");
    }
    return $line;
}
sub sock { $_[0]->{session}{sock} }

1;
__END__

=pod
 
=encoding utf8

=head1 NAME

AnyEvent::SSH2 - 基于 AnyEvent 的 SSH2 的非阻塞事件驱动的实现

=head1 SYNOPSIS

对多台主机, 并行的远程执行一些命令.

    use AE;
    use AnyEvent::SSH2;

    my $ssh1 = AnyEvent::SSH2->new(
        'ip',
        user => 'root',
        pass => 'pass',
    );   
    
    my $ssh2 = AnyEvent::SSH2->new(
        'ip'
        user => 'root',
        pass => 'pass',
    );   
    
    my $cv = AE::cv;

    $cv->begin;
    $ssh1->send('sleep 5;hostname' => sub {
        my ($ssh,  $stdout, $stderr) = @_;
        print "$stdout";
        $cv->end;
    })->connect;  
    
    $cv->begin;
    $ssh2->send('sleep 1;hostname' => sub {
        my ($ssh,  $stdout, $stderr) = @_;
        print "$stdout";
        $cv->end;
    })->connect;  

    $cv->recv;

对同一个主机, 并行的执行多条命令...注意顺序并不固定, 任何一个命令先执行完都会先回调.

    use AnyEvent::SSH2;
    my $ssh = AnyEvent::SSH2->new(
        'ip'
        user => 'root',
        pass => 'pass',
    );   
    
    
    my $cv = AE::cv;
    $cv->begin;
    $ssh->send('sleep 5; echo 5' => sub {
        my ($ssh,  $stdout, $stderr) = @_;
        print "$stdout";
        $cv->end;
    });
    
    $cv->begin;
    $ssh->send('sleep 1; echo 1 ; uptime' => sub {
        my ($ssh,  $stdout, $stderr) = @_;
        print "$stdout";
        $cv->end;
    });
    
    $ssh->connect;  
    
    $cv->recv;

或者你可能想有一定层次, 根据前一条命令的条件来执行指定的命令.

    my $cv = AE::cv;
    $ssh->send('sleep 5; echo 5' => sub {
        my ($ssh,  $stdout, $stderr) = @_;
        print "$stdout";
        $ssh->send('sleep 1; echo 1 ; uptime' => sub {
            my ($ssh,  $stdout, $stderr) = @_;
            print "$stdout";
            $cv->send;
        });
    });
    
    $ssh->connect;  
    
    $cv->recv;

=head1 DESCRIPTION

这个模块是基于 Net::SSH::Perl 实现的在 AnyEvent 上的事件驱动的支持. 并不是使用的 Fork 的实现 (non-fork), 这是基于 socket 的原生事件驱动实现. 
可以同时异步的连接多个主机进行操作.  并且也可以支持同时对一个主机同时执行多条命令与根据前面结果然后在执行指定命令.

=head1 属性

默认对象 new 的时候需要提供连接的主机地址. 本对象的属性继承所有的 L<Net::SSH::Perl> 的属性. 并实现了下列这些

=head2 user 

提供用于远程连接的用户名. 如果不提供会默认使用当前用户.

=head2 pass 

提供用于远程连接的密码. 也支持 key 方式认证. 需要指定如下属性

    identity_files => ['/root/.ssh/id_rsa'],
    options => [
        'PubkeyAuthentication yes',
        'PasswordAuthentication no', # 可能你想关掉密码认证
    ],

=head1 方法

本对象所支持的方法如下

=head2 send

这个需要提供你要给远程执行的命令做为第一个参数, 第二个参数是命令执行完的回调函数. 
回调函数的第二个和第三个参数会别会是命令执行的标准输出和标准错误.

本方法可以重复设置, 都会一次性发给远程主机执行. 所以执行完会根据执行结果的速度, 会立即返回并调用回调.

=head2 connect

当上面的命令定义完了, 可以调用 connect 方法来运行整个事件.

=head1 SEE ALSO

L<AnyEvent>, L<Net::SSH::Perl>

=head1 AUTHOR

扶凯 fukai <iakuf@163.com>

=cut
