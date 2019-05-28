# App::hopen::Gen::Make::AssetGraphVisitor - visitor to write goals
package App::hopen::Gen::Make::AssetGraphVisitor;
use Data::Hopen qw(hlog getparameters $VERBOSE);
use Data::Hopen::Base;

our $VERSION = '0.000010';

use parent 'Data::Hopen::Visitor';
use Class::Tiny;

use App::hopen::BuildSystemGlobals;     # for $DestDir
use App::hopen::Gen::Make::AssetGraphNode;     # for $OUTPUT
use Quote::Code;

# Docs {{{1

=head1 NAME

# App::hopen::Gen::Make::AssetGraphVisitor - visitor to write goals

=head1 SYNOPSIS

This is the visitor used when L<App::hopen::Gen::Make> traverses the
asset graph.  Its purpose is to tie the inputs to each goal into that goal.

=head1 FUNCTIONS

=cut

# }}}1

=head2 visit_goal

Write a goal entry to the Makefile being built.
This happens while the asset graph is being run.

=cut

sub visit_goal {
    my ($self, %args) = getparameters('self', [qw(goal node_inputs)], @_);
    my $fh = $args{node_inputs}->find(App::hopen::Gen::Make::AssetGraphNode::OUTPUT);

    # Pull the inputs.  TODO refactor out the code in common with
    # AhG::Cmd::input_assets().
    my $hrInputs =
        $args{node_inputs}->find(-name => 'made',
                                    -set => '*', -levels => 'local') // {};
    die 'No input files to goal ' . $args{goal}->name
        unless scalar keys %$hrInputs;

    my $lrInputs = %$hrInputs{(keys %$hrInputs)[0]};
    hlog { __PACKAGE__, 'found inputs to goal', $args{goal}->name, Dumper($lrInputs) } 2;

    my @paths = map { $_->target->path_wrt($DestDir) } @$lrInputs;
    print $fh qc'\n# === Makefile goal {$args{goal}->name}\n' if $VERBOSE;
    print $fh qc'{$args{goal}->name}: ';
    say $fh join ' ', @paths;
} #visit_goal()

=head2 visit_node

No-op.

=cut

sub visit_node { }

1;
__END__
# vi: set fdm=marker: #
