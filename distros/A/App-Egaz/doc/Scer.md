# *Saccharomyces cerevisiae* strains

[TOC levels=1-3]: # ""

- [*Saccharomyces cerevisiae* strains](#saccharomyces-cerevisiae-strains)
- [Prepare sequences](#prepare-sequences)
- [Detailed/alternative steps](#detailedalternative-steps)
  - [lastz and lav2axt](#lastz-and-lav2axt)
  - [lastz and lpcnam](#lastz-and-lpcnam)
  - [lastz with partitioned sequences](#lastz-with-partitioned-sequences)
- [Template steps](#template-steps)


# Prepare sequences

```bash
mkdir -p ~/data/alignment/egaz/download
cd ~/data/alignment/egaz/download

# S288c (soft-masked) from Ensembl
aria2c -x 6 -s 3 -c ftp://ftp.ensembl.org/pub/release-82/fasta/saccharomyces_cerevisiae/dna/Saccharomyces_cerevisiae.R64-1-1.dna_sm.toplevel.fa.gz

aria2c -x 6 -s 3 -c ftp://ftp.ensembl.org/pub/release-82/gff3/saccharomyces_cerevisiae/Saccharomyces_cerevisiae.R64-1-1.82.gff3.gz

# RM11_1a from NCBI assembly
aria2c -x 6 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/149/365/GCA_000149365.1_ASM14936v1/GCA_000149365.1_ASM14936v1_genomic.fna.gz

# YJM789 from NCBI WGS
aria2c -x 6 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/sra/wgs_aux/AA/FW/AAFW02/AAFW02.1.fsa_nt.gz

# Saccharomyces paradoxus NRRL Y-17217
aria2c -x 6 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/sra/wgs_aux/AA/BY/AABY01/AABY01.1.fsa_nt.gz

# Saccharomyces pastorianus CBS 1513
aria2c -x 6 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/sra/wgs_aux/AZ/CJ/AZCJ01/AZCJ01.1.fsa_nt.gz

# Saccharomyces eubayanus FM1318
# WGS >gi|918735454|gb|JMCK01000001
aria2c -x 6 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/sra/wgs_aux/JM/CK/JMCK01/JMCK01.1.fsa_nt.gz

find . -name "*.gz" | xargs gzip -t

cd ~/data/alignment/egaz

# for `fasops check`
faops filter -N -s download/Saccharomyces_cerevisiae.R64-1-1.dna_sm.toplevel.fa.gz S288c.fa
faops filter -N -s download/GCA_000149365.1_ASM14936v1_genomic.fna.gz RM11_1a.fa

egaz prepseq S288c.fa -o S288c -v

gzip -d -c download/Saccharomyces_cerevisiae.R64-1-1.82.gff3.gz > S288c/chr.gff
egaz masked S288c/*.fa -o S288c/repeat.yml

egaz prepseq \
    RM11_1a.fa -o RM11_1a \
    --repeatmasker '--species Fungi --parallel 8' -v

egaz prepseq \
    download/AAFW02.1.fsa_nt.gz -o YJM789 \
    --about 2000000 --repeatmasker '--species Fungi --parallel 8' --min 1000 -v

egaz prepseq \
    download/AABY01.1.fsa_nt.gz -o Spar \
    --about 2000000 --repeatmasker '--species Fungi --parallel 8' --min 1000 -v

egaz prepseq \
    download/AZCJ01.1.fsa_nt.gz -o Spas \
    --about 2000000 --repeatmasker '--species Fungi --parallel 8' --min 1000 -v

egaz prepseq \
    download/JMCK01.1.fsa_nt.gz -o Seub \
    --about 2000000 --repeatmasker '--species Fungi --parallel 8' --min 1000 --gi -v

```

# Detailed/alternative steps

## lastz and lav2axt

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
    spanr stat S288c/chr.sizes stdin -o S288cvsRM11_1a_lav2axt.csv

```

## lastz and lpcnam

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
    spanr stat S288c/chr.sizes stdin -o S288cvsRM11_1a_lpcnam_axt.csv

egaz lpcnam \
    --parallel 8 --verbose --syn \
    S288c RM11_1a S288cvsRM11_1a_lpcnam/lav.tar.gz -o S288cvsRM11_1a_lpcnam_syn

fasops maf2fas S288cvsRM11_1a_lpcnam_syn/mafSynNet/*.synNet.maf.gz -o S288cvsRM11_1a_lpcnam_syn.fas

fasops check S288cvsRM11_1a_lpcnam_syn.fas S288c.fa --name S288c -o stdout | grep -v "OK"
fasops check S288cvsRM11_1a_lpcnam_syn.fas RM11_1a.fa --name RM11_1a -o stdout | grep -v "OK"

fasops covers S288cvsRM11_1a_lpcnam_syn.fas -n S288c -o stdout |
    spanr stat S288c/chr.sizes stdin -o S288cvsRM11_1a_lpcnam_syn.csv

```

## lastz with partitioned sequences

```bash
cd ~/data/alignment/egaz

find S288c -type f -name "*.fa" |
    parallel --no-run-if-empty --linebuffer -k -j 8 '
        echo >&2 {}
        egaz partition {} --chunk 500000 --overlap 10000
    '

egaz lastz \
    --set set01 -C 0 --parallel 8 --verbose \
    S288c RM11_1a --tp \
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
    spanr stat S288c/chr.sizes stdin -o S288cvsRM11_1a_partition.csv

```

# Template steps

```bash
cd ~/data/alignment/egaz

egaz template \
    S288c RM11_1a YJM789 Spar Spas Seub \
    --multi -o multi6/ \
    --rawphylo --order --parallel 8 -v

bash multi6/1_pair.sh
bash multi6/2_rawphylo.sh
bash multi6/3_multi.sh

egaz template \
    S288c RM11_1a YJM789 Spar \
    --multi -o multi6/ \
    --multiname multi4 --tree multi6/Results/multi6.nwk --outgroup Spar \
    --vcf --aligndb \
    --parallel 8 -v

bash multi6/3_multi.sh
bash multi6/4_vcf.sh
bash multi6/6_chr_length.sh
bash multi6/7_multi_aligndb.sh
bash multi6/9_pack_up.sh

```

