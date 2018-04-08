#!/usr/bin/env Rscript
library(getopt)
library(ape)

spec = matrix(
    c(
        "help",
        "h",
        0,
        "logical",
        "brief help message",

        "infile",
        "i",
        1,
        "character",
        "input filename",

        "outfile",
        "o",
        1,
        "character",
        "output filename"
    ),
    byrow = TRUE,
    ncol = 5
)
opt = getopt(spec)

if (!is.null(opt$help)) {
    cat(getopt(spec, usage = TRUE))

    q(status = 1)
}

if (is.null(opt$infile)) {
    cat("--infile is need\n")
    cat(getopt(spec, usage = TRUE))

    q(status = 1)
}

if (is.null(opt$outfile)) {
    opt$outfile = paste(opt$infile, ".pdf", sep = "")
}

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
}

pdf(file = opt$outfile)
tree <- read.tree(opt$infile)
plot_tree(tree)
dev.off()
