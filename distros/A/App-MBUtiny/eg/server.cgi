#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: server.cgi 121 2019-07-01 19:51:50Z abalama $
#
# The App::MBUtiny HTTP storage CGI script
#
#########################################################################
use strict;
use utf8;

=encoding utf8

=head1 NAME

The App::MBUtiny HTTP storage CGI script

=head1 SYNOPSIS

    ScriptAlias "/mbuserver" "/path/to/server.cgi"
    # ... or:
    # ScriptAliasMatch "^/mbuserver" "/path/to/server.cgi"

=head1 DESCRIPTION

This script provides the App::MBUtiny HTTP storage server methods

NOTE! Check BASE_URI_PREFIX constant first if you want change base URI prefix

=head1 EXAMPLES

=over 4

=item B<PUT /mbuserver/file.tar.gz>

    lwp-request -E -m PUT -c "application/octet-stream" "http://localhost/mbuserver/foo/bar/file.tar.gz" < file.tar.gz

Put file to server in as-is format (upload)

    PUT http://localhost/mbuserver/foo/bar/file.tar.gz
    User-Agent: lwp-request/6.15 libwww-perl/6.15
    Content-Length: 73820
    Content-Type: application/octet-stream

    201 Created
    Connection: close
    Date: Tue, 25 Jun 2019 16:41:42 GMT
    Server: Apache/2.2.25 (Win32) mod_ssl/2.2.25 OpenSSL/0.9.8y mod_perl/2.0.8 Perl/v5.16.3
    Content-Length: 0
    Content-Location: /mbuserver/foo/bar/file.tar.gz
    Content-Type: application/octet-stream; charset=ISO-8859-1
    Client-Date: Tue, 25 Jun 2019 16:41:43 GMT
    Client-Peer: 127.0.0.1:80
    Client-Response-Num: 1

=item B<GET /mbuserver>

    lwp-request -E "http://localhost/mbuserver/foo/bar"

Get list of available files in text/plain format, output is in "ls -1" format

    GET http://localhost/mbuserver/foo/bar
    User-Agent: lwp-request/6.15 libwww-perl/6.15

    200 OK
    Connection: close
    Date: Tue, 25 Jun 2019 16:49:05 GMT
    Server: Apache/2.2.25 (Win32) mod_ssl/2.2.25 OpenSSL/0.9.8y mod_perl/2.0.8 Perl/v5.16.3
    Content-Type: text/plain; charset=utf-8
    Client-Date: Tue, 25 Jun 2019 16:49:05 GMT
    Client-Peer: 127.0.0.1:80
    Client-Response-Num: 1
    Client-Transfer-Encoding: chunked

    file.tar.gz

=item B<HEAD /mbuserver/file.tar.gz>

    lwp-request -E -m HEAD "http://localhost/mbuserver/foo/bar/file.tar.gz"

Returns info about file.tar.gz file in HTTP headers

    HEAD http://localhost/mbuserver/foo/bar/file.tar.gz
    User-Agent: lwp-request/6.15 libwww-perl/6.15

    302 Found
    Connection: close
    Date: Tue, 25 Jun 2019 16:49:43 GMT
    Location: /foo/bar/file.tar.gz
    Server: Apache/2.2.25 (Win32) mod_ssl/2.2.25 OpenSSL/0.9.8y mod_perl/2.0.8 Perl/v5.16.3
    Content-Type: text/plain; charset=utf-8
    Client-Date: Tue, 25 Jun 2019 16:49:43 GMT
    Client-Peer: 127.0.0.1:80
    Client-Response-Num: 1

    HEAD http://localhost/foo/bar/file.tar.gz
    User-Agent: lwp-request/6.15 libwww-perl/6.15

    200 OK
    Connection: close
    Date: Tue, 25 Jun 2019 16:49:43 GMT
    Accept-Ranges: bytes
    ETag: "5212b100-1205c-58c289a9b4200"
    Server: Apache/2.2.25 (Win32) mod_ssl/2.2.25 OpenSSL/0.9.8y mod_perl/2.0.8 Perl/v5.16.3
    Content-Length: 73820
    Content-Type: application/x-gzip
    Last-Modified: Tue, 25 Jun 2019 16:41:44 GMT
    Client-Date: Tue, 25 Jun 2019 16:49:43 GMT
    Client-Peer: 127.0.0.1:80
    Client-Response-Num: 1

