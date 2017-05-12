package Catalyst::Plugin::AutoAssets;
use strict;
use warnings;

our $VERSION = '0.40';

use Moose::Role;
use namespace::autoclean;

use CatalystX::InjectComponent;
use Catalyst::Controller::AutoAssets;

after setup_finalize => sub {
  my $c = shift;

  # New: Turn off new 'autoflush' flag in logger (see Catalyst::Log).
  # This is needed to surpress output of debug log messages for 
  # static requests (see no_log opt in Catalyst::Plugin::AutoAssets)
  $c->log->autoflush(0) if $c->log->can('autoflush');
};

after 'setup_components' => sub { (shift)->inject_asset_controllers(@_) };

sub inject_asset_controllers {
  my $c = shift;

  my $config = $c->config->{'Plugin::AutoAssets'} or return;
  my $assets = $config->{assets} or die "No 'assets' defined in 'Plugin::AutoAssets' config!";
  
  if (ref $assets eq 'HASH') {
    $c->_inject_single_asset_controller($_,$assets->{$_}) for (keys %$assets);
  }
  elsif (ref $assets eq 'ARRAY') {
    $c->_inject_single_asset_controller($_) for (@$assets);
  }
  else {
    die "'assets' must be a hashref or an arrayref";
  }
}

sub _inject_single_asset_controller {
  my ($c, $controller, $cfg) = @_;
  
  if(ref($controller)) {
    $cfg = { %$controller };
    $controller = delete $cfg->{controller} 
      or die "Bad asset config; 'controller' class not specified";
  }
  
  unless ($c->can('asset_controllers')) {
    $c->mk_classdata('asset_controllers');
    $c->asset_controllers([]);
  }
  my %seen = map {$_=>1} @{$c->asset_controllers};
  
  die "Duplicate asset controller '$controller'" if ($seen{$controller});
  
  push @{$c->asset_controllers}, $controller;
  
  $c->config( "Controller::$controller" => $cfg );
  
  CatalystX::InjectComponent->inject(
    into => $c,
    component => 'Catalyst::Controller::AutoAssets',
    as => $controller
  );
}

# Convenience method to get all configured html head tags of all the
# asset controllers at once:
sub all_html_head_tags {
  my $c = shift;
  return join("\r\n", map {
    $c->controller($_)->html_head_tags
  } @{$c->asset_controllers} );
}


1;

__END__

=pod

=head1 NAME

Catalyst::Plugin::AutoAssets - Plugin interface to L<Catalyst::Controller::AutoAssets>

=head1 SYNOPSIS

  use Catalyst;
  with 'Catalyst::Plugin::AutoAssets';
  
  # Inject/setup AutoAssets controllers: 
  #  * MyApp::Controller::Assets::ExtJS   (/assets/extjs)
  #  * MyApp::Controller::Assets::MyCSS   (/assets/mycss)
  __PACKAGE__->config(
    name => 'MyApp',
    'Plugin::AutoAssets' => {
      assets => {
        'Assets::ExtJS' => {
          type => 'Directory',
          include => 'ext-3.4.0',
          persist_state => 1,
          sha1_string_length => 15
        },
        'Assets::MyCSS' => {
          type => 'CSS',
          include => '/path/to/css',
          minify => 1
        }
      }
    }
  );
  
  # Or, using arrayref syntax (if order is important):
  __PACKAGE__->config(
    name => 'MyApp',
    'Plugin::AutoAssets' => {
      assets => [
        {
          controller => 'Assets::ExtJS',
          type => 'Directory',
          include => 'ext-3.4.0',
          persist_state => 1,
          sha1_string_length => 15
        },
        {
          controller => 'Assets::MyCSS',
          type => 'CSS',
          include => '/path/to/css',
          minify => 1
        },
        {
          controller => 'Assets::Icons',
          type => 'IconSet',
          include => 'root/static/icons'
        }
      ]
    }
  );

Optionally, within .tt files:

  <head>
    <!-- all html includes from all assets at once -->
    [% c.all_html_head_tags %]
  </head>

=head1 DESCRIPTION

This class provides a simple Catalyst Plugin interface to L<Catalyst::Controller::AutoAssets> for easy
setup of multiple AutoAssets controllers via config. To use, simply pass a hashref (or arrayref) of 'assets' into the 
config key 'Plugin::AutoAssets' in your Catalyst application config. This hash should contain controller 
class names in the keys and Catalyst::Controller::AutoAssets hash configs in the values. Each controller 
will be injected into your application at runtime.

This is just a faster setup than creating the controller classes manually. See L<Catalyst::Controller::AutoAssets>
for details and supported config params.

=head1 CONFIG PARAMS

=head2 assets

HashRef or ArrayRef of L<Catalyst::Controller::AutoAssets> configs. Defines the name of each controller to create
and the config to use. In HashRef form, the Controller name is specified in the keys with hashref config values.
ArrayRef form is a list of hashref configs with an extra key 'controller' to set the Controller name (removed from
the config before being passed into the Controller).

See the SYNOPSIS above for examples of both.

=head1 METHODS

=head2 all_html_head_tags

Convenience method concats the output of C<html_head_tags()> from all the AutoAssets controllers at once.

=head1 SEE ALSO

=over

=item L<Catalyst::Controller::AutoAssets>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
