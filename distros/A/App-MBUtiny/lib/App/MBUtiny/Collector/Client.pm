package App::MBUtiny::Collector::Client; # $Id: Client.pm 121 2019-07-01 19:51:50Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MBUtiny::Collector::Client - Client for access to App::MBUtiny collector server

=head1 VIRSION

Version 1.00

=head1 SYNOPSIS

    use App::MBUtiny::Collector::Client;

    my $client = new App::MBUtiny::Collector::Client(
        url     => 'http://test:test@localhost/mbutiny', # Base URL
        timeout => 180, # default: 180
        verbose => 1, # Show req/res data
    );

    my $check_struct = $client->check;

    print STDERR $client->error unless $check_status;

=head1 DESCRIPTION

Client for access to App::MBUtiny collector server

This module is based on L<WWW::MLite::Client> class

=head2 new

    my $client = new App::MBUtiny::Collector::Client(
        url     => 'http://test:test@localhost/mbutiny', # Base URL
        timeout => 180, # default: 180
        verbose => 1, # Show req/res data
    );

Returns the collector client object

=over 4

=item B<timeout>

Timeout of requests

Default: 180 sec

=item B<url>

The Full URL of the collector location

=item B<verbose>

Verbose flag. 0 = off, 1 = on

Default: 0

=back

See L<WWW::MLite::Client>

=head2 add

    $client->add(
        type => 1,
        name => "foo",
        file => "foo-2019-06-25.tar.gz",
        size => 123456,
        md5  => "3a5fb8a1e0564eed5a6f5c4389ec5fa0",
        sha1 => "22d12324fa2256e275761b55d5c063b8d9fc3b95",
        status => 1,
        error => "",
        comment => "Test external fixup"
    ) or die $client->error;

Request for fixupping of backup on collector by name and others parameters.

The method returns status of operation: 0 - Error; 1 - Ok

=head2 check

    my $check = $client->check;

Performs the checking of MBUtiny collector server and returns structure in format:

    {
       'description' => 'Check collectors',
       'dsn' => 'dbi:SQLite:dbname=/var/lib/mbutiny/mbutiny.db',
       'error' => '',
       'method' => 'GET',
       'name' => 'check',
       'path' => '/mbutiny',
       'status' => 1,
       'time' => '0.004'
    }

=head2 del

    $client->del(
        type => 1,
        name => "foo",
        file => "foo-2019-06-25.tar.gz",
    ) or die $client->error;

Delete file-record from collector

The method returns status of operation: 0 - Error; 1 - Ok

=head2 get

    my %info = $client->get(
            name => "foo",
            file => "foo-2019-06-25.tar.gz",
        );

Request for getting information about file on collector by name and filename.

The method returns info-structure. See L<App::MBUtiny::Collector::DBI/get>

=head2 list

    my @list = $client->list(name => "foo");

Request for getting list of files on collector by name.

The method returns array of info-structures.
See L<App::MBUtiny::Collector::DBI/list>

=head2 report

    my @list = $client->report(start => 123456789);

Request for getting report of backup on collector by name.
See L<App::MBUtiny::Collector::DBI/report>

=head2 request

    my $struct = $client->request();

Performs request to collector server over L<WWW::MLite::Client>

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MBUtiny>, L<WWW::MLite::Client>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.00';

#use Carp;
#use CTK::TFVals qw/ :ALL /;
use CTK::ConfGenUtil;
#use Try::Tiny;
#use File::Basename qw/basename/;

use base qw/ WWW::MLite::Client /;

use constant {
        CONTENT_TYPE        => "application/json",
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

sub new {
    my $class = shift;
    my %params = @_;
    $params{sr_attrs}       ||= SR_ATTRS;
    $params{ua_opts}        ||= { agent => "MBUtiny/$VERSION" };
    $params{format}         ||= SERIALIZE_FORMAT;
    $params{content_type}   ||= CONTENT_TYPE;
    $params{no_check_redirect} //= 1;
    return $class->SUPER::new(%params);
}
sub request {
    my $self = shift;
    my $data = $self->SUPER::request(@_);
    my $state = $self->status;
    if ($state) {
        my $err = _check_response($data);
        if ($err) {
            $self->status(0);
            $self->error($err);
        }
    }
    return $data if is_hash($data);
    if ($data) {
        $self->status(0);
        $self->error("Non serialized content found!");
    }
    return {
        status => $self->status,
        error  => $self->error,
    };
}
sub check {
    my $self = shift;
    return $self->request();
}
sub add {
    my $self = shift;
    my %args = @_;
    $self->request(POST => undef, {%args});
    return $self->status;
}
sub del {
    my $self = shift;
    my %args = @_;
    my $base_path = $self->{uri}->path;
    my $name = $args{name};
    unless ($name) {
        $self->error("The name attribute not specified!");
        return $self->status(0);
    }
    my $file = $args{file};
    unless ($file) {
        $self->error("The file attribute not specified!");
        return $self->status(0);
    }
    $self->request(DELETE => sprintf('%s/%s?file=%s&type=%d', $base_path, $name, $file, $args{type} || 0));
    return $self->status;
}
sub list {
    my $self = shift;
    my $uri = $self->{uri}->clone;
    my %args = @_;
    my $name = $args{name};
    unless ($name) {
        $self->error("The name attribute not specified!");
        return ();
    }
    my $path_orig = $uri->path;
    $uri->path(sprintf("%s/list", $path_orig));
    $uri->query_form(name => $name);
    my $list = $self->request(GET => $uri->path_query) || {};
    my $result = array($list, "list");
    return @$result;
}
sub get {
    my $self = shift;
    my $uri = $self->{uri}->clone;
    my %args = @_;
    my $name = $args{name};
    unless ($name) {
        $self->error("The name attribute not specified!");
        return ();
    }
    my $file = $args{file};
    my $path_orig = $uri->path;
    $uri->path(sprintf("%s/%s", $path_orig, $name));
    $uri->query_form(file => $file) if $file;
    my $info = $self->request(GET => $uri->path_query) || {};
    my $result = hash($info, "info");
    return %$result;
}
sub report {
    my $self = shift;
    my $uri = $self->{uri}->clone;
    my %args = @_;
    $uri->path(sprintf("%s/report", $uri->path));
    my $start = $args{start};
    $uri->query_form(start => $start) if $start;
    my $list = $self->request(GET => $uri->path_query) || {};
    my $result = array($list, "report");
    return @$result;
}

sub _check_response {
    # Returns error string when status = 0 and error is not empty
    my $res = shift;
    # Returns:
    #  "..." - errors!
    #  undef - no errors
    if ( !$res ) {
        return;
    } elsif (is_hash($res)) {
        return if value($res => "status"); # OK
        if (my $err = value($res => "error")) {
            return $err;
        }
    } else {
        return "The response has not valid JSON format";
    }
    return "Unknown error";
}

1;

__END__
