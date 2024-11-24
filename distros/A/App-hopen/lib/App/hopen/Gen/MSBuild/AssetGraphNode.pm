# App::hopen::Gen::MSBuild::AssetGraphNode - AssetOp for Gen::MSBuild
package App::hopen::Gen::MSBuild::AssetGraphNode;
use Data::Hopen qw(hlog getparameters *VERBOSE);
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000015'; # TRIAL

use parent 'App::hopen::G::AssetOp';
use Class::Tiny;

use App::hopen::BuildSystemGlobals;     # for $DestDir
use Quote::Code;
use String::Print;

# Docs {{{1

=head1 NAME

App::hopen::Gen::MSBuild::AssetGraphNode - AssetOp for Gen::MSBuild

=head1 SYNOPSIS

TODO

=head1 FUNCTIONS

=cut

# }}}1

use vars::i '*OUTPUT' => eval "\\'__R_MSBuildXML'";

=head2 _run

Add to the XML hashref being built up in C<__R_MSBuildXML>.

If the `how` of a node is defined but falsy, it's a goal.
If `how` is defined and truthy, it's a file.

=cut

sub _run {
    my ($self, %args) = getparameters('self', [qw(; phase visitor)], @_);
    my $lrXML = $self->scope->find($OUTPUT);
        # TODO deal with multiple inputs being merged in DAG::_run()

    my @inputs = $self->input_assets;
    my $output = $self->asset->target;
    $output = $output->path_wrt($DestDir) if eval { $output->DOES('App::hopen::Util::BasedPath') };
        # TODO refactor this processing into a utility module/function

    # Debugging output
    hlog {;
        qc'Project piece from node {$self->name}',
        qc'{$self->how//"<nothing to be done>"}',
        map { qc'Depends on {$_->target}' } @inputs,
    };

    if(defined $self->how && !$self->how) {     # goal = MSBuild <Target>
        hlog { Goal => $output };
        $lrXML = [ Target => { Name => $output },
                    $lrXML ];

    } elsif(defined $self->how) {               # file = MSBuild task
        hlog { File => $output };
        my @paths = map { $_->target->path_wrt($DestDir) } @inputs;
        my $recipe = $self->how;

        # TODO refactor this processing into a utility module/function
        $recipe =~ s<#first\b><$paths[0] // ''>ge;      # first input
        $recipe =~ s<#all\b><join(' ', @paths)>ge;      # all inputs
        $recipe =~ s<#out\b><$output // ''>ge;

        $lrXML = [ TODO => { Name => $output },
                    $lrXML ];
    }

    $self->make($self->asset);
    return {$OUTPUT=>$lrXML};
} #_run()

1;
__END__
# vi: set fdm=marker: #
