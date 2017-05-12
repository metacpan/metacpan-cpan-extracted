package Auth::Kokolores::Plugins;

use Moose;

our $VERSION = '1.01'; # VERSION
# ABSTRACT: class for handling kokolores plugins

has 'plugins' => (
	is => 'ro',
	isa => 'ArrayRef[Auth::Kokolores::Plugin]',
	default => sub { [] },
	traits => [ 'Array' ],
	handles => {
		'add_plugin' => 'push',
		'all_plugins' => 'elements',
		'num_plugins' => 'count',
	}
);

has 'plugin_prefix' => (
	is => 'ro', isa => 'Str', default => 'Auth::Kokolores::Plugin::',
);

sub init {
  my ( $self, $server ) = @_;
  foreach my $p ( $self->all_plugins ) {
    $server->log(4, 'initializing plugin '.$p->name.'...');
    $p->init(@_);
  }
  return;
}

sub child_init {
  my ( $self, $server ) = @_;
  foreach my $p ( $self->all_plugins ) {
    $server->log(4, 'in-child initialization of plugin '.$p->name.'...');
    $p->child_init(@_);
  }
  return;
}

sub shutdown {
  my ( $self, $server ) = @_;
  foreach my $p ( $self->all_plugins ) {
    $server->log(4, 'shuting down plugin '.$p->name.'...');
    $p->shutdown(@_);
  }
  return;
}

sub load_plugin {
	my ( $self, $plugin_name, $params ) = @_;
	if( ! defined $params->{'module'} ) {
		die('no module defined for plugin '.$plugin_name.'!');
	}
	my $module = $params->{'module'};
	my $plugin_class = $self->plugin_prefix.$module;
	my $plugin;

	my $code = "require ".$plugin_class.";";
	eval $code; ## no critic (ProhibitStringyEval)
	if($@) {
    die('could not load module '.$module.' for plugin '.$plugin_name.': '.$@);
  }

	eval {
    $plugin = $plugin_class->new(
      name => $plugin_name,
      %$params,
    );
    $plugin->init();
  };
  if($@) {
    die('could not initialize plugin '.$plugin_name.': '.$@);
  }
	$self->add_plugin($plugin);

	return;
}

sub new_from_config {
	my ( $class, $server, $config ) = @_;

	my $self = $class->new();

	if( ! defined $config ) {
		return( $self );
	}
	if( ref($config) ne 'HASH' ) {
		die('config must be an hashref!');
	}

	foreach my $plugin_name ( keys %{$config} ) {
		$self->load_plugin(
      $plugin_name, {
        server => $server,
			  %{$config->{$plugin_name}},
      },
    );
	}
  $server->log(2, 'loaded '.$self->num_plugins.' plugins...');

	return $self;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::Kokolores::Plugins - class for handling kokolores plugins

=head1 VERSION

version 1.01

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
