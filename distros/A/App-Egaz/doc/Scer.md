# *Saccharomyces cerevisiae* strains

- [*Saccharomyces cerevisiae* strains](#saccharomyces-cerevisiae-strains)
    * [Prepare sequences](#prepare-sequences)
    * [Detailed steps](#detailed-steps)
        + [lastz and lav2axt](#lastz-and-lav2axt)
        + [lastz and lpcnam](#lastz-and-lpcnam)
        + [lastz with partitioned sequences](#lastz-with-partitioned-sequences)
    * [Template steps](#template-steps)

## Prepare sequences

* Download

```shell
mkdir -p ~/data/egaz/download
cd ~/data/egaz/download

# S288c (soft-masked) from Ensembl
curl -O http://ftp.ensembl.org/pub/release-105/fasta/saccharomyces_cerevisiae/dna/Saccharomyces_cerevisiae.R64-1-1.dna_sm.toplevel.fa.gz
curl -O http://ftp.ensembl.org/pub/release-105/gff3/saccharomyces_cerevisiae/Saccharomyces_cerevisiae.R64-1-1.105.gff3.gz

# RM11_1a
curl -O https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/149/365/GCA_000149365.1_ASM14936v1/GCA_000149365.1_ASM14936v1_genomic.fna.gz

# YJM789
curl -O https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/181/435/GCA_000181435.1_ASM18143v1/GCA_000181435.1_ASM18143v1_genomic.fna.gz

# Saccharomyces paradoxus CBS432
curl -O https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/002/079/055/GCF_002079055.1_ASM207905v1/GCF_002079055.1_ASM207905v1_genomic.fna.gz

# Saccharomyces pastorianus CBS 1483
curl -O https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/011/022/315/GCA_011022315.1_ASM1102231v1/GCA_011022315.1_ASM1102231v1_genomic.fna.gz

# Saccharomyces eubayanus FM1318
curl -O https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/001/298/625/GCF_001298625.1_SEUB3.0/GCF_001298625.1_SEUB3.0_genomic.fna.gz

find . -name "*.gz" | xargs gzip -t

```

* prepare

```shell
cd ~/data/egaz

# for `fasr check`
faops filter -N -s download/Saccharomyces_cerevisiae.R64-1-1.dna_sm.toplevel.fa.gz S288c.fa
egaz prepseq S288c.fa -o S288c -v

gzip -dcf download/Saccharomyces_cerevisiae.R64-1-1.105.gff3.gz > S288c/chr.gff
spanr gff --tag CDS S288c/chr.gff -o S288c/cds.json
faops masked S288c/*.fa | spanr cover stdin -o S288c/repeat.json
spanr merge S288c/repeat.json S288c/cds.json -o S288c/anno.json

faops filter -N -s download/GCA_000149365*.fna.gz RM11_1a.fa
egaz prepseq \
    RM11_1a.fa -o RM11_1a \
    --repeatmasker '--species Fungi --parallel 6' -v

egaz prepseq \
    download/GCA_000181435*.fna.gz -o YJM789 \
    --about 2000000 --min 1000 --repeatmasker '--species Fungi --parallel 6' -v

egaz prepseq \
    download/GCF_002079055*.fna.gz -o Spar \
    --repeatmasker '--species Fungi --parallel 6' -v

egaz prepseq \
    download/GCA_011022315*.fna.gz -o Spas \
    --about 2000000 --min 1000 --repeatmasker '--species Fungi --parallel 6' -v

egaz prepseq \
    download/GCF_001298625*.fna.gz -o Seub \
    --about 2000000 --min 1000 --repeatmasker '--species Fungi --parallel 6' -v

```

## Detailed steps

### lastz and lav2axt

```shell script
cd ~/data/egaz

egaz lastz \
    --set set01 --parallel 6 --verbose \
    S288c RM11_1a \
    -o S288cvsRM11_1a_lav2axt

find S288cvsRM11_1a_lav2axt -type f -name "*.lav" |
    parallel --no-run-if-empty --linebuffer -k -j 6 '
        >&2 echo {}
        egaz lav2axt {} -o {}.axt
    '

fasr axt2fas --tname S288c --qname RM11_1a \
    RM11_1a/chr.sizes S288cvsRM11_1a_lav2axt/*.axt |
    fasr filter --ge 1000 stdin -o S288cvsRM11_1a_lav2axt.fas

fasr check --name S288c S288c.fa S288cvsRM11_1a_lav2axt.fas | grep -v "OK"
fasr check --name RM11_1a RM11_1a.fa S288cvsRM11_1a_lav2axt.fas | grep -v "OK"

```

### lastz and lpcnam

```shell script
cd ~/data/egaz

egaz lastz \
    --set set01 -C 0 --parallel 6 --verbose \
    S288c RM11_1a \
    -o S288cvsRM11_1a_lpcnam

# UCSC's pipeline
egaz lpcnam \
    --parallel 6 --verbose \
    S288c RM11_1a S288cvsRM11_1a_lpcnam

fasr axt2fas --tname S288c --qname RM11_1a \
    RM11_1a/chr.sizes S288cvsRM11_1a_lpcnam/axtNet/*.net.axt.gz |
    fasr filter --ge 1000 stdin -o S288cvsRM11_1a_lpcnam_axt.fas

fasr check --name S288c S288c.fa S288cvsRM11_1a_lpcnam_axt.fas | grep -v "OK"
fasr check --name RM11_1a RM11_1a.fa S288cvsRM11_1a_lpcnam_axt.fas | grep -v "OK"

# UCSC's syntenic pipeline
egaz lpcnam \
    --parallel 8 --verbose --syn \
    S288c RM11_1a S288cvsRM11_1a_lpcnam/lav.tar.gz -o S288cvsRM11_1a_lpcnam_syn

fasr maf2fas S288cvsRM11_1a_lpcnam_syn/mafSynNet/*.synNet.maf.gz |
    fasr filter --ge 1000 stdin -o S288cvsRM11_1a_lpcnam_syn.fas

fasr check --name S288c S288c.fa S288cvsRM11_1a_lpcnam_syn.fas | grep -v "OK"
fasr check --name RM11_1a RM11_1a.fa S288cvsRM11_1a_lpcnam_syn.fas | grep -v "OK"

```

### lastz with partitioned sequences

```shell script
cd ~/data/egaz

find S288c -type f -name "*.fa" |
    parallel --no-run-if-empty --linebuffer -k -j 6 '
        >&2 echo {}
        egaz partition {} --chunk 500000 --overlap 10000
    '

egaz lastz \
    --set set01 -C 0 --parallel 6 --verbose \
    S288c RM11_1a --tp \
    -o S288cvsRM11_1a_partition

egaz lpcnam \
    --parallel 6 --verbose \
    S288c RM11_1a S288cvsRM11_1a_partition

fasr axt2fas --tname S288c --qname RM11_1a \
    RM11_1a/chr.sizes S288cvsRM11_1a_partition/axtNet/*.net.axt.gz |
    fasr filter --ge 1000 stdin -o S288cvsRM11_1a_partition.fas

fasr check --name S288c S288c.fa S288cvsRM11_1a_partition.fas | grep -v "OK"
fasr check --name RM11_1a RM11_1a.fa S288cvsRM11_1a_partition.fas | grep -v "OK"

```

### Comparison

```shell
cd ~/data/egaz

ARRAY=(
    S288cvsRM11_1a_lav2axt.fas
    S288cvsRM11_1a_lpcnam_axt.fas
    S288cvsRM11_1a_lpcnam_syn.fas
    S288cvsRM11_1a_partition.fas
)

# N50
for F in ${ARRAY[@]}; do
    fasr subset <(echo S288c) ${F} --required `# Only keeps S288c` |
        faops filter -d stdin stdout `# removes dashes` |
        faops n50 -S -C -g 12071326 stdin |
        datamash transpose |
        sed '1d' |
        sed "s/^/${F}\t/"
done |
    (echo -e "#item\tN50\tSum\tCount" && cat) |
    mlr --itsv --omd cat

# depths
for F in ${ARRAY[@]}; do
    fasr subset <(echo S288c) ${F} --required |
        grep '^>S288c.' |
        spanr cover stdin |
        spanr stat --all S288c/chr.sizes stdin |
        sed '1d' |
        tr ',' '\t' |
        sed "s/^/${F}\t/"

    # single copy
    fasr subset <(echo S288c) ${F} --required |
        grep '^>S288c.' |
        spanr coverage -d stdin `# detailed depths` |
        jq '."1"' `# depth 1` |
        spanr stat --all S288c/chr.sizes stdin |
        sed '1d' |
        tr ',' '\t' |
        sed "s/^/${F}\t/"
done |
    (echo -e "#item\tchrLength\tsize\tcoverage" && cat) |
    mlr --itsv --omd cat

fasr subset <(echo S288c) S288cvsRM11_1a_lpcnam_axt.fas --required |
    grep '^>S288c.' |
    spanr coverage -d stdin


```

| #item                         | N50   | Sum      | Count |
|-------------------------------|-------|----------|-------|
| S288cvsRM11_1a_lav2axt.fas    | 84580 | 12603461 | 821   |
| S288cvsRM11_1a_lpcnam_axt.fas | 81344 | 11578920 | 307   |
| S288cvsRM11_1a_lpcnam_syn.fas | 83326 | 11455734 | 257   |
| S288cvsRM11_1a_partition.fas  | 77565 | 11579491 | 327   |

| #item                         | chrLength | size     | coverage |
|-------------------------------|-----------|----------|----------|
| S288cvsRM11_1a_lav2axt.fas    | 12071326  | 11627698 | 0.9632   |
| S288cvsRM11_1a_lav2axt.fas    | 12071326  | 11038024 | 0.9144   |
| S288cvsRM11_1a_lpcnam_axt.fas | 12071326  | 11578920 | 0.9592   |
| S288cvsRM11_1a_lpcnam_axt.fas | 12071326  | 11578920 | 0.9592   |
| S288cvsRM11_1a_lpcnam_syn.fas | 12071326  | 11455734 | 0.9490   |
| S288cvsRM11_1a_lpcnam_syn.fas | 12071326  | 11455734 | 0.9490   |
| S288cvsRM11_1a_partition.fas  | 12071326  | 11579491 | 0.9593   |
| S288cvsRM11_1a_partition.fas  | 12071326  | 11579491 | 0.9593   |

### A quick dotplot

```shell
cd ~/data/egaz

brew install wang-q/tap/wfmash
cargo install --git https://github.com/ekg/pafplot --branch main

wfmash S288c/chr.fasta RM11_1a/chr.fasta > aln.paf
paf2dotplot png medium aln.paf

pafplot aln.paf

```

## Template steps

```shell script
cd ~/data/egaz

egaz template \
    S288c RM11_1a YJM789 Spar Spas Seub \
    --multi -o multi6/ \
    --mash --fasttree --parallel 6 -v

bash multi6/1_pair.sh
bash multi6/2_mash.sh
bash multi6/3_multi.sh

egaz template \
    S288c RM11_1a YJM789 Spar \
    --multi -o multi6/ \
    --multiname multi4 --tree multi6/Results/multi6.ft.nwk \
    --outgroup Spar \
    --vcf \
    --fasttree --parallel 6 -v

bash multi6/3_multi.sh
bash multi6/4_vcf.sh
bash multi6/9_pack_up.sh

```

