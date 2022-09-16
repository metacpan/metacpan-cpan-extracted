package App::MonM::Checkit::HTTP; # $Id: HTTP.pm 116 2022-08-27 08:57:12Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Checkit::HTTP - Checkit HTTP subclass

=head1 VIRSION

Version 1.01

=head1 SYNOPSIS

    <Checkit "foo">

        Enable  yes
        Type    http
        URL     http://www.example.com
        Method  POST
        TimeOut 180
        Target  code
        IsTrue  200
        Content "Blah-Blah-Blah"
        Proxy   "http://http.example.com:8001"
        Set     X-Foo foo
        Set     X-Bar bar

        # . . .

    </Checkit>

=head1 DESCRIPTION

Checkit HTTP subclass

=head2 check

Checkit method.
This is backend method of L<App::MonM::Checkit/check>

Returns:

=over 4

=item B<code>

The HTTP response code: 1xx, 2xx, 3xx, 4xx, 5xx or 0

=item B<content>

The response content

=item B<message>

The HTTP response status line

=item B<source>

Method and URL of request

=item B<status>

0 if error occured and if code is 4xx or 5xx

1 if no errors and if code is 1xx, 2xx or 3xx

=back

=head1 CONFIGURATION DIRECTIVES

The basic Checkit configuration options (directives) detailed describes in L<App::MonM::Checkit/CONFIGURATION DIRECTIVES>

=over 4

=item B<Content>

    Content  "Content for HTTP request"

Specifies POST/PUT/PATCH request content

Example:

    Set Content-Type text/plain
    Content "Content for POST HTTP request"

Default: no content

=item B<Method>

    Method      GET

Defines the HTTP method: GET, POST, PUT, HEAD, PATCH, DELETE, and etc.

Default: GET

=item B<Proxy>

    Proxy http://http.example.com:8001/

Defines the proxy URL for a http/https requests

Default: no proxy

=item B<Set>

    Set X-Token mdffltrtkmdffltrtk

Defines HTTP request headers. This directive allows you set case sensitive HTTP headers.
There can be several such directives.

Examples:

    Set User-Agent  "MyAgent/1.00"
    Set X-Token     "mdffltrtkmdffltrtk"


=item B<Timeout>

    Timeout    1m

Defines the timeout of HTTP request

Default: 180

=item B<URL>

    URL     https://www.example.com

Defines the URL for HTTP/HTTPS requests

Default: http://localhost

Examples:

    URL     https://user:password@www.example.com
    URL     https://www.example.com

=back

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.01';

use Encode;
use CTK::ConfGenUtil;
use URI;
use LWP::UserAgent();
use HTTP::Request();

use App::MonM::Const qw/PROJECTNAME/;
use App::MonM::Util qw/set2attr getTimeOffset/;

use constant {
        DEFAULT_URL     => "http://localhost",
        DEFAULT_METHOD  => "GET",
        DEFAULT_TIMEOUT => 180,
    };

sub check {
    my $self = shift;
    my $type = $self->type;
    return $self->maybe::next::method() unless $type && ($type eq 'http' or $type eq 'https');

    # Init
    my $url = lvalue($self->config, 'url') || DEFAULT_URL;
    my $method = lvalue($self->config, 'method') || DEFAULT_METHOD;
    my $timeout = getTimeOffset(lvalue($self->config, 'timeout') || DEFAULT_TIMEOUT);
    my $attr = set2attr($self->config);
    my $content = lvalue($self->config, 'content') // '';
    my $proxy = lvalue($self->config, 'proxy') || "";

    # Agent
    my $uri = URI->new($url);
    my $ua = LWP::UserAgent->new(
        agent               => sprintf("%s/%s", PROJECTNAME, $VERSION),
        timeout             => $timeout,
        protocols_allowed   => ['http', 'https'],
    );
    $ua->default_header($_, value($attr, $_)) for (keys %$attr);

    # Proxy
    $ua->proxy(['http', 'https'], $proxy) if $proxy;

    # Prepare request data
    my $request = HTTP::Request->new(uc($method) => $uri);
    if ($method =~ /PUT|POST|PATCH/) {
        Encode::_utf8_on($content);
        $request->header('Content-Length' => length(Encode::encode("utf8", $content)));
        $request->content(Encode::encode("utf8", $content));
    }

    # Request
    my $response = $ua->request($request);

    # Result
    $self->status(($response->is_info || $response->is_success || $response->is_redirect) ? 1 : 0);
    $self->error($response->decoded_content // '') unless $self->status;
    $self->source(sprintf("%s %s", $method, $response->request->uri->canonical->as_string));
    $self->message($response->status_line || '');
    $self->code($response->code || 0);
    $self->content($response->decoded_content // '');

    return;
}

1;

__END__
