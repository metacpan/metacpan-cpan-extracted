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

package AxKit2::Config;

=head1 NAME

AxKit2::Config - Configuration class

=head1 DESCRIPTION

This class is a parser for the configuration files. This document also describes
the API for the classes that implement the configuration, which are
C<AxKit2::Config::Global>, C<AxKit2::Config::Server> and C<AxKit2::Config::Location>.
It's just easier to type C<AxKit2::Config> so we're putting the docs here to be
nice :-)

=cut

use strict;
use warnings;

use AxKit2::Client;
use AxKit2::Config::Global;
use AxKit2::Config::Server;
use AxKit2::Config::Location;
use File::Spec::Functions qw(rel2abs);

our %CONFIG;

__PACKAGE__->add_config_param(Plugin => \&TAKE1, sub { my $conf = shift; AxKit2::Client->load_plugin($conf, $_[0]); $conf->add_plugin($_[0]); });
__PACKAGE__->add_config_param(Port => \&TAKE1, sub { my $conf = shift; $conf->port($_[0]) });
__PACKAGE__->add_config_param(DocumentRoot => \&TAKE1, sub { my $conf = shift; $conf->docroot(rel2abs($_[0])) });
__PACKAGE__->add_config_param(ConsolePort => \&TAKE1, sub { my $conf = shift; $conf->isa('AxKit2::Config::Global') || die "ConsolePort only allowed at global level"; $conf->console_port($_[0]) });
__PACKAGE__->add_config_param(ConsoleAddr => \&TAKE1, sub { my $conf = shift; $conf->isa('AxKit2::Config::Global') || die "ConsoleAddr only allowed at global level"; $conf->console_addr($_[0]) });
__PACKAGE__->add_config_param(PluginDir => \&TAKE1, sub { my $conf = shift; $conf->plugin_dir($_[0]) });

our $GLOBAL = AxKit2::Config::Global->new();

sub new {
    my ($class, $file) = @_;
    
    my $self = bless {
            servers => [],
        }, $class;
    
    $self->parse_config($file);
    
    return $self;
}

sub global {
    return $GLOBAL;
}

sub add_config_param {
    my $class = shift;
    my $key = shift || die "add_config_param() requires a key";
    my $validate = shift || die "add_config_param() requires a validate routine";
    my $store = shift || die "add_config_param() requires a store routine";

    if ($key !~ m/_/) {
        $key =~ s/([A-Z]+)([A-Z])/$1_$2/g;
        $key =~ s/([a-z0-9])([A-Z])/$1_$2/g;
    }
    $key = lc($key);

    if (exists $CONFIG{$key}) {
        die "Config key '$key' already exists";
    }
    $CONFIG{$key} = [$validate, $store];
    $key =~ s/_//g;
    $CONFIG{$key} = [$validate, $store];
}

sub servers {
    my $self = shift;
    return @{$self->{servers}};
}

sub parse_config {
    my ($self, $file) = @_;
    
    open(my $fh, $file) || die "open($file): $!";
    local $self->{_fh} = $fh;
    
    my $global = $self->global;
    while ($self->_configline) {
        if (/^<Server(\s*(\S*))>/i) {
            my $name = $2 || "";
            $self->_parse_server($global, $name);
            next;
        }
        _generic_config($global, $_);
    }
}

sub _parse_server {
    my ($self, $global, $name) = @_;
    
    my $server = AxKit2::Config::Server->new($global, $name);
    
    my $closing = 0;
    while ($self->_configline) {
        if (/^<Location\s+(\S.*)>/i) {
            my $path = $1;
            my $loc = $self->_parse_location($server, $path);
            $server->add_location($loc);
            next;
        }
        elsif (/<\/Server>/i) { $closing++; last; }
        _generic_config($server, $_);
    }
    
    my $forserver = $name ? "for server named $name " : "";
    die "No </Server> line ${forserver}in config file" unless $closing;
    
    push @{$self->{servers}}, $server;
    
    return;
}

