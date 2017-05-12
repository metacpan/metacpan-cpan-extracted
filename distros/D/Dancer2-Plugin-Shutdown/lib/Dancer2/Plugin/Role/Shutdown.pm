use strictures 2;

package # for internal use only
    Dancer2::Plugin::Role::Shutdown;

# ABSTRACT: Role for L<Dancer2::Plugin::Shutdown>

use Carp qw(croak);
use Class::Load qw(load_class);
use Scalar::Util qw(blessed);
use Moo::Role 2;

use constant NORMAL => 0;
use constant GRACEFUL => 1;

our $VERSION = '0.002'; # VERSION


has shared => (
    is => 'rwp',
    default => sub { {} },
);


has validator => (
    is => 'rw',
    default => sub {
        sub {
            my ($app, $rest, $sessid) = @_;
            return unless $sessid;
            my $sx = $app->session->expires // 0;
            $app->session->expires($rest) if $rest > $sx;
            $app->response->header(Warning => "199 Application shuts down in $rest seconds");
            return 1;
        }
    }
);


sub has_valid_session {
    my $app = shift; 

    my $engine = $app->session_engine // return;

    return if $app->has_destroyed_session;

    my $session_cookie = $app->cookie( $engine->cookie_name ) // return;
    my $session_id = $session_cookie->value // return;

    eval  { $engine->retrieve( id => $session_id ) };
    return if $@;

    return $session_id;
}


sub session_status {
    my $app = shift; 

    my $engine = $app->session_engine // return "unsupported";

    return "destroyed" if $app->has_destroyed_session;

    my $session_cookie = $app->cookie( $engine->cookie_name ) // return "missing";
    my $session_id = $session_cookie->value // return "empty";

    eval  { $engine->retrieve( id => $session_id ) };
    return "invalid" if $@;

    return "ok";
}


sub before_hook {
    my $self = shift;
    return unless $self->shared->{state};
    my $app  = $self->app;
    my $time = $self->shared->{final};
    my $rest = $time - time;
    if ($rest < 0) {
        $self->status(503);
        $self->halt;
    } elsif ($self->shared->{state} == GRACEFUL) {
        if (my $validator = $self->validator) {
            my $sessid = has_valid_session($app);
            unless ($validator->($app, $rest, $sessid)) {
                $self->status(503);
                $self->halt;
            }
        }
    } else {
      croak "bad state: ".$self->shared->{state};
    }
}

sub _shutdown_at {
    my $self = shift;
    croak "a validator isn't installed yet" unless ref $self->validator eq 'CODE';
    my $time = shift // 0;
    if ($time < time) {
        $time += time;
    }
    $self->shared->{final} = $time;
    $self->shared->{state} = GRACEFUL;
    return $time;
}

1;

__END__

=pod

=head1 NAME

Dancer2::Plugin::Role::Shutdown - Role for L<Dancer2::Plugin::Shutdown>

=head1 VERSION

version 0.002

=head1 ATTRIBUTES

=head2 shared

=head2 validator

=head1 METHODS

=head2 before_hook

=head1 FUNCTIONS

=head2 has_valid_session

=head2 session_status

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libdancer2-plugin-shutdown-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Zurborg.

This is free software, licensed under:

  The ISC License

=cut
