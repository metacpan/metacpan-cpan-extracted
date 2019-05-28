# App::hopen::Gen::Make::AssetGraphNode - AssetOp for Gen::Make
package App::hopen::Gen::Make::AssetGraphNode;
use Data::Hopen qw(getparameters $VERBOSE);
use Data::Hopen::Base;

our $VERSION = '0.000010';

use parent 'App::hopen::G::AssetOp';
use Class::Tiny;

use App::hopen::BuildSystemGlobals;     # for $DestDir
use Quote::Code;
use String::Print;

# Docs {{{1

=head1 NAME

App::hopen::Gen::Make::AssetGraphNode - AssetOp for Gen::Make

=head1 SYNOPSIS

TODO

=head1 FUNCTIONS

=cut

# }}}1

use vars::i '&OUTPUT' => sub { '__R_Makefile' };

=head2 _run

Generate a piece of a Makefile and write it to the filehandle in
C<__R_Makefile>.

=cut

sub _run {
    my ($self, %args) = getparameters('self', [qw(; phase visitor)], @_);
    my $fh = $self->scope->find(OUTPUT);
        # TODO deal with multiple inputs being merged in DAG::_run()

    my @inputs = $self->input_assets;
    my $output = $self->asset->target->path_wrt($DestDir);
        # TODO refactor this processing into a utility module/function

    # Debugging output
    if($VERBOSE) {
        print $fh qc'\n# Makefile piece from node {$self->name}\n';
        print $fh qc'    # {$self->how//"<nothing to be done>"}\n';
        print $fh qc'    # Depends on {$_->target}\n' foreach @inputs;
    }

    if($self->how) {
        my @paths = map { $_->target->path_wrt($DestDir) } @inputs;
        my $recipe = $self->how;
        # TODO refactor this processing into a utility module/function
        $recipe =~ s<#first\b><$paths[0] // ''>ge;      # first input
        $recipe =~ s<#all\b><join(' ', @paths)>ge;      # all inputs
        $recipe =~ s<#out\b><$output // ''>ge;
        print $fh qc_to <<"EOT"
#{$output}: #{join(" ", @paths)}
\t#{$recipe}
EOT

    }

    $self->make($self->asset);
    return {};
} #_run()

1;
__END__
# vi: set fdm=marker: #
