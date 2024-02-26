package Catalyst::ActionRole::Methods;

use Moose::Role;

our $VERSION = '0.103';

around 'list_extra_info' => sub {
    my $orig = shift;
    my $self = shift;
    my $info = $self->$orig( @_ );
    $info->{'HTTP_METHOD'} = [ $self->get_allowed_methods( $self->class, undef, $self->name ) ];
    $info;
};

around 'dispatch', sub {
    my $orig = shift;
    my $self = shift;
    my $c    = shift;

    my $return = $self->$orig($c, @_);

    my $class = $self->class;
    my $controller = $c->component( $class );
    my $method_name = $self->name;
    my $req_method = $c->request->method;
    my $suffix = uc $req_method;
    my ( $rest_method, $code );

    {
        $rest_method = $method_name . '_' . $suffix;

        if ( $code = $controller->action_for( $rest_method ) ) {
            my $sub_return = $c->forward( $code, $c->request->args );
            return defined $sub_return ? $sub_return : $return;
        } elsif ( $code = $controller->can( $rest_method ) ) {
            # nothing to do
        } elsif ( 'OPTIONS' eq $suffix ) {
            $c->response->status( 204 );
        } elsif ( 'HEAD' eq $suffix ) {
            $suffix = 'GET';
            redo;
        } elsif ( 'not_implemented' eq $suffix ) {
            ( my $enc_req_method = $req_method ) =~ s[(["'&<>])]{ '&#'.(ord $1).';' }ge;
            $c->response->status( 405 );
            $c->response->content_type( 'text/html' );
            $c->response->body(
                '<!DOCTYPE html><title>405 Method Not Allowed</title>'
                . "<p>The requested method $enc_req_method is not allowed for this URL.</p>"
            );
        } else {
            $suffix = 'not_implemented';
            redo;
        }
    }

    if ( not $code ) {
        my @allowed = $self->get_allowed_methods( $class, $c, $method_name );
        $c->response->header( Allow => @allowed ? \@allowed : '' );
    }

    # localise stuff so we can dispatch the action 'as normal, but get
    # different stats shown, and different code run.
    # Also get the full path for the action, and make it look like a forward
    local $self->{'code'} = $code || sub {};
    ( local $self->{'reverse'} = "-> $self->{'reverse'}" ) =~ s{[^/]+\z}{$rest_method};

    my $sub_return = $c->execute( $class, $self, @{ $c->request->args } );
    defined $sub_return ? $sub_return : $return;
};

sub get_allowed_methods {
    my ( $self, $controller, $c, $name ) = @_;
    my $class = ref $controller || $controller; # backcompat
    my %methods = map /^\Q$name\E\_(.+)()$/, $class->meta->get_all_method_names;
    $methods{'HEAD'} = 1 if exists $methods{'GET'};
    delete $methods{'not_implemented'};
    sort keys %methods;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::ActionRole::Methods - Dispatch by HTTP Methods

=head1 SYNOPSIS

 sub foo : Local Does('Methods') {
   my ($self, $c, $arg) = @_;
   # called first, regardless of HTTP request method
 }

 sub foo_GET : Action {
   my ($self, $c, $arg) = @_;
   # called next, but only for GET requests
   # this is passed the same @_ as its generic action
 }

 sub foo_POST { # does not need to be an action
   my ($self, $c, $arg) = @_;
   # likewise for POST requests
 }

 sub foo_not_implemented { # fallback
   my ($self, $c, $arg) = @_;
   # only needed if you want to override the default 405 response
 }

=head1 DESCRIPTION

This is a L<Catalyst> extension which adds additional dispatch based on the
HTTP method, in the same way L<Catalyst::Action::REST> does:

An action which does this role will be matched and run as usual. But after it
returns, a sub-action will also run, which will be identified by taking the
name of the main action and appending an underscore and the HTTP request method
name. This sub-action is passed the same captures and args as the main action.

You can also write the sub-action as a plain method without declaring it as an
action. Probably the only advantage of declaring it as an action is that other
action roles can then be applied to it.

There are several fallbacks if a sub-action for the current request method does
not exist:

=over 3

=item 1.

C<HEAD> requests will try to use the sub-action for C<GET>.

=item 2.

C<OPTIONS> requests will set up a 204 (No Content) response.

=item 3.

The C<not_implemented> sub-action is tried as a last resort.

=item 4.

Finally, a 405 (Method Not Found) response is set up.

=back

Both fallback responses include an C<Allow> header which will be populated from
the available sub-actions.

Note that this action role only I<adds> dispatch. It does not affect matching!
The main action will always run if it otherwise matches the request, even if no
suitable sub-action exists and a 405 is generated. Nor does it affect chaining.
All subsequent actions in a chain will still run, along with their sub-actions.

=head1 INTERACTION WITH CHAINED DISPATCH

The fact that this is an action role which is attached to individual actions
has some odd and unintuitive consequences when combining it with Chained
dispatch, particularly when it is used in multiple actions in the same chain.
This example will not work well at all:

 sub foo : Chained(/) CaptureArgs(1) Does('Methods') { ... }
 sub foo_GET { ... }

 sub bar : Chained(foo) Args(0) { ... }
 sub bar_POST { ... }

Because each action does its own isolated C<Methods> sub-dispatch, a C<GET>
request to this chain will run C<foo>, then C<foo_GET>, then C<bar>, then
set up a 405 response due to the absence of C<bar_GET>. And because C<bar> only
has a sub-action for C<POST>, that is all the C<Allow> header will contain.

Worse (maybe), a C<POST> will run C<foo>, then set up a 405 response with an
C<Allow> list of just C<GET>, but then still run C<bar> and C<bar_POST>.

This means it is never useful for an action which is further along a chain to
have I<more> sub-actions than any earlier action.

Having I<fewer> sub-actions can be useful: if the earlier part of the chain is
shared with other chains then each chain can handle a different set of request
methods:

 sub foo : Chained(/) CaptureArgs(1) Does('Methods') { ... }
 sub foo_GET { ... }
 sub foo_POST { ... }

 sub bar : Chained(foo) Args(0) { ... }
 sub bar_GET { ... }

 sub quux : Chained(foo) Args(0) { ... }
 sub quux_POST { ... }

In this example, the C</foo/bar> chain will handle only C<GET> while the
C</foo/quux> chain will handle only C<POST>. If you later wanted to make
C</foo/quux> also handle C<GET> then you would only need to add C<quux_GET>
because there is already a C<foo_GET>. But to make C</foo/bar> handle C<PUT>,
you would need to add both C<foo_PUT> I<and> C<bar_PUT>.

=head1 VERSUS Catalyst::Action::REST

L<Catalyst::Action::REST> works fine doesn't it?  Why offer a new approach?  There's
a few reasons:

First, when L<Catalyst::Action::REST> was written we did not have
L<Moose> and the only way to augment functionality was via inheritance.  Now that
L<Moose> is common we instead say that it is typically better to use a L<Moose::Role>
to augment a class function rather to use a subclass.  The role approach is a smaller
hammer and it plays nicer when you need to combine several roles to augment a class
(as compared to multiple inheritance approaches.).  This is why we brought support for
action roles into core L<Catalyst::Controller> several years ago.  Letting you have
this functionality via a role should lead to more flexible systems that play nice
with other roles.  One nice side effect of this 'play nice with others' is that we
were able to hook into the 'list_extra_info' method of the core action class so that
you can now see in your developer mode debug output the matched http methods, for
example:

    .-------------------------------------+----------------------------------------.
    | Path Spec                           | Private                                |
    +-------------------------------------+----------------------------------------+
    | /myaction/*/next_action_in_chain    | GET, HEAD, POST /myaction (1)          |
    |                                     | => /next_action_in_chain (0)           |
    '-------------------------------------+----------------------------------------'

This is not to say its never correct to use an action class, but now you have the
choice.

Second, L<Catalyst::Action::REST> has the behavior as noted of altering the core
L<Catalyst::Request> class.  This might not be desired and has always struck the
author as a bit too much side effect / action at a distance.

Last, L<Catalyst::Action::REST> is actually a larger distribution with a bunch of
other features and dependencies that you might not want.  The intention is to offer
those bits of functionality as standalone, modern components and allow one to assemble
the parts needed, as needed.

This action role is for the most part a 1-1 port of the action class, with one minor
change to reduce the dependency count.  Additionally, it does not automatically
apply the L<Catalyst::Request::REST> action class to your global L<Catalyst>
action class. This feature is left off because its easy to set this yourself if
desired via the global L<Catalyst> configuration and we want to follow and promote
the idea of 'do one thing well and nothing surprising'.

B<NOTE> There is an additional minor change in how we handle return values from actions.  In
general L<Catalyst> does nothing with an action return value (unless in an auto action).
However this might not always be the future case, and you might have used that return value
for something in your custom code.  In L<Catalyst::Action::REST> the return value was
always the return of the dispatched sub action (if any).  We tweaked this so that we use
the sub action return value, BUT if that value is undefined, we use the parent action
return value instead.

We also dropped saying 'REST' when all we are doing is dispatching on HTTP method.
Since the time that the first version of L<Catalysts::Action::REST> was released to
CPAN our notion of what 'REST' means has greatly evolved so I think its correct to
change the name to be functionality specific and to not confuse people that are new
to the REST discipline.

This action role is intended to be used in all the places
you used to use the action class and have the same results, with the exception
of the already mentioned 'not messing with the global request class'.  However
L<Catalyst::Action::REST> has been around for a long time and is well vetted in
production so I would caution care with changing your mission critical systems
very quickly.

=head1 VERSUS NATIVE METHOD ATTRIBUTES

L<Catalyst> since version 5.90030 has offered a core approach to dispatch on the
http method (via L<Catalyst::ActionRole::HTTPMethods>).  Why still use this action role
versus the core functionality?  ALthough it partly comes down to preference and the
author's desire to give current users of L<Catalyst::Action::REST> a path forward, there
is some functionality differences beetween the two which may recommend one over the
other.  For example the core method matching does not offer an automatic default
'Not Implemented' response that correctly sets the OPTIONS header.  Also the dispatch
flow between the two approaches is different and when using chained actions one 
might be a better choice over the other depending on how your chains are arranged and
your desired flow of action.

=head1 METHODS
 
This role contains the following methods.

=head2 get_allowed_methods

Returns a list of the allowed methods.

=head2 dispatch
 
This method overrides the default dispatch mechanism to the re-dispatching
mechanism described above.

=head1 CONTRIBUTORS

This module is based on code, tests and documentation extracted out of
L<Catalyst::Action::REST>, which was originally developed by Adam Jacob
with lots of help from mst and jrockway, while being paid by Marchex, Inc
(http://www.marchex.com).

The following people also contributed to parts copied from that package:
 
Tomas Doran (t0m) E<lt>bobtfish@bobtfish.netE<gt>
 
Dave Rolsky E<lt>autarch@urth.orgE<gt>
 
Arthur Axel "fREW" Schmidt E<lt>frioux@gmail.comE<gt>
 
J. Shirley E<lt>jshirley@gmail.comE<gt>
 
Wallace Reis E<lt>wreis@cpan.orgE<gt>
 
=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

John Napiorkowski <jjnapiork@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
