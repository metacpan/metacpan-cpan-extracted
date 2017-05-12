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

# Class representing a single connection to the server

package AxKit2::Connection;

=head1 NAME

AxKit2::Connection - The client/connection side class.

=head1 DESCRIPTION

This class implements a single connection to the AxKit server.

It is a subclass of C<Danga::Socket>. See L<Danga::Socket> for the APIs
available to this class.

=head1 API

=cut

use strict;
use warnings;
use base qw(Danga::Socket AxKit2::Client);

use AxKit2::HTTPHeaders;
use AxKit2::Constants;
use AxKit2::Utils qw(http_date);

use fields qw(
    alive_time
    create_time
    headers_string
    headers_in
    headers_out
    ditch_leading_rn
    server_config
    path_config
    http_headers_sent
    notes
    sock_closed
    pause_count
    continuation
    keep_alive_count
    );

use constant KEEP_ALIVE_MAX => 100;
use constant CLEANUP_TIME => 5; # every N seconds
use constant MAX_HTTP_HEADER_LENGTH => 102400; # 100k

sub new {
    my AxKit2::Connection $self = shift;
    my $sock = shift;
    my $servconf = shift;
    $self = fields::new($self) unless ref($self);
    
    $self->SUPER::new($sock);

    my $now = time;
    $self->{alive_time} = $self->{create_time} = $now;
    
    $self->{headers_string} = '';
    $self->{closed} = 0;
    $self->{ditch_leading_rn} = 0; # TODO - work out how to set that...
    $self->{server_config} = $servconf;
    $self->{keep_alive_count} = 0;
    $self->{notes} = {};
    
    $self->log(LOGINFO, "Connection from " . $self->peer_addr_string);
    
    $self->hook_connect();
    
    return $self;
}

=head2 C<< $obj->uptime >>

Return the uptime for this connection in seconds (fractional)

=cut
sub uptime {
    my AxKit2::Connection $self = shift;
    
    return (time() - $self->{create_time});
}

=head2 C<< $obj->paused >>

Returns true if this connection is "paused".

=cut
sub paused {
    my AxKit2::Connection $self = shift;
    return 1 if $self->{pause_count};
    return 1 if $self->{closed};
    return 0;
}

=head2 C<< $obj->pause_read >>

Suspend reading from this client.

=cut
sub pause_read {
    my AxKit2::Connection $self = shift;
    $self->{pause_count}++;
    $self->watch_read(0);
}

=head2 C<< $obj->continue_read >>

Continue reading from this client. This is stacked, so two calls to C<pause_read>
and one call to C<continue_read> will not result in a continue.

These two calls are mainly used internally for continuations and 99.9% of the
time you should not be calling them.

=cut
sub continue_read {
    my AxKit2::Connection $self = shift;
    $self->{pause_count}--;
    if ($self->{pause_count} <= 0) {
        $self->{pause_count} = 0;
        $self->watch_read(1);
    }
}

=head2 C<< $obj->config >>

Retrieve the current config object for this request. Note that this may return
a different config object in different phases of the request because the config
object can be dependant on the URI.

=cut
sub config {
    my AxKit2::Connection $self = shift;
    return $self->{path_config} if $self->{path_config};
    if ($self->{headers_in}) {
        return $self->{path_config} = $self->{server_config}->get_config(
                                            $self->{headers_in}->request_uri
                                            );
    }
    return $self->{server_config};
}

=head2 C<< $obj->notes( KEY [, VALUE ] ) >>

Get/Set a custom key/value pair for this connection.

=cut
sub notes {
    my AxKit2::Connection $self = shift;
    my $key  = shift;
    @_ and $self->{notes}->{$key} = shift;
    $self->{notes}->{$key};
}

sub max_idle_time       { 30 }
sub max_connect_time    { 180 }
sub event_err { my AxKit2::Connection $self = shift; $self->close("Error") }
sub event_hup { my AxKit2::Connection $self = shift; $self->close("Disconnect (HUP)") }
sub close     { my AxKit2::Connection $self = shift; $self->{sock_closed}++; $self->{notes} = undef; $self->SUPER::close(@_) }

