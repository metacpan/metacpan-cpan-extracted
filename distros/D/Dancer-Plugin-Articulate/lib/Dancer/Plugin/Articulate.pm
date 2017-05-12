package Dancer::Plugin::Articulate;
use strict;
use warnings;

use Dancer::Plugin;
use Articulate;
our $VERSION = '0.003';

=head1 NAME

Dancer::Plugin::Articulate - use Articulate in your Dancer App

=head1 SYNOPSIS

  use Dancer;
  use Dancer::Plugin::Articulate;
  my $app = articulate_app;
  $app->enable;
  dance;

  # in config.yml
  plugins:
    Articulate:
      components:
        framework: Articulate::FrameworkAdapter::Dancer1
      # Other Articulate config goes here

Creates an instance of L<Articulate> using your Dancer config, and
enables the app, declaring routes, etc. See L<Articulate> for how to
configure and use it, and L<Articulate::FrameworkAdapter::Dancer1> for
details of the integration between Dancer1 and Articulate.

=head1 SEE ALSO

=over

=item * L<Dancer2::Plugin::Articulate>

=item * L<Dancer::Plugins>

=item * L<Dancer::Config>

=item * L<Articulate::FrameworkAdapter::Dancer1>

=back

=cut

register articulate_app => sub {
  return Articulate->instance(plugin_setting);
};

register_plugin();

=head1 BUGS

Bugs should be reported to the L<github issue
tracker|https://github.com/pdl/Articulate/issues>. Pull Requests
welcome!

=head1 COPYRIGHT

Articulate is Copyright 2014-2015 Daniel Perrett. You are free to use
it subject to the same terms as perl: see the LICENSE file included in
this distribution for what this means.

=cut

1;
