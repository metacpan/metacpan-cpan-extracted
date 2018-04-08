package App::Egaz::Command::plottree;
use strict;
use warnings;
use autodie;

use App::Egaz -command;
use App::Egaz::Common;

sub abstract {
    return 'use the ape package to draw newick trees';
}

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename", ],
        [ "device=s",  "png or pdf", { default => "pdf" }, ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "egaz plottree [options] <infile>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* <infile> should be a newick file (*.nwk)
* --outfile can't be stdout
* The R package `ape` is needed
* .travis.yml contains the installation guide

MARKDOWN

    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} != 1 ) {
        my $message = "This command need one input file.\n\tIt found";
        $message .= sprintf " [%s]", $_ for @{$args};
        $message .= ".\n";
        $self->usage_error($message);
    }
    for ( @{$args} ) {
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".$opt->{device}";
    }

}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $R = Statistics::R->new;

    $R->set( 'datafile', $args->[0] );
    $R->set( 'figfile',  $opt->{outfile} );

    $R->run(q{ library(ape) });
    $R->run(
        q{
        plot_tree <- function(tree) {
            barlen <- min(median(tree$edge.length), 0.1)
            if (barlen < 0.1)
                barlen <- 0.01
            tree <- ladderize(tree)
            plot.phylo(
                tree,
                cex = 0.8,
                font = 1,
                adj = 0,
                xpd = TRUE,
                label.offset = 0.001,
                no.margin = TRUE,
                underscore = TRUE
            )
            nodelabels(
                tree$node.label,
                adj = c(1.3,-0.5),
                frame = "n",
                cex = 0.8,
                font = 3,
                xpd = TRUE
            )
            add.scale.bar(cex = 0.8, lwd = 2, length = barlen)
        }}    # Don't start a new line here
    );
    $R->run(q{ tree <- read.tree(datafile) });

    if ( $opt->{device} eq 'pdf' ) {
        $R->run(q{ pdf(file=figfile) });
    }
    elsif ( $opt->{device} eq 'png' ) {
        $R->run(q{ png(file=figfile) });
    }
    else {
        Carp::croak "Unrecognized device: [$opt->{device}]\n";
    }

    $R->run(q{ plot_tree(tree) });
    $R->run(q{ dev.off() });

}

1;
