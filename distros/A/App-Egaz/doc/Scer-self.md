# Self alignments of *Saccharomyces cerevisiae* S288c

[TOC levels=1-3]: # ""

- [Self alignments of *Saccharomyces cerevisiae* S288c](#self-alignments-of-saccharomyces-cerevisiae-s288c)
- [Prepare sequences](#prepare-sequences)
- [Detailed steps](#detailed-steps)
  - [self alignment](#self-alignment)
  - [blast](#blast)
  - [merge](#merge)
  - [clean](#clean)
- [Template steps](#template-steps)


# Prepare sequences

In [here](Scer.md#prepare-sequences).

Each .fa files in <path/target> should contain only one sequences.

# Detailed steps

## self alignment

```bash
cd ~/data/egaz

egaz lastz \
    --set set01 -C 0 --parallel 8 --isself --verbose \
    S288c S288c \
    -o S288cvsSelf

egaz lpcnam \
    --parallel 8 --verbose \
    S288c S288c S288cvsSelf

fasr axt2fas --tname S288c --qname S288c \
    S288c/chr.sizes S288cvsSelf/axtNet/*.net.axt.gz |
    fasr filter --ge 1000 stdin -o S288cvsSelf_axt.fas

fasr check --name S288c S288c.fa S288cvsSelf_axt.fas | grep -v "OK"

fasr cover --name S288c S288cvsSelf_axt.fas |
    spanr stat S288c/chr.sizes stdin -o S288cvsSelf_axt.csv

cat S288cvsSelf_axt.fas |
    grep "^>S288c." |
    rgr prop S288c/repeat.json stdin |
    tsv-summarize --quantile "2:0.1,0.5,0.9"
#0       0.0053  0.2281

```

## minimap2

```shell
cd ~/data/egaz

# https://github.com/lh3/minimap2/blob/master/cookbook.md#constructing-self-homology-map
minimap2 -DP -k19 -w19 -m200 S288c/chr.fasta S288c/chr.fasta > mm.paf

# https://github.com/lh3/miniasm/blob/master/PAF.md
# 10	int	Number of residue matches
cat mm.paf |
    tsv-filter --ge "10:1000" |
    tsv-sort -k1,1 -k6,6 -k3,3n -k8,8n \
    > mm.length.paf

# convert to rg
cat mm.length.paf |
     perl -nla -e '
        my $f_id = $F[0];
        my $f_begin = $F[2] + 1;
        my $f_end = $F[3];

        my $g_id = $F[5];
        my $g_begin = $F[7] + 1;
        my $g_end = $F[8];

        print "$f_id:$f_begin-$f_end";
        print "$g_id:$g_begin-$g_end";
    ' |
    tsv-uniq |
    rgr sort stdin \
    > mm.rg

# remove repeats
rgr prop S288c/repeat.json mm.rg |
    tsv-filter --le "2:0.3" |
    tsv-select -f 1 \
    > mm.filter.rg

faops region S288c/chr.fasta mm.filter.rg mm.gl.fasta

# stats
spanr cover mm.rg |
    spanr stat S288c/chr.sizes stdin --all

spanr cover mm.filter.rg |
    spanr stat S288c/chr.sizes stdin --all

spanr stat S288c/chr.sizes S288c/repeat.json --all

# draw the dotplot
cat mm.length.paf |
    tsv-select -f 1-12 |
    rgr field stdin --chr 1 --start 3 --end 4 -a |
    rgr runlist --op overlap -f 13 \
        <(spanr cover mm.filter.rg) \
        stdin |
    tsv-select -f 1-12 \
    > mm.filter.paf

paf2dotplot png medium mm.filter.paf

```

## `wfmash -X`

```shell
cd ~/data/egaz

wfmash -X -p 70 S288c/chr.fasta S288c/chr.fasta > self.paf

paf2dotplot png medium self.paf

```

## blast

```bash
cd ~/data/egaz

mkdir -p S288c_proc
mkdir -p S288c_result

cd ~/data/egaz/S288c_proc

# Get exact copies in the genome
fasr axt2fas \
    ../S288c/chr.sizes ../S288cvsSelf/axtNet/*.net.axt.gz |
    fasr filter --ge 1000 stdin -o axt.fas

# links by lastz-chain
fasr link axt.fas |
    perl -nl -e 's/(target|query)\.//g; print;' \
    > links.lastz.tsv

# remove species names
# remove duplicated sequences
# remove sequences with more than 250 Ns
fasr separate axt.fas --rc |
    perl -nl -e '/^>/ and s/^>(target|query)\./\>/; print;' |
    faops filter -u -d stdin stdout |
    faops filter -n 250 stdin stdout \
    > axt.gl.fasta

# Get more paralogs
egaz blastn axt.gl.fasta genome.fa -o axt.bg.blast
egaz blastmatch axt.bg.blast -c 0.95 -o axt.bg.region
samtools faidx genome.fa -r axt.bg.region --continue |
    perl -p -e '/^>/ and s/:/(+):/' \
    > axt.bg.fasta

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
cd ~/data/egaz/S288c_proc

# merge
linkr sort -o links.sort.tsv \
    links.lastz.tsv links.blast.tsv

linkr clean   links.sort.tsv       -o links.sort.clean.tsv
rgr   merge   links.sort.clean.tsv -o links.merge.tsv       -c 0.95
linkr clean   links.sort.clean.tsv -o links.clean.tsv       -r links.merge.tsv --bundle 500
linkr connect links.clean.tsv      -o links.connect.tsv     -r 0.9
linkr filter  links.connect.tsv    -o links.filter.tsv      -r 0.8

# recreate links
fasr create genome.fa links.filter.tsv -o multi.temp.fas
#fasr check genome.fa multi.temp.fas | grep -v "OK"

fasr refine multi.temp.fas -o multi.refine.fas --msa mafft -p 8 --chop 10
#fasr check genome.fa multi.refine.fas | grep -v "OK"

fasr link multi.refine.fas |
    linkr sort stdin -o links.refine.tsv

fasr link multi.refine.fas --best |
    linkr sort stdin -o links.best.tsv
fasr create genome.fa links.best.tsv -o pair.temp.fas
fasr refine pair.temp.fas -o pair.refine.fas  --msa mafft -p 8

cat links.refine.tsv |
    perl -nla -F"\t" -e 'print for @F' |
    spanr cover stdin -o cover.json

echo "* Stats of links"
echo "key,count" > links.count.csv
for n in 2 3 4-50; do
    linkr filter links.refine.tsv -n ${n} -o stdout \
        > links.copy${n}.tsv

    cat links.copy${n}.tsv |
        perl -nla -F"\t" -e 'print for @F' |
        spanr cover stdin -o copy${n}.json

    wc -l links.copy${n}.tsv |
        perl -nl -e '
            @fields = grep {/\S+/} split /\s+/;
            next unless @fields == 2;
            next unless $fields[1] =~ /links\.([\w-]+)\.tsv/;
            printf qq{%s,%s\n}, $1, $fields[0];
        ' \
        >> links.count.csv

    rm links.copy${n}.tsv
done

spanr merge copy2.json copy3.json copy4-50.json -o copy.all.json
spanr stat chr.sizes copy.all.json --all -o links.copy.csv

fasops mergecsv links.copy.csv links.count.csv --concat -o copy.csv

echo "* Coverage figure"
spanr stat chr.sizes cover.json -o cover.json.csv

```

## clean

```bash
cd ~/data/egaz/S288c_proc

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
cd ~/data/egaz

egaz template \
    S288c \
    --self -o selfS288c/ \
    --circos --parallel 8 -v

bash selfS288c/1_self.sh
bash selfS288c/3_proc.sh
bash selfS288c/4_circos.sh
bash selfS288c/9_pack_up.sh

```

