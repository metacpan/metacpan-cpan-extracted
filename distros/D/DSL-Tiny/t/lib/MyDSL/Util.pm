use strict;
use warnings;

package MyDSL::Util;

use Sub::Exporter -setup => {
    exports => [
        qw(curry_with_tracer_call
            naked_generator
            )
    ]
};

# this example ripped off from Sub::Exporter::Util::curry_method
# called by e.g. build_dsl_keywords w/ method name as arg.
sub curry_with_tracer_call {
    my $override_name = shift;

    # called in _compile_keyword with $self as arg (DSL object/class)
    sub {
        my ( $invocant, $name ) = @_;
        $name = $override_name if defined $override_name;

        # connected to DSL keyword, called in dsl script.
        sub {
            push @{ $invocant->trace_log },
                "tracing call to $name(" . join( ", ", @_ ) . ")";
            $invocant->$name(@_);
        };
    };
}

sub naked_generator {
    my $override_name = shift;

    my $caller = caller();

    # called in _compile_keyword with $self as arg (DSL object/class)
    sub {
        my ( $invocant, $name ) = @_;
        $name = $override_name if defined $override_name;
        $name = $caller . '::' . $name;

        # connected to DSL keyword, called in dsl script.
        sub {
            no strict 'refs';
            &$name(@_);
        };
    };
}

1;
