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

package AxKit2::Config::Location;

# Configuration for a location (a URI path within a server)

use strict;
use warnings;

our $AUTOLOAD;

sub new {
    my $class = shift;
    my $server = shift;
    my $path = shift;
    
    my %defaults = (
        Plugins => [],
        Notes => {},
        CachedHooks => {},
        );
    
    my %args = ( __server => $server, __path => $path, %defaults, @_ );
    
    return bless \%args, $class;
}

sub server {
    my $self = shift;
    $self->{__server};
}

sub path {
    my $self = shift;
    $self->{__path};
}

sub matches {
    my $self = shift;
    my $tomatch = shift;
    return index($tomatch, $self->path) + 1;
}

sub docroot {
    my $self = shift;
    @_ and $self->{DocumentRoot} = shift;
    $self->{DocumentRoot} || $self->server->docroot;
}

sub add_plugin {
    my $self = shift;
    push @{$self->{Plugins}}, shift;
}

sub plugins {
    my $self = shift;
    @{$self->{Plugins}}, $self->server->plugins;
}

sub plugin_dir {
    my $self = shift;
    @_ and $self->{PluginDir} = shift;
    $self->{PluginDir} || $self->server->plugin_dir;
}

sub cached_hooks {
    my $self = shift;
    my $hook = shift;
    @_ and $self->{CachedHooks}{$hook} = shift;
    $self->{CachedHooks}{$hook};
}

sub notes {
    my $self = shift;
    my $key = shift || die "notes() requires a key";
    
    @_ and $self->{Notes}{$key} = [ @_ ];
    return $self->server->notes($key) if !exists $self->{Notes}{$key};
    return @{ $self->{Notes}{$key} || [] } if wantarray;
    ${ $self->{Notes}{$key} || [] }[0];
}

sub DESTROY {}

sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    $self->server->$method(@_);
}

1;
