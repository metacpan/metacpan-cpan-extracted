# App::hopen::G::Cmd - base class for hopen(1) command-graph nodes
package App::hopen::G::Cmd;
use Data::Hopen::Base;
use Quote::Code;

our $VERSION = '0.000010';

use parent 'Data::Hopen::G::Op';
use Class::Tiny {
    made => sub { [] },
};

use Class::Method::Modifiers qw(around);
use Data::Hopen qw(getparameters);

# Docs {{{1

=head1 NAME

App::hopen::G::Cmd - base class for hopen(1) operation-graph nodes

=head1 SYNOPSIS

This is the base class for graph nodes in the command graph of
L<App::hopen>.  See L<App::hopen::Conventions>.

=head1 ATTRIBUTES

=head2 made

An arrayref of the outputs from this function, which are L<App::hopen::Asset>
instances.  (TODO enforce this requirement.)

=cut

# }}}1

=head1 FUNCTIONS

=head2 make

Adds L<App::hopen::Asset> instances to L</made> (a L<Cmd|App::hopen::G::Cmd>'s
asset output).  B<Does not> add the assets to the generator's asset graph,
since the generator is not available as instance data.  One or more parameters
or arrayrefs of parameters can be given.  Returns a list of the C<Asset>
instances made.  Each parameter can be:

=over

=item *

An L<App::hopen::Asset> or subclass (in which case
L<made_by|App::hopen::Asset/made_by> is updated)

=item *

A valid C<target> for an L<App::hopen::Asset>.

=back

=cut

sub make {
    my $self = shift or croak 'Need an instance';
    my @retval;
    for my $arg (@_) {
        if(ref $arg eq 'ARRAY') {
            push @retval, $self->make(@$arg);
        } elsif(eval { $arg->DOES('App::hopen::Asset') }) {
            $arg->made_by($self);
            push @{$self->made}, $arg;
            push @retval, $arg;
        } else {
            my $asset = App::hopen::Asset->new(target=>$arg, made_by=>$self);
            push @{$self->made}, $asset;
            push @retval, $asset;
        }
    } #foreach arg
    return @retval;
} #make()

=head2 input_assets

Returns the assets provided as input via L</make> calls in predecessor nodes.
Only meaningful within C<_run()> (since that's when C<< $self->scope >>
is populated).  Returns an arrayref in scalar context or a list in list context.

=cut

sub input_assets {
    my $self = shift or croak 'Need an instance';
    my $lrSourceFiles;

    my $hrSourceFiles =
        $self->scope->find(-name => 'made', -set => '*', -levels => 'local') // {};

    if(scalar keys %$hrSourceFiles) {
        $lrSourceFiles = %$hrSourceFiles{(keys %$hrSourceFiles)[0]};
    } else {
        $lrSourceFiles = [];
    }

    return $lrSourceFiles unless wantarray;
    return @$lrSourceFiles;
} #input_assets()

=head2 run

Overrides L<Data::Hopen::G::Runnable/run> to stuff L</made> into the
outputs if it's not already there.  Note that this will B<replace>
any non-arrayref C<made> output.

=cut

around 'run' => sub {
    my $orig = shift;
    my $self = shift or croak 'Need an instance';
    my $retval = $self->$orig(@_);

    $retval->{made} = $self->made unless ref $retval->{made} eq 'ARRAY';
        # TODO clone?  Shallow copy?
    return $retval;
}; #run()

1;
__END__
# vi: set fdm=marker: #