sub event_read {
    my AxKit2::Connection $self = shift;
    $self->{alive_time} = time;
    
    if ($self->{headers_in}) {
        # already got the headers... do we get a body too?
        my $bref = $self->read(8192);
        return $self->close($!) unless defined $bref;
        return $self->hook_body_data($bref);
    }
    my $to_read = MAX_HTTP_HEADER_LENGTH - length($self->{headers_string});
    my $bref = $self->read($to_read);
    return $self->close($!) unless defined $bref;
    
    $self->{headers_string} .= $$bref;
    my $idx = index($self->{headers_string}, "\r\n\r\n");
    
    my $lame_request = 0;
    
    if ($idx == -1) {
        # usually we get the headers all in one packet (one event), so
        # if we get in here, that means it's more than likely the
        # extra \r\n and if we clean it now (throw it away), then we
        # can avoid a regexp later on.
        if ($self->{ditch_leading_rn} && $self->{headers_string} eq "\r\n") {
            $self->{ditch_leading_rn} = 0;
            $self->{headers_string}   = "";
            return;
        }
        
        # Could be a HTTP/0.9 request...
        if ($self->{headers_string} !~ /^GET [^ ]+\n$/i) {
            $self->close('long_headers')
                if length($self->{headers_string}) >= MAX_HTTP_HEADER_LENGTH;
            return;
        }
        # for HTTP/0.9, just set $idx to the end of the string
        $idx = length($self->{headers_string}) - 2;
        $self->{headers_string} .= "\r\n";
        $lame_request = 1;
    }
    
    my $hstr = substr($self->{headers_string}, 0, $idx);
    
    # push back the \r\n\r\n
    my $extra = substr($self->{headers_string}, $idx+4);
    if (my $len = length($extra)) {
        $self->push_back_read(\$extra);
    }

    # some browsers send an extra \r\n after their POST bodies that isn't
    # in their content-length.  a base class can tell us when they're
    # on their 2nd+ request after a POST and tell us to be ready for that
    # condition, and we'll clean it up
    $hstr =~ s/^\r\n// if $self->{ditch_leading_rn};
    
    $self->{headers_in} = AxKit2::HTTPHeaders->new(\$hstr, 0, $lame_request);
    
    if (!$self->{headers_in}) {
        $self->{headers_in} = AxKit2::HTTPHeaders->new(\("GET / HTTP/1.0\r\n\r\n"));
        $self->default_error_out(BAD_REQUEST);
    }
    
    $self->{ditch_leading_rn} = 0;
    
    $self->hook_post_read_request($self->{headers_in});
}

sub event_write {
    my AxKit2::Connection $self = shift;
    $self->{alive_time} = time;
    
    if ($self->hook_write_body_data) {
        return;
    }
    
    # if hook_write_body_data didn't want to send anything, we just pump
    # whatever's in the queue to go out.
    if ($self->write(undef)) {
        # Everything sent. No need to watch for write notifications any more.
        $self->watch_write(0);
    }
}

=head2 C<< $obj->headers_out( [ NEW_HEADERS ] ) >>

Get/set the response header object.

See L<AxKit2::HTTPHeaders>.

=cut
sub headers_out {
    my AxKit2::Connection $self = shift;
    @_ and $self->{headers_out} = shift;
    $self->{headers_out};
}

=head2 C<< $obj->headers_in >>

Get the request header object.

See L<AxKit2::HTTPHeaders>.

=cut
sub headers_in {
    my AxKit2::Connection $self = shift;
    $self->{headers_in};
}

=head2 C<< $obj->param( ARGS ) >>

A shortcut for C<< $obj->headers_in->param( ARGS ) >>. See L<AxKit2::HTTPHeaders>
for details.

=cut
sub param {
    my AxKit2::Connection $self = shift;
    $self->{headers_in}->param(@_);
}

=head2 C<< $obj->send_http_headers >>

Send the response headers to the browser.

=cut
sub send_http_headers {
    my AxKit2::Connection $self = shift;
    
    return if $self->{http_headers_sent}++;
    return if $self->headers_in && $self->headers_in->lame_request;
    $self->write($self->headers_out->to_string_ref);
}

sub initialize_response {
    my AxKit2::Connection $self = shift;
    
    return if $self->{headers_out};
    
    $self->{headers_out} = AxKit2::HTTPHeaders->new_response;
    $self->{headers_out}->header(Date   => http_date());
    $self->{headers_out}->header(Server => "AxKit-2/v$AxKit2::VERSION");
}

