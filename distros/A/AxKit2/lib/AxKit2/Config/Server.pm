# Copyright 2001-2006 The Apache Software Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package AxKit2::Config::Server;

# Configuration for a server (aka listening port/service/vhost)

use strict;
use warnings;

# we don't use the Location class directly, but we call its methods so
# this use() is here to show the dependency
use AxKit2::Config::Location;

sub new {
    my $class = shift;
    my $global = shift;
    my $name = shift;
    
    my %defaults = (
        Port => 8000,
        Plugins => [],
        Locations => [],
        Notes => {},
        CachedHooks => {},
        );

    my %args = ( __global => $global, %defaults, @_ );
    
    return bless \%args, $class;
}

sub global {
    my $self = shift;
    $self->{__global};
}

sub path {
    my $self = shift;
    return "/";
}

sub port {
    my $self = shift;
    @_ and $self->{Port} = shift;
    $self->{Port};
}

sub docroot {
    my $self = shift;
    @_ and $self->{DocumentRoot} = shift;
    $self->{DocumentRoot} || $self->global->docroot;
}

sub add_plugin {
    my $self = shift;
    push @{$self->{Plugins}}, shift;
}

sub plugins {
    my $self = shift;
    @{$self->{Plugins}}, $self->global->plugins;
}

sub plugin_dir {
    my $self = shift;
    @_ and $self->{PluginDir} = shift;
    $self->{PluginDir} || $self->global->plugin_dir;
}

sub add_location {
    my $self = shift;
    push @{$self->{Locations}}, shift;
}

sub cached_hooks {
    my $self = shift;
    my $hook = shift;
    @_ and $self->{CachedHooks}{$hook} = shift;
    $self->{CachedHooks}{$hook};
}

# given a path, find the config related to it
# sometimes this is a Location config, sometimes Server (i.e. $self)
sub get_config {
    my $self = shift;
    my $path = shift;
    
    for my $loc (reverse @{$self->{Locations}}) {
        return $loc if $loc->matches($path);
    }
    
    return $self;
}

sub notes {
    my $self = shift;
    my $key = shift || die "notes() requires a key";
    
    @_ and $self->{Notes}{$key} = [ @_ ];
    return $self->global->notes($key) if !exists $self->{Notes}{$key};
    return @{ $self->{Notes}{$key} || [] } if wantarray;
    ${ $self->{Notes}{$key} || [] }[0];
}

1;
