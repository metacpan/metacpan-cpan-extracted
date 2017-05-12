package Dancer2::Plugin::Articulate;
use strict;
use warnings;

use Dancer2::Plugin;
use Articulate;
our $VERSION = '0.002';

=head1 NAME

Dancer2::Plugin::Articulate - use Articulate in your Dancer2 App

=head1 SYNOPSIS

	# in config.yml
	plugins:
		Articulate:
			components:
				framework:
					Articulate::FrameworkAdapter::Dancer2:
						appname: MyApp
			# Other Articulate config goes here

Creates an instance of L<Articulate> using your Dancer2 config, and enables the app, declaring routes, etc.
See L<Articulate> for how to configure and use it, and L<Articulate::FrameworkAdapter::Dancer2> for details of the integration between Dancer2 and Articulate.

=head1 SEE ALSO

=over

=item * L<Dancer::Plugin::Articulate>

=item * L<Dancer2::Plugins>

=item * L<Dancer2::Config>

=item * L<Articulate::FrameworkAdapter::Dancer2>

=back

=cut

register articulate_app => sub {
	my $dsl = shift;
	Articulate->instance (plugin_setting);
}, { is_global => 1};

register_plugin for_versions => [2];

=head1 BUGS

Bugs should be reported to the L<github issue tracker|https://github.com/pdl/Articulate/issues>. Pull Requests welcome!

=head1 COPYRIGHT

Articulate is Copyright 2014-2015 Daniel Perrett. You are free to use it subject to the same terms as perl: see the LICENSE file included in this distribution for what this means.

=cut

1;
