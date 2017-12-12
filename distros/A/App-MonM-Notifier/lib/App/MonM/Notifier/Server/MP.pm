package App::MonM::Notifier::Server::MP; # $Id: MP.pm 46 2017-12-04 12:19:36Z abalama $
use strict;
use warnings FATAL => 'all';
use utf8;

=head1 NAME

App::MonM::Notifier::Server::MP - mod_perl2 server handler

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    # Apache2 config section
    #PerlSwitches -I/path/to/App-MonM-Notifier/lib
    <IfModule mod_perl.c>
      <Location /monotifier>
        SetHandler modperl
        PerlResponseHandler App::MonM::Notifier::Server::MP
        #PerlSetVar Debug 1
        PerlSetVar MonotifierConfig /path/to/config.conf
     </Location>
    </IfModule>

=head1 DESCRIPTION

To use the functionality of this module, you must edit the virtual-host section of
the Apache2 WEB server configuration file

=head2 FUNCTIONS

=over 8

=item B<handler>

Handler for Apache2 WEB server. For internal use only

=item B<server_init>

Method provides server initialization. For internal use only

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

C<mod_perl2>, L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

<mod_perl2>, L<App::MonM::Notifier>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut


use vars qw/ $VERSION $PATCH_20141100055 /;
$VERSION = "1.01";
$PATCH_20141100055 = 0;

use Encode;
use Encode::Locale;

use mod_perl2;
use Apache2::RequestIO ();
use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::ServerRec ();
use Apache2::ServerUtil ();
use Apache2::Connection ();
use Apache2::Const -compile => qw/ :common :http /;
use Apache2::Log;
use Apache2::Util ();
use APR::Const -compile => qw/ :common /;
use APR::Table ();

use CGI -compile => qw/ :all /;
use JSON;
use File::Spec;
use File::Find;
use File::Basename;
use URI;

use CTKx;
use CTK qw/:BASE/;
use CTK::Util;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use Sys::Hostname;
use Try::Tiny;

use App::MonM::Notifier::Util;
use App::MonM::Notifier::Const;

use base qw/App::MonM::Notifier::Server/;

use constant {
        PREFIX      => "monotifier",
        LOGFILENAME => "monotifier.server.log",
        LOCATION    => "/monotifier",
        LOCALHOSTIP => "127.0.0.1",
        DATE_FORMAT => "%D %H:%M:%S %Z",
        CONTENT_TYPE=> 'application/json; charset=utf-8',

        MPE_INTERNAL    => 0,
        MPE_T_ANY       => 1,
        MPE_T_BOOL      => 2,
        MPE_T_NUMBER    => 3,
        MPE_T_INTEGER   => 4,
        MPE_T_STRING    => 5,
        MPE_T_IPV4      => 6,
        MPE_T_ISO8601   => 7,
        MPE_T_TOKEN     => 8,
        MPE_STORE       => 10,
        MPE_STORE_GETALL=> 11,
        MPE_SERVER_SEND => 20,
        MPE_SERVER_REMOVE   => 21,
        MPE_SERVER_UPDATE   => 22,
        MPE_CONTENT_LENGTH  => 30,
        MPE_JSON_PARSING=> 40,
        MPE_JSON_BAD    => 41,

        MPERRORS      => {
            0 => "Internal error",
            1 => "Incorrect value: %s",
            2 => "Incorrect bool value: %s",
            3 => "Incorrect number value: %s",
            4 => "Incorrect integer value: %s",
            5 => "Incorrect string value: %s",
            6 => "Incorrect IPv4 value: %s",
            7 => "Incorrect ISO8601 value: %s",
            8 => "Incorrect Token value: %s",
            10 => "Can't connect to store",
            11 => "Can't get data from store: %s",
            20 => "Can't send message: %s",
            21 => "Can't remove message: %s",
            22 => "Can't update message: %s",
            30 => "Request Content-Length incorrect",
            40 => "Can't load JSON from request: %s",
            41 => "Bad JSON format",
            Apache2::Const::HTTP_NO_CONTENT => "No content",
            Apache2::Const::AUTH_REQUIRED => "Auth required",
            Apache2::Const::FORBIDDEN => "Access denied",
            Apache2::Const::HTTP_NO_CONTENT => "No content",
            Apache2::Const::HTTP_BAD_REQUEST => "Bad request: %s",
            Apache2::Const::HTTP_METHOD_NOT_ALLOWED => "This method not allowed: %s",
        },
    };
