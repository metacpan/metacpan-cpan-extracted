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

package AxKit2::Client;

use strict;
use warnings;

use AxKit2::Plugin;
use AxKit2::Constants;
use AxKit2::Processor;
use AxKit2::Utils qw(xml_escape);
use Carp qw(croak);

our %PLUGINS;

sub load_plugin {
    my ($class, $conf, $plugin) = @_;
    
    my $package;
    
    if ($plugin =~ m/::/) {
        # "full" package plugin (My::Plugin)
        $package = $plugin;
        $package =~ s/[^_a-z0-9:]+//gi;
        my $eval = qq[require $package;\n] 
                  .qq[sub ${plugin}::plugin_name { '$plugin' }]
                  .qq[sub ${plugin}::hook_name { shift->{_hook}; }];
        $eval =~ m/(.*)/s;
        $eval = $1;
        eval $eval;
        die "Failed loading $package - eval $@" if $@;
        $class->log(LOGDEBUG, "Loaded Plugin $package");
    }
    else {
        
        my $dir = $conf->plugin_dir || "./plugins";
        
        my $plugin_name = plugin_to_name($plugin);
        $package = "AxKit2::Plugin::$plugin_name";
        
        # don't reload plugins if they are already loaded
        unless ( defined &{"${package}::plugin_name"} ) {
            AxKit2::Plugin->_compile($plugin_name,
                $package, "$dir/$plugin");
        }
    }
    
    return if $PLUGINS{$plugin};
    
    my $plug = $package->new();
    $PLUGINS{$plugin} = $plug;
    $plug->_register();
}

sub plugin_to_name {
    my $plugin = shift;
    
    my $plugin_name = $plugin;
    
    # Escape everything into valid perl identifiers
    $plugin_name =~ s/([^A-Za-z0-9_\/])/sprintf("_%2x",unpack("C",$1))/eg;

    # second pass cares for slashes and words starting with a digit
    $plugin_name =~ s{
              (/+)       # directory
              (\d?)      # package's first character
             }[
               "::" . (length $2 ? sprintf("_%2x",unpack("C",$2)) : "")
              ]egx;

    
    return $plugin_name;
}

sub plugin_instance {
    my $plugin = shift;
    return $PLUGINS{$plugin};
}

sub config {
    # should be subclassed - clients get a server config
    AxKit2::Config->global;
}

sub run_hooks {
    my ($self, $hook) = (shift, shift);
    
    my $conf = $self->config();
    
    if (my $cached_hooks = $conf->cached_hooks($hook)) {
        return $self->_run_hooks($conf, $hook, [@_], $cached_hooks, 0);
    }
    
    my @hooks;
    for my $plugin ($conf->plugins) {
        my $plug = $PLUGINS{$plugin} || next;
        push @hooks, map { [$plugin, $plug, $_] } $plug->hooks($hook);
    }
    
    $conf->cached_hooks($hook, \@hooks);
    $self->_run_hooks($conf, $hook, [@_], \@hooks, 0);
}

sub finish_continuation {
    my ($self) = @_;
    my $todo = $self->{continuation} || croak "No continuation in progress";
    $self->continue_read();
    $self->{continuation} = undef;
    my $hook = shift @$todo;
    my $args = shift @$todo;
    my $pos  = shift @$todo;
    my $conf = $self->config;
    my $hooks = $conf->cached_hooks($hook);
    $self->_run_hooks($conf, $hook, $args, $hooks, $pos+1);
}

sub _run_hooks {
    my $self = shift;
    my ($conf, $hook, $args, $hooks, $pos) = @_;
    
    my $last_hook = $#$hooks;
    
    my @r;
    if ($pos <= $last_hook) {
        for my $idx ($pos .. $last_hook) {
            my $info = $hooks->[$idx];
            my ($plugin, $plug, $h) = @$info;
            # $self->log(LOGDEBUG, "$plugin ($idx) running hook $hook") unless $hook eq 'logging';
            eval { @r = $plug->$h($self, $conf, @$args) };
            if ($@) {
                my $err = $@;
                $self->log(LOGERROR, "FATAL PLUGIN ERROR: $err");
                $self->hook_error($err) unless $hook eq 'error';
                return DONE;
            }
            next unless @r;
            if (!defined $r[0]) {
                print "r0 not defined in hook $hook\[$idx]\n";
            }
            if ($r[0] == CONTINUATION) {
                $self->pause_read();
                $self->{continuation} = [$hook, $args, $idx];
            }
            last unless $r[0] == DECLINED;
        }
    }
    
    $r[0] = DECLINED if not defined $r[0];
    if ($r[0] != CONTINUATION) {
        my $responder = "hook_${hook}_end";
        if (my $meth = $self->can($responder)) {
            return $meth->($self, $r[0], $r[1], @$args);
        }
    }
    return @r;
}

