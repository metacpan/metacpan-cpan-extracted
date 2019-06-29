package App::TeleGramma::PluginManager;
$App::TeleGramma::PluginManager::VERSION = '0.14';
# ABSTRACT: Plugin manager for the TeleGramma bot

use Mojo::Base -base;
use File::Spec::Functions qw/catdir/;

require Module::Pluggable;

has 'config';
has 'search_dirs' => sub { [catdir($ENV{HOME}, '.telegramma', 'plugins')] };
has 'list' => sub { [] };
has 'listeners' => sub { [] };
has 'app';

sub load_plugins {
  my $self = shift;
  $self->list([]);

  Module::Pluggable->import(
    search_path => ['App::TeleGramma::Plugin'],
    search_dirs => $self->search_dirs,
    require     => 1,
    except      => [qw/App::TeleGramma::Plugin::Base/]
  );

  foreach my $p ($self->plugins) {
    if (! $p->check_prereqs()) {
      warn "$p - failed prereq check\n";
    }

    # instantiate it
    my $o = $p->new(app_config => $self->config, app => $self->app);
    $o->create_default_config_if_necessary;

    if ($o->read_config->{enable} =~ /yes/i) {

      # register it
      my @botactions = $o->register;
      foreach my $ba (@botactions) {
        if ($ba->can_listen) {
          push @{ $self->listeners }, $ba;
        }
      }

      # add it to our list of plugins
      push @{ $self->list }, $o;
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TeleGramma::PluginManager - Plugin manager for the TeleGramma bot

=head1 VERSION

version 0.14

=head1 AUTHOR

Justin Hawkins <justin@hawkins.id.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins <justin@eatmorecode.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
