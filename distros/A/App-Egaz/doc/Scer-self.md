# Self alignments of *Saccharomyces cerevisiae* S288c

[TOC levels=1-3]: # " "
- [Self alignments of *Saccharomyces cerevisiae* S288c](#self-alignments-of-saccharomyces-cerevisiae-s288c)
- [Prepare sequences](#prepare-sequences)
- [Detailed steps](#detailed-steps)
    - [self alignement](#self-alignement)
    - [blast](#blast)
    - [merge](#merge)
    - [clean](#clean)
- [Template steps](#template-steps)


# Prepare sequences

In [here](Scer.md#prepare-sequences).

Each .fa files in <path/target> should contain only one sequences.

# Detailed steps

## self alignement

```bash
cd ~/data/alignment/egaz

egaz lastz \
    --set set01 -C 0 --parallel 8 --isself --verbose \
    S288c S288c \
    -o S288cvsSelf

egaz lpcnam \
    --parallel 8 --verbose \
    S288c S288c S288cvsSelf

fasops axt2fas \
    -l 1000 -t S288c -q S288c -s S288c/chr.sizes \
    S288cvsSelf/axtNet/*.net.axt.gz -o S288cvsSelf_axt.fas

fasops check S288cvsSelf_axt.fas S288c.fa --name S288c -o stdout | grep -v "OK"

fasops covers S288cvsSelf_axt.fas -n S288c -o stdout |
    runlist stat -s S288c/chr.sizes stdin -o S288cvsSelf_axt.csv

```

## blast

```bash
cd ~/data/alignment/egaz

mkdir -p S288c_proc
mkdir -p S288c_result

cd ~/data/alignment/egaz/S288c_proc

# genome
find ../S288c -type f -name "*.fa" |
    sort |
    xargs cat |
    perl -nl -e "/^>/ or \$_ = uc; print" \
    > genome.fa
faops size genome.fa > chr.sizes

# Get exact copies in the genome
fasops axt2fas ../S288cvsSelf/axtNet/*.axt.gz -l 1000 -s chr.sizes -o stdout > axt.fas
fasops separate axt.fas --nodash -s .sep.fasta

echo "* Target positions"
egaz exactmatch target.sep.fasta genome.fa \
    --length 500 -o replace.target.tsv
fasops replace axt.fas replace.target.tsv -o axt.target.fas

echo "* Query positions"
egaz exactmatch query.sep.fasta genome.fa \
    --length 500 -o replace.query.tsv
fasops replace axt.target.fas replace.query.tsv -o axt.correct.fas

# coverage stats
fasops covers axt.correct.fas -o axt.correct.yml
runlist split axt.correct.yml -s .temp.yml
runlist compare --op union target.temp.yml query.temp.yml -o axt.union.yml
runlist stat --size chr.sizes axt.union.yml -o union.csv

# links by lastz-chain
fasops links axt.correct.fas -o stdout |
    perl -nl -e 's/(target|query)\.//g; print;' \
    > links.lastz.tsv

# remove species names
# remove duplicated sequences
# remove sequences with more than 250 Ns
fasops separate axt.correct.fas --nodash --rc -o stdout |
    perl -nl -e '/^>/ and s/^>(target|query)\./\>/; print;' |
    faops filter -u stdin stdout |
    faops filter -n 250 stdin stdout \
    > axt.gl.fasta

# Get more paralogs
egaz blastn axt.gl.fasta genome.fa -o axt.bg.blast
egaz blastmatch axt.bg.blast -c 0.95 --perchr -o axt.bg.region
faops region -s genome.fa axt.bg.region axt.bg.fasta

cat axt.gl.fasta axt.bg.fasta |
    faops filter -u stdin stdout |
    faops filter -n 250 stdin stdout \
    > axt.all.fasta

# link paralogs
echo "* Link paralogs"
egaz blastn axt.all.fasta axt.all.fasta -o axt.all.blast
egaz blastlink axt.all.blast -c 0.95 -o links.blast.tsv

```

## merge

```bash
cd ~/data/alignment/egaz/S288c_proc

# merge
rangeops sort -o links.sort.tsv \
    links.lastz.tsv links.blast.tsv

rangeops clean   links.sort.tsv         -o links.sort.clean.tsv
rangeops merge   links.sort.clean.tsv   -o links.merge.tsv       -c 0.95 -p 8
rangeops clean   links.sort.clean.tsv   -o links.clean.tsv       -r links.merge.tsv --bundle 500
rangeops connect links.clean.tsv        -o links.connect.tsv     -r 0.9
rangeops filter  links.connect.tsv      -o links.filter.tsv      -r 0.8

# recreate links
rangeops create links.filter.tsv    -o multi.temp.fas       -g genome.fa
fasops   refine multi.temp.fas      -o multi.refine.fas     --msa mafft -p 8 --chop 10
fasops   links  multi.refine.fas    -o stdout \
    | rangeops sort stdin -o links.refine.tsv

fasops   links  multi.refine.fas    -o stdout     --best \
    | rangeops sort stdin -o links.best.tsv
rangeops create links.best.tsv      -o pair.temp.fas    -g genome.fa
fasops   refine pair.temp.fas       -o pair.refine.fas  --msa mafft -p 8

cat links.refine.tsv \
    | perl -nla -F"\t" -e 'print for @F' \
    | runlist cover stdin -o cover.yml

echo "* Stats of links"
echo "key,count" > links.count.csv
for n in 2 3 4 5-50; do
    rangeops filter links.refine.tsv -n ${n} -o stdout \
        > links.copy${n}.tsv

    cat links.copy${n}.tsv \
        | perl -nla -F"\t" -e 'print for @F' \
        | runlist cover stdin -o copy${n}.yml

    wc -l links.copy${n}.tsv \
        | perl -nl -e '
            @fields = grep {/\S+/} split /\s+/;
            next unless @fields == 2;
            next unless $fields[1] =~ /links\.([\w-]+)\.tsv/;
            printf qq{%s,%s\n}, $1, $fields[0];
        ' \
        >> links.count.csv

    rm links.copy${n}.tsv
done

runlist merge copy2.yml copy3.yml copy4.yml copy5-50.yml -o copy.all.yml
runlist stat --size chr.sizes copy.all.yml --mk --all -o links.copy.csv

fasops mergecsv links.copy.csv links.count.csv --concat -o copy.csv

echo "* Coverage figure"
runlist stat --size chr.sizes cover.yml

```

## clean

```bash
cd ~/data/alignment/egaz/S288c_proc

# clean
find . -type f -name "*genome.fa*" | xargs rm
find . -type f -name "*all.fasta*" | xargs rm
find . -type f -name "*.sep.fasta" | xargs rm
find . -type f -name "axt.*" | xargs rm
find . -type f -name "replace.*.tsv" | xargs rm
find . -type f -name "*.temp.yml" | xargs rm
find . -type f -name "*.temp.fas" | xargs rm
find . -type f -name "copy*.yml" | xargs rm

```

# Template steps

```bash
cd ~/data/alignment/egaz

egaz template \
    S288c \
    --self -o selfS288c/ \
    --circos --aligndb --parallel 8 -v

bash selfS288c/1_self.sh
bash selfS288c/3_proc.sh
bash selfS288c/4_circos.sh
bash selfS288c/6_chr_length.sh
bash selfS288c/7_self_aligndb.sh
bash selfS288c/9_pack_up.sh

```

