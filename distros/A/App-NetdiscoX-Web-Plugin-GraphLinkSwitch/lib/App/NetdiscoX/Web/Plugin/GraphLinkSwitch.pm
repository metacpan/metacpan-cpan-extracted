package App::NetdiscoX::Web::Plugin::GraphLinkSwitch;
 
our $VERSION = '0.01';
 
use Dancer ':syntax';
use App::Netdisco::Web::Plugin;
use App::Netdisco::Util::Device 'get_device';
 
use File::ShareDir 'dist_dir';
register_template_path(
  dist_dir( 'App-NetdiscoX-Web-Plugin-GraphLinkSwitch' ));

register_device_details({
  name  => 'graphlinkswitch',
  label => 'GraphLinkSwitch',
  default => 'on',
});

hook 'before_template' => sub {
    return unless
      index(request->path, uri_for('/ajax/content/device/details')->path) == 0;

    my $tokens = shift;
    my $device = $tokens->{d};

    # defaults
    $tokens->{deviceip} = ($device->{ip});
    $tokens->{devicedns} = ($device->{dns});

};


register_css('graphlinkswitch');
register_javascript('graphlinkswitch');
 
=head1 NAME
 
App::NetdiscoX::Web::Plugin::GraphLinkSwitch - Will add links to the device details page to a graph website.
 
=head1 SYNOPSIS
 
 # in your ~/environments/deployment.yml file
   
 extra_web_plugins:
   - X::GraphLinkSwitch

 plugin_graphlinkswitch:
   location_traffic: 'https://host.tld/page'
   location_errors: 'https://host.tld/page'
   location_discards: 'https://host.tld/page'
   location_cpuload: 'https://host.tld/page'
   location_cam_overflows: 'https://host.tld/page'
   location_igmp_status: 'https://host.tld/page'
   open_in_same_window: false
 
=head1 Description
 
This is a plugin for the L<App::Netdisco> network management application. It
adds a column to the Device Details named "GraphLinkSwitch" with links to a
graph website.
 
=head1 AUTHOR
 
Frederik Reenders <f.reenders@utwente.nl>
 
=head1 COPYRIGHT AND LICENSE
  
Copyright (C) 2014 by University of Twente

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.
 
=cut
 
true;
