[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

mkdir -p mash
cd mash

log_info mash sketch
[% FOREACH item IN opt.data -%]
if [[ ! -e [% item.name %].msh ]]; then
    cat [% item.dir %]/chr.fasta |
        mash sketch -k 21 -s 100000 -p [% opt.parallel %] - -I "[% item.name %]" -o [% item.name %]
fi

[% END -%]

log_info mash triangle
mash triangle -E -p [% opt.parallel %] -l <(
    cat ../genome.lst | parallel echo "{}.msh"
    ) \
    > dist.tsv

log_info fill matrix with lower triangle
tsv-select -f 1-3 dist.tsv |
    (tsv-select -f 2,1,3 dist.tsv && cat) |
    (
        cut -f 1 dist.tsv |
            tsv-uniq |
            parallel -j 1 --keep-order 'echo -e "{}\t{}\t0"' &&
        cat
    ) \
    > dist_full.tsv

log_info Raw phylogenetic tree by MinHash
cat dist_full.tsv |
    Rscript -e '
        library(readr);
        library(tidyr);
        library(ape);
        pair_dist <- read_tsv(file("stdin"), col_names=F, show_col_types = FALSE);
        tmp <- pair_dist %>%
            pivot_wider( names_from = X2, values_from = X3, values_fill = list(X3 = 1.0) )
        tmp <- as.matrix(tmp)
        mat <- tmp[,-1]
        rownames(mat) <- tmp[,1]

        dist_mat <- as.dist(mat)
        clusters <- hclust(dist_mat, method = "ward.D2")
        tree <- as.phylo(clusters)
        write.tree(phy=tree, file="tree.nwk")

        group <- cutree(clusters, h=0.4) # k=5
        groups <- as.data.frame(group)
        groups$ids <- rownames(groups)
        rownames(groups) <- NULL
        groups <- groups[order(groups$group), ]
        write_tsv(groups, "groups.tsv")
    '

log_info newick-utils
cat tree.nwk |
[% IF opt.outgroup -%]
    nw_reroot - [% opt.outgroup %] |
[% END -%]
    nw_order - -c n \
    > ../Results/[% opt.multiname %].mash.raw.nwk

plotr tree ../Results/[% opt.multiname %].mash.raw.nwk