=item B<GET /mbuserver/file.tar.gz>

    lwp-request -E "http://localhost/mbuserver/foo/bar/file.tar.gz"

Returns content of file.tar.gz file (download)

    GET http://localhost/mbuserver/foo/bar/file.tar.gz
    User-Agent: lwp-request/6.15 libwww-perl/6.15

    302 Found
    Connection: close
    Date: Tue, 25 Jun 2019 16:50:50 GMT
    Location: /foo/bar/file.tar.gz
    Server: Apache/2.2.25 (Win32) mod_ssl/2.2.25 OpenSSL/0.9.8y mod_perl/2.0.8 Perl/v5.16.3
    Content-Length: 0
    Content-Type: text/plain; charset=utf-8
    Client-Date: Tue, 25 Jun 2019 16:50:50 GMT
    Client-Peer: 127.0.0.1:80
    Client-Response-Num: 1
    X-Pad: avoid browser bug

    GET http://localhost/foo/bar/file.tar.gz
    User-Agent: lwp-request/6.15 libwww-perl/6.15

    200 OK
    Connection: close
    Date: Tue, 25 Jun 2019 16:50:50 GMT
    Accept-Ranges: bytes
    ETag: "5212b100-1205c-58c289a9b4200"
    Server: Apache/2.2.25 (Win32) mod_ssl/2.2.25 OpenSSL/0.9.8y mod_perl/2.0.8 Perl/v5.16.3
    Content-Length: 73820
    Content-Type: application/x-gzip
    Last-Modified: Tue, 25 Jun 2019 16:41:44 GMT
    Client-Date: Tue, 25 Jun 2019 16:50:50 GMT
    Client-Peer: 127.0.0.1:80
    Client-Response-Num: 1

=item B<DELETE /mbuserver/file.tar.gz>

    lwp-request -E -m DELETE "http://localhost/mbuserver/foo/bar/file.tar.gz"

Delete file from server

    DELETE http://localhost/mbuserver/foo/bar/file.tar.gz
    User-Agent: lwp-request/6.15 libwww-perl/6.15

    204 No Content
    Connection: close
    Date: Tue, 25 Jun 2019 16:51:28 GMT
    Server: Apache/2.2.25 (Win32) mod_ssl/2.2.25 OpenSSL/0.9.8y mod_perl/2.0.8 Perl/v5.16.3
    Content-Length: 0
    Content-Type: text/html; charset=ISO-8859-1
    Client-Date: Tue, 25 Jun 2019 16:51:28 GMT
    Client-Peer: 127.0.0.1:80
    Client-Response-Num: 1

=back

=head1 INTERNAL METHODS

=head2 get_list

Returns list of files. Internal use only!

=head2 raise

Returns error and exit. Internal use only!

=head1 SEE ALSO

L<CGI>, L<HTTP::Message>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use CGI qw/-putdata_upload/;
use Cwd qw/getcwd/;
use Fcntl qw(:flock);
use File::Spec;
use File::Path qw/mkpath/;
use File::Find;

use constant BASE_URI_PREFIX => '/mbuserver';
#use constant BASE_URI_PREFIX => '/server.cgi';

use constant {
        CONTENT_TYPE    => 'text/plain',
        DEFAULT_METHOD  => 'GET',
        DEFAULT_PATH    => '/',
        BUFFER_SIZE     => 4*1024, # 4kB
    };

my $q = new CGI;

