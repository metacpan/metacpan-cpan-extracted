package App::TeleGramma::Config;
$App::TeleGramma::Config::VERSION = '0.14';
# ABSTRACT: TeleGramma and TeleGramma plugin configuration

use Mojo::Base -base;
use File::Spec::Functions qw/catdir/;
use Config::INI::Writer 0.025;
use Config::INI::Reader 0.025;

has config    => sub { {} };
has path_base => sub { catdir($ENV{HOME}, '.telegramma') };

sub path_config      { catdir(shift->path_base, 'telegramma.ini') }
sub path_plugins     { catdir(shift->path_base, 'plugins') }
sub path_logs        { catdir(shift->path_base, 'logs') }
sub path_plugin_data { catdir(shift->path_base, 'plugindata') }
sub path_pid         { catdir(shift->path_base, 'telegramma.pid') }

sub read {
  my $self = shift;
  $self->config( Config::INI::Reader->read_file( $self->path_config ) );
}

sub write {
  my $self = shift;
  Config::INI::Writer->write_file($self->config, $self->path_config);
}

sub default_config {
  [
    '_' => [ bot_token => 'please change me, see: https://telegram.me/BotFather' ],
  ],
}

sub create_if_necessary {
  my $self = shift;

  foreach my $path (
    $self->path_base,
    $self->path_plugins,
    $self->path_plugin_data,
    catdir($self->path_plugins, 'App'),
    catdir($self->path_plugins, 'App/TeleGramma'),
    catdir($self->path_plugins, 'App/TeleGramma/Plugin'),
    $self->path_logs ) {

    if (! -e $path) {
      mkdir $path, 0700 || die "cannot create $path: $!\n";
    }
    elsif (! -d $path) {
      die "$path is not a directory?\n";
    }
  }

  my $config_path = $self->path_config;
  if (! -e $config_path) {
    $self->create_default_config;
    return 1;
  }

  return 0;
}

sub create_default_config {
  my $self = shift;
  my $path = $self->path_config;

  Config::INI::Writer->write_file($self->default_config, $path);
  chmod 0600, $path;
}

sub config_created_message {
  my $self = shift;
  my $path = $self->path_config;

  return <<EOF
Your new config has been created in $path

Please edit it now and update the Telegram Bot token, then
re-run $0.

The configuration will have an entry for each plugin currently available on
your system, but disabled.
EOF
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TeleGramma::Config - TeleGramma and TeleGramma plugin configuration

=head1 VERSION

version 0.14

=head1 AUTHOR

Justin Hawkins <justin@hawkins.id.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins <justin@eatmorecode.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
