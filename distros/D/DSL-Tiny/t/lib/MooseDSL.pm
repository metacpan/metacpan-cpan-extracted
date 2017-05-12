#!perl

package MooseDSL;

use Moose;

with qw(DSL::Tiny::Role);

sub build_dsl_keywords {
    return [
        # simple keyword -> curry_method examples
        qw(argulator return_self clear_call_log),
    ];
}

has call_log => (
    clearer => 'clear_call_log',
    default => sub { [] },
    is      => 'rw',
    lazy    => 1
);

sub argulator {
    my $self = shift;
    push @{ $self->call_log }, join "::", @_;
}

sub return_self { return $_[0] }

1;