sub log {
    my $self = shift;
    $self->run_hooks('logging', @_);
}

sub hook_connect {
    my $self = shift;
    $self->run_hooks('connect');
}

sub hook_connect_end {
    my $self = shift;
    my ($ret, $out) = @_;
    if ($ret == DECLINED || $ret == OK) {
        # success
        $self->run_hooks('pre_request');
    }
    else {
        $self->close("connect hook closing");
        return;
    }
}

sub hook_pre_request {
    my $self = shift;
    $self->run_hooks('pre_request');
}

sub hook_pre_request_end {
    my $self = shift;
    my ($ret, $out) = @_;
    # TODO: Manage $ret
    return;
}

sub hook_body_data {
    my $self = shift;
    $self->run_hooks('body_data', @_);
}

sub hook_body_data_end {
    my ($self, $ret) = @_;
    if ($ret == DECLINED || $ret == DONE) {
        return $self->process_request();
    }
    elsif ($ret == OK) {
        return 1;
    }
    else {
        $self->default_error_out($ret);
    }
}

sub hook_write_body_data {
    my $self = shift;
    my ($ret) = $self->run_hooks('write_body_data');
    if ($ret == CONTINUATION) {
        die "Continuations not supported on write_body_data";
    }
    elsif ($ret == DECLINED || $ret == DONE) {
        return;
    }
    elsif ($ret == OK) {
        return 1;
    }
    else {
        $self->default_error_out($ret);
    }
}

sub hook_post_read_request {
    my $self = shift;
    $self->run_hooks('post_read_request', @_);
}

sub hook_post_read_request_end {
    my ($self, $ret, $out, $hd) = @_;
    if ($ret == DECLINED || $ret == OK) {
        if ($hd->request_method =~ /GET|HEAD/) {
            return $self->process_request;
        }
        return;
    }
    elsif ($ret == DONE) {
        $self->write(sub { $self->hook_response_sent($self->headers_out->response_code) });
    }
    else {
        $self->default_error_out($ret);
    }
}

sub hook_uri_translation {
    my ($self, $hd, $uri) = @_;
    $self->run_hooks('uri_translation', $hd, $uri);
}

sub hook_uri_translation_end {
    my ($self, $ret, $out, $hd) = @_;
    if ($ret == DECLINED || $ret == OK) {
        return $self->run_hooks('mime_map', $hd, $hd->filename);
    }
    elsif ($ret == DONE) {
        $self->write(sub { $self->hook_response_sent($self->headers_out->response_code) });
    }
    else {
        $self->default_error_out($ret);
    }
}

sub hook_mime_map_end {
    my ($self, $ret, $out, $hd) = @_;
    if ($ret == DECLINED || $ret == OK) {
        return $self->run_hooks('access_control', $hd);
    }
    elsif ($ret == DONE) {
        $self->write(sub { $self->hook_response_sent($self->headers_out->response_code) });
    }
    else {
        $self->default_error_out($ret);
    }
}

sub hook_access_control_end {
    my ($self, $ret, $out, $hd) = @_;
    if ($ret == DECLINED || $ret == OK) {
        return $self->run_hooks('authentication', $hd);
    }
    elsif ($ret == DONE) {
        $self->write(sub { $self->hook_response_sent($self->headers_out->response_code) });
    }
    else {
        $self->default_error_out($ret);
    }
}

sub hook_authentication_end {
    my ($self, $ret, $out, $hd) = @_;
    if ($ret == DECLINED || $ret == OK) {
        return $self->run_hooks('authorization', $hd);
    }
    elsif ($ret == DONE) {
        $self->write(sub { $self->hook_response_sent($self->headers_out->response_code) });
    }
    else {
        $self->default_error_out($ret);
    }
}

sub hook_authorization_end {
    my ($self, $ret, $out, $hd) = @_;
    if ($ret == DECLINED || $ret == OK) {
        return $self->run_hooks('fixup', $hd);
    }
    elsif ($ret == DONE) {
        $self->write(sub { $self->hook_response_sent($self->headers_out->response_code) });
    }
    else {
        $self->default_error_out($ret);
    }
}

sub hook_fixup_end {
    my ($self, $ret, $out, $hd) = @_;
    if ($ret == DECLINED || $ret == OK) {
        return $self->run_hooks(
                            'xmlresponse', 
                            AxKit2::Processor->new($self, $hd->filename),
                            $hd);
    }
    elsif ($ret == DONE) {
        $self->write(sub { $self->hook_response_sent($self->headers_out->response_code) });
    }
    else {
        $self->default_error_out($ret);
    }
}

