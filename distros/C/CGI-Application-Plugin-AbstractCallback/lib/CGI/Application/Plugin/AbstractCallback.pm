package CGI::Application::Plugin::AbstractCallback;

use strict;
use warnings;

our $VERSION = '0.03';

use Carp;
use CGI::Application;

sub import {
	my $class = shift;
	my $hook = shift;
	
	my $caller = scalar caller;
	
	if (UNIVERSAL::isa($caller, 'CGI::Application') && defined $hook) {
		eval {
			no strict 'refs';
			# $caller->add_callback($hook, \&{$class . '::callback'});
			$caller->add_callback($hook, $class->can('callback'));
		};
		if ($@) {
			carp $@;
		}
	}
	else {
		carp "Invalid call from package is't a CGI::Application, or not defined hook $hook";
	}
}

sub callback {
	my CGI::Application $self = shift;
	my %args = @_;
	# no action
	# please override me
}

1;
__END__

=head1 NAME

CGI::Application::Plugin::AbstractCallback - This is the abstract method for externalizing callbacks

=head1 SYNOPSIS

	package MyApp::Plugin::MyInitCallback;
	
	use strict;
	use warnings;
	
	use base CGI::Application::Plugin::AbstractCallback;
	
	sub callback {
		# override me
	}
	1;
	
	package MyApp;
	
	use base qw|CGI::Application|;
	use MyApp::Plugin::MyInitCallback qw|init|; ## add init hook your callback
	
	1;

=head1 DESCRIPTION

This module is the abstract class for externalizing callbacks.
The callback defined in the child class( of this class)  is added in specified hook.

=head1 METHODS

=head2 callback()

This method is abstract, So you should implement and override the method as callback.

=head1 SEE ALSO

L<CGI::Application|CGI::Application>
perl(1)

=head1 AUTHOR

Toru Yamaguchi, E<lt>zigorou@cpan.orgE<gt>

=head1 THANKS

=over 4

=item Songhee Han

=back 4

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Toru Yamaguchi

This library is free software. You can modify and or distribute it under the same terms as Perl itself.

=cut