package App::MBUtiny::Collector::Server; # $Id: Server.pm 131 2019-07-16 18:45:44Z abalama $
use strict;
use warnings;
use utf8;

=encoding utf-8

=head1 NAME

App::MBUtiny::Collector::Server - MBUtiny collector server

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use CGI;
    use App::MBUtiny::Collector::Server "/mbutiny";

    my $q = new CGI;
    my $server = new App::MBUtiny::Collector::Server(
        project => "MBUtiny",
        ident   => "mbutiny",
        log     => "on",
        logfd   => fileno(STDERR),
    );
    $server->status or die($server->error);
    print $server->call($q->request_method, $q->request_uri, $q)
      or die($server->error);

=head1 DESCRIPTION

MBUtiny collector server

This class provides L<WWW::MLite> REST server methods for MBUtiny collector

See C<collector.cgi.sample> file for example

=cut

use vars qw/ $VERSION $BASE_URL_PATH_PREFIX /;
$VERSION = '1.01';

use base qw/WWW::MLite/;

use Encode;
use HTTP::Status qw/:constants :is/;
use HTTP::Date;
use URI;
use App::MBUtiny::Util qw/explain/;
use App::MBUtiny::Collector::DBI;
use CTK::Serializer;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;

use constant {
    URL_PATH_PREFIX     => "/mbutiny",
    CONTENT_TYPE        => "application/json; charset=utf-8",
    SERIALIZE_FORMAT    => 'json',
    SR_ATTRS            => {
        json => [
            { # For serialize
                utf8 => 0,
                pretty => 1,
                allow_nonref => 1,
                allow_blessed => 1,
            },
            { # For deserialize
                utf8 => 0,
                allow_nonref => 1,
                allow_blessed => 1,
            },
        ],
    },
};

