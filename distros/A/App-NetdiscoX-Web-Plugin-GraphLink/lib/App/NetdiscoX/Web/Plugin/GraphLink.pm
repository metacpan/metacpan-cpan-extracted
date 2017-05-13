package App::NetdiscoX::Web::Plugin::GraphLink;
 
our $VERSION = '0.01';
 
use Dancer ':syntax';
use App::Netdisco::Web::Plugin;
 
use File::ShareDir 'dist_dir';
register_template_path(
  dist_dir( 'App-NetdiscoX-Web-Plugin-GraphLink' ));

register_device_port_column({
  name  => 'graphlink',
  position => 'mid',
  label => 'GraphLink',
  default => 'on',
});

register_css('graphlink');
register_javascript('graphlink');
 
=head1 NAME
 
App::NetdiscoX::Web::Plugin::GraphLink - Will add a link to the device/port page to a graph website.
 
=head1 SYNOPSIS
 
 # in your ~/environments/deployment.yml file
   
 extra_web_plugins:
   - X::GraphLink
 
=head1 Description
 
This is a plugin for the L<App::Netdisco> network management application. It
adds a column to the Device Ports table named "GraphLink" with a link to a
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
