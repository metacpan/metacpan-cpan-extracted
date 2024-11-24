# App::hopen::Gen::Ninja::AssetGraphNode - AssetOp for Gen::Ninja
package App::hopen::Gen::Ninja::AssetGraphNode;
use Data::Hopen qw(getparameters *VERBOSE);
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000015'; # TRIAL

use parent 'App::hopen::G::AssetOp';
use Class::Tiny {
    _rules => sub { +{} },
};

use App::hopen::BuildSystemGlobals;     # for $DestDir
use Quote::Code;
use String::Print;

# Docs {{{1

=head1 NAME

App::hopen::Gen::Ninja::AssetGraphNode - AssetOp for Gen::Ninja

=head1 SYNOPSIS

TODO

=head1 ATTRIBUTES

=head2 _rules

TODO?  Store mapping from command lines to rules?  Don't want to generate
a separate rule for every command if we can help it.

=head1 FUNCTIONS

=cut

# }}}1

use vars::i '&OUTPUT' => sub { '__R_Ninjafile' };

=head2 _run

Generate a piece of a C<build.ninja> file and write it to the filehandle in
C<__R_Ninjafile>.

If the `how` of a node is defined but falsy, it's a goal.
If `how` is defined and truthy, it's a file.

=cut

sub _run {
    state $ruleidx=0;

    my ($self, %args) = getparameters('self', [qw(; phase visitor)], @_);
    my $fh = $self->scope->find(OUTPUT);
        # TODO deal with multiple inputs being merged in DAG::_run()

    my @inputs = $self->input_assets;
    my $output = $self->asset->target;
    $output = $output->path_wrt($DestDir) if eval { $output->DOES('App::hopen::Util::BasedPath') };
        # TODO refactor this processing into a utility module/function

    # Debugging output
    if($VERBOSE) {
        print $fh qc'\n# From node {$self->name}:\n';
        print $fh qc'    # {$self->how//"<nothing to be done>"}\n';
        print $fh qc'    # Depends on {$_->target}\n' foreach @inputs;
    }

    if(defined $self->how) {
        my @paths = map { $_->target->path_wrt($DestDir) } @inputs;
        my $recipe = $self->how;
        # TODO refactor this processing into a utility module/function
        warn "I don't yet support #first very well (in ``$recipe'')" if $recipe =~ /#first/;
        $recipe =~ s<#first\b><\$in>g;  # first input   # TODO FIXME
        $recipe =~ s<#all\b><\$in>g;    # all inputs
        $recipe =~ s<#out\b><\$out>g;

        # Emit the entry.  If the recipe is defined but falsy,
        # this is a goal, so it gets a `phony` and a `default`.

        # TODO FIXME ugly hack: for now, each command gets its own rule.

        if($self->how) {    # File target

            my $rulename = 'rule_' . ++$ruleidx;
            print $fh qc_to <<"EOT"
rule #{$rulename}
    command = #{$recipe}

build #{$output}: #{$rulename} #{join(" ", @paths)}

EOT
        } else {            # Goal target

            print $fh qc_to <<"EOT"
build #{$output}: phony #{join(" ", @paths)}
default #{$output}

EOT
        }

    } #endif defined $self->how

    $self->make($self->asset);
    return {};
} #_run()

1;
__END__
# vi: set fdm=marker: #
