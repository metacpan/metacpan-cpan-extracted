# Data::Hopen::G::Goal - A named build goal
package Data::Hopen::G::Goal;
use Data::Hopen::Base;

our $VERSION = '0.000012';

use parent 'Data::Hopen::G::Op';
use Class::Tiny {
    should_output => true,      # if true, forward the goal's inputs as
                                # its outputs.
};

use Data::Hopen;
use Data::Hopen::Util::Data qw(forward_opts);

# Docs {{{1

=head1 NAME

Data::Hopen::G::Goal - a named goal in a hopen build

=head1 SYNOPSIS

A C<Goal> is a named build target, e.g., C<doc> or C<dist>.  The name C<all>
is reserved for the root goal.  Goals usually appear at the end of the build
graph, but this is not required --- Goal nodes can appear anywhere in the
graph.

=head1 MEMBERS

=head2 should_output

Boolean, default true.  If false, the goal's outputs are always C<{}> (empty).
If true, the goal's inputs are passed through as outputs.

=head1 FUNCTIONS

=head2 run

Passes through the inputs if L</should_output> is set.

=cut

# }}}1

sub _run {
    my ($self, %args) = getparameters('self', [qw(; phase generator)], @_);
    hlog { Goal => $self->name, ($self->should_output ? 'with' : 'without'),
            'outputs' };

    return {} unless $self->should_output;

    return $self->passthrough(-nocontext=>1, -levels => 'local',
            forward_opts(\%args, {'-'=>1}, qw[phase generator]));
} #_run()

=head2 BUILD

Enforce the requirement for a user-specified name.

=cut

sub BUILD {
    my ($self, $args) = @_;
    croak 'Goals must have names' unless $args->{name};
} #BUILD()

1;
__END__
# vi: set fdm=marker: #