sub _parse_location {
    my ($self, $server, $path) = @_;
    
    my $location = AxKit2::Config::Location->new($server, $path);

    my $closing = 0;
    while ($self->_configline) {
        if (/<\/Location>/i) { $closing++; last; }
        _generic_config($location, $_);
    }
    
    die "No </Location> line for path: $path in config file" unless $closing;
    
    return $location;
}

sub _generic_config {
    my ($conf, $line) = @_;
    my ($key, $rest) = split(/\s+/, $line, 2);
    $key = lc($key);
    $key =~ s/-/_/g;
    if (!$CONFIG{$key} || ($key =~ s/_//g && !$CONFIG{$key})) {
        die "Invalid line in server config: $line";
    }
    my $cfg = $CONFIG{$key};
    my @vals = $cfg->[0]->($rest); # validate and clean
    $cfg->[1]->($conf, @vals);   # save value(s)
    return;
}

sub _configline {
    my $self = shift;
    die "No filehandle!" unless $self->{_fh};
    
    while ($_ = $self->{_fh}->getline) {
        return unless defined $_;
    
        next unless /\S/;
        # skip comments
        next if /^\s*#/;
        
        # cleanup whitespace
        s/^\s*//; s/\s*$//;
        
        chomp;
        
        if (s/\\$//) {
            # continuation line...
            my $line = $_;
            $_ = $line . $self->_configline;
        }
        
        return $_;
    }
}

sub _get_quoted {
    my $line = shift;
    my $quotechar = shift;
    
    my $out = '';
    $line =~ s/^$quotechar//;
    while ($line =~ /\G(.*?)([\\$quotechar])/gc) {
        $out .= $1;
        my $token = $2;
        if ($token eq "\\") {
            $line =~ /\G([$quotechar\\])/gc || die "invalid escape char";
            $out .= $1;
        }
        elsif ($token eq $quotechar) {
            $line =~ /\G\s*(.*)$/gc;
            return $out, $1;
        }
    }
    die "Invalid quoted string";
}

sub TAKEBOOL {
    my $str = shift;
    $str =~ /^(y(?:es)?|1|on|true)$/i and return 1;
    $str =~ /^(no?|0|off|false)$/i and return 0;
    die "Unkown boolean value: $str";
}

sub TAKE1 {
    my $str = shift;
    my @vals = TAKEMANY($str);
    if (@vals != 1) {
        die "Invalid number of params";
    }
    return $vals[0];
}

sub TAKEMANY {
    my $str = shift;
    my @vals;
    while (length($str)) {
        if ($str =~ /^(["'])/) {
            my $val;
            ($val, $str) = _get_quoted($str, $1);
            push @vals, $val;
        }
        else {
            $str =~ s/^(\S+)\s*// || die "bad format";
            push @vals, $1;
        }
    }
    die "No data found" unless @vals;
    return @vals;
}

1;

__END__

=head1 DIRECTIVES

DocumentRoot

ConsolePort

ConsoleAddr

PluginDir

Plugin

<Server> / <Server name>

Port

<Location path>

...

=head1 API

=head2 C<< $config->docroot( [ STRING ] ) >>

Get/set the DocumentRoot.

=head2 C<< $config->console_port( [ NUMBER ] ) >>

Get/set the ConsolePort. See L<AxKit2::Console>.

=head2 C<< $config->console_addr( [ STRING ] ) >>

Get/set the ConsoleAddr bind address.

=head2 C<< $config->plugin_dir( [ STRING ] ) >>

Get/set the PluginDir (directory to look in for plugins).

=head2 C<< $config->notes( KEY [, VALUE] ) >>

Get/set per-config key-value pairs.

=head1 CASCADING

Lookup of values cascades from the location to the server to the global config
class. So if the docroot isn't set in the C<< <Location> >> section, the config
class will automatically cascade down to the C<< <Server> >> section to look
for the value, and down to the global level if it is still not found.

=head1 LOCATION MATCHING

How AxKit2 matches a request to a particular C<< <Location> >> section is at
best described as naive. It simply looks for the last matching location section
in the config file. This has consequences that I should document better.

=cut