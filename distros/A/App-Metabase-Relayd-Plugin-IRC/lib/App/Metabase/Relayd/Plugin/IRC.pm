package App::Metabase::Relayd::Plugin::IRC;
$App::Metabase::Relayd::Plugin::IRC::VERSION = '0.08';
# ABSTRACT: IRC plugin for metabase-relayd

use strict;
use warnings;
use POE qw(Component::IRC Component::IRC::Plugin::Connector);

sub init {
  my $package = shift;
  my $config  = shift;
  return unless $config and ref $config eq 'Config::Tiny';
  return unless $config->{IRC};
  return unless $config->{IRC}->{server};
  my $heap = $config->{IRC};
  POE::Session->create(
     package_states => [
        __PACKAGE__, [qw(_start _start_up irc_registered irc_001 mbrd_received)],
     ],
     heap => $heap,
  );
}

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $kernel->refcount_increment( $_[SESSION]->ID(), __PACKAGE__ );
  $kernel->yield( '_start_up' );
  return;
}

sub _start_up {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{nick} = 'relayd' . $$ unless $heap->{nick};
  my $irc = POE::Component::IRC->spawn(
    ( map { ( $_, $heap->{$_} ) } grep { exists $heap->{$_} } qw(server nick ircname username port password flood) ),
  );
  $heap->{_irc} = $irc;
  return;
}

sub irc_registered {
  my ($kernel,$heap,$irc) = @_[KERNEL,HEAP,ARG0];
  $irc->plugin_add( 'Connector', POE::Component::IRC::Plugin::Connector->new() );
  $irc->yield( 'connect', { } );
  return;
}

sub irc_001 {
  my ($kernel,$heap,$sender) = @_[KERNEL,HEAP,SENDER];
  $kernel->post( $sender, 'join', $_ ) for _get_channels( $heap->{channels} );
  return;
}

sub _get_channels {
  my $channels = shift;
  my @channels;
  unless ( $channels ) {
    push @channels, '#relayd';
  }
  else {
    push @channels, map { ( /^\#/ ? $_ : "#$_" ) } split(/\,/, $channels);
  }
  return @channels;
}

sub mbrd_received {
  my ($kernel,$heap,$data,$ip) = @_[KERNEL,HEAP,ARG0,ARG1];
  use Time::Piece;
  my $stamp = '[ ';
  {
    my $t = localtime;
    $stamp .= join ' ', $ip, $t->strftime("%Y-%m-%dT%H:%M:%S");
  }
  $stamp .= ' ]';
  my $t = localtime; my $ts = $t->strftime("%Y-%m-%dT%H:%M:%S");
  my $msg = join(' ', uc($data->{grade}), ( map { $data->{$_} } qw(distfile archname osversion) ), "perl-" . $data->{perl_version}, $stamp );
  $heap->{_irc}->yield( 'privmsg', $_, $msg ) for _get_channels( $heap->{channels} );
  return;
}


qq[Smokey IRC];

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Metabase::Relayd::Plugin::IRC - IRC plugin for metabase-relayd

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  # example metabase-relayd configuration file

  [IRC]

  server = my.irc.server
  nick = myrelayd

=head1 DESCRIPTION

App::Metabase::Relayd::Plugin::IRC is an IRC plugin for L<App::Metabase::Relayd> and
L<metabase-relayd> that announces on IRC channels when reports are received by the daemon.

Configuration is handled by a section in the L<metabase-relayd> configuration file.

When L<metabase-relayd> starts a bot will join configured channels and start announcing
reports that it has received.

=for Pod::Coverage   init
  irc_registered
  irc_001
  mbrd_received

=head1 CONFIGURATION

This plugin uses an C<[IRC]> section within the L<metabase-relayd> configuration file.

The only mandatory required parameter is C<server>.

=over

=item C<server>

Specify the name or IP address of an ircd to connect to. Mandatory.

=item C<nick>

The nickname to use. Defaults to C<relayd> plus $$.

=item C<port>

The ircd port to connect to. Defaults to C<6667>.

=item C<ircname>

Some cute comment or something.

=item C<username>

Your client's username.

=item C<password>

The password that is required if your ircd is restricted.

=item C<channels>

A comma-separated list of IRC channels to join, default is C<#relayd>

=item C<flood>

Set to a C<true> value to disable anti-flood protection when sending stuff to
the ircd. Defaults to C<false> if not specified. Care should be used when enabling
this option and it requires the cooperation of a friendly irc oper to ensure that
disconnects and k-lines are not the side-effects of enabling this option.

=back

=head1 SEE ALSO

L<metabase-relayd>

L<App::Metabase::Relayd::Plugin>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
