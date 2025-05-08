package Class::Debug;

use strict;
use warnings;

use Carp;
use Config::Abstraction 0.20;
use Log::Abstraction 0.11;

=head1 NAME

Class::Debug - Add Runtime Debugging to a Class

=head1 VERSION

0.02

=cut

our $VERSION = 0.02;

=head1 SYNOPSIS

The C<Class::Debug> module is a lightweight utility designed to inject runtime debugging capabilities into other classes,
primarily by layering configuration and logging support.

Add this to your constructor:

   use Class::Debug;
   use Params::Get;

   sub new {
   	my $class = shift;
	my $params = Params::Get(undef, \@_);

	$params = Class::Debug::setup($class, $params);

	return bless $params, $class;
    }

=head1 SUBROUTINES/METHODS

=head2 setup

Configure your class for runtime debugging.

Takes two arguments:

=over 4

=item * C<class>

=item * C<params>

A hashref containing default parameters to be used in the constructor.

=back

Returns the new values for the constructor.

Now you can set up a configuration file and environment variables to debug your module.

=cut

sub setup
{
	my $class = shift;
	my $params = shift;

	# Load the configuration from a config file, if provided
	if(exists($params->{'config_file'})) {
		# my $config = YAML::XS::LoadFile($params->{'config_file'});
		my $config_dirs = $params->{'config_dirs'};
		if((!$config_dirs) && (!-r $params->{'config_file'})) {
			croak("$class: ", $params->{'config_file'}, ': File not readable');
		}

		if(my $config = Config::Abstraction->new(config_dirs => $config_dirs, config_file => $params->{'config_file'}, env_prefix => "${class}::")) {
			$params = $config->merge_defaults(defaults => $params, section => $class);
		} else {
			croak("$class: Can't load configuration from ", $params->{'config_file'});
		}
	} elsif(my $config = Config::Abstraction->new(env_prefix => "${class}::")) {
		$params = $config->merge_defaults(defaults => $params, section => $class);
	}

	# Load the default logger, which may have been defined in the config file or passed in
	if(my $logger = $params->{'logger'}) {
		if((ref($logger) eq 'HASH') && $logger->{'syslog'}) {
			$params->{'logger'} = Log::Abstraction->new(carp_on_warn => 1, syslog => $logger->{'syslog'});
		} else {
			$params->{'logger'} = Log::Abstraction->new(carp_on_warn => 1, logger => $logger);
		}
	} else {
		$params->{'logger'} = Log::Abstraction->new(carp_on_warn => 1);
	}

	return $params;
}

=head1 SEE ALSO

=over 4

=item * L<Config::Abstraction>

=item * L<Log::Abstraction>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-class-debug at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Debug>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Class::Debug

You can also look for information at:

=cut

1;
