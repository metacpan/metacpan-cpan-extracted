# ABSTRACT: Does the actual request to the API
use strict;
use warnings;
use 5.010;
package API::CLI::Request;

our $VERSION = '0.001'; # VERSION

use Moo;

has openapi => ( is => 'ro' );
has method => ( is => 'ro' );
has path => ( is => 'ro' );
has req => ( is => 'rw' );
has url => ( is => 'rw' );
has verbose => ( is => 'ro' );

sub from_openapi {
    my ($class, %args) = @_;

    my $method = $args{method};
    my $path = delete $args{path};
    my $opt = delete $args{options};
    my $params = delete $args{parameters};

    my $self = $class->new(
        openapi => delete $args{openapi},
        method => delete $args{method},
        path => $path,
        %args,
    );

    my $host = $self->openapi->{host};
    my $scheme = $self->openapi->{schemes}->[0];

    my $basePath = $self->openapi->{basePath} // '';
    $basePath = '' if $basePath eq '/';
    my $url = URI->new("$scheme://$host$basePath$path");
    my %query;
    for my $name (sort keys %$opt) {
        my $value = $opt->{ $name };
        if ($name =~ s/^q-//) {
            $query{ $name } = $value;
        }
    }
    $url->query_form(%query);
    $self->url($url);

    my $req = HTTP::Request->new( $self->method => $self->url );
    $self->req($req);

    return $self;
}

sub request {
    my ($self) = @_;

    my $ua = LWP::UserAgent->new;
    my $req = $self->req;
    my $res = $ua->request($req);
    my $code = $res->code;
    my $content = $res->decoded_content;
    my $status = $res->status_line;

    my $ct = $res->content_type;
    my $out = $self->verbose ? "Response: $status ($ct)\n" : undef;
    my $data;
    my $ok = 0;
    if ($res->is_success) {
        $ok = 1;
        if ($ct eq 'application/json') {
            my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
            $data = $coder->decode($content);
            $content = $coder->encode($data);
        }
    }

    return ($ok, $out, $content);
}

sub content {
    shift->req->content(@_);
}

sub header {
    shift->req->header(@_);
}

1;

__END__

=pod

=head1 NAME

API::CLI::Request = Does the actual request to the API

=head1 METHODS

=over 4

=item content

    $req->content($data);

Sets POST/PUT/PATCH content


=item from_openapi

=item header

=item method

=item openapi

=item path

=item req

=item request

=item url

=item verbose

=back

=cut
