package App::CLI::Plugin::Log::Dispatch::Configurator::YAML;

use strict;
use warnings;
use base qw(Class::Accessor::Grouped);
use Log::Dispatch::Config;
use Log::Dispatch::Configurator::YAML;

__PACKAGE__->mk_group_accessors(inherited => "log");

our $VERSION = '1.1';

sub setup {

	my($self, @argv) = @_;
	my $config = Log::Dispatch::Configurator::YAML->new($self->config->{log_dispatch_configurator_yaml});
	Log::Dispatch::Config->configure($config);
	$self->log(Log::Dispatch::Config->instance);
	$self->maybe::next::method(@argv);
}

1;
__END__

=head1 NAME

App::CLI::Plugin::Log::Dispatch::Configurator::YAML - for App::CLI::Extension easy Log::Dispatch module

=head1 VERSION

1.1

=head1 SYNOPSIS

  # MyApp.pm
  package MyApp;
  
  use strict;
  use base qw(App::CLI::Extension);
  
  # extension method
  __PACKAGE__->load_plugins(qw(Log::Dispatch::Configurator::YAML));
  
  __PACKAGE__->config(log_dispatch_configurator_yaml => "/path/to/log.yml");
  
  1;
  
  # /path/to/log.yml
  dispatchers:
    - file
    - screen

  file:
    class: Log::Dispatch::File
    min_level: debug
    filename: /path/to/log
    mode: append
    newline: 1
    close_after_write: 1
    format: '[%d] [%p] %m'

  screen:
    class: Log::Dispatch::Screen
    min_level: debug
    stderr: 1
    newline: 1
    format: '%m'
  
  # MyApp/Hello.pm
  package MyApp::Hello;
  use strict;
  use feature ":5.10.0";
  use base qw(App::CLI::Command);
  
  sub run {
  
	my($self, @args) = @_;
	$self->log->info("hello");
	$self->log->error("fatal error");
	$self->log->debug("debug");
  }
  
  1;
  
  # execute
  cat /path/to/log
  [Tue Apr  6 00:58:05 2010] [info] hello
  [Tue Apr  6 00:58:05 2010] [error] fatal error
  [Tue Apr  6 00:58:05 2010] [debug] debug
  
=head1 DESCRIPTION

App::CLI::Plugin::Log::Dispatch::Configurator::YAML is App::CLI::Extension easy Log::Dispatch module

=head1 AUTHOR

Akira Horimoto E<lt>kurt0027@gmail.comE<gt>

=head1 SEE ALSO

L<App::CLI::Extension> L<Log::Dispatch::Configurator::YAML>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 COPYRIGHT

Copyright (C) 2010 Akira Horimoto

=cut
