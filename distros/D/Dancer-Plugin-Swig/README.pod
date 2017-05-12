use strict;
use warnings;
package Dancer::Plugin::Swig;
our $VERSION = '0.02';

use Dancer ':syntax';
use Dancer::Plugin;
use WebService::SwigClient;

my $swig_client;

register render => sub {
  my ($template_path, $params) = @_;
  $params ||= {};
  initialize() unless $swig_client;
  return $swig_client->render($template_path, $params);
};

sub reinitialize {
  undef $swig_client;
  initialize();
}

sub initialize {
  my %plugin_settings = %{ plugin_setting() };

  my $service_url = delete $plugin_settings{service_url};
  die "A service url is required in order to use this plugin" unless $service_url;

  $swig_client = WebService::SwigClient->new(service_url => $service_url);

  return;
}

register_plugin;
1;

=head1 NAME

Dancer::Plugin::Swig - A plugin for swig client

=head1 SYNOPSIS
In your Dancer config.yml:

  plugins:
      Swig:
          service_url: "http://localhost:21060"

In your Dancer application:

  package NewApp;
  use Dancer ':syntax';
  use Dancer::Plugin::Swig;

  our $VERSION = '0.1';

  get '/' => sub {
    render 'index.html', { hello_world => 'howdy' };
  };

  true;

=head1 DESCRIPTION

B<Dancer::Plugin::Swig> provides syntax to interact with a Swig as a service
application.

=head1 LICENSE

Copyright (c) 2014 Logan Bell and Shutterstock Inc (http://shutterstock.com).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
