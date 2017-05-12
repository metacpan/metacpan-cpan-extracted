# ABSTRACT: Use L<AnyEvent> with L<Tickit> user interface.

use strict;
use warnings;
package AnyEvent::Tickit;
BEGIN {
  $AnyEvent::Tickit::AUTHORITY = 'cpan:AJGB';
}
$AnyEvent::Tickit::VERSION = '0.01';
use AnyEvent;
use base qw( Tickit );

sub _capture_weakself {
    my ($self, $method) = @_;

    Scalar::Util::weaken $self;

    my $cb = $self->can($method);

    return $cb->( $self, @_ );
}

sub new {
    my ($class, %args) = @_;

    my $cv = delete $args{cv};

    my $self = $class->Tickit::new( %args );

    $self->{ae_loop} = $cv || AE::cv;

    $self->{ae_sigwinch} = AE::signal WINCH => sub {
        $self->_SIGWINCH;
    };

    $self->{ae_io} = AE::io $self->term->get_input_handle, 0, sub {
        $self->_input_readready();
    };

    $self->{ae_timer} = AE::timer 0, 0, sub {
        $self->_timeout();
    };

    return $self;
}

sub get_loop {
    return $_[0]->{ae_loop};
}

sub _make_writer {
    my ($self, $out) = @_;

    $self->{ae_writer} = AnyEvent::Tickit::Handle->new(
        fh => $out,
        no_delay => 1,
    );

    return $self->{ae_writer};
}

sub _input_readready {
    my $self = shift;

    my $term = $self->term;

    undef $self->{timer};

    $term->input_readable();

    $self->_timeout;
}

sub _timeout {
    my $self = shift;

    my $term = $self->term;
    if ( defined( my $timeout = $term->check_timeout) ) {
        $self->{timer} = AE::timer $timeout / 1000, 0, sub {
            $self->_timeout();
        };
    }
}

sub later {
    my ($self, $cb) = @_;
    AnyEvent::postpone {
        $cb->();
    };
}

sub timer {
    my $self = shift;
    my ($mode, $when, $cb) = @_;

    my $after = $mode eq 'at' ? $when - time : $when;

    push @{ $self->{ae_timers} }, AE::timer $after, 0, $cb;
}

sub stop {
    $_[0]->get_loop->send;
}

sub run {
    my $self = shift;

    $self->setup_term();

    $self->{ae_sigint} = AE::signal INT => sub {
        $self->stop;
    };

    $self->get_loop->recv;

    {
        $self->teardown_term;

        delete $self->{$_} for qw(
            ae_sigint
            ae_sigwinch
            ae_io
            ae_loop
            ae_timer
            ae_timers
        );
    }

    return 1;
}

package
    AnyEvent::Tickit::Handle;

use base 'AnyEvent::Handle';

*write = \&AnyEvent::Handle::push_write;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Tickit - Use L<AnyEvent> with L<Tickit> user interface.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use AnyEvent;
    use AnyEvent::Tickit;

    my $loop = AE::cv;

    my $tickit = AnyEvent::Tickit->new( cv => $cv );

    # Create some widgets
    # ...

    $tickit->set_root_widget( $rootwidget );

    # Create some AnyEvent event handlers
    # ...

    $tickit->run();

=head1 DESCRIPTION

Use L<AnyEvent> with L<Tickit> user interface.

=head1 SEE ALSO

=over 4

=item * L<Tickit::Async>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
