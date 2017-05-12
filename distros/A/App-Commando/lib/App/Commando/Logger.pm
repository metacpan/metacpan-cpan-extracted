package App::Commando::Logger;

use strict;
use warnings;

use Carp;
use Moo;
use Scalar::Util qw(openhandle);

has 'device'    => ( is => 'ro' );
has 'formatter' => ( is => 'rw' );
has 'level'     => ( is => 'rw' );

sub BUILDARGS {
    my ($class, $device) = @_;

    return {
        device => $device,
    };
}

sub BUILD {
    my ($self) = @_;

    eval {
        $self->{_fh} = openhandle($self->device);
        open($self->{_fh}, '>>', $self->device) if !defined $self->{_fh};
    };
    if ($@) {
        croak 'Can\'t open log device';
    }

    return $self;
}

my %levels = (
    'debug' => 1,
    'info'  => 2,
    'warn'  => 3,
    'error' => 4,
    'fatal' => 5,
);

sub _store {
    my ($self, $level, $message) = @_;

    if ($levels{lc $level} >= $levels{lc $self->{level}}) {
        print { $self->{_fh} }
            ref($self->formatter) eq 'CODE' ?
                $self->formatter->($level, $message) : $message;
    }
}

sub debug {
    my ($self, $message) = @_;

    $self->_store('debug', $message);
}

sub info {
    my ($self, $message) = @_;

    $self->_store('info', $message);
}

sub warn {
    my ($self, $message) = @_;

    $self->_store('warn', $message);
}

sub error {
    my ($self, $message) = @_;

    $self->_store('error', $message);
}

sub fatal {
    my ($self, $message) = @_;

    $self->_store('fatal', $message);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Commando::Logger

=head1 VERSION

version 0.012

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