my $DEBUG;

my $server;
my $server_cnt = 0;
sub server_init {
    my $r = shift;
    return 1 if $server && $server->status;
    $server_cnt++;

    $DEBUG = $r->dir_config("debug") || 0; # Debug Mode

    # Patch: http://osdir.com/ml/modperl.perl.apache.org/2014-11/msg00055.html
    unless ($PATCH_20141100055) {
        my $sver = _get_server_version();
        if ($sver && ($sver >= 2.04) && !Apache2::Connection->can('remote_ip')) { # Apache 2.4.x or larger
            eval 'sub Apache2::Connection::remote_ip { return $_[0]->client_ip }';
        }
        $PATCH_20141100055 = 1;
    }

    # Singleton CTK object
    #my $docroot = $r->document_root();
    my $datadir = catdir(sharedstatedir(), PREFIX);
    my $c = new CTK(
        prefix  => PREFIX,
        cfgfile => $r->dir_config("monotifierconfig") // undef,
        logdir  => syslogdir(),
        #logfile => catfile(syslogdir(), LOGFILENAME),
        datadir => $datadir,
    );
    $c->datadir($datadir);
    my $ctkx = CTKx->instance( c => $c );

    $server = __PACKAGE__->new( location => LOCATION );

    # Register handlers
    $server->register_handler(
            handler => "index",
            method  => "GET",
            path    => "/",
            query   => undef,
            code    => \&_index_handler,
            description => "Index",
        ) or return 0;
    $server->register_handler(
            handler => "search",
            method  => "GET",
            path    => "/search",
            query   => undef,
            code    => \&_search_handler,
            description => "Search messages"
        ) or return 0;
    $server->register_handler(
            handler => "send",
            method  => "POST",
            path    => "/",
            query   => undef,
            code    => \&_send_handler,
            description => "Send message"
        ) or return 0;
    $server->register_handler(
            handler => "check",
            method  => "GET",
            path    => "/",
            query   => "check",
            code    => \&_check_handler,
            description => "Check message by ID",
        ) or return 0;
    $server->register_handler(
            handler => "levels",
            method  => "GET",
            path    => "/levels",
            query   => undef,
            code    => \&_levels_handler,
            description => "Get allowed levels",
        ) or return 0;
    $server->register_handler(
            handler => "remove",
            method  => "DELETE",
            path    => "/",
            query   => undef,
            code    => \&_remove_handler,
            description => "Remove message by ID",
        ) or return 0;
    $server->register_handler(
            handler => "update",
            method  => "PUT",
            path    => "/",
            query   => undef,
            code    => \&_update_handler,
            description => "Update message",
        ) or return 0;
    return 1;
}
sub handler {
    my $r = shift;
    Apache2::RequestUtil->request($r);
    $r->handler('modperl');
    #$server = undef;

    # Server init
    server_init($r) or return _raise(sprintf("Can't create server instance: %s", $server->error));
    my $c = CTKx->instance->c();

    # CGI object
    my $q = new CGI if $r->method ne 'PUT';
    $r->content_type(CONTENT_TYPE);
    my $action = scalar($q ? $q->param("action") : 'default') || 'default';

    # Server instance
    my $location = $r->location || LOCATION; $location =~ s/\/+$//;

    my $uri = $r->uri || ""; $uri =~ s/\/+$//;
    my $blank = {
            status      => 1,
            error       => [],
            object_req  => $action,
            object_res  => '',
            date        => dtf("%w, %DD %MON %YYYY %hh:%mm:%ss ".tz_diff()),
            method      => $r->method,
            location    => $location,
            uri         => $uri,
            qs          => $r->args || "",
            debug       => $DEBUG ? 1 : 0,
            started     => $r->request_time,
            startedfmt  => decode(locale => Apache2::Util::ht_time($r->pool, $r->request_time, DATE_FORMAT, 0)),
            #data        => $server->data,
            server_init_count => $server_cnt,
        };
    $server->data($blank);

    #$output{handlers} = $server->{handlers} ;#if $DEBUG;
    $server->set(config => $c->config) if $DEBUG;

    # Debug headers
    my $hh = $r->headers_in();
    my @hha = ();
    while (my ($k, $v) = each %$hh) { push @hha, sprintf("%s: %s", $k, $v) }
    my $hhs = join("\n", @hha);
    #$output{rerquest_headers} = [$hhs];
    $server->set(request_headers => {%$hh}) if $DEBUG;
    _debug(sprintf("Request headers: \n%s", $hhs));

    # _set_error(\%output, 1, $repdir, $!) && return _output($r => \%output);
    #_set_error(\%output, Apache2::Const::HTTP_METHOD_NOT_ALLOWED, $meth);
    #_error("Error method %s", $meth);

    # Dispatching
    $server->run_handler(uc($r->method || "GET"), $uri, $action, $q)
        or return _raise($server->error);

    # OUTPUT
    my $tm = time();
    $server->set(finished => $tm);
    $server->set(finishedfmt => decode(locale => Apache2::Util::ht_time($r->pool, $tm, DATE_FORMAT, 0)));
    return _serialize($r => $server->data);
}
sub _index_handler {
    my $self = shift;
    my $o = shift;
    my $q = shift;
    my $r = Apache2::RequestUtil->request();
    my $data = $self->data;
    $self->set(object_res => $o);

    my $store = $self->store;
    unless ($store && $store->ping) {
        $self->_set_err(MPE_STORE);
    }

    # Information
    my $host = $r->hostname();
    my $https = $r->subprocess_env('https') ? 1 : 0;
    my $scheme = $https ? "https" : "http";
    my $port = $r->server->port(); $port ||= $https ? 443 : 80;
    my $uri = URI->new($r->uri || "/", "http");
    $uri->scheme($scheme);
    $uri->host($host);
    $uri->port($port);
    $self->set(base_url => $uri->canonical->as_string);
    my $handlers = $self->{handlers};
    my @methods = keys %$handlers;
    $self->set(allowed_methods => ["HEAD", @methods]);
    my @queries;
    foreach my $m (@methods) { # Methods
        my $method = $handlers->{$m};
        foreach my $p (keys %$method) { # Paths
            my $path = $method->{$p};
            foreach my $u (keys %$path) { # Queries
                my $query = $path->{$u};
                my $uc = $uri->clone;
                $uc->path( $p );
                $uc->query_form( action => $u ) unless $u eq 'default';
                push @queries, {
                        name => $query->{name} || 'none',
                        description => $query->{description} || '',
                        string => sprintf("%s %s", $m, $uc->canonical->as_string),
                    };
            }
        }
    }
    $self->set(allowed_handlers => [@queries]);

    $self->data($data);
    return 1; # Or 0 only!!
}
sub _search_handler {
    my $self = shift;
    my $o = shift;
    my $q = shift;
    my $r = Apache2::RequestUtil->request();
    $self->set(object_res => $o);
    my $c = CTKx->instance->c();
    my $config = $c->config;

    # Auth
    my $token = $q->param("token");
    my $exptoken = value($config => "token");
    if ($exptoken && length($exptoken)) {
        unless ($token) {
            $self->_set_err(Apache2::Const::AUTH_REQUIRED);
            return 1;
        }
        unless ($token =~ /^[a-f0-9]{64}$/i) {
            $self->_set_err(MPE_T_TOKEN, "token");
            return 1;
        }
        unless ($exptoken eq $token) {
            $self->_set_err(Apache2::Const::FORBIDDEN);
            return 1;
        }
    }

    # Search fields validation
    my $id = $q->param("id");
    $self->_set_err(MPE_T_NUMBER, "id") if $id && !is_num($id);
    my $ip = $q->param("ip");
    $self->_set_err(MPE_T_IPV4, "ip") if $ip && !is_ipv4($ip);
    my $host = $q->param("host");
    $self->_set_err(MPE_T_STRING, "host") if $host && !length($host);
    my $ident = $q->param("ident");
    $self->_set_err(MPE_T_STRING, "ident") if $ident && !length($ident);
    my $level = $q->param("level");
    $level = getLevelName($level) if $level && is_int8($level);
    if ($level && length($level)) {
        my $ln = getLevelByName($level);
        $self->_set_err(MPE_T_ANY, "level") unless defined($ln) && $ln >= 0;
    }
    my $to = $q->param("to");
    $self->_set_err(MPE_T_ANY, "to") if defined($to) && !length($to);
    my $from = $q->param("from");
    $self->_set_err(MPE_T_ANY, "from") if defined($from) && !length($from);
    my $status = $q->param("status");
    $self->_set_err(MPE_T_STRING, "status") if defined($status) && !length($status);
    my $errcode = $q->param("errcode");
    $self->_set_err(MPE_T_INTEGER, "errcode") if defined($errcode) && !is_int8($errcode);
    my $pubdate = $q->param("pubdate");
    $self->_set_err(MPE_T_NUMBER, "pubdate") if defined($pubdate) && !is_num($pubdate);
    return 1 unless $self->get("status");

    my $store = $self->store;
    unless ($store && $store->ping) {
        $self->_set_err(MPE_STORE);
        return 1;
    }
    my @table = $store->getall(
            id      => $id,
            ip      => $ip,
            host    => $host,
            ident   => $ident,
            level   => ($level ? getLevelByName($level) : undef),
            to      => $to,
            from    => $from,
            status  => $status,
            errcode => $errcode,
            pubdate => $pubdate,
        );
    unless ($store->status) {
        $self->_set_err(MPE_STORE_GETALL, $store->error);
        return 1;
    }

    $self->set( messages => \@table );
    return 1; # Or 0 only!!
}
sub _send_handler {
    my $self = shift;
    my $o = shift;
    my $q = shift;
    my $r = Apache2::RequestUtil->request();
    $self->set(object_res => $o);
    my $c = CTKx->instance->c();
    my $config = $c->config;

    # Auto
    my $ip = $r->connection->remote_ip || LOCALHOSTIP;
    unless (is_ipv4($ip)) {
        $self->_set_err(MPE_T_IPV4, "remote ip (client ip)");
        return 1;
    }
    my $host = resolve($ip) || "";

    # Auth
    my $token = $q->param("token");
    my $exptoken = value($config => "token");
    if ($exptoken && length($exptoken)) {
        unless ($token) {
            $self->_set_err(Apache2::Const::AUTH_REQUIRED);
            return 1;
        }
        unless ($token =~ /^[a-f0-9]{64}$/i) {
            $self->_set_err(MPE_T_TOKEN, "token");
            return 1;
        }
        unless ($exptoken eq $token) {
            $self->_set_err(Apache2::Const::FORBIDDEN);
            return 1;
        }
    }

    # User
    my $ident = $q->param("ident");
    $self->_set_err(MPE_T_STRING, "ident") if $ident && length($ident) > 255;
    my $level = $q->param("level");
    $level = getLevelName($level) if $level && is_int8($level);
    if ($level && length($level)) {
        my $ln = getLevelByName($level);
        $self->_set_err(MPE_T_ANY, "level") unless defined($ln) && $ln >= 0;
    }
    my $to = $q->param("to");
    Encode::_utf8_on($to) if defined($to);
    $self->_set_err(MPE_T_ANY, "to") unless defined($to) && length($to) && length($to) < 255;
    my $from = $q->param("from");
    Encode::_utf8_on($from) if defined($from);
    $self->_set_err(MPE_T_ANY, "from") if defined($from) && length($from) > 255;

    # Message
    my $subject = $q->param("subject");
    Encode::_utf8_on($subject) if defined($subject);
    $self->_set_err(MPE_T_ANY, "subject") if defined($subject) && length($subject) > 255;
    my $message = $q->param("message");
    Encode::_utf8_on($message) if defined($message);

    # Additional fields
    my $comment = $q->param("comment");
    Encode::_utf8_on($comment) if defined($comment);
    my $pubdate = $q->param("pubdate");
    if (defined($pubdate) && length($pubdate)) {
        if (is_num($pubdate)) {
            $self->_set_err(MPE_T_NUMBER, "pubdate") if $pubdate <= 0;
        } else {
            if (is_iso8601($pubdate)) {
                $pubdate = iso2time($pubdate);
            } else {
                $self->_set_err(MPE_T_ISO8601, "pubdate");
            }
        }
    }
    my $expires = $q->param("expires");

    return 1 unless $self->get("status");

    my $id = $self->send(
        # -- Auto
        ip      => $ip,
        host    => $host,
        # -- User
        ident   => $ident,
        level   => getLevelByName($level || "debug"),
        to      => $to,
        from    => $from,
        # -- Message
        subject => $subject,
        message => $message,
        # -- Additional fields
        comment => $comment,
        pubdate => $pubdate || time, # Время когда начать попытки отправки. Может быть в будущем
        expires => $expires, # Время когда закончить попытки отправки
    );

    unless ($self->status) {
        $self->_set_err(MPE_SERVER_SEND, $self->error);
        return 1;
    }

    $self->set(id => $id);
    return 1; # Or 0 only!!
}
sub _check_handler {
    my $self = shift;
    my $o = shift;
    my $q = shift;
    my $r = Apache2::RequestUtil->request();
    $self->set(object_res => $o);
    my $c = CTKx->instance->c();
    my $config = $c->config;

    # Auth
    my $token = $q->param("token");
    my $exptoken = value($config => "token");
    if ($exptoken && length($exptoken)) {
        unless ($token) {
            $self->_set_err(Apache2::Const::AUTH_REQUIRED);
            return 1;
        }
        unless ($token =~ /^[a-f0-9]{64}$/i) {
            $self->_set_err(MPE_T_TOKEN, "token");
            return 1;
        }
        unless ($exptoken eq $token) {
            $self->_set_err(Apache2::Const::FORBIDDEN);
            return 1;
        }
    }

    my $id = $q->param("id");
    $self->_set_err(MPE_T_NUMBER, "id") unless $id && is_num($id);
    return 1 unless $self->get("status");

    my $store = $self->store;
    unless ($store && $store->ping) {
        $self->_set_err(MPE_STORE);
        return 1;
    }
    my %rec = $store->get($id);
    unless ($store->status) {
        $self->_set_err(MPE_STORE_GETALL, $store->error);
        return 1;
    }

    $self->set( message => {%rec} );

    return 1; # Or 0 only!!
}
sub _levels_handler {
    my $self = shift;
    my $o = shift;
    my $q = shift;
    my $r = Apache2::RequestUtil->request();
    $self->set(object_res => $o);

    my $levels = LEVELS;
    $self->set( available_levels => [(sort {$levels->{$a} <=> $levels->{$b}} keys(%$levels))] );
    $self->set( levels => {%$levels} );

    return 1; # Or 0 only!!
}
sub _remove_handler {
    my $self = shift;
    my $o = shift;
    my $q = shift;
    my $r = Apache2::RequestUtil->request();
    $self->set(object_res => $o);
    my $c = CTKx->instance->c();
    my $config = $c->config;

    # Auth
    my $token = $q->param("token");
    my $exptoken = value($config => "token");
    if ($exptoken && length($exptoken)) {
        unless ($token) {
            $self->_set_err(Apache2::Const::AUTH_REQUIRED);
            return 1;
        }
        unless ($token =~ /^[a-f0-9]{64}$/i) {
            $self->_set_err(MPE_T_TOKEN, "token");
            return 1;
        }
        unless ($exptoken eq $token) {
            $self->_set_err(Apache2::Const::FORBIDDEN);
            return 1;
        }
    }

    my $id = $q->param("id");
    $self->_set_err(MPE_T_NUMBER, "id") unless $id && is_num($id);
    return 1 unless $self->get("status");

    my $status = $self->remove($id);
    unless ($self->status) {
        $self->_set_err(MPE_SERVER_REMOVE, $self->error);
        return 1;
    }

    return 1; # Or 0 only!!
}
sub _update_handler {
    my $self = shift;
    my $o = shift;
    my $q = shift;
    my $r = Apache2::RequestUtil->request();
    $self->set(object_res => $o);
    my $c = CTKx->instance->c();
    my $config = $c->config;

    my $pool = "";
    my $buffer;
    my $cnt = 0;
    while ( my $bytesread = $r->read($buffer, 1024) ) {
        $pool .= $buffer if defined $buffer;
        $cnt += $bytesread;
    }
    my $cl = $r->headers_in->{'Content-Length'} || 0;
    unless (length($pool)) {
        $self->_set_err(Apache2::Const::HTTP_NO_CONTENT);
        return 1;
    }
    unless ($cl && $cnt == $cl) {
        $self->_set_err(MPE_CONTENT_LENGTH);
        return 1;
    }
    Encode::_utf8_on($pool);
    #print STDERR $pool;

    my $struct;
    try {
        my $in = from_json($pool, {utf8 => 0});
        if ($in && ((ref($in) eq 'HASH') || ref($in) eq 'ARRAY')) {
            if (ref($in) eq 'ARRAY') {
                $struct = shift(@$in) || {};
            } else { # HASH
                $struct = $in;
            }
        } else {
            $self->_set_err(MPE_JSON_BAD);
        }
    } catch {
        $self->_set_err(MPE_JSON_PARSING, $_);
    };
    return 1 unless $self->get("status");

    #$self->set(data => $struct);

    my $id = $struct->{id};
    $self->_set_err(MPE_T_NUMBER, "id") unless $id && is_num($id);
    return 1 unless $self->get("status");

    # Auth
    my $token = $struct->{token};;
    my $exptoken = value($config => "token");
    if ($exptoken && length($exptoken)) {
        unless ($token) {
            $self->_set_err(Apache2::Const::AUTH_REQUIRED);
            return 1;
        }
        unless ($token =~ /^[a-f0-9]{64}$/i) {
            $self->_set_err(MPE_T_TOKEN, "token");
            return 1;
        }
        unless ($exptoken eq $token) {
            $self->_set_err(Apache2::Const::FORBIDDEN);
            return 1;
        }
    }

    my $status = $self->update(%$struct);
    unless ($self->status) {
        $self->_set_err(MPE_SERVER_UPDATE, $self->error);
        return 1;
    }

    return 1; # Or 0 only!!
}

