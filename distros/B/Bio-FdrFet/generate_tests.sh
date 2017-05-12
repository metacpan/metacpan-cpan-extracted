#!/bin/sh

# run this script to generate test inputs.
# New tests go in newtests

if [[ ! -d newtests ]]
then
    mkdir newtests
fi

if [[ ! -d temp ]]
then
    mkdir temp
fi

cp t/HIV-loci-pval.inp .
cp t/example_pathways.txt .
for universe in genes union intersection
do
    perl -I lib fdr-fet.pl -genelist=HIV-loci-pval.inp -pathway=example_pathways.txt \
         -outdir=temp -universe=$universe  > newtests.log.$universe 2>&1
    mv temp/example_pathways.txt.out newtests/results.pathway.$universe
    mv temp/example_pathways.txt.fdr35.detail.out newtests/results.detail.$universe
done

perl -I lib fdr-fet.pl -genelist=HIV-loci-pval.inp -pathway=example_pathways.txt \
     -outdir=temp -universe=user -genecount=20000  > newtests.log.user 2>&1
mv temp/example_pathways.txt.out newtests/results.pathway.user
mv temp/example_pathways.txt.fdr35.detail.out newtests/results.detail.user