$BASE_URL_PATH_PREFIX = URL_PATH_PREFIX;
sub import {
    my $pkg = shift;
    $BASE_URL_PATH_PREFIX = shift || URL_PATH_PREFIX;

=head1 METHODS

WWW::MLite methods

=head2 GET /mbutiny

    curl -v --raw http://localhost/mbutiny

    > GET /mbutiny HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.62.0
    > Accept: */*
    >
    < HTTP/1.1 200 OK
    < Date: Wed, 19 Jun 2019 10:57:31 GMT
    < Server: Apache/2.2.25 (Win32) mod_ssl/2.2.25 OpenSSL/0.9.8y mod_perl/2.0.8 Perl/v5.16.3
    < Connection: close
    < Content-Length: 214
    < Content-Type: application/json; charset=utf-8
    <
    {
       "dsn" : "dbi:SQLite:dbname=/var/lib/mbutiny/mbutiny.db",
       "status" : 1,
       "name" : "check",
       "error" : "",
       "method" : "GET",
       "path" : "/mbutiny",
       "description" : "Check collectors"
    }

    curl -v --raw http://localhost/mbutiny/foo

    > GET /mbutiny/foo HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.58.0
    > Accept: */*
    >
    < HTTP/1.1 200 OK
    < Date: Sat, 22 Jun 2019 10:29:26 GMT
    < Server: Apache/2.4.29 (Ubuntu)
    < Connection: close
    < Content-Length: 556
    < Content-Type: application/json; charset=utf-8
    <
    {
       "name" : "foo",
       "error" : "",
       "file" : null,
       "status" : 1,
       "time" : 0.0073,
       "info" : {
          "comment" : "Local storages...",
          "sha1" : "4200f422b425967ca2cb278cf311edeb74ecdde1",
          "addr" : "127.0.0.1",
          "file" : "foo-2019-06-22.tar.gz",
          "type" : 1,
          "status" : 1,
          "time" : 1561194766,
          "md5" : "008413f90584f4af5d5a49c7c0ec64c2",
          "id" : 13,
          "size" : 501,
          "name" : "foo",
          "error" : ""
       }
    }

=cut

__PACKAGE__->register_method( # GET /mbutiny
    name    => "check",
    description => "Check collectors",
    method  => "GET",
    path    => $BASE_URL_PATH_PREFIX,
    deep    => 1,
    attrs   => {
            serialize   => 1,
        },
    requires => undef,
    returns => undef,
    code    => sub {
### CODE:
    my $self = shift;
    my $q = shift;
    my $dbi = $self->dbi;
    my @params = @_;
    my $name = _get_name_from_path($self->{request_uri} // "");
    if ($name) {
        my $file = $q->param("file");
        my %data = $dbi->get(name => $name, file => $file);
        if ($dbi->error) {
            $self->error($dbi->error);
            $self->status(0);
            return HTTP_INTERNAL_SERVER_ERROR;
        }
        $self->data({
            name   => $name,
            file   => $file,
            info   => \%data,
        });
    } else {
        $self->data({
            dsn     => $dbi->dsn,
            #params  => [@params],
            name    => $self->name,
            description => $self->info("description"),
            #attrs  => $self->info("attrs"),
            path    => $self->info("path"),
            method  => $self->info("method"),
            #requires => $self->info("requires"),
            #returns => $self->info("returns"),
        });
    }

    return HTTP_OK; # HTTP RC
    #return HTTP_INTERNAL_SERVER_ERROR; # HTTP RC
});

=head2 GET /mbutiny/list

    curl -v --raw http://localhost/mbutiny/list?name=foo

    > GET /mbutiny/list HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 31 May 2019 05:41:34 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Connection: close
    < Content-Length: 16
    < Content-Type: text/plain
    <
    {
       "time" : 0.0012,
       "list" : [...],
       "status" : 1,
       "error" : ""
    }

=cut

__PACKAGE__->register_method( # GET /mbutiny/list
    name    => "list",
    method  => "GET",
    path    => "$BASE_URL_PATH_PREFIX/list",
    deep    => 0,
    attrs   => {
            serialize   => 1,
        },
    description => "Get list of files by name",
    code    => sub {
### CODE:
    my $self = shift;
    my $q = shift;
    my $dbi = $self->dbi;
    my $name = $q->param("name") || '';
    unless ($name) {
        $self->error("The name attribute required!");
        $self->{status} = 0;
        return HTTP_BAD_REQUEST;
    }
    my @table = $dbi->list(name => $name);
    if ($dbi->error) {
        $self->error($dbi->error);
        $self->status(0);
        return HTTP_INTERNAL_SERVER_ERROR;
    }
    $self->data({
        list => \@table,
    });
    return HTTP_OK; # HTTP RC
});

=head2 GET /mbutiny/report

    curl -v --raw http://localhost/mbutiny/report?start=1561799700

    > GET /mbutiny/report HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 31 May 2019 05:41:34 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Connection: close
    < Content-Length: 16
    < Content-Type: text/plain
    <
    {
       "time" : 0.0012,
       "report" : [...],
       "status" : 1,
       "error" : ""
    }

=cut

__PACKAGE__->register_method( # GET /mbutiny/report
    name    => "report",
    method  => "GET",
    path    => "$BASE_URL_PATH_PREFIX/report",
    deep    => 0,
    attrs   => {
            serialize   => 1,
        },
    description => "Get backup report by start time",
    code    => sub {
### CODE:
    my $self = shift;
    my $q = shift;
    my $dbi = $self->dbi;
    my $start = $q->param("start") || 0;
    unless (is_int($start)) {
        $self->error("The start attribute is not integer value type!");
        $self->{status} = 0;
        return HTTP_BAD_REQUEST;
    }
    my @table = $dbi->report(start => $start);
    if ($dbi->error) {
        $self->error($dbi->error);
        $self->status(0);
        return HTTP_INTERNAL_SERVER_ERROR;
    }
    $self->data({
        report => \@table,
    });
    return HTTP_OK; # HTTP RC
});

=head2 POST /mbutiny

    curl -v -d '{ "type": 1, "name": "foo", "file": "foo", "size": 501, "md5": "3a5fb8a1e0564eed5a6f5c4389ec5fa0", "sha1": "22d12324fa2256e275761b55d5c063b8d9fc3b95", "status": 1, "error": "", "comment": "Test external fixup!"}' --raw -H "Content-Type: application/json" http://localhost/mbutiny

    > POST /mbutiny HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    > Content-Type: application/json
    > Content-Length: 27
    >
    < HTTP/1.1 200 OK
    < Date: Thu, 20 Jun 2019 15:03:34 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Connection: close
    < Content-Length: 27
    < Content-Type: text/plain; charset=utf-8
    <

=cut

__PACKAGE__->register_method( # POST /mbutiny
    name    => "add",
    method  => "POST",
    path    => $BASE_URL_PATH_PREFIX,
    deep    => 0,
    attrs   => {
            deserialize => 1,
            serialize   => 1,
        },
    description => "Add new data",
    code    => sub {
### CODE:
    my $self = shift;
    my $q = shift;
    my $dbi = $self->dbi;
    my $data = $self->data;
    $self->data({}); # Flush data!
    my %args = is_hash($data) ? %$data : ();
    unless (%args) {
        $self->error("No input data!");
        $self->status(0);
        return HTTP_BAD_REQUEST;
    }

    $dbi->add(
        type    => $args{type},
        name    => $args{name},
        file    => $args{file},
        size    => $args{size},
        md5     => $args{md5},
        sha1    => $args{sha1},
        status  => $args{status},
        error   => $args{error},
        comment => $args{comment},
        addr    => $ENV{REMOTE_ADDR},
    ) or do {
        $self->error($dbi->error());
        $self->status(0);
        return HTTP_INTERNAL_SERVER_ERROR;
    };

    return HTTP_OK; # HTTP RC
});

=head2 DELETE /mbutiny/NAME

    curl -v --raw -X DELETE http://localhost/mbutiny/NAME?file=name&type=1

    > DELETE /mbutiny/NAME?file=name HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.58.0
    > Accept: */*
    >
    < HTTP/1.1 204 No Content
    < Date: Fri, 21 Jun 2019 21:40:36 GMT
    < Server: Apache/2.4.29 (Ubuntu)
    < Connection: close
    < Content-Type: text/plain
    <

=cut

__PACKAGE__->register_method( # DELETE /mbutiny/NAME
    name    => "delete",
    method  => "DELETE",
    path    => $BASE_URL_PATH_PREFIX,
    deep    => 1,
    attrs   => {
        serialize => 1,
    },
    description => "Delete file",
    code    => sub {
### CODE:
    my $self = shift;
    my $q = shift;
    my $dbi = $self->dbi;
    my $name = _get_name_from_path($self->{request_uri} // "");
    unless ($name) {
        $self->error("Incorrect path! Check backup host name");
        $self->status(0);
        return HTTP_BAD_REQUEST;
    }
    my $file = $q->param("file");
    unless ($file) {
        $self->error("Incorrect file name for delete");
        $self->status(0);
        return HTTP_BAD_REQUEST;
    }
    my $type = $q->param("type") // 0;

    $dbi->del(
        type    => $type,
        name    => $name,
        file    => $file,
        addr    => $ENV{REMOTE_ADDR},
    ) or do {
        $self->error($dbi->error());
        $self->status(0);
        return HTTP_INTERNAL_SERVER_ERROR;
    };

    return HTTP_NO_CONTENT; # HTTP RC
});

    return 1;
}

sub again {
    my $self = shift;
    $self->SUPER::again;

    # Serializer
    my $sr = new CTK::Serializer(SERIALIZE_FORMAT, attrs => SR_ATTRS);
    unless ($sr->status) {
        $self->error(sprintf("Can't create json serializer: %s", $sr->error));
        $self->{status} = 0;
    }
    $self->{sr} = $sr;

    # DBI object
    my $dbi_conf = $self->config('dbi') || {};
    $dbi_conf = {} unless is_hash($dbi_conf);
    my $dbi = new App::MBUtiny::Collector::DBI(%$dbi_conf);
    $self->log_error($dbi->error) if $dbi->error;
    $self->{dbi} = $dbi;

    return $self;
}
sub serializer {
    my $self = shift;
    return $self->{sr};
}
sub dbi {
    my $self = shift;
    return $self->{dbi};
}
sub middleware {
    my $self = shift;
    my $q = shift;

    # Check DBI connect
    if ($self->dbi->error) { # DBI checking
        $self->error($self->dbi->error);
        $self->status(0);
    }
    $self->{_time} = sprintf("%.4f", $self->tms(1))*1;
    return HTTP_INTERNAL_SERVER_ERROR unless $self->status;

    # Prepare input data
    my $meth = $self->info->{method} || "GET";
    if ($meth =~ /POST|PUT|PATCH/) {
        my $data = $q->param($meth."DATA") // $q->param('XForms:Model');
        Encode::_utf8_on($data);
        if (value($self->info("attrs"), "deserialize")) {
            my $serializer = $self->serializer;
            $self->data($serializer->deserialize($data));
            unless ($serializer->status) {
                $self->error(sprintf("Can't deserialize document: %s", $serializer->error));
                $self->status(0);
                return HTTP_INTERNAL_SERVER_ERROR;
            }
        } else {
            $self->data($data);
        }
    }

    return HTTP_OK;
}
sub response {
    my $self = shift;
    my $q = shift;
    my $rc = $self->code; # RC HTTP code (from yuor methods)
    my $head = $self->head || {}; # HTTP Headers (hashref)
    my $data = $self->data; # The working data
    my $msg = $self->message || HTTP::Status::status_message($rc) || "Unknown code";
    $data = {status => 0, error => $self->error || "Unknown error"} if !$self->status && (is_void($data) || $data eq "");
    return $self->SUPER::response unless $data && ref($data);
    return $self->SUPER::response unless value($self->info("attrs"), "serialize");
    #binmode STDOUT, ":raw:utf8"; # Disabled, by encoding reasons. See SUPER::response (utf8::encode($content))

    # Set debug time
    $data->{'time'} = sprintf("%.4f", sprintf("%.4f", $self->tms(1))*1 - $self->{_time})*1;

    # Set status and response
    $data->{status} = $self->status;
    $data->{error} = $self->error;

    # Headers
    $head->{Server} = sprintf("%s/%s", __PACKAGE__, $VERSION);
    $head->{Connection} = "close";
    $head->{Date} = HTTP::Date::time2str(time());
    $head->{'Content-Type'} = CONTENT_TYPE;
    $self->head($head);

    my $serializer = $self->serializer;
    $self->data($serializer->serialize($data));

    unless ($serializer->status) {
        my $errmsg = sprintf("Can't serialize structure: %s", $serializer->error);
        $errmsg =~ s/\"/\\\"/g;
        $errmsg =~ s/\'/\\\'/g;
        $self->data(sprintf('{"status": 0, "error": "%s"}', $errmsg));
        $self->code(HTTP_INTERNAL_SERVER_ERROR);
    }

    #my @res = (sprintf("Status: %s %s", $rc, $msg));
    #push @res, sprintf("Content-Type: %s", "text/plain; charset=utf-8");
    #push @res, "", $data // "";
    #return join("\015\012", @res);

    return $self->SUPER::response;
}

sub _get_name_from_path {
    my $request_uri = shift // '';
    my $uri = new URI(sprintf("http://localhost%s", $request_uri));
    my $str = $uri->path() // "";
    return "" unless length($str);
    return "" if index($str, $BASE_URL_PATH_PREFIX, 0);
    my $sfx = substr($str, length($BASE_URL_PATH_PREFIX)) || "";
    $sfx =~ s/^\/+//;
    $sfx =~ s/\/+/\-/g;
    return $sfx;
}

=head1 INTERNAL METHODS

=head2 again

The CTK method for classes extension

See L<CTK/again>

=head2 dbi

Returns L<App::MBUtiny::Collector::DBI> object

=head2 middleware

The L<WWW::MLite> method for input data preparing

=head2 response

The L<WWW::MLite> method for output data preparing

=head2 serializer

Returns current serializer object

See L<CTK::Serializer>

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<App::MBUtiny>, L<WWW::MLite>, L<App::MBUtiny::Collector::DBI>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

1;

__END__

__PACKAGE__->register_method( # GET /mbutiny/dump
    name    => "getDump",
    method  => "GET",
    path    => "$BASE_URL_PATH_PREFIX/dump",
    deep    => 0,
    attrs   => {},
    description => "Test (GET dump)",
    code    => sub {
### CODE:
    my $self = shift;
    $self->data(explain($self));
    return HTTP_OK; # HTTP RC
});

__PACKAGE__->register_method( # GET /mbutiny/env
    name    => "getEnv",
    method  => "GET",
    path    => "$BASE_URL_PATH_PREFIX/env",
    deep    => 0,
    attrs   => {},
    description => "Test (GET env)",
    code    => sub {
### CODE:
    my $self = shift;
    $self->data(explain(\%ENV));
    return HTTP_OK; # HTTP RC
});
