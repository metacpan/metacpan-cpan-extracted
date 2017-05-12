package App::SmokeBox::Mini::Plugin::IRC;
{
  $App::SmokeBox::Mini::Plugin::IRC::VERSION = '0.12';
}

#ABSTRACT: IRC plugin for minismokebox

use strict;
use warnings;
use POE qw[Component::IRC Component::IRC::Plugin::Connector Component::IRC::Plugin::CTCP];
use POE::Component::IRC::Common qw[u_irc];

sub init {
  my $package = shift;
  my $config  = shift;
  return unless $config and ref $config eq 'Config::Tiny';
  return unless $config->{IRC};
  return unless $config->{IRC}->{server};
  my $heap = $config->{IRC};
  POE::Session->create(
     package_states => [
        __PACKAGE__, [qw(_start _start_up irc_registered irc_001 irc_join sbox_smoke sbox_stop sbox_perl_info)],
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
  $heap->{nick} = $^O . $$ unless $heap->{nick};
  my $irc = POE::Component::IRC->spawn(
    ( map { ( $_, $heap->{$_} ) } grep { exists $heap->{$_} } qw(server nick ircname username port password) ),
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

sub irc_join {
  my ($kernel,$heap,$sender) = @_[KERNEL,HEAP,SENDER];
  my $map = $heap->{_irc}->isupport('CASEMAPPING');
  my $unick = u_irc( ( split /!/, $_[ARG0] )[0], $map );
  my $chan = $_[ARG1];
  return unless $unick eq u_irc( $heap->{_irc}->nick_name(), $map );
  return unless $heap->{_msg};
  $kernel->post( $sender, 'privmsg', $chan, $heap->{_msg} );
  return;
}

sub _get_channels {
  my $channels = shift;
  my @channels;
  unless ( $channels ) {
    push @channels, '#smokebox';
  }
  else {
    push @channels, split(/\,/, $channels);
  }
  return @channels;
}

sub sbox_perl_info {
  my ($kernel,$heap,$vers,$arch,$osvers) = @_[KERNEL,HEAP,ARG0,ARG1,ARG2];
  my $message = "Smoking v$vers built for $arch $osvers";
  $heap->{_msg} = $message;
  $heap->{_irc}->yield( 'privmsg', $_, $message ) for _get_channels( $heap->{channels} );
  $heap->{_irc}->plugin_add( 'CTCP',
    POE::Component::IRC::Plugin::CTCP->new(
      version  => $message,
      userinfo => $message,
    )
  );
  return;
}

sub sbox_smoke {
  my ($kernel,$heap,$data) = @_[KERNEL,HEAP,ARG0];
  my $dist = $data->{job}->module();
  my ($result) = $data->{result}->results;
  my $message = "Distribution: '$dist' finished with status '$result->{status}'";
  $heap->{_irc}->yield( 'privmsg', $_, $message ) for _get_channels( $heap->{channels} );
  return;
}

sub sbox_stop {
  my ($kernel,$heap,@stats) = @_[KERNEL,HEAP,ARG0..$#_];
  $kernel->refcount_decrement( $_[SESSION]->ID(), __PACKAGE__ );
  $heap->{_irc}->yield( 'privmsg', $_, 'Smoker finished: ' . join(',', @stats) ) for
    _get_channels( $heap->{channels} );
  $heap->{_irc}->delay( [ 'shutdown' ], 5 );
  return;
}

qq[Smokey IRC];

__END__

=pod

=head1 NAME

App::SmokeBox::Mini::Plugin::IRC - IRC plugin for minismokebox

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  # example minismokebox configuration file

  [IRC]

  server = my.irc.server
  nick = mysmoker

=head1 DESCRIPTION

App::SmokeBox::Mini::Plugin::IRC is an IRC plugin for L<App::SmokeBox::Mini> and
L<minismokebox> that announces on IRC channels when smoke jobs finish and when
L<minismokebox> itself finishes.

Configuration is handled by a section in the L<minismokebox> configuration file.

When L<minismokebox> starts a bot will join configured channels and start announcing
completed smoke jobs. When the smoke run finishes the bot will announce statistics
relating to the smoke run and then terminate.

=for Pod::Coverage   ^irc|sbox|init

=head1 CONFIGURATION

This plugin uses an C<[IRC]> section within the L<minismokebox> configuration file.

The only mandatory required parameter is C<server>.

=over

=item C<server>

Specify the name or IP address of an ircd to connect to. Mandatory.

=item C<nick>

The nickname to use. Defaults to $^O plus $$.

=item C<port>

The ircd port to connect to. Defaults to C<6667>.

=item C<ircname>

Some cute comment or something.

=item C<username>

Your client's username.

=item C<password>

The password that is required if your ircd is restricted.

=item C<channels>

A comma-separated list of IRC channels to join, default is C<#smokebox>

=back

=head1 SEE ALSO

L<minismokebox>

L<App::SmokeBox::Mini::Plugin>

=head1 AUTHOR

Chris Williams

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
