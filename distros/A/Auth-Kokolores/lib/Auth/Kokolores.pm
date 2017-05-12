package Auth::Kokolores;
 
use strict;
use base qw(Net::Server::PreFork);

# ABSTRACT: an alternative saslauthd
our $VERSION = '1.01'; # VERSION

use Auth::Kokolores::Config;
use Auth::Kokolores::Request;
use Auth::Kokolores::Response;
use Auth::Kokolores::Plugins;
use Auth::Kokolores::Protocol::CyrusSaslauthd;
use Auth::Kokolores::Protocol::DovecotAuth;

use Getopt::Long;

sub print_usage {
  print "$0 [-h|--help] [-c|--config=<file>] [-f|--foreground] [-l|--loglevel=<level>]\n";
  return;
}
 
sub configure {
  my $self = shift;
  my $server = $self->{'server'};

  return if(@_);

  if( ! defined $server->{'config_file'} ) {
    $server->{'config_file'} = '/etc/kokolores/kokolores.conf';
  }
  $self->{'program_name'} = $0;

  $server->{'background'} = 1;
  $server->{'setsid'} = 1;
  $server->{'no_close_by_child'} = 1;

  # commandline options
  my $cmdline = {};
  GetOptions( $cmdline,
    "help|h",
    "config|c:s",
    "foreground|f",
    "loglevel|l:i",
  );
  if ($cmdline->{'help'}) {
    $self->print_usage;
    exit 0;
  }
  if (defined($cmdline->{'config'}) && $cmdline->{'config'} ne "") {
    $server->{'config_file'} = $cmdline->{'config'};
  }

  # read and apply configuration file
  my $config = Auth::Kokolores::Config->new_from_file( $server->{'config_file'} );
  $config->apply_config( $self );

  $server->{'port'} = $self->{'socket_path'}.'|unix';

  $self->{'plugins'} = Auth::Kokolores::Plugins->new_from_config( $self, $config->Plugin );

  # cmdline values which overwrite config/defaults
  if ($cmdline->{'foreground'}) {
      $server->{'background'} = undef;
      $server->{'setsid'} = undef;
      $server->{'log_file'} = undef;
  }
  if( $cmdline->{'loglevel'} ) {
    $server->{'log_level'} = $cmdline->{'loglevel'};
  }

  return;
}

sub post_configure_hook {
  my $self = shift;
  $self->{'plugins'}->init( $self );
  return;
}

sub post_bind_hook {
  my $self = shift;
  $self->_set_process_stat('master');
  $self->set_socket_permissions;
  return;
}

sub set_socket_permissions {
  my $self = shift;
  if( ! defined $self->{'socket_mode'} ) {
    return;
  }
  my $mode = oct($self->{'socket_mode'});

  $self->log(2, sprintf('setting socket mode to: %o', $mode));
  chmod( $mode, $self->{'socket_path'} )
    or $self->log(1, 'could not change mode of socket: '.$!);
  
  return;
}

sub child_init_hook {
  my $self = shift;
  $self->{'plugins'}->child_init( $self );
  $self->_set_process_stat('virgin child');
  return;
}

sub child_finish_hook {
  my $self = shift;
  $self->{'plugins'}->shutdown( $self );
  return;
}

sub authenticate {
  my ( $self, $r ) = @_;
  my $failed = 0;

  foreach my $plugin ( $self->{'plugins'}->all_plugins ) {
    my $ok = $plugin->authenticate( $r );
    if( ! defined $ok ) {
      $self->log(3, 'plugin '.$plugin->name.': next');
      next;
    } elsif( $ok && $self->{'satisfy'} eq 'any' ) {
      $self->log(3, 'plugin '.$plugin->name.': success (any)');
      return Auth::Kokolores::Response->new_success;
    } elsif( !$ok && $self->{'satisfy'} ne 'any' ) {
      $self->log(3, 'plugin '.$plugin->name.': failed (all)');
      return Auth::Kokolores::Response->new_fail;
    } elsif( $ok ) {
      $self->log(3, 'plugin '.$plugin->name.': success');
    } else {
      $self->log(3, 'plugin '.$plugin->name.': failed');
      $failed++;
    }
  }

  if( $failed == 0 ) {
    return Auth::Kokolores::Response->new_success;
  }
  return Auth::Kokolores::Response->new_fail;
}

sub pre_process_kokolores_request {
  my ( $self, $r ) = @_;

  foreach my $plugin ( $self->{'plugins'}->all_plugins ) {
    my $pre_response = $plugin->pre_process( $r );
    if( defined $pre_response ) {
      return $pre_response;
    }
  }

  return;
}

sub post_process_kokolores_request {
  my ( $self, $r, $response ) = @_;

  foreach my $plugin ( $self->{'plugins'}->all_plugins ) {
    my $post_response = $plugin->post_process( $r, $response );
    if( defined $post_response ) {
      return $post_response;
    }
  }

  return;
}
 
sub process_kokolores_request {
  my ( $self, $r ) = @_;

  my $pre_response = $self->pre_process_kokolores_request( $r );
  if( defined $pre_response ) {
    # if there is a response from a pre_process object
    # return with this response
    return $pre_response;
  }

  my $response = $self->authenticate( $r );

  my $post_response = $self->post_process_kokolores_request( $r, $response );
  if( defined $post_response ) {
    return $post_response;
  }

  return $response;
}

sub get_protocol_handler {
  my ( $self, $conn, $port ) = @_;
  # TODO: make this configurable per socket
  my $protocol = $self->{'protocol'};
  my $protocol_class = "Auth::Kokolores::Protocol::".$protocol;
  return $protocol_class->new(
    server => $self,
    handle => $conn,
  );
}

sub process_request {
  my ( $self, $conn ) = @_;
  my $port = $conn->NS_port;
  $self->log(4, "accepted new client on port $port");

  my $protocol = $self->get_protocol_handler( $conn, $port );
  $protocol->init_connection;

  $self->_set_process_stat('waiting request');
  my $r = $protocol->read_request;

  $self->_set_process_stat('processing request');

  my $response;
  eval { $response = $self->process_kokolores_request( $r ); };
  if( $@ ) {
    $self->log(1, 'processing request failed: '.$@);
    return;
  }
  $protocol->write_response( $response );

  $protocol->shutdown_connection;
  $self->_set_process_stat('idle');
  return;
}

sub _set_process_stat {
  my ( $self, $stat ) = @_;
  $0 = $self->{'program_name'}.' ('.$stat.')';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::Kokolores - an alternative saslauthd

=head1 VERSION

version 1.01

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
