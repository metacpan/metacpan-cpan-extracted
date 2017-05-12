#!perl

package MyDSL;

use Moo;

with qw(DSL::Tiny::Role);

use MyDSL::Util qw(curry_with_tracer_call naked_generator);
use MyHelper;
use Sub::Exporter::Util qw(curry_chain curry_method);

sub build_dsl_keywords {
    return [
        # simple keyword -> curry_method examples
        qw(call_log_as_array clear_call_log),

        # simple keyword, written differently
        'my_context',

        # test explicit call to curry_method w/out renaming.
        main => { as => curry_method, },

        # use different keyword/method names and use curry_method
        break_encapsulation => { as => curry_method('return_self'), },

        # chain through has_a relationship
        # ends up as $dsl->a_helper->beep().
        test_curry_chain => { as => curry_chain( a_helper => 'beep' ), },

        # chain through has_a relationship, with an explicit warning to
        # helper's method.
        # ends up as $dsl->a_helper->beep( warning => 'Andele!').
        test_curry_chain_with_arg => {
            as => curry_chain( a_helper => beep => [ warning => 'Andele!' ] ),
        },

        # a single before generator
        test_simple_before => {
            as     => curry_method('main'),
            before => curry_method('before_1'),
        },

        # several before generators
        test_multi_before => {
            as     => curry_method('main'),
            before => [ curry_method('before_1'), curry_method('before_2'), ],
        },

        # a single after generator
        test_simple_after => {
            after => curry_method('after_1'),
            as    => curry_method('main'),
        },

        # several after generators
        test_multi_after => {
            after => [ curry_method('after_1'), curry_method('after_2'), ],
            as    => curry_method('main'),
        },

        # a bit of everything
        test_complex => {
            after  => [ curry_method('after_1'),  curry_method('after_2'), ],
            as     => curry_method('main'),
            before => [ curry_method('before_1'), curry_method('before_2'), ],
        },

        # a method that stuffs its args into the call log
        qw(argulator),

        qw(clear_trace_log),
        test_alternate_currier => { as => curry_with_tracer_call('main'), },

        naked => { as => naked_generator },
        bare  => { as => naked_generator('naked') },

    ];
}

has a_helper => ( is => 'rw', default => sub { return MyHelper->new() } );

has call_log => (
    clearer => 'clear_call_log',
    default => sub { [] },
    is      => 'rw',
    lazy    => 1
);

has trace_log => (
    clearer => 'clear_trace_log',
    default => sub { [] },
    is      => 'rw',
    lazy    => 1
);

sub after_1 { push @{ $_[0]->call_log }, 'after_1' }
sub after_2 { push @{ $_[0]->call_log }, 'after_2' }

sub argulator {
    my $self = shift;
    push @{ $self->call_log }, join "::", @_;
}

sub before_1 { push @{ $_[0]->call_log }, 'before_1' }
sub before_2 { push @{ $_[0]->call_log }, 'before_2' }

sub call_log_as_array { @{ $_[0]->call_log } }

sub main { push @{ $_[0]->call_log }, 'main' }

sub naked { return "buck" }

sub my_context {
    my $self = shift;
    if ( defined wantarray ) {
        if (wantarray) {
            push @{ $self->call_log }, 'array_context';
        }
        else {
            push @{ $self->call_log }, 'scalar_context';
        }
    }
    else {
        push @{ $self->call_log }, 'void_context';
    }
}

sub return_self { return $_[0] }

1;
