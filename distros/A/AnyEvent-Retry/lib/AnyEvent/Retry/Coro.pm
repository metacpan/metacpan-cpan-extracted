package AnyEvent::Retry::Coro;
BEGIN {
  $AnyEvent::Retry::Coro::VERSION = '0.03';
}
# ABSTRACT: AnyEvent::Retry for jobs that run in separate threads
use Moose;
use Coro;
use Scalar::Util qw(weaken);
use Try::Tiny;

use true;
use namespace::autoclean;

extends 'AnyEvent::Retry';

has '+on_failure' => (
    init_arg => undef,
    required => 0,
    writer   => 'set_failure_cb',
);

has '+on_success' => (
    init_arg => undef,
    required => 0,
    writer   => 'set_success_cb',
);

has 'running_coro' => (
    init_arg => undef,
    accessor => 'running_coro',
    clearer  => 'clear_running_coro',
);

before start => sub {
    my $self = shift;
    Scalar::Util::weaken($self);
    my $cb = Coro::rouse_cb;
    $self->set_failure_cb( sub { $cb->( error   => @_ ) } );
    $self->set_success_cb( sub { $cb->( success => @_ ) } );
};

override run_code => sub {
    my $self = shift;
    my @result = try {
        my $result = $self->try->();
        return (($result ? 1 : 0), 'success', $result);
    }
    catch {
        warn $_;
        return (0, 'error', $_);
    }
};

override handle_tick => sub {
    my ($self, $i) = @_;
    weaken $self;
    $self->running_coro(async {
        $self->handle_result($self->run_code);
        $self->clear_running_coro if defined $self;
    });
};

sub DEMOLISH {
    my $self = shift;
    $self->running_coro->throw('DEMOLISH');
}

sub wait {
    my ($status, @args) = Coro::rouse_wait();
    return $args[0] if $status eq 'success';
    die $args[1];
}

sub run {
    my $self = shift;
    $self->start;

    # this is so DEMOLISH still works right
    my $class = $self->meta->name;
    undef $self;
    $class->wait;
}

__PACKAGE__->meta->make_immutable;



=pod

=head1 NAME

AnyEvent::Retry::Coro - AnyEvent::Retry for jobs that run in separate threads

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Coro;

    my $r = AnyEvent::Retry::Coro->new(
        max_tries => 100, # eventually give up
        interval  => { Constant => { interval => 1 } }, # try every second
        try       => {
            die 'out of cake!' if $cake-- < 0;
            return do_science();
        },

    );

    my $neat_gun = $r->run; # keep on trying until you run out of cake

=head1 DESCRIPTION

This module makes L<AnyEvent::Retry> work nicely with L<Coro>.  You
don't need to provide success or failure callbacks anymore, and your
task to retry just needs C<die> or return a result.

=head1 METHODS

=head2 run

This runs the task, blocking the thread until a result is available.
If your task encounters an error, this will die.  If it's sucessful,
it returns the result.

=head2 wait

Allows you to run the task without blocking:

    $r->start;
    ...; # do anything
    my $result = $r->wait; # block here

C<run> is implemented exactly like the above.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

