package Catalyst::TraitFor::Request::ContentNegotiationHelpers;

our $VERSION = '0.006';

use Moose::Role;
use HTTP::Headers::ActionPack;

has content_negotiator => (
  is => 'bare',
  required => 1,
  lazy => 1,
  builder => '_build_content_negotiator',
  handles => +{
    raw_choose_media_type => 'choose_media_type',
    raw_choose_language => 'choose_language',
    raw_choose_charset => 'choose_charset',
    raw_choose_encoding => 'choose_encoding',
  });

  sub _build_content_negotiator {
    return HTTP::Headers::ActionPack->new
      ->get_content_negotiator;
  }

my $on_best = sub {
  my ($self, $method, %callbacks) = @_;
  my $default = delete $callbacks{no_match};
  if(my $match = $self->$method(keys %callbacks)) {
    return $callbacks{$match}->($self);
  } else {
    return $default ? $default->($self, %callbacks) : undef;
  }
};

sub choose_media_type {
  my $self = shift;
  return $self->raw_choose_media_type(\@_, $self->header('Accept'));
}

sub accepts_media_type {
  my $self = shift;
  return map { $self->choose_media_type($_) } @_;
}

sub on_best_media_type {
  return shift->$on_best('choose_media_type', @_);
}

sub choose_language {
  my $self = shift;
  return $self->raw_choose_language(\@_, $self->header('Accept-Language'));
}

sub accepts_language {
  my $self = shift;
  return $self->choose_language(@_) ? 1:0;
}

sub on_best_language {
  return shift->$on_best('choose_language', @_);
}

sub choose_charset {
  my $self = shift;
  return $self->raw_choose_charset(\@_, $self->header('Accept-Charset'));
}

sub accepts_charset  {
  my $self = shift;
  return $self->choose_charset(@_) ? 1:0;
}

sub on_best_charset {
  return shift->$on_best('choose_charset', @_);
}

sub choose_encoding {
  my $self = shift;
  return $self->raw_choose_encoding(\@_, $self->header('Accept-Encoding'));
}

sub accepts_encoding {
  my $self = shift;
  return $self->choose_encoding(@_) ? 1:0;
}

sub on_best_encoding {
  return shift->$on_best('choose_encoding', @_);
}

1;

=head1 NAME

Catalyst::TraitFor::Request::ContentNegotiationHelpers - assistance with content negotiation

=head1 SYNOPSIS

For L<Catalyst> v5.90090+

    package MyApp;

    use Catalyst;

    MyApp->request_class_traits(['Catalyst::TraitFor::Request::ContentNegotiationHelpers']);
    MyApp->setup;

For L<Catalyst> older than v5.90090

    package MyApp;

    use Catalyst;
    use CatalystX::RoleApplicator;

    MyApp->apply_request_class_roles('Catalyst::TraitFor::Request::ContentNegotiationHelpers');
    MyApp->setup;

In a controller:

    package MyApp::Controller::Example;

    use Moose;
    use MooseX::MethodAttributes;

    sub myaction :Local {
      my ($self, $c) = @_;
      my $best_media_type = $c->req->choose_media_type('application/json', 'text/html');
    }

    sub choose :Local {
      my ($self, $c) = @_;
      my $body = $c->req->on_best_media_type(
        'no_match' => sub { 'none' },
        'text/html' => sub { 'html' },
        'application/json' => sub { 'json' });

      $c->res->body($body);
    }

    sub filter : Local {
      my ($self, $c) = @_;
      my @acceptable = $c->req->accepts_media_type('image/jpeg', 'text/html', 'text/plain');
    }


=head1 DESCRIPTION

When using L<Catalyst> and developing web APIs it can be desirable to examine
the state of HTTP Headers of the request to make decisions about what to do,
for example what format to return (HTML, XML, JSON, other).  This role can
be applied to your L<Catalyst::Request> to add some useful helper methods for
the more common types of server side content negotiation.

