package App::Slackeria::PluginLoader;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

sub new {
	my ( $obj, %conf ) = @_;

	my $ref = {};

	return bless( $ref, $obj );
}

sub load {
	my ( $self, $plugin, %conf ) = @_;
	my $obj;
	eval sprintf(
		'use App::Slackeria::Plugin::%s;'
		  . '$obj = App::Slackeria::Plugin::%s->new(%%conf);',
		( ucfirst($plugin) ) x 2,
	);
	if ($@) {
		print STDERR "Cannot load plugin ${plugin}:\n$@\n";
	}
	else {
		$self->{plugin}->{$plugin} = $obj;
	}

	return;
}

sub list {
	my ($self) = @_;

	my @list = sort keys %{ $self->{plugin} };

	return @list;
}

sub run {
	my ( $self, $name, $conf ) = @_;

	if ( $self->{plugin}->{$name} ) {
		return $self->{plugin}->{$name}->run($conf);
	}

	return;
}

1;

__END__

=head1 NAME

App::Slackeria::PluginLoader - Plugin wrapper for App::Slackeria

=head1 SYNOPSIS

    use App::Slackeria::PluginLoader;

    my $plugin = App::Slackeria::PluginLoader->new();
    my $result;

    $plugin->load('CPAN', %cpan_default_conf);

    $result->{slackeria}->{CPAN} = $plugin->run('CPAN', {
            name => 'App-Slackeria',
            # further slackeria-specific configuration (if needed)
    });

    # $result->{slackeria}->{CPAN} is like:
    # {
    #     ok => 1,
    #     data => 'v0.1',
    #     href => 'http://search.cpan.org/dist/App-Slackeria/'
    # }

=head1 VERSION

version 0.12

=head1 DESCRIPTION

B<App::Slackeria::PluginLoader> loads and executes a number of B<slackeria>
plugins.  It also makes sure that any errors in plugins are catched and do not
affect the code using B<App::Slackeria::PluginLoader>.

=head1 METHODS

=over

=item $plugin = App::Slackeria::PluginLoader->new()

Returns a new App::Slackeria::PluginLoader object.  Does not take any arguments.

=item $plugin->load(I<plugin>, I<%conf>)

Create an internal App::Slackeria::Plugin::I<plugin> object by using it and
calling App::Slackeria::Plugin::I<plugin>->new(I<%conf>).  If I<plugin> does not
exist or fails during setup, B<load> prints an error message to STDERR.

=item $plugin->list()

Returns an array containing the names of all loaded plugins.

=item $plugin->run(I<plugin>, I<$conf_ref>)

Calls the B<run> method of I<plugin>:
$plugin_object->run(I<$conf_ref>).

If I<plugin> exists and is loaded, it returns the output of the run method,
otherwise undef.

=back

=head1 DEPENDENCIES

None.

=head1 SEE ALSO

slackeria(1), App::Slackeria::Plugin(3pm).

=head1 AUTHOR

Copyright (C) 2011 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

  0. You just DO WHAT THE FUCK YOU WANT TO.