sub _serialize {
    my $r = shift;
    my $out = shift;
    my $output = to_json($out, { utf8  => 0, pretty => 1, });
    $r->headers_out->set('Accept-Ranges', 'none');
    $r->set_content_length(length(Encode::encode_utf8($output)) || 0);
    return Apache2::Const::OK if uc($r->method) eq "HEAD";
    $r->print($output);
    $r->rflush();
    return Apache2::Const::OK;
}
sub _set_err {
    my $self = shift;
    my $code = shift || 0;
    my @data = @_;
    my $msg = sprintf(MPERRORS->{$code}, @data);
    my $err = $self->get("error");
    $err = [] unless $err && is_array($err);
    push @$err, {code => $code, message => $msg};
    $self->set(status => 0);
    _debug(sprintf("Error: code=%d; message=\"%s\"", $code, $msg));
    return 1;
}
sub _debug {
    my $msg = shift;
    return 1 unless $DEBUG;
    return 0 unless defined $msg;
    my $r = Apache2::RequestUtil->request();
    $r->log->debug(sprintf("%s> %s", PREFIX, $msg));
    return 1;
}
sub _error {
    my $msg = shift;
    return 0 unless defined $msg;
    my $r = Apache2::RequestUtil->request();
    $r->log->error(sprintf("%s> %s", PREFIX, $msg));
    return 1;
}
sub _raise {
    my $errmsg = shift;
    my $r = Apache2::RequestUtil->request();
    my $notes = $r->notes;
    _error($errmsg);
    $ENV{REDIRECT_ERROR_NOTES} = $errmsg;
    $r->subprocess_env(REDIRECT_ERROR_NOTES => $errmsg);
    $notes->set('error-notes' => $errmsg);
    return Apache2::Const::SERVER_ERROR;
}

sub _get_server_version {
    return 0 unless $ENV{MOD_PERL};
    my $sver = Apache2::ServerUtil::get_server_banner() || '';
    $sver =~ s/^.+?\///;
    if ($sver =~ /([0-9]+)\.([0-9]+)\.([0-9]+)/) {
        return $1 + ($2/100) + ($3/10000);
    } elsif ($sver =~ /([0-9]+)\.([0-9]+)/) {
        return $1 + ($2/100);
    } elsif ($sver =~ /([0-9]+)/) {
        return $1;
    }
    return 0
}

1;
__END__
