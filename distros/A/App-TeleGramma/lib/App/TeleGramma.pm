package App::TeleGramma;
$App::TeleGramma::VERSION = '0.14';
# ABSTRACT: A modular Telegram Bot


use Mojo::Base 'Telegram::Bot::Brain';

use App::TeleGramma::Config;
use App::TeleGramma::PluginManager;
use App::TeleGramma::Plugin::Base;
use App::TeleGramma::Constants qw/:const/;

use feature 'say';

has 'config';
has 'plugins';
has 'token';

# prepare/read config
sub startup {
  my $self = shift;

  # prep config
  my $config_was_created = 0;
  $self->config(App::TeleGramma::Config->new);
  $self->config->create_if_necessary && do
    {
      say $self->config->config_created_message;
      $config_was_created = 1;
    };

  # prep plugins
  $self->plugins(App::TeleGramma::PluginManager->new(config => $self->config, app => $self));
  $self->plugins->load_plugins;

  exit 0 if $config_was_created;

  # load token
  $self->config->read;
  $self->token($self->config->config->{_}->{bot_token});

}

sub bail_if_misconfigured {
  my $self = shift;

  if (! $self->token) {
    die "config file does not have a bot token - bailing out\n";
  }

  if ($self->token =~ /please/i) {
    die "config file has the default bot token - bailing out\n";
  }
}

sub init {
  my $self = shift;

  # add a listener which will pass every message to each listen plugin
  $self->add_listener(
    sub { 1 },  # everything matches
    \&incoming_message
  );

}

sub incoming_message {
  my $self = shift;
  my $msg  = shift;

  # pass it to all registered plugin listeners
  foreach my $listener (@{ $self->plugins->listeners }) {
    # call each one
    my $res = $listener->process_message($msg);
    if (! $res) {
      warn "listener did not provide a response";
      next;
    }
    if (($res eq PLUGIN_NO_RESPONSE_LAST) ||
        ($res eq PLUGIN_RESPONDED_LAST)) {
          last;
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TeleGramma - A modular Telegram Bot

=head1 VERSION

version 0.14

=head1 SYNOPSIS

Install App::TeleGramma and its dependencies

   $ cpanm App::TeleGramma

The first time run, a basic configuration file is automatically created for you.

   $ telegramma
   Your new config has been created in /Users/username/.telegramma/telegramma.ini

   Please edit it now and update the Telegram Bot token, then
   re-run bin/telegramma.

   The configuration will have an entry for each plugin currently available on
   your system, but disabled.

Edit the config file, adding (at least) the Telegram Bot API key. You can get
an API key from the @botfather bot on Telegram.

Now you can run, first in foreground mode for testing purposes:

   $ telegramma --nodaemon

When it's all good, you'll want to run it as a daemon:

   $ telegramma

You can monitor the status of the running process, and shut it down.

   $ telegramma --status

   $ telegramma --shutdown

=head1 DESCRIPTION

TeleGramma is an easy to use, extensible bot to use with Telegram C<www.telegram.org>.

Its plugin architecture makes it easy to add new modules either from other authors,
or yourself.

=head1 NAME

App::TeleGramma - A modular Telegram Bot

=head1 BUGS

None known.

=head1 AUTHOR

Justin Hawkins C<justin@eatmorecode.com>

=head1 SEE ALSO

L<Telegram::Bot> - the lower level API

=head1 AUTHOR

Justin Hawkins <justin@hawkins.id.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins <justin@eatmorecode.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
