package App::NetdiscoX::Web::Plugin::RANCID;

use strict;
use warnings;

our $VERSION = '3.000000';

use Dancer ':syntax';

use App::Netdisco::Web::Plugin;
use App::Netdisco::Util::Device 'get_device';
use App::Netdisco::Util::Permission 'acl_matches';

use File::ShareDir 'dist_dir';
register_template_path(
  dist_dir( 'App-NetdiscoX-Web-Plugin-RANCID' ));

register_device_details({
  name  => 'rancid',
  label => 'RANCID',
  default => 'on',
});

hook 'before_template' => sub {
    return unless
      index(request->path, uri_for('/ajax/content/device/details')->path) == 0;

    my $config = config;
    my $tokens = shift;
    my $device = $tokens->{d};
    my $domain_suffix = setting('domain_suffix') || '';

    # defaults
    $tokens->{rancidgroup} = '';
    $tokens->{ranciddevice} = ($device->{dns} || $device->{name} || $device->{ip});

    return unless exists $config->{rancid};
    my $rancid = $config->{rancid};

    $rancid->{groups}      ||= {};
    $rancid->{excluded}    ||= [];
    $rancid->{by_ip}       ||= [];
    $rancid->{by_hostname} ||= [];

    if (acl_matches(get_device($device->{ip}),$rancid->{excluded})) {
        session rancid_display => 0;
    } else {
        session rancid_display => 1;
    }

    foreach my $g (keys %{ $rancid->{groups} }) {
        if (acl_matches( get_device($device->{ip}), $rancid->{groups}->{$g} )) {
            $tokens->{rancidgroup} = $g;
            if (acl_matches( get_device($device->{ip}),$rancid->{by_hostname})) {
                $tokens->{ranciddevice} =~ s/$domain_suffix$//;
            } elsif (acl_matches( get_device($device->{ip}), $rancid->{by_ip})) {
                $tokens->{ranciddevice} = $device->{ip};
            }
            last;
        }
    }
};

1;

__END__

=pod

=cut

=head1 NAME

App::NetdiscoX::Web::Plugin::RANCID - Link to device backups in RANCID/WebSVN

=head1 DEPRECATED

This plugin is deprecated and no longer maintained!

Please use the External Links feature which is built-in to Netdisco itself.
You can use this feature to create a templated hyperlink, and use tags or
custom fields to replicate the GROUP.

L<https://github.com/netdisco/netdisco/wiki/Configuration#external_links>

For example in your Netdisco C<deployment.yml> configuration file:

 external_links:
   device:
     - url: 'https://websvn.example.com/websvn/filedetails.php?repname=rancid&path=/configs/[% device %]'
       displayname: 'RANCID WebSVN'
       only: '192.0.2.0/24'

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2013,2019-2025 by The Netdisco Developer Team.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
     * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
     * Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
     * Neither the name of the Netdisco Project nor the
       names of its contributors may be used to endorse or promote products
       derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE NETDISCO DEVELOPER TEAM BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
