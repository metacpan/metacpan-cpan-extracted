package App::MonM::Checkit::HTTP; # $Id: HTTP.pm 80 2019-07-08 10:41:47Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Checkit::HTTP - Checkit HTTP subclass

=head1 VIRSION

Version 1.00

=head1 SYNOPSIS

    <Checkit "foo">
        Enable  yes
        Type    http
        URL     http://www.example.com
        Method  GET
        TimeOut 180
        Target  code
        IsTrue  200
        Content "Blah-Blah-Blah"
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

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.00';

use Encode;
use CTK::ConfGenUtil;
use URI;
use LWP::UserAgent();
use HTTP::Request();

use App::MonM::Const qw/PROJECTNAME/;
use App::MonM::Util qw/set2attr/;

use constant {
        DEFAULT_URL     => "http://localhost",
        DEFAULT_METHOD  => "GET",
        DEFAULT_TIMEOUT => 180,
    };

sub check {
    my $self = shift;
    my $type = $self->type;
    return $self->maybe::next::method() unless $type && $type eq 'http';

    # Init
    my $url = value($self->config, 'url') || DEFAULT_URL;
    my $method = value($self->config, 'method') || DEFAULT_METHOD;
    my $timeout = value($self->config, 'timeout') || DEFAULT_TIMEOUT;
    my $attr = set2attr($self->config);
    my $content = value($self->config, 'content') // '';

    # Prepare request
    my $uri = new URI($url);
    my $ua = new LWP::UserAgent(
        agent               => sprintf("%s/%s", PROJECTNAME, $VERSION),
        timeout             => $timeout,
        protocols_allowed   => ['http', 'https'],
    );
    $ua->default_header($_, value($attr, $_)) for (keys %$attr);
    my $request = new HTTP::Request(uc($method) => $uri);
    if ($method =~ /PUT|POST|PATCH/) {
        Encode::_utf8_on($content);
        $request->header('Content-Length' => length(Encode::encode("utf8", $content)));
        $request->content(Encode::encode("utf8", $content));
    }
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
