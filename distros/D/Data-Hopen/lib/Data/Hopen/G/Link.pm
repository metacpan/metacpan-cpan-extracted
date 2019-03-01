# Data::Hopen::G::Link - base class for hopen edges
package Data::Hopen::G::Link;
use Data::Hopen::Base;

our $VERSION = '0.000012';

use parent 'Data::Hopen::G::Runnable';
use Class::Tiny {
    greedy => 0
};

use Data::Hopen qw(:default UNSPECIFIED);
use Data::Hopen::Util::Data qw(clone);

=head1 NAME

Data::Hopen::G::Link - The base class for all hopen links between ops.

=head1 VARIABLES

=head2 greedy

If set truthy in the C<new()> call, the edge will ask for all inputs.

=head1 FUNCTIONS

=head2 run

Copy the inputs to the outputs.

    my $hrOutputs = $op->run($scope)

The output is C<{}> if no inputs are provided.

=cut

sub _run {
    my ($self, %args) = getparameters('self', [qw(; phase generator)], @_);
    return $self->passthrough(-nocontext => 1);
} #run()


=head2 BUILD

Constructor.  Interprets L</greedy>.

=cut

sub BUILD {
    my ($self, $args) = @_;
    $self->want(UNSPECIFIED) if $args->{greedy};
    #hlog { 'Link::BUILD', Dumper($self), Dumper($args) };
    #hlog { 'Link::BUILD', Dumper($self->scope) };
} #BUILD()

1;
__END__
# vi: set fdm=marker: #
