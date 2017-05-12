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

package AxKit2::Config::Global;

# Global configuration

use strict;
use warnings;

sub new {
    my $class = shift;
    
    my %defaults = (
        Plugins => [],
        Notes => {},
        );

    return bless { %defaults, @_ }, $class;
}

sub docroot {
    my $self = shift;
    @_ and $self->{DocumentRoot} = shift;
    $self->{DocumentRoot};
}

sub console_port {
    my $self = shift;
    @_ and $self->{ConsolePort} = shift;
    $self->{ConsolePort};
}

sub console_addr {
    my $self = shift;
    @_ and $self->{ConsoleAddr} = shift;
    $self->{ConsoleAddr};
}

sub add_plugin {
    my $self = shift;
    push @{$self->{Plugins}}, shift;
}

sub plugins {
    my $self = shift;
    @{$self->{Plugins}};
}

sub plugin_dir {
    my $self = shift;
    @_ and $self->{PluginDir} = shift;
    $self->{PluginDir};
}

sub cached_hooks {
    my $self = shift;
    # never cache at the global level
    return;
}

sub notes {
    my $self = shift;
    my $key = shift || die "notes() requires a key";
    
    @_ and $self->{Notes}{$key} = [ @_ ];
    return @{ $self->{Notes}{$key} || [] } if wantarray;
    ${ $self->{Notes}{$key} || [] }[0];
}

1;
