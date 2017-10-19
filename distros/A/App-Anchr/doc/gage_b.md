# Assemble four genomes from GAGE-B data sets by ANCHR

[TOC levels=1-3]: # " "
- [Assemble four genomes from GAGE-B data sets by ANCHR](#assemble-four-genomes-from-gage-b-data-sets-by-anchr)
- [*Bacillus cereus* ATCC 10987](#bacillus-cereus-atcc-10987)
    - [Bcer: download](#bcer-download)
    - [Bcer: combinations of different quality values and read lengths](#bcer-combinations-of-different-quality-values-and-read-lengths)
    - [Bcer: quorum](#bcer-quorum)
    - [Bcer: k-unitigs and anchors](#bcer-k-unitigs-and-anchors)
    - [Bcer: merge anchors](#bcer-merge-anchors)
- [*Rhodobacter sphaeroides* 2.4.1](#rhodobacter-sphaeroides-241)
    - [Rsph: download](#rsph-download)
    - [Rsph: combinations of different quality values and read lengths](#rsph-combinations-of-different-quality-values-and-read-lengths)
    - [Rsph: quorum](#rsph-quorum)
    - [Rsph: k-unitigs and anchors](#rsph-k-unitigs-and-anchors)
    - [Rsph: merge anchors](#rsph-merge-anchors)
- [*Mycobacterium abscessus* 6G-0125-R](#mycobacterium-abscessus-6g-0125-r)
    - [Mabs: download](#mabs-download)
    - [Mabs: combinations of different quality values and read lengths](#mabs-combinations-of-different-quality-values-and-read-lengths)
    - [Mabs: quorum](#mabs-quorum)
    - [Mabs: k-unitigs and anchors](#mabs-k-unitigs-and-anchors)
    - [Mabs: merge anchors](#mabs-merge-anchors)
- [*Vibrio cholerae* CP1032(5)](#vibrio-cholerae-cp10325)
    - [Vcho: download](#vcho-download)
    - [Vcho: combinations of different quality values and read lengths](#vcho-combinations-of-different-quality-values-and-read-lengths)
    - [Vcho: quorum](#vcho-quorum)
    - [Vcho: generate k-unitigs](#vcho-generate-k-unitigs)
    - [Vcho: create anchors](#vcho-create-anchors)
    - [Vcho: results](#vcho-results)
    - [Vcho: merge anchors](#vcho-merge-anchors)
- [*Mycobacterium abscessus* 6G-0125-R Full](#mycobacterium-abscessus-6g-0125-r-full)
    - [MabsF: download](#mabsf-download)
    - [MabsF: combinations of different quality values and read lengths](#mabsf-combinations-of-different-quality-values-and-read-lengths)
    - [MabsF: quorum](#mabsf-quorum)
    - [MabsF: down sampling](#mabsf-down-sampling)
    - [MabsF: k-unitigs and anchors (sampled)](#mabsf-k-unitigs-and-anchors-sampled)
    - [MabsF: merge anchors](#mabsf-merge-anchors)
- [*Rhodobacter sphaeroides* 2.4.1 Full](#rhodobacter-sphaeroides-241-full)
    - [RsphF: download](#rsphf-download)
    - [RsphF: combinations of different quality values and read lengths](#rsphf-combinations-of-different-quality-values-and-read-lengths)
    - [RsphF: quorum](#rsphf-quorum)
    - [RsphF: down sampling](#rsphf-down-sampling)
    - [RsphF: k-unitigs and anchors (sampled)](#rsphf-k-unitigs-and-anchors-sampled)
    - [RsphF: merge anchors](#rsphf-merge-anchors)
- [*Vibrio cholerae* CP1032(5) Full](#vibrio-cholerae-cp10325-full)
    - [VchoF: download](#vchof-download)
    - [VchoF: combinations of different quality values and read lengths](#vchof-combinations-of-different-quality-values-and-read-lengths)
    - [VchoF: quorum](#vchof-quorum)
    - [VchoF: down sampling](#vchof-down-sampling)
    - [VchoF: k-unitigs and anchors (sampled)](#vchof-k-unitigs-and-anchors-sampled)
    - [VchoF: merge anchors](#vchof-merge-anchors)


# *Bacillus cereus* ATCC 10987

## Bcer: download

* Reference genome

    * Strain: Bacillus cereus ATCC 10987
    * Taxid: [222523](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=222523)
    * RefSeq assembly accession:
      [GCF_000008005.1](ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/008/005/GCF_000008005.1_ASM800v1/GCF_000008005.1_ASM800v1_assembly_report.txt)
    * Proportion of paralogs (> 1000 bp): 0.0797

```bash
BASE_NAME=Bcer
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 1_genome
cd 1_genome

aria2c -x 9 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/008/005/GCF_000008005.1_ASM800v1/GCF_000008005.1_ASM800v1_genomic.fna.gz

TAB=$'\t'
cat <<EOF > replace.tsv
NC_003909.8${TAB}1
NC_005707.1${TAB}pBc10987
EOF

faops replace GCF_000008005.1_ASM800v1_genomic.fna.gz replace.tsv genome.fa

cp ~/data/anchr/paralogs/gage/Results/Bcer/Bcer.multi.fas paralogs.fas

```

* Illumina

    Download from GAGE-B site.

```bash
BASE_NAME=Bcer
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina
cd 2_illumina

aria2c -x 9 -s 3 -c http://ccb.jhu.edu/gage_b/datasets/B_cereus_MiSeq.tar.gz

# NOT gzipped tar
tar xvf B_cereus_MiSeq.tar.gz raw/frag_1__cov100x.fastq
tar xvf B_cereus_MiSeq.tar.gz raw/frag_2__cov100x.fastq

cat raw/frag_1__cov100x.fastq \
    | pigz -p 8 -c \
    > R1.fq.gz
cat raw/frag_2__cov100x.fastq \
    | pigz -p 8 -c \
    > R2.fq.gz

rm -fr raw
```

* GAGE-B assemblies

```bash
BASE_NAME=Bcer
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 8_competitor
cd 8_competitor

aria2c -x 9 -s 3 -c http://ccb.jhu.edu/gage_b/genomeAssemblies/B_cereus_MiSeq.tar.gz

tar xvfz B_cereus_MiSeq.tar.gz abyss_ctg.fasta
tar xvfz B_cereus_MiSeq.tar.gz cabog_ctg.fasta
tar xvfz B_cereus_MiSeq.tar.gz mira_ctg.fasta
tar xvfz B_cereus_MiSeq.tar.gz msrca_ctg.fasta
tar xvfz B_cereus_MiSeq.tar.gz sga_ctg.fasta
tar xvfz B_cereus_MiSeq.tar.gz soap_ctg.fasta
tar xvfz B_cereus_MiSeq.tar.gz spades_ctg.fasta
tar xvfz B_cereus_MiSeq.tar.gz velvet_ctg.fasta

```

* FastQC

```bash
BASE_NAME=Bcer
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/fastqc
cd 2_illumina/fastqc

fastqc -t 16 \
    ../R1.fq.gz ../R2.fq.gz \
    -o .

```

* kmergenie

```bash
BASE_NAME=Bcer
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/kmergenie
cd 2_illumina/kmergenie

kmergenie -l 21 -k 151 -s 10 -t 8 ../R1.fq.gz -o oriR1
kmergenie -l 21 -k 151 -s 10 -t 8 ../R2.fq.gz -o oriR2

```

## Bcer: combinations of different quality values and read lengths

* qual: 25 and 30
* len: 60

```bash
BASE_NAME=Bcer
cd ${HOME}/data/anchr/${BASE_NAME}

if [ ! -e 2_illumina/R1.uniq.fq.gz ]; then
    tally \
        --pair-by-offset --with-quality --nozip --unsorted \
        -i 2_illumina/R1.fq.gz \
        -j 2_illumina/R2.fq.gz \
        -o 2_illumina/R1.uniq.fq \
        -p 2_illumina/R2.uniq.fq
    
    parallel --no-run-if-empty -j 2 "
            pigz -p 4 2_illumina/{}.uniq.fq
        " ::: R1 R2
fi

parallel --no-run-if-empty -j 3 "
    mkdir -p 2_illumina/Q{1}L{2}
    cd 2_illumina/Q{1}L{2}
    
    if [ -e R1.fq.gz ]; then
        echo '    R1.fq.gz already presents'
        exit;
    fi

    anchr trim \
        --noscythe \
        -q {1} -l {2} \
        ../R1.uniq.fq.gz ../R2.uniq.fq.gz \
        -o stdout \
        | bash
    " ::: 25 30 ::: 60

# Stats
printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat.md
printf "|:--|--:|--:|--:|\n" >> stat.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Paralogs"; faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Illumina"; faops n50 -H -S -C 2_illumina/R1.fq.gz 2_illumina/R2.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "uniq";     faops n50 -H -S -C 2_illumina/R1.uniq.fq.gz 2_illumina/R2.uniq.fq.gz;) >> stat.md

parallel -k --no-run-if-empty -j 3 "
    printf \"| %s | %s | %s | %s |\n\" \
        \$( 
            echo Q{1}L{2};
            if [[ {1} -ge '30' ]]; then
                faops n50 -H -S -C \
                    2_illumina/Q{1}L{2}/R1.fq.gz \
                    2_illumina/Q{1}L{2}/R2.fq.gz \
                    2_illumina/Q{1}L{2}/Rs.fq.gz;
            else
                faops n50 -H -S -C \
                    2_illumina/Q{1}L{2}/R1.fq.gz \
                    2_illumina/Q{1}L{2}/R2.fq.gz;
            fi
        )
    " ::: 25 30 ::: 60 \
    >> stat.md

cat stat.md
```

| Name     |     N50 |       Sum |       # |
|:---------|--------:|----------:|--------:|
| Genome   | 5224283 |   5432652 |       2 |
| Paralogs |    2295 |    223889 |     103 |
| Illumina |     251 | 481020311 | 2080000 |
| uniq     |     251 | 480993557 | 2079856 |
| Q25L60   |     250 | 381755768 | 1713804 |
| Q30L60   |     250 | 371873795 | 1752907 |

## Bcer: quorum

```bash
BASE_NAME=Bcer
REAL_G=5432652
cd ${HOME}/data/anchr/${BASE_NAME}

parallel --no-run-if-empty -j 1 "
    cd 2_illumina/Q{1}L{2}
    echo >&2 '==> Group Q{1}L{2} <=='

    if [ ! -e R1.fq.gz ]; then
        echo >&2 '    R1.fq.gz not exists'
        exit;
    fi

    if [ -e pe.cor.fa ]; then
        echo >&2 '    pe.cor.fa exists'
        exit;
    fi

    if [[ {1} == '30' ]]; then
        anchr quorum \
            R1.fq.gz R2.fq.gz Rs.fq.gz \
            -p 16 \
            -o quorum.sh
    else
        anchr quorum \
            R1.fq.gz R2.fq.gz \
            -p 16 \
            -o quorum.sh
    fi

    bash quorum.sh
    
    echo >&2
    " ::: 25 30 ::: 60

# Stats of processed reads
bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 header \
    > stat1.md

parallel -k --no-run-if-empty -j 3 "
    if [ ! -d 2_illumina/Q{1}L{2} ]; then
        exit;
    fi

    bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 2_illumina/Q{1}L{2} ${REAL_G}
    " ::: 25 30 ::: 60 \
     >> stat1.md

cat stat1.md
```

| Name   |   SumIn | CovIn |  SumOut | CovOut | Discard% | AvgRead |  Kmer | RealG |  EstG | Est/Real |   RunTime |
|:-------|--------:|------:|--------:|-------:|---------:|--------:|------:|------:|------:|---------:|----------:|
| Q25L60 | 381.76M |  70.3 | 343.49M |   63.2 |  10.023% |     218 | "127" | 5.43M | 5.34M |     0.98 | 0:01'18'' |
| Q30L60 | 372.08M |  68.5 | 348.42M |   64.1 |   6.360% |     210 | "121" | 5.43M | 5.34M |     0.98 | 0:01'16'' |

* Clear intermediate files.

```bash
BASE_NAME=Bcer
cd $HOME/data/anchr/${BASE_NAME}

find 2_illumina -type f -name "quorum_mer_db.jf" | xargs rm
find 2_illumina -type f -name "k_u_hash_0"       | xargs rm
find 2_illumina -type f -name "*.tmp"            | xargs rm
find 2_illumina -type f -name "pe.renamed.fastq" | xargs rm
find 2_illumina -type f -name "se.renamed.fastq" | xargs rm
find 2_illumina -type f -name "pe.cor.sub.fa"    | xargs rm
```

* kmergenie

```bash
BASE_NAME=Bcer
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/kmergenie
cd 2_illumina/kmergenie

kmergenie -l 21 -k 151 -s 10 -t 8 ../Q30L60/pe.cor.fa -o Q30L60

```

## Bcer: k-unitigs and anchors

```bash
BASE_NAME=Bcer
REAL_G=5432652
cd ${HOME}/data/anchr/${BASE_NAME}

# k-unitigs
parallel --no-run-if-empty -j 1 "
    echo >&2 '==> Group Q{1}L{2} '

    if [ -e Q{1}L{2}/k_unitigs.fasta ]; then
        echo >&2 '    k_unitigs.fasta already presents'
        exit;
    fi
    
    mkdir -p Q{1}L{2}
    cd Q{1}L{2}

    anchr kunitigs \
        ../2_illumina/Q{1}L{2}/pe.cor.fa \
        ../2_illumina/Q{1}L{2}/environment.json \
        -p 16 \
        --kmer 31,41,51,61,71,81,59,91 \
        -o kunitigs.sh
    bash kunitigs.sh
    
    echo >&2
    " ::: 25 30 ::: 60

# anchors
parallel --no-run-if-empty -j 3 "
    echo >&2 '==> Group Q{1}L{2}'

    if [ -e Q{1}L{2}/anchor/pe.anchor.fa ]; then
        exit;
    fi

    if [ ! -e Q{1}L{2}/k_unitigs.fasta ]; then
        exit;
    fi

    rm -fr Q{1}L{2}/anchor
    mkdir -p Q{1}L{2}/anchor
    cd Q{1}L{2}/anchor
    anchr anchors \
        ../pe.cor.fa \
        ../k_unitigs.fasta \
        -p 8 \
        -o anchors.sh
    bash anchors.sh
    
    echo >&2
    " ::: 25 30 ::: 60

# Stats of anchors
bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 header \
    > stat2.md

parallel -k --no-run-if-empty -j 6 "
    if [ ! -e Q{1}L{2}/anchor/pe.anchor.fa ]; then
        exit;
    fi

    bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 Q{1}L{2} ${REAL_G}
    " ::: 25 30 ::: 60 \
     >> stat2.md

cat stat2.md
```

| Name   |  SumCor | CovCor | N50SR |   Sum |   # | N50Anchor |   Sum |   # | N50Others |    Sum |  # |                      Kmer | RunTimeKU | RunTimeAN |
|:-------|--------:|-------:|------:|------:|----:|----------:|------:|----:|----------:|-------:|---:|--------------------------:|----------:|:----------|
| Q25L60 | 343.49M |   63.2 | 34827 | 5.35M | 275 |     34827 | 5.33M | 245 |       806 | 26.22K | 30 | "31,41,51,59,61,71,81,91" | 0:05'15'' | 0:01'42'' |
| Q30L60 | 348.42M |   64.1 | 43794 | 5.37M | 245 |     43794 | 5.31M | 212 |     16156 | 55.94K | 33 | "31,41,51,59,61,71,81,91" | 0:05'18'' | 0:02'15'' |

## Bcer: merge anchors

```bash
BASE_NAME=Bcer
cd ${HOME}/data/anchr/${BASE_NAME}

# merge anchors
mkdir -p merge
anchr contained \
    $(
        parallel -k --no-run-if-empty -j 6 "
            if [ -e Q{1}L{2}/anchor/pe.anchor.fa ]; then
                echo Q{1}L{2}/anchor/pe.anchor.fa
            fi
        " ::: 25 30 ::: 60
    ) \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.contained.fasta
anchr orient merge/anchor.contained.fasta --len 1000 --idt 0.98 -o merge/anchor.orient.fasta
anchr merge merge/anchor.orient.fasta --len 1000 --idt 0.999 -o merge/anchor.merge0.fasta
anchr contained merge/anchor.merge0.fasta --len 1000 --idt 0.98 \
    --proportion 0.99 --parallel 16 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.merge.fasta

# merge others
anchr contained \
    $(
        parallel -k --no-run-if-empty -j 6 "
            if [ -e Q{1}L{2}/anchor/pe.others.fa ]; then
                echo Q{1}L{2}/anchor/pe.others.fa
            fi
        " ::: 25 30 35 ::: 60
    ) \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.contained.fasta
anchr orient merge/others.contained.fasta --len 1000 --idt 0.98 -o merge/others.orient.fasta
anchr merge merge/others.orient.fasta --len 1000 --idt 0.999 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.merge.fasta

# sort on ref
bash ~/Scripts/cpan/App-Anchr/share/sort_on_ref.sh merge/anchor.merge.fasta 1_genome/genome.fa merge/anchor.sort
nucmer -l 200 1_genome/genome.fa merge/anchor.sort.fa
mummerplot -png out.delta -p anchor.sort --large

# mummerplot files
rm *.[fr]plot
rm out.delta
rm *.gp

mv anchor.sort.png merge/

# quast
rm -fr 9_qa
quast --no-check --threads 16 \
    -R 1_genome/genome.fa \
    8_competitor/abyss_ctg.fasta \
    8_competitor/cabog_ctg.fasta \
    8_competitor/mira_ctg.fasta \
    8_competitor/msrca_ctg.fasta \
    8_competitor/sga_ctg.fasta \
    8_competitor/soap_ctg.fasta \
    8_competitor/spades_ctg.fasta \
    8_competitor/velvet_ctg.fasta \
    merge/anchor.merge.fasta \
    1_genome/paralogs.fas \
    --label "abyss,cabog,mira,msrca,sga,soap,spades,velvet,merge,paralogs" \
    -o 9_qa

```

```bash
BASE_NAME=Bcer
cd ${HOME}/data/anchr/${BASE_NAME}

rm -fr superreads
mkdir -p superreads
perl -MApp::Fasops::Common -e '
        BEGIN { our $count = 0; }
        
        my $seq_of = App::Fasops::Common::read_fasta( q{merge/anchor.merge.fasta} );
        
        for my $key (keys %{$seq_of}) {
            printf qq{>%s length:%d\n}, $count, length($seq_of->{$key});
            printf qq{%s\n}, $seq_of->{$key};
        }
    ' \
    > superreads/merged_kunitigs.fasta

perl ~/Scripts/cpan/App-Anchr/share/createSuperReadsForDirectory.perl \
    superreads \
    superreads/merged_kunitigs.fasta \
    2_illumina/Q30L60/pe.cor.fa \
    2_illumina/Q30L60/meanAndStdevByPrefix.pe.txt
 
```

* Stats

```bash
BASE_DIR=$HOME/data/anchr/Bcer
cd ${BASE_DIR}

printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat3.md
printf "|:--|--:|--:|--:|\n" >> stat3.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Paralogs";   faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchor.merge"; faops n50 -H -S -C merge/anchor.merge.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "others.merge"; faops n50 -H -S -C merge/others.merge.fasta;) >> stat3.md

cat stat3.md
```

| Name         |     N50 |     Sum |   # |
|:-------------|--------:|--------:|----:|
| Genome       | 5224283 | 5432652 |   2 |
| Paralogs     |    2295 |  223889 | 103 |
| anchor.merge |   45136 | 5333005 | 207 |
| others.merge |   16158 |   24816 |   4 |

* Clear QxxLxxx.

```bash
BASE_DIR=$HOME/data/anchr/Bcer
cd ${BASE_DIR}

#rm -fr 2_illumina/Q{20,25,30}L*
rm -fr Q{20,25,30}L*
```

# *Rhodobacter sphaeroides* 2.4.1

## Rsph: download

* Reference genome

    * Strain: Rhodobacter sphaeroides 2.4.1
    * Taxid: [272943](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=272943)
    * RefSeq assembly accession:
      [GCF_000012905.2](ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/745/GCF_000006745.1_ASM674v1/GCF_000006745.1_ASM674v1_assembly_report.txt)
    * Proportion of paralogs (> 1000 bp): 0.0286

```bash
BASE_NAME=Rsph
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 1_genome
cd 1_genome

aria2c -x 9 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/012/905/GCF_000012905.2_ASM1290v2/GCF_000012905.2_ASM1290v2_genomic.fna.gz

TAB=$'\t'
cat <<EOF > replace.tsv
NC_007493.2${TAB}1
NC_007494.2${TAB}2
NC_009007.1${TAB}A
NC_007488.2${TAB}B
NC_007489.1${TAB}C
NC_007490.2${TAB}D
NC_009008.1${TAB}E
EOF

faops replace GCF_000012905.2_ASM1290v2_genomic.fna.gz replace.tsv genome.fa

cp ~/data/anchr/paralogs/gage/Results/Rsph/Rsph.multi.fas paralogs.fas

```

* Illumina

    Download from GAGE-B site.

```bash
BASE_NAME=Rsph
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina
cd 2_illumina

aria2c -x 9 -s 3 -c http://ccb.jhu.edu/gage_b/datasets/R_sphaeroides_MiSeq.tar.gz

# NOT gzipped tar
tar xvf R_sphaeroides_MiSeq.tar.gz raw/insert_540_1__cov100x.fastq
tar xvf R_sphaeroides_MiSeq.tar.gz raw/insert_540_2__cov100x.fastq

cat raw/insert_540_1__cov100x.fastq \
    | pigz -p 8 -c \
    > R1.fq.gz
cat raw/insert_540_2__cov100x.fastq \
    | pigz -p 8 -c \
    > R2.fq.gz

rm -fr raw
```

* GAGE-B assemblies

```bash
BASE_NAME=Rsph
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 8_competitor
cd 8_competitor

aria2c -x 9 -s 3 -c http://ccb.jhu.edu/gage_b/genomeAssemblies/R_sphaeroides_MiSeq.tar.gz

tar xvfz R_sphaeroides_MiSeq.tar.gz abyss_ctg.fasta
tar xvfz R_sphaeroides_MiSeq.tar.gz cabog_ctg.fasta
tar xvfz R_sphaeroides_MiSeq.tar.gz mira_ctg.fasta
tar xvfz R_sphaeroides_MiSeq.tar.gz msrca_ctg.fasta
tar xvfz R_sphaeroides_MiSeq.tar.gz sga_ctg.fasta
tar xvfz R_sphaeroides_MiSeq.tar.gz soap_ctg.fasta
tar xvfz R_sphaeroides_MiSeq.tar.gz spades_ctg.fasta
tar xvfz R_sphaeroides_MiSeq.tar.gz velvet_ctg.fasta

```

* FastQC

```bash
BASE_NAME=Rsph
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/fastqc
cd 2_illumina/fastqc

fastqc -t 16 \
    ../R1.fq.gz ../R2.fq.gz \
    -o .

```

* kmergenie

```bash
BASE_NAME=Rsph
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/kmergenie
cd 2_illumina/kmergenie

kmergenie -l 21 -k 151 -s 10 -t 8 ../R1.fq.gz -o oriR1
kmergenie -l 21 -k 151 -s 10 -t 8 ../R2.fq.gz -o oriR2

```

## Rsph: combinations of different quality values and read lengths

* qual: 20, 25, and 30
* len: 60

```bash
BASE_NAME=Rsph
cd ${HOME}/data/anchr/${BASE_NAME}

if [ ! -e 2_illumina/R1.uniq.fq.gz ]; then
    tally \
        --pair-by-offset --with-quality --nozip --unsorted \
        -i 2_illumina/R1.fq.gz \
        -j 2_illumina/R2.fq.gz \
        -o 2_illumina/R1.uniq.fq \
        -p 2_illumina/R2.uniq.fq
    
    parallel --no-run-if-empty -j 2 "
            pigz -p 4 2_illumina/{}.uniq.fq
        " ::: R1 R2
fi

if [ ! -e 2_illumina/R1.scythe.fq.gz ]; then
    parallel --no-run-if-empty -j 2 "
        scythe \
            2_illumina/{}.uniq.fq.gz \
            -q sanger \
            -a /home/wangq/.plenv/versions/5.18.4/lib/perl5/site_perl/5.18.4/auto/share/dist/App-Anchr/illumina_adapters.fa \
            --quiet \
            | pigz -p 4 -c \
            > 2_illumina/{}.scythe.fq.gz
        " ::: R1 R2
fi

parallel --no-run-if-empty -j 3 "
    mkdir -p 2_illumina/Q{1}L{2}
    cd 2_illumina/Q{1}L{2}
    
    if [ -e R1.fq.gz ]; then
        echo '    R1.fq.gz already presents'
        exit;
    fi

    anchr trim \
        --noscythe \
        -q {1} -l {2} \
        ../R1.scythe.fq.gz ../R2.scythe.fq.gz \
        -o stdout \
        | bash
    " ::: 20 25 30 ::: 60

# Stats
printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat.md
printf "|:--|--:|--:|--:|\n" >> stat.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Paralogs"; faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Illumina"; faops n50 -H -S -C 2_illumina/R1.fq.gz 2_illumina/R2.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "uniq";     faops n50 -H -S -C 2_illumina/R1.uniq.fq.gz 2_illumina/R2.uniq.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "scythe";   faops n50 -H -S -C 2_illumina/R1.scythe.fq.gz 2_illumina/R2.scythe.fq.gz;) >> stat.md

parallel -k --no-run-if-empty -j 3 "
    printf \"| %s | %s | %s | %s |\n\" \
        \$( 
            echo Q{1}L{2};
            if [[ {1} -ge '30' ]]; then
                faops n50 -H -S -C \
                    2_illumina/Q{1}L{2}/R1.fq.gz \
                    2_illumina/Q{1}L{2}/R2.fq.gz \
                    2_illumina/Q{1}L{2}/Rs.fq.gz;
            else
                faops n50 -H -S -C \
                    2_illumina/Q{1}L{2}/R1.fq.gz \
                    2_illumina/Q{1}L{2}/R2.fq.gz;
            fi
        )
    " ::: 20 25 30 ::: 60 \
    >> stat.md

cat stat.md
```

| Name     |     N50 |       Sum |       # |
|:---------|--------:|----------:|--------:|
| Genome   | 3188524 |   4602977 |       7 |
| Paralogs |    2337 |    147155 |      66 |
| Illumina |     251 | 451800000 | 1800000 |
| uniq     |     251 | 447895946 | 1784446 |
| scythe   |     251 | 347832128 | 1784446 |
| Q20L60   |     145 | 174293113 | 1281168 |
| Q25L60   |     134 | 144881787 | 1149800 |
| Q30L60   |     117 | 126094347 | 1149478 |

## Rsph: quorum

```bash
BASE_NAME=Rsph
REAL_G=4602977
cd ${HOME}/data/anchr/${BASE_NAME}

parallel --no-run-if-empty -j 1 "
    cd 2_illumina/Q{1}L{2}
    echo >&2 '==> Group Q{1}L{2} <=='

    if [ ! -e R1.fq.gz ]; then
        echo >&2 '    R1.fq.gz not exists'
        exit;
    fi

    if [ -e pe.cor.fa ]; then
        echo >&2 '    pe.cor.fa exists'
        exit;
    fi

    if [[ {1} == '30' ]]; then
        anchr quorum \
            R1.fq.gz R2.fq.gz Rs.fq.gz \
            -p 16 \
            -o quorum.sh
    else
        anchr quorum \
            R1.fq.gz R2.fq.gz \
            -p 16 \
            -o quorum.sh
    fi

    bash quorum.sh
    
    echo >&2
    " ::: 20 25 30 ::: 60

# Stats of processed reads
bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 header \
    > stat1.md

parallel -k --no-run-if-empty -j 3 "
    if [ ! -d 2_illumina/Q{1}L{2} ]; then
        exit;
    fi

    bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 2_illumina/Q{1}L{2} ${REAL_G}
    " ::: 20 25 30 ::: 60 \
     >> stat1.md

cat stat1.md
```

| Name   |   SumIn | CovIn |  SumOut | CovOut | Discard% | AvgRead | Kmer | RealG |  EstG | Est/Real |   RunTime |
|:-------|--------:|------:|--------:|-------:|---------:|--------:|-----:|------:|------:|---------:|----------:|
| Q20L60 | 174.29M |  37.9 | 154.91M |   33.7 |  11.122% |     136 | "37" |  4.6M | 4.55M |     0.99 | 0:00'54'' |
| Q25L60 | 144.88M |  31.5 | 138.36M |   30.1 |   4.502% |     126 | "35" |  4.6M | 4.53M |     0.99 | 0:00'55'' |
| Q30L60 | 126.32M |  27.4 | 123.22M |   26.8 |   2.454% |     111 | "31" |  4.6M | 4.52M |     0.98 | 0:00'50'' |

* Clear intermediate files.

```bash
BASE_NAME=Rsph
cd $HOME/data/anchr/${BASE_NAME}

find 2_illumina -type f -name "quorum_mer_db.jf" | xargs rm
find 2_illumina -type f -name "k_u_hash_0"       | xargs rm
find 2_illumina -type f -name "*.tmp"            | xargs rm
find 2_illumina -type f -name "pe.renamed.fastq" | xargs rm
find 2_illumina -type f -name "se.renamed.fastq" | xargs rm
find 2_illumina -type f -name "pe.cor.sub.fa"    | xargs rm
```

* kmergenie

```bash
BASE_NAME=Rsph
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/kmergenie
cd 2_illumina/kmergenie

kmergenie -l 21 -k 151 -s 10 -t 8 ../Q20L60/pe.cor.fa -o Q20L60

```

## Rsph: k-unitigs and anchors

```bash
BASE_NAME=Rsph
REAL_G=4602977
cd ${HOME}/data/anchr/${BASE_NAME}

# k-unitigs
parallel --no-run-if-empty -j 1 "
    echo >&2 '==> Group Q{1}L{2} '

    if [ -e Q{1}L{2}/k_unitigs.fasta ]; then
        echo >&2 '    k_unitigs.fasta already presents'
        exit;
    fi
    
    mkdir -p Q{1}L{2}
    cd Q{1}L{2}

    anchr kunitigs \
        ../2_illumina/Q{1}L{2}/pe.cor.fa \
        ../2_illumina/Q{1}L{2}/environment.json \
        -p 16 \
        --kmer 31,41,51,61,71,81 \
        -o kunitigs.sh
    bash kunitigs.sh
    
    echo >&2
    " ::: 20 25 30 ::: 60

# anchors
parallel --no-run-if-empty -j 3 "
    echo >&2 '==> Group Q{1}L{2}'

    if [ -e Q{1}L{2}/anchor/pe.anchor.fa ]; then
        exit;
    fi

    if [ ! -e Q{1}L{2}/k_unitigs.fasta ]; then
        exit;
    fi

    rm -fr Q{1}L{2}/anchor
    mkdir -p Q{1}L{2}/anchor
    cd Q{1}L{2}/anchor
    anchr anchors \
        ../pe.cor.fa \
        ../k_unitigs.fasta \
        -p 8 \
        -o anchors.sh
    bash anchors.sh
    
    echo >&2
    " ::: 20 25 30 ::: 60

# Stats of anchors
bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 header \
    > stat2.md

parallel -k --no-run-if-empty -j 6 "
    if [ ! -e Q{1}L{2}/anchor/pe.anchor.fa ]; then
        exit;
    fi

    bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 Q{1}L{2} ${REAL_G}
    " ::: 20 25 30 ::: 60 \
     >> stat2.md

cat stat2.md
```

| Name   |  SumCor | CovCor | N50SR |   Sum |    # | N50Anchor |   Sum |   # | N50Others |     Sum |   # |                Kmer | RunTimeKU | RunTimeAN |
|:-------|--------:|-------:|------:|------:|-----:|----------:|------:|----:|----------:|--------:|----:|--------------------:|----------:|:----------|
| Q20L60 | 154.91M |   33.7 | 21566 | 4.55M |  432 |     21854 | 4.51M | 376 |       796 |  42.42K |  56 | "31,41,51,61,71,81" | 0:02'04'' | 0:01'42'' |
| Q25L60 | 138.36M |   30.1 | 17440 | 4.53M |  498 |     17460 | 4.48M | 429 |       755 |  51.28K |  69 | "31,41,51,61,71,81" | 0:01'56'' | 0:01'36'' |
| Q30L60 | 123.22M |   26.8 | 10535 | 4.52M |  725 |     10753 | 4.44M | 624 |       758 |  74.44K | 101 | "31,41,51,61,71,81" | 0:01'45'' | 0:01'31'' |

## Rsph: merge anchors

```bash
BASE_DIR=$HOME/data/anchr/Rsph
cd ${BASE_DIR}

# merge anchors
mkdir -p merge
anchr contained \
    $(
        parallel -k --no-run-if-empty -j 6 "
            if [ -e Q{1}L{2}/anchor/pe.anchor.fa ]; then
                echo Q{1}L{2}/anchor/pe.anchor.fa
            fi
        " ::: 20 25 30 ::: 60
    ) \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.contained.fasta
anchr orient merge/anchor.contained.fasta --len 1000 --idt 0.98 -o merge/anchor.orient.fasta
anchr merge merge/anchor.orient.fasta --len 1000 --idt 0.999 -o merge/anchor.merge0.fasta
anchr contained merge/anchor.merge0.fasta --len 1000 --idt 0.98 \
    --proportion 0.99 --parallel 16 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.merge.fasta

# merge others
anchr contained \
    $(
        parallel -k --no-run-if-empty -j 6 "
            if [ -e Q{1}L{2}/anchor/pe.others.fa ]; then
                echo Q{1}L{2}/anchor/pe.others.fa
            fi
        " ::: 25 30 35 ::: 60
    ) \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.contained.fasta
anchr orient merge/others.contained.fasta --len 1000 --idt 0.98 -o merge/others.orient.fasta
anchr merge merge/others.orient.fasta --len 1000 --idt 0.999 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.merge.fasta

# sort on ref
bash ~/Scripts/cpan/App-Anchr/share/sort_on_ref.sh merge/anchor.merge.fasta 1_genome/genome.fa merge/anchor.sort
nucmer -l 200 1_genome/genome.fa merge/anchor.sort.fa
mummerplot -png out.delta -p anchor.sort --large

# mummerplot files
rm *.[fr]plot
rm out.delta
rm *.gp

mv anchor.sort.png merge/

# quast
rm -fr 9_qa
quast --no-check --threads 16 \
    -R 1_genome/genome.fa \
    8_competitor/abyss_ctg.fasta \
    8_competitor/cabog_ctg.fasta \
    8_competitor/mira_ctg.fasta \
    8_competitor/msrca_ctg.fasta \
    8_competitor/sga_ctg.fasta \
    8_competitor/soap_ctg.fasta \
    8_competitor/spades_ctg.fasta \
    8_competitor/velvet_ctg.fasta \
    merge/anchor.merge.fasta \
    1_genome/paralogs.fas \
    --label "abyss,cabog,mira,msrca,sga,soap,spades,velvet,merge,paralogs" \
    -o 9_qa

```

* Stats

```bash
BASE_DIR=$HOME/data/anchr/Rsph
cd ${BASE_DIR}

printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat3.md
printf "|:--|--:|--:|--:|\n" >> stat3.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Paralogs";   faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchor.merge"; faops n50 -H -S -C merge/anchor.merge.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "others.merge"; faops n50 -H -S -C merge/others.merge.fasta;) >> stat3.md

cat stat3.md
```

| Name         |     N50 |     Sum |   # |
|:-------------|--------:|--------:|----:|
| Genome       | 3188524 | 4602977 |   7 |
| Paralogs     |    2337 |  147155 |  66 |
| anchor.merge |   27741 | 4516953 | 291 |
| others.merge |    1099 |    9245 |   8 |

* Clear QxxLxxx.

```bash
BASE_DIR=$HOME/data/anchr/Rsph
cd ${BASE_DIR}

#rm -fr 2_illumina/Q{20,25,30}L*
rm -fr Q{20,25,30}L*
```

# *Mycobacterium abscessus* 6G-0125-R

## Mabs: download

* Reference genome

    * *Mycobacterium abscessus* ATCC 19977
        * Taxid: [561007](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=561007)
        * RefSeq assembly accession:
          [GCF_000069185.1](ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/069/185/GCF_000069185.1_ASM6918v1/GCF_000069185.1_ASM6918v1_assembly_report.txt)
        * Proportion of paralogs (> 1000 bp): 0.0168
    * *Mycobacterium abscessus* 6G-0125-R
        * RefSeq assembly accession: GCF_000270985.1

```bash
BASE_NAME=Mabs
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 1_genome
cd 1_genome

aria2c -x 9 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/069/185/GCF_000069185.1_ASM6918v1/GCF_000069185.1_ASM6918v1_genomic.fna.gz

TAB=$'\t'
cat <<EOF > replace.tsv
NC_010397.1${TAB}1
NC_010394.1${TAB}unnamed
EOF

faops replace GCF_000069185.1_ASM6918v1_genomic.fna.gz replace.tsv genome.fa

cp ~/data/anchr/paralogs/gage/Results/Mabs/Mabs.multi.fas paralogs.fas

```

* Illumina

    Download from GAGE-B site.

```bash
BASE_NAME=Mabs
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina
cd 2_illumina

aria2c -x 9 -s 3 -c http://ccb.jhu.edu/gage_b/datasets/M_abscessus_MiSeq.tar.gz

# NOT gzipped tar
tar xvf M_abscessus_MiSeq.tar.gz raw/reads_1.fastq
tar xvf M_abscessus_MiSeq.tar.gz raw/reads_2.fastq

cat raw/reads_1.fastq \
    | pigz -p 8 -c \
    > R1.fq.gz
cat raw/reads_2.fastq \
    | pigz -p 8 -c \
    > R2.fq.gz

rm -fr raw
```

* GAGE-B assemblies

```bash
BASE_NAME=Mabs
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 8_competitor
cd 8_competitor

aria2c -x 9 -s 3 -c http://ccb.jhu.edu/gage_b/genomeAssemblies/M_abscessus_MiSeq.tar.gz

tar xvfz M_abscessus_MiSeq.tar.gz abyss_ctg.fasta
tar xvfz M_abscessus_MiSeq.tar.gz cabog_ctg.fasta
tar xvfz M_abscessus_MiSeq.tar.gz mira_ctg.fasta
tar xvfz M_abscessus_MiSeq.tar.gz msrca_ctg.fasta
tar xvfz M_abscessus_MiSeq.tar.gz sga_ctg.fasta
tar xvfz M_abscessus_MiSeq.tar.gz soap_ctg.fasta
tar xvfz M_abscessus_MiSeq.tar.gz spades_ctg.fasta
tar xvfz M_abscessus_MiSeq.tar.gz velvet_ctg.fasta

```

* FastQC

```bash
BASE_NAME=Mabs
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/fastqc
cd 2_illumina/fastqc

fastqc -t 16 \
    ../R1.fq.gz ../R2.fq.gz \
    -o .

```

* kmergenie

```bash
BASE_NAME=Mabs
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/kmergenie
cd 2_illumina/kmergenie

kmergenie -l 21 -k 151 -s 10 -t 8 ../R1.fq.gz -o oriR1
kmergenie -l 21 -k 151 -s 10 -t 8 ../R2.fq.gz -o oriR2

```

## Mabs: combinations of different quality values and read lengths

* qual: 20, 25, and 30
* len: 60

```bash
BASE_NAME=Mabs
cd ${HOME}/data/anchr/${BASE_NAME}

if [ ! -e 2_illumina/R1.uniq.fq.gz ]; then
    tally \
        --pair-by-offset --with-quality --nozip --unsorted \
        -i 2_illumina/R1.fq.gz \
        -j 2_illumina/R2.fq.gz \
        -o 2_illumina/R1.uniq.fq \
        -p 2_illumina/R2.uniq.fq
    
    parallel --no-run-if-empty -j 2 "
            pigz -p 4 2_illumina/{}.uniq.fq
        " ::: R1 R2
fi

if [ ! -e 2_illumina/R1.scythe.fq.gz ]; then
    parallel --no-run-if-empty -j 2 "
        scythe \
            2_illumina/{}.uniq.fq.gz \
            -q sanger \
            -a /home/wangq/.plenv/versions/5.18.4/lib/perl5/site_perl/5.18.4/auto/share/dist/App-Anchr/illumina_adapters.fa \
            --quiet \
            | pigz -p 4 -c \
            > 2_illumina/{}.scythe.fq.gz
        " ::: R1 R2
fi

parallel --no-run-if-empty -j 3 "
    mkdir -p 2_illumina/Q{1}L{2}
    cd 2_illumina/Q{1}L{2}
    
    if [ -e R1.fq.gz ]; then
        echo '    R1.fq.gz already presents'
        exit;
    fi

    anchr trim \
        --noscythe \
        -q {1} -l {2} \
        ../R1.scythe.fq.gz ../R2.scythe.fq.gz \
        -o stdout \
        | bash
    " ::: 20 25 30 ::: 60

# Stats
printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat.md
printf "|:--|--:|--:|--:|\n" >> stat.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Paralogs"; faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Illumina"; faops n50 -H -S -C 2_illumina/R1.fq.gz 2_illumina/R2.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "uniq";     faops n50 -H -S -C 2_illumina/R1.uniq.fq.gz 2_illumina/R2.uniq.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "scythe";   faops n50 -H -S -C 2_illumina/R1.scythe.fq.gz 2_illumina/R2.scythe.fq.gz;) >> stat.md

parallel -k --no-run-if-empty -j 3 "
    printf \"| %s | %s | %s | %s |\n\" \
        \$( 
            echo Q{1}L{2};
            if [[ {1} == '30' ]]; then
                faops n50 -H -S -C \
                    2_illumina/Q{1}L{2}/R1.fq.gz \
                    2_illumina/Q{1}L{2}/R2.fq.gz \
                    2_illumina/Q{1}L{2}/Rs.fq.gz;
            else
                faops n50 -H -S -C \
                    2_illumina/Q{1}L{2}/R1.fq.gz \
                    2_illumina/Q{1}L{2}/R2.fq.gz;
            fi
        )
    " ::: 20 25 30 ::: 60 \
    >> stat.md

cat stat.md
```

| Name     |     N50 |       Sum |       # |
|:---------|--------:|----------:|--------:|
| Genome   | 5067172 |   5090491 |       2 |
| Paralogs |    1580 |     83364 |      53 |
| Illumina |     251 | 511999840 | 2039840 |
| uniq     |     251 | 511871830 | 2039330 |
| scythe   |     194 | 369175995 | 2039330 |
| Q20L60   |     180 | 291683466 | 1747016 |
| Q25L60   |     175 | 251424558 | 1563932 |
| Q30L60   |     164 | 222027704 | 1502478 |

## Mabs: quorum

```bash
BASE_NAME=Mabs
REAL_G=5090491
cd ${HOME}/data/anchr/${BASE_NAME}

parallel --no-run-if-empty -j 1 "
    cd 2_illumina/Q{1}L{2}
    echo >&2 '==> Group Q{1}L{2} <=='

    if [ ! -e R1.fq.gz ]; then
        echo >&2 '    R1.fq.gz not exists'
        exit;
    fi

    if [ -e pe.cor.fa ]; then
        echo >&2 '    pe.cor.fa exists'
        exit;
    fi

    if [[ {1} == '30' ]]; then
        anchr quorum \
            R1.fq.gz R2.fq.gz Rs.fq.gz \
            -p 16 \
            -o quorum.sh
    else
        anchr quorum \
            R1.fq.gz R2.fq.gz \
            -p 16 \
            -o quorum.sh
    fi

    bash quorum.sh
    
    echo >&2
    " ::: 20 25 30 ::: 60

# Stats of processed reads
bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 header \
    > stat1.md

parallel -k --no-run-if-empty -j 3 "
    if [ ! -d 2_illumina/Q{1}L{2} ]; then
        exit;
    fi

    bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 2_illumina/Q{1}L{2} ${REAL_G}
    " ::: 20 25 30 ::: 60 \
     >> stat1.md

cat stat1.md
```

| Name   |   SumIn | CovIn |  SumOut | CovOut | Discard% | AvgRead | Kmer | RealG |  EstG | Est/Real |   RunTime |
|:-------|--------:|------:|--------:|-------:|---------:|--------:|-----:|------:|------:|---------:|----------:|
| Q20L60 | 291.68M |  57.3 | 228.29M |   44.8 |  21.734% |     167 | "47" | 5.09M | 5.23M |     1.03 | 0:01'09'' |
| Q25L60 | 251.42M |  49.4 | 210.79M |   41.4 |  16.164% |     162 | "43" | 5.09M | 5.21M |     1.02 | 0:01'02'' |
| Q30L60 | 222.24M |  43.7 | 194.38M |   38.2 |  12.534% |     152 | "39" | 5.09M | 5.19M |     1.02 | 0:01'05'' |

* Clear intermediate files.

```bash
BASE_NAME=Mabs
cd $HOME/data/anchr/${BASE_NAME}

find 2_illumina -type f -name "quorum_mer_db.jf" | xargs rm
find 2_illumina -type f -name "k_u_hash_0"       | xargs rm
find 2_illumina -type f -name "*.tmp"            | xargs rm
find 2_illumina -type f -name "pe.renamed.fastq" | xargs rm
find 2_illumina -type f -name "se.renamed.fastq" | xargs rm
find 2_illumina -type f -name "pe.cor.sub.fa"    | xargs rm
```

* kmergenie

```bash
BASE_NAME=Mabs
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/kmergenie
cd 2_illumina/kmergenie

kmergenie -l 21 -k 151 -s 10 -t 8 ../Q20L60/pe.cor.fa -o Q20L60

```

## Mabs: k-unitigs and anchors

```bash
BASE_NAME=Mabs
REAL_G=5090491
cd ${HOME}/data/anchr/${BASE_NAME}

# k-unitigs
parallel --no-run-if-empty -j 1 "
    echo >&2 '==> Group Q{1}L{2} '

    if [ -e Q{1}L{2}/k_unitigs.fasta ]; then
        echo >&2 '    k_unitigs.fasta already presents'
        exit;
    fi
    
    mkdir -p Q{1}L{2}
    cd Q{1}L{2}

    anchr kunitigs \
        ../2_illumina/Q{1}L{2}/pe.cor.fa \
        ../2_illumina/Q{1}L{2}/environment.json \
        -p 16 \
        --kmer 31,41,51,61,71,81 \
        -o kunitigs.sh
    bash kunitigs.sh
    
    echo >&2
    " ::: 20 25 30 ::: 60

# anchors
parallel --no-run-if-empty -j 3 "
    echo >&2 '==> Group Q{1}L{2}'

    if [ -e Q{1}L{2}/anchor/pe.anchor.fa ]; then
        exit;
    fi

    if [ ! -e Q{1}L{2}/k_unitigs.fasta ]; then
        exit;
    fi

    rm -fr Q{1}L{2}/anchor
    mkdir -p Q{1}L{2}/anchor
    cd Q{1}L{2}/anchor
    anchr anchors \
        ../pe.cor.fa \
        ../k_unitigs.fasta \
        -p 8 \
        -o anchors.sh
    bash anchors.sh
    
    echo >&2
    " ::: 20 25 30 ::: 60

# Stats of anchors
bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 header \
    > stat2.md

parallel -k --no-run-if-empty -j 6 "
    if [ ! -e Q{1}L{2}/anchor/pe.anchor.fa ]; then
        exit;
    fi

    bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 Q{1}L{2} ${REAL_G}
    " ::: 20 25 30 ::: 60 \
     >> stat2.md

cat stat2.md
```

| Name   |  SumCor | CovCor | N50SR |   Sum |    # | N50Anchor |   Sum |    # | N50Others |     Sum |   # |                   Kmer | RunTimeKU | RunTimeAN |
|:-------|--------:|-------:|------:|------:|-----:|----------:|------:|-----:|----------:|--------:|----:|-----------------------:|----------:|:----------|
| Q20L60 | 228.29M |   44.8 |  6493 | 5.21M | 1213 |      6642 | 5.07M | 1046 |       815 | 141.92K | 167 | "31,41,45,51,61,71,81" | 0:02'44'' | 0:01'44'' |
| Q25L60 | 210.79M |   41.4 |  8980 | 5.17M |  885 |      9075 |  5.1M |  796 |       764 |  64.25K |  89 | "31,41,45,51,61,71,81" | 0:02'36'' | 0:01'38'' |
| Q30L60 | 194.38M |   38.2 | 14939 |  5.2M |  616 |     15113 | 5.11M |  561 |      9075 |   93.7K |  55 | "31,41,45,51,61,71,81" | 0:02'30'' | 0:01'40'' |

## Mabs: merge anchors

```bash
BASE_DIR=$HOME/data/anchr/Mabs
cd ${BASE_DIR}

# merge anchors
mkdir -p merge
anchr contained \
    $(
        parallel -k --no-run-if-empty -j 6 "
            if [ -e Q{1}L{2}/anchor/pe.anchor.fa ]; then
                echo Q{1}L{2}/anchor/pe.anchor.fa
            fi
        " ::: 20 25 30 ::: 60
    ) \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.contained.fasta
anchr orient merge/anchor.contained.fasta --len 1000 --idt 0.98 -o merge/anchor.orient.fasta
anchr merge merge/anchor.orient.fasta --len 1000 --idt 0.999 -o merge/anchor.merge0.fasta
anchr contained merge/anchor.merge0.fasta --len 1000 --idt 0.98 \
    --proportion 0.99 --parallel 16 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.merge.fasta

# merge others
anchr contained \
    $(
        parallel -k --no-run-if-empty -j 6 "
            if [ -e Q{1}L{2}/anchor/pe.others.fa ]; then
                echo Q{1}L{2}/anchor/pe.others.fa
            fi
        " ::: 25 30 35 ::: 60
    ) \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.contained.fasta
anchr orient merge/others.contained.fasta --len 1000 --idt 0.98 -o merge/others.orient.fasta
anchr merge merge/others.orient.fasta --len 1000 --idt 0.999 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.merge.fasta

# sort on ref
bash ~/Scripts/cpan/App-Anchr/share/sort_on_ref.sh merge/anchor.merge.fasta 1_genome/genome.fa merge/anchor.sort
nucmer -l 200 1_genome/genome.fa merge/anchor.sort.fa
mummerplot -png out.delta -p anchor.sort --large

# mummerplot files
rm *.[fr]plot
rm out.delta
rm *.gp

mv anchor.sort.png merge/

# quast
rm -fr 9_qa
quast --no-check --threads 16 \
    -R 1_genome/genome.fa \
    8_competitor/abyss_ctg.fasta \
    8_competitor/cabog_ctg.fasta \
    8_competitor/mira_ctg.fasta \
    8_competitor/msrca_ctg.fasta \
    8_competitor/sga_ctg.fasta \
    8_competitor/soap_ctg.fasta \
    8_competitor/spades_ctg.fasta \
    8_competitor/velvet_ctg.fasta \
    merge/anchor.merge.fasta \
    1_genome/paralogs.fas \
    --label "abyss,cabog,mira,msrca,sga,soap,spades,velvet,merge,paralogs" \
    -o 9_qa

```

* Stats

```bash
BASE_DIR=$HOME/data/anchr/Mabs
cd ${BASE_DIR}

printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat3.md
printf "|:--|--:|--:|--:|\n" >> stat3.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Paralogs";   faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchor.merge"; faops n50 -H -S -C merge/anchor.merge.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "others.merge"; faops n50 -H -S -C merge/others.merge.fasta;) >> stat3.md

cat stat3.md
```

| Name         |     N50 |     Sum |   # |
|:-------------|--------:|--------:|----:|
| Genome       | 5067172 | 5090491 |   2 |
| Paralogs     |    1580 |   83364 |  53 |
| anchor.merge |   16004 | 5148343 | 519 |
| others.merge |   40761 |   49228 |   3 |

* Clear QxxLxxx.

```bash
BASE_DIR=$HOME/data/anchr/Mabs
cd ${BASE_DIR}

#rm -fr 2_illumina/Q{20,25,30}L*
rm -fr Q{20,25,30}L*
```

# *Vibrio cholerae* CP1032(5)

## Vcho: download

* Reference genome

    * *Vibrio cholerae* O1 biovar El Tor str. N16961
        * Taxid: [243277](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=243277)
        * RefSeq assembly accession:
          [GCF_000006745.1](ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/745/GCF_000006745.1_ASM674v1/GCF_000006745.1_ASM674v1_assembly_report.txt)
        * Proportion of paralogs (> 1000 bp): 0.0210
    * *Vibrio cholerae* CP1032(5)
        * RefSeq assembly accession: GCF_000279305.1

```bash
BASE_NAME=Vcho
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 1_genome
cd 1_genome

aria2c -x 9 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/745/GCF_000006745.1_ASM674v1/GCF_000006745.1_ASM674v1_genomic.fna.gz

TAB=$'\t'
cat <<EOF > replace.tsv
NC_002505.1${TAB}I
NC_002506.1${TAB}II
EOF

faops replace GCF_000006745.1_ASM674v1_genomic.fna.gz replace.tsv genome.fa

cp ~/data/anchr/paralogs/gage/Results/Vcho/Vcho.multi.fas paralogs.fas

```

* Illumina

    Download from GAGE-B site.

```bash
BASE_NAME=Vcho
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina
cd 2_illumina

aria2c -x 9 -s 3 -c http://ccb.jhu.edu/gage_b/datasets/V_cholerae_MiSeq.tar.gz

# NOT gzipped tar
tar xvf V_cholerae_MiSeq.tar.gz raw/reads_1.fastq
tar xvf V_cholerae_MiSeq.tar.gz raw/reads_2.fastq

cat raw/reads_1.fastq \
    | pigz -p 8 -c \
    > R1.fq.gz
cat raw/reads_2.fastq \
    | pigz -p 8 -c \
    > R2.fq.gz

rm -fr raw
```

* GAGE-B assemblies

```bash
BASE_NAME=Vcho
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 8_competitor
cd 8_competitor

aria2c -x 9 -s 3 -c http://ccb.jhu.edu/gage_b/genomeAssemblies/V_cholerae_MiSeq.tar.gz

tar xvfz V_cholerae_MiSeq.tar.gz abyss_ctg.fasta
tar xvfz V_cholerae_MiSeq.tar.gz cabog_ctg.fasta
tar xvfz V_cholerae_MiSeq.tar.gz mira_ctg.fasta
tar xvfz V_cholerae_MiSeq.tar.gz msrca_ctg.fasta
tar xvfz V_cholerae_MiSeq.tar.gz sga_ctg.fasta
tar xvfz V_cholerae_MiSeq.tar.gz soap_ctg.fasta
tar xvfz V_cholerae_MiSeq.tar.gz spades_ctg.fasta
tar xvfz V_cholerae_MiSeq.tar.gz velvet_ctg.fasta

```

* FastQC

```bash
BASE_NAME=Vcho
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/fastqc
cd 2_illumina/fastqc

fastqc -t 16 \
    ../R1.fq.gz ../R2.fq.gz \
    -o .

```

## Vcho: combinations of different quality values and read lengths

* qual: 20, 25, and 30
* len: 60 and 90

```bash
BASE_NAME=Vcho
cd ${HOME}/data/anchr/${BASE_NAME}

if [ ! -e 2_illumina/R1.uniq.fq.gz ]; then
    tally \
        --pair-by-offset --with-quality --nozip --unsorted \
        -i 2_illumina/R1.fq.gz \
        -j 2_illumina/R2.fq.gz \
        -o 2_illumina/R1.uniq.fq \
        -p 2_illumina/R2.uniq.fq
    
    parallel --no-run-if-empty -j 2 "
            pigz -p 4 2_illumina/{}.uniq.fq
        " ::: R1 R2
fi

if [ ! -e 2_illumina/R1.scythe.fq.gz ]; then
    parallel --no-run-if-empty -j 2 "
        scythe \
            2_illumina/{}.uniq.fq.gz \
            -q sanger \
            -a /home/wangq/.plenv/versions/5.18.4/lib/perl5/site_perl/5.18.4/auto/share/dist/App-Anchr/illumina_adapters.fa \
            --quiet \
            | pigz -p 4 -c \
            > 2_illumina/{}.scythe.fq.gz
        " ::: R1 R2
fi

parallel --no-run-if-empty -j 3 "
    mkdir -p 2_illumina/Q{1}L{2}
    cd 2_illumina/Q{1}L{2}
    
    if [ -e R1.fq.gz ]; then
        echo '    R1.fq.gz already presents'
        exit;
    fi

    anchr trim \
        --noscythe \
        -q {1} -l {2} \
        ../R1.scythe.fq.gz ../R2.scythe.fq.gz \
        -o stdout \
        | bash
    " ::: 20 25 30 ::: 60 90

```

* Stats

```bash
BASE_NAME=Vcho
cd ${HOME}/data/anchr/${BASE_NAME}

printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat.md
printf "|:--|--:|--:|--:|\n" >> stat.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Paralogs"; faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Illumina"; faops n50 -H -S -C 2_illumina/R1.fq.gz 2_illumina/R2.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "uniq";     faops n50 -H -S -C 2_illumina/R1.uniq.fq.gz 2_illumina/R2.uniq.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "scythe";   faops n50 -H -S -C 2_illumina/R1.scythe.fq.gz 2_illumina/R2.scythe.fq.gz;) >> stat.md

parallel -k --no-run-if-empty -j 3 "
    printf \"| %s | %s | %s | %s |\n\" \
        \$( 
            echo Q{1}L{2};
            if [[ {1} == '30' ]]; then
                faops n50 -H -S -C \
                    2_illumina/Q{1}L{2}/R1.fq.gz \
                    2_illumina/Q{1}L{2}/R2.fq.gz \
                    2_illumina/Q{1}L{2}/Rs.fq.gz;
            else
                faops n50 -H -S -C \
                    2_illumina/Q{1}L{2}/R1.fq.gz \
                    2_illumina/Q{1}L{2}/R2.fq.gz;
            fi
        )
    " ::: 20 25 30 ::: 60 90 \
    >> stat.md

cat stat.md
```

| Name     |     N50 |       Sum |       # |
|:---------|--------:|----------:|--------:|
| Genome   | 2961149 |   4033464 |       2 |
| Paralogs |    3483 |    114707 |      48 |
| Illumina |     251 | 399999624 | 1593624 |
| uniq     |     251 | 397989616 | 1585616 |
| scythe   |     198 | 303351043 | 1585616 |
| Q20L60   |     192 | 276676322 | 1504034 |
| Q20L90   |     192 | 271399426 | 1460080 |
| Q25L60   |     189 | 254738206 | 1415632 |
| Q25L90   |     189 | 248113857 | 1359224 |
| Q30L60   |     182 | 231416118 | 1354988 |
| Q30L90   |     183 | 227344381 | 1300876 |

## Vcho: quorum

```bash
BASE_NAME=Vcho
cd ${HOME}/data/anchr/${BASE_NAME}

parallel --no-run-if-empty -j 1 "
    cd 2_illumina/Q{1}L{2}
    echo >&2 '==> Group Q{1}L{2} <=='

    if [ ! -e R1.fq.gz ]; then
        echo >&2 '    R1.fq.gz not exists'
        exit;
    fi

    if [ -e pe.cor.fa ]; then
        echo >&2 '    pe.cor.fa exists'
        exit;
    fi

    if [[ {1} == '30' ]]; then
        anchr quorum \
            R1.fq.gz R2.fq.gz Rs.fq.gz \
            -p 16 \
            -o quorum.sh
    else
        anchr quorum \
            R1.fq.gz R2.fq.gz \
            -p 16 \
            -o quorum.sh
    fi

    bash quorum.sh
    
    echo >&2
    " ::: 20 25 30 ::: 60 90

```

Clear intermediate files.

```bash
BASE_NAME=Vcho
cd $HOME/data/anchr/${BASE_NAME}

find 2_illumina -type f -name "quorum_mer_db.jf" | xargs rm
find 2_illumina -type f -name "k_u_hash_0"       | xargs rm
find 2_illumina -type f -name "*.tmp"            | xargs rm
find 2_illumina -type f -name "pe.renamed.fastq" | xargs rm
find 2_illumina -type f -name "se.renamed.fastq" | xargs rm
find 2_illumina -type f -name "pe.cor.sub.fa"    | xargs rm
```

* Stats of processed reads

```bash
BASE_NAME=Vcho
cd ${HOME}/data/anchr/${BASE_NAME}

REAL_G=4033464

bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 header \
    > stat1.md

parallel -k --no-run-if-empty -j 3 "
    if [ ! -d 2_illumina/Q{1}L{2} ]; then
        exit;
    fi

    bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 2_illumina/Q{1}L{2} ${REAL_G}
    " ::: 20 25 30 ::: 60 90 \
     >> stat1.md

cat stat1.md
```

| Name   |   SumIn | CovIn |  SumOut | CovOut | Discard% | AvgRead |  Kmer | RealG |  EstG | Est/Real |   RunTime |
|:-------|--------:|------:|--------:|-------:|---------:|--------:|------:|------:|------:|---------:|----------:|
| Q20L60 | 276.68M |  68.6 | 224.36M |   55.6 |  18.911% |     183 | "113" | 4.03M | 3.96M |     0.98 | 0:01'05'' |
| Q20L90 |  271.4M |  67.3 | 220.69M |   54.7 |  18.684% |     184 | "113" | 4.03M | 3.96M |     0.98 | 0:01'04'' |
| Q25L60 | 254.74M |  63.2 | 217.57M |   53.9 |  14.590% |     179 | "109" | 4.03M | 3.95M |     0.98 | 0:01'04'' |
| Q25L90 | 248.11M |  61.5 | 212.22M |   52.6 |  14.465% |     182 | "111" | 4.03M | 3.95M |     0.98 | 0:01'02'' |
| Q30L60 | 231.51M |  57.4 | 205.43M |   50.9 |  11.266% |     174 | "105" | 4.03M | 3.94M |     0.98 | 0:01'02'' |
| Q30L90 | 227.45M |  56.4 |  201.7M |   50.0 |  11.322% |     177 | "107" | 4.03M | 3.94M |     0.98 | 0:00'58'' |

* kmergenie

```bash
BASE_NAME=Vcho
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/kmergenie
cd 2_illumina/kmergenie

kmergenie -l 21 -k 151 -s 10 -t 8 ../R1.fq.gz -o oriR1
kmergenie -l 21 -k 151 -s 10 -t 8 ../R2.fq.gz -o oriR2
kmergenie -l 21 -k 151 -s 10 -t 8 ../Q20L60/pe.cor.fa -o Q20L60

```

## Vcho: generate k-unitigs

```bash
BASE_NAME=Vcho
cd ${HOME}/data/anchr/${BASE_NAME}

parallel --no-run-if-empty -j 1 "
    echo >&2 '==> Group Q{1}L{2} '

    if [ -e Q{1}L{2}/k_unitigs.fasta ]; then
        echo >&2 '    k_unitigs.fasta already presents'
        exit;
    fi
    
    mkdir -p Q{1}L{2}
    cd Q{1}L{2}

    anchr kunitigs \
        ../2_illumina/Q{1}L{2}/pe.cor.fa \
        ../2_illumina/Q{1}L{2}/environment.json \
        -p 16 \
        --kmer 31,41,51,61,71,81,101,121,57,63 \
        -o kunitigs.sh
    bash kunitigs.sh
    
    echo >&2
    " ::: 20 25 30 ::: 60 90

```

## Vcho: create anchors

```bash
BASE_NAME=Vcho
cd ${HOME}/data/anchr/${BASE_NAME}

parallel --no-run-if-empty -j 3 "
    echo >&2 '==> Group Q{1}L{2}'

    if [ -e Q{1}L{2}/anchor/pe.anchor.fa ]; then
        exit;
    fi

    rm -fr Q{1}L{2}/anchor
    bash ~/Scripts/cpan/App-Anchr/share/anchor.sh Q{1}L{2} 8 false
    
    echo >&2
    " ::: 20 25 30 ::: 60 90

```

* Stats of anchors

```bash
BASE_NAME=Vcho
cd ${HOME}/data/anchr/${BASE_NAME}

REAL_G=4033464

bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 header \
    > stat2.md

parallel -k --no-run-if-empty -j 6 "
    if [ ! -e Q{1}L{2}/anchor/pe.anchor.fa ]; then
        exit;
    fi

    bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 Q{1}L{2} ${REAL_G}
    " ::: 20 25 30 ::: 60 90 \
     >> stat2.md

cat stat2.md
```

## Vcho: results

| Name   |  SumCor | CovCor | N50SR |   Sum |   # | N50Anchor |   Sum |   # | N50Others |    Sum |   # |                              Kmer | RunTimeKU | RunTimeAN |
|:-------|--------:|-------:|------:|------:|----:|----------:|------:|----:|----------:|-------:|----:|----------------------------------:|----------:|:----------|
| Q20L60 | 224.36M |   55.6 |  9312 | 3.99M | 737 |      9549 | 3.89M | 608 |       771 | 96.04K | 129 | "31,41,51,57,61,63,71,81,101,121" | 0:03'18'' | 0:01'37'' |
| Q20L90 | 220.69M |   54.7 |  9312 | 3.99M | 730 |      9549 | 3.89M | 598 |       765 | 97.45K | 132 | "31,41,51,57,61,63,71,81,101,121" | 0:03'24'' | 0:01'25'' |
| Q25L60 | 217.57M |   53.9 | 24544 | 3.96M | 355 |     24583 | 3.91M | 289 |       789 | 49.08K |  66 | "31,41,51,57,61,63,71,81,101,121" | 0:03'22'' | 0:01'39'' |
| Q25L90 | 212.22M |   52.6 | 23725 | 3.96M | 362 |     24544 | 3.91M | 294 |       772 | 49.93K |  68 | "31,41,51,57,61,63,71,81,101,121" | 0:03'22'' | 0:01'29'' |
| Q30L60 | 205.43M |   50.9 | 29588 | 3.96M | 329 |     29684 | 3.91M | 266 |       765 | 45.76K |  63 | "31,41,51,57,61,63,71,81,101,121" | 0:03'14'' | 0:01'36'' |
| Q30L90 |  201.7M |   50.0 | 29588 | 3.96M | 329 |     29684 | 3.91M | 266 |       765 | 45.76K |  63 | "31,41,51,57,61,63,71,81,101,121" | 0:03'15'' | 0:01'36'' |

## Vcho: merge anchors

```bash
BASE_DIR=$HOME/data/anchr/Vcho
cd ${BASE_DIR}

# merge anchors
mkdir -p merge
anchr contained \
    Q20L60/anchor/pe.anchor.fa \
    Q25L60/anchor/pe.anchor.fa \
    Q30L60/anchor/pe.anchor.fa \
    Q20L90/anchor/pe.anchor.fa \
    Q25L90/anchor/pe.anchor.fa \
    Q30L90/anchor/pe.anchor.fa \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.contained.fasta
anchr orient merge/anchor.contained.fasta --len 1000 --idt 0.98 -o merge/anchor.orient.fasta
anchr merge merge/anchor.orient.fasta --len 1000 --idt 0.999 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.merge.fasta

# merge others
anchr contained \
    Q20L60/anchor/pe.others.fa \
    Q25L60/anchor/pe.others.fa \
    Q30L60/anchor/pe.others.fa \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.contained.fasta
anchr orient merge/others.contained.fasta --len 1000 --idt 0.98 -o merge/others.orient.fasta
anchr merge merge/others.orient.fasta --len 1000 --idt 0.999 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.merge.fasta

# sort on ref
bash ~/Scripts/cpan/App-Anchr/share/sort_on_ref.sh merge/anchor.merge.fasta 1_genome/genome.fa merge/anchor.sort
nucmer -l 200 1_genome/genome.fa merge/anchor.sort.fa
mummerplot -png out.delta -p anchor.sort --large

# mummerplot files
rm *.[fr]plot
rm out.delta
rm *.gp

mv anchor.sort.png merge/

# quast
rm -fr 9_qa
quast --no-check --threads 16 \
    -R 1_genome/genome.fa \
    8_competitor/abyss_ctg.fasta \
    8_competitor/cabog_ctg.fasta \
    8_competitor/mira_ctg.fasta \
    8_competitor/msrca_ctg.fasta \
    8_competitor/sga_ctg.fasta \
    8_competitor/soap_ctg.fasta \
    8_competitor/spades_ctg.fasta \
    8_competitor/velvet_ctg.fasta \
    merge/anchor.merge.fasta \
    1_genome/paralogs.fas \
    --label "abyss,cabog,mira,msrca,sga,soap,spades,velvet,merge,paralogs" \
    -o 9_qa

```

* Stats

```bash
BASE_DIR=$HOME/data/anchr/Vcho
cd ${BASE_DIR}

printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat3.md
printf "|:--|--:|--:|--:|\n" >> stat3.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Paralogs";   faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchor.merge"; faops n50 -H -S -C merge/anchor.merge.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "others.merge"; faops n50 -H -S -C merge/others.merge.fasta;) >> stat3.md

cat stat3.md
```

| Name         |     N50 |     Sum |   # |
|:-------------|--------:|--------:|----:|
| Genome       | 2961149 | 4033464 |   2 |
| Paralogs     |    3483 |  114707 |  48 |
| anchor.merge |   32909 | 3910957 | 235 |
| others.merge |    1068 |    5516 |   5 |

* Clear QxxLxxx.

```bash
BASE_DIR=$HOME/data/anchr/Vcho
cd ${BASE_DIR}

#rm -fr 2_illumina/Q{20,25,30}L*
rm -fr Q{20,25,30}L*
```

# *Mycobacterium abscessus* 6G-0125-R Full

## MabsF: download

* Reference genome

```bash
BASE_NAME=MabsF
mkdir -p ${HOME}/data/anchr/${BASE_NAME}
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 1_genome
cd 1_genome

cp ~/data/anchr/Mabs/1_genome/genome.fa .
cp ~/data/anchr/Mabs/1_genome/paralogs.fas .

```

* Illumina

    SRX246890, SRR768269

```bash
BASE_NAME=MabsF
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina
cd 2_illumina

cat << EOF > sra_ftp.txt
ftp://ftp.sra.ebi.ac.uk/vol1/srr/SRR768/SRR768269
EOF

aria2c -x 9 -s 3 -c -i sra_ftp.txt

cat << EOF > sra_md5.txt
afcf09a85f0797ab893b05200b575b9d        SRR768269
EOF

md5sum --check sra_md5.txt

fastq-dump --split-files ./SRR768269  
find . -name "*.fastq" | parallel -j 2 pigz -p 8

ln -s SRR768269_1.fastq.gz R1.fq.gz
ln -s SRR768269_2.fastq.gz R2.fq.gz
```

* GAGE-B assemblies

```bash
BASE_NAME=MabsF
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 8_competitor
cd 8_competitor

cp ~/data/anchr/Mabs/8_competitor/* .

```

* FastQC

```bash
BASE_NAME=MabsF
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/fastqc
cd 2_illumina/fastqc

fastqc -t 16 \
    ../R1.fq.gz ../R2.fq.gz \
    -o .

```

* kmergenie

```bash
BASE_NAME=MabsF
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/kmergenie
cd 2_illumina/kmergenie

kmergenie -l 21 -k 151 -s 10 -t 8 ../R1.fq.gz -o oriR1
kmergenie -l 21 -k 151 -s 10 -t 8 ../R2.fq.gz -o oriR2

```

## MabsF: combinations of different quality values and read lengths

* qual: 20, 25, 30, and 35
* len: 60

```bash
BASE_NAME=MabsF
cd ${HOME}/data/anchr/${BASE_NAME}

if [ ! -e 2_illumina/R1.uniq.fq.gz ]; then
    tally \
        --pair-by-offset --with-quality --nozip --unsorted \
        -i 2_illumina/R1.fq.gz \
        -j 2_illumina/R2.fq.gz \
        -o 2_illumina/R1.uniq.fq \
        -p 2_illumina/R2.uniq.fq
    
    parallel --no-run-if-empty -j 2 "
            pigz -p 4 2_illumina/{}.uniq.fq
        " ::: R1 R2
fi

# Down sampling to 200x
REAL_G=5090491
READ_COUNT=$(( 200 / 2 * ${REAL_G} / 251 ))
if [ ! -e 2_illumina/R1.200x.fq.gz ]; then
    parallel --no-run-if-empty -j 2 "
        seqtk sample \
            -s${READ_COUNT} \
            2_illumina/{}.uniq.fq.gz \
            ${READ_COUNT} \
            | pigz -p 4 -c \
            > 2_illumina/{}.200x.fq.gz
        " ::: R1 R2
fi

if [ ! -e 2_illumina/R1.scythe.fq.gz ]; then
    parallel --no-run-if-empty -j 2 "
        scythe \
            2_illumina/{}.200x.fq.gz \
            -q sanger \
            -a /home/wangq/.plenv/versions/5.18.4/lib/perl5/site_perl/5.18.4/auto/share/dist/App-Anchr/illumina_adapters.fa \
            --quiet \
            | pigz -p 4 -c \
            > 2_illumina/{}.scythe.fq.gz
        " ::: R1 R2
fi

parallel --no-run-if-empty -j 3 "
    mkdir -p 2_illumina/Q{1}L{2}
    cd 2_illumina/Q{1}L{2}
    
    if [ -e R1.fq.gz ]; then
        echo '    R1.fq.gz already presents'
        exit;
    fi

    anchr trim \
        --noscythe \
        -q {1} -l {2} \
        ../R1.scythe.fq.gz ../R2.scythe.fq.gz \
        -o stdout \
        | bash
    " ::: 20 25 30 35 ::: 60

# Stats
printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat.md
printf "|:--|--:|--:|--:|\n" >> stat.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Paralogs"; faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Illumina"; faops n50 -H -S -C 2_illumina/R1.fq.gz 2_illumina/R2.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "uniq";     faops n50 -H -S -C 2_illumina/R1.uniq.fq.gz 2_illumina/R2.uniq.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "200x";     faops n50 -H -S -C 2_illumina/R1.200x.fq.gz 2_illumina/R2.200x.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "scythe";   faops n50 -H -S -C 2_illumina/R1.scythe.fq.gz 2_illumina/R2.scythe.fq.gz;) >> stat.md

parallel -k --no-run-if-empty -j 3 "
    printf \"| %s | %s | %s | %s |\n\" \
        \$( 
            echo Q{1}L{2};
            if [[ {1} -ge '30' ]]; then
                faops n50 -H -S -C \
                    2_illumina/Q{1}L{2}/R1.fq.gz \
                    2_illumina/Q{1}L{2}/R2.fq.gz \
                    2_illumina/Q{1}L{2}/Rs.fq.gz;
            else
                faops n50 -H -S -C \
                    2_illumina/Q{1}L{2}/R1.fq.gz \
                    2_illumina/Q{1}L{2}/R2.fq.gz;
            fi
        )
    " ::: 20 25 30 35 ::: 60 \
    >> stat.md

cat stat.md
```

| Name     |     N50 |        Sum |       # |
|:---------|--------:|-----------:|--------:|
| Genome   | 5067172 |    5090491 |       2 |
| Paralogs |    1580 |      83364 |      53 |
| Illumina |     251 | 2194026140 | 8741140 |
| uniq     |     251 | 2191831898 | 8732398 |
| 200x     |     251 | 1018098168 | 4056168 |
| scythe   |     194 |  734312412 | 4056168 |
| Q20L60   |     180 |  578890373 | 3469454 |
| Q25L60   |     174 |  498468112 | 3103052 |
| Q30L60   |     164 |  439352008 | 2977906 |
| Q35L60   |     135 |  237111173 | 1957449 |

## MabsF: quorum

```bash
BASE_NAME=MabsF
REAL_G=5090491
cd ${HOME}/data/anchr/${BASE_NAME}

parallel --no-run-if-empty -j 1 "
    cd 2_illumina/Q{1}L{2}
    echo >&2 '==> Group Q{1}L{2} <=='

    if [ ! -e R1.fq.gz ]; then
        echo >&2 '    R1.fq.gz not exists'
        exit;
    fi

    if [ -e pe.cor.fa ]; then
        echo >&2 '    pe.cor.fa exists'
        exit;
    fi

    if [[ {1} -ge '30' ]]; then
        anchr quorum \
            R1.fq.gz R2.fq.gz Rs.fq.gz \
            -p 16 \
            -o quorum.sh
    else
        anchr quorum \
            R1.fq.gz R2.fq.gz \
            -p 16 \
            -o quorum.sh
    fi

    bash quorum.sh
    
    echo >&2
    " ::: 20 25 30 35 ::: 60

# Stats of processed reads
bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 header \
    > stat1.md

parallel -k --no-run-if-empty -j 3 "
    if [ ! -d 2_illumina/Q{1}L{2} ]; then
        exit;
    fi

    bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 2_illumina/Q{1}L{2} ${REAL_G}
    " ::: 20 25 30 35 ::: 60 \
     >> stat1.md

cat stat1.md

```

| Name   |   SumIn | CovIn |  SumOut | CovOut | Discard% | AvgRead | Kmer | RealG |  EstG | Est/Real |   RunTime |
|:-------|--------:|------:|--------:|-------:|---------:|--------:|-----:|------:|------:|---------:|----------:|
| Q20L60 | 578.89M | 113.7 | 451.73M |   88.7 |  21.966% |     167 | "45" | 5.09M | 5.39M |     1.06 | 0:06'06'' |
| Q25L60 | 498.47M |  97.9 | 415.13M |   81.5 |  16.719% |     161 | "43" | 5.09M | 5.28M |     1.04 | 0:05'27'' |
| Q30L60 | 439.78M |  86.4 | 382.34M |   75.1 |  13.060% |     152 | "39" | 5.09M | 5.26M |     1.03 | 0:04'49'' |
| Q35L60 | 237.66M |  46.7 |    221M |   43.4 |   7.010% |     126 | "31" | 5.09M | 5.19M |     1.02 | 0:02'27'' |

* Clear intermediate files.

```bash
BASE_NAME=MabsF
cd $HOME/data/anchr/${BASE_NAME}

find 2_illumina -type f -name "quorum_mer_db.jf" | xargs rm
find 2_illumina -type f -name "k_u_hash_0"       | xargs rm
find 2_illumina -type f -name "*.tmp"            | xargs rm
find 2_illumina -type f -name "pe.renamed.fastq" | xargs rm
find 2_illumina -type f -name "se.renamed.fastq" | xargs rm
find 2_illumina -type f -name "pe.cor.sub.fa"    | xargs rm
```

## MabsF: down sampling

```bash
BASE_NAME=MabsF
REAL_G=5090491
cd ${HOME}/data/anchr/${BASE_NAME}

for QxxLxx in $( parallel "echo 'Q{1}L{2}'" ::: 20 25 30 35 ::: 60 ); do
    echo "==> ${QxxLxx}"

    if [ ! -e 2_illumina/${QxxLxx}/pe.cor.fa ]; then
        echo "2_illumina/${QxxLxx}/pe.cor.fa not exists"
        continue;
    fi

    for X in 40 80; do
        printf "==> Coverage: %s\n" ${X}
        
        rm -fr 2_illumina/${QxxLxx}X${X}*
    
        faops split-about -l 0 \
            2_illumina/${QxxLxx}/pe.cor.fa \
            $(( ${REAL_G} * ${X} )) \
            "2_illumina/${QxxLxx}X${X}"
        
        MAX_SERIAL=$(
            cat 2_illumina/${QxxLxx}/environment.json \
                | jq ".SUM_OUT | tonumber | . / ${REAL_G} / ${X} | floor | . - 1"
        )
        
        for i in $( seq 0 1 ${MAX_SERIAL} ); do
            P=$( printf "%03d" ${i})
            printf "  * Part: %s\n" ${P}
            
            mkdir -p "2_illumina/${QxxLxx}X${X}P${P}"
            
            mv  "2_illumina/${QxxLxx}X${X}/${P}.fa" \
                "2_illumina/${QxxLxx}X${X}P${P}/pe.cor.fa"
            cp 2_illumina/${QxxLxx}/environment.json "2_illumina/${QxxLxx}X${X}P${P}"
    
        done
    done
done

```

## MabsF: k-unitigs and anchors (sampled)

```bash
BASE_NAME=MabsF
REAL_G=5090491
cd ${HOME}/data/anchr/${BASE_NAME}

# k-unitigs (sampled)
parallel --no-run-if-empty -j 1 "
    echo >&2 '==> Group Q{1}L{2}X{3}P{4}'

    if [ ! -e 2_illumina/Q{1}L{2}X{3}P{4}/pe.cor.fa ]; then
        echo >&2 '    2_illumina/Q{1}L{2}X{3}P{4}/pe.cor.fa not exists'
        exit;
    fi

    if [ -e Q{1}L{2}X{3}P{4}/k_unitigs.fasta ]; then
        echo >&2 '    k_unitigs.fasta already presents'
        exit;
    fi

    mkdir -p Q{1}L{2}X{3}P{4}
    cd Q{1}L{2}X{3}P{4}

    anchr kunitigs \
        ../2_illumina/Q{1}L{2}X{3}P{4}/pe.cor.fa \
        ../2_illumina/Q{1}L{2}X{3}P{4}/environment.json \
        -p 16 \
        --kmer 31,41,51,61,71,81 \
        -o kunitigs.sh
    bash kunitigs.sh

    echo >&2
    " ::: 20 25 30 35 ::: 60 ::: 40 80 ::: 000 001 002 003 004 005

# anchors (sampled)
parallel --no-run-if-empty -j 3 "
    echo >&2 '==> Group Q{1}L{2}X{3}P{4}'

    if [ ! -e Q{1}L{2}X{3}P{4}/pe.cor.fa ]; then
        echo >&2 '    pe.cor.fa not exists'
        exit;
    fi

    if [ -e Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa ]; then
        echo >&2 '    k_unitigs.fasta already presents'
        exit;
    fi

    rm -fr Q{1}L{2}X{3}P{4}/anchor
    mkdir -p Q{1}L{2}X{3}P{4}/anchor
    cd Q{1}L{2}X{3}P{4}/anchor
    anchr anchors \
        ../pe.cor.fa \
        ../k_unitigs.fasta \
        -p 8 \
        -o anchors.sh
    bash anchors.sh
    
    echo >&2
    " ::: 20 25 30 35 ::: 60 ::: 40 80 ::: 000 001 002 003 004 005

# Stats of anchors
bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 header \
    > stat2.md

parallel -k --no-run-if-empty -j 6 "
    if [ ! -e Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa ]; then
        exit;
    fi

    bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 Q{1}L{2}X{3}P{4} ${REAL_G}
    " ::: 20 25 30 35 ::: 60 ::: 40 80 ::: 000 001 002 003 004 005 \
    >> stat2.md

cat stat2.md
```

| Name          |  SumCor | CovCor | N50SR |   Sum |    # | N50Anchor |   Sum |    # | N50Others |     Sum |    # |                Kmer | RunTimeKU | RunTimeAN |
|:--------------|--------:|-------:|------:|------:|-----:|----------:|------:|-----:|----------:|--------:|-----:|--------------------:|----------:|:----------|
| Q20L60X40P000 | 203.62M |   40.0 |  3335 | 5.18M | 2109 |      3572 | 4.81M | 1603 |       770 | 373.43K |  506 | "31,41,51,61,71,81" | 0:05'32'' | 0:02'19'' |
| Q20L60X40P001 | 203.62M |   40.0 |  3446 | 5.18M | 2081 |      3641 | 4.81M | 1598 |       801 | 364.43K |  483 | "31,41,51,61,71,81" | 0:05'35'' | 0:02'20'' |
| Q20L60X80P000 | 407.24M |   80.0 |  2027 | 5.06M | 3136 |      2353 | 4.21M | 1973 |       764 | 848.88K | 1163 | "31,41,51,61,71,81" | 0:07'20'' | 0:03'18'' |
| Q25L60X40P000 | 203.62M |   40.0 | 16018 | 5.19M |  540 |     16459 | 5.12M |  490 |     13041 |  76.17K |   50 | "31,41,51,61,71,81" | 0:04'32'' | 0:02'19'' |
| Q25L60X40P001 | 203.62M |   40.0 | 17598 | 5.15M |  508 |     17723 | 5.13M |  470 |       812 |  28.51K |   38 | "31,41,51,61,71,81" | 0:03'23'' | 0:02'23'' |
| Q25L60X80P000 | 407.24M |   80.0 |  8476 | 5.18M |  940 |      8614 | 5.11M |  839 |       816 |  76.51K |  101 | "31,41,51,61,71,81" | 0:05'50'' | 0:03'30'' |
| Q30L60X40P000 | 203.62M |   40.0 | 18298 | 5.17M |  464 |     18420 | 5.13M |  424 |       914 |   35.4K |   40 | "31,41,51,61,71,81" | 0:03'49'' | 0:02'13'' |
| Q35L60X40P000 | 203.62M |   40.0 | 20655 | 5.14M |  434 |     20681 | 5.11M |  396 |       757 |  29.91K |   38 | "31,41,51,61,71,81" | 0:04'09'' | 0:02'28'' |

## MabsF: merge anchors

```bash
BASE_NAME=MabsF
cd ${HOME}/data/anchr/${BASE_NAME}

# merge anchors
mkdir -p merge
anchr contained \
    $(
        parallel -k --no-run-if-empty -j 6 "
            if [ -e Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa ]; then
                echo Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa
            fi
            " ::: 25 30 35 ::: 60 ::: 40 80 ::: 000 001 002 003 004 005 006
    ) \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.contained.fasta
anchr orient merge/anchor.contained.fasta --len 1000 --idt 0.98 -o merge/anchor.orient.fasta
anchr merge merge/anchor.orient.fasta --len 1000 --idt 0.999 -o merge/anchor.merge0.fasta
anchr contained merge/anchor.merge0.fasta --len 1000 --idt 0.98 \
    --proportion 0.99 --parallel 16 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.merge.fasta

# merge others
mkdir -p merge
anchr contained \
    $(
        parallel -k --no-run-if-empty -j 6 "
            if [ -e Q{1}L{2}X{3}P{4}/anchor/pe.others.fa ]; then
                echo Q{1}L{2}X{3}P{4}/anchor/pe.others.fa
            fi
            " ::: 25 30 35 ::: 60 ::: 40 80 ::: 000 001 002 003 004 005 006
    ) \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.contained.fasta
anchr orient merge/others.contained.fasta --len 1000 --idt 0.98 -o merge/others.orient.fasta
anchr merge merge/others.orient.fasta --len 1000 --idt 0.999 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.merge.fasta

# sort on ref
bash ~/Scripts/cpan/App-Anchr/share/sort_on_ref.sh merge/anchor.merge.fasta 1_genome/genome.fa merge/anchor.sort
nucmer -l 200 1_genome/genome.fa merge/anchor.sort.fa
mummerplot -png out.delta -p anchor.sort --large

# mummerplot files
rm *.[fr]plot
rm out.delta
rm *.gp

mv anchor.sort.png merge/

# quast
rm -fr 9_qa
quast --no-check --threads 16 \
    -R 1_genome/genome.fa \
    8_competitor/abyss_ctg.fasta \
    8_competitor/cabog_ctg.fasta \
    8_competitor/mira_ctg.fasta \
    8_competitor/msrca_ctg.fasta \
    8_competitor/sga_ctg.fasta \
    8_competitor/soap_ctg.fasta \
    8_competitor/spades_ctg.fasta \
    8_competitor/velvet_ctg.fasta \
    merge/anchor.merge.fasta \
    1_genome/paralogs.fas \
    --label "abyss,cabog,mira,msrca,sga,soap,spades,velvet,merge,paralogs" \
    -o 9_qa

```

* Stats

```bash
BASE_NAME=MabsF
cd ${HOME}/data/anchr/${BASE_NAME}

printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat3.md
printf "|:--|--:|--:|--:|\n" >> stat3.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Paralogs";   faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchor.merge"; faops n50 -H -S -C merge/anchor.merge.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "others.merge"; faops n50 -H -S -C merge/others.merge.fasta;) >> stat3.md

cat stat3.md
```

| Name         |     N50 |     Sum |   # |
|:-------------|--------:|--------:|----:|
| Genome       | 5067172 | 5090491 |   2 |
| Paralogs     |    1580 |   83364 |  53 |
| anchor.merge |   81639 | 5155449 | 122 |
| others.merge |   13061 |   39393 |   7 |

* Clear QxxLxxXxx.

```bash
BASE_NAME=MabsF
cd ${HOME}/data/anchr/${BASE_NAME}

rm -fr 2_illumina/Q{20,25,30}L{1,60,90,120}X*
rm -fr Q{20,25,30}L{1,60,90,120}X*
```

# *Rhodobacter sphaeroides* 2.4.1 Full

## RsphF: download

* Reference genome

```bash
BASE_NAME=RsphF
mkdir -p ${HOME}/data/anchr/${BASE_NAME}
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 1_genome
cd 1_genome

cp ~/data/anchr/Rsph/1_genome/genome.fa .
cp ~/data/anchr/Rsph/1_genome/paralogs.fas .

```

* Illumina

    SRX160386, SRR522246

```bash
BASE_NAME=RsphF
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina
cd 2_illumina

cat << EOF > sra_ftp.txt
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR522/SRR522246/SRR522246_1.fastq.gz
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR522/SRR522246/SRR522246_2.fastq.gz
EOF

aria2c -x 9 -s 3 -c -i sra_ftp.txt

cat << EOF > sra_md5.txt
a29e463504252388f9f381bd8659b084 SRR522246_1.fastq.gz
0e44d585f34c41681a7dcb25960ee273 SRR522246_2.fastq.gz
EOF

md5sum --check sra_md5.txt

ln -s SRR522246_1.fastq.gz R1.fq.gz
ln -s SRR522246_2.fastq.gz R2.fq.gz
```

* GAGE-B assemblies

```bash
BASE_NAME=RsphF
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 8_competitor
cd 8_competitor

cp ~/data/anchr/Rsph/8_competitor/* .

```

* FastQC

```bash
BASE_NAME=MabsF
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/fastqc
cd 2_illumina/fastqc

fastqc -t 16 \
    ../R1.fq.gz ../R2.fq.gz \
    -o .

```

## RsphF: combinations of different quality values and read lengths

* qual: 20, 25, and 30
* len: 60

```bash
BASE_NAME=RsphF
cd ${HOME}/data/anchr/${BASE_NAME}

if [ ! -e 2_illumina/R1.uniq.fq.gz ]; then
    tally \
        --pair-by-offset --with-quality --nozip --unsorted \
        -i 2_illumina/R1.fq.gz \
        -j 2_illumina/R2.fq.gz \
        -o 2_illumina/R1.uniq.fq \
        -p 2_illumina/R2.uniq.fq
    
    parallel --no-run-if-empty -j 2 "
            pigz -p 8 2_illumina/{}.uniq.fq
        " ::: R1 R2
fi

if [ ! -e 2_illumina/R1.shuffle.fq.gz ]; then
    shuffle.sh \
        in=2_illumina/R1.uniq.fq.gz \
        in2=2_illumina/R2.uniq.fq.gz \
        out=2_illumina/R1.shuffle.fq \
        out2=2_illumina/R2.shuffle.fq
    
    parallel --no-run-if-empty -j 2 "
            pigz -p 8 2_illumina/{}.shuffle.fq
        " ::: R1 R2
fi

# Down sampling to 300x
REAL_G=4602977
READ_COUNT=$(( 300 / 2 * ${REAL_G} / 251 ))
if [ ! -e 2_illumina/R1.200x.fq.gz ]; then
    parallel --no-run-if-empty -j 2 "
        seqtk sample \
            -s${READ_COUNT} \
            2_illumina/{}.shuffle.fq.gz \
            ${READ_COUNT} \
            | pigz -p 4 -c \
            > 2_illumina/{}.down.fq.gz
        " ::: R1 R2
fi

if [ ! -e 2_illumina/R1.scythe.fq.gz ]; then
    parallel --no-run-if-empty -j 2 "
        scythe \
            2_illumina/{}.down.fq.gz \
            -q sanger \
            -a /home/wangq/.plenv/versions/5.18.4/lib/perl5/site_perl/5.18.4/auto/share/dist/App-Anchr/illumina_adapters.fa \
            --quiet \
            | pigz -p 4 -c \
            > 2_illumina/{}.scythe.fq.gz
        " ::: R1 R2
fi

parallel --no-run-if-empty -j 3 "
    mkdir -p 2_illumina/Q{1}L{2}
    cd 2_illumina/Q{1}L{2}
    
    if [ -e R1.fq.gz ]; then
        echo '    R1.fq.gz already presents'
        exit;
    fi

    anchr trim \
        --noscythe \
        -q {1} -l {2} \
        ../R1.scythe.fq.gz ../R2.scythe.fq.gz \
        -o stdout \
        | bash
    " ::: 20 25 30 ::: 60

# Stats
printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat.md
printf "|:--|--:|--:|--:|\n" >> stat.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Paralogs"; faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Illumina"; faops n50 -H -S -C 2_illumina/R1.fq.gz 2_illumina/R2.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "uniq";     faops n50 -H -S -C 2_illumina/R1.uniq.fq.gz 2_illumina/R2.uniq.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "shuffle";  faops n50 -H -S -C 2_illumina/R1.shuffle.fq.gz 2_illumina/R2.shuffle.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "down";     faops n50 -H -S -C 2_illumina/R1.down.fq.gz 2_illumina/R2.down.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "scythe";   faops n50 -H -S -C 2_illumina/R1.scythe.fq.gz 2_illumina/R2.scythe.fq.gz;) >> stat.md

parallel -k --no-run-if-empty -j 3 "
    printf \"| %s | %s | %s | %s |\n\" \
        \$( 
            echo Q{1}L{2};
            if [[ {1} -ge '30' ]]; then
                faops n50 -H -S -C \
                    2_illumina/Q{1}L{2}/R1.fq.gz \
                    2_illumina/Q{1}L{2}/R2.fq.gz \
                    2_illumina/Q{1}L{2}/Rs.fq.gz;
            else
                faops n50 -H -S -C \
                    2_illumina/Q{1}L{2}/R1.fq.gz \
                    2_illumina/Q{1}L{2}/R2.fq.gz;
            fi
        )
    " ::: 20 25 30 ::: 60 \
    >> stat.md

cat stat.md

```

| Name     |     N50 |        Sum |        # |
|:---------|--------:|-----------:|---------:|
| Genome   | 3188524 |    4602977 |        7 |
| Paralogs |    2337 |     147155 |       66 |
| Illumina |     251 | 4237215336 | 16881336 |
| uniq     |     251 | 4199507606 | 16731106 |
| shuffle  |     251 | 4199507606 | 16731106 |
| down     |     251 | 1380893066 |  5501566 |
| scythe   |     251 | 1065413486 |  5501566 |
| Q20L60   |     145 |  536780836 |  3946238 |
| Q25L60   |     134 |  446183787 |  3541934 |
| Q30L60   |     117 |  388454569 |  3542857 |

## RsphF: quorum

```bash
BASE_NAME=RsphF
cd ${HOME}/data/anchr/${BASE_NAME}

parallel --no-run-if-empty -j 1 "
    cd 2_illumina/Q{1}L{2}
    echo >&2 '==> Group Q{1}L{2} <=='

    if [ ! -e R1.fq.gz ]; then
        echo >&2 '    R1.fq.gz not exists'
        exit;
    fi

    if [ -e pe.cor.fa ]; then
        echo >&2 '    pe.cor.fa exists'
        exit;
    fi

    if [[ {1} -ge '30' ]]; then
        anchr quorum \
            R1.fq.gz R2.fq.gz Rs.fq.gz \
            -p 16 \
            -o quorum.sh
    else
        anchr quorum \
            R1.fq.gz R2.fq.gz \
            -p 16 \
            -o quorum.sh
    fi

    bash quorum.sh
    
    echo >&2
    " ::: 20 25 30 ::: 60

# Stats of processed reads
REAL_G=4602977

bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 header \
    > stat1.md

parallel -k --no-run-if-empty -j 3 "
    if [ ! -d 2_illumina/Q{1}L{2} ]; then
        exit;
    fi

    bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 2_illumina/Q{1}L{2} ${REAL_G}
    " ::: 20 25 30 ::: 60 \
     >> stat1.md

cat stat1.md

```

| Name   |   SumIn | CovIn |  SumOut | CovOut | Discard% | AvgRead | Kmer | RealG |  EstG | Est/Real |   RunTime |
|:-------|--------:|------:|--------:|-------:|---------:|--------:|-----:|------:|------:|---------:|----------:|
| Q20L60 | 536.78M | 116.6 | 477.56M |  103.8 |  11.032% |     137 | "37" |  4.6M | 4.58M |     1.00 | 0:06'12'' |
| Q25L60 | 446.18M |  96.9 | 426.13M |   92.6 |   4.494% |     127 | "35" |  4.6M | 4.55M |     0.99 | 0:04'57'' |
| Q30L60 | 389.16M |  84.5 | 379.54M |   82.5 |   2.473% |     112 | "31" |  4.6M | 4.55M |     0.99 | 0:04'09'' |

* Clear intermediate files.

```bash
BASE_NAME=RsphF
cd $HOME/data/anchr/${BASE_NAME}

find 2_illumina -type f -name "quorum_mer_db.jf" | xargs rm
find 2_illumina -type f -name "k_u_hash_0"       | xargs rm
find 2_illumina -type f -name "*.tmp"            | xargs rm
find 2_illumina -type f -name "pe.renamed.fastq" | xargs rm
find 2_illumina -type f -name "se.renamed.fastq" | xargs rm
find 2_illumina -type f -name "pe.cor.sub.fa"    | xargs rm
```

* kmergenie

```bash
BASE_NAME=RsphF
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/kmergenie
cd 2_illumina/kmergenie

kmergenie -l 21 -k 151 -s 10 -t 8 ../R1.fq.gz -o oriR1
kmergenie -l 21 -k 151 -s 10 -t 8 ../R2.fq.gz -o oriR2
kmergenie -l 21 -k 151 -s 10 -t 8 ../Q20L60/pe.cor.fa -o Q20L60

```

## RsphF: down sampling

```bash
BASE_NAME=RsphF
cd ${HOME}/data/anchr/${BASE_NAME}

REAL_G=4602977

for QxxLxx in $( parallel "echo 'Q{1}L{2}'" ::: 20 25 30 ::: 60 ); do
    echo "==> ${QxxLxx}"

    if [ ! -e 2_illumina/${QxxLxx}/pe.cor.fa ]; then
        echo "2_illumina/${QxxLxx}/pe.cor.fa not exists"
        continue;
    fi

    for X in 40 80; do
        printf "==> Coverage: %s\n" ${X}
        
        rm -fr 2_illumina/${QxxLxx}X${X}*
    
        faops split-about -l 0 \
            2_illumina/${QxxLxx}/pe.cor.fa \
            $(( ${REAL_G} * ${X} )) \
            "2_illumina/${QxxLxx}X${X}"
        
        MAX_SERIAL=$(
            cat 2_illumina/${QxxLxx}/environment.json \
                | jq ".SUM_OUT | tonumber | . / ${REAL_G} / ${X} | floor | . - 1"
        )
        
        for i in $( seq 0 1 ${MAX_SERIAL} ); do
            P=$( printf "%03d" ${i})
            printf "  * Part: %s\n" ${P}
            
            mkdir -p "2_illumina/${QxxLxx}X${X}P${P}"
            
            mv  "2_illumina/${QxxLxx}X${X}/${P}.fa" \
                "2_illumina/${QxxLxx}X${X}P${P}/pe.cor.fa"
            cp 2_illumina/${QxxLxx}/environment.json "2_illumina/${QxxLxx}X${X}P${P}"
    
        done
    done
done

```

## RsphF: k-unitigs and anchors (sampled)

```bash
BASE_NAME=RsphF
cd ${HOME}/data/anchr/${BASE_NAME}

# k-unitigs (sampled)
parallel --no-run-if-empty -j 1 "
    echo >&2 '==> Group Q{1}L{2}X{3}P{4}'

    if [ ! -e 2_illumina/Q{1}L{2}X{3}P{4}/pe.cor.fa ]; then
        echo >&2 '    2_illumina/Q{1}L{2}X{3}P{4}/pe.cor.fa not exists'
        exit;
    fi

    if [ -e Q{1}L{2}X{3}P{4}/k_unitigs.fasta ]; then
        echo >&2 '    k_unitigs.fasta already presents'
        exit;
    fi

    mkdir -p Q{1}L{2}X{3}P{4}
    cd Q{1}L{2}X{3}P{4}

    anchr kunitigs \
        ../2_illumina/Q{1}L{2}X{3}P{4}/pe.cor.fa \
        ../2_illumina/Q{1}L{2}X{3}P{4}/environment.json \
        -p 16 \
        --kmer 31,41,51,61,71,81 \
        -o kunitigs.sh
    bash kunitigs.sh

    echo >&2
    " ::: 20 25 30 ::: 60 ::: 40 80 ::: 000 001 002 003 004 005

# anchors (sampled)
parallel --no-run-if-empty -j 3 "
    echo >&2 '==> Group Q{1}L{2}X{3}P{4}'

    if [ ! -e Q{1}L{2}X{3}P{4}/pe.cor.fa ]; then
        echo >&2 '    pe.cor.fa not exists'
        exit;
    fi

    if [ -e Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa ]; then
        echo >&2 '    k_unitigs.fasta already presents'
        exit;
    fi

    rm -fr Q{1}L{2}X{3}P{4}/anchor
    mkdir -p Q{1}L{2}X{3}P{4}/anchor
    cd Q{1}L{2}X{3}P{4}/anchor
    anchr anchors \
        ../pe.cor.fa \
        ../k_unitigs.fasta \
        -p 8 \
        -o anchors.sh
    bash anchors.sh
    
    echo >&2
    " ::: 20 25 30 ::: 60 ::: 40 80 ::: 000 001 002 003 004 005

# Stats of anchors
REAL_G=4602977

bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 header \
    > stat2.md

parallel -k --no-run-if-empty -j 6 "
    if [ ! -e Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa ]; then
        exit;
    fi

    bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 Q{1}L{2}X{3}P{4} ${REAL_G}
    " ::: 20 25 30 ::: 60 ::: 40 80 ::: 000 001 002 003 004 005 \
    >> stat2.md

cat stat2.md
```

| Name          |  SumCor | CovCor | N50SR |   Sum |   # | N50Anchor |   Sum |   # | N50Others |     Sum |   # |                Kmer | RunTimeKU | RunTimeAN |
|:--------------|--------:|-------:|------:|------:|----:|----------:|------:|----:|----------:|--------:|----:|--------------------:|----------:|:----------|
| Q20L60X40P000 | 184.12M |   40.0 | 16431 | 4.55M | 582 |     16523 | 4.48M | 486 |       740 |  68.47K |  96 | "31,41,51,61,71,81" | 0:03'25'' | 0:02'29'' |
| Q20L60X40P001 | 184.12M |   40.0 | 16649 | 4.56M | 596 |     17665 | 4.48M | 486 |       778 |  82.57K | 110 | "31,41,51,61,71,81" | 0:03'31'' | 0:02'31'' |
| Q20L60X80P000 | 368.24M |   80.0 | 12635 | 4.55M | 725 |     12869 | 4.44M | 580 |       765 | 105.47K | 145 | "31,41,51,61,71,81" | 0:05'31'' | 0:04'06'' |
| Q25L60X40P000 | 184.12M |   40.0 | 19595 | 4.54M | 448 |     19960 |  4.5M | 392 |       795 |  45.06K |  56 | "31,41,51,61,71,81" | 0:03'42'' | 0:02'32'' |
| Q25L60X40P001 | 184.12M |   40.0 | 20582 | 4.54M | 418 |     20698 |  4.5M | 372 |       752 |   33.9K |  46 | "31,41,51,61,71,81" | 0:03'40'' | 0:02'30'' |
| Q25L60X80P000 | 368.24M |   80.0 | 27777 | 4.55M | 344 |     27802 | 4.51M | 292 |       755 |  41.02K |  52 | "31,41,51,61,71,81" | 0:07'09'' | 0:03'46'' |
| Q30L60X40P000 | 184.12M |   40.0 | 12285 | 4.53M | 656 |     12365 | 4.46M | 564 |       757 |   67.6K |  92 | "31,41,51,61,71,81" | 0:05'18'' | 0:02'46'' |
| Q30L60X40P001 | 184.12M |   40.0 | 13794 | 4.54M | 584 |     13944 | 4.49M | 520 |       788 |  46.32K |  64 | "31,41,51,61,71,81" | 0:05'11'' | 0:02'51'' |
| Q30L60X80P000 | 368.24M |   80.0 | 18881 | 4.55M | 444 |     18924 | 4.51M | 395 |       773 |  36.98K |  49 | "31,41,51,61,71,81" | 0:07'00'' | 0:03'14'' |

## RsphF: merge anchors

```bash
BASE_NAME=RsphF
cd ${HOME}/data/anchr/${BASE_NAME}

# merge anchors
mkdir -p merge
anchr contained \
    $(
        parallel -k --no-run-if-empty -j 6 "
            if [ -e Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa ]; then
                echo Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa
            fi
            " ::: 20 25 30 ::: 60 ::: 40 80 ::: 000 001 002 003 004 005 006
    ) \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.contained.fasta
anchr orient merge/anchor.contained.fasta --len 1000 --idt 0.98 -o merge/anchor.orient.fasta
anchr merge merge/anchor.orient.fasta --len 1000 --idt 0.999 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.merge.fasta

# merge others
mkdir -p merge
anchr contained \
    $(
        parallel -k --no-run-if-empty -j 6 "
            if [ -e Q{1}L{2}X{3}P{4}/anchor/pe.others.fa ]; then
                echo Q{1}L{2}X{3}P{4}/anchor/pe.others.fa
            fi
            " ::: 20 25 30 ::: 60 ::: 40 80 ::: 000 001 002 003 004 005 006
    ) \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.contained.fasta
anchr orient merge/others.contained.fasta --len 1000 --idt 0.98 -o merge/others.orient.fasta
anchr merge merge/others.orient.fasta --len 1000 --idt 0.999 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.merge.fasta

# sort on ref
bash ~/Scripts/cpan/App-Anchr/share/sort_on_ref.sh merge/anchor.merge.fasta 1_genome/genome.fa merge/anchor.sort
nucmer -l 200 1_genome/genome.fa merge/anchor.sort.fa
mummerplot -png out.delta -p anchor.sort --large

# mummerplot files
rm *.[fr]plot
rm out.delta
rm *.gp

mv anchor.sort.png merge/

# quast
rm -fr 9_qa
quast --no-check --threads 16 \
    -R 1_genome/genome.fa \
    8_competitor/abyss_ctg.fasta \
    8_competitor/cabog_ctg.fasta \
    8_competitor/mira_ctg.fasta \
    8_competitor/msrca_ctg.fasta \
    8_competitor/sga_ctg.fasta \
    8_competitor/soap_ctg.fasta \
    8_competitor/spades_ctg.fasta \
    8_competitor/velvet_ctg.fasta \
    merge/anchor.merge.fasta \
    1_genome/paralogs.fas \
    --label "abyss,cabog,mira,msrca,sga,soap,spades,velvet,merge,paralogs" \
    -o 9_qa

```

* Stats

```bash
BASE_NAME=RsphF
cd ${HOME}/data/anchr/${BASE_NAME}

printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat3.md
printf "|:--|--:|--:|--:|\n" >> stat3.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Paralogs";   faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchor.merge"; faops n50 -H -S -C merge/anchor.merge.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "others.merge"; faops n50 -H -S -C merge/others.merge.fasta;) >> stat3.md

cat stat3.md
```

| Name         |     N50 |     Sum |   # |
|:-------------|--------:|--------:|----:|
| Genome       | 3188524 | 4602977 |   7 |
| Paralogs     |    2337 |  147155 |  66 |
| anchor.merge |   44642 | 4539106 | 206 |
| others.merge |    1154 |   21928 |  18 |

* Clear QxxLxxXxx.

```bash
BASE_NAME=RsphF
cd ${HOME}/data/anchr/${BASE_NAME}

rm -fr 2_illumina/Q{20,25,30}L{1,60,90,120}X*
rm -fr Q{20,25,30}L{1,60,90,120}X*
```

# *Vibrio cholerae* CP1032(5) Full

## VchoF: download

* Reference genome

```bash
BASE_NAME=VchoF
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 1_genome
cd 1_genome

cp ~/data/anchr/Vcho/1_genome/genome.fa .
cp ~/data/anchr/Vcho/1_genome/paralogs.fas .

```

* Illumina

    SRX247310, SRR769320

```bash
mkdir -p ~/data/anchr/Vcho/2_illumina
cd ~/data/anchr/Vcho/2_illumina

cat << EOF > sra_ftp.txt
ftp://ftp.sra.ebi.ac.uk/vol1/srr/SRR769/SRR769320
EOF

aria2c -x 9 -s 3 -c -i sra_ftp.txt

cat << EOF > sra_md5.txt
28f49ca6ae9a00c3a7937e00e04e8512        SRR769320
EOF

md5sum --check sra_md5.txt

fastq-dump --split-files ./SRR769320  
find . -name "*.fastq" | parallel -j 2 pigz -p 8

ln -s SRR769320_1.fastq.gz R1.fq.gz
ln -s SRR769320_2.fastq.gz R2.fq.gz
```

* GAGE-B assemblies

```bash
BASE_NAME=VchoF
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 8_competitor
cd 8_competitor

cp ~/data/anchr/Vcho/8_competitor/* .

```

* FastQC

```bash
BASE_NAME=VchoF
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/fastqc
cd 2_illumina/fastqc

fastqc -t 16 \
    ../R1.fq.gz ../R2.fq.gz \
    -o .

```

## VchoF: combinations of different quality values and read lengths

* qual: 20, 25, 30, and 35
* len: 60

```bash
BASE_NAME=VchoF
REAL_G=4033464
SAMPLING_COVERAGE=200
cd ${HOME}/data/anchr/${BASE_NAME}

if [ ! -e 2_illumina/R1.uniq.fq.gz ]; then
    tally \
        --pair-by-offset --with-quality --nozip --unsorted \
        -i 2_illumina/R1.fq.gz \
        -j 2_illumina/R2.fq.gz \
        -o 2_illumina/R1.uniq.fq \
        -p 2_illumina/R2.uniq.fq
    
    parallel --no-run-if-empty -j 2 "
            pigz -p 4 2_illumina/{}.uniq.fq
        " ::: R1 R2
fi

# Down sampling
READ_COUNT=$(( ${SAMPLING_COVERAGE} / 2 * ${REAL_G} / 251 ))
if [ ! -e 2_illumina/R1.down.fq.gz ]; then
    parallel --no-run-if-empty -j 2 "
        seqtk sample \
            -s${READ_COUNT} \
            2_illumina/{}.uniq.fq.gz \
            ${READ_COUNT} \
            | pigz -p 4 -c \
            > 2_illumina/{}.down.fq.gz
        " ::: R1 R2
fi

if [ ! -e 2_illumina/R1.scythe.fq.gz ]; then
    parallel --no-run-if-empty -j 2 "
        scythe \
            2_illumina/{}.down.fq.gz \
            -q sanger \
            -a /home/wangq/.plenv/versions/5.18.4/lib/perl5/site_perl/5.18.4/auto/share/dist/App-Anchr/illumina_adapters.fa \
            --quiet \
            | pigz -p 4 -c \
            > 2_illumina/{}.scythe.fq.gz
        " ::: R1 R2
fi

parallel --no-run-if-empty -j 3 "
    mkdir -p 2_illumina/Q{1}L{2}
    cd 2_illumina/Q{1}L{2}
    
    if [ -e R1.fq.gz ]; then
        echo '    R1.fq.gz already presents'
        exit;
    fi

    anchr trim \
        --noscythe \
        -q {1} -l {2} \
        ../R1.scythe.fq.gz ../R2.scythe.fq.gz \
        -o stdout \
        | bash
    " ::: 20 25 30 35 ::: 60

# Stats
printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat.md
printf "|:--|--:|--:|--:|\n" >> stat.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Paralogs"; faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Illumina"; faops n50 -H -S -C 2_illumina/R1.fq.gz 2_illumina/R2.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "uniq";     faops n50 -H -S -C 2_illumina/R1.uniq.fq.gz 2_illumina/R2.uniq.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "down";     faops n50 -H -S -C 2_illumina/R1.down.fq.gz 2_illumina/R2.down.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "scythe";   faops n50 -H -S -C 2_illumina/R1.scythe.fq.gz 2_illumina/R2.scythe.fq.gz;) >> stat.md

parallel -k --no-run-if-empty -j 3 "
    printf \"| %s | %s | %s | %s |\n\" \
        \$( 
            echo Q{1}L{2};
            if [[ {1} -ge '30' ]]; then
                faops n50 -H -S -C \
                    2_illumina/Q{1}L{2}/R1.fq.gz \
                    2_illumina/Q{1}L{2}/R2.fq.gz \
                    2_illumina/Q{1}L{2}/Rs.fq.gz;
            else
                faops n50 -H -S -C \
                    2_illumina/Q{1}L{2}/R1.fq.gz \
                    2_illumina/Q{1}L{2}/R2.fq.gz;
            fi
        )
    " ::: 20 25 30 35 ::: 60 \
    >> stat.md

cat stat.md
```

| Name     |     N50 |        Sum |       # |
|:---------|--------:|-----------:|--------:|
| Genome   | 2961149 |    4033464 |       2 |
| Paralogs |    3483 |     114707 |      48 |
| Illumina |     251 | 1762158050 | 7020550 |
| uniq     |     251 | 1727781592 | 6883592 |
| down     |     251 |  806692414 | 3213914 |
| scythe   |     198 |  613637861 | 3213914 |
| Q20L60   |     191 |  558809317 | 3046850 |
| Q25L60   |     188 |  513691780 | 2864002 |
| Q30L60   |     181 |  466029782 | 2737046 |
| Q35L60   |     156 |  310121409 | 2163038 |

## VchoF: quorum

```bash
BASE_NAME=VchoF
REAL_G=4033464
cd ${HOME}/data/anchr/${BASE_NAME}

parallel --no-run-if-empty -j 1 "
    cd 2_illumina/Q{1}L{2}
    echo >&2 '==> Group Q{1}L{2} <=='

    if [ ! -e R1.fq.gz ]; then
        echo >&2 '    R1.fq.gz not exists'
        exit;
    fi

    if [ -e pe.cor.fa ]; then
        echo >&2 '    pe.cor.fa exists'
        exit;
    fi

    if [[ {1} -ge '30' ]]; then
        anchr quorum \
            R1.fq.gz R2.fq.gz Rs.fq.gz \
            -p 16 \
            -o quorum.sh
    else
        anchr quorum \
            R1.fq.gz R2.fq.gz \
            -p 16 \
            -o quorum.sh
    fi

    bash quorum.sh
    
    echo >&2
    " ::: 20 25 30 35 ::: 60

# Stats of processed reads
bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 header \
    > stat1.md

parallel -k --no-run-if-empty -j 3 "
    if [ ! -d 2_illumina/Q{1}L{2} ]; then
        exit;
    fi

    bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 2_illumina/Q{1}L{2} ${REAL_G}
    " ::: 20 25 30 35 ::: 60 \
     >> stat1.md

cat stat1.md

```

| Name   |   SumIn | CovIn |  SumOut | CovOut | Discard% | AvgRead |  Kmer | RealG |  EstG | Est/Real |   RunTime |
|:-------|--------:|------:|--------:|-------:|---------:|--------:|------:|------:|------:|---------:|----------:|
| Q20L60 | 558.81M | 138.5 | 449.06M |  111.3 |  19.639% |     183 | "111" | 4.03M | 4.05M |     1.00 | 0:01'45'' |
| Q25L60 | 513.69M | 127.4 | 435.83M |  108.1 |  15.156% |     179 | "109" | 4.03M | 4.01M |     0.99 | 0:01'42'' |
| Q30L60 | 466.22M | 115.6 | 411.28M |  102.0 |  11.783% |     173 | "103" | 4.03M | 3.98M |     0.99 | 0:01'35'' |
| Q35L60 | 310.41M |  77.0 | 291.79M |   72.3 |   6.001% |     147 |  "83" | 4.03M | 3.94M |     0.98 | 0:01'05'' |

* Clear intermediate files.

```bash
BASE_NAME=VchoF
cd $HOME/data/anchr/${BASE_NAME}

find 2_illumina -type f -name "quorum_mer_db.jf" | xargs rm
find 2_illumina -type f -name "k_u_hash_0"       | xargs rm
find 2_illumina -type f -name "*.tmp"            | xargs rm
find 2_illumina -type f -name "pe.renamed.fastq" | xargs rm
find 2_illumina -type f -name "se.renamed.fastq" | xargs rm
find 2_illumina -type f -name "pe.cor.sub.fa"    | xargs rm
```

* kmergenie

```bash
BASE_NAME=VchoF
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/kmergenie
cd 2_illumina/kmergenie

kmergenie -l 21 -k 151 -s 10 -t 8 ../R1.fq.gz -o oriR1
kmergenie -l 21 -k 151 -s 10 -t 8 ../R2.fq.gz -o oriR2
kmergenie -l 21 -k 151 -s 10 -t 8 ../Q20L60/pe.cor.fa -o Q20L60

```

## VchoF: down sampling

```bash
BASE_NAME=VchoF
REAL_G=4033464
cd ${HOME}/data/anchr/${BASE_NAME}

for QxxLxx in $( parallel "echo 'Q{1}L{2}'" ::: 20 25 30 35 ::: 60 ); do
    echo "==> ${QxxLxx}"

    if [ ! -e 2_illumina/${QxxLxx}/pe.cor.fa ]; then
        echo "2_illumina/${QxxLxx}/pe.cor.fa not exists"
        continue;
    fi

    for X in 40 80; do
        printf "==> Coverage: %s\n" ${X}
        
        rm -fr 2_illumina/${QxxLxx}X${X}*
    
        faops split-about -l 0 \
            2_illumina/${QxxLxx}/pe.cor.fa \
            $(( ${REAL_G} * ${X} )) \
            "2_illumina/${QxxLxx}X${X}"
        
        MAX_SERIAL=$(
            cat 2_illumina/${QxxLxx}/environment.json \
                | jq ".SUM_OUT | tonumber | . / ${REAL_G} / ${X} | floor | . - 1"
        )
        
        for i in $( seq 0 1 ${MAX_SERIAL} ); do
            P=$( printf "%03d" ${i})
            printf "  * Part: %s\n" ${P}
            
            mkdir -p "2_illumina/${QxxLxx}X${X}P${P}"
            
            mv  "2_illumina/${QxxLxx}X${X}/${P}.fa" \
                "2_illumina/${QxxLxx}X${X}P${P}/pe.cor.fa"
            cp 2_illumina/${QxxLxx}/environment.json "2_illumina/${QxxLxx}X${X}P${P}"
    
        done
    done
done

```

## VchoF: k-unitigs and anchors (sampled)

```bash
BASE_NAME=VchoF
REAL_G=4033464
cd ${HOME}/data/anchr/${BASE_NAME}

# k-unitigs (sampled)
parallel --no-run-if-empty -j 1 "
    echo >&2 '==> Group Q{1}L{2}X{3}P{4}'

    if [ ! -e 2_illumina/Q{1}L{2}X{3}P{4}/pe.cor.fa ]; then
        echo >&2 '    2_illumina/Q{1}L{2}X{3}P{4}/pe.cor.fa not exists'
        exit;
    fi

    if [ -e Q{1}L{2}X{3}P{4}/k_unitigs.fasta ]; then
        echo >&2 '    k_unitigs.fasta already presents'
        exit;
    fi

    mkdir -p Q{1}L{2}X{3}P{4}
    cd Q{1}L{2}X{3}P{4}

    anchr kunitigs \
        ../2_illumina/Q{1}L{2}X{3}P{4}/pe.cor.fa \
        ../2_illumina/Q{1}L{2}X{3}P{4}/environment.json \
        -p 16 \
        --kmer 31,41,51,61,71,81 \
        -o kunitigs.sh
    bash kunitigs.sh

    echo >&2
    " ::: 20 25 30 35 ::: 60 ::: 40 80 ::: 000 001 002 003 004 005

# anchors (sampled)
parallel --no-run-if-empty -j 3 "
    echo >&2 '==> Group Q{1}L{2}X{3}P{4}'

    if [ ! -e Q{1}L{2}X{3}P{4}/pe.cor.fa ]; then
        echo >&2 '    pe.cor.fa not exists'
        exit;
    fi

    if [ -e Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa ]; then
        echo >&2 '    k_unitigs.fasta already presents'
        exit;
    fi

    rm -fr Q{1}L{2}X{3}P{4}/anchor
    mkdir -p Q{1}L{2}X{3}P{4}/anchor
    cd Q{1}L{2}X{3}P{4}/anchor
    anchr anchors \
        ../pe.cor.fa \
        ../k_unitigs.fasta \
        -p 8 \
        -o anchors.sh
    bash anchors.sh
    
    echo >&2
    " ::: 20 25 30 35 ::: 60 ::: 40 80 ::: 000 001 002 003 004 005

# Stats of anchors
bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 header \
    > stat2.md

parallel -k --no-run-if-empty -j 6 "
    if [ ! -e Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa ]; then
        exit;
    fi

    bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 Q{1}L{2}X{3}P{4} ${REAL_G}
    " ::: 20 25 30 35 ::: 60 ::: 40 80 ::: 000 001 002 003 004 005 \
    >> stat2.md

cat stat2.md
```

| Name          |  SumCor | CovCor | N50SR |   Sum |    # | N50Anchor |   Sum |   # | N50Others |     Sum |   # |                Kmer | RunTimeKU | RunTimeAN |
|:--------------|--------:|-------:|------:|------:|-----:|----------:|------:|----:|----------:|--------:|----:|--------------------:|----------:|:----------|
| Q20L60X40P000 | 161.34M |   40.0 | 10485 | 3.93M |  672 |     10697 | 3.85M | 568 |       780 |  77.45K | 104 | "31,41,51,61,71,81" | 0:01'56'' | 0:00'52'' |
| Q20L60X40P001 | 161.34M |   40.0 | 10263 | 3.93M |  677 |     10523 | 3.84M | 552 |       772 |  90.95K | 125 | "31,41,51,61,71,81" | 0:01'53'' | 0:00'54'' |
| Q20L60X80P000 | 322.68M |   80.0 |  5651 | 3.93M | 1086 |      5916 | 3.79M | 885 |       780 | 149.39K | 201 | "31,41,51,61,71,81" | 0:03'00'' | 0:01'25'' |
| Q25L60X40P000 | 161.34M |   40.0 | 13227 | 3.94M |  546 |     13361 | 3.86M | 454 |       819 |  75.15K |  92 | "31,41,51,61,71,81" | 0:01'57'' | 0:01'03'' |
| Q25L60X40P001 | 161.34M |   40.0 | 13163 | 3.93M |  551 |     13878 | 3.85M | 441 |       757 |  78.78K | 110 | "31,41,51,61,71,81" | 0:01'56'' | 0:01'07'' |
| Q25L60X80P000 | 322.68M |   80.0 |  7475 | 3.94M |  871 |      7662 | 3.83M | 716 |       772 | 113.26K | 155 | "31,41,51,61,71,81" | 0:03'04'' | 0:01'32'' |
| Q30L60X40P000 | 161.34M |   40.0 | 14871 | 3.93M |  488 |     15216 | 3.86M | 396 |       757 |   65.6K |  92 | "31,41,51,61,71,81" | 0:01'54'' | 0:01'05'' |
| Q30L60X40P001 | 161.34M |   40.0 | 16194 | 3.93M |  482 |     16458 | 3.86M | 383 |       708 |   70.7K |  99 | "31,41,51,61,71,81" | 0:02'28'' | 0:01'02'' |
| Q30L60X80P000 | 322.68M |   80.0 |  9140 | 3.94M |  756 |      9270 | 3.84M | 622 |       766 |  98.53K | 134 | "31,41,51,61,71,81" | 0:03'49'' | 0:01'27'' |
| Q35L60X40P000 | 161.34M |   40.0 | 29728 | 3.93M |  318 |     30761 | 3.88M | 245 |       728 |  51.21K |  73 | "31,41,51,61,71,81" | 0:03'18'' | 0:01'07'' |

## VchoF: merge anchors

```bash
BASE_NAME=VchoF
cd ${HOME}/data/anchr/${BASE_NAME}

# merge anchors
mkdir -p merge
anchr contained \
    $(
        parallel -k --no-run-if-empty -j 6 "
            if [ -e Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa ]; then
                echo Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa
            fi
            " ::: 20 25 30 35 ::: 60 ::: 40 80 ::: 000 001 002 003 004 005 006
    ) \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.contained.fasta
anchr orient merge/anchor.contained.fasta --len 1000 --idt 0.98 -o merge/anchor.orient.fasta
anchr merge merge/anchor.orient.fasta --len 1000 --idt 0.999 -o merge/anchor.merge0.fasta
anchr contained merge/anchor.merge0.fasta --len 1000 --idt 0.98 \
    --proportion 0.99 --parallel 16 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.merge.fasta

# merge others
mkdir -p merge
anchr contained \
    $(
        parallel -k --no-run-if-empty -j 6 "
            if [ -e Q{1}L{2}X{3}P{4}/anchor/pe.others.fa ]; then
                echo Q{1}L{2}X{3}P{4}/anchor/pe.others.fa
            fi
            " ::: 20 25 30 35 ::: 60 ::: 40 80 ::: 000 001 002 003 004 005 006
    ) \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.contained.fasta
anchr orient merge/others.contained.fasta --len 1000 --idt 0.98 -o merge/others.orient.fasta
anchr merge merge/others.orient.fasta --len 1000 --idt 0.999 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.merge.fasta

# sort on ref
bash ~/Scripts/cpan/App-Anchr/share/sort_on_ref.sh merge/anchor.merge.fasta 1_genome/genome.fa merge/anchor.sort
nucmer -l 200 1_genome/genome.fa merge/anchor.sort.fa
mummerplot -png out.delta -p anchor.sort --large

# mummerplot files
rm *.[fr]plot
rm out.delta
rm *.gp

mv anchor.sort.png merge/

# quast
rm -fr 9_qa
quast --no-check --threads 16 \
    -R 1_genome/genome.fa \
    8_competitor/abyss_ctg.fasta \
    8_competitor/cabog_ctg.fasta \
    8_competitor/mira_ctg.fasta \
    8_competitor/msrca_ctg.fasta \
    8_competitor/sga_ctg.fasta \
    8_competitor/soap_ctg.fasta \
    8_competitor/spades_ctg.fasta \
    8_competitor/velvet_ctg.fasta \
    merge/anchor.merge.fasta \
    1_genome/paralogs.fas \
    --label "abyss,cabog,mira,msrca,sga,soap,spades,velvet,merge,paralogs" \
    -o 9_qa

```

* Stats

```bash
BASE_NAME=VchoF
cd ${HOME}/data/anchr/${BASE_NAME}

printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat3.md
printf "|:--|--:|--:|--:|\n" >> stat3.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Paralogs";   faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchor.merge"; faops n50 -H -S -C merge/anchor.merge.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "others.merge"; faops n50 -H -S -C merge/others.merge.fasta;) >> stat3.md

cat stat3.md
```

| Name         |     N50 |     Sum |   # |
|:-------------|--------:|--------:|----:|
| Genome       | 2961149 | 4033464 |   2 |
| Paralogs     |    3483 |  114707 |  48 |
| anchor.merge |   59780 | 3893974 | 136 |
| others.merge |    1058 |   24575 |  17 |

* Clear QxxLxxXxx.

```bash
BASE_NAME=VchoF
cd ${HOME}/data/anchr/${BASE_NAME}

rm -fr 2_illumina/Q{20,25,30,35}L{1,60,90,120}X*
rm -fr Q{20,25,30,35}L{1,60,90,120}X*
```