sub hook_xmlresponse_end {
    my ($self, $ret, $out, $input, $hd) = @_;
    if ($ret == DECLINED) {
        return $self->run_hooks('response', $hd);
    }
    elsif ($ret == DONE) {
        $self->write(sub { $self->hook_response_sent($self->headers_out->response_code) });
    }
    elsif ($ret == OK) {
        $out->output() if $out;
        $self->write(sub { $self->http_response_sent($self->headers_out->response_code) });
    }
    else {
        $self->default_error_out($ret);
    }
}

sub hook_response_end {
    my ($self, $ret, $out, $hd) = @_;
    if ($ret == DECLINED) {
        $self->default_error_out(NOT_FOUND);
    }
    elsif ($ret == OK || $ret == DONE) {
        $self->write(sub { $self->hook_response_sent($self->headers_out->response_code) });
    }
    else {
        $self->default_error_out($ret);
    }
    
}

sub hook_response_sent {
    my $self = shift;
    $self->run_hooks('response_sent', @_);
}

sub hook_response_sent_end {
    my ($self, $ret, $out, $code) = @_;
    if ($ret == DONE) {
        $self->close("plugin decided not to keep connection open");
    }
    elsif ($ret == DECLINED || $ret == OK) {
        return $self->http_response_sent;
    }
    else {
        $self->default_error_out($ret);
    }
}

sub hook_error {
    my $self = shift;
    $self->headers_out->code(SERVER_ERROR);
    $self->run_hooks('error', @_);
}

sub hook_error_end {
    my ($self, $ret) = @_;
    if ($ret == DECLINED) {
        $self->default_error_out(SERVER_ERROR);
    }
    elsif ($ret == OK || $ret == DONE) {
        # we assume some hook handled the error
    }
    else {
        $self->default_error_out($ret);
    }
}

# stolen shamelessly from httpd-2.2.2/modules/http/http_protocol.c
sub default_error_out {
    my ($self, $code, $extras) = @_;
    $extras = '' unless defined $extras;
    
    $self->initialize_response;
    
    $self->headers_out->code($code);
    
    if ($code == NOT_MODIFIED) {
        $self->send_http_headers;
        $self->write(sub { $self->hook_response_sent($self->headers_out->response_code) });
        # The 304 response MUST NOT contain a message-body
        return;
    }
    
    $self->headers_out->header('Content-Type', 'text/html');
    $self->headers_out->header('Connection', 'close');
    $self->send_http_headers;
    
    $self->write("<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">\n" .
                 "<HTML><HEAD>\n" .
                 "<TITLE>$code ".$self->headers_out->http_code_english."</TITLE>\n" .
                 "</HEAD></BODY>\n" .
                 "<H1>".$self->headers_out->http_code_english."</H1>\n"
                 );
    
    if ($code == REDIRECT) {
        my $new_uri = $self->headers_out->header('Location')
            || die "No Location header set for REDIRECT";
        $self->write('The document has moved <A HREF="' . 
                        xml_escape($new_uri) . "\">here</A>.<P>\n");
    }
    elsif ($code == BAD_REQUEST) {
        $self->write("<p>Your browser sent a request that this server could not understand.<br />\n" .
                     xml_escape($extras)."</p>\n");
    }
    elsif ($code == UNAUTHORIZED) {
        $self->write("<p>This server could not verify that you\n" .
                       "are authorized to access the document\n" .
                       "requested.  Either you supplied the wrong\n" .
                       "credentials (e.g., bad password), or your\n" .
                       "browser doesn't understand how to supply\n" .
                       "the credentials required.</p>\n");
    }
    elsif ($code == FORBIDDEN) {
        $self->write("<p>You don't have permission to access " . 
                     xml_escape($self->headers_in->uri) .
                     "\non this server.</p>\n");
    }
    elsif ($code == NOT_FOUND) {
        $self->write("<p>The requested URL " . 
                     xml_escape($self->headers_in->uri) .
                     " was not found on this server.</p>\n");
    }
    elsif ($code == SERVICE_UNAVAILABLE) {
        $self->write("<p>The server is temporarily unable to service your\n" .
                     "request due to maintenance downtime or capacity\n" .
                     "problems. Please try again later.</p>\n");
    }
    else {
        $self->write("The server encountered an internal error or \n" .
                     "misconfiguration and was unable to complete \n" .
                     "your request.<p>\n" .
                     "More information about this error may be available\n" .
                     "in the server error log.<p>\n");
    }
    
    $self->write(<<EOT);
<HR>
</BODY></HTML>
EOT

    $self->write(sub { $self->hook_response_sent($self->headers_out->response_code) });
}

1;
