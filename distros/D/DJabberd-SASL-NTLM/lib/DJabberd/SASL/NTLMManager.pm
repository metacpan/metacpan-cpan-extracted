package DJabberd::SASL::NTLMManager;

use strict;
use warnings;
use MIME::Base64 qw/encode_base64 decode_base64/;
use POSIX ":sys_wait_h";
use Carp;
our $logger = DJabberd::Log->get_logger();

sub new {
    my $class  = shift;
    my $plugin = shift;
    return bless { __plugin => $plugin }, $class;
}

sub server_start {
    my $self = shift;
    my $init = shift;
    my $cb   = shift;
    $self->{state} = "start";
    $logger->info("server start");
    &$cb("1");
}

sub need_step {
    my $self = shift;
    $logger->info("need step");
}

sub server_step {

    my $self     = shift;
    my $response = shift;
    my $cb       = shift;
    my ( $code, $reply, $data );
    my $plugin = $self->{__plugin};
    my $in     = $plugin->{in};
    my $out    = $plugin->{out};
    my $s      = $plugin->{s};

    $logger->info( "server step: " . $self->{state} );
    if ( waitpid( $plugin->{pid}, WNOHANG ) > 0 ) {
        $logger->info("ntlm_auth die");
        &invoke_ntlm_auth($plugin);
        &$cb;
        return;
    }

    if ( $self->{state} eq "start" ) {
        $self->{state} = "challenge";
        $response = encode_base64( $response, '' );
        print $out "YR $response\n";
        if ( $s->can_read(2) ) {
            unless ( sysread $in, $data, 16 ) {
                &$cb(undef);
                return;
            }
            $reply = $data;
            while ( $s->can_read(0) ) {
                last unless ( sysread $in, $data, 16 );
                $reply .= $data;
            }
        }
        else {
            $logger->warn("no reply after 2 sec");
            &rip_child($plugin);
            &$cb(undef);
            return;
        }
        ( $code, $reply ) = split( /\s+/, $reply );
        if ( $code ne "TT" ) {
            $self->{error} = "internal ntlmhelper error";
            $logger->warn("receive: $code $reply");
            $logger->warn( $self->{error} );
            $reply = undef;
        }
        else {
            $reply = decode_base64($reply);
        }
        &$cb($reply);
    }
    elsif ( $self->{state} eq "challenge" ) {
        $response = encode_base64( $response, '' );
        print $out "KK $response\n";
        if ( $s->can_read(2) ) {
            unless ( sysread $in, $data, 16 ) {
                &$cb;
                return;
            }
            $reply = $data;
            while ( $s->can_read(0) ) {
                last unless ( sysread $in, $data, 16 );
                $reply .= $data;
            }
        }
        else {
            $logger->warn("no reply after 2 sec");
            &rip_child($plugin);
            &$cb;
            return;
        }
        ( $code, $reply ) = split( /\s+/, $reply );
        if ( $code eq "AF" ) {
            $plugin->{user}  = lc $reply;
            $self->{success} = 1;
        }
        elsif ( $code eq "NA" ) {
            $self->{error} = "no match, " . $reply;
            $logger->warn( $self->{error} );
        }
        else {
            $self->{error} = "internal ntlmhelper error";
            $logger->warn( $self->{error} );
        }
        &$cb;
    }
}

sub rip_child {
    my $plugin = shift;

    #close $plugin->{in};
    #close $plugin->{out};
    kill 15, $plugin->{pid};
}

sub invoke_ntlm_auth {
    use IPC::Open3;
    use IO::Select;

    my $plugin = shift;
    $plugin->{err} = 1;
    $plugin->{pid} =
      open3( $plugin->{out}, $plugin->{in}, $plugin->{err}, $plugin->{helper},
        @{ $plugin->{params} } );
    $plugin->{s} = IO::Select->new();
    $plugin->{s}->add( $plugin->{in} );

    croak "Can't open bidirectional pipe to NTLM helper"
      unless ( $plugin->{pid} );
}

sub mechanism  { }
sub server_new { $_[0] }
sub is_success { $_[0]->{success} }
sub error      { $_[0]->{error} }
sub answer     { $_[0]->{__plugin}{user} }
sub property   { }

sub authenticated_jid { $_[0]->{jid} }
sub set_authenticated_jid { $_[0]->{jid} = $_[1] }

sub is_mechanism_supported { "NTLM" }

1;
