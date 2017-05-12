package Business::YQL;
use Moo;

our $VERSION = '0.0004'; # VERSION

use HTTP::Request::Common qw(GET POST);
use URI;
use URI::QueryParam;
use LWP::UserAgent;
use JSON qw(to_json from_json);
use Carp qw(croak);
use Log::Any qw($log);
use Try::Tiny;

has scheme  => (is => 'ro', default => 'http'                           );
has domain  => (is => 'ro', default => 'query.yahooapis.com'            );
has version => (is => 'ro', default => 'v1'                             );
has timeout => (is => 'ro', default => 10                               );
has retries => (is => 'ro', default => 3                                );

has uri     => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return sprintf '%s://%s/%s/public/yql',
            $self->scheme, $self->domain, $self->version;
    },
);

has ua      => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $ua = LWP::UserAgent->new;
        $ua->timeout($self->timeout);
        return $ua
    },
);

sub q {
    my ($self, $query) = @_;
    croak "Invalid query string"
        unless $query;

    my %params = (
        q           => $query,
        format      => 'json',
        env         => 'store://datatables.org/alltableswithkeys',
        jsonCompat  => 'new',
    );

    my $uri = URI->new($self->uri);
    $uri->query_form(%params);

    if ($query =~ m/^insert/i) {
        return $self->_req(POST $uri);
    } else {
        return $self->_req(GET $uri);
    }
}

sub _req {
    my ($self, $req) = @_;
    $self->_log_request($req);
    my $res = $self->ua->request($req);
    $self->_log_response($res);
    my $retries = $self->retries;
    while ($res->code =~ /^5/x and $retries--) {
        sleep 1;
        $res = $self->ua->request($req);
    }
    return from_json $res->content
        if $res->code =~ /^4/x;
    return $res->content ? from_json($res->content)->{query}{results} : 1;
}

sub _log_content {
    my ($self, $content) = @_;
    if ($content && length $content) {
        try {
            $content = to_json from_json $content;
            $log->trace($content);
        } catch {
            $log->error('Invalid JSON: ' . $content);
        };
    }
}

sub _log_request {
    my ($self, $req) = @_;
    $log->trace($req->method . ' => ' . $req->uri);
    _log_content $req->content;
}

sub _log_response {
    my ($self, $res) = @_;
    $log->trace($res->status_line);
    _log_content $res->content;
}


# ABSTRACT: YQL Perl interface for the Y! Query API


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::YQL - YQL Perl interface for the Y! Query API

=head1 VERSION

version 0.0004

=head1 SYNOPSIS

    use Business::YQL;

    my $yql = Business::YQL->new;
    my $data = $yql->q('show tables');

    $data = $yql->query("insert into yahoo.y.ahoo.it (url) values ('http://google.com')");

=head1 DESCRIPTION

This module provides a simple Perl interface (via JSON) to perform YQL queries.  You can test queries in Yahoo's developer console here: L<http://developer.yahoo.com/yql/console|http://developer.yahoo.com/yql/console>.

=head1 METHODS

=head2 new

Instantiates a new Business::YQL client object.  All parameters are optional.

    my $yql = Business::YQL->new(
        scheme => 'http',
        domain => 'query.yahooapis.com',
        version => 'v1',
        timeout => 10,
        retries => 3,
    );

B<Parameters>

=over 4

=item - C<scheme>

I<Optional>E<10> E<8>

The valid HTTP scheme for the URI builder.  Defaults to C<http>.

=item - C<domain>

I<Optional>E<10> E<8>

The Yahoo API top-level domain to make API calls against.  Defaults to L<query.yahooapis.com|http:/query.yahooapis.com>.

=item - C<version>

I<Optional>E<10> E<8>

The Yahoo API version to use.  Defaults to C<v1>.

=item - C<timeout>

I<Optional>E<10> E<8>

The maximum number of seconds to wait after submitting an HTTP request before timing out the response.  Defaults to C<10> seconds.

=item - C<retries>

I<Optional>E<10> E<8>

The number of times to retry requests in cases when Yahoo returns a 5xx response.  Defaults to C<3> attempts.

=back

=head2 q

Submits the YQL query, this method simply takes a string to send to Y! API, and returns the decoded JSON response n the form of a Perl object if the request was valid.

    q("SELECT * from geo.places WHERE text='SFO'")

=head1 AUTHOR

Ali Anari <ali@anari.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ali Anari.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
