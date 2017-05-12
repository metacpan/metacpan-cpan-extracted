package Catalyst::Plugin::SubRequest;

use strict;
use warnings;
use Plack::Request;

our $VERSION = '0.21';

=head1 NAME

Catalyst::Plugin::SubRequest - Make subrequests to actions in Catalyst

=head1 SYNOPSIS

    use Catalyst 'SubRequest';

    my $res_body = $c->subreq('/test/foo/bar', { template => 'magic.tt' });

    my $res_body = $c->subreq( {
       path            => '/test/foo/bar',
       body            => $body
    }, {
       template        => 'magic.tt'
    });

    # Get the full response object
    my $res = $c->subreq_res('/test/foo/bar', {
        template => 'mailz.tt'
    }, {
        param1   => 23
    });
    $c->log->warn( $res->content_type );

=head1 DESCRIPTION

Make subrequests to actions in Catalyst. Uses the  catalyst
dispatcher, so it will work like an external url call.
Methods are provided both to get the body of the response and the full
response (L<Catalyst::Response>) object.

=head1 METHODS

=over 4

=item subreq [path as string or hash ref], [stash as hash ref], [parameters as hash ref]

=item subrequest

=item sub_request

Takes a full path to a path you'd like to dispatch to.

If the path is passed as a hash ref then it can include body, action,
match and path.

An optional second argument as hashref can contain data to put into the
stash of the subrequest.

An optional third argument as hashref can contain data to pass as
parameters to the subrequest.

Returns the body of the response.

=item subreq_res [path as string or hash ref], [stash as hash ref], [parameters as hash ref]

=item subrequest_response

=item sub_request_response

Like C<sub_request()>, but returns a full L<Catalyst::Response> object.

=back

=cut

*subreq              = \&sub_request;
*subrequest          = \&sub_request;
*subreq_res          = \&sub_request_response;
*subrequest_response = \&sub_request_response;

sub sub_request {
  return shift->sub_request_response(@_)->body;
}

sub sub_request_response {
  my ( $c, $path, $stash, $params ) = @_;
  $stash ||= {};
  my $env = $c->request->env;
  my $req = Plack::Request->new($env);
  my $uri = $req->uri;
  $uri->query_form( $params || {} );
  local $env->{QUERY_STRING} = $uri->query || '';
  local $env->{PATH_INFO}    = $path;
  local $env->{REQUEST_URI}  = $env->{SCRIPT_NAME} . $path;

  # Jump through a few hoops for backcompat with pre 5.9007x
  local($env->{&Catalyst::Middleware::Stash::PSGI_KEY}) = &Catalyst::Middleware::Stash::_create_stash()
    if $INC{'Catalyst/Middleware/Stash.pm'};

  $env->{REQUEST_URI} =~ s|//|/|g;
  my $class = ref($c) || $c;

  $c->stats->profile(
    begin   => 'subrequest: ' . $path,
    comment => '',
  ) if ( $c->debug );

  # need this so that
  my $writer = Catalyst::Plugin::SubRequest::Writer->new;
  my $response_cb = sub {
    my $response = shift;
    my ($status, $headers, $body) = @$response;
    if($body) {
      return;
    } else {
      return $writer;
    }
  };

  my $i_ctx = $class->prepare( env => $env, response_cb => $response_cb );
  $i_ctx->stash($stash);
  $i_ctx->dispatch;
  $i_ctx->finalize;
  $c->stats->profile( end => 'subrequest: ' . $path ) if $c->debug;

  if($writer->_is_closed) {
    $i_ctx->response->body($writer->body);
  }

  return $i_ctx->response;
}


package Catalyst::Plugin::SubRequest::Writer;
use Moose;
has body => (
  isa     => 'Str',
  is      => 'ro',
  traits  => ['String'],
  default => '',
  handles => { write => 'append' }
);
has _is_closed => ( isa => 'Bool', is => 'rw', default => 0 );
sub close { shift->_is_closed(1) }

around write => sub {
  my $super = shift;
  my $self = shift;
  return if $self->_is_closed;
  $self->$super(@_);
};

=head1 SEE ALSO

L<Catalyst>.

=head1 AUTHORS

Marcus Ramberg, C<mramberg@cpan.org>

Tomas Doran (t0m) C<< bobtfish@bobtfish.net >>

=head1 MAINTAINERS

Eden Cardim (edenc) C<eden@insoli.de>

=head1 THANK YOU

SRI, for writing the awesome Catalyst framework

MIYAGAWA, for writing the awesome Plack toolkit

=head1 COPYRIGHT

Copyright (c) 2005 - 2011
the Catalyst::Plugin::SubRequest L</AUTHORS>
as listed above.

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
