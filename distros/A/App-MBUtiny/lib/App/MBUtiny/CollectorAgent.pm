package App::MBUtiny::CollectorAgent; # $Id: CollectorAgent.pm 60 2014-09-09 13:33:32Z abalama $
use strict;

=head1 NAME

App::MBUtiny::CollectorAgent - Agent for access to App::MBUtiny collector server

=head1 VIRSION

Version 1.02

=head1 SYNOPSIS

    use App::MBUtiny::CollectorAgent;
    
    my $agent = new App::MBUtiny::CollectorAgent(
            uri => "https://mbutiny.example.com/collector.cgi",
        );
    
    my $status = $agent->check;
    
    if ($status) {
        print STDOUT $agent->response->{data}{message};
    } else { 
        print STDERR $agent->error;
    }

=head1 DESCRIPTION

Agent for access to App::MBUtiny collector server

=head1 METHODS

=over 8

=item B<new>

    my $agent = new App::MBUtiny::CollectorAgent(
            uri         => $uri, # Collector URI
            user        => $user, # optional
            password    => $password, # optional
            timeout     => $timeout, # default: 180
        );

Returns agent

=item B<check>

    my $status = $agent->check;

Returns check-status of collector. 0 - Error; 1 - Ok

See README file for details of data format

=item B<del>

    my $status = $agent->del(
            host => $hostname,
            file => $filename,
        );

Request for deleting of file on collector by hostname and filename.
The method returns status of operation: 0 - Error; 1 - Ok

See README file for details of data format

=item B<download>

    my $status = $agent->download(
            host => $hostname,
            file => $filename,
            path => "/file/to/write",
        );

Request for download file on collector by hostname and filename.
Result will be written to "path" file.
The method returns status of operation: 0 - Error; 1 - Ok

See README file for details of data format

=item B<error>

    print $agent->error;

Returns error string

=item B<fixup>

    $status = $agent->fixup(
            type    => $type, # 0 - external / 1 - internal (Uploaded earlier)
            id      => $id, # ID of file (type = 1 only)
            host    => $hostname,
            file    => $filename,
            path    => $filepath, # /path/to/filename
            sha1    => $sha1, # Optional
            md5     => $md5,  # Optional
            status  => $status, # 1 - good backup / 0 - bad backup
            comment => $comment, # Optional
            message => "Your files successfully stored ...", # Optional
        );

Request for fixupping of backup on collector by hostname and others parameters.
The method returns status of operation: 0 - Error; 1 - Ok

See README file for details of data format

=item B<info>

    my $status = $agent->info(
            host => $hostname,
            file => $filename,
        );

Request for getting information about file on collector by hostname and filename.
The method returns status of operation: 0 - Error; 1 - Ok

See README file for details of data format

=item B<list>

    my $status = $agent->list(
            host => $hostname,
        );

Request for getting list of files on collector by hostname.
The method returns status of operation: 0 - Error; 1 - Ok

See README file for details of data format

=item B<report>

    my $status = $agent->report(
            host    => $hostname, # Optional. Default: all hosts
            start   => '01.09.2014', # Optional. Default: current date
            finish  => '09.09.2014', # Optional. Default: current date
            type    => 2, # 0 - external; 1 - internal; 2 - both (all, default)
        );

Request for getting report of backup on collector by hostname.
The method returns status of operation: 0 - Error; 1 - Ok

See README file for details of data format

=item B<request>

    my $request = $agent->request;

Returns request hash

=item B<response>

    my $response = $agent->response;

Returns response hash

=item B<status>

    my $status = $agent->status;

Returns object status value. 0 - Error; 1 - Ok

=item B<upload>

    $status = $agent->upload(
            host    => $hostname,
            file    => $filename,
            path    => $filepath, # /path/to/filename
            sha1    => $sha1, # Optional
            md5     => $md5,  # Optional
            comment => $comment, # Optional
        );

Request for uploading of backup on collector by hostname and others parameters.
The method returns status of operation: 0 - Error; 1 - Ok

See README file for details of data format

=back

=head1 HISTORY

See C<CHANGES> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MBUtiny>

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2014 D&D Corporation. All Rights Reserved

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

use vars qw/ $VERSION /;
$VERSION = '1.02';

