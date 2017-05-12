package DJabberd::SASL::NTLM;

use strict;
use warnings;
use base qw/DJabberd::SASL/;
use IPC::Open3;
use IO::Select;
use Carp;

our $VERSION = '0.03';

sub manager_class { 'DJabberd::SASL::NTLMManager' }

sub mechanisms {
    my $plugin = shift;
    return { NTLM => 1 };
}

sub set_config_ntlmauthhelper {
    my ( $self, $val ) = @_;
    $val =~ s/^\s*\b(.+)\b\s*$/$1/;
    my ( $ntlmauthhelper, @params ) = split( /\s+/, $val );
    croak "Invalid NTLM helper: $ntlmauthhelper"
      unless ( -f $ntlmauthhelper && -x $ntlmauthhelper );
    $self->{err} = 1;    # set STDERR for child
    $self->{pid} =
      open3( $self->{out}, $self->{in}, $self->{err}, $ntlmauthhelper,
        @params );
    $self->{s} = IO::Select->new();
    $self->{s}->add( $self->{in} );
    $self->{helper} = $ntlmauthhelper;
    $self->{params} = [@params];

    croak "Can't open bidirectional pipe to NTLM helper"
      unless ( $self->{pid} );
}

## XXX dupe sux
sub register {
    my ( $plugin, $vhost ) = @_;
    $plugin->SUPER::register($vhost);

    $vhost->register_hook(
        "SendFeatures",
        sub {
            my ( $vh, $cb, $conn ) = @_;
            if ( my $sasl_conn = $conn->sasl ) {
                if ( $sasl_conn->is_success ) {
                    return;
                }
            }
            my @mech = $plugin->mechanisms_list;
            my $xml_mechanisms =
              "<mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'>";
            $xml_mechanisms .= join "",
              map { "<mechanism>$_</mechanism>" } @mech;
            $xml_mechanisms .= "<optional/>" if $plugin->is_optional;
            $xml_mechanisms .= "</mechanisms>";
            $cb->stanza($xml_mechanisms);
        }
    );
}

1;
__END__

=head1 NAME

DJabberd::SASL::NTLM - NTLM SASL Auth plugin 

=head1 SYNOPSIS

    <Plugin DJabberd::SASL::NTLM>
        Optional   yes
        NTLMAuthHelper /usr/bin/ntlm_auth --helper-protocol=squid-2.5-ntlmssp
    </Plugin>

=head1 DESCRIPTION

Plugin that allow NTLM authentification using samba ntlm_auth helper through winbind

=cut
