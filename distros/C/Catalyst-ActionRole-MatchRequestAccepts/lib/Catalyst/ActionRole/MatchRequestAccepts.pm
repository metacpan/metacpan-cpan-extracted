package Catalyst::ActionRole::MatchRequestAccepts;

our $VERSION = '0.06';

use 5.008008;
use Moose::Role;
use Perl6::Junction 'all', 'any';
use HTTP::Headers::Util 'split_header_words';
use namespace::autoclean;

requires 'attributes';

has http_accept => (is=>'ro', required=>1, default=>'http-accept');

sub _http_accept {
  my ($self, $request) = @_;
  return map {
    $self->_split_accept_header($_);
  } $request->headers->header('Accept');
}

sub _split_accept_header {
  my ($self, $accept_header) = @_;
  my %types;
  foreach my $pair (split_header_words $accept_header) {
    my ($type) = @{$pair}[0];
    next if $types{$type};
    $types{$type}=1;
  }
  return keys %types;
}

sub _query_accept {
  my ($self, $request) = @_;
  my $accept = $request->query_parameters->{$self->http_accept} || undef;
  (defined($accept)  && ref($accept)) ? @$accept : $accept;
}

sub _resolve_http_accept {
  my ($self, $ctx) = @_;
  if($ctx->debug) {
    my @hdr_accepts = $self->_query_accept($ctx->req);
    if($hdr_accepts[0]) {
      return @hdr_accepts;
    } else {
      return $self->_http_accept($ctx->req);
    }
  } else {
    return $self->_http_accept($ctx->req);
  }
}

sub _resolve_accept_attr {
  @{shift->attributes->{Accept} || []};
}

around 'match', sub {
  my ($orig, $self, $ctx) = @_;
  my @attr_accepts = $self->_resolve_accept_attr;
  my @hdr_accepts = $self->_resolve_http_accept($ctx);

  if(@attr_accepts) {
    if(any(@attr_accepts) eq any(@hdr_accepts)) {
      return $self->$orig($ctx);
    } else {
      return 0;
    }
  } else {
    return $self->$orig($ctx);
  }
};

1;

=head1 NAME

Catalyst::ActionRole::MatchRequestAccepts - Dispatch actions based on HTTP Accept Header

=head1 SYNOPSIS

    package MyApp::Controller::Foo;

    use Moose;
    use namespace::autoclean;

    BEGIN {
      extends 'Catalyst::Controller::ActionRole';
    }

    ## Add the ActionRole to all the Controller's actions.  You can also 
    ## selectively add the ActionRole with the :Does action attribute or in
    ## controller configuration.  See Catalyst::Controller::ActionRole for
    ## more information.

    __PACKAGE__->config(
      action_roles => ['MatchRequestAccepts'],
    );

    ## Match for incoming requests with HTTP Accepts: plain/html
    sub for_html : Path('foo') Accept('plain/html') { ... }

    ## Match for incoming requests with HTTP Accepts: application/json
    sub for_json : Path('foo') Accept('application/json') { ... }

=head1 DESCRIPTION

Lets you specify a match for the HTTP C<Accept> Header, which is provided by
the L<Catalyst> C<< $ctx->request->headers >> object.  You might wish to instead
look at L<Catalyst::Action::REST> if you are doing complex applications that
match different incoming request types, but if you are very fussy about how
your actions match, or if you are doing some simple ajaxy bits you might like
to use this instead of a full on package (like L<Catalyst::Action::REST> is.)

Currently the match performed is a pure equalty, no attempt to guess or infer
matches based on similarity are done.  If you need to match several variations
you can specify all the variations with multiple attribute declarations.  Right
now we don't support expression based matching, such as C<text/*>, although
adding such would probably not be very hard (although I don't want to make the
logic here slow down our dispatch matching too much).

Please note that if you specify multiple C<Accept> attributes on a single
action, those will be matched via an OR condition and not an AND condition.  In
other words we short circuit match the first action with at least one of the
C<Accept> values appearing in the requested HTTP headers.  I think this is
correct since I imagine the purpose of multiple C<Accept> attributes would be
to match several acceptable variations of a given type, not to match any of
several unrelated types.  However if you have a use case for this please let
me know.

If an action consumes this role, but no C<Accept> attributes are found, the
action will simple accept all types.

For debugging purposes, if the L<Catalyst> debug flag is enabled, you can
override the HTTP Accept header with the C<http-accept> query parameter.  This
makes it easy to force detect in testing or in your browser.  This feature is
NOT available when the debug flag is off.

Also, as usual you can specify attributes and information in th configuration
of your L<Catalyst::Controller> subclass:

    ## Set the 'our_action_json' action to consume this ActionRole.  In this
    ## example GET '/json' would only match if the client request HTTP included
    ## an Accept: application/json.

    __PACKAGE__->config(
      action_roles => ['MatchRequestAccepts'],
      action => {
        our_action_json => { Path => 'json', Accept => 'application/json' },
      });

    ## GET '/foo' will dispatch to either action 'our_action_json' or action
    ## 'our_action_html' depending on the incoming HTTP Accept.

    __PACKAGE__->config(
      action => {
        our_action_json => {
          Does => 'MatchRequestAccepts',
          Path => 'foo',
          Accept => 'application/json',
        },
        our_action_html => {
          Does => 'MatchRequestAccepts',
          Path => 'foo',
          Accept => 'text/html',
        },
      });

There's a functioning L<Catalyst> example application in the test directory for
your review as well.

=head1 EXAMPLE WITH CHAINED ACTIONS

The following example uses L<Catalyst> chaining to match one of two different
types of C<Accept> headers, and to return the correct HTTP error message if
nothing is matched.  This is probably my most common use pattern.

    package MyApp::Web::Controller::Chained;

    use Moose;
    use namespace::autoclean;

    BEGIN {
      extends 'Catalyst::Controller::ActionRole';
    }

    __PACKAGE__->config(
      action_roles => ['MatchRequestAccepts'],
    );

    sub root : Chained('/') PathPrefix CaptureArgs(0) {}

      sub text_html
        : Chained('root') PathPart('') Accept('text/html') Args(0)
      {
        my ($self, $ctx) = @_;
        $ctx->response->body('text_html');
      }

      sub json
        : Chained('root') PathPart('') Accept('application/json') Args(0)
      {
        my ($self, $ctx) = @_;
        $ctx->response->body('json');
      }

      sub not_accepted
        : Chained('root') PathPart('') Args
      {
        my ($self, $ctx) = @_;
        $ctx->response->status(406);
        $ctx->response->body('error_not_accepted');
      }

    __PACKAGE__->meta->make_immutable;

In the given example, a C<GET> request to C<http://www.myapp.com/chained> will
match for C<Accept> values of HTML and JSON, and will return a status 406 error
to all other requests.

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>

=head1 THANKS

Shout out to Florian Ragwitz <rafl@debian.org> for providing such a great
example in L<Catalyst::ActionRole::MatchRequestMethod>.  Source code and tests
are pretty much copied from his stuff.

I also cargo culted a chuck of code from L<Catalyst::TraitFor::Request::REST>
which let me parse HTTP Accept lines.

=head1 SEE ALSO

L<Catalyst::ActionRole::MatchRequestMethod>, L<Catalyst::Action::REST>,
L<Catalyst>, L<Catalyst::Controller::ActionRole>, L<Moose>.

=head1 COPYRIGHT & LICENSE

Copyright 2011, John Napiorkowski L<email:jjnapiork@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
