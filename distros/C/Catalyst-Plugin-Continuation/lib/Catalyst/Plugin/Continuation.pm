package Catalyst::Plugin::Continuation;

use strict;
use warnings;

use Catalyst::Continuation;
use NEXT;

use base qw/Class::Accessor/;

__PACKAGE__->mk_accessors(qw/continuation/);

our $VERSION = '0.01';

*continue = \&cont;

=head1 NAME

Catalyst::Plugin::Continuation - Catalyst Continuation Plugin

=head1 SYNOPSIS

    # Make sure to load session plugins too!
    package MyApp;
    use Catalyst qw/Session Session::Store::File
      Session::State::Cookie Continuation/;

    # Create a controller
    package MyApp::Controller::Test;
    use base 'Catalyst::Controller';

    # Add a action with attached action class
    sub counter : Global {
        my ( $self, $c ) = @_;
        my $up      = $c->continue('up');
        my $down    = $c->continue('down');
        my $counter = $c->stash->{counter} || 0;
        $c->res->body(<<"EOF");
    Counter: $counter<br/>
    <a href="$up">++</a>
    <a href="$down">--</a>
    EOF
    }

    # Add private actions for continuations
    sub up   : Private { $_[1]->stash->{counter}++ }
    sub down : Private { $_[1]->stash->{counter}-- }

=head1 DESCRIPTION

Catalyst Continuation Plugin.

=head1 OVERLOADED METHODS

=head2 prepare_action

=head2 dispatch

These methods are overridden to allow the special continuation dispatch.

=head1 METHODS

=head2 continuation

Contains the continuation object that was restored.

=head2 set_continuation $id, $structure

=head2 get_continuation $id

=head2 delete_continuation $id

=head2 active_continuations

=head2 clear_continuations

=head2 generate_continuation_id

These are internal methods which you can override.

They default to storing inside C<< $c->session >>, and using
L<Catalyst::Plugin::Session/generate_session_id>.

If you want your continuations to be garbage collected in some way you need to
override this to store the data in some other backend.

Note that C<active_continuations> returns a hash reference which you can edit.
Be careful.

=cut

sub get_continuation {
    my ( $c, $id ) = @_;
    $c->session->{_continuations}{$id};
}

sub set_continuation {
    my ( $c, $id, $value ) = @_;
    $c->session->{_continuations}{$id} = $value;
}

sub delete_continuation {
    my ( $c, $id ) = @_;
    delete $c->session->{_continuations}{$id};
}

sub active_continuations {
    my $c = shift;
    return $c->session->{_continuations};
}

sub clear_continuations {
    my $c = shift;
    %{ $c->session->{_continuations} } = ();
}

sub generate_continuation_id {
    my $c = shift;
    $c->generate_session_id;
}

sub prepare_action {
    my $c = shift;
    if ( $c->req->path eq "" and my $k = $c->req->params->{_k} ) {
        $c->log->debug(qq/Found continuation "$k"/) if $c->debug;
        if ( my $cont = $c->cont_class->new_from_store( $c, $k ) ) {
            $c->log->debug(qq/Restored continuation "$k"/) if $c->debug;
            $c->continuation($cont);
        } else {
            $c->continuation_expired($k);
        }
    } else {
        $c->NEXT::prepare_action(@_);
    }
}

sub dispatch {
    my $c = shift;

    if ( my $cont = $c->continuation ) {
        return $cont->execute;
    } else {
        return $c->NEXT::dispatch(@_);
    }
}

=head2 $c->continuation_expired( $id )

This handler is called when the continuation with the ID $id tried to get
invoked but did not exist

=cut

sub continuation_expired {
    my ( $c, $k ) = @_;
    die "The continuation has expired";
}

=head2 $c->resume_continuation( $cont_or_id );

Resume a continuation based on an ID or an object.

This is a convenience method intended on saving you the need to load and
execute the continuation yourself.

=cut

sub resume_continuation {
    my ( $c, $id_or_cont, @args ) = @_;

    (
        Scalar::Util::blessed($id_or_cont)
        ? $id_or_cont
        : $c->cont_class->new_from_store( $c, $id_or_cont )
          || $c->continuation_expired($id_or_cont)
    )->execute(@args);
}

=head2 $c->continue($method)

=head2 $c->cont($method)

Returns the L<Catalyst::Continuation> object for given method.

Takes the same arguments as L<Catalyst/forward> and it's relatives.

=cut

sub cont {
    my ( $c, @args ) = @_;
    $c->cont_class->new( c => $c, forward => \@args );
}

=head2 $c->caller_continuation

A pseudo-cc - a continuation to your caller.

Note that this does B<NOT> honor the call stack in any way - it is B<ONLY> to
reinvoke the immediate caller. See the NeedsLogin test controller in the test
suite for an example of how to use this effectively.

=cut

sub caller_continuation {
    my $c      = shift;
    my $caller = $c->stack->[-2] or die "No caller";

    $c->cont_class->new(
        c                 => $c,
        forward           => [ "/" . $caller->reverse ],
        forward_to_caller => 0,
    );
}

=head2 $c->cont_class

Returns the string C<Catalyst::Continuation> by default. You may override this
to replace the continuation class.

=cut

sub cont_class { "Catalyst::Continuation" }

sub _uri_to_cont {
    my ( $c, $cont ) = @_;
    $c->uri_for( "/", { _k => $cont->id } );
}

=head1 CAVEATS

Continuations take up space, and are by default stored in the session.

When invoked a session will delete itself by default, but anything else will
leak, until the session expires.

If this is a concern for you, override the C<get_continuation> family of
functions to have a better scheme for storage.

Some approaches you could implement, depending on how you use continuations:

=over 4

=item size limiting

Store up to $x continuations, and toss out old ones once this starts to
overflow. This is essentially an LRU policy.

=item continuation grouping

Group all the continuations saved in a single request together. When one of
them is deleted, all the rest go with it.

=item use the fine grained session expiry feature

L<Catalyst::Plugin::Session> allows you to expire some session keys before the
entire session expired. You can associate each session with it's own unique
key, and avoid extending the continuation's time-to-live.

=back

If you override all these functions then you don't need the
L<Catalyst::Plugin::Session> dependency.

=head1 SEE ALSO

L<Catalyst>, Seaside (http://www.seaside.st/), L<Jifty>, L<Coro::Cont>, psychiatrist(1).

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>
Yuval Kogman, C<nothingmuch@woobling.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
