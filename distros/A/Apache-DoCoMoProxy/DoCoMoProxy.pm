package Apache::DoCoMoProxy;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

=head1 NAME

Apache::DoCoMoProxy - NTT DoCoMo HTTP gateway clone for mod_proxy

=head1 SYNOPSIS

  # in httpd.conf
  PerlAuthenHandler Apache::DoCoMoProxy

=head1 DESCRIPTION

NTT DoCoMo i-mode terminals use original http gateway.
Apache::DoCoMoProxy emulates it. GET or POST uid=NULLGWDOCOMO
parameter changes terminal id.

At first time of proxy request, basic auth required.
Input terminal id and user agent(comma separate). 
password anyone.

 ex.)
 
 account: AZ0826YK,DoCoMo/1.0/N503i/c30
 password: (none)

=head1 AUTHOR

Hiroyuki Kobayashi <kobayasi@piano.gs>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This module comes B<WITHOUT ANY WARRANTY>.

=head1 SEE ALSO

L<Apache::ProxyPassThru>

=cut

use URI;
use Apache::Constants qw(:common);
use Apache::Request;
use LWP::UserAgent();

sub handler {
    my $r = shift;
    my ($res,$sent_pw) = $r->get_basic_auth_pw();
    return $res if $res != OK;
    my $user = $r->connection->user;

    $r->handler('perl-script');
    $r->push_handlers(PerlHandler => \&proxy_handler);
    
    return OK;
}

sub proxy_handler
{
    my ($r) = @_;
    my($key,$val);

    my ($user,$ua) = split(m|,|,$r->connection->user);
    $ua ||= 'DoCoMo/1.0/N503i/c30';

    my $request = new HTTP::Request $r->method, get_filter($user,$r->uri);

    my(%headers_in) = $r->headers_in;
    while(($key,$val) = each %headers_in) {
        $request->header($key,$val);
    }

    $request->header('user-agent' => $ua);

    if ($r->method eq 'POST') {
        my $len = $headers_in{'Content-Length'};
        my $buff = '';
        $r->read($buff,$len);
	$request->content(post_filter($user,$buff,$r));
    }

    my $res = (new LWP::UserAgent)->simple_request($request);
    $r->content_type($res->header('Content-type'));

    $r->status($res->code);
    $r->status_line($res->status_line);
    $res->scan(sub {
        $r->header_out(@_);
    });

    $r->send_http_header();
    $r->print($res->content);

    return OK;
}

sub get_filter
{
    my $uid = shift;
    my $uri = shift;
    my $url = URI::URL->new($uri);
    my %args = $url->query_form();

    if( $args{uid} eq 'NULLGWDOCOMO'){
	$args{uid} = $uid;
	$url->query_form(%args);
    }
    return $url;
}

sub post_filter
{
    my ($uid,$buff,$r) = @_;
    my $q = URI::URL->new("?$buff");
    my %args = $q->query_form();
    
    if( $args{uid} eq 'NULLGWDOCOMO' ){
        $args{uid} = $uid;
    }
    $q->query_form(%args);

    return $q->query;
}

1;
