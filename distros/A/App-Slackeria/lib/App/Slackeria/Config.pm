package App::Slackeria::Config;

use strict;
use warnings;
use 5.010;

use Config::Tiny;
use Carp;
use File::BaseDir qw(config_files);

our $VERSION = '0.12';

sub new {
	my ($obj) = @_;

	my $ref = {};

	return bless( $ref, $obj );
}

sub get {
	my ( $self, $name, $section ) = @_;
	$self->load($name);

	if ( $name ne 'config' ) {
		$self->{file}->{$name}->{$section}->{name} //= $name;
	}

	return $self->{file}->{$name}->{$section} // {};
}

sub load {
	my ( $self, $name ) = @_;
	my $file = config_files("slackeria/${name}");

	if ( defined $self->{file}->{$name} ) {
		return;
	}

	if ($file) {
		$self->{file}->{$name} = Config::Tiny->read($file);
	}
	else {
		$self->{file}->{$name} = {};
	}

	if ( $name eq 'config' ) {
		$self->{projects}
		  = [ split( / /, $self->{file}->{$name}->{slackeria}->{projects} ) ];
		delete $self->{file}->{$name}->{slackeria};
	}

	return;
}

sub projects {
	my ($self) = @_;

	$self->load('config');

	return @{ $self->{projects} };
}

sub plugins {
	my ($self) = @_;

	$self->load('config');

	return keys %{ $self->{file}->{config} };
}

1;

__END__

=head1 NAME

App::Slackeria::Config - Get config values for App::Slackeria and plugins

=head1 SYNOPSIS

    use App::Slackeria::Config;

    my $conf = App::Slackeria::Config->new();
    for my $name ($conf->plugins()) {
        my $plugin_conf = $conf->get('config', $name);
        # load plugin
    }
    for my $project ($conf->projects()) {
        for my $name ($conf->plugins()) {
            my $plugin_conf = $conf->get($project, $name);
            # run plugin
        }
    }

=head1 VERSION

version 0.12

=head1 DESCRIPTION

B<App::Slackeria::Config> uses Config::Tiny(3pm) to load config files.

=head1 METHODS

=over

=item $config = App::Slackeria::Config->new()

Returns a new App::Slackeria::Config object.  Does not take any arguments.

=item $config->get(I<$name>, I<$section>)

Returns a hashref containing the I<section> of the config file I<name>.  If
I<name> does not exist or does not contain I<section>, returns a reference to
an empty hash.  If I<name> is not B<config> and I<section> does not have a
B<name> field, sets B<name> to I<name> in the hashref.

=item $config->load(I<$name>)

Loads $XDG_CONFIG_HOME/slackeria/I<name> (defaulting to
~/.config/slackeria/I<name>) and saves its content internally. If the config
file does not exist, saves an empty hashref.

$config->get automatically calls this, so there should be no need for you to
use it.

=item $config->projects()

Returns an array of all projects, as listed in the B<projects> key in the
B<slackeria> section of the B<config> file.

=item $config->plugins()

Returns an array of all plugins, which is actually just a list of all
sections in the B<config> file.

=back

=head1 DEPENDENCIES

Config::Tiny, File::BaseDir.

=head1 SEE ALSO

slackeria(1)

=head1 AUTHOR

Copyright (C) 2011 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

  0. You just DO WHAT THE FUCK YOU WANT TO.
