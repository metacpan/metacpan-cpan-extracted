# *Saccharomyces cerevisiae* strains

[TOC levels=1-3]: # " "
- [*Saccharomyces cerevisiae* strains](#saccharomyces-cerevisiae-strains)
- [Prepare sequences](#prepare-sequences)
- [lastz and lav2axt](#lastz-and-lav2axt)
- [lastz and lpcnam](#lastz-and-lpcnam)
- [lastz with partitioned sequences](#lastz-with-partitioned-sequences)


# Prepare sequences

```bash
mkdir -p ~/data/alignment/egaz/download
cd ~/data/alignment/egaz/download

aria2c -x 9 -s 3 -c ftp://ftp.ensembl.org/pub/release-82/fasta/saccharomyces_cerevisiae/dna/Saccharomyces_cerevisiae.R64-1-1.dna_sm.toplevel.fa.gz
aria2c -x 9 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/149/365/GCA_000149365.1_ASM14936v1/GCA_000149365.1_ASM14936v1_genomic.fna.gz

cd ~/data/alignment/egaz

faops filter -N -s  download/Saccharomyces_cerevisiae.R64-1-1.dna_sm.toplevel.fa.gz S288c.fa
faops filter -N -s download/GCA_000149365.1_ASM14936v1_genomic.fna.gz RM11_1a.fa

egaz prepseq S288c.fa -o S288c -v
egaz prepseq RM11_1a.fa -o RM11_1a -v

```

# lastz and lav2axt

```bash
cd ~/data/alignment/egaz

egaz lastz \
    --set set01 --parallel 8 --verbose \
    S288c RM11_1a \
    -o S288cvsRM11_1a_lav2axt

find S288cvsRM11_1a_lav2axt -type f -name "*.lav" |
    parallel --no-run-if-empty --linebuffer -k -j 8 '
        echo >&2 {}
        egaz lav2axt {} -o {}.axt
    '

fasops axt2fas \
    -l 1000 -t S288c -q RM11_1a -s RM11_1a/chr.sizes \
    S288cvsRM11_1a_lav2axt/*.axt -o S288cvsRM11_1a_lav2axt.fas

fasops check S288cvsRM11_1a_lav2axt.fas S288c.fa --name S288c -o stdout | grep -v "OK"
fasops check S288cvsRM11_1a_lav2axt.fas RM11_1a.fa --name RM11_1a -o stdout | grep -v "OK"

fasops covers S288cvsRM11_1a_lav2axt.fas -n S288c -o stdout |
    runlist stat -s S288c/chr.sizes stdin -o S288cvsRM11_1a_lav2axt.csv

```

# lastz and lpcnam

```bash
cd ~/data/alignment/egaz

egaz lastz \
    --set set01 -C 0 --parallel 8 --verbose \
    S288c RM11_1a \
    -o S288cvsRM11_1a_lpcnam

egaz lpcnam \
    --parallel 8 --verbose \
    S288c RM11_1a S288cvsRM11_1a_lpcnam

fasops axt2fas \
    -l 1000 -t S288c -q RM11_1a -s RM11_1a/chr.sizes \
    S288cvsRM11_1a_lpcnam/axtNet/*.net.axt.gz -o S288cvsRM11_1a_lpcnam_axt.fas

fasops check S288cvsRM11_1a_lpcnam_axt.fas S288c.fa --name S288c -o stdout | grep -v "OK"
fasops check S288cvsRM11_1a_lpcnam_axt.fas RM11_1a.fa --name RM11_1a -o stdout | grep -v "OK"

fasops covers S288cvsRM11_1a_lpcnam_axt.fas -n S288c -o stdout |
    runlist stat -s S288c/chr.sizes stdin -o S288cvsRM11_1a_lpcnam_axt.csv

egaz lpcnam \
    --parallel 8 --verbose --syn \
    S288c RM11_1a S288cvsRM11_1a_lpcnam/lav.tar.gz -o S288cvsRM11_1a_lpcnam_syn

fasops maf2fas S288cvsRM11_1a_lpcnam_syn/mafSynNet/*.synNet.maf.gz -o S288cvsRM11_1a_lpcnam_syn.fas

fasops check S288cvsRM11_1a_lpcnam_syn.fas S288c.fa --name S288c -o stdout | grep -v "OK"
fasops check S288cvsRM11_1a_lpcnam_syn.fas RM11_1a.fa --name RM11_1a -o stdout | grep -v "OK"

fasops covers S288cvsRM11_1a_lpcnam_syn.fas -n S288c -o stdout |
    runlist stat -s S288c/chr.sizes stdin -o S288cvsRM11_1a_lpcnam_syn.csv

```

# lastz with partitioned sequences

```bash
cd ~/data/alignment/egaz

find S288c -type f -name "*.fa" |
    parallel --no-run-if-empty --linebuffer -k -j 8 '
        echo >&2 {}
        egaz partition {} --chunk 500000 --overlap 10000
    '

find RM11_1a -type f -name "*.fa" |
    parallel --no-run-if-empty --linebuffer -k -j 8 '
        echo >&2 {}
        egaz partition {} --chunk 500000 --overlap 0
    '

egaz lastz \
    --set set01 -C 0 --parallel 8 --verbose \
    S288c RM11_1a --tp --qp \
    -o S288cvsRM11_1a_partition

egaz lpcnam \
    --parallel 8 --verbose \
    S288c RM11_1a S288cvsRM11_1a_partition

fasops axt2fas \
    -l 1000 -t S288c -q RM11_1a -s RM11_1a/chr.sizes \
    S288cvsRM11_1a_partition/axtNet/*.net.axt.gz -o S288cvsRM11_1a_partition.fas

fasops check S288cvsRM11_1a_partition.fas S288c.fa --name S288c -o stdout | grep -v "OK"
fasops check S288cvsRM11_1a_partition.fas RM11_1a.fa --name RM11_1a -o stdout | grep -v "OK"

fasops covers S288cvsRM11_1a_partition.fas -n S288c -o stdout |
    runlist stat -s S288c/chr.sizes stdin -o S288cvsRM11_1a_partition.csv

```

