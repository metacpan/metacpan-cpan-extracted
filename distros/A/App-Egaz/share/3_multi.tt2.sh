[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

if [ -e Results/[% opt.multiname %].nwk ]; then
    log_info Results/[% opt.multiname %].nwk exists
    exit;
fi

[% IF opt.fasttree -%]
if [ -s Results/[% opt.multiname %].ft.nwk ]; then
    log_info Results/[% opt.multiname %].ft.nwk exists
    exit;
fi
[% ELSE -%]
if [ -s Results/[% opt.multiname %].raxml.nwk ]; then
    log_info Results/[% opt.multiname %].raxml.nwk exists
    exit;
fi
[% END -%]

if [ -d [% opt.multiname %]_mz ]; then
    rm -fr [% opt.multiname %]_mz;
fi;
mkdir -p [% opt.multiname %]_mz

if [ -d [% opt.multiname %]_fasta ]; then
    rm -fr [% opt.multiname %]_fasta;
fi;
mkdir -p [% opt.multiname %]_fasta

if [ -d [% opt.multiname %]_refined ]; then
    rm -fr [% opt.multiname %]_refined;
fi;
mkdir -p [% opt.multiname %]_refined

mkdir -p Results

#----------------------------#
# mz
#----------------------------#
log_info multiz

[% IF opt.tree -%]
egaz multiz \
[% FOREACH item IN opt.data -%]
[% IF not loop.first -%]
[% t = opt.data.0.name -%]
[% q = item.name -%]
    Pairwise/[% t %]vs[% q %] \
[% END -%]
[% END -%]
    --tree [% opt.tree %] \
    -o [% opt.multiname %]_mz \
    --parallel [% opt.parallel %]

[% ELSIF opt.order %]
egaz multiz \
[% FOREACH item IN opt.data -%]
[% IF not loop.first -%]
[% t = opt.data.0.name -%]
[% q = item.name -%]
    Pairwise/[% t %]vs[% q %] \
[% END -%]
[% END -%]
    --tree fake_tree.nwk \
    -o [% opt.multiname %]_mz \
    --parallel [% opt.parallel %]

[% ELSE %]
egaz multiz \
[% FOREACH item IN opt.data -%]
[% IF not loop.first -%]
[% t = opt.data.0.name -%]
[% q = item.name -%]
    Pairwise/[% t %]vs[% q %] \
[% END -%]
[% END -%]
    --tree $(
        if [ -s Results/[% opt.multiname %].mash.raw.nwk ]; then
            echo Results/[% opt.multiname %].mash.raw.nwk;
        elif [ -s Results/[% opt.multiname %].raxml.raw.nwk ]; then
            echo Results/[% opt.multiname %].raxml.raw.nwk;
        elif [ -s Results/[% opt.multiname %].ft.raw.nwk ]; then
            echo Results/[% opt.multiname %].ft.raw.nwk;
        else
            echo fake_tree.nwk;
        fi
    ) \
    -o [% opt.multiname %]_mz \
    --parallel [% opt.parallel %]

[% END -%]

find [% opt.multiname %]_mz -type f -name "*.maf" |
    parallel --no-run-if-empty -j 2 pigz -p [% opt.parallel2 %] {}

#----------------------------#
# maf2fas
#----------------------------#
log_info Convert maf to fas
find [% opt.multiname %]_mz -name "*.maf" -or -name "*.maf.gz" |
    parallel --no-run-if-empty -j [% opt.parallel %] \
        fasr maf2fas {} -o [% opt.multiname %]_fasta/{/}.fas

#----------------------------#
# refine fasta
#----------------------------#
log_info Refine fas
find [% opt.multiname %]_fasta -name "*.fas" -or -name "*.fas.gz" |
    parallel --no-run-if-empty -j 2 '
        fasr refine \
            --msa [% opt.msa %] --parallel [% opt.parallel2 %] \
            --quick --pad 100 --fill 100 \
[% IF opt.outgroup -%]
            --outgroup \
[% END -%]
            {} \
            -o [% opt.multiname %]_refined/{/}
    '

find [% opt.multiname %]_refined -type f -name "*.fas" |
    parallel --no-run-if-empty -j 2 pigz -p [% opt.parallel2 %] {}

#----------------------------#
# RAxML
#----------------------------#
[% IF opt.data.size > 3 -%]
[% IF opt.fasttree -%]
log_info FastTree

gzip -dcf [% opt.multiname %]_refined/*.fas.gz |
    fasr concat genome.lst stdin |
    FastTree -nt -fastest -noml -boot 100 |
[% IF opt.outgroup -%]
    nw_reroot - [% opt.outgroup %] |
[% END -%]
    nw_order - -c n \
    > Results/[% opt.multiname %].ft.nwk

plotr tree Results/[% opt.multiname %].ft.nwk
[% ELSE -%]
log_info RAxML

egaz raxml \
    --parallel [% IF opt.parallel > 3 %] [% opt.parallel - 1 %] [% ELSE %] 2 [% END %] \
[% IF opt.outgroup -%]
    --outgroup [% opt.outgroup %] \
[% END -%]
[% IF opt.verbose -%]
    -v \
[% END -%]
    [% opt.multiname %]_refined/*.fas.gz \
    -o Results/[% opt.multiname %].nwk.tmp

cat Results/[% opt.multiname %].nwk.tmp |
    nw_order - -c n \
    > Results/[% opt.multiname %].raxml.nwk
rm Results/[% opt.multiname %].nwk.tmp

plotr tree Results/[% opt.multiname %].raxml.nwk
[% END -%]

[% ELSIF opt.data.size == 3 -%]
echo "(([% opt.data.0.name %],[% opt.data.1.name %]),[% opt.data.2.name %]);" > Results/[% opt.multiname %].nwk

[% ELSE -%]
echo "([% opt.data.0.name %],[% opt.data.1.name %]);" > Results/[% opt.multiname %].nwk

[% END -%]

exit;