sub process_request {
    my AxKit2::Connection $self = shift;
    my $hd = $self->{headers_in};
    
    $self->initialize_response($hd);
    
    no warnings 'uninitialized';
    if ($hd->header('Connection') =~ /\bkeep-alive\b/i) {
        # client asked for keep alive. Do we?
        $self->{keep_alive_count}++;
        if ($self->{keep_alive_count} > KEEP_ALIVE_MAX) {
            $self->{headers_out}->header(Connection => 'close');
        }
        else {
            $self->{headers_out}->header(Connection => 'Keep-Alive');
            $self->{headers_out}->header('Keep-Alive' => 
                "timeout=" . $self->max_idle_time . 
                ", max=" .  (KEEP_ALIVE_MAX - $self->{keep_alive_count}));
        }
    }

    # This starts off the chain reaction of the main state machine
    $self->hook_uri_translation($hd, $hd->request_uri);
}

# called when we've finished writing everything to a client and we need
# to reset our state for another request.  returns 1 to mean that we should
# support persistence, 0 means we're discarding this connection.
sub http_response_sent {
    my AxKit2::Connection $self = $_[0];
    
    $self->log(LOGDEBUG, "Response sent");
    
    return 0 if $self->{sock_closed};
    
    # close if we're supposed to
    if (
        ! defined $self->{headers_out} ||
        ! $self->{headers_out}->res_keep_alive($self->{headers_in})
        )
    {
        # do a final read so we don't have unread_data_waiting and RST
        # the connection.  IE and others send an extra \r\n after POSTs
        my $dummy = $self->read(5);
        
        # close if we have no response headers or they say to close
        $self->close("no_keep_alive");
        return 0;
    }

    # if they just did a POST, set the flag that says we might expect
    # an unadvertised \r\n coming from some browsers.  Old Netscape
    # 4.x did this on all POSTs, and Firefox/Safari do it on
    # XmlHttpRequest POSTs.
    if ($self->{headers_in}->request_method eq "POST") {
        $self->{ditch_leading_rn} = 1;
    }

    # now since we're doing persistence, uncork so the last packet goes.
    # we will recork when we're processing a new request.
    # TODO: Disabled because this seemed mostly relevant to Perlbal...
    $self->tcp_cork(0);

    # reset state
    $self->{alive_time}            = $self->{create_time} = time;
    $self->{headers_string}        = '';
    $self->{headers_in}            = undef;
    $self->{headers_out}           = undef;
    $self->{http_headers_sent}     = 0;
    $self->{notes}                 = {};
    $self->{path_config}           = undef;
    
    # NOTE: because we only speak 1.0 to clients they can't have
    # pipeline in a read that we haven't read yet.
    $self->watch_read(1);
    $self->watch_write(0);
    
    $self->hook_pre_request();
    
    return 1;
}

sub DESTROY {
#    print "Connection DESTROY\n";
}

Danga::Socket->AddTimer(CLEANUP_TIME, \&_do_cleanup);

# Cleanup routine to get rid of timed out sockets
sub _do_cleanup {
    my $now = time;
    
    # AxKit2::Client->log(LOGDEBUG, "do cleanup");
    
    Danga::Socket->AddTimer(CLEANUP_TIME, \&_do_cleanup);
    
    my $sf = __PACKAGE__->get_sock_ref;
    
    my $conns = 0;

    my %max_age;  # classname -> max age (0 means forever)
    my %max_connect; # classname -> max connect time
    my @to_close;
    while (my $k = each %$sf) {
        my AxKit2::Connection $v = $sf->{$k};
        my $ref = ref $v;
        next unless $v->isa('AxKit2::Connection');
        $conns++;
        unless (defined $max_age{$ref}) {
            $max_age{$ref}      = $ref->max_idle_time || 0;
            $max_connect{$ref}  = $ref->max_connect_time || 0;
        }
        if (my $t = $max_connect{$ref}) {
            if ($v->{create_time} < $now - $t) {
                push @to_close, $v;
                next;
            }
        }
        if (my $t = $max_age{$ref}) {
            if ($v->{alive_time} < $now - $t) {
                push @to_close, $v;
            }
        }
    }
    
    $_->close("Timeout") foreach @to_close;
}

1;