my $meth = $q->request_method || DEFAULT_METHOD;
my $ruri = $q->request_uri || DEFAULT_PATH;
   $ruri =~ s/[?\#](.*)$//;
   $ruri =~ s/\/+$//;
my $path = $ruri;
my $info = $q->path_info();
if ($info) {
    $path = $info;
} else {
    my $i = index($path, BASE_URI_PREFIX);
    substr($path, $i, length(BASE_URI_PREFIX), '') if $i > -1;
}
$path = DEFAULT_PATH unless length($path);
my $reqkey = sprintf("%s %s", $meth, $path);
my $root = $ENV{DOCUMENT_ROOT} // getcwd();
if ($reqkey eq 'GET /') { # lwp-request -E "http://localhost/mbuserver"
    print  $q->header(-type => CONTENT_TYPE, -charset => 'utf-8',);
    print get_list($root);
} elsif ($meth eq 'GET') { # lwp-request -E "http://localhost/mbuserver/foo/bar/test.txt"
    my $file = File::Spec->catfile($root, $path);
    if (-f $file) {
        raise("Incorrect path: %s. Check BASE_URI_PREFIX constant first", $ruri) if $ruri eq $path;
        print $q->redirect($path);
    } elsif (-d $file) {
        print $q->header(-type => CONTENT_TYPE, -charset => 'utf-8',);
        print get_list($file);
    } else {
        print $q->header(
            -type       => CONTENT_TYPE,
            -charset    => 'utf-8',
            -status     => '404 Not Found',
        );
        print "Not Found";
    }
} elsif ($meth eq 'HEAD') { # lwp-request -E -m HEAD "http://localhost/mbuserver/foo/bar/test.txt"
    my $file = File::Spec->catfile($root, $path);
    if (-f $file) {
        raise("Incorrect path: %s. Check BASE_URI_PREFIX constant first", $ruri) if $ruri eq $path;
        print $q->redirect($path);
    } elsif (-d $file) {
        my $content = get_list($file);
        print $q->header(-type => CONTENT_TYPE, -charset => 'utf-8', -content_length => length($content));
    } else {
        print $q->header(
            -type       => CONTENT_TYPE,
            -charset    => 'utf-8',
            -status     => '404 Not Found',
        );
    }
} elsif ($meth eq 'PUT') { # lwp-request -E -m PUT -c "application/octet-stream" "http://localhost/mbuserver/foo/bar/test.txt" < test.txt
    # Get filename
    my ($volume, $directories, $file) = File::Spec->splitpath( $path );
    my $dir = File::Spec->catfile($root, $directories);
    unless (-d $dir or -l $dir) {
        mkpath( $dir, {verbose => 0} );
    }

    # Uploading
    my $out_file = File::Spec->catfile($dir, $file);
    my $got_size = 0;
    UPLOADBLOCK: {
        my $buffer = "";
        my $io_handle = $q->upload('PUTDATA') or last UPLOADBLOCK;
        open( MBUUPLOAD, '>', $out_file ) or raise("Can't open file %s", $out_file);
        flock(MBUUPLOAD, LOCK_EX) or raise("Can't lock file %s: %s", $out_file, $!);
        binmode(MBUUPLOAD);
        while (my $bytesread = $io_handle->read($buffer, BUFFER_SIZE) ) {
            print MBUUPLOAD $buffer;
            $got_size += $bytesread;
        }
        close MBUUPLOAD;
    }
    raise("Can't upload file %s", $file) unless $got_size && $got_size == -s $out_file;

    # Response
    print $q->header(
        -type               => 'application/octet-stream',
        -content_location   => $ruri,
        -status             => '201 Created',
    );
} elsif ($meth eq 'DELETE') { # lwp-request -E -m DELETE "http://localhost/mbuserver/foo/bar/test.txt"
    my $file = File::Spec->catfile($root, $path);
    if (-f $file) {
        unlink $file or raise("Could not unlink %s: %s", $file, $!);
        print $q->header(
            -status     => '204 No Content',
        );
    } elsif (-d $file) {
        print $q->header(
            -type       => CONTENT_TYPE,
            -charset    => 'utf-8',
            -status     => '405 Method Not Allowed',
        );
        print "Method Not Allowed";
    } else {
        print $q->header(
            -type       => CONTENT_TYPE,
            -charset    => 'utf-8',
            -status     => '404 Not Found',
        );
        print "Not Found";
    }
} else {
    print $q->header(
        -type       => CONTENT_TYPE,
        -charset    => 'utf-8',
        -status     => '501 Not Implemented',
    );
    printf "Not Implemented: %s", $reqkey;
}

sub get_list {
    my $r = shift || $root;
    my $name = $q->param("name") || $q->param("host");
    my @list = ();
    find({wanted => sub {
        return if $File::Find::dir ne $r;
        return if $name && index($_, $name) < 0;
        push @list, $_ if -f $_;
    }}, $r);
    return join "\n", @list;
}
sub raise {
    my $format = shift || "Unknown error";
    my @err = @_;
    print $q->header(
        -type       => CONTENT_TYPE,
        -charset    => 'utf-8',
        -status     => '500 Internal Server Error',
    );
    printf $format, @err;
    exit 0;
}

1;

__END__
