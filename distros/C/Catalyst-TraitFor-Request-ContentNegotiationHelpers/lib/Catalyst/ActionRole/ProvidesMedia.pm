package Catalyst::ActionRole::ProvidesMedia;

use Moose::Role;
use Plack::MIME;
use Scalar::Util;
requires 'dispatch';

has 'media_actions' => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_media_actions');

  sub _build_media_actions {
    my $name = (my $self = shift)->name;
    my %media_actions = ();
    foreach my $action($self->class->meta->get_all_method_names) {
      my ($media_proto) = ($action=~m/^$name\_(.+)$/);
      next unless $media_proto;
      my $media = Plack::MIME->mime_type('.' . lc($media_proto)) ||
        ( $media_proto eq 'no_match' ? $media_proto : die "$media_proto not a MIME type" );
      $media_actions{$media} = $action;
    }

    return \%media_actions;
  }

sub forwards {
  my ($self, $ctx) = @_;

  Scalar::Util::weaken($ctx);
  my %media_actions = %{$self->media_actions};
  unless(exists $media_actions{no_match}) {
    $media_actions{no_match} = sub {
      my ($req, %callbacks) = @_;
      $ctx->res->status(406);
      $ctx->res->content_type('text/plain');
      my $allowed = join(',',(keys %callbacks)); 
      $ctx->res->body("You requested a media type we don't support.  Acceptable types are: $allowed");
    };
  }

  my @forwards = map {
    my $action = $media_actions{$_};
    $_ => $_ eq 'no_match' ?
      sub { $ctx->forward($action, \%media_actions) } :
      sub { $ctx->forward($action) };
  } (keys %media_actions);

  return @forwards;
}

around 'dispatch', sub {
  my ($orig, $self, $ctx, @rest) = @_;
  my $return = $self->$orig($ctx, @rest);
  $ctx->req->on_best_media_type($self->forwards($ctx));
  return $return;
};

1;

=head1 NAME

Catalyst::ActionRole::ProvidesMedia - Delegate actions based on best mediatype match

=head1 SYNOPSIS

    package MyApp;
    use Catalyst;
  
    MyApp->request_class_traits(['Catalyst::TraitFor::Request::ContentNegotiationHelpers']);
    MyApp->setup;

    package MyApp::Controller::Example;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub myaction :Chained(/) Does('ProvidesMedia') CaptureArgs(0) {
      my ($self, $c) = @_;
    }

      # Executed if the request accept header like prefers and accepts
      # type 'application/json'.
      sub myaction_JSON :Action { }

      # Executed if the request accept header like prefers and accepts
      # type 'text/html'.
      sub myaction_HTML :Action { }

      # Executed if none of the above types are accepted by the incoming
      # request accept header.

      sub myaction_no_match :Action {
        my ($self, $c, $matches) = @_;
        
        # There's a sane default for this, but you can override as needed.
      }

      sub next_action_in_chain_1 :Chained(myaction) Args(0) { ... }
      sub next_action_in_chain_2 :Chained(myaction) Args(0) { ... }

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

In server side content negotiation you seek the provide response data based on
what a client says it can accept (typically ranked in order of what is most
acceptable to which is least.)  This way a client can tell the server what type
of representation of a resource it knows how to handle.  A Server can either
provide that represention or return an error state explaining that it cannot (
with some optional information about what it can provide).

Classic REST over HTTP allows for server side content negotiation over representation
media type, language, encoding and character set.   The L<Catalyst> request trait
L<Catalyst::TraitFor::Request::ContentNegotiationHelpers> provides methods on the request
object for helping a programmer correctly make choices based on what a client is 
requesting.  This Actionrole provides additional sugar by allowing one to delegate
to an action based on the matched media type.

B<NOTE>: This actionrole only provides feaures over mediatypes NOT other catagories
of content negotiation.  However in general practice content negotiation over
media types is probably the most common use case.  It would be easy to add action
roles that clone this one to do the same for encoding, language, etc.

=head1 USAGE

Apply the action role to an action, for example:

    sub myaction :Chained(/) Does('ProvidesMedia') CaptureArgs(1) {
      my ($self, $c, $id) = @_;
    }

When the action body completes (as long as it does not detach or generate
an error) we then delegate (via $c->forward) to an action that matches the
first action's method name, followed by an extension that can be matched to
a media type:

    # Executed if the request accept header like prefers and accepts
    # type 'application/json'.
    sub myaction_JSON :Action { }

    # Executed if the request accept header like prefers and accepts
    # type 'text/html'.
    sub myaction_HTML :Action { }

When several possible matches exist, as in the above example, we inspect the
HTTP request ACCEPT header and determine the best match.  Should no match
exist, we return a default 'no match' response which looks like this:

    sub myaction_no_match :Action {
      my ($self, $c, $matches) = @_;
      my $allowed = join(',', keys %{$matches||+{}});
      $c->response->status(406);
      $c->response->content_type('text/plain');
      $c->response->body("No match for Accept header.  Media types we support are: $allowed");
    }

You may override this default action by providing your own.  The argument
"$matches" is a hashref where the keys are matches allowed and the values
are references to the matched action, that way you could for example
redelegate to default.

=head1 VERSUS Catalyst::Action::REST

L<Catalyst::TraitFor::Request::REST> (which comes with the L<Catalyst::Action::REST>
distribution) defines a method 'accepted_content_types' which returns an array of
content types that the client accepts, sorted in order by inspecting the ACCEPT
header.  However for GET requests this is overridden and instead we return the
request content-type if one exists.  I'm not sure this is exactly correct.

=head1 METHODS
 
This role contains the following methods.

=head1 ALSO SEE

L<Catalyst::TraitFor::Request::ContentNegotiationHelpers>, L<Catalyst>

=head1 AUTHOR

  John Napiorkowski <jnapiork@cpan.org>
  
=head1 COPYRIGHT
 
Copyright (c) 2015 the above named AUTHOR
 
=head1 LICENSE
 
You may distribute this code under the same terms as Perl itself.
 
=cut