Most of the real work is done by L<HTTP::Headers::ActionPack::ContentNegotiation>,
this role just seeks to make it easier to use those features.

=head1 ATTRIBUTES

This role defines the following attributes.

=head2 content_negotiator

This is a 'bare' attribute with no direct accessors.  It expose a few methods to
assist in content negotation.

=head1 METHODS

This role defines the following methods:

=head2 choose_media_type (@array_of_types)

Given an array of possible media types ('application/json', 'text/html', etc.)
return the one that is the best match for the current request (by looking at the
current request ACCEPT header, parsing it and comparing).

  my $best_type = $c->req->accepts_media_type('image/jpeg', 'text/html', 'text/plain');

Returns undefined if no types match.

=head2 accepts_media_type ($type | @types)

For each media type passed as in a list of arguments, return that media type IF
the type is acceptable to the requesting client.  Can be used in boolean context
to determine if a single or list of types is acceptable or as a filter to permit
on those types that are acceptable:

    if($c->req->accepts_media_type('application/json')) {
      # handle JSON
    }

    my @acceptable = $c->req->accepts_media_type('image/jpeg', 'text/html', 'text/plain');

If nothing is acceptable an undef will be returned.

=head2 on_best_media_type (%callbacks)

Given a hash where the keys are media types and the values are coderefs, execute
and return the value of the coderef whose key is the best match for that media type
(based on the result of L</choose_media_type>.  For example:

    my $body = $c->req->on_best_media_type(
      'no_match' => sub { 'none' },
      'text/html' => sub { 'html' },
      'application/json' => sub { 'json' });

    $c->res->body($body);

The coderef will receive the current request object as its single argument.

If there are no matches, execute the coderef associated with a 'no_match' key
or return undef if no such key exists.  When executing the 'no_match' callback
(if any) we also pass a hash of the other callbacks, which you might use for
setting a default response, or to inspect as part of the information required.

    'no_match' => sub {
      my ($req, %callbacks) = @_;
      my @allowed = keys %callbacks;
      ...
    }

In this case the 'no_match' callback is removed from '%callbacks' passed to prevent
the possibility of recursion.

=head2 choose_language (@array_of_langauges)

Given an array of possible media types ('en-US', 'es', etc.)
return the one that is the best match for the current request.

=head2 accepts_language ($type)

Like L</accepts_media_type> but for request language.

=head2 on_best_language (%callbacks)

Works like L</on_best_media_type> but matches language.

=head2 choose_charset (@array_of_character_sets)

Given an array of possible media types ("UTF-8", "US-ASCII", etc.)
return the one that is the best match for the current request.

=head2 accepts_charset ($type)

Like L</accepts_media_type> but for request character set.

=head2 on_best_charset (%callbacks)

Works like L</on_best_media_type> but matches charset.

=head2 choose_encoding (@array_of_encodings)

Given an array of possible encodings ("gzip", "identity", etc.)
return the one that is the best match for the current request.

=head2 accepts_encoding ($type)

Like L</accepts_media_type> but for request encoding.

=head2 on_best_encoding (%callbacks)

Works like L</on_best_media_type> but matches encoding.

=head2 raw_choose_media_type

=head2 raw_choose_language

=head2 raw_choose_charset

=head2 raw_choose_encoding

These are methods that map directly to the underlying L<HTTP::Headers::ActionPack::ContentNegotiation>
object.  The are basicallty the same functionality except they require two arguments
(an additional one to support the HTTP header string).  You generally won't need them unless
you need to compare am HTTP header that is not one that is part of the current request.

=head1 Action Roles

The following ActionRoles are part of this distribution and are offered as
an alternative method for constructing your controllers

=over 4

=item L<Catalyst::ActionRole::ProvidesMedia>

=back

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Catalyst>, L<Catalyst::Request>, L<HTTP::Headers::ActionPack::ContentNegotiation>

=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