use Encode;
use CTK::Util qw/ :API /;
use CTK::TFVals qw/ :ALL /;
use CTK::ConfGenUtil;
use XML::Simple;
use Try::Tiny;
use App::MBUtiny::Util;
use Text::Unidecode;

# LWP
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use HTTP::Headers;

use constant {
        REQ_ROOTNAME    => 'request',
        RES_ROOTNAME    => 'response',
        XMLDECL         => '<?xml version="1.0" encoding="utf-8"?>',
    };

our $DEBUG = 0;

sub new {
    my $class = shift;
    my %data  = @_;
    #carp( "Can't defined URI" ) unless $data{uri};
    
    # Create a user agent object
    my $ua = new LWP::UserAgent(
        agent => "MBUtiny/1.0",
        max_redirect => 10,
        requests_redirectable => ['GET','HEAD','POST'],
        protocols_allowed     => ['http', 'https', 'ftp'],
        timeout               => $data{timeout} || 180,
    );
    $ua->default_header('Cache-Control' => "no-cache");
    
    # Auth
    my $login = fv2null($data{user});
    my $passw = fv2null($data{password});
    $ua->add_handler( request_prepare => sub { 
            my($req, $ua, $h) = @_;
            $req->authorization_basic( $login, $passw );
            return $req;
        } ) if $login;

    return bless {
            uri     => $data{uri} || '',
            user    => $data{user},
            password=> $data{password},
            error   => '',
            status  => 1, # Ok
            ua      => $ua,
            request => {},
            response=> {},
        }, $class;
}
sub error { 
    my $self = shift;
    my $s = shift;
    $self->{error} = $s if defined $s;
    return $self->{error};
}
sub status { 
    my $self = shift;
    my $s = shift;
    $self->{status} = $s if defined $s;
    return $self->{status};
}
sub request { 
    my $self = shift;
    my $s = shift;
    $self->{request} = $s if defined $s;
    return $self->{request};
}
sub response { 
    my $self = shift;
    my $s = shift;
    $self->{response} = $s if defined $s;
    return $self->{response};
}
sub upload { 
    my $self = shift;
    my %data = @_;
    my $object = "upload";
    
    # Data for XML request
    my $xml_data = {
            host => [$data{host}],   # имя хоста
            file => [$data{file}],   # имя файла
        };
    $xml_data->{sha1} = [$data{sha1}] if $data{sha1}; # SHA1 для проверки (необязательный параметр)
    $xml_data->{md5} = [$data{md5}] if $data{md5};    # MD5 для проверки (необязательный параметр)
    $xml_data->{comment} = [$data{comment}] if $data{comment}; # Комментарий (необязательный параметр)
    
    # Установка реквеста
    $self->request({
            object  => [$object],
            data    => $xml_data,
        });

    return $self->_send_request($object, {
            Content_Type => 'form-data',
            Content      => [
                    action  => $object, 
                    request => XMLout(
                            $self->request,
                            RootName => REQ_ROOTNAME, XMLDecl => XMLDECL,
                        ),
                    data    => [$data{path}],
                ]
        });
}
sub check { 
    my $self = shift;
    $self->request({ object => ["check"] });
    return $self->_send_request("check");
}
sub fixup { 
    my $self = shift;
    my %data = @_;
    my $object = "fixup";
    
    # Data
    my $id = $data{id} || 0;
    my $type = defined($data{type}) ? $data{type} : ((is_int($id) && $id) ? 1 : 0);

    # Data for XML request
    my $xml_data = {
            status  => [$data{status} ? 1 : 0],
        };
    if ($type && is_int($type) && $type == 1) {
        # Запись уже в БД существует, нужно просто добавить МИНИМУМ данных
        $xml_data->{type}   = [1]; # Internal
        $xml_data->{id}     = [$id];
    } else {
        # Запрос на создение записи, количество передаваемых даннх МАКСИМАЛЬНО
        $xml_data->{type}   = [0]; # External
        $xml_data->{host}   = [uv2null($data{host})]; # имя хоста
        $xml_data->{file}   = [uv2null($data{file})]; # имя файла
        $xml_data->{sha1}   = [$data{sha1}] if $data{sha1}; # SHA1 для проверки (необязательный параметр)
        $xml_data->{md5}    = [$data{md5}] if $data{md5};    # MD5 для проверки (необязательный параметр)
        my $path = $data{path};
        if ($path && -e $path ) {
            $xml_data->{size} = [-s $path || 0];
        }
    }
    $xml_data->{comment} = [$data{comment}] if $data{comment}; # Комментарий (необязательный параметр)
    $xml_data->{message} = [$data{message}] if $data{message}; # Сообщение/Ошибка (необязательный параметр)
    
    # Установка реквеста
    $self->request({
            object  => [$object],
            data    => $xml_data,
        });
    
    return $self->_send_request($object);
}
sub list { 
    my $self = shift;
    my %data = @_;
    my $object = "list";

    # Data for XML request
    my $xml_data = {
            host => [uv2null($data{host})], # имя хоста
        };
    
    # Установка реквеста
    $self->request({
            object  => [$object],
            data    => $xml_data,
        });
    
    return $self->_send_request($object);
}
sub del { 
    my $self = shift;
    my %data = @_;
    my $object = "delete";
    
    # Data for XML request
    my $xml_data = {
            host => [uv2null($data{host})], # имя хоста
            file => [uv2null($data{file})], # имя файла
        };
    
    
    # Установка реквеста
    $self->request({
            object  => [$object],
            data    => $xml_data,
        });
    
    return $self->_send_request($object);
}
sub info { 
    my $self = shift;
    my %data = @_;
    my $object = "info";
    
    # Data for XML request
    my $xml_data = {
            host => [uv2null($data{host})], # имя хоста
            file => [uv2null($data{file})], # имя файла
        };
    
    # Установка реквеста
    $self->request({
            object  => [$object],
            data    => $xml_data,
        });
    
    return $self->_send_request($object);
}
sub download { 
    my $self = shift;
    my $ua      = $self->{ua};
    my $uri     = $self->{uri};
    my %data = @_;
    $self->error("URI is not defined") && return $self->status(0) unless $uri;
    my $uri_obj = new URI($uri);
    my $object = "download";
    
    my $path = uv2null($data{path});
    $self->error("Path to file is not defined") && return $self->status(0) unless $path;
    
    # Data for XML request
    my $xml_data = {
            host => [uv2null($data{host})], # имя хоста
            file => [uv2null($data{file})], # имя файла
        };
    # Установка реквеста
    $self->request({
            object  => [$object],
            data    => $xml_data,
        });
    my $xml_request = XMLout(
        $self->request,
        RootName => REQ_ROOTNAME, XMLDecl => XMLDECL,
    );
    printf "REQUEST: %s\n%s\n",$uri, $xml_request if $DEBUG;
    
    # POST
    #my $res = $ua->post($uri_obj, 
    #            Content      => [
    #                action  => $object, 
    #                request => $xml_request,
    #            ]
    #        );    
    require HTTP::Request::Common;
    my @parameters = ($uri_obj, Content      => [
                    action  => $object, 
                    request => $xml_request,
                ]);
    my @suff = $ua->_process_colonic_headers(\@parameters, (ref($parameters[1]) ? 2 : 1));
    my $res = $ua->request( HTTP::Request::Common::POST( @parameters ), @suff, $path);

    # Success
    if ($res->is_success) {
        #printf "RESPONSE:\n%s\n", unidecode($res->content) if $DEBUG;;
        #$self->response(_read_xml($res->decoded_content));

        $self->response({
                object      => __PACKAGE__,
                query_string=> $uri_obj->query,
                remote_addr => '',
                status      => 1,
                error       => '',
                data        => {
                        file    => $res->filename,
                        message => sprintf("File %s saved to %s", uv2null($data{file}), $path),
                    },
                debug_time  => 0
            });
        $self->status(1);
        #printf "RESPONSE:\n%s\n", Data::Dumper::Dumper($self->response) if $DEBUG;
        
    } else {
        printf "STATUS_LINE: %s\n", $res->status_line if $DEBUG;
        my $content = $res->decoded_content;
        if ($content && $content =~ /<response>/s) {
            $self->response(_read_xml($content));
            printf "RESPONSE:\n%s\n", unidecode($content) if $DEBUG;;
            my $rst = $self->response;
            if ($rst->{status}) {
                $self->_check_response($object);
            } else {
                $self->error($rst->{error});
            }            
        } else {
            $self->error(sprintf("Error fetching data from %s: %s", $uri, $res->status_line));
            $self->response({
                object      => __PACKAGE__,
                query_string=> $uri_obj->query,
                remote_addr => '',
                status      => 0,
                error       => [$res->status_line],
                data        => undef,
                debug_time  => 0
            });
        }
            
        $self->status(0);
    }
    
    return $self->status;
}
sub report { 
    my $self = shift;
    my %data = @_;
    my $object = "report";
    
    my $type = 2;
    if (defined($data{type}) && $data{type} == 0) {
        $type = 0;
    } elsif(defined($data{type}) && $data{type} == 1) {
        $type = 1;
    }

    # Data for XML request
    my $xml_data = {
            host => [uv2null($data{host})], # имя хоста
            date_start => [uv2null($data{start})], # Старт
            date_finish => [uv2null($data{finish})], # Финиш
            type => [$type], # тип
        };
    
    # Установка реквеста
    $self->request({
            object  => [$object],
            data    => $xml_data,
        });
    
    return $self->_send_request($object);
}
sub _send_request {
    my $self    = shift;
    my $object  = shift;
    my $post_data = shift;
    my $ua      = $self->{ua};
    my $uri     = $self->{uri};
    $self->error("Object is not defined") && return $self->status(0) unless $object;
    $self->error("URI is not defined") && return $self->status(0) unless $uri;
    my $uri_obj = new URI($uri);
    
    # Data for XML request
    my $xml_request = XMLout(
        $self->request,
        RootName => REQ_ROOTNAME, XMLDecl => XMLDECL,
    );
    printf "REQUEST: %s\n%s\n",$uri, $xml_request if $DEBUG;

    # POST
    my $res = ($post_data && ref($post_data) eq 'HASH') 
        ? $ua->post($uri_obj, %$post_data)
        : $ua->post($uri_obj, 
            Content      => [
                    action  => $object, 
                    request => $xml_request,
                ]
            );
    
    # Success
    if ($res->is_success) {
        printf "RESPONSE:\n%s\n", unidecode($res->decoded_content) if $DEBUG;;
        $self->response(_read_xml($res->decoded_content));
        my $rst = $self->response;
        if ($rst->{status}) {
            $self->_check_response($object);
        } else {
            $self->status(0);
            $self->error($rst->{error});
        }
    } else {
        $self->error(sprintf("Error fetching data from %s: %s", $uri, $res->status_line));
        $self->response({
                object      => __PACKAGE__,
                query_string=> $uri_obj->query,
                remote_addr => '',
                status      => 0,
                error       => [$res->status_line],
                data        => undef,
                debug_time  => 0
            });
        $self->status(0);
    }
    
    return $self->status;
}
sub _check_response {
    my $self = shift;
    my $name = lc(fv2null(shift)); # optional
    
    my $respnse = $self->response;
    unless ($respnse && ref($respnse) eq 'HASH') {
        $self->error("Checking failed! Incorrect response format");
        return $self->status(0);
    }
    
    if (value($respnse => "status")) {
        # Status = 1
        return $self->status(1) if !$name || lc(value($respnse => "object")) eq $name;
        $self->error(sprintf("Checking failed! Object incorrect. Got (in response): %s; expected: %s", 
                lc(value($respnse => "object")),
                $name
            ));
    } else {
        # Status = 0
        my $errs = array($respnse => "error") || ["Checking failed! Undefined error"];
        $self->error("Checking failed!".(join("\n",@$errs)));
    }
    
    return $self->status(0);
}
sub _read_xml {
    my $request = uv2null(shift);
    my $xml;
    
    unless ($request) {
        return {
                object      => __PACKAGE__,
                remote_addr => '',
                status      => 0,
                error       => "XML Reading error! Bad XML format. No response data",
                data        => undef,
                debug_time  => 0
            };
    }
    Encode::_utf8_on($request);
    
    try {
        $xml = XMLin($request, KeyAttr => [ qw/qwertyuiop/ ]);
        unless ($xml && ref($xml) eq 'HASH') {
            $xml = {
                object      => __PACKAGE__,
                remote_addr => '',
                status      => 0,
                error       => "XML Reading error! Bad XML format",
                data        => undef,
                debug_time  => 0
            };
        }
    } catch {
        $xml = {
            object          => __PACKAGE__,
            remote_addr     => '',
            status          => 0,
            error           => sprintf("XML Reading error! Can't load XML from request \"%s\": %s", $request, $_),
            data            => undef,
            debug_time  => 0
        };
    };
    return $xml;
}
1;
