# Bacteria 2+3

[TOC levels=1-3]: # " "
- [Bacteria 2+3](#bacteria-23)
- [Escherichia virus Lambda](#escherichia-virus-lambda)
    - [lambda: download](#lambda-download)
    - [lambda: preprocess PacBio reads](#lambda-preprocess-pacbio-reads)
    - [lambda: reads stats](#lambda-reads-stats)
    - [lambda: 3GS](#lambda-3gs)
- [Shigella flexneri NCTC0001, 福氏志贺氏菌](#shigella-flexneri-nctc0001-福氏志贺氏菌)
    - [Sfle: download](#sfle-download)
    - [Sfle: combinations of different quality values and read lengths](#sfle-combinations-of-different-quality-values-and-read-lengths)
    - [Sfle: down sampling](#sfle-down-sampling)
    - [Sfle: generate super-reads](#sfle-generate-super-reads)
    - [Sfle: create anchors](#sfle-create-anchors)
    - [Sfle: results](#sfle-results)
    - [Sfle: merge anchors](#sfle-merge-anchors)
    - [Sfle: 3GS](#sfle-3gs)
    - [Sfle: expand anchors](#sfle-expand-anchors)
- [Vibrio parahaemolyticus ATCC BAA-239, 副溶血弧菌](#vibrio-parahaemolyticus-atcc-baa-239-副溶血弧菌)
    - [Vpar: download](#vpar-download)
    - [Vpar: combinations of different quality values and read lengths](#vpar-combinations-of-different-quality-values-and-read-lengths)
    - [Vpar: down sampling](#vpar-down-sampling)
    - [Vpar: generate super-reads](#vpar-generate-super-reads)
    - [Vpar: create anchors](#vpar-create-anchors)
    - [Vpar: results](#vpar-results)
    - [Vpar: merge anchors](#vpar-merge-anchors)
    - [Vpar: 3GS](#vpar-3gs)
    - [Vpar: expand anchors](#vpar-expand-anchors)
- [Legionella pneumophila subsp. pneumophila ATCC 33152D-5; Philadelphia-1, 嗜肺军团菌](#legionella-pneumophila-subsp-pneumophila-atcc-33152d-5-philadelphia-1-嗜肺军团菌)
    - [Lpne: download](#lpne-download)
    - [Lpne: combinations of different quality values and read lengths](#lpne-combinations-of-different-quality-values-and-read-lengths)
    - [Lpne: down sampling](#lpne-down-sampling)
    - [Lpne: generate super-reads](#lpne-generate-super-reads)
    - [Lpne: create anchors](#lpne-create-anchors)
    - [Lpne: results](#lpne-results)
    - [Lpne: merge anchors](#lpne-merge-anchors)
    - [Lpne: 3GS](#lpne-3gs)
    - [Lpne: expand anchors](#lpne-expand-anchors)
- [Neisseria gonorrhoeae FDAARGOS_207, 淋病奈瑟氏菌](#neisseria-gonorrhoeae-fdaargos-207-淋病奈瑟氏菌)
    - [Ngon: download](#ngon-download)
    - [Ngon: combinations of different quality values and read lengths](#ngon-combinations-of-different-quality-values-and-read-lengths)
    - [Ngon: down sampling](#ngon-down-sampling)
    - [Ngon: generate super-reads](#ngon-generate-super-reads)
    - [Ngon: create anchors](#ngon-create-anchors)
    - [Ngon: results](#ngon-results)
    - [Ngon: merge anchors](#ngon-merge-anchors)
    - [Ngon: 3GS](#ngon-3gs)
    - [Ngon: expand anchors](#ngon-expand-anchors)
- [Neisseria meningitidis FDAARGOS_209, 脑膜炎奈瑟氏菌](#neisseria-meningitidis-fdaargos-209-脑膜炎奈瑟氏菌)
    - [Nmen: download](#nmen-download)
    - [Nmen: combinations of different quality values and read lengths](#nmen-combinations-of-different-quality-values-and-read-lengths)
    - [Nmen: quorum](#nmen-quorum)
    - [Nmen: down sampling](#nmen-down-sampling)
    - [Nmen: k-unitigs and anchors (sampled)](#nmen-k-unitigs-and-anchors-sampled)
    - [Nmen: merge anchors](#nmen-merge-anchors)
    - [Nmen: 3GS](#nmen-3gs)
    - [Nmen: expand anchors](#nmen-expand-anchors)
- [Bordetella pertussis FDAARGOS_195, 百日咳博德特氏杆菌](#bordetella-pertussis-fdaargos-195-百日咳博德特氏杆菌)
    - [Bper: download](#bper-download)
    - [Bper: combinations of different quality values and read lengths](#bper-combinations-of-different-quality-values-and-read-lengths)
    - [Bper: down sampling](#bper-down-sampling)
    - [Bper: generate super-reads](#bper-generate-super-reads)
    - [Bper: create anchors](#bper-create-anchors)
    - [Bper: results](#bper-results)
    - [Bper: merge anchors](#bper-merge-anchors)
- [Corynebacterium diphtheriae FDAARGOS_197, 白喉杆菌](#corynebacterium-diphtheriae-fdaargos-197-白喉杆菌)
    - [Cdip: download](#cdip-download)
    - [Cdip: combinations of different quality values and read lengths](#cdip-combinations-of-different-quality-values-and-read-lengths)
    - [Cdip: quorum](#cdip-quorum)
    - [Cdip: down sampling](#cdip-down-sampling)
    - [Cdip: k-unitigs and anchors (sampled)](#cdip-k-unitigs-and-anchors-sampled)
    - [Cdip: merge anchors](#cdip-merge-anchors)
    - [Cdip: 3GS](#cdip-3gs)
    - [Cdip: expand anchors](#cdip-expand-anchors)
- [Francisella tularensis FDAARGOS_247, 土拉热弗朗西斯氏菌](#francisella-tularensis-fdaargos-247-土拉热弗朗西斯氏菌)
    - [Ftul: download](#ftul-download)
    - [Ftul: combinations of different quality values and read lengths](#ftul-combinations-of-different-quality-values-and-read-lengths)
    - [Ftul: quorum](#ftul-quorum)
    - [Ftul: down sampling](#ftul-down-sampling)
    - [Ftul: k-unitigs and anchors (sampled)](#ftul-k-unitigs-and-anchors-sampled)
    - [Ftul: merge anchors](#ftul-merge-anchors)
    - [Ftul: 3GS](#ftul-3gs)
    - [Ftul: expand anchors](#ftul-expand-anchors)
- [Haemophilus influenzae FDAARGOS_199, 流感嗜血杆菌](#haemophilus-influenzae-fdaargos-199-流感嗜血杆菌)
    - [Hinf: download](#hinf-download)
- [Listeria monocytogenes FDAARGOS_351, 单核细胞增生李斯特氏菌](#listeria-monocytogenes-fdaargos-351-单核细胞增生李斯特氏菌)
    - [Lmon: download](#lmon-download)
- [Clostridioides difficile 630](#clostridioides-difficile-630)
    - [Cdif: download](#cdif-download)
- [Campylobacter jejuni subsp. jejuni ATCC 700819, 空肠弯曲杆菌](#campylobacter-jejuni-subsp-jejuni-atcc-700819-空肠弯曲杆菌)
    - [Cjej: download](#cjej-download)


# Escherichia virus Lambda

Project
[SRP055199](https://trace.ncbi.nlm.nih.gov/Traces/sra/?study=SRP055199)

## lambda: download

* Reference genome

    * Strain: Escherichia virus Lambda (viruses)
    * Taxid: [10710](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id=10710&lvl=3&lin=f&keep=1&srchmode=1&unlock)
    * RefSeq assembly accession:
      [GCF_000840245.1](ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/840/245/GCF_000840245.1_ViralProj14204/GCF_000840245.1_ViralProj14204_assembly_report.txt)
    * Proportion of paralogs (> 1000 bp): 0.0

```bash
mkdir -p ~/data/anchr/lambda/1_genome
cd ~/data/anchr/lambda/1_genome

aria2c -x 9 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/840/245/GCF_000840245.1_ViralProj14204/GCF_000840245.1_ViralProj14204_genomic.fna.gz

TAB=$'\t'
cat <<EOF > replace.tsv
NC_001416.1${TAB}1
EOF

faops replace GCF_000840245.1_ViralProj14204_genomic.fna.gz replace.tsv genome.fa

#cp ~/data/anchr/paralogs/otherbac/Results/lambda/lambda.multi.fas paralogs.fas

```

* PacBio

```bash
mkdir -p ~/data/anchr/lambda/3_pacbio
cd ~/data/anchr/lambda/3_pacbio

cat << EOF > sra_ftp.txt
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR179/005/SRR1796325/SRR1796325.fastq.gz
EOF

aria2c -x 9 -s 3 -c -i sra_ftp.txt

cat << EOF > sra_md5.txt
2c663d7ea426eea0aaba9017e1a9168c SRR1796325.fastq.gz
EOF

md5sum --check sra_md5.txt

cd ~/data/anchr/lambda
faops filter -l 0 3_pacbio/SRR1796325.fastq.gz 3_pacbio/pacbio.fasta

```

## lambda: preprocess PacBio reads

```bash
BASE_NAME=lambda
cd ${HOME}/data/anchr/${BASE_NAME}

head -n 3000 3_pacbio/pacbio.fasta > 3_pacbio/pacbio.40x.fasta

anchr trimlong --parallel 16 -v \
    3_pacbio/pacbio.40x.fasta \
    -o 3_pacbio/pacbio.40x.trim.fasta

```

## lambda: reads stats

```bash
BASE_NAME=lambda
cd ${HOME}/data/anchr/${BASE_NAME}

printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat.md
printf "|:--|--:|--:|--:|\n" >> stat.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat.md
#printf "| %s | %s | %s | %s |\n" \
#    $(echo "Paralogs"; faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat.md
#
#printf "| %s | %s | %s | %s |\n" \
#    $(echo "Illumina"; faops n50 -H -S -C 2_illumina/R1.fq.gz 2_illumina/R2.fq.gz;) >> stat.md
#printf "| %s | %s | %s | %s |\n" \
#    $(echo "uniq";     faops n50 -H -S -C 2_illumina/R1.uniq.fq.gz 2_illumina/R2.uniq.fq.gz;) >> stat.md
#
#parallel -k --no-run-if-empty -j 3 "
#    printf \"| %s | %s | %s | %s |\n\" \
#        \$( 
#            echo Q{1}L{2};
#            if [[ {1} -ge '30' ]]; then
#                faops n50 -H -S -C \
#                    2_illumina/Q{1}L{2}/R1.fq.gz \
#                    2_illumina/Q{1}L{2}/R2.fq.gz \
#                    2_illumina/Q{1}L{2}/Rs.fq.gz;
#            else
#                faops n50 -H -S -C \
#                    2_illumina/Q{1}L{2}/R1.fq.gz \
#                    2_illumina/Q{1}L{2}/R2.fq.gz;
#            fi
#        )
#    " ::: 20 25 30 35 ::: 60 \
#    >> stat.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "PacBio";    faops n50 -H -S -C 3_pacbio/pacbio.fasta;) >> stat.md

parallel -k --no-run-if-empty -j 3 "
    printf \"| %s | %s | %s | %s |\n\" \
        \$( 
            echo PacBio.{};
            faops n50 -H -S -C \
                3_pacbio/pacbio.{}.fasta;
        )
    " ::: 40x 40x.trim \
    >> stat.md

cat stat.md

```

| Name            |   N50 |      Sum |    # |
|:----------------|------:|---------:|-----:|
| Genome          | 48502 |    48502 |    1 |
| PacBio          |  1325 | 11945526 | 9796 |
| PacBio.40x      |  1365 |  1896887 | 1500 |
| PacBio.40x.trim |  1452 |  1509584 | 1054 |

## lambda: 3GS

* miniasm

```bash
BASE_NAME=lambda
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p miniasm

minimap -Sw5 -L100 -m0 -t16 \
    ~/data/anchr/e_coli/anchorLong/group/11_2.long.fasta ~/data/anchr/e_coli/anchorLong/group/11_2.long.fasta \
    > miniasm/pacbio.40x.paf

sftp://wangq@wq.nju.edu.cn

miniasm miniasm/pacbio.40x.paf > miniasm/utg.noseq.gfa

miniasm -f 3_pacbio/pacbio.40x.fasta miniasm/pacbio.40x.paf \
    > miniasm/utg.gfa

awk '/^S/{print ">"$2"\n"$3}' miniasm/utg.gfa > miniasm/utg.fa

minimap 1_genome/genome.fa miniasm/utg.fa | minidot - > miniasm/utg.eps

```


# Shigella flexneri NCTC0001, 福氏志贺氏菌

Project
[ERP005470](https://trace.ncbi.nlm.nih.gov/Traces/sra/?study=ERP005470)

## Sfle: download

* Reference genome

    * Strain: Shigella flexneri 2a str. 301
    * Taxid: [198214](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=198214)
    * RefSeq assembly accession:
      [GCF_000006925.2](ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/925/GCF_000006925.2_ASM692v2/GCF_000006925.2_ASM692v2_assembly_report.txt)
    * Proportion of paralogs (> 1000 bp): 0.0870

```bash
mkdir -p ~/data/anchr/Sfle/1_genome
cd ~/data/anchr/Sfle/1_genome

aria2c -x 9 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/925/GCF_000006925.2_ASM692v2/GCF_000006925.2_ASM692v2_genomic.fna.gz

TAB=$'\t'
cat <<EOF > replace.tsv
NC_004337.2${TAB}1
NC_004851.1${TAB}pCP301
EOF

faops replace GCF_000006925.2_ASM692v2_genomic.fna.gz replace.tsv genome.fa

cp ~/data/anchr/paralogs/otherbac/Results/Sfle/Sfle.multi.fas paralogs.fas

```

* Illumina

    * [ERX518562](https://www.ncbi.nlm.nih.gov/sra/ERX518562)

```bash
mkdir -p ~/data/anchr/Sfle/2_illumina
cd ~/data/anchr/Sfle/2_illumina

cat << EOF > sra_ftp.txt
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR559/ERR559526/ERR559526_1.fastq.gz
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR559/ERR559526/ERR559526_2.fastq.gz
EOF

aria2c -x 9 -s 3 -c -i sra_ftp.txt

cat << EOF > sra_md5.txt
b79fa3fd3b2fb0370e12b8eb910c0268    ERR559526_1.fastq.gz
30c98d66d10d194c62ace652e757c0f3    ERR559526_2.fastq.gz
EOF

md5sum --check sra_md5.txt

ln -s ERR559526_1.fastq.gz R1.fq.gz
ln -s ERR559526_2.fastq.gz R2.fq.gz

```

* PacBio

```bash
mkdir -p ~/data/anchr/Sfle/3_pacbio
cd ~/data/anchr/Sfle/3_pacbio

# download from sra
cat <<EOF > hdf5.txt
http://sra-download.ncbi.nlm.nih.gov/srapub_files/ERR569654_ERR569654_hdf5.tgz
http://sra-download.ncbi.nlm.nih.gov/srapub_files/ERR569655_ERR569655_hdf5.tgz
http://sra-download.ncbi.nlm.nih.gov/srapub_files/ERR569656_ERR569656_hdf5.tgz
http://sra-download.ncbi.nlm.nih.gov/srapub_files/ERR569657_ERR569657_hdf5.tgz
http://sra-download.ncbi.nlm.nih.gov/srapub_files/ERR569658_ERR569658_hdf5.tgz
EOF
aria2c -x 9 -s 3 -c -i hdf5.txt

# untar
mkdir -p ~/data/anchr/Sfle/3_pacbio/untar
cd ~/data/anchr/Sfle/3_pacbio
tar xvfz ERR569654_ERR569654_hdf5.tgz --directory untar

# convert .bax.h5 to .subreads.bam
mkdir -p ~/data/anchr/Sfle/3_pacbio/bam
cd ~/data/anchr/Sfle/3_pacbio/bam

source ~/share/pitchfork/deployment/setup-env.sh
for movie in m140529;
do 
    bax2bam ~/data/anchr/Sfle/3_pacbio/untar/${movie}*.bax.h5
done

# convert .subreads.bam to fasta
mkdir -p ~/data/anchr/Sfle/3_pacbio/fasta

for movie in m140529;
do
    if [ ! -e ~/data/anchr/Sfle/3_pacbio/bam/${movie}*.subreads.bam ]; then
        continue
    fi

    samtools fasta \
        ~/data/anchr/Sfle/3_pacbio/bam/${movie}*.subreads.bam \
        > ~/data/anchr/Sfle/3_pacbio/fasta/${movie}.fasta
done

cd ~/data/anchr/Sfle
cat 3_pacbio/fasta/*.fasta > 3_pacbio/pacbio.fasta

rm -fr ~/data/anchr/Sfle/3_pacbio/untar
```

## Sfle: combinations of different quality values and read lengths

* qual: 20, 25, and 30
* len: 60 and 90

```bash
BASE_DIR=$HOME/data/anchr/Sfle

cd ${BASE_DIR}
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

cd ${BASE_DIR}
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

cd ${BASE_DIR}
parallel --no-run-if-empty -j 4 "
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
BASE_DIR=$HOME/data/anchr/Sfle
cd ${BASE_DIR}

printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat.md
printf "|:--|--:|--:|--:|\n" >> stat.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Paralogs";   faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Illumina"; faops n50 -H -S -C 2_illumina/R1.fq.gz 2_illumina/R2.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "PacBio";   faops n50 -H -S -C 3_pacbio/pacbio.fasta;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "uniq";   faops n50 -H -S -C 2_illumina/R1.uniq.fq.gz 2_illumina/R2.uniq.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "scythe";   faops n50 -H -S -C 2_illumina/R1.scythe.fq.gz 2_illumina/R2.scythe.fq.gz;) >> stat.md

for qual in 20 25 30; do
    for len in 60 90; do
        DIR_COUNT="${BASE_DIR}/2_illumina/Q${qual}L${len}"

        printf "| %s | %s | %s | %s |\n" \
            $(echo "Q${qual}L${len}"; faops n50 -H -S -C ${DIR_COUNT}/R1.fq.gz  ${DIR_COUNT}/R2.fq.gz;) \
            >> stat.md
    done
done

cat stat.md
```

| Name     |     N50 |       Sum |       # |
|:---------|--------:|----------:|--------:|
| Genome   | 4607202 |   4828820 |       2 |
| Paralogs |    1377 |    543111 |     334 |
| Illumina |     150 | 346446900 | 2309646 |
| PacBio   |    3333 | 432566566 |  170957 |
| uniq     |     150 | 346176600 | 2307844 |
| scythe   |     150 | 346111063 | 2307844 |
| Q20L60   |     150 | 333654543 | 2241618 |
| Q20L90   |     150 | 330186360 | 2210410 |
| Q25L60   |     150 | 318498288 | 2147972 |
| Q25L90   |     150 | 313056345 | 2098682 |
| Q30L60   |     150 | 299305225 | 2026998 |
| Q30L90   |     150 | 292247140 | 1962820 |

## Sfle: down sampling

```bash
BASE_DIR=$HOME/data/anchr/Sfle
cd ${BASE_DIR}

ARRAY=(
    "2_illumina/Q20L60:Q20L60"
    "2_illumina/Q20L90:Q20L90"
    "2_illumina/Q25L60:Q25L60"
    "2_illumina/Q25L90:Q25L90"
    "2_illumina/Q30L60:Q30L60"
    "2_illumina/Q30L90:Q30L90"
)

for group in "${ARRAY[@]}" ; do
    
    GROUP_DIR=$(group=${group} perl -e '@p = split q{:}, $ENV{group}; print $p[0];')
    GROUP_ID=$( group=${group} perl -e '@p = split q{:}, $ENV{group}; print $p[1];')
    printf "==> %s \t %s\n" "$GROUP_DIR" "$GROUP_ID"

    echo "==> Group ${GROUP_ID}"
    DIR_COUNT="${BASE_DIR}/${GROUP_ID}"
    mkdir -p ${DIR_COUNT}
    
    if [ -e ${DIR_COUNT}/R1.fq.gz ]; then
        continue     
    fi
    
    ln -s ${BASE_DIR}/${GROUP_DIR}/R1.fq.gz ${DIR_COUNT}/R1.fq.gz
    ln -s ${BASE_DIR}/${GROUP_DIR}/R2.fq.gz ${DIR_COUNT}/R2.fq.gz

done
```

```bash
BASE_DIR=$HOME/data/anchr/Sfle
cd ${BASE_DIR}

head -n 160000 3_pacbio/pacbio.fasta > 3_pacbio/pacbio.40x.fasta
faops n50 -S -C 3_pacbio/pacbio.40x.fasta

head -n 320000 3_pacbio/pacbio.fasta > 3_pacbio/pacbio.80x.fasta
faops n50 -S -C 3_pacbio/pacbio.80x.fasta

```

## Sfle: generate super-reads

```bash
BASE_DIR=$HOME/data/anchr/Sfle
cd ${BASE_DIR}

perl -e '
    for my $n (
        qw{
        Q20L60 Q20L90
        Q25L60 Q25L90
        Q30L60 Q30L90
        }
        )
    {
        printf qq{%s\n}, $n;
    }
    ' \
    | parallel --no-run-if-empty -j 3 "
        echo '==> Group {}'
        
        if [ ! -d ${BASE_DIR}/{} ]; then
            echo '    directory not exists'
            exit;
        fi        

        if [ -e ${BASE_DIR}/{}/k_unitigs.fasta ]; then
            echo '    k_unitigs.fasta already presents'
            exit;
        fi

        cd ${BASE_DIR}/{}
        anchr superreads \
            R1.fq.gz R2.fq.gz \
            --nosr -p 8 \
            --kmer 41,61,81,101,121 \
           -o superreads.sh
        bash superreads.sh
    "

```

Clear intermediate files.

```bash
BASE_DIR=$HOME/data/anchr/Sfle
cd ${BASE_DIR}

find . -type f -name "quorum_mer_db.jf"          | xargs rm
find . -type f -name "k_u_hash_0"                | xargs rm
find . -type f -name "readPositionsInSuperReads" | xargs rm
find . -type f -name "*.tmp"                     | xargs rm
find . -type f -name "pe.renamed.fastq"          | xargs rm
find . -type f -name "pe.cor.sub.fa"             | xargs rm
```

## Sfle: create anchors

```bash
BASE_DIR=$HOME/data/anchr/Sfle
cd ${BASE_DIR}

perl -e '
    for my $n (
        qw{
        Q20L60 Q20L90
        Q25L60 Q25L90
        Q30L60 Q30L90
        }
        )
    {
        printf qq{%s\n}, $n;
    }
    ' \
    | parallel --no-run-if-empty -j 3 "
        echo '==> Group {}'

        if [ -e ${BASE_DIR}/{}/anchor/pe.anchor.fa ]; then
            exit;
        fi

        rm -fr ${BASE_DIR}/{}/anchor
        bash ~/Scripts/cpan/App-Anchr/share/anchor.sh ${BASE_DIR}/{} 8 false
    "

```

## Sfle: results

* Stats of super-reads

```bash
BASE_DIR=$HOME/data/anchr/Sfle
cd ${BASE_DIR}

REAL_G=4607202

bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 header \
    > ${BASE_DIR}/stat1.md

perl -e '
    for my $n (
        qw{
        Q20L60 Q20L90
        Q25L60 Q25L90
        Q30L60 Q30L90
        }
        )
    {
        printf qq{%s\n}, $n;
    }
    ' \
    | parallel -k --no-run-if-empty -j 4 "
        if [ ! -d ${BASE_DIR}/{} ]; then
            exit;
        fi

        bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 ${BASE_DIR}/{} ${REAL_G}
    " >> ${BASE_DIR}/stat1.md

cat stat1.md
```

* Stats of anchors

```bash
BASE_DIR=$HOME/data/anchr/Sfle
cd ${BASE_DIR}

bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 header \
    > ${BASE_DIR}/stat2.md

perl -e '
    for my $n (
        qw{
        Q20L60 Q20L90
        Q25L60 Q25L90
        Q30L60 Q30L90
        }
        )
    {
        printf qq{%s\n}, $n;
    }
    ' \
    | parallel -k --no-run-if-empty -j 8 "
        if [ ! -e ${BASE_DIR}/{}/anchor/pe.anchor.fa ]; then
            exit;
        fi

        bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 ${BASE_DIR}/{}
    " >> ${BASE_DIR}/stat2.md

cat stat2.md
```

| Name   |   SumFq | CovFq | AvgRead |               Kmer |   SumFa | Discard% | RealG |  EstG | Est/Real | SumKU | SumSR |   RunTime |
|:-------|--------:|------:|--------:|-------------------:|--------:|---------:|------:|------:|---------:|------:|------:|----------:|
| Q20L60 | 333.65M |  72.4 |     148 | "41,61,81,101,121" | 307.96M |   7.702% | 4.61M | 4.22M |     0.92 | 4.26M |     0 | 0:04'30'' |
| Q20L90 | 330.19M |  71.7 |     149 | "41,61,81,101,121" | 305.44M |   7.493% | 4.61M | 4.21M |     0.91 | 4.26M |     0 | 0:04'36'' |
| Q25L60 |  318.5M |  69.1 |     148 | "41,61,81,101,121" | 301.45M |   5.353% | 4.61M | 4.19M |     0.91 | 4.22M |     0 | 0:04'29'' |
| Q25L90 | 313.06M |  67.9 |     149 | "41,61,81,101,121" | 296.68M |   5.230% | 4.61M | 4.19M |     0.91 | 4.22M |     0 | 0:05'02'' |
| Q30L60 | 299.31M |  65.0 |     147 | "41,61,81,101,121" | 287.19M |   4.047% | 4.61M | 4.18M |     0.91 | 4.22M |     0 | 0:04'58'' |
| Q30L90 | 292.25M |  63.4 |     148 | "41,61,81,101,121" | 280.53M |   4.009% | 4.61M | 4.18M |     0.91 | 4.22M |     0 | 0:04'49'' |

| Name   | N50SR |   Sum |   # | N50Anchor |   Sum |   # | N50Others |    Sum |   # |   RunTime |
|:-------|------:|------:|----:|----------:|------:|----:|----------:|-------:|----:|----------:|
| Q20L60 |  8637 | 4.26M | 778 |      8821 | 4.17M | 660 |       765 | 87.11K | 118 | 0:00'51'' |
| Q20L90 |  9406 | 4.26M | 725 |      9482 | 4.18M | 615 |       766 | 80.73K | 110 | 0:00'53'' |
| Q25L60 | 19847 | 4.22M | 398 |     20462 | 4.18M | 337 |       770 | 44.81K |  61 | 0:00'58'' |
| Q25L90 | 21495 | 4.22M | 378 |     21517 | 4.18M | 321 |       765 | 41.64K |  57 | 0:00'56'' |
| Q30L60 | 29285 | 4.22M | 316 |     29285 | 4.18M | 264 |       760 | 37.42K |  52 | 0:00'57'' |
| Q30L90 | 29285 | 4.22M | 314 |     29570 | 4.18M | 261 |       760 | 37.88K |  53 | 0:00'56'' |

## Sfle: merge anchors

```bash
BASE_DIR=$HOME/data/anchr/Sfle
cd ${BASE_DIR}

# merge anchors
mkdir -p merge
anchr contained \
    Q20L60/anchor/pe.anchor.fa \
    Q20L90/anchor/pe.anchor.fa \
    Q25L60/anchor/pe.anchor.fa \
    Q25L90/anchor/pe.anchor.fa \
    Q30L60/anchor/pe.anchor.fa \
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
    Q20L90/anchor/pe.others.fa \
    Q25L60/anchor/pe.others.fa \
    Q25L90/anchor/pe.others.fa \
    Q30L60/anchor/pe.others.fa \
    Q30L90/anchor/pe.others.fa \
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
    merge/anchor.merge.fasta \
    merge/others.merge.fasta \
    1_genome/paralogs.fas \
    --label "merge,others,paralogs" \
    -o 9_qa

```

## Sfle: 3GS

```bash
BASE_DIR=$HOME/data/anchr/Sfle
cd ${BASE_DIR}

canu \
    -p Sfle -d canu-raw-40x \
    gnuplot=$(brew --prefix)/Cellar/$(brew list --versions gnuplot | sed 's/ /\//')/bin/gnuplot \
    genomeSize=4.8m \
    -pacbio-raw 3_pacbio/pacbio.40x.fasta

canu \
    -p Sfle -d canu-raw-80x \
    gnuplot=$(brew --prefix)/Cellar/$(brew list --versions gnuplot | sed 's/ /\//')/bin/gnuplot \
    genomeSize=4.8m \
    -pacbio-raw 3_pacbio/pacbio.80x.fasta

faops n50 -S -C canu-raw-40x/Sfle.trimmedReads.fasta.gz
faops n50 -S -C canu-raw-80x/Sfle.trimmedReads.fasta.gz

```

## Sfle: expand anchors

* anchorLong

```bash
BASE_DIR=$HOME/data/anchr/Sfle
cd ${BASE_DIR}

anchr cover \
    --parallel 16 \
    -c 2 -m 40 \
    -b 20 --len 1000 --idt 0.9 \
    merge/anchor.merge.fasta \
    canu-raw-40x/Sfle.trimmedReads.fasta.gz \
    -o merge/anchor.cover.fasta

rm -fr anchorLong
anchr overlap2 \
    --parallel 16 \
    merge/anchor.cover.fasta \
    canu-raw-40x/Sfle.trimmedReads.fasta.gz \
    -d anchorLong \
    -b 20 --len 1000 --idt 0.98

anchr overlap \
    merge/anchor.cover.fasta \
    --serial --len 10 --idt 0.9999 \
    -o stdout \
    | perl -nla -e '
        BEGIN {
            our %seen;
            our %count_of;
        }

        @F == 13 or next;
        $F[3] > 0.9999 or next;

        my $pair = join( "-", sort { $a <=> $b } ( $F[0], $F[1], ) );
        next if $seen{$pair};
        $seen{$pair} = $_;

        $count_of{ $F[0] }++;
        $count_of{ $F[1] }++;

        END {
            for my $pair ( keys %seen ) {
                my ($f_id, $g_id) = split "-", $pair;
                next if $count_of{$f_id} > 2;
                next if $count_of{$g_id} > 2;
                print $seen{$pair};
            }
        }
    ' \
    | sort -k 1n,1n -k 2n,2n \
    > anchorLong/anchor.ovlp.tsv

ANCHOR_COUNT=$(faops n50 -H -N 0 -C anchorLong/anchor.fasta)
echo ${ANCHOR_COUNT}

rm -fr anchorLong/group
anchr group \
    anchorLong/anchorLong.db \
    anchorLong/anchorLong.ovlp.tsv \
    --oa anchorLong/anchor.ovlp.tsv \
    --parallel 16 \
    --range "1-${ANCHOR_COUNT}" --len 1000 --idt 0.98 --max "-14" -c 4 --png

pushd ${BASE_DIR}/anchorLong
cat group/groups.txt \
    | parallel --no-run-if-empty -j 8 '
        echo {};
        anchr orient \
            --len 1000 --idt 0.98 \
            group/{}.anchor.fasta \
            group/{}.long.fasta \
            -r group/{}.restrict.tsv \
            -o group/{}.strand.fasta;

        anchr overlap --len 1000 --idt 0.98 \
            group/{}.strand.fasta \
            -o stdout \
            | anchr restrict \
                stdin group/{}.restrict.tsv \
                -o group/{}.ovlp.tsv;

        anchr overlap --len 10 --idt 0.9999 \
            group/{}.strand.fasta \
            -o stdout \
            | perl -nla -e '\''
                @F == 13 or next;
                $F[3] > 0.98 or next;
                $F[9] == 0 or next;
                $F[5] > 0 and $F[6] == $F[7] or next;
                /anchor.+anchor/ or next;
                print;
            '\'' \
            > group/{}.anchor.ovlp.tsv
            
        anchr layout \
            group/{}.ovlp.tsv \
            group/{}.relation.tsv \
            group/{}.strand.fasta \
            --oa group/{}.anchor.ovlp.tsv \
            --png \
            -o group/{}.contig.fasta
    '
popd

# false strand
cat anchorLong/group/*.ovlp.tsv \
    | perl -nla -e '/anchor.+long/ or next; print $F[0] if $F[8] == 1;' \
    | sort | uniq -c

cat \
   anchorLong/group/non_grouped.fasta\
   anchorLong/group/*.contig.fasta \
   | faops filter -l 0 -a 1000 stdin anchorLong/contig.fasta

```

* contigTrim

```bash
BASE_DIR=$HOME/data/anchr/Sfle
cd ${BASE_DIR}

rm -fr contigTrim
anchr overlap2 \
    --parallel 16 \
    anchorLong/contig.fasta \
    canu-raw-40x/Sfle.contigs.fasta \
    -d contigTrim \
    -b 20 --len 1000 --idt 0.98 --all

CONTIG_COUNT=$(faops n50 -H -N 0 -C contigTrim/anchor.fasta)
echo ${CONTIG_COUNT}

rm -fr contigTrim/group
anchr group \
    --parallel 16 \
    --keep \
    contigTrim/anchorLong.db \
    contigTrim/anchorLong.ovlp.tsv \
    --range "1-${CONTIG_COUNT}" --len 1000 --idt 0.98 --max 20000 -c 1

pushd ${BASE_DIR}/contigTrim
cat group/groups.txt \
    | parallel --no-run-if-empty -j 8 '
        echo {};
        anchr orient \
            --len 1000 --idt 0.98 \
            group/{}.anchor.fasta \
            group/{}.long.fasta \
            -r group/{}.restrict.tsv \
            -o group/{}.strand.fasta;

        anchr overlap --len 1000 --idt 0.98 \
            group/{}.strand.fasta \
            -o stdout \
            | anchr restrict \
                stdin group/{}.restrict.tsv \
                -o group/{}.ovlp.tsv;

        anchr layout \
            group/{}.ovlp.tsv \
            group/{}.relation.tsv \
            group/{}.strand.fasta \
            -o group/{}.contig.fasta
    '
popd

cat \
    contigTrim/group/non_grouped.fasta \
    contigTrim/group/*.contig.fasta \
    >  contigTrim/contig.fasta

```

* quast

```bash
BASE_DIR=$HOME/data/anchr/Sfle
cd ${BASE_DIR}

rm -fr 9_qa_contig
quast --no-check --threads 16 \
    -R 1_genome/genome.fa \
    merge/anchor.merge.fasta \
    merge/anchor.cover.fasta \
    anchorLong/contig.fasta \
    contigTrim/contig.fasta \
    canu-raw-40x/Sfle.contigs.fasta \
    canu-raw-80x/Sfle.contigs.fasta \
    1_genome/paralogs.fas \
    --label "merge,cover,contig,contigTrim,canu-40x,canu-80x,paralogs" \
    -o 9_qa_contig

```

* Stats

```bash
BASE_DIR=$HOME/data/anchr/Sfle
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
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchor.cover"; faops n50 -H -S -C merge/anchor.cover.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchorLong"; faops n50 -H -S -C anchorLong/contig.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "contigTrim"; faops n50 -H -S -C contigTrim/contig.fasta;) >> stat3.md

cat stat3.md
```

| Name         |     N50 |     Sum |   # |
|:-------------|--------:|--------:|----:|
| Genome       | 4607202 | 4828820 |   2 |
| Paralogs     |    1377 |  543111 | 334 |
| anchor.merge |   29718 | 4177514 | 258 |
| others.merge |    1013 |    5268 |   5 |
| anchor.cover |   21445 | 4065033 | 337 |
| anchorLong   |   21727 | 4064559 | 333 |
| contigTrim   |   59768 | 4286051 | 140 |

* Clear QxxLxxx.

```bash
BASE_DIR=$HOME/data/anchr/Sfle
cd ${BASE_DIR}

rm -fr 2_illumina/Q{20,25,30}L*
rm -fr Q{20,25,30}L*
```

# Vibrio parahaemolyticus ATCC BAA-239, 副溶血弧菌

Project
[SRP040661](https://trace.ncbi.nlm.nih.gov/Traces/sra/?study=SRP040661)

## Vpar: download

* Reference genome

    * Strain: Vibrio parahaemolyticus RIMD 2210633
    * Taxid: [223926](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=223926)
    * RefSeq assembly accession:
      [GCF_000196095.1](ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/196/095/GCF_000196095.1_ASM19609v1/GCF_000196095.1_ASM19609v1_assembly_report.txt)
    * Proportion of paralogs (> 1000 bp): 0.0225

```bash
mkdir -p ~/data/anchr/Vpar/1_genome
cd ~/data/anchr/Vpar/1_genome

aria2c -x 9 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/196/095/GCF_000196095.1_ASM19609v1/GCF_000196095.1_ASM19609v1_genomic.fna.gz

TAB=$'\t'
cat <<EOF > replace.tsv
NC_004603.1${TAB}1
NC_004605.1${TAB}2
EOF

faops replace GCF_000196095.1_ASM19609v1_genomic.fna.gz replace.tsv genome.fa

cp ~/data/anchr/paralogs/otherbac/Results/Vpar/Vpar.multi.fas paralogs.fas

```

* Illumina

    * [SRX2165170](https://www.ncbi.nlm.nih.gov/sra/SRX2165170)

```bash
mkdir -p ~/data/anchr/Vpar/2_illumina
cd ~/data/anchr/Vpar/2_illumina

cat << EOF > sra_ftp.txt
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR424/005/SRR4244665/SRR4244665_1.fastq.gz
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR424/005/SRR4244665/SRR4244665_2.fastq.gz
EOF

aria2c -x 9 -s 3 -c -i sra_ftp.txt

cat << EOF > sra_md5.txt
e18d81e9d1e6776e3af8a7c077ca68c8 SRR4244665_1.fastq.gz
d1c22a57ff241fef3c8e98a2b1f51441 SRR4244665_2.fastq.gz
EOF

md5sum --check sra_md5.txt

ln -s SRR4244665_1.fastq.gz R1.fq.gz
ln -s SRR4244665_2.fastq.gz R2.fq.gz

```

* PacBio

```bash
mkdir -p ~/data/anchr/Vpar/3_pacbio
cd ~/data/anchr/Vpar/3_pacbio

# download from sra
cat <<EOF > hdf5.txt
http://sra-download.ncbi.nlm.nih.gov/srapub_files/SRR4244666_SRR4244666_hdf5.tgz
EOF
aria2c -x 9 -s 3 -c -i hdf5.txt

# untar
mkdir -p ~/data/anchr/Vpar/3_pacbio/untar
cd ~/data/anchr/Vpar/3_pacbio
tar xvfz SRR4244666_SRR4244666_hdf5.tgz --directory untar

# convert .bax.h5 to .subreads.bam
mkdir -p ~/data/anchr/Vpar/3_pacbio/bam
cd ~/data/anchr/Vpar/3_pacbio/bam

source ~/share/pitchfork/deployment/setup-env.sh
for movie in m150515;
do 
    bax2bam ~/data/anchr/Vpar/3_pacbio/untar/${movie}*.bax.h5
done

# convert .subreads.bam to fasta
mkdir -p ~/data/anchr/Vpar/3_pacbio/fasta

for movie in m150515;
do
    if [ ! -e ~/data/anchr/Vpar/3_pacbio/bam/${movie}*.subreads.bam ]; then
        continue
    fi

    samtools fasta \
        ~/data/anchr/Vpar/3_pacbio/bam/${movie}*.subreads.bam \
        > ~/data/anchr/Vpar/3_pacbio/fasta/${movie}.fasta
done

cd ~/data/anchr/Vpar
cat 3_pacbio/fasta/*.fasta > 3_pacbio/pacbio.fasta

faops n50 3_pacbio/pacbio.fasta

rm -fr ~/data/anchr/Vpar/3_pacbio/untar
```

## Vpar: combinations of different quality values and read lengths

* qual: 20, 25, and 30
* len: 60

```bash
BASE_DIR=$HOME/data/anchr/Vpar

cd ${BASE_DIR}
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

cd ${BASE_DIR}
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

cd ${BASE_DIR}
parallel --no-run-if-empty -j 4 "
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

```

* Stats

```bash
BASE_DIR=$HOME/data/anchr/Vpar
cd ${BASE_DIR}

printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat.md
printf "|:--|--:|--:|--:|\n" >> stat.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Paralogs";   faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Illumina"; faops n50 -H -S -C 2_illumina/R1.fq.gz 2_illumina/R2.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "PacBio";   faops n50 -H -S -C 3_pacbio/pacbio.fasta;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "uniq";   faops n50 -H -S -C 2_illumina/R1.uniq.fq.gz 2_illumina/R2.uniq.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "scythe";   faops n50 -H -S -C 2_illumina/R1.scythe.fq.gz 2_illumina/R2.scythe.fq.gz;) >> stat.md

for qual in 20 25 30; do
    for len in 60; do
        DIR_COUNT="${BASE_DIR}/2_illumina/Q${qual}L${len}"

        printf "| %s | %s | %s | %s |\n" \
            $(echo "Q${qual}L${len}"; faops n50 -H -S -C ${DIR_COUNT}/R1.fq.gz  ${DIR_COUNT}/R2.fq.gz;) \
            >> stat.md
    done
done

cat stat.md
```

| Name     |     N50 |        Sum |        # |
|:---------|--------:|-----------:|---------:|
| Genome   | 3288558 |    5165770 |        2 |
| Paralogs |    3333 |     155714 |       62 |
| Illumina |     101 | 1368727962 | 13551762 |
| PacBio   |   11771 | 1228497092 |   143537 |
| uniq     |     101 | 1361783404 | 13483004 |
| scythe   |     101 | 1346787728 | 13483004 |
| Q20L60   |     101 | 1264469138 | 12611522 |
| Q25L60   |     101 | 1200269501 | 12011552 |
| Q30L60   |     101 | 1080002384 | 10917028 |

## Vpar: down sampling

```bash
BASE_DIR=$HOME/data/anchr/Vpar
cd ${BASE_DIR}

ARRAY=(
    "2_illumina/Q20L60:Q20L60:5000000"
    "2_illumina/Q25L60:Q25L60:5000000"
    "2_illumina/Q30L60:Q30L60:5000000"
)

for group in "${ARRAY[@]}" ; do
    
    GROUP_DIR=$(group=${group} perl -e '@p = split q{:}, $ENV{group}; print $p[0];')
    GROUP_ID=$( group=${group} perl -e '@p = split q{:}, $ENV{group}; print $p[1];')
    GROUP_MAX=$(group=${group} perl -e '@p = split q{:}, $ENV{group}; print $p[2];')
    printf "==> %s \t %s \t %s\n" "$GROUP_DIR" "$GROUP_ID" "$GROUP_MAX"

    perl -e 'print 1000000 * $_, qq{\n} for 1 .. 5' \
    | parallel --no-run-if-empty -j 4 "
        if [[ {} -gt '$GROUP_MAX' ]]; then
            exit;
        fi

        echo '    ${GROUP_ID}_{}'
        mkdir -p ${BASE_DIR}/${GROUP_ID}_{}
        
        if [ -e ${BASE_DIR}/${GROUP_ID}_{}/R1.fq.gz ]; then
            exit;
        fi

        seqtk sample -s{} \
            ${BASE_DIR}/${GROUP_DIR}/R1.fq.gz {} \
            | pigz -p 4 -c > ${BASE_DIR}/${GROUP_ID}_{}/R1.fq.gz
        seqtk sample -s{} \
            ${BASE_DIR}/${GROUP_DIR}/R2.fq.gz {} \
            | pigz -p 4 -c > ${BASE_DIR}/${GROUP_ID}_{}/R2.fq.gz
    "

done
```

```bash
BASE_DIR=$HOME/data/anchr/Vpar
cd ${BASE_DIR}

head -n 50000 3_pacbio/pacbio.fasta > 3_pacbio/pacbio.40x.fasta
faops n50 -S -C 3_pacbio/pacbio.40x.fasta

head -n 100000 3_pacbio/pacbio.fasta > 3_pacbio/pacbio.80x.fasta
faops n50 -S -C 3_pacbio/pacbio.80x.fasta

```

## Vpar: generate super-reads

```bash
BASE_DIR=$HOME/data/anchr/Vpar
cd ${BASE_DIR}

perl -e '
    for my $n (
        qw{
        Q20L60
        Q25L60
        Q30L60
        }
        )
    {
        for my $i ( 1 .. 5 ) {
            printf qq{%s_%d\n}, $n, ( 1000000 * $i );
        }
    }
    ' \
    | parallel --no-run-if-empty -j 3 "
        echo '==> Group {}'
        
        if [ ! -d ${BASE_DIR}/{} ]; then
            echo '    directory not exists'
            exit;
        fi        

        if [ -e ${BASE_DIR}/{}/k_unitigs.fasta ]; then
            echo '    k_unitigs.fasta already presents'
            exit;
        fi

        cd ${BASE_DIR}/{}
        anchr superreads \
            R1.fq.gz R2.fq.gz \
            --nosr -p 8 \
            --kmer 41,61,81 \
            -o superreads.sh
        bash superreads.sh
    "

```

Clear intermediate files.

```bash
BASE_DIR=$HOME/data/anchr/Vpar
cd ${BASE_DIR}

find . -type f -name "quorum_mer_db.jf"          | xargs rm
find . -type f -name "k_u_hash_0"                | xargs rm
find . -type f -name "readPositionsInSuperReads" | xargs rm
find . -type f -name "*.tmp"                     | xargs rm
find . -type f -name "pe.renamed.fastq"          | xargs rm
find . -type f -name "pe.cor.sub.fa"             | xargs rm
```

## Vpar: create anchors

```bash
BASE_DIR=$HOME/data/anchr/Vpar
cd ${BASE_DIR}

perl -e '
    for my $n (
        qw{
        Q20L60
        Q25L60
        Q30L60
        }
        )
    {
        for my $i ( 1 .. 5 ) {
            printf qq{%s_%d\n}, $n, ( 1000000 * $i );
        }
    }
    ' \
    | parallel --no-run-if-empty -j 3 "
        echo '==> Group {}'

        if [ -e ${BASE_DIR}/{}/anchor/pe.anchor.fa ]; then
            exit;
        fi

        rm -fr ${BASE_DIR}/{}/anchor
        bash ~/Scripts/cpan/App-Anchr/share/anchor.sh ${BASE_DIR}/{} 8 false
    "

```

## Vpar: results

* Stats of super-reads

```bash
BASE_DIR=$HOME/data/anchr/Vpar
cd ${BASE_DIR}

REAL_G=5165770

bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 header \
    > ${BASE_DIR}/stat1.md

perl -e '
    for my $n (
        qw{
        Q20L60
        Q25L60
        Q30L60
        }
        )
    {
        for my $i ( 1 .. 5 ) {
            printf qq{%s_%d\n}, $n, ( 1000000 * $i );
        }
    }
    ' \
    | parallel -k --no-run-if-empty -j 4 "
        if [ ! -d ${BASE_DIR}/{} ]; then
            exit;
        fi

        bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 ${BASE_DIR}/{} ${REAL_G}
    " >> ${BASE_DIR}/stat1.md

cat stat1.md
```

* Stats of anchors

```bash
BASE_DIR=$HOME/data/anchr/Vpar
cd ${BASE_DIR}

bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 header \
    > ${BASE_DIR}/stat2.md

perl -e '
    for my $n (
        qw{
        Q20L60
        Q25L60
        Q30L60
        }
        )
    {
        for my $i ( 1 .. 5 ) {
            printf qq{%s_%d\n}, $n, ( 1000000 * $i );
        }
    }
    ' \
    | parallel -k --no-run-if-empty -j 8 "
        if [ ! -e ${BASE_DIR}/{}/anchor/pe.anchor.fa ]; then
            exit;
        fi

        bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 ${BASE_DIR}/{}
    " >> ${BASE_DIR}/stat2.md

cat stat2.md
```

| Name           |   SumFq | CovFq | AvgRead |       Kmer |   SumFa | Discard% | RealG |  EstG | Est/Real | SumKU | SumSR |   RunTime |
|:---------------|--------:|------:|--------:|-----------:|--------:|---------:|------:|------:|---------:|------:|------:|----------:|
| Q20L60_1000000 | 200.52M |  38.8 |     100 | "41,61,81" | 184.35M |   8.065% | 5.17M | 5.09M |     0.99 | 5.06M |     0 | 0:02'38'' |
| Q20L60_2000000 | 401.05M |  77.6 |     100 | "41,61,81" |  368.8M |   8.041% | 5.17M | 5.11M |     0.99 | 5.06M |     0 | 0:04'09'' |
| Q20L60_3000000 | 601.57M | 116.5 |     100 | "41,61,81" | 553.44M |   8.000% | 5.17M | 5.15M |     1.00 | 5.06M |     0 | 0:05'41'' |
| Q20L60_4000000 | 802.09M | 155.3 |     100 | "41,61,81" | 738.12M |   7.975% | 5.17M | 5.22M |     1.01 | 5.07M |     0 | 0:07'19'' |
| Q20L60_5000000 |      1G | 194.1 |     100 | "41,61,81" | 923.21M |   7.922% | 5.17M | 5.33M |     1.03 | 5.08M |     0 | 0:08'49'' |
| Q25L60_1000000 | 199.85M |  38.7 |     100 | "41,61,81" | 185.65M |   7.107% | 5.17M | 5.09M |     0.98 | 5.06M |     0 | 0:02'31'' |
| Q25L60_2000000 |  399.7M |  77.4 |     100 | "41,61,81" | 371.46M |   7.065% | 5.17M |  5.1M |     0.99 | 5.06M |     0 | 0:04'23'' |
| Q25L60_3000000 | 599.55M | 116.1 |      99 | "41,61,81" | 557.36M |   7.037% | 5.17M | 5.14M |     0.99 | 5.05M |     0 | 0:05'49'' |
| Q25L60_4000000 | 799.39M | 154.7 |     100 | "41,61,81" | 743.47M |   6.995% | 5.17M | 5.21M |     1.01 | 5.06M |     0 | 0:07'16'' |
| Q25L60_5000000 | 999.26M | 193.4 |      99 | "41,61,81" | 929.71M |   6.960% | 5.17M | 5.32M |     1.03 | 5.07M |     0 | 0:09'01'' |
| Q30L60_1000000 | 197.85M |  38.3 |      99 | "41,61,81" |  185.3M |   6.343% | 5.17M | 5.09M |     0.98 | 5.05M |     0 | 0:02'33'' |
| Q30L60_2000000 | 395.73M |  76.6 |      99 | "41,61,81" | 370.58M |   6.354% | 5.17M |  5.1M |     0.99 | 5.06M |     0 | 0:04'01'' |
| Q30L60_3000000 | 593.56M | 114.9 |      99 | "41,61,81" | 555.98M |   6.331% | 5.17M | 5.14M |     0.99 | 5.06M |     0 | 0:05'27'' |
| Q30L60_4000000 | 791.42M | 153.2 |      99 | "41,61,81" | 741.61M |   6.294% | 5.17M |  5.2M |     1.01 | 5.05M |     0 | 0:07'08'' |
| Q30L60_5000000 | 989.29M | 191.5 |      99 | "41,61,81" | 927.36M |   6.260% | 5.17M | 5.31M |     1.03 | 5.05M |     0 | 0:08'35'' |

| Name           |  N50SR |   Sum |   # | N50Anchor |   Sum |   # | N50Others |    Sum |  # |   RunTime |
|:---------------|-------:|------:|----:|----------:|------:|----:|----------:|-------:|---:|----------:|
| Q20L60_1000000 | 105824 | 5.06M | 127 |    105824 | 5.04M |  99 |       697 | 18.92K | 28 | 0:00'58'' |
| Q20L60_2000000 |  79132 | 5.06M | 150 |     82106 | 5.04M | 125 |       710 | 17.57K | 25 | 0:01'27'' |
| Q20L60_3000000 |  45783 | 5.06M | 223 |     45783 | 5.04M | 194 |       710 | 20.35K | 29 | 0:01'55'' |
| Q20L60_4000000 |  32504 | 5.07M | 301 |     33092 | 5.04M | 271 |       710 | 20.92K | 30 | 0:02'14'' |
| Q20L60_5000000 |  24540 | 5.08M | 401 |     24540 | 5.05M | 362 |       745 | 27.59K | 39 | 0:02'37'' |
| Q25L60_1000000 | 153473 | 5.06M | 107 |    153473 | 5.04M |  78 |       722 | 20.76K | 29 | 0:00'53'' |
| Q25L60_2000000 | 155751 | 5.06M | 105 |    155751 | 5.04M |  81 |       745 | 16.97K | 24 | 0:01'22'' |
| Q25L60_3000000 |  88545 | 5.05M | 126 |     88545 | 5.04M | 101 |       710 | 17.51K | 25 | 0:01'47'' |
| Q25L60_4000000 |  71321 | 5.06M | 161 |     71321 | 5.04M | 135 |       745 | 18.37K | 26 | 0:02'14'' |
| Q25L60_5000000 |  55803 | 5.07M | 196 |     55803 | 5.05M | 169 |       729 | 19.05K | 27 | 0:02'39'' |
| Q30L60_1000000 | 179300 | 5.05M | 110 |    179300 | 5.04M |  82 |       656 | 18.77K | 28 | 0:00'53'' |
| Q30L60_2000000 | 175008 | 5.06M | 100 |    175008 | 5.04M |  77 |       710 | 16.14K | 23 | 0:01'22'' |
| Q30L60_3000000 | 155751 | 5.06M | 106 |    155751 | 5.04M |  82 |       693 | 16.62K | 24 | 0:01'46'' |
| Q30L60_4000000 | 123854 | 5.05M | 107 |    123854 | 5.04M |  84 |       710 | 16.14K | 23 | 0:02'14'' |
| Q30L60_5000000 |  99637 | 5.05M | 123 |     99637 | 5.04M |  99 |       697 | 16.64K | 24 | 0:02'38'' |

## Vpar: merge anchors

```bash
BASE_DIR=$HOME/data/anchr/Vpar
cd ${BASE_DIR}

# merge anchors
mkdir -p merge
anchr contained \
    Q20L60_2000000/anchor/pe.anchor.fa \
    Q20L60_3000000/anchor/pe.anchor.fa \
    Q20L60_4000000/anchor/pe.anchor.fa \
    Q20L60_5000000/anchor/pe.anchor.fa \
    Q25L60_2000000/anchor/pe.anchor.fa \
    Q25L60_3000000/anchor/pe.anchor.fa \
    Q25L60_4000000/anchor/pe.anchor.fa \
    Q25L60_5000000/anchor/pe.anchor.fa \
    Q30L60_2000000/anchor/pe.anchor.fa \
    Q30L60_3000000/anchor/pe.anchor.fa \
    Q30L60_4000000/anchor/pe.anchor.fa \
    Q30L60_5000000/anchor/pe.anchor.fa \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.contained.fasta
anchr orient merge/anchor.contained.fasta --len 1000 --idt 0.98 -o merge/anchor.orient.fasta
anchr merge merge/anchor.orient.fasta --len 1000 --idt 0.999 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.merge.fasta

# merge others
anchr contained \
    Q20L60_2000000/anchor/pe.others.fa \
    Q25L60_2000000/anchor/pe.others.fa \
    Q30L60_2000000/anchor/pe.others.fa \
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
    merge/anchor.merge.fasta \
    1_genome/paralogs.fas \
    --label "merge,paralogs" \
    -o 9_qa

```

## Vpar: 3GS

```bash
BASE_DIR=$HOME/data/anchr/Vpar
cd ${BASE_DIR}

canu \
    -p Vpar -d canu-raw-40x \
    gnuplot=$(brew --prefix)/Cellar/$(brew list --versions gnuplot | sed 's/ /\//')/bin/gnuplot \
    genomeSize=5.2m \
    -pacbio-raw 3_pacbio/pacbio.40x.fasta

canu \
    -p Vpar -d canu-raw-80x \
    gnuplot=$(brew --prefix)/Cellar/$(brew list --versions gnuplot | sed 's/ /\//')/bin/gnuplot \
    genomeSize=5.2m \
    -pacbio-raw 3_pacbio/pacbio.80x.fasta

faops n50 -S -C canu-raw-40x/Vpar.trimmedReads.fasta.gz
faops n50 -S -C canu-raw-80x/Vpar.trimmedReads.fasta.gz

```

## Vpar: expand anchors

* anchorLong

```bash
BASE_DIR=$HOME/data/anchr/Vpar
cd ${BASE_DIR}

anchr cover \
    --parallel 16 \
    -c 2 -m 40 \
    -b 20 --len 1000 --idt 0.9 \
    merge/anchor.merge.fasta \
    canu-raw-40x/Vpar.trimmedReads.fasta.gz \
    -o merge/anchor.cover.fasta

rm -fr anchorLong
anchr overlap2 \
    --parallel 16 \
    merge/anchor.cover.fasta \
    canu-raw-40x/Vpar.trimmedReads.fasta.gz \
    -d anchorLong \
    -b 20 --len 1000 --idt 0.98

anchr overlap \
    merge/anchor.cover.fasta \
    --serial --len 10 --idt 0.9999 \
    -o stdout \
    | perl -nla -e '
        BEGIN {
            our %seen;
            our %count_of;
        }

        @F == 13 or next;
        $F[3] > 0.9999 or next;

        my $pair = join( "-", sort { $a <=> $b } ( $F[0], $F[1], ) );
        next if $seen{$pair};
        $seen{$pair} = $_;

        $count_of{ $F[0] }++;
        $count_of{ $F[1] }++;

        END {
            for my $pair ( keys %seen ) {
                my ($f_id, $g_id) = split "-", $pair;
                next if $count_of{$f_id} > 2;
                next if $count_of{$g_id} > 2;
                print $seen{$pair};
            }
        }
    ' \
    | sort -k 1n,1n -k 2n,2n \
    > anchorLong/anchor.ovlp.tsv

ANCHOR_COUNT=$(faops n50 -H -N 0 -C anchorLong/anchor.fasta)
echo ${ANCHOR_COUNT}

rm -fr anchorLong/group
anchr group \
    anchorLong/anchorLong.db \
    anchorLong/anchorLong.ovlp.tsv \
    --oa anchorLong/anchor.ovlp.tsv \
    --parallel 16 \
    --range "1-${ANCHOR_COUNT}" --len 1000 --idt 0.98 --max "-14" -c 4 --png

pushd ${BASE_DIR}/anchorLong
cat group/groups.txt \
    | parallel --no-run-if-empty -j 8 '
        echo {};
        anchr orient \
            --len 1000 --idt 0.98 \
            group/{}.anchor.fasta \
            group/{}.long.fasta \
            -r group/{}.restrict.tsv \
            -o group/{}.strand.fasta;

        anchr overlap --len 1000 --idt 0.98 \
            group/{}.strand.fasta \
            -o stdout \
            | anchr restrict \
                stdin group/{}.restrict.tsv \
                -o group/{}.ovlp.tsv;

        anchr overlap --len 10 --idt 0.9999 \
            group/{}.strand.fasta \
            -o stdout \
            | perl -nla -e '\''
                @F == 13 or next;
                $F[3] > 0.98 or next;
                $F[9] == 0 or next;
                $F[5] > 0 and $F[6] == $F[7] or next;
                /anchor.+anchor/ or next;
                print;
            '\'' \
            > group/{}.anchor.ovlp.tsv
            
        anchr layout \
            group/{}.ovlp.tsv \
            group/{}.relation.tsv \
            group/{}.strand.fasta \
            --oa group/{}.anchor.ovlp.tsv \
            --png \
            -o group/{}.contig.fasta
    '
popd

# false strand
cat anchorLong/group/*.ovlp.tsv \
    | perl -nla -e '/anchor.+long/ or next; print $F[0] if $F[8] == 1;' \
    | sort | uniq -c

cat \
   anchorLong/group/non_grouped.fasta\
   anchorLong/group/*.contig.fasta \
   | faops filter -l 0 -a 1000 stdin anchorLong/contig.fasta

```

* contigTrim

```bash
BASE_DIR=$HOME/data/anchr/Vpar
cd ${BASE_DIR}

rm -fr contigTrim
anchr overlap2 \
    --parallel 16 \
    anchorLong/contig.fasta \
    canu-raw-40x/Vpar.contigs.fasta \
    -d contigTrim \
    -b 20 --len 1000 --idt 0.98 --all

CONTIG_COUNT=$(faops n50 -H -N 0 -C contigTrim/anchor.fasta)
echo ${CONTIG_COUNT}

rm -fr contigTrim/group
anchr group \
    --parallel 16 \
    --keep \
    contigTrim/anchorLong.db \
    contigTrim/anchorLong.ovlp.tsv \
    --range "1-${CONTIG_COUNT}" --len 1000 --idt 0.98 --max 20000 -c 1

pushd ${BASE_DIR}/contigTrim
cat group/groups.txt \
    | parallel --no-run-if-empty -j 8 '
        echo {};
        anchr orient \
            --len 1000 --idt 0.98 \
            group/{}.anchor.fasta \
            group/{}.long.fasta \
            -r group/{}.restrict.tsv \
            -o group/{}.strand.fasta;

        anchr overlap --len 1000 --idt 0.98 \
            group/{}.strand.fasta \
            -o stdout \
            | anchr restrict \
                stdin group/{}.restrict.tsv \
                -o group/{}.ovlp.tsv;

        anchr layout \
            group/{}.ovlp.tsv \
            group/{}.relation.tsv \
            group/{}.strand.fasta \
            -o group/{}.contig.fasta
    '
popd

cat \
    contigTrim/group/non_grouped.fasta \
    contigTrim/group/*.contig.fasta \
    >  contigTrim/contig.fasta

```

* quast

```bash
BASE_DIR=$HOME/data/anchr/Vpar
cd ${BASE_DIR}

rm -fr 9_qa_contig
quast --no-check --threads 16 \
    -R 1_genome/genome.fa \
    merge/anchor.merge.fasta \
    merge/anchor.cover.fasta \
    anchorLong/contig.fasta \
    contigTrim/contig.fasta \
    canu-raw-40x/Vpar.contigs.fasta \
    canu-raw-80x/Vpar.contigs.fasta \
    1_genome/paralogs.fas \
    --label "merge,cover,contig,contigTrim,canu-40x,canu-80x,paralogs" \
    -o 9_qa_contig

```

* Stats

```bash
BASE_DIR=$HOME/data/anchr/Vpar
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
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchor.cover"; faops n50 -H -S -C merge/anchor.cover.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchorLong"; faops n50 -H -S -C anchorLong/contig.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "contigTrim"; faops n50 -H -S -C contigTrim/contig.fasta;) >> stat3.md

cat stat3.md
```

| Name         |     N50 |     Sum |  # |
|:-------------|--------:|--------:|---:|
| Genome       | 3288558 | 5165770 |  2 |
| Paralogs     |    3333 |  155714 | 62 |
| anchor.merge |  175008 | 5047543 | 73 |
| others.merge |   20100 |   20100 |  1 |
| anchor.cover |  175008 | 5024576 | 78 |
| anchorLong   |  208183 | 5023596 | 63 |
| contigTrim   | 1488730 | 5148305 | 11 |

* Clear QxxLxxx.

```bash
BASE_DIR=$HOME/data/anchr/Vpar
cd ${BASE_DIR}

rm -fr 2_illumina/Q{20,25,30}L*
rm -fr Q{20,25,30}L*
```

# Legionella pneumophila subsp. pneumophila ATCC 33152D-5; Philadelphia-1, 嗜肺军团菌

Project
[SRP040661](https://trace.ncbi.nlm.nih.gov/Traces/sra/?study=SRP040661)

## Lpne: download

* Reference genome

    * Strain: Legionella pneumophila subsp. pneumophila str. Philadelphia 1
    * Taxid: [272624](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id=272624&lvl=3&lin=f&keep=1&srchmode=1&unlock)
    * RefSeq assembly accession:
      [GCF_000008485.1](ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/008/485/GCF_000008485.1_ASM848v1/GCF_000008485.1_ASM848v1_assembly_report.txt)
    * Proportion of paralogs (> 1000 bp): 0.0264

```bash
mkdir -p ~/data/anchr/Lpne/1_genome
cd ~/data/anchr/Lpne/1_genome

aria2c -x 9 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/008/485/GCF_000008485.1_ASM848v1/GCF_000008485.1_ASM848v1_genomic.fna.gz

TAB=$'\t'
cat <<EOF > replace.tsv
NC_002942.5${TAB}1
EOF

faops replace GCF_000008485.1_ASM848v1_genomic.fna.gz replace.tsv genome.fa

cp ~/data/anchr/paralogs/otherbac/Results/Lpne/Lpne.multi.fas paralogs.fas

```

* Illumina

    * [SRX2179279](https://www.ncbi.nlm.nih.gov/sra/SRX2179279) SRR4272054

```bash
mkdir -p ~/data/anchr/Lpne/2_illumina
cd ~/data/anchr/Lpne/2_illumina

cat << EOF > sra_ftp.txt
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR427/004/SRR4272054/SRR4272054_1.fastq.gz
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR427/004/SRR4272054/SRR4272054_2.fastq.gz
EOF

aria2c -x 9 -s 3 -c -i sra_ftp.txt

cat << EOF > sra_md5.txt
6391a189c30acde364eb553e1f592a81 SRR4272054_1.fastq.gz
67ec48fd2c37e09b35f232f262c46d15 SRR4272054_2.fastq.gz
EOF

md5sum --check sra_md5.txt

ln -s SRR4272054_1.fastq.gz R1.fq.gz
ln -s SRR4272054_2.fastq.gz R2.fq.gz

```

* PacBio

```bash
mkdir -p ~/data/anchr/Lpne/3_pacbio
cd ~/data/anchr/Lpne/3_pacbio

# download from sra
cat <<EOF > hdf5.txt
http://sra-download.ncbi.nlm.nih.gov/srapub_files/SRR4272055_SRR4272055_hdf5.tgz
http://sra-download.ncbi.nlm.nih.gov/srapub_files/SRR4272056_SRR4272056_hdf5.tgz
http://sra-download.ncbi.nlm.nih.gov/srapub_files/SRR4272057_SRR4272057_hdf5.tgz
EOF
aria2c -x 9 -s 3 -c -i hdf5.txt

# untar
mkdir -p ~/data/anchr/Lpne/3_pacbio/untar
cd ~/data/anchr/Lpne/3_pacbio
tar xvfz SRR4272055_SRR4272055_hdf5.tgz --directory untar
tar xvfz SRR4272056_SRR4272056_hdf5.tgz --directory untar
tar xvfz SRR4272057_SRR4272057_hdf5.tgz --directory untar

# convert .bax.h5 to .subreads.bam
mkdir -p ~/data/anchr/Lpne/3_pacbio/bam
cd ~/data/anchr/Lpne/3_pacbio/bam

source ~/share/pitchfork/deployment/setup-env.sh
for movie in m141027 m141028 m150113;
do 
    bax2bam ~/data/anchr/Lpne/3_pacbio/untar/${movie}*.bax.h5
done

# convert .subreads.bam to fasta
mkdir -p ~/data/anchr/Lpne/3_pacbio/fasta

for movie in m141027 m141028 m150113;
do
    if [ ! -e ~/data/anchr/Lpne/3_pacbio/bam/${movie}*.subreads.bam ]; then
        continue
    fi

    samtools fasta \
        ~/data/anchr/Lpne/3_pacbio/bam/${movie}*.subreads.bam \
        > ~/data/anchr/Lpne/3_pacbio/fasta/${movie}.fasta
done

cd ~/data/anchr/Lpne
cat 3_pacbio/fasta/*.fasta > 3_pacbio/pacbio.fasta

rm -fr ~/data/anchr/Lpne/3_pacbio/untar
```

## Lpne: combinations of different quality values and read lengths

* qual: 20, 25, and 30
* len: 60

```bash
BASE_DIR=$HOME/data/anchr/Lpne

cd ${BASE_DIR}
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

cd ${BASE_DIR}
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

cd ${BASE_DIR}
parallel --no-run-if-empty -j 4 "
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

```

* Stats

```bash
BASE_DIR=$HOME/data/anchr/Lpne
cd ${BASE_DIR}

printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat.md
printf "|:--|--:|--:|--:|\n" >> stat.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Paralogs";   faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Illumina"; faops n50 -H -S -C 2_illumina/R1.fq.gz 2_illumina/R2.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "PacBio";   faops n50 -H -S -C 3_pacbio/pacbio.fasta;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "uniq";   faops n50 -H -S -C 2_illumina/R1.uniq.fq.gz 2_illumina/R2.uniq.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "scythe";   faops n50 -H -S -C 2_illumina/R1.scythe.fq.gz 2_illumina/R2.scythe.fq.gz;) >> stat.md

for qual in 20 25 30; do
    for len in 60; do
        DIR_COUNT="${BASE_DIR}/2_illumina/Q${qual}L${len}"

        printf "| %s | %s | %s | %s |\n" \
            $(echo "Q${qual}L${len}"; faops n50 -H -S -C ${DIR_COUNT}/R1.fq.gz  ${DIR_COUNT}/R2.fq.gz;) \
            >> stat.md
    done
done

cat stat.md
```

| Name     |     N50 |        Sum |        # |
|:---------|--------:|-----------:|---------:|
| Genome   | 3397754 |    3397754 |        1 |
| Paralogs |    2793 |     100722 |       43 |
| Illumina |     101 | 1060346682 | 10498482 |
| PacBio   |    8538 |  287320468 |    56763 |
| uniq     |     101 | 1056283452 | 10458252 |
| scythe   |     101 | 1048724230 | 10458252 |
| Q20L60   |     101 |  977114865 |  9759022 |
| Q25L60   |     101 |  908681802 |  9124858 |
| Q30L60   |     101 |  774121137 |  7914064 |

## Lpne: down sampling

```bash
BASE_DIR=$HOME/data/anchr/Lpne
cd ${BASE_DIR}

ARRAY=(
    "2_illumina/Q20L60:Q20L60:4000000"
    "2_illumina/Q25L60:Q25L60:4000000"
    "2_illumina/Q30L60:Q30L60:4000000"
)

for group in "${ARRAY[@]}" ; do
    
    GROUP_DIR=$(group=${group} perl -e '@p = split q{:}, $ENV{group}; print $p[0];')
    GROUP_ID=$( group=${group} perl -e '@p = split q{:}, $ENV{group}; print $p[1];')
    GROUP_MAX=$(group=${group} perl -e '@p = split q{:}, $ENV{group}; print $p[2];')
    printf "==> %s \t %s \t %s\n" "$GROUP_DIR" "$GROUP_ID" "$GROUP_MAX"

    perl -e 'print 1000000 * $_, qq{\n} for 1 .. 5' \
    | parallel --no-run-if-empty -j 4 "
        if [[ {} -gt '$GROUP_MAX' ]]; then
            exit;
        fi

        echo '    ${GROUP_ID}_{}'
        mkdir -p ${BASE_DIR}/${GROUP_ID}_{}
        
        if [ -e ${BASE_DIR}/${GROUP_ID}_{}/R1.fq.gz ]; then
            exit;
        fi

        seqtk sample -s{} \
            ${BASE_DIR}/${GROUP_DIR}/R1.fq.gz {} \
            | pigz -p 4 -c > ${BASE_DIR}/${GROUP_ID}_{}/R1.fq.gz
        seqtk sample -s{} \
            ${BASE_DIR}/${GROUP_DIR}/R2.fq.gz {} \
            | pigz -p 4 -c > ${BASE_DIR}/${GROUP_ID}_{}/R2.fq.gz
    "

done
```

```bash
BASE_DIR=$HOME/data/anchr/Lpne
cd ${BASE_DIR}

head -n 50000 3_pacbio/pacbio.fasta > 3_pacbio/pacbio.40x.fasta
faops n50 -S -C 3_pacbio/pacbio.40x.fasta

head -n 100000 3_pacbio/pacbio.fasta > 3_pacbio/pacbio.80x.fasta
faops n50 -S -C 3_pacbio/pacbio.80x.fasta

```

## Lpne: generate super-reads

```bash
BASE_DIR=$HOME/data/anchr/Lpne
cd ${BASE_DIR}

perl -e '
    for my $n (
        qw{
        Q20L60
        Q25L60
        Q30L60
        }
        )
    {
        for my $i ( 1 .. 5 ) {
            printf qq{%s_%d\n}, $n, ( 1000000 * $i );
        }
    }
    ' \
    | parallel --no-run-if-empty -j 3 "
        echo '==> Group {}'
        
        if [ ! -d ${BASE_DIR}/{} ]; then
            echo '    directory not exists'
            exit;
        fi        

        if [ -e ${BASE_DIR}/{}/k_unitigs.fasta ]; then
            echo '    k_unitigs.fasta already presents'
            exit;
        fi

        cd ${BASE_DIR}/{}
        anchr superreads \
            R1.fq.gz R2.fq.gz \
            --nosr -p 8 \
            --kmer 41,61,81 \
            -o superreads.sh
        bash superreads.sh
    "

```

Clear intermediate files.

```bash
BASE_DIR=$HOME/data/anchr/Lpne
cd ${BASE_DIR}

find . -type f -name "quorum_mer_db.jf"          | xargs rm
find . -type f -name "k_u_hash_0"                | xargs rm
find . -type f -name "readPositionsInSuperReads" | xargs rm
find . -type f -name "*.tmp"                     | xargs rm
find . -type f -name "pe.renamed.fastq"          | xargs rm
find . -type f -name "pe.cor.sub.fa"             | xargs rm
```

## Lpne: create anchors

```bash
BASE_DIR=$HOME/data/anchr/Lpne
cd ${BASE_DIR}

perl -e '
    for my $n (
        qw{
        Q20L60
        Q25L60
        Q30L60
        }
        )
    {
        for my $i ( 1 .. 5 ) {
            printf qq{%s_%d\n}, $n, ( 1000000 * $i );
        }
    }
    ' \
    | parallel --no-run-if-empty -j 3 "
        echo '==> Group {}'

        if [ -e ${BASE_DIR}/{}/anchor/pe.anchor.fa ]; then
            exit;
        fi

        rm -fr ${BASE_DIR}/{}/anchor
        bash ~/Scripts/cpan/App-Anchr/share/anchor.sh ${BASE_DIR}/{} 8 false
    "

```

## Lpne: results

* Stats of super-reads

```bash
BASE_DIR=$HOME/data/anchr/Lpne
cd ${BASE_DIR}

REAL_G=3397754

bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 header \
    > ${BASE_DIR}/stat1.md

perl -e '
    for my $n (
        qw{
        Q20L60
        Q25L60
        Q30L60
        }
        )
    {
        for my $i ( 1 .. 5 ) {
            printf qq{%s_%d\n}, $n, ( 1000000 * $i );
        }
    }
    ' \
    | parallel -k --no-run-if-empty -j 4 "
        if [ ! -d ${BASE_DIR}/{} ]; then
            exit;
        fi

        bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 ${BASE_DIR}/{} ${REAL_G}
    " >> ${BASE_DIR}/stat1.md

cat stat1.md
```

* Stats of anchors

```bash
BASE_DIR=$HOME/data/anchr/Lpne
cd ${BASE_DIR}

bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 header \
    > ${BASE_DIR}/stat2.md

perl -e '
    for my $n (
        qw{
        Q20L60
        Q25L60
        Q30L60
        }
        )
    {
        for my $i ( 1 .. 5 ) {
            printf qq{%s_%d\n}, $n, ( 1000000 * $i );
        }
    }
    ' \
    | parallel -k --no-run-if-empty -j 8 "
        if [ ! -e ${BASE_DIR}/{}/anchor/pe.anchor.fa ]; then
            exit;
        fi

        bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 ${BASE_DIR}/{}
    " >> ${BASE_DIR}/stat2.md

cat stat2.md
```

| Name           |   SumFq | CovFq | AvgRead |       Kmer |   SumFa | Discard% | RealG |  EstG | Est/Real | SumKU | SumSR |   RunTime |
|:---------------|--------:|------:|--------:|-----------:|--------:|---------:|------:|------:|---------:|------:|------:|----------:|
| Q20L60_1000000 | 200.24M |  58.9 |     100 | "41,61,81" | 181.17M |   9.524% |  3.4M |  3.4M |     1.00 | 3.42M |     0 | 0:05'07'' |
| Q20L60_2000000 | 400.49M | 117.9 |     100 | "41,61,81" | 362.45M |   9.500% |  3.4M | 3.41M |     1.00 | 3.43M |     0 | 0:08'38'' |
| Q20L60_3000000 | 600.74M | 176.8 |      99 | "41,61,81" | 543.81M |   9.476% |  3.4M | 3.43M |     1.01 | 3.43M |     0 | 0:12'31'' |
| Q20L60_4000000 |    801M | 235.7 |      99 | "41,61,81" |  725.8M |   9.388% |  3.4M | 3.47M |     1.02 | 3.43M |     0 | 0:15'59'' |
| Q25L60_1000000 | 199.18M |  58.6 |      99 | "41,61,81" | 183.62M |   7.812% |  3.4M |  3.4M |     1.00 | 3.48M |     0 | 0:05'12'' |
| Q25L60_2000000 | 398.32M | 117.2 |      99 | "41,61,81" | 367.28M |   7.792% |  3.4M | 3.41M |     1.00 | 3.43M |     0 | 0:08'33'' |
| Q25L60_3000000 | 597.52M | 175.9 |      99 | "41,61,81" |  551.1M |   7.769% |  3.4M | 3.41M |     1.00 | 3.42M |     0 | 0:12'32'' |
| Q25L60_4000000 | 796.67M | 234.5 |      99 | "41,61,81" |  734.9M |   7.753% |  3.4M | 3.42M |     1.01 | 3.43M |     0 | 0:14'31'' |
| Q30L60_1000000 | 195.64M |  57.6 |      98 | "41,61,81" |  183.5M |   6.208% |  3.4M |  3.4M |     1.00 | 3.41M |     0 | 0:05'13'' |
| Q30L60_2000000 | 391.27M | 115.2 |      98 | "41,61,81" | 367.04M |   6.193% |  3.4M |  3.4M |     1.00 | 3.42M |     0 | 0:07'40'' |
| Q30L60_3000000 | 586.89M | 172.7 |      97 | "41,61,81" |  550.6M |   6.183% |  3.4M | 3.41M |     1.00 | 3.42M |     0 | 0:10'04'' |
| Q30L60_4000000 | 774.12M | 227.8 |      97 | "41,61,81" |  726.3M |   6.177% |  3.4M | 3.41M |     1.00 | 3.42M |     0 | 0:08'35'' |

| Name           |  N50SR |   Sum |   # | N50Anchor |   Sum |   # | N50Others |     Sum |   # |   RunTime |
|:---------------|-------:|------:|----:|----------:|------:|----:|----------:|--------:|----:|----------:|
| Q20L60_1000000 |  59861 | 3.42M | 134 |     60611 | 3.36M | 110 |     43054 |   59.5K |  24 | 0:02'01'' |
| Q20L60_2000000 |  27709 | 3.43M | 222 |     28368 | 3.37M | 190 |     21578 |  65.35K |  32 | 0:03'10'' |
| Q20L60_3000000 |  14498 | 3.43M | 396 |     14852 | 3.38M | 353 |       955 |  55.98K |  43 | 0:04'01'' |
| Q20L60_4000000 |   7243 | 3.43M | 772 |      7331 | 3.34M | 648 |       749 |  90.87K | 124 | 0:04'34'' |
| Q25L60_1000000 | 120520 | 3.48M | 101 |    120520 | 3.37M |  66 |     88397 | 117.88K |  35 | 0:01'53'' |
| Q25L60_2000000 |  62424 | 3.43M | 124 |     62424 | 3.36M |  95 |     43054 |  62.52K |  29 | 0:03'02'' |
| Q25L60_3000000 |  30976 | 3.42M | 200 |     31319 | 3.39M | 175 |       897 |  32.64K |  25 | 0:03'32'' |
| Q25L60_4000000 |  20322 | 3.43M | 304 |     20440 | 3.38M | 273 |     14979 |  50.13K |  31 | 0:04'18'' |
| Q30L60_1000000 | 219482 | 3.41M |  83 |    219482 |  3.4M |  56 |       734 |  18.18K |  27 | 0:01'41'' |
| Q30L60_2000000 | 128845 | 3.42M |  93 |    128845 | 3.36M |  68 |     21578 |  59.28K |  25 | 0:02'42'' |
| Q30L60_3000000 |  68045 | 3.42M | 123 |     68045 | 3.37M |  97 |     15040 |   46.9K |  26 | 0:03'30'' |
| Q30L60_4000000 |  49793 | 3.42M | 146 |     49793 | 3.38M | 126 |     15040 |  42.66K |  20 | 0:03'54'' |

## Lpne: merge anchors

```bash
BASE_DIR=$HOME/data/anchr/Lpne
cd ${BASE_DIR}

# merge anchors
mkdir -p merge
anchr contained \
    Q20L60_1000000/anchor/pe.anchor.fa \
    Q20L60_2000000/anchor/pe.anchor.fa \
    Q20L60_3000000/anchor/pe.anchor.fa \
    Q20L60_4000000/anchor/pe.anchor.fa \
    Q25L60_1000000/anchor/pe.anchor.fa \
    Q25L60_2000000/anchor/pe.anchor.fa \
    Q25L60_3000000/anchor/pe.anchor.fa \
    Q25L60_4000000/anchor/pe.anchor.fa \
    Q30L60_1000000/anchor/pe.anchor.fa \
    Q30L60_2000000/anchor/pe.anchor.fa \
    Q30L60_3000000/anchor/pe.anchor.fa \
    Q30L60_4000000/anchor/pe.anchor.fa \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.contained.fasta
anchr orient merge/anchor.contained.fasta --len 1000 --idt 0.98 -o merge/anchor.orient.fasta
anchr merge merge/anchor.orient.fasta --len 1000 --idt 0.999 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.merge.fasta

# merge others
anchr contained \
    Q20L60_2000000/anchor/pe.others.fa \
    Q25L60_2000000/anchor/pe.others.fa \
    Q30L60_2000000/anchor/pe.others.fa \
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
    merge/anchor.merge.fasta \
    merge/others.merge.fasta \
    1_genome/paralogs.fas \
    --label "merge,others,paralogs" \
    -o 9_qa

```

## Lpne: 3GS

```bash
BASE_DIR=$HOME/data/anchr/Lpne
cd ${BASE_DIR}

canu \
    -p Lpne -d canu-raw-40x \
    gnuplot=$(brew --prefix)/Cellar/$(brew list --versions gnuplot | sed 's/ /\//')/bin/gnuplot \
    genomeSize=3.4m \
    -pacbio-raw 3_pacbio/pacbio.40x.fasta

canu \
    -p Lpne -d canu-raw-80x \
    gnuplot=$(brew --prefix)/Cellar/$(brew list --versions gnuplot | sed 's/ /\//')/bin/gnuplot \
    genomeSize=3.4m \
    -pacbio-raw 3_pacbio/pacbio.80x.fasta

faops n50 -S -C canu-raw-40x/Lpne.trimmedReads.fasta.gz
faops n50 -S -C canu-raw-80x/Lpne.trimmedReads.fasta.gz

```

## Lpne: expand anchors

* anchorLong

```bash
BASE_DIR=$HOME/data/anchr/Lpne
cd ${BASE_DIR}

anchr cover \
    --parallel 16 \
    -c 2 -m 40 \
    -b 20 --len 1000 --idt 0.9 \
    merge/anchor.merge.fasta \
    canu-raw-40x/Lpne.trimmedReads.fasta.gz \
    -o merge/anchor.cover.fasta

rm -fr anchorLong
anchr overlap2 \
    --parallel 16 \
    merge/anchor.cover.fasta \
    canu-raw-40x/Lpne.trimmedReads.fasta.gz \
    -d anchorLong \
    -b 20 --len 1000 --idt 0.98

anchr overlap \
    merge/anchor.cover.fasta \
    --serial --len 10 --idt 0.9999 \
    -o stdout \
    | perl -nla -e '
        BEGIN {
            our %seen;
            our %count_of;
        }

        @F == 13 or next;
        $F[3] > 0.9999 or next;

        my $pair = join( "-", sort { $a <=> $b } ( $F[0], $F[1], ) );
        next if $seen{$pair};
        $seen{$pair} = $_;

        $count_of{ $F[0] }++;
        $count_of{ $F[1] }++;

        END {
            for my $pair ( keys %seen ) {
                my ($f_id, $g_id) = split "-", $pair;
                next if $count_of{$f_id} > 2;
                next if $count_of{$g_id} > 2;
                print $seen{$pair};
            }
        }
    ' \
    | sort -k 1n,1n -k 2n,2n \
    > anchorLong/anchor.ovlp.tsv

ANCHOR_COUNT=$(faops n50 -H -N 0 -C anchorLong/anchor.fasta)
echo ${ANCHOR_COUNT}

rm -fr anchorLong/group
anchr group \
    anchorLong/anchorLong.db \
    anchorLong/anchorLong.ovlp.tsv \
    --oa anchorLong/anchor.ovlp.tsv \
    --parallel 16 \
    --range "1-${ANCHOR_COUNT}" --len 1000 --idt 0.98 --max "-14" -c 4 --png

pushd ${BASE_DIR}/anchorLong
cat group/groups.txt \
    | parallel --no-run-if-empty -j 8 '
        echo {};
        anchr orient \
            --len 1000 --idt 0.98 \
            group/{}.anchor.fasta \
            group/{}.long.fasta \
            -r group/{}.restrict.tsv \
            -o group/{}.strand.fasta;

        anchr overlap --len 1000 --idt 0.98 \
            group/{}.strand.fasta \
            -o stdout \
            | anchr restrict \
                stdin group/{}.restrict.tsv \
                -o group/{}.ovlp.tsv;

        anchr overlap --len 10 --idt 0.9999 \
            group/{}.strand.fasta \
            -o stdout \
            | perl -nla -e '\''
                @F == 13 or next;
                $F[3] > 0.98 or next;
                $F[9] == 0 or next;
                $F[5] > 0 and $F[6] == $F[7] or next;
                /anchor.+anchor/ or next;
                print;
            '\'' \
            > group/{}.anchor.ovlp.tsv
            
        anchr layout \
            group/{}.ovlp.tsv \
            group/{}.relation.tsv \
            group/{}.strand.fasta \
            --oa group/{}.anchor.ovlp.tsv \
            --png \
            -o group/{}.contig.fasta
    '
popd

# false strand
cat anchorLong/group/*.ovlp.tsv \
    | perl -nla -e '/anchor.+long/ or next; print $F[0] if $F[8] == 1;' \
    | sort | uniq -c

cat \
   anchorLong/group/non_grouped.fasta\
   anchorLong/group/*.contig.fasta \
   | faops filter -l 0 -a 1000 stdin anchorLong/contig.fasta

```

* contigTrim

```bash
BASE_DIR=$HOME/data/anchr/Lpne
cd ${BASE_DIR}

rm -fr contigTrim
anchr overlap2 \
    --parallel 16 \
    anchorLong/contig.fasta \
    canu-raw-40x/Lpne.contigs.fasta \
    -d contigTrim \
    -b 20 --len 1000 --idt 0.98 --all

CONTIG_COUNT=$(faops n50 -H -N 0 -C contigTrim/anchor.fasta)
echo ${CONTIG_COUNT}

rm -fr contigTrim/group
anchr group \
    --parallel 16 \
    --keep \
    contigTrim/anchorLong.db \
    contigTrim/anchorLong.ovlp.tsv \
    --range "1-${CONTIG_COUNT}" --len 1000 --idt 0.98 --max 20000 -c 1

pushd ${BASE_DIR}/contigTrim
cat group/groups.txt \
    | parallel --no-run-if-empty -j 8 '
        echo {};
        anchr orient \
            --len 1000 --idt 0.98 \
            group/{}.anchor.fasta \
            group/{}.long.fasta \
            -r group/{}.restrict.tsv \
            -o group/{}.strand.fasta;

        anchr overlap --len 1000 --idt 0.98 \
            group/{}.strand.fasta \
            -o stdout \
            | anchr restrict \
                stdin group/{}.restrict.tsv \
                -o group/{}.ovlp.tsv;

        anchr layout \
            group/{}.ovlp.tsv \
            group/{}.relation.tsv \
            group/{}.strand.fasta \
            -o group/{}.contig.fasta
    '
popd

cat \
    contigTrim/group/non_grouped.fasta \
    contigTrim/group/*.contig.fasta \
    >  contigTrim/contig.fasta

```

* quast

```bash
BASE_DIR=$HOME/data/anchr/Lpne
cd ${BASE_DIR}

rm -fr 9_qa_contig
quast --no-check --threads 16 \
    -R 1_genome/genome.fa \
    merge/anchor.merge.fasta \
    merge/anchor.cover.fasta \
    anchorLong/contig.fasta \
    contigTrim/contig.fasta \
    canu-raw-40x/Lpne.contigs.fasta \
    canu-raw-80x/Lpne.contigs.fasta \
    1_genome/paralogs.fas \
    --label "merge,cover,contig,contigTrim,canu-40x,canu-80x,paralogs" \
    -o 9_qa_contig

```

* Stats

```bash
BASE_DIR=$HOME/data/anchr/Lpne
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
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchor.cover"; faops n50 -H -S -C merge/anchor.cover.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchorLong"; faops n50 -H -S -C anchorLong/contig.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "contigTrim"; faops n50 -H -S -C contigTrim/contig.fasta;) >> stat3.md

cat stat3.md
```

| Name         |     N50 |     Sum |  # |
|:-------------|--------:|--------:|---:|
| Genome       | 3397754 | 3397754 |  1 |
| Paralogs     |    2793 |  100722 | 43 |
| anchor.merge |  248586 | 3426711 | 53 |
| others.merge |   43054 |   47381 |  5 |
| anchor.cover |  248586 | 3375327 | 45 |
| anchorLong   |  261851 | 3373001 | 39 |
| contigTrim   | 3408430 | 3418287 |  7 |

* Clear QxxLxxx.

```bash
BASE_DIR=$HOME/data/anchr/Lpne
cd ${BASE_DIR}

rm -fr 2_illumina/Q{20,25,30}L*
rm -fr Q{20,25,30}L*
```

# Neisseria gonorrhoeae FDAARGOS_207, 淋病奈瑟氏菌

Project
[SRP040661](https://trace.ncbi.nlm.nih.gov/Traces/sra/?study=SRP040661)

## Ngon: download

* Reference genome

    * Strain: Neisseria gonorrhoeae FA 1090
    * Taxid: [242231](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=242231)
    * RefSeq assembly accession:
      [GCF_000006845.1](ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/845/GCF_000006845.1_ASM684v1/GCF_000006845.1_ASM684v1_assembly_report.txt)
    * Proportion of paralogs (> 1000 bp): 0.0546

```bash
mkdir -p ~/data/anchr/Ngon/1_genome
cd ~/data/anchr/Ngon/1_genome

aria2c -x 9 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/845/GCF_000006845.1_ASM684v1/GCF_000006845.1_ASM684v1_genomic.fna.gz

TAB=$'\t'
cat <<EOF > replace.tsv
NC_002946.2${TAB}1
EOF

faops replace GCF_000006845.1_ASM684v1_genomic.fna.gz replace.tsv genome.fa

cp ~/data/anchr/paralogs/otherbac/Results/Ngon/Ngon.multi.fas paralogs.fas

```

SRX2179294 SRX2179295

* Illumina

    * [SRX2179294](https://www.ncbi.nlm.nih.gov/sra/SRX2179294) SRR4272072

```bash
mkdir -p ~/data/anchr/Ngon/2_illumina
cd ~/data/anchr/Ngon/2_illumina

cat << EOF > sra_ftp.txt
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR427/002/SRR4272072/SRR4272072_1.fastq.gz
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR427/002/SRR4272072/SRR4272072_2.fastq.gz
EOF

aria2c -x 9 -s 3 -c -i sra_ftp.txt

cat << EOF > sra_md5.txt
0e6b38963276a1fdc256eb1f843025bc SRR4272072_1.fastq.gz
532bbf1672dec3316a868774f411d50e SRR4272072_2.fastq.gz
EOF

md5sum --check sra_md5.txt

ln -s SRR4272072_1.fastq.gz R1.fq.gz
ln -s SRR4272072_2.fastq.gz R2.fq.gz

```

* PacBio

```bash
mkdir -p ~/data/anchr/Ngon/3_pacbio
cd ~/data/anchr/Ngon/3_pacbio

# download from sra
cat <<EOF > hdf5.txt
http://sra-download.ncbi.nlm.nih.gov/srapub_files/SRR4272071_SRR4272071_hdf5.tgz
EOF
aria2c -x 9 -s 3 -c -i hdf5.txt

# untar
mkdir -p ~/data/anchr/Ngon/3_pacbio/untar
cd ~/data/anchr/Ngon/3_pacbio
tar xvfz SRR4272071_SRR4272071_hdf5.tgz --directory untar

# convert .bax.h5 to .subreads.bam
mkdir -p ~/data/anchr/Ngon/3_pacbio/bam
cd ~/data/anchr/Ngon/3_pacbio/bam

source ~/share/pitchfork/deployment/setup-env.sh
for movie in m150115;
do 
    bax2bam ~/data/anchr/Ngon/3_pacbio/untar/${movie}*.bax.h5
done

# convert .subreads.bam to fasta
mkdir -p ~/data/anchr/Ngon/3_pacbio/fasta

for movie in m150115;
do
    if [ ! -e ~/data/anchr/Ngon/3_pacbio/bam/${movie}*.subreads.bam ]; then
        continue
    fi

    samtools fasta \
        ~/data/anchr/Ngon/3_pacbio/bam/${movie}*.subreads.bam \
        > ~/data/anchr/Ngon/3_pacbio/fasta/${movie}.fasta
done

cd ~/data/anchr/Ngon
cat 3_pacbio/fasta/*.fasta > 3_pacbio/pacbio.fasta

faops n50 3_pacbio/pacbio.fasta

rm -fr ~/data/anchr/Ngon/3_pacbio/untar
```

## Ngon: combinations of different quality values and read lengths

* qual: 20, 25, and 30
* len: 60

```bash
BASE_DIR=$HOME/data/anchr/Ngon

cd ${BASE_DIR}
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

cd ${BASE_DIR}
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

cd ${BASE_DIR}
parallel --no-run-if-empty -j 4 "
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

```

* Stats

```bash
BASE_DIR=$HOME/data/anchr/Ngon
cd ${BASE_DIR}

printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat.md
printf "|:--|--:|--:|--:|\n" >> stat.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Paralogs";   faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Illumina"; faops n50 -H -S -C 2_illumina/R1.fq.gz 2_illumina/R2.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "PacBio";   faops n50 -H -S -C 3_pacbio/pacbio.fasta;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "uniq";   faops n50 -H -S -C 2_illumina/R1.uniq.fq.gz 2_illumina/R2.uniq.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "scythe";   faops n50 -H -S -C 2_illumina/R1.scythe.fq.gz 2_illumina/R2.scythe.fq.gz;) >> stat.md

for qual in 20 25 30; do
    for len in 60; do
        DIR_COUNT="${BASE_DIR}/2_illumina/Q${qual}L${len}"

        printf "| %s | %s | %s | %s |\n" \
            $(echo "Q${qual}L${len}"; faops n50 -H -S -C ${DIR_COUNT}/R1.fq.gz  ${DIR_COUNT}/R2.fq.gz;) \
            >> stat.md
    done
done

cat stat.md
```

| Name     |     N50 |        Sum |        # |
|:---------|--------:|-----------:|---------:|
| Genome   | 2153922 |    2153922 |        1 |
| Paralogs |    4318 |     142093 |       53 |
| Illumina |     101 | 1491583958 | 14768158 |
| PacBio   |   11808 | 1187845820 |   137516 |
| uniq     |     101 | 1485449016 | 14707416 |
| scythe   |     101 | 1460356291 | 14707416 |
| Q20L60   |     101 | 1239834586 | 12544518 |
| Q25L60   |     101 | 1062429395 | 10873960 |
| Q30L60   |     101 |  734805677 |  7775198 |

## Ngon: down sampling

```bash
BASE_DIR=$HOME/data/anchr/Ngon
cd ${BASE_DIR}

ARRAY=(
    "2_illumina/Q20L60:Q20L60:4000000"
    "2_illumina/Q25L60:Q25L60:4000000"
    "2_illumina/Q30L60:Q30L60:4000000"
)

for group in "${ARRAY[@]}" ; do
    
    GROUP_DIR=$(group=${group} perl -e '@p = split q{:}, $ENV{group}; print $p[0];')
    GROUP_ID=$( group=${group} perl -e '@p = split q{:}, $ENV{group}; print $p[1];')
    GROUP_MAX=$(group=${group} perl -e '@p = split q{:}, $ENV{group}; print $p[2];')
    printf "==> %s \t %s \t %s\n" "$GROUP_DIR" "$GROUP_ID" "$GROUP_MAX"

    perl -e 'print 1000000 * $_, qq{\n} for 1 .. 5' \
    | parallel --no-run-if-empty -j 4 "
        if [[ {} -gt '$GROUP_MAX' ]]; then
            exit;
        fi

        echo '    ${GROUP_ID}_{}'
        mkdir -p ${BASE_DIR}/${GROUP_ID}_{}
        
        if [ -e ${BASE_DIR}/${GROUP_ID}_{}/R1.fq.gz ]; then
            exit;
        fi

        seqtk sample -s{} \
            ${BASE_DIR}/${GROUP_DIR}/R1.fq.gz {} \
            | pigz -p 4 -c > ${BASE_DIR}/${GROUP_ID}_{}/R1.fq.gz
        seqtk sample -s{} \
            ${BASE_DIR}/${GROUP_DIR}/R2.fq.gz {} \
            | pigz -p 4 -c > ${BASE_DIR}/${GROUP_ID}_{}/R2.fq.gz
    "

done

```

```bash
BASE_DIR=$HOME/data/anchr/Ngon
cd ${BASE_DIR}

head -n 25000 3_pacbio/pacbio.fasta > 3_pacbio/pacbio.40x.fasta
faops n50 -S -C 3_pacbio/pacbio.40x.fasta

head -n 50000 3_pacbio/pacbio.fasta > 3_pacbio/pacbio.80x.fasta
faops n50 -S -C 3_pacbio/pacbio.80x.fasta

```

## Ngon: generate super-reads

```bash
BASE_DIR=$HOME/data/anchr/Ngon
cd ${BASE_DIR}

perl -e '
    for my $n (
        qw{
        Q20L60
        Q25L60
        Q30L60
        }
        )
    {
        for my $i ( 1 .. 5 ) {
            printf qq{%s_%d\n}, $n, ( 1000000 * $i );
        }
    }
    ' \
    | parallel --no-run-if-empty -j 3 "
        echo '==> Group {}'
        
        if [ ! -d ${BASE_DIR}/{} ]; then
            echo '    directory not exists'
            exit;
        fi        

        if [ -e ${BASE_DIR}/{}/k_unitigs.fasta ]; then
            echo '    k_unitigs.fasta already presents'
            exit;
        fi

        cd ${BASE_DIR}/{}
        anchr superreads \
            R1.fq.gz R2.fq.gz \
            --nosr -p 8 \
            --kmer 41,61,81 \
            -o superreads.sh
        bash superreads.sh
    "

```

Clear intermediate files.

```bash
BASE_DIR=$HOME/data/anchr/Ngon
cd ${BASE_DIR}

find . -type f -name "quorum_mer_db.jf"          | xargs rm
find . -type f -name "k_u_hash_0"                | xargs rm
find . -type f -name "readPositionsInSuperReads" | xargs rm
find . -type f -name "*.tmp"                     | xargs rm
find . -type f -name "pe.renamed.fastq"          | xargs rm
find . -type f -name "pe.cor.sub.fa"             | xargs rm
```

## Ngon: create anchors

```bash
BASE_DIR=$HOME/data/anchr/Ngon
cd ${BASE_DIR}

perl -e '
    for my $n (
        qw{
        Q20L60
        Q25L60
        Q30L60
        }
        )
    {
        for my $i ( 1 .. 5 ) {
            printf qq{%s_%d\n}, $n, ( 1000000 * $i );
        }
    }
    ' \
    | parallel --no-run-if-empty -j 3 "
        echo '==> Group {}'

        if [ -e ${BASE_DIR}/{}/anchor/pe.anchor.fa ]; then
            exit;
        fi

        rm -fr ${BASE_DIR}/{}/anchor
        bash ~/Scripts/cpan/App-Anchr/share/anchor.sh ${BASE_DIR}/{} 8 false
    "

```

## Ngon: results

* Stats of super-reads

```bash
BASE_DIR=$HOME/data/anchr/Ngon
cd ${BASE_DIR}

REAL_G=2153922

bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 header \
    > ${BASE_DIR}/stat1.md

perl -e '
    for my $n (
        qw{
        Q20L60
        Q25L60
        Q30L60
        }
        )
    {
        for my $i ( 1 .. 5 ) {
            printf qq{%s_%d\n}, $n, ( 1000000 * $i );
        }
    }
    ' \
    | parallel -k --no-run-if-empty -j 4 "
        if [ ! -d ${BASE_DIR}/{} ]; then
            exit;
        fi

        bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 ${BASE_DIR}/{} ${REAL_G}
    " >> ${BASE_DIR}/stat1.md

cat stat1.md
```

* Stats of anchors

```bash
BASE_DIR=$HOME/data/anchr/Ngon
cd ${BASE_DIR}

bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 header \
    > ${BASE_DIR}/stat2.md

perl -e '
    for my $n (
        qw{
        Q20L60
        Q25L60
        Q30L60
        }
        )
    {
        for my $i ( 1 .. 5 ) {
            printf qq{%s_%d\n}, $n, ( 1000000 * $i );
        }
    }
    ' \
    | parallel -k --no-run-if-empty -j 8 "
        if [ ! -e ${BASE_DIR}/{}/anchor/pe.anchor.fa ]; then
            exit;
        fi

        bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 ${BASE_DIR}/{}
    " >> ${BASE_DIR}/stat2.md

cat stat2.md
```

| Name           |   SumFq | CovFq | AvgRead |       Kmer |   SumFa | Discard% | RealG |  EstG | Est/Real | SumKU | SumSR |   RunTime |
|:---------------|--------:|------:|--------:|-----------:|--------:|---------:|------:|------:|---------:|------:|------:|----------:|
| Q20L60_1000000 | 197.67M |  91.8 |      98 | "41,61,81" | 176.42M |  10.751% | 2.15M | 2.07M |     0.96 | 2.05M |     0 | 0:03'46'' |
| Q20L60_2000000 | 395.34M | 183.5 |      99 | "41,61,81" | 353.32M |  10.627% | 2.15M | 2.11M |     0.98 | 2.03M |     0 | 0:06'39'' |
| Q20L60_3000000 | 593.02M | 275.3 |      98 | "41,61,81" |  532.1M |  10.273% | 2.15M | 2.25M |     1.04 | 1.84M |     0 | 0:10'29'' |
| Q20L60_4000000 | 790.69M | 367.1 |      98 | "41,61,81" | 710.98M |  10.082% | 2.15M | 2.37M |     1.10 |  1.6M |     0 | 0:14'50'' |
| Q25L60_1000000 | 195.42M |  90.7 |      98 | "41,61,81" | 179.22M |   8.288% | 2.15M | 2.05M |     0.95 | 2.04M |     0 | 0:04'48'' |
| Q25L60_2000000 |  390.8M | 181.4 |      97 | "41,61,81" | 358.66M |   8.224% | 2.15M | 2.06M |     0.96 | 2.04M |     0 | 0:08'22'' |
| Q25L60_3000000 | 586.22M | 272.2 |      97 | "41,61,81" | 538.76M |   8.096% | 2.15M | 2.11M |     0.98 | 2.03M |     0 | 0:12'09'' |
| Q25L60_4000000 | 781.64M | 362.9 |      97 | "41,61,81" |    719M |   8.014% | 2.15M | 2.17M |     1.01 |    2M |     0 | 0:15'35'' |
| Q30L60_1000000 | 189.01M |  87.8 |      95 | "41,61,81" | 177.26M |   6.221% | 2.15M | 2.04M |     0.95 | 2.04M |     0 | 0:04'38'' |
| Q30L60_2000000 | 378.02M | 175.5 |      94 | "41,61,81" | 354.55M |   6.209% | 2.15M | 2.05M |     0.95 | 2.04M |     0 | 0:08'08'' |
| Q30L60_3000000 | 567.03M | 263.3 |      94 | "41,61,81" | 531.94M |   6.189% | 2.15M | 2.06M |     0.96 | 2.04M |     0 | 0:11'21'' |
| Q30L60_4000000 | 734.81M | 341.1 |      93 | "41,61,81" | 689.49M |   6.167% | 2.15M | 2.08M |     0.96 | 2.03M |     0 | 0:11'17'' |

| Name           | N50SR |   Sum |    # | N50Anchor |     Sum |   # | N50Others |     Sum |    # |   RunTime |
|:---------------|------:|------:|-----:|----------:|--------:|----:|----------:|--------:|-----:|----------:|
| Q20L60_1000000 |  7552 | 2.05M |  478 |      7717 |   1.97M | 379 |       725 |  74.35K |   99 | 0:01'52'' |
| Q20L60_2000000 |  3187 | 2.03M |  890 |      3441 |   1.86M | 654 |       757 | 172.56K |  236 | 0:02'15'' |
| Q20L60_3000000 |  1304 | 1.84M | 1576 |      1728 |   1.21M | 708 |       746 | 623.36K |  868 | 0:02'51'' |
| Q20L60_4000000 |   977 |  1.6M | 1715 |      1435 | 767.32K | 531 |       724 | 833.17K | 1184 | 0:02'54'' |
| Q25L60_1000000 | 18201 | 2.04M |  222 |     18384 |   2.01M | 184 |       752 |  29.52K |   38 | 0:01'42'' |
| Q25L60_2000000 | 10804 | 2.04M |  345 |     10996 |      2M | 293 |       727 |  37.77K |   52 | 0:02'32'' |
| Q25L60_3000000 |  3585 | 2.03M |  824 |      3879 |   1.88M | 611 |       765 | 155.13K |  213 | 0:02'58'' |
| Q25L60_4000000 |  2270 |    2M | 1139 |      2532 |   1.72M | 757 |       786 | 283.29K |  382 | 0:03'38'' |
| Q30L60_1000000 | 20872 | 2.04M |  205 |     20872 |   2.01M | 165 |       721 |  28.47K |   40 | 0:01'57'' |
| Q30L60_2000000 | 20188 | 2.04M |  219 |     20628 |   2.01M | 178 |       762 |  31.84K |   41 | 0:02'36'' |
| Q30L60_3000000 | 16937 | 2.04M |  242 |     17918 |   2.01M | 201 |       726 |  29.25K |   41 | 0:03'19'' |
| Q30L60_4000000 | 14239 | 2.03M |  279 |     14269 |      2M | 228 |       752 |  37.14K |   51 | 0:03'35'' |

## Ngon: merge anchors

```bash
BASE_DIR=$HOME/data/anchr/Ngon
cd ${BASE_DIR}

# merge anchors
mkdir -p merge
anchr contained \
    Q20L60_1000000/anchor/pe.anchor.fa \
    Q20L60_2000000/anchor/pe.anchor.fa \
    Q20L60_3000000/anchor/pe.anchor.fa \
    Q25L60_1000000/anchor/pe.anchor.fa \
    Q25L60_2000000/anchor/pe.anchor.fa \
    Q25L60_3000000/anchor/pe.anchor.fa \
    Q25L60_4000000/anchor/pe.anchor.fa \
    Q30L60_1000000/anchor/pe.anchor.fa \
    Q30L60_2000000/anchor/pe.anchor.fa \
    Q30L60_3000000/anchor/pe.anchor.fa \
    Q30L60_4000000/anchor/pe.anchor.fa \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.contained.fasta
anchr orient merge/anchor.contained.fasta --len 1000 --idt 0.98 -o merge/anchor.orient.fasta
anchr merge merge/anchor.orient.fasta --len 1000 --idt 0.999 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.merge.fasta

# merge others
anchr contained \
    Q20L60_2000000/anchor/pe.others.fa \
    Q25L60_2000000/anchor/pe.others.fa \
    Q30L60_2000000/anchor/pe.others.fa \
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
    merge/anchor.merge.fasta \
    merge/others.merge.fasta \
    1_genome/paralogs.fas \
    --label "merge,others,paralogs" \
    -o 9_qa

```

## Ngon: 3GS

```bash
BASE_DIR=$HOME/data/anchr/Ngon
cd ${BASE_DIR}

canu \
    -p Ngon -d canu-raw-40x \
    gnuplot=$(brew --prefix)/Cellar/$(brew list --versions gnuplot | sed 's/ /\//')/bin/gnuplot \
    genomeSize=2.3m \
    -pacbio-raw 3_pacbio/pacbio.40x.fasta

canu \
    -p Ngon -d canu-raw-80x \
    gnuplot=$(brew --prefix)/Cellar/$(brew list --versions gnuplot | sed 's/ /\//')/bin/gnuplot \
    genomeSize=2.3m \
    -pacbio-raw 3_pacbio/pacbio.80x.fasta

faops n50 -S -C canu-raw-40x/Ngon.trimmedReads.fasta.gz
faops n50 -S -C canu-raw-80x/Ngon.trimmedReads.fasta.gz

```

## Ngon: expand anchors

* anchorLong

```bash
BASE_DIR=$HOME/data/anchr/Ngon
cd ${BASE_DIR}

anchr cover \
    --parallel 16 \
    -c 2 -m 40 \
    -b 20 --len 1000 --idt 0.9 \
    merge/anchor.merge.fasta \
    canu-raw-40x/Ngon.trimmedReads.fasta.gz \
    -o merge/anchor.cover.fasta

rm -fr anchorLong
anchr overlap2 \
    --parallel 16 \
    merge/anchor.cover.fasta \
    canu-raw-40x/Ngon.trimmedReads.fasta.gz \
    -d anchorLong \
    -b 20 --len 1000 --idt 0.98

anchr overlap \
    merge/anchor.cover.fasta \
    --serial --len 10 --idt 0.9999 \
    -o stdout \
    | perl -nla -e '
        BEGIN {
            our %seen;
            our %count_of;
        }

        @F == 13 or next;
        $F[3] > 0.9999 or next;

        my $pair = join( "-", sort { $a <=> $b } ( $F[0], $F[1], ) );
        next if $seen{$pair};
        $seen{$pair} = $_;

        $count_of{ $F[0] }++;
        $count_of{ $F[1] }++;

        END {
            for my $pair ( keys %seen ) {
                my ($f_id, $g_id) = split "-", $pair;
                next if $count_of{$f_id} > 2;
                next if $count_of{$g_id} > 2;
                print $seen{$pair};
            }
        }
    ' \
    | sort -k 1n,1n -k 2n,2n \
    > anchorLong/anchor.ovlp.tsv

ANCHOR_COUNT=$(faops n50 -H -N 0 -C anchorLong/anchor.fasta)
echo ${ANCHOR_COUNT}

rm -fr anchorLong/group
anchr group \
    anchorLong/anchorLong.db \
    anchorLong/anchorLong.ovlp.tsv \
    --oa anchorLong/anchor.ovlp.tsv \
    --parallel 16 \
    --range "1-${ANCHOR_COUNT}" --len 1000 --idt 0.98 --max "-14" -c 4 --png

pushd ${BASE_DIR}/anchorLong
cat group/groups.txt \
    | parallel --no-run-if-empty -j 8 '
        echo {};
        anchr orient \
            --len 1000 --idt 0.98 \
            group/{}.anchor.fasta \
            group/{}.long.fasta \
            -r group/{}.restrict.tsv \
            -o group/{}.strand.fasta;

        anchr overlap --len 1000 --idt 0.98 \
            group/{}.strand.fasta \
            -o stdout \
            | anchr restrict \
                stdin group/{}.restrict.tsv \
                -o group/{}.ovlp.tsv;

        anchr overlap --len 10 --idt 0.9999 \
            group/{}.strand.fasta \
            -o stdout \
            | perl -nla -e '\''
                @F == 13 or next;
                $F[3] > 0.98 or next;
                $F[9] == 0 or next;
                $F[5] > 0 and $F[6] == $F[7] or next;
                /anchor.+anchor/ or next;
                print;
            '\'' \
            > group/{}.anchor.ovlp.tsv
            
        anchr layout \
            group/{}.ovlp.tsv \
            group/{}.relation.tsv \
            group/{}.strand.fasta \
            --oa group/{}.anchor.ovlp.tsv \
            --png \
            -o group/{}.contig.fasta
    '
popd

# false strand
cat anchorLong/group/*.ovlp.tsv \
    | perl -nla -e '/anchor.+long/ or next; print $F[0] if $F[8] == 1;' \
    | sort | uniq -c

cat \
   anchorLong/group/non_grouped.fasta\
   anchorLong/group/*.contig.fasta \
   | faops filter -l 0 -a 1000 stdin anchorLong/contig.fasta

```

* contigTrim

```bash
BASE_DIR=$HOME/data/anchr/Ngon
cd ${BASE_DIR}

rm -fr contigTrim
anchr overlap2 \
    --parallel 16 \
    anchorLong/contig.fasta \
    canu-raw-40x/Ngon.contigs.fasta \
    -d contigTrim \
    -b 20 --len 1000 --idt 0.98 --all

CONTIG_COUNT=$(faops n50 -H -N 0 -C contigTrim/anchor.fasta)
echo ${CONTIG_COUNT}

rm -fr contigTrim/group
anchr group \
    --parallel 16 \
    --keep \
    contigTrim/anchorLong.db \
    contigTrim/anchorLong.ovlp.tsv \
    --range "1-${CONTIG_COUNT}" --len 1000 --idt 0.98 --max 20000 -c 1

pushd ${BASE_DIR}/contigTrim
cat group/groups.txt \
    | parallel --no-run-if-empty -j 8 '
        echo {};
        anchr orient \
            --len 1000 --idt 0.98 \
            group/{}.anchor.fasta \
            group/{}.long.fasta \
            -r group/{}.restrict.tsv \
            -o group/{}.strand.fasta;

        anchr overlap --len 1000 --idt 0.98 \
            group/{}.strand.fasta \
            -o stdout \
            | anchr restrict \
                stdin group/{}.restrict.tsv \
                -o group/{}.ovlp.tsv;

        anchr layout \
            group/{}.ovlp.tsv \
            group/{}.relation.tsv \
            group/{}.strand.fasta \
            -o group/{}.contig.fasta
    '
popd

cat \
    contigTrim/group/non_grouped.fasta \
    contigTrim/group/*.contig.fasta \
    >  contigTrim/contig.fasta

```

* quast

```bash
BASE_DIR=$HOME/data/anchr/Ngon
cd ${BASE_DIR}

rm -fr 9_qa_contig
quast --no-check --threads 16 \
    -R 1_genome/genome.fa \
    merge/anchor.merge.fasta \
    merge/anchor.cover.fasta \
    anchorLong/contig.fasta \
    contigTrim/contig.fasta \
    canu-raw-40x/Ngon.contigs.fasta \
    canu-raw-80x/Ngon.contigs.fasta \
    1_genome/paralogs.fas \
    --label "merge,cover,contig,contigTrim,canu-40x,canu-80x,paralogs" \
    -o 9_qa_contig

```

* Stats

```bash
BASE_DIR=$HOME/data/anchr/Ngon
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
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchor.cover"; faops n50 -H -S -C merge/anchor.cover.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchorLong"; faops n50 -H -S -C anchorLong/contig.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "contigTrim"; faops n50 -H -S -C contigTrim/contig.fasta;) >> stat3.md

cat stat3.md
```

| Name         |     N50 |     Sum |   # |
|:-------------|--------:|--------:|----:|
| Genome       | 2153922 | 2153922 |   1 |
| Paralogs     |    4318 |  142093 |  53 |
| anchor.merge |   23012 | 2014543 | 152 |
| others.merge |    2347 |    2347 |   1 |
| anchor.cover |   19415 | 1876453 | 161 |
| anchorLong   |   29718 | 1874102 | 124 |
| contigTrim   |  465723 | 1839660 |  22 |

* Clear QxxLxxx.

```bash
BASE_DIR=$HOME/data/anchr/Ngon
cd ${BASE_DIR}

rm -fr 2_illumina/Q{20,25,30}L*
rm -fr Q{20,25,30}L*
```

# Neisseria meningitidis FDAARGOS_209, 脑膜炎奈瑟氏菌

Project
[SRP040661](https://trace.ncbi.nlm.nih.gov/Traces/sra/?study=SRP040661)

## Nmen: download

* Reference genome

    * Strain: Neisseria meningitidis MC58
    * Taxid: [122586](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=122586)
    * RefSeq assembly accession:
      [GCF_000008805.1](ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/008/805/GCF_000008805.1_ASM880v1/GCF_000008805.1_ASM880v1_assembly_report.txt)
    * Proportion of paralogs (> 1000 bp): 0

```bash
mkdir -p ~/data/anchr/Nmen/1_genome
cd ~/data/anchr/Nmen/1_genome

aria2c -x 9 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/008/805/GCF_000008805.1_ASM880v1/GCF_000008805.1_ASM880v1_genomic.fna.gz

TAB=$'\t'
cat <<EOF > replace.tsv
NC_003112.2${TAB}1
EOF

faops replace GCF_000008805.1_ASM880v1_genomic.fna.gz replace.tsv genome.fa

cp ~/data/anchr/paralogs/otherbac/Results/Nmen/Nmen.multi.fas paralogs.fas

```

* Illumina

    * [SRX2179304](https://www.ncbi.nlm.nih.gov/sra/SRX2179304) SRR4272082

```bash
mkdir -p ~/data/anchr/Nmen/2_illumina
cd ~/data/anchr/Nmen/2_illumina

cat << EOF > sra_ftp.txt
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR427/002/SRR4272082/SRR4272082_1.fastq.gz
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR427/002/SRR4272082/SRR4272082_2.fastq.gz
EOF

aria2c -x 9 -s 3 -c -i sra_ftp.txt

cat << EOF > sra_md5.txt
72eda37b3158f5668d6fe8ce62c6db7a SRR4272082_1.fastq.gz
4db52e50a273945315af9aa4582c6dc2 SRR4272082_2.fastq.gz
EOF

md5sum --check sra_md5.txt

ln -s SRR4272082_1.fastq.gz R1.fq.gz
ln -s SRR4272082_2.fastq.gz R2.fq.gz

```

* PacBio

```bash
mkdir -p ~/data/anchr/Nmen/3_pacbio
cd ~/data/anchr/Nmen/3_pacbio

# download from sra
cat <<EOF > hdf5.txt
http://sra-download.ncbi.nlm.nih.gov/srapub_files/SRR4272081_SRR4272081_hdf5.tgz
EOF
aria2c -x 9 -s 3 -c -i hdf5.txt

# untar
mkdir -p ~/data/anchr/Nmen/3_pacbio/untar
cd ~/data/anchr/Nmen/3_pacbio
tar xvfz SRR4272081_SRR4272081_hdf5.tgz --directory untar

# convert .bax.h5 to .subreads.bam
mkdir -p ~/data/anchr/Nmen/3_pacbio/bam
cd ~/data/anchr/Nmen/3_pacbio/bam

source ~/share/pitchfork/deployment/setup-env.sh
for movie in m150116;
do 
    bax2bam ~/data/anchr/Nmen/3_pacbio/untar/${movie}*.bax.h5
done

# convert .subreads.bam to fasta
mkdir -p ~/data/anchr/Nmen/3_pacbio/fasta

for movie in m150116;
do
    if [ ! -e ~/data/anchr/Nmen/3_pacbio/bam/${movie}*.subreads.bam ]; then
        continue
    fi

    samtools fasta \
        ~/data/anchr/Nmen/3_pacbio/bam/${movie}*.subreads.bam \
        > ~/data/anchr/Nmen/3_pacbio/fasta/${movie}.fasta
done

cd ~/data/anchr/Nmen
cat 3_pacbio/fasta/*.fasta > 3_pacbio/pacbio.fasta

faops n50 3_pacbio/pacbio.fasta

rm -fr ~/data/anchr/Nmen/3_pacbio/untar
```

* FastQC

```bash
BASE_NAME=Nmen
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/fastqc
cd 2_illumina/fastqc

fastqc -t 16 \
    ../R1.fq.gz ../R2.fq.gz \
    -o .

```

## Nmen: combinations of different quality values and read lengths

* qual: 20, 25, and 30
* len: 60

```bash
BASE_NAME=Nmen
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
REAL_G=2272360
READ_COUNT=$(( 200 / 2 * ${REAL_G} / 101 ))
parallel --no-run-if-empty -j 2 "
    seqtk sample \
        -s${READ_COUNT} \
        2_illumina/{}.uniq.fq.gz \
        ${READ_COUNT} \
        | pigz -p 4 -c \
        > 2_illumina/{}.200x.fq.gz
    " ::: R1 R2

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
        ../R1.200x.fq.gz ../R2.200x.fq.gz \
        -o stdout \
        | bash
    " ::: 20 25 30 ::: 60

```

* Stats

```bash
BASE_NAME=Nmen
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
    $(echo "PacBio";   faops n50 -H -S -C 3_pacbio/pacbio.fasta;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Illumina"; faops n50 -H -S -C 2_illumina/R1.fq.gz 2_illumina/R2.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "uniq";     faops n50 -H -S -C 2_illumina/R1.uniq.fq.gz 2_illumina/R2.uniq.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "200x";     faops n50 -H -S -C 2_illumina/R1.200x.fq.gz 2_illumina/R2.200x.fq.gz;) >> stat.md

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
| Genome   | 2272360 |    2272360 |        1 |
| Paralogs |       0 |          0 |        0 |
| PacBio   |    9603 |  402166610 |    58711 |
| Illumina |     101 | 1395253390 | 13814390 |
| uniq     |     101 | 1389594158 | 13758358 |
| 200x     |     101 |  454471922 |  4499722 |
| Q20L60   |     101 |  383136380 |  3873164 |
| Q25L60   |     101 |  330579421 |  3379270 |
| Q30L60   |     101 |  277833033 |  2980121 |

## Nmen: quorum

```bash
BASE_NAME=Nmen
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

```

Clear intermediate files.

```bash
BASE_NAME=Nmen
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
BASE_NAME=Nmen
cd ${HOME}/data/anchr/${BASE_NAME}

REAL_G=2272360

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
| Q20L60 | 383.14M | 168.6 | 342.54M |  150.7 |  10.596% |      98 | "71" | 2.27M | 2.95M |     1.30 | 0:01'27'' |
| Q25L60 | 330.58M | 145.5 | 302.59M |  133.2 |   8.466% |      98 | "71" | 2.27M | 2.77M |     1.22 | 0:01'18'' |
| Q30L60 | 278.35M | 122.5 |  259.5M |  114.2 |   6.772% |      95 | "65" | 2.27M | 2.64M |     1.16 | 0:01'03'' |

* kmergenie

```bash
BASE_NAME=Nmen
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/kmergenie
cd 2_illumina/kmergenie

kmergenie -l 21 -k 91 -s 10 -t 8 ../R1.fq.gz -o oriR1
kmergenie -l 21 -k 91 -s 10 -t 8 ../R2.fq.gz -o oriR2
kmergenie -l 21 -k 91 -s 10 -t 8 ../Q30L60/pe.cor.fa -o Q30L60

```

```bash
BASE_DIR=$HOME/data/anchr/Nmen
cd ${BASE_DIR}

head -n 25000 3_pacbio/pacbio.fasta > 3_pacbio/pacbio.40x.fasta
faops n50 -S -C 3_pacbio/pacbio.40x.fasta

head -n 50000 3_pacbio/pacbio.fasta > 3_pacbio/pacbio.80x.fasta
faops n50 -S -C 3_pacbio/pacbio.80x.fasta

```

## Nmen: down sampling

```bash
BASE_NAME=Nmen
cd ${HOME}/data/anchr/${BASE_NAME}

REAL_G=2272360

for QxxLxx in $( parallel "echo 'Q{1}L{2}'" ::: 25 30 ::: 60 ); do
    echo "==> ${QxxLxx}"

    if [ ! -e 2_illumina/${QxxLxx}/pe.cor.fa ]; then
        echo "2_illumina/${QxxLxx}/pe.cor.fa not exists"
        continue;
    fi

    for X in 40 80 120 160; do
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

## Nmen: k-unitigs and anchors (sampled)

```bash
BASE_NAME=Nmen
cd ${HOME}/data/anchr/${BASE_NAME}

# k-unitigs (sampled)
parallel --no-run-if-empty -j 3 "
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
        -p 8 \
        --kmer 31,41,51,61,71,81 \
        -o kunitigs.sh
    bash kunitigs.sh

    echo >&2
    " ::: 25 30 ::: 60 ::: 40 80 120 160 ::: 000 001 002 003 004 005 006

# anchors (sampled)
parallel --no-run-if-empty -j 3 "
    echo >&2 '==> Group Q{1}L{2}X{3}P{4}'

    if [ -e Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa ]; then
        exit;
    fi

    rm -fr Q{1}L{2}X{3}P{4}/anchor
    bash ~/Scripts/cpan/App-Anchr/share/anchor.sh Q{1}L{2}X{3}P{4} 8 false
    
    echo >&2
    " ::: 25 30 ::: 60 ::: 40 80 120 160 ::: 000 001 002 003 004 005 006

# Stats of anchors
REAL_G=2272360

bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 header \
    > stat2.md

parallel -k --no-run-if-empty -j 6 "
    if [ ! -e Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa ]; then
        exit;
    fi

    bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 Q{1}L{2}X{3}P{4} ${REAL_G}
    " ::: 25 30 ::: 60 ::: 40 80 120 160 ::: 000 001 002 003 004 005 006 \
    >> stat2.md

cat stat2.md
```

| Name           |  SumCor | CovCor | N50SR |   Sum |   # | N50Anchor |   Sum |   # | N50Others |     Sum |   # |                Kmer | RunTimeKU | RunTimeAN |
|:---------------|--------:|-------:|------:|------:|----:|----------:|------:|----:|----------:|--------:|----:|--------------------:|----------:|:----------|
| Q25L60X40P000  |  90.89M |   40.0 |  8433 | 2.12M | 391 |      8591 | 2.04M | 321 |       961 |  76.91K |  70 | "31,41,51,61,71,81" | 0:02'53'' | 0:01'13'' |
| Q25L60X40P001  |  90.89M |   40.0 |  8424 | 2.14M | 392 |      8409 | 2.04M | 331 |      9874 | 102.57K |  61 | "31,41,51,61,71,81" | 0:02'52'' | 0:00'55'' |
| Q25L60X40P002  |  90.89M |   40.0 |  8424 | 2.16M | 401 |      8526 | 2.03M | 320 |      5808 | 138.15K |  81 | "31,41,51,61,71,81" | 0:02'47'' | 0:01'12'' |
| Q25L60X80P000  | 181.79M |   80.0 |  8256 | 2.14M | 424 |      8379 | 2.05M | 347 |       951 |  84.91K |  77 | "31,41,51,61,71,81" | 0:04'33'' | 0:01'37'' |
| Q25L60X120P000 | 272.68M |  120.0 |  7764 | 2.15M | 477 |      7854 | 2.05M | 372 |       832 |  98.28K | 105 | "31,41,51,61,71,81" | 0:05'58'' | 0:02'04'' |
| Q30L60X40P000  |  90.89M |   40.0 |  8732 | 2.12M | 392 |      8901 | 2.04M | 310 |       867 |  76.48K |  82 | "31,41,51,61,71,81" | 0:03'06'' | 0:01'17'' |
| Q30L60X40P001  |  90.89M |   40.0 |  8720 | 2.11M | 392 |      8871 | 2.06M | 315 |       706 |  55.09K |  77 | "31,41,51,61,71,81" | 0:02'44'' | 0:01'05'' |
| Q30L60X80P000  | 181.79M |   80.0 |  9268 | 2.13M | 369 |      9632 | 2.05M | 302 |       935 |  76.24K |  67 | "31,41,51,61,71,81" | 0:02'41'' | 0:01'29'' |

## Nmen: merge anchors

```bash
BASE_NAME=Nmen
cd ${HOME}/data/anchr/${BASE_NAME}

# merge anchors
mkdir -p merge
anchr contained \
    $(
        parallel -k --no-run-if-empty -j 6 "
            if [ -e Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa ]; then
                echo Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa
            fi
            " ::: 25 30 ::: 60 ::: 40 80 120 160 ::: 000 001 002 003 004 005 006
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
            " ::: 25 30 ::: 60 ::: 40 80 120 160 ::: 000 001 002 003 004 005 006
    ) \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.contained.fasta
anchr orient merge/others.contained.fasta --len 1000 --idt 0.98 -o merge/others.orient.fasta
anchr merge merge/others.orient.fasta --len 1000 --idt 0.999 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.merge.fasta

# anchors sorted on ref
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
    merge/anchor.merge.fasta \
    merge/others.merge.fasta \
    1_genome/paralogs.fas \
    --label "merge,others,paralogs" \
    -o 9_qa

```

## Nmen: 3GS

```bash
BASE_DIR=$HOME/data/anchr/Nmen
cd ${BASE_DIR}

canu \
    -p Nmen -d canu-raw-40x \
    gnuplot=$(brew --prefix)/Cellar/$(brew list --versions gnuplot | sed 's/ /\//')/bin/gnuplot \
    genomeSize=2.3m \
    -pacbio-raw 3_pacbio/pacbio.40x.fasta

canu \
    -p Nmen -d canu-raw-80x \
    gnuplot=$(brew --prefix)/Cellar/$(brew list --versions gnuplot | sed 's/ /\//')/bin/gnuplot \
    genomeSize=2.3m \
    -pacbio-raw 3_pacbio/pacbio.80x.fasta

faops n50 -S -C canu-raw-40x/Nmen.trimmedReads.fasta.gz
faops n50 -S -C canu-raw-80x/Nmen.trimmedReads.fasta.gz

```

## Nmen: expand anchors

* anchorLong

```bash
BASE_NAME=Nmen
cd ${HOME}/data/anchr/${BASE_NAME}

anchr cover \
    --parallel 16 \
    -c 2 -m 40 \
    -b 20 --len 1000 --idt 0.9 \
    merge/anchor.merge.fasta \
    canu-raw-40x/${BASE_NAME}.trimmedReads.fasta.gz \
    -o merge/anchor.cover.fasta

rm -fr anchorLong
anchr overlap2 \
    --parallel 16 \
    merge/anchor.cover.fasta \
    canu-raw-40x/${BASE_NAME}.trimmedReads.fasta.gz \
    -d anchorLong \
    -b 20 --len 1000 --idt 0.98

anchr overlap \
    merge/anchor.cover.fasta \
    --serial --len 10 --idt 0.9999 \
    -o stdout \
    | perl -nla -e '
        BEGIN {
            our %seen;
            our %count_of;
        }

        @F == 13 or next;
        $F[3] > 0.9999 or next;

        my $pair = join( "-", sort { $a <=> $b } ( $F[0], $F[1], ) );
        next if $seen{$pair};
        $seen{$pair} = $_;

        $count_of{ $F[0] }++;
        $count_of{ $F[1] }++;

        END {
            for my $pair ( keys %seen ) {
                my ($f_id, $g_id) = split "-", $pair;
                next if $count_of{$f_id} > 2;
                next if $count_of{$g_id} > 2;
                print $seen{$pair};
            }
        }
    ' \
    | sort -k 1n,1n -k 2n,2n \
    > anchorLong/anchor.ovlp.tsv

ANCHOR_COUNT=$(faops n50 -H -N 0 -C anchorLong/anchor.fasta)
echo ${ANCHOR_COUNT}

rm -fr anchorLong/group
anchr group \
    anchorLong/anchorLong.db \
    anchorLong/anchorLong.ovlp.tsv \
    --oa anchorLong/anchor.ovlp.tsv \
    --parallel 16 \
    --range "1-${ANCHOR_COUNT}" --len 1000 --idt 0.98 --max "-14" -c 4

pushd anchorLong
cat group/groups.txt \
    | parallel --no-run-if-empty -j 8 '
        echo {};
        anchr orient \
            --len 1000 --idt 0.98 \
            group/{}.anchor.fasta \
            group/{}.long.fasta \
            -r group/{}.restrict.tsv \
            -o group/{}.strand.fasta;

        anchr overlap --len 1000 --idt 0.98 \
            group/{}.strand.fasta \
            -o stdout \
            | anchr restrict \
                stdin group/{}.restrict.tsv \
                -o group/{}.ovlp.tsv;

        anchr overlap --len 10 --idt 0.9999 \
            group/{}.strand.fasta \
            -o stdout \
            | perl -nla -e '\''
                @F == 13 or next;
                $F[3] > 0.98 or next;
                $F[9] == 0 or next;
                $F[5] > 0 and $F[6] == $F[7] or next;
                /anchor.+anchor/ or next;
                print;
            '\'' \
            > group/{}.anchor.ovlp.tsv
            
        anchr layout \
            group/{}.ovlp.tsv \
            group/{}.relation.tsv \
            group/{}.strand.fasta \
            --oa group/{}.anchor.ovlp.tsv \
            -o group/{}.contig.fasta
    '
popd

# false strand
cat anchorLong/group/*.ovlp.tsv \
    | perl -nla -e '/anchor.+long/ or next; print $F[0] if $F[8] == 1;' \
    | sort | uniq -c

cat \
   anchorLong/group/non_grouped.fasta\
   anchorLong/group/*.contig.fasta \
   | faops filter -l 0 -a 1000 stdin anchorLong/contig.fasta

```

* contigTrim

```bash
BASE_NAME=Nmen
cd ${HOME}/data/anchr/${BASE_NAME}

rm -fr contigTrim
anchr overlap2 \
    --parallel 16 \
    anchorLong/contig.fasta \
    canu-raw-40x/${BASE_NAME}.contigs.fasta \
    -d contigTrim \
    -b 20 --len 1000 --idt 0.98 --all

CONTIG_COUNT=$(faops n50 -H -N 0 -C contigTrim/anchor.fasta)
echo ${CONTIG_COUNT}

rm -fr contigTrim/group
anchr group \
    --parallel 16 \
    --keep \
    contigTrim/anchorLong.db \
    contigTrim/anchorLong.ovlp.tsv \
    --range "1-${CONTIG_COUNT}" --len 1000 --idt 0.98 --max 20000 -c 1

pushd contigTrim
cat group/groups.txt \
    | parallel --no-run-if-empty -j 8 '
        echo {};
        anchr orient \
            --len 1000 --idt 0.98 \
            group/{}.anchor.fasta \
            group/{}.long.fasta \
            -r group/{}.restrict.tsv \
            -o group/{}.strand.fasta;

        anchr overlap --len 1000 --idt 0.98 --all \
            group/{}.strand.fasta \
            -o stdout \
            | anchr restrict \
                stdin group/{}.restrict.tsv \
                -o group/{}.ovlp.tsv;

        anchr layout \
            group/{}.ovlp.tsv \
            group/{}.relation.tsv \
            group/{}.strand.fasta \
            -o group/{}.contig.fasta
    '
popd

cat \
    contigTrim/group/non_grouped.fasta \
    contigTrim/group/*.contig.fasta \
    >  contigTrim/contig.fasta

```

* quast

```bash
BASE_NAME=Nmen
cd ${HOME}/data/anchr/${BASE_NAME}

rm -fr 9_qa_contig
quast --no-check --threads 16 \
    -R 1_genome/genome.fa \
    merge/anchor.merge.fasta \
    merge/anchor.cover.fasta \
    anchorLong/contig.fasta \
    contigTrim/contig.fasta \
    canu-raw-40x/Nmen.contigs.fasta \
    canu-raw-80x/Nmen.contigs.fasta \
    1_genome/paralogs.fas \
    --label "merge,cover,contig,contigTrim,canu-40x,canu-80x,paralogs" \
    -o 9_qa_contig

```

* Stats

```bash
BASE_NAME=Nmen
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
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchor.cover"; faops n50 -H -S -C merge/anchor.cover.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchorLong"; faops n50 -H -S -C anchorLong/contig.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "contigTrim"; faops n50 -H -S -C contigTrim/contig.fasta;) >> stat3.md

cat stat3.md
```

| Name         |     N50 |     Sum |   # |
|:-------------|--------:|--------:|----:|
| Genome       | 2272360 | 2272360 |   1 |
| Paralogs     |       0 |       0 |   0 |
| anchor.merge |    9877 | 2075643 | 295 |
| others.merge |    9917 |   47940 |  11 |
| anchor.cover |    6814 | 1583544 | 313 |
| anchorLong   |    7239 | 1582929 | 302 |
| contigTrim   |   15255 | 1826314 | 225 |

* Clear QxxLxxXxx.

```bash
BASE_NAME=Nmen
cd ${HOME}/data/anchr/${BASE_NAME}

rm -fr 2_illumina/Q{20,25,30}L{1,60,90,120}X*
rm -fr Q{20,25,30}L{1,60,90,120}X*
```

# Bordetella pertussis FDAARGOS_195, 百日咳博德特氏杆菌

* Project
[SRP040661](https://trace.ncbi.nlm.nih.gov/Traces/sra/?study=SRP040661)

* Other name: ATCC BAA-589D-5; Tohama 1;

* BioSample: [SAMN04875532](https://www.ncbi.nlm.nih.gov/biosample/SAMN04875532)

## Bper: download

* Reference genome

    * Strain: Bordetella pertussis Tohama I
    * Taxid: [257313](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=257313)
    * RefSeq assembly accession:
      [GCF_000195715.1](ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/195/715/GCF_000195715.1_ASM19571v1/GCF_000195715.1_ASM19571v1_assembly_report.txt)
    * Proportion of paralogs (> 1000 bp): 0.0201

```bash
mkdir -p ~/data/anchr/Bper/1_genome
cd ~/data/anchr/Bper/1_genome

aria2c -x 9 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/195/715/GCF_000195715.1_ASM19571v1/GCF_000195715.1_ASM19571v1_genomic.fna.gz

TAB=$'\t'
cat <<EOF > replace.tsv
NC_002929.2${TAB}1
EOF

faops replace GCF_000195715.1_ASM19571v1_genomic.fna.gz replace.tsv genome.fa

cp ~/data/anchr/paralogs/otherbac/Results/Bper/Bper.multi.fas paralogs.fas

```

* Illumina

    * [SRX2179101](https://www.ncbi.nlm.nih.gov/sra/SRX2179101) SRR4271511
    * [SRX2179104](https://www.ncbi.nlm.nih.gov/sra/SRX2179104) SRR4271510

```bash
mkdir -p ~/data/anchr/Bper/2_illumina
cd ~/data/anchr/Bper/2_illumina

cat << EOF > sra_ftp.txt
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR427/001/SRR4271511/SRR4271511_1.fastq.gz
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR427/001/SRR4271511/SRR4271511_2.fastq.gz
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR427/000/SRR4271510/SRR4271510_1.fastq.gz
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR427/000/SRR4271510/SRR4271510_2.fastq.gz
EOF

aria2c -x 9 -s 3 -c -i sra_ftp.txt

cat << EOF > sra_md5.txt
0177ba6d05bfbf8a77f47b56cceb7c2e SRR4271511_1.fastq.gz
bf80b95eef4b86ad09cddec0c323415a SRR4271511_2.fastq.gz
1e52042a69c78ad7e3cd4dde3cc36721 SRR4271510_1.fastq.gz
b4d60d4ec59cc7c6dcd12e235981dfda SRR4271510_2.fastq.gz
EOF

md5sum --check sra_md5.txt

gzip -d -c SRR427151{1,0}_1.fastq.gz | pigz -p 8 -c > R1.fq.gz
gzip -d -c SRR427151{1,0}_2.fastq.gz | pigz -p 8 -c > R2.fq.gz

```

## Bper: combinations of different quality values and read lengths

* qual: 20, 25, and 30
* len: 60

```bash
BASE_DIR=$HOME/data/anchr/Bper

cd ${BASE_DIR}
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

cd ${BASE_DIR}
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

cd ${BASE_DIR}
parallel --no-run-if-empty -j 4 "
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

```

* Stats

```bash
BASE_DIR=$HOME/data/anchr/Bper
cd ${BASE_DIR}

printf "| %s | %s | %s | %s |\n" \
    "Name" "N50" "Sum" "#" \
    > stat.md
printf "|:--|--:|--:|--:|\n" >> stat.md

printf "| %s | %s | %s | %s |\n" \
    $(echo "Genome";   faops n50 -H -S -C 1_genome/genome.fa;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Paralogs";   faops n50 -H -S -C 1_genome/paralogs.fas;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Illumina"; faops n50 -H -S -C 2_illumina/R1.fq.gz 2_illumina/R2.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "PacBio";   faops n50 -H -S -C 3_pacbio/pacbio.fasta;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "uniq";   faops n50 -H -S -C 2_illumina/R1.uniq.fq.gz 2_illumina/R2.uniq.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "scythe";   faops n50 -H -S -C 2_illumina/R1.scythe.fq.gz 2_illumina/R2.scythe.fq.gz;) >> stat.md

for qual in 20 25 30; do
    for len in 60; do
        DIR_COUNT="${BASE_DIR}/2_illumina/Q${qual}L${len}"

        printf "| %s | %s | %s | %s |\n" \
            $(echo "Q${qual}L${len}"; faops n50 -H -S -C ${DIR_COUNT}/R1.fq.gz  ${DIR_COUNT}/R2.fq.gz;) \
            >> stat.md
    done
done

cat stat.md
```

| Name     |     N50 |        Sum |        # |
|:---------|--------:|-----------:|---------:|
| Genome   | 4086189 |    4086189 |        1 |
| Paralogs |         |            |          |
| Illumina |     101 | 1673028438 | 16564638 |
| PacBio   |         |            |          |
| uniq     |     101 | 1655310614 | 16389214 |
| scythe   |     101 | 1610064719 | 16389214 |
| Q20L60   |     101 | 1293069038 | 13162032 |
| Q25L60   |     101 | 1054727096 | 10895386 |
| Q30L60   |     101 |  622654879 |  6731812 |

## Bper: down sampling

```bash
BASE_DIR=$HOME/data/anchr/Bper
cd ${BASE_DIR}

ARRAY=(
    "2_illumina/Q20L60:Q20L60:5000000"
    "2_illumina/Q25L60:Q25L60:5000000"
    "2_illumina/Q30L60:Q30L60:3000000"
)

for group in "${ARRAY[@]}" ; do
    
    GROUP_DIR=$(group=${group} perl -e '@p = split q{:}, $ENV{group}; print $p[0];')
    GROUP_ID=$( group=${group} perl -e '@p = split q{:}, $ENV{group}; print $p[1];')
    GROUP_MAX=$(group=${group} perl -e '@p = split q{:}, $ENV{group}; print $p[2];')
    printf "==> %s \t %s \t %s\n" "$GROUP_DIR" "$GROUP_ID" "$GROUP_MAX"

    perl -e 'print 1000000 * $_, qq{\n} for 1 .. 5' \
    | parallel --no-run-if-empty -j 4 "
        if [[ {} -gt '$GROUP_MAX' ]]; then
            exit;
        fi

        echo '    ${GROUP_ID}_{}'
        mkdir -p ${BASE_DIR}/${GROUP_ID}_{}
        
        if [ -e ${BASE_DIR}/${GROUP_ID}_{}/R1.fq.gz ]; then
            exit;
        fi

        seqtk sample -s{} \
            ${BASE_DIR}/${GROUP_DIR}/R1.fq.gz {} \
            | pigz -p 4 -c > ${BASE_DIR}/${GROUP_ID}_{}/R1.fq.gz
        seqtk sample -s{} \
            ${BASE_DIR}/${GROUP_DIR}/R2.fq.gz {} \
            | pigz -p 4 -c > ${BASE_DIR}/${GROUP_ID}_{}/R2.fq.gz
    "

done

```

## Bper: generate super-reads

```bash
BASE_DIR=$HOME/data/anchr/Bper
cd ${BASE_DIR}

perl -e '
    for my $n (
        qw{
        Q20L60
        Q25L60
        Q30L60
        }
        )
    {
        for my $i ( 1 .. 5 ) {
            printf qq{%s_%d\n}, $n, ( 1000000 * $i );
        }
    }
    ' \
    | parallel --no-run-if-empty -j 3 "
        echo '==> Group {}'
        
        if [ ! -d ${BASE_DIR}/{} ]; then
            echo '    directory not exists'
            exit;
        fi        

        if [ -e ${BASE_DIR}/{}/k_unitigs.fasta ]; then
            echo '    k_unitigs.fasta already presents'
            exit;
        fi

        cd ${BASE_DIR}/{}
        anchr superreads \
            R1.fq.gz R2.fq.gz \
            --nosr -p 8 \
            --kmer 41,61,81 \
            -o superreads.sh
        bash superreads.sh
    "

```

Clear intermediate files.

```bash
BASE_DIR=$HOME/data/anchr/Bper
cd ${BASE_DIR}

find . -type f -name "quorum_mer_db.jf"          | xargs rm
find . -type f -name "k_u_hash_0"                | xargs rm
find . -type f -name "readPositionsInSuperReads" | xargs rm
find . -type f -name "*.tmp"                     | xargs rm
find . -type f -name "pe.renamed.fastq"          | xargs rm
find . -type f -name "pe.cor.sub.fa"             | xargs rm
```

## Bper: create anchors

```bash
BASE_DIR=$HOME/data/anchr/Bper
cd ${BASE_DIR}

perl -e '
    for my $n (
        qw{
        Q20L60
        Q25L60
        Q30L60
        }
        )
    {
        for my $i ( 1 .. 5 ) {
            printf qq{%s_%d\n}, $n, ( 1000000 * $i );
        }
    }
    ' \
    | parallel --no-run-if-empty -j 3 "
        echo '==> Group {}'

        if [ -e ${BASE_DIR}/{}/anchor/pe.anchor.fa ]; then
            exit;
        fi

        rm -fr ${BASE_DIR}/{}/anchor
        bash ~/Scripts/cpan/App-Anchr/share/anchor.sh ${BASE_DIR}/{} 8 false
    "

```

## Bper: results

* Stats of super-reads

```bash
BASE_DIR=$HOME/data/anchr/Bper
cd ${BASE_DIR}

REAL_G=4086189

bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 header \
    > ${BASE_DIR}/stat1.md

perl -e '
    for my $n (
        qw{
        Q20L60
        Q25L60
        Q30L60
        }
        )
    {
        for my $i ( 1 .. 5 ) {
            printf qq{%s_%d\n}, $n, ( 1000000 * $i );
        }
    }
    ' \
    | parallel -k --no-run-if-empty -j 4 "
        if [ ! -d ${BASE_DIR}/{} ]; then
            exit;
        fi

        bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 1 ${BASE_DIR}/{} ${REAL_G}
    " >> ${BASE_DIR}/stat1.md

cat stat1.md
```

* Stats of anchors

```bash
BASE_DIR=$HOME/data/anchr/Bper
cd ${BASE_DIR}

bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 header \
    > ${BASE_DIR}/stat2.md

perl -e '
    for my $n (
        qw{
        Q20L60
        Q25L60
        Q30L60
        }
        )
    {
        for my $i ( 1 .. 5 ) {
            printf qq{%s_%d\n}, $n, ( 1000000 * $i );
        }
    }
    ' \
    | parallel -k --no-run-if-empty -j 8 "
        if [ ! -e ${BASE_DIR}/{}/anchor/pe.anchor.fa ]; then
            exit;
        fi

        bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 ${BASE_DIR}/{}
    " >> ${BASE_DIR}/stat2.md

cat stat2.md
```

| Name           |   SumFq | CovFq | AvgRead |       Kmer |   SumFa | Discard% | RealG |  EstG | Est/Real | SumKU | SumSR |   RunTime |
|:---------------|--------:|------:|--------:|-----------:|--------:|---------:|------:|------:|---------:|------:|------:|----------:|
| Q20L60_1000000 |  196.5M |  48.1 |      98 | "41,61,81" | 174.49M |  11.200% | 4.09M | 3.53M |     0.86 | 3.35M |     0 | 0:02'28'' |
| Q20L60_2000000 | 392.97M |  96.2 |      98 | "41,61,81" | 350.42M |  10.828% | 4.09M | 3.76M |     0.92 | 3.49M |     0 | 0:04'13'' |
| Q20L60_3000000 | 589.47M | 144.3 |      98 | "41,61,81" | 527.09M |  10.583% | 4.09M |    4M |     0.98 | 3.49M |     0 | 0:05'46'' |
| Q20L60_4000000 | 785.92M | 192.3 |      98 | "41,61,81" | 704.37M |  10.377% | 4.09M | 4.32M |     1.06 | 3.42M |     0 | 0:07'29'' |
| Q20L60_5000000 | 982.43M | 240.4 |      98 | "41,61,81" | 882.57M |  10.165% | 4.09M | 4.68M |     1.15 | 3.26M |     0 | 0:09'27'' |
| Q25L60_1000000 | 193.62M |  47.4 |      97 | "41,61,81" |    176M |   9.104% | 4.09M | 3.49M |     0.85 | 3.31M |     0 | 0:02'24'' |
| Q25L60_2000000 | 387.23M |  94.8 |      97 | "41,61,81" |  353.2M |   8.788% | 4.09M | 3.72M |     0.91 | 3.46M |     0 | 0:04'20'' |
| Q25L60_3000000 | 580.86M | 142.2 |      97 | "41,61,81" | 530.94M |   8.594% | 4.09M | 3.99M |     0.98 | 3.53M |     0 | 0:06'14'' |
| Q25L60_4000000 | 774.45M | 189.5 |      97 | "41,61,81" | 709.38M |   8.401% | 4.09M | 4.35M |     1.06 | 3.58M |     0 | 0:07'41'' |
| Q25L60_5000000 | 968.06M | 236.9 |      97 | "41,61,81" | 888.28M |   8.242% | 4.09M | 4.75M |     1.16 | 3.61M |     0 | 0:09'43'' |
| Q30L60_1000000 | 184.98M |  45.3 |      93 | "41,61,81" | 170.81M |   7.662% | 4.09M | 3.44M |     0.84 | 3.16M |     0 | 0:02'29'' |
| Q30L60_2000000 |    370M |  90.6 |      92 | "41,61,81" | 343.25M |   7.231% | 4.09M | 3.84M |     0.94 | 3.36M |     0 | 0:04'09'' |
| Q30L60_3000000 | 554.99M | 135.8 |      92 | "41,61,81" | 516.82M |   6.878% | 4.09M | 4.35M |     1.07 | 3.46M |     0 | 0:05'33'' |

| Name           | N50SR |   Sum |    # | N50Anchor |   Sum |    # | N50Others |     Sum |    # |   RunTime |
|:---------------|------:|------:|-----:|----------:|------:|-----:|----------:|--------:|-----:|----------:|
| Q20L60_1000000 |  2742 | 3.35M | 1662 |      3114 | 2.96M | 1127 |       753 | 390.98K |  535 | 0:01'23'' |
| Q20L60_2000000 |  2254 | 3.49M | 2020 |      2579 | 2.94M | 1273 |       766 | 547.44K |  747 | 0:01'51'' |
| Q20L60_3000000 |  1735 | 3.49M | 2481 |      2108 | 2.64M | 1335 |       766 | 842.39K | 1146 | 0:02'32'' |
| Q20L60_4000000 |  1386 | 3.42M | 2875 |      1793 | 2.27M | 1291 |       748 |   1.15M | 1584 | 0:02'51'' |
| Q20L60_5000000 |  1130 | 3.26M | 3134 |      1572 | 1.85M | 1169 |       742 |   1.41M | 1965 | 0:03'05'' |
| Q25L60_1000000 |  2807 | 3.31M | 1588 |      3210 | 2.93M | 1072 |       744 | 374.64K |  516 | 0:01'22'' |
| Q25L60_2000000 |  3211 | 3.46M | 1544 |      3556 | 3.13M | 1091 |       728 | 328.02K |  453 | 0:02'10'' |
| Q25L60_3000000 |  2914 | 3.53M | 1679 |      3223 | 3.14M | 1148 |       766 | 391.06K |  531 | 0:02'53'' |
| Q25L60_4000000 |  2532 | 3.58M | 1905 |      2838 |  3.1M | 1247 |       767 | 482.46K |  658 | 0:03'36'' |
| Q25L60_5000000 |  2192 | 3.61M | 2149 |      2563 | 3.01M | 1333 |       759 |  592.4K |  816 | 0:04'09'' |
| Q30L60_1000000 |  2433 | 3.16M | 1703 |      2778 |  2.7M | 1076 |       758 | 459.36K |  627 | 0:01'29'' |
| Q30L60_2000000 |  2858 | 3.36M | 1610 |      3251 | 2.98M | 1087 |       731 | 372.53K |  523 | 0:01'44'' |
| Q30L60_3000000 |  3136 | 3.46M | 1580 |      3503 |  3.1M | 1088 |       742 | 353.88K |  492 | 0:02'18'' |

## Bper: merge anchors

```bash
BASE_DIR=$HOME/data/anchr/Bper
cd ${BASE_DIR}

# merge anchors
mkdir -p merge
anchr contained \
    Q20L60_1000000/anchor/pe.anchor.fa \
    Q20L60_2000000/anchor/pe.anchor.fa \
    Q20L60_3000000/anchor/pe.anchor.fa \
    Q20L60_4000000/anchor/pe.anchor.fa \
    Q25L60_1000000/anchor/pe.anchor.fa \
    Q25L60_2000000/anchor/pe.anchor.fa \
    Q25L60_3000000/anchor/pe.anchor.fa \
    Q25L60_4000000/anchor/pe.anchor.fa \
    Q30L60_1000000/anchor/pe.anchor.fa \
    Q30L60_2000000/anchor/pe.anchor.fa \
    Q30L60_3000000/anchor/pe.anchor.fa \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.contained.fasta
anchr orient merge/anchor.contained.fasta --len 1000 --idt 0.98 -o merge/anchor.orient.fasta
anchr merge merge/anchor.orient.fasta --len 1000 --idt 0.999 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/anchor.merge.fasta

# merge others
anchr contained \
    Q20L60_2000000/anchor/pe.others.fa \
    Q25L60_2000000/anchor/pe.others.fa \
    Q30L60_2000000/anchor/pe.others.fa \
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
    merge/anchor.merge.fasta \
    merge/others.merge.fasta \
    1_genome/paralogs.fas \
    --label "merge,others,paralogs" \
    -o 9_qa

```

* Stats

```bash
BASE_DIR=$HOME/data/anchr/Bper
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
| Genome       | 4086189 | 4086189 |   1 |
| Paralogs     |         |         |     |
| anchor.merge |    4674 | 3478267 | 986 |
| others.merge |    1024 |   52609 |  49 |

* Clear QxxLxxx.

```bash
BASE_DIR=$HOME/data/anchr/Bper
cd ${BASE_DIR}

rm -fr 2_illumina/Q{20,25,30}L*
rm -fr Q{20,25,30}L*
```

# Corynebacterium diphtheriae FDAARGOS_197, 白喉杆菌

* Project
[SRP040661](https://trace.ncbi.nlm.nih.gov/Traces/sra/?study=SRP040661)

* Other name: ATCC 700971D-5; NCTC 13129;

* BioSample: [SAMN04875534](https://www.ncbi.nlm.nih.gov/biosample/SAMN04875534)

## Cdip: download

* Reference genome

    * Strain: Corynebacterium diphtheriae NCTC 13129 (high GC Gram+)
    * Taxid: [257309](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=257309)
    * RefSeq assembly accession:
      [GCF_000195815.1](ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/195/815/GCF_000195815.1_ASM19581v1/GCF_000195815.1_ASM19581v1_assembly_report.txt)
    * Proportion of paralogs (> 1000 bp): 0.0180

```bash
mkdir -p ~/data/anchr/Cdip/1_genome
cd ~/data/anchr/Cdip/1_genome

aria2c -x 9 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/195/815/GCF_000195815.1_ASM19581v1/GCF_000195815.1_ASM19581v1_genomic.fna.gz

TAB=$'\t'
cat <<EOF > replace.tsv
NC_002935.2${TAB}1
EOF

faops replace GCF_000195815.1_ASM19581v1_genomic.fna.gz replace.tsv genome.fa

cp ~/data/anchr/paralogs/otherbac/Results/Cdip/Cdip.multi.fas paralogs.fas

```

* Illumina

    * [SRX2179108](https://www.ncbi.nlm.nih.gov/sra/SRX2179108) SRR4271515

```bash
mkdir -p ~/data/anchr/Cdip/2_illumina
cd ~/data/anchr/Cdip/2_illumina

cat << EOF > sra_ftp.txt
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR427/005/SRR4271515/SRR4271515_1.fastq.gz
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR427/005/SRR4271515/SRR4271515_2.fastq.gz
EOF

aria2c -x 9 -s 3 -c -i sra_ftp.txt

cat << EOF > sra_md5.txt
abb1c4a0140d13fa9513e445ebcb97c6 SRR4271515_1.fastq.gz
0910e7ae9d75f37a08e3b24aa75326ed SRR4271515_2.fastq.gz
EOF

md5sum --check sra_md5.txt

ln -s SRR4271515_1.fastq.gz R1.fq.gz
ln -s SRR4271515_2.fastq.gz R2.fq.gz

```

* PacBio

```bash
mkdir -p ~/data/anchr/Cdip/3_pacbio
cd ~/data/anchr/Cdip/3_pacbio

# download from sra
cat <<EOF > hdf5.txt
http://sra-download.ncbi.nlm.nih.gov/srapub_files/SRR4271514_SRR4271514_hdf5.tgz
EOF
aria2c -x 9 -s 3 -c -i hdf5.txt

# untar
mkdir -p ~/data/anchr/Cdip/3_pacbio/untar
cd ~/data/anchr/Cdip/3_pacbio
tar xvfz SRR4271514_SRR4271514_hdf5.tgz --directory untar

# convert .bax.h5 to .subreads.bam
mkdir -p ~/data/anchr/Cdip/3_pacbio/bam
cd ~/data/anchr/Cdip/3_pacbio/bam

source ~/share/pitchfork/deployment/setup-env.sh
for movie in m141028;
do 
    bax2bam ~/data/anchr/Cdip/3_pacbio/untar/${movie}*.bax.h5
done

# convert .subreads.bam to fasta
mkdir -p ~/data/anchr/Cdip/3_pacbio/fasta

for movie in m141028;
do
    if [ ! -e ~/data/anchr/Cdip/3_pacbio/bam/${movie}*.subreads.bam ]; then
        continue
    fi

    samtools fasta \
        ~/data/anchr/Cdip/3_pacbio/bam/${movie}*.subreads.bam \
        > ~/data/anchr/Cdip/3_pacbio/fasta/${movie}.fasta
done

cd ~/data/anchr/Cdip
cat 3_pacbio/fasta/*.fasta > 3_pacbio/pacbio.fasta

rm -fr ~/data/anchr/Cdip/3_pacbio/untar
```

* FastQC

```bash
BASE_NAME=Cdip
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/fastqc
cd 2_illumina/fastqc

fastqc -t 16 \
    ../R1.fq.gz ../R2.fq.gz \
    -o .

```

## Cdip: combinations of different quality values and read lengths

* qual: 20, 25, and 30
* len: 60

```bash
BASE_NAME=Cdip
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
    " ::: 20 25 30 ::: 60

```

* Stats

```bash
BASE_NAME=Cdip
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
    $(echo "PacBio";   faops n50 -H -S -C 3_pacbio/pacbio.fasta;) >> stat.md
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
    " ::: 20 25 30 ::: 60 \
    >> stat.md

cat stat.md
```

| Name     |     N50 |        Sum |        # |
|:---------|--------:|-----------:|---------:|
| Genome   | 2488635 |    2488635 |        1 |
| Paralogs |    5635 |      56210 |       18 |
| PacBio   |    8966 |  665803465 |   110317 |
| Illumina |     101 | 1124010012 | 11128812 |
| uniq     |     101 | 1120677416 | 11095816 |
| Q20L60   |     101 |  942374034 |  9521902 |
| Q25L60   |     101 |  811857109 |  8299530 |
| Q30L60   |     101 |  674398728 |  7270020 |

## Cdip: quorum

```bash
BASE_NAME=Cdip
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

```

Clear intermediate files.

```bash
BASE_NAME=Cdip
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
BASE_NAME=Cdip
cd ${HOME}/data/anchr/${BASE_NAME}

REAL_G=2488635

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
| Q20L60 | 942.37M | 378.7 | 839.01M |  337.1 |  10.969% |      98 | "51" | 2.49M | 2.92M |     1.17 | 0:03'14'' |
| Q25L60 | 811.86M | 326.2 | 742.27M |  298.3 |   8.571% |      97 | "51" | 2.49M | 2.58M |     1.04 | 0:02'48'' |
| Q30L60 | 675.61M | 271.5 | 631.39M |  253.7 |   6.545% |      93 | "43" | 2.49M | 2.48M |     0.99 | 0:02'21'' |

* kmergenie

```bash
BASE_NAME=Cdip
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/kmergenie
cd 2_illumina/kmergenie

kmergenie -l 21 -k 91 -s 10 -t 8 ../R1.fq.gz -o oriR1
kmergenie -l 21 -k 91 -s 10 -t 8 ../R2.fq.gz -o oriR2
kmergenie -l 21 -k 91 -s 10 -t 8 ../Q30L60/pe.cor.fa -o Q30L60

```

## Cdip: down sampling

```bash
BASE_NAME=Cdip
cd ${HOME}/data/anchr/${BASE_NAME}

REAL_G=2488635

for QxxLxx in $( parallel "echo 'Q{1}L{2}'" ::: 25 30 ::: 60 ); do
    echo "==> ${QxxLxx}"

    if [ ! -e 2_illumina/${QxxLxx}/pe.cor.fa ]; then
        echo "2_illumina/${QxxLxx}/pe.cor.fa not exists"
        continue;
    fi

    for X in 40 80 120 160 240; do
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

```bash
BASE_DIR=$HOME/data/anchr/Cdip
cd ${BASE_DIR}

head -n 35000 3_pacbio/pacbio.fasta > 3_pacbio/pacbio.40x.fasta
faops n50 -S -C 3_pacbio/pacbio.40x.fasta

head -n 70000 3_pacbio/pacbio.fasta > 3_pacbio/pacbio.80x.fasta
faops n50 -S -C 3_pacbio/pacbio.80x.fasta

```

## Cdip: k-unitigs and anchors (sampled)

```bash
BASE_NAME=Cdip
cd ${HOME}/data/anchr/${BASE_NAME}

# k-unitigs (sampled)
parallel --no-run-if-empty -j 3 "
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
        -p 8 \
        --kmer 31,41,51,61,71,81 \
        -o kunitigs.sh
    bash kunitigs.sh

    echo >&2
    " ::: 25 30 ::: 60 ::: 40 80 120 160 240 ::: 000 001 002 003 004 005 006

# anchors (sampled)
parallel --no-run-if-empty -j 3 "
    echo >&2 '==> Group Q{1}L{2}X{3}P{4}'

    if [ -e Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa ]; then
        exit;
    fi

    rm -fr Q{1}L{2}X{3}P{4}/anchor
    bash ~/Scripts/cpan/App-Anchr/share/anchor.sh Q{1}L{2}X{3}P{4} 8 false
    
    echo >&2
    " ::: 25 30 ::: 60 ::: 40 80 120 160 240 ::: 000 001 002 003 004 005 006

# Stats of anchors
REAL_G=2488635

bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 header \
    > stat2.md

parallel -k --no-run-if-empty -j 6 "
    if [ ! -e Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa ]; then
        exit;
    fi

    bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 Q{1}L{2}X{3}P{4} ${REAL_G}
    " ::: 25 30 ::: 60 ::: 40 80 120 160 240 ::: 000 001 002 003 004 005 006 \
    >> stat2.md

cat stat2.md
```

| Name           | SumCor  | CovCor | N50SR |   Sum |   # | N50Anchor |   Sum |   # | N50Others |    Sum |   # |                Kmer | RunTimeKU | RunTimeAN |
|:---------------|:--------|-------:|------:|------:|----:|----------:|------:|----:|----------:|-------:|----:|--------------------:|----------:|----------:|
| Q25L60X40P000  | 99.55M  |   40.0 | 34190 | 2.46M | 140 |     34190 | 2.45M | 131 |       844 |  7.28K |   9 | "31,41,51,61,71,81" | 0:02'48'' | 0:01'25'' |
| Q25L60X40P001  | 99.55M  |   40.0 | 30045 | 2.46M | 148 |     30045 | 2.45M | 132 |       844 | 13.48K |  16 | "31,41,51,61,71,81" | 0:02'49'' | 0:01'35'' |
| Q25L60X40P002  | 99.55M  |   40.0 | 27638 | 2.47M | 162 |     27680 | 2.45M | 145 |       742 | 13.08K |  17 | "31,41,51,61,71,81" | 0:02'46'' | 0:01'35'' |
| Q25L60X40P003  | 99.55M  |   40.0 | 33236 | 2.46M | 131 |     33236 | 2.45M | 117 |       684 |  9.59K |  14 | "31,41,51,61,71,81" | 0:02'53'' | 0:01'23'' |
| Q25L60X40P004  | 99.55M  |   40.0 | 49674 | 2.45M |  99 |     49674 | 2.45M |  91 |       748 |  6.37K |   8 | "31,41,51,61,71,81" | 0:02'58'' | 0:01'31'' |
| Q25L60X40P005  | 99.55M  |   40.0 | 46364 | 2.46M | 108 |     46364 | 2.45M |  97 |       727 |  7.86K |  11 | "31,41,51,61,71,81" | 0:02'55'' | 0:01'33'' |
| Q25L60X40P006  | 99.55M  |   40.0 | 47421 | 2.46M | 117 |     47421 | 2.45M | 105 |       783 |  9.12K |  12 | "31,41,51,61,71,81" | 0:02'45'' | 0:01'35'' |
| Q25L60X80P000  | 199.09M |   80.0 | 19434 | 2.46M | 238 |     19434 | 2.44M | 213 |       822 | 19.67K |  25 | "31,41,51,61,71,81" | 0:03'58'' | 0:02'06'' |
| Q25L60X80P001  | 199.09M |   80.0 | 15365 | 2.46M | 246 |     15447 | 2.45M | 227 |       727 | 13.98K |  19 | "31,41,51,61,71,81" | 0:03'53'' | 0:02'11'' |
| Q25L60X80P002  | 199.09M |   80.0 | 27534 | 2.46M | 163 |     27534 | 2.45M | 151 |       707 |  8.48K |  12 | "31,41,51,61,71,81" | 0:03'57'' | 0:01'56'' |
| Q25L60X120P000 | 298.64M |  120.0 |  9278 | 2.47M | 391 |      9498 | 2.44M | 351 |       770 | 29.14K |  40 | "31,41,51,61,71,81" | 0:05'22'' | 0:02'46'' |
| Q25L60X120P001 | 298.64M |  120.0 | 13839 | 2.46M | 290 |     13936 | 2.44M | 261 |       727 | 20.61K |  29 | "31,41,51,61,71,81" | 0:05'23'' | 0:02'34'' |
| Q25L60X160P000 | 398.18M |  160.0 |  6698 | 2.47M | 550 |      6848 | 2.42M | 479 |       727 | 50.73K |  71 | "31,41,51,61,71,81" | 0:07'01'' | 0:03'12'' |
| Q25L60X240P000 | 597.27M |  240.0 |  4746 | 2.47M | 759 |      4908 | 2.38M | 627 |       778 |  95.9K | 132 | "31,41,51,61,71,81" | 0:09'39'' | 0:03'43'' |
| Q30L60X40P000  | 99.55M  |   40.0 | 55218 | 2.46M |  91 |     55218 | 2.44M |  81 |     10398 | 17.13K |  10 | "31,41,51,61,71,81" | 0:03'05'' | 0:01'35'' |
| Q30L60X40P001  | 99.55M  |   40.0 | 55749 | 2.45M |  93 |     55749 | 2.45M |  85 |       844 |  6.42K |   8 | "31,41,51,61,71,81" | 0:02'52'' | 0:01'35'' |
| Q30L60X40P002  | 99.55M  |   40.0 | 65454 | 2.46M |  75 |     65454 | 2.44M |  62 |      1126 | 13.91K |  13 | "31,41,51,61,71,81" | 0:03'01'' | 0:01'37'' |
| Q30L60X40P003  | 99.55M  |   40.0 | 97954 | 2.45M |  68 |     97954 | 2.45M |  62 |       834 |  4.77K |   6 | "31,41,51,61,71,81" | 0:02'53'' | 0:01'25'' |
| Q30L60X40P004  | 99.55M  |   40.0 | 71924 | 2.45M |  76 |     71924 | 2.45M |  67 |       727 |  6.18K |   9 | "31,41,51,61,71,81" | 0:02'54'' | 0:01'26'' |
| Q30L60X40P005  | 99.55M  |   40.0 | 63766 | 2.45M |  88 |     63766 | 2.44M |  76 |       727 |  8.73K |  12 | "31,41,51,61,71,81" | 0:02'37'' | 0:01'26'' |
| Q30L60X80P000  | 199.09M |   80.0 | 60425 | 2.45M |  76 |     60425 | 2.45M |  70 |       753 |  4.59K |   6 | "31,41,51,61,71,81" | 0:04'00'' | 0:02'03'' |
| Q30L60X80P001  | 199.09M |   80.0 | 68973 | 2.45M |  64 |     68973 | 2.45M |  57 |       844 |  5.27K |   7 | "31,41,51,61,71,81" | 0:04'02'' | 0:02'00'' |
| Q30L60X80P002  | 199.09M |   80.0 | 89791 | 2.45M |  65 |     89791 | 2.45M |  58 |       809 |  5.53K |   7 | "31,41,51,61,71,81" | 0:04'01'' | 0:02'08'' |
| Q30L60X120P000 | 298.64M |  120.0 | 60425 | 2.45M |  74 |     60427 | 2.45M |  67 |       727 |  5.37K |   7 | "31,41,51,61,71,81" | 0:05'23'' | 0:02'27'' |
| Q30L60X120P001 | 298.64M |  120.0 | 71924 | 2.45M |  62 |     71924 | 2.44M |  56 |       844 |   4.9K |   6 | "31,41,51,61,71,81" | 0:05'18'' | 0:02'36'' |
| Q30L60X160P000 | 398.18M |  160.0 | 60427 | 2.45M |  75 |     60427 | 2.45M |  68 |       727 |  5.37K |   7 | "31,41,51,61,71,81" | 0:06'26'' | 0:03'04'' |
| Q30L60X240P000 | 597.27M |  240.0 | 57594 | 2.45M |  86 |     59198 | 2.44M |  74 |       844 |  9.05K |  12 | "31,41,51,61,71,81" | 0:06'47'' | 0:03'28'' |

## Cdip: merge anchors

```bash
BASE_NAME=Cdip
cd ${HOME}/data/anchr/${BASE_NAME}

# merge anchors
mkdir -p merge
anchr contained \
    $(
        parallel -k --no-run-if-empty -j 6 "
            if [ -e Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa ]; then
                echo Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa
            fi
            " ::: 25 30 ::: 60 ::: 40 80 120 160 240 ::: 000 001 002 003 004 005 006
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
            " ::: 25 30 ::: 60 ::: 40 80 120 160 240 ::: 000 001 002 003 004 005 006
    ) \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.contained.fasta
anchr orient merge/others.contained.fasta --len 1000 --idt 0.98 -o merge/others.orient.fasta
anchr merge merge/others.orient.fasta --len 1000 --idt 0.999 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.merge.fasta

# anchors sorted on ref
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
    merge/anchor.merge.fasta \
    merge/others.merge.fasta \
    1_genome/paralogs.fas \
    --label "merge,others,paralogs" \
    -o 9_qa

```

## Cdip: 3GS

```bash
BASE_NAME=Cdip
REAL_G=2488635
cd $HOME/data/anchr/${BASE_NAME}

canu \
    -p ${BASE_NAME} -d canu-raw-40x \
    gnuplot=$(brew --prefix)/Cellar/$(brew list --versions gnuplot | sed 's/ /\//')/bin/gnuplot \
    genomeSize=${REAL_G} \
    -pacbio-raw 3_pacbio/pacbio.40x.fasta

canu \
    -p ${BASE_NAME} -d canu-raw-80x \
    gnuplot=$(brew --prefix)/Cellar/$(brew list --versions gnuplot | sed 's/ /\//')/bin/gnuplot \
    genomeSize=${REAL_G} \
    -pacbio-raw 3_pacbio/pacbio.80x.fasta

faops n50 -S -C canu-raw-40x/${BASE_NAME}.trimmedReads.fasta.gz
faops n50 -S -C canu-raw-80x/${BASE_NAME}.trimmedReads.fasta.gz

```

## Cdip: expand anchors

* anchorLong

```bash
BASE_NAME=Cdip
cd ${HOME}/data/anchr/${BASE_NAME}

anchr cover \
    --parallel 16 \
    -c 2 -m 40 \
    -b 20 --len 1000 --idt 0.9 \
    merge/anchor.merge.fasta \
    canu-raw-40x/${BASE_NAME}.trimmedReads.fasta.gz \
    -o merge/anchor.cover.fasta

rm -fr anchorLong
anchr overlap2 \
    --parallel 16 \
    merge/anchor.cover.fasta \
    canu-raw-40x/${BASE_NAME}.trimmedReads.fasta.gz \
    -d anchorLong \
    -b 20 --len 1000 --idt 0.98

anchr overlap \
    merge/anchor.cover.fasta \
    --serial --len 10 --idt 0.9999 \
    -o stdout \
    | perl -nla -e '
        BEGIN {
            our %seen;
            our %count_of;
        }

        @F == 13 or next;
        $F[3] > 0.9999 or next;

        my $pair = join( "-", sort { $a <=> $b } ( $F[0], $F[1], ) );
        next if $seen{$pair};
        $seen{$pair} = $_;

        $count_of{ $F[0] }++;
        $count_of{ $F[1] }++;

        END {
            for my $pair ( keys %seen ) {
                my ($f_id, $g_id) = split "-", $pair;
                next if $count_of{$f_id} > 2;
                next if $count_of{$g_id} > 2;
                print $seen{$pair};
            }
        }
    ' \
    | sort -k 1n,1n -k 2n,2n \
    > anchorLong/anchor.ovlp.tsv

ANCHOR_COUNT=$(faops n50 -H -N 0 -C anchorLong/anchor.fasta)
echo ${ANCHOR_COUNT}

rm -fr anchorLong/group
anchr group \
    anchorLong/anchorLong.db \
    anchorLong/anchorLong.ovlp.tsv \
    --oa anchorLong/anchor.ovlp.tsv \
    --parallel 16 \
    --range "1-${ANCHOR_COUNT}" --len 1000 --idt 0.98 --max "-14" -c 4

pushd anchorLong
cat group/groups.txt \
    | parallel --no-run-if-empty -j 8 '
        echo {};
        anchr orient \
            --len 1000 --idt 0.98 \
            group/{}.anchor.fasta \
            group/{}.long.fasta \
            -r group/{}.restrict.tsv \
            -o group/{}.strand.fasta;

        anchr overlap --len 1000 --idt 0.98 \
            group/{}.strand.fasta \
            -o stdout \
            | anchr restrict \
                stdin group/{}.restrict.tsv \
                -o group/{}.ovlp.tsv;

        anchr overlap --len 10 --idt 0.9999 \
            group/{}.strand.fasta \
            -o stdout \
            | perl -nla -e '\''
                @F == 13 or next;
                $F[3] > 0.98 or next;
                $F[9] == 0 or next;
                $F[5] > 0 and $F[6] == $F[7] or next;
                /anchor.+anchor/ or next;
                print;
            '\'' \
            > group/{}.anchor.ovlp.tsv
            
        anchr layout \
            group/{}.ovlp.tsv \
            group/{}.relation.tsv \
            group/{}.strand.fasta \
            --oa group/{}.anchor.ovlp.tsv \
            -o group/{}.contig.fasta
    '
popd

# false strand
cat anchorLong/group/*.ovlp.tsv \
    | perl -nla -e '/anchor.+long/ or next; print $F[0] if $F[8] == 1;' \
    | sort | uniq -c

cat \
   anchorLong/group/non_grouped.fasta\
   anchorLong/group/*.contig.fasta \
   | faops filter -l 0 -a 1000 stdin anchorLong/contig.fasta

```

* contigTrim

```bash
BASE_NAME=Cdip
cd ${HOME}/data/anchr/${BASE_NAME}

rm -fr contigTrim
anchr overlap2 \
    --parallel 16 \
    anchorLong/contig.fasta \
    canu-raw-40x/${BASE_NAME}.contigs.fasta \
    -d contigTrim \
    -b 20 --len 1000 --idt 0.98 --all

CONTIG_COUNT=$(faops n50 -H -N 0 -C contigTrim/anchor.fasta)
echo ${CONTIG_COUNT}

rm -fr contigTrim/group
anchr group \
    --parallel 16 \
    --keep \
    contigTrim/anchorLong.db \
    contigTrim/anchorLong.ovlp.tsv \
    --range "1-${CONTIG_COUNT}" --len 1000 --idt 0.98 --max 20000 -c 1

pushd contigTrim
cat group/groups.txt \
    | parallel --no-run-if-empty -j 8 '
        echo {};
        anchr orient \
            --len 1000 --idt 0.98 \
            group/{}.anchor.fasta \
            group/{}.long.fasta \
            -r group/{}.restrict.tsv \
            -o group/{}.strand.fasta;

        anchr overlap --len 1000 --idt 0.98 --all \
            group/{}.strand.fasta \
            -o stdout \
            | anchr restrict \
                stdin group/{}.restrict.tsv \
                -o group/{}.ovlp.tsv;

        anchr layout \
            group/{}.ovlp.tsv \
            group/{}.relation.tsv \
            group/{}.strand.fasta \
            -o group/{}.contig.fasta
    '
popd

cat \
    contigTrim/group/non_grouped.fasta \
    contigTrim/group/*.contig.fasta \
    >  contigTrim/contig.fasta

```

* quast

```bash
BASE_NAME=Cdip
cd ${HOME}/data/anchr/${BASE_NAME}

rm -fr 9_qa_contig
quast --no-check --threads 16 \
    -R 1_genome/genome.fa \
    merge/anchor.merge.fasta \
    merge/anchor.cover.fasta \
    anchorLong/contig.fasta \
    contigTrim/contig.fasta \
    canu-raw-40x/${BASE_NAME}.contigs.fasta \
    canu-raw-80x/${BASE_NAME}.contigs.fasta \
    1_genome/paralogs.fas \
    --label "merge,cover,contig,contigTrim,canu-40x,canu-80x,paralogs" \
    -o 9_qa_contig

```

* Stats

```bash
BASE_NAME=Cdip
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
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchor.cover"; faops n50 -H -S -C merge/anchor.cover.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchorLong"; faops n50 -H -S -C anchorLong/contig.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "contigTrim"; faops n50 -H -S -C contigTrim/contig.fasta;) >> stat3.md

cat stat3.md
```

| Name         |     N50 |     Sum |  # |
|:-------------|--------:|--------:|---:|
| Genome       | 2488635 | 2488635 |  1 |
| Paralogs     |    5635 |   56210 | 18 |
| anchor.merge |  115948 | 2447558 | 46 |
| others.merge |    2541 |   23728 | 10 |
| anchor.cover |  108033 | 2442070 | 45 |
| anchorLong   |  125030 | 2441001 | 30 |
| contigTrim   | 2488479 | 2488479 |  1 |

* Clear QxxLxxXxx.

```bash
BASE_NAME=Cdip
cd ${HOME}/data/anchr/${BASE_NAME}

rm -fr 2_illumina/Q{20,25,30}L{1,60,90,120}X*
rm -fr Q{20,25,30}L{1,60,90,120}X*
```

# Francisella tularensis FDAARGOS_247, 土拉热弗朗西斯氏菌

* Project
[SRP040661](https://trace.ncbi.nlm.nih.gov/Traces/sra/?study=SRP040661)

* Other name: SHU-S4

* BioSample: [SAMN04875573](https://www.ncbi.nlm.nih.gov/biosample/SAMN04875573)

## Ftul: download

* Reference genome

    * Strain: Francisella tularensis subsp. tularensis SCHU S4 (g-proteobacteria)
    * Taxid: [177416](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=177416)
    * RefSeq assembly accession:
      [GCF_000008985.1](ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/008/985/GCF_000008985.1_ASM898v1/GCF_000008985.1_ASM898v1_assembly_report.txt)
    * Proportion of paralogs (> 1000 bp): 0.0438

```bash
mkdir -p ~/data/anchr/Ftul/1_genome
cd ~/data/anchr/Ftul/1_genome

aria2c -x 9 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/008/985/GCF_000008985.1_ASM898v1/GCF_000008985.1_ASM898v1_genomic.fna.gz

TAB=$'\t'
cat <<EOF > replace.tsv
NC_006570.2${TAB}1
EOF

faops replace GCF_000008985.1_ASM898v1_genomic.fna.gz replace.tsv genome.fa

cp ~/data/anchr/paralogs/otherbac/Results/Ftul/Ftul.multi.fas paralogs.fas

```

* Illumina

    * [SRX2105481](https://www.ncbi.nlm.nih.gov/sra/SRX2179108) SRR4124773

```bash
mkdir -p ~/data/anchr/Ftul/2_illumina
cd ~/data/anchr/Ftul/2_illumina

cat << EOF > sra_ftp.txt
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR412/003/SRR4124773/SRR4124773_1.fastq.gz
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR412/003/SRR4124773/SRR4124773_2.fastq.gz
EOF

aria2c -x 9 -s 3 -c -i sra_ftp.txt

cat << EOF > sra_md5.txt
f24d93fab957c01c8501d7b60c1f0e99 SRR4124773_1.fastq.gz
6cdca7f1fb3bbbb811a3c8b9c63dcd3b SRR4124773_2.fastq.gz
EOF

md5sum --check sra_md5.txt

ln -s SRR4124773_1.fastq.gz R1.fq.gz
ln -s SRR4124773_2.fastq.gz R2.fq.gz

```

* PacBio

```bash
mkdir -p ~/data/anchr/Ftul/3_pacbio
cd ~/data/anchr/Ftul/3_pacbio

# download from sra
cat <<EOF > hdf5.txt
http://sra-download.ncbi.nlm.nih.gov/srapub_files/SRR4124774_SRR4124774_hdf5.tgz
EOF
aria2c -x 9 -s 3 -c -i hdf5.txt

# untar
mkdir -p ~/data/anchr/Ftul/3_pacbio/untar
cd ~/data/anchr/Ftul/3_pacbio
tar xvfz SRR4124774_SRR4124774_hdf5.tgz --directory untar

# convert .bax.h5 to .subreads.bam
mkdir -p ~/data/anchr/Ftul/3_pacbio/bam
cd ~/data/anchr/Ftul/3_pacbio/bam

source ~/share/pitchfork/deployment/setup-env.sh
for movie in m150419;
do 
    bax2bam ~/data/anchr/Ftul/3_pacbio/untar/${movie}*.bax.h5
done

# convert .subreads.bam to fasta
mkdir -p ~/data/anchr/Ftul/3_pacbio/fasta

for movie in m150419;
do
    if [ ! -e ~/data/anchr/Ftul/3_pacbio/bam/${movie}*.subreads.bam ]; then
        continue
    fi

    samtools fasta \
        ~/data/anchr/Ftul/3_pacbio/bam/${movie}*.subreads.bam \
        > ~/data/anchr/Ftul/3_pacbio/fasta/${movie}.fasta
done

cd ~/data/anchr/Ftul
cat 3_pacbio/fasta/*.fasta > 3_pacbio/pacbio.fasta

rm -fr ~/data/anchr/Ftul/3_pacbio/untar
```

* FastQC

```bash
BASE_NAME=Ftul
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/fastqc
cd 2_illumina/fastqc

fastqc -t 16 \
    ../R1.fq.gz ../R2.fq.gz \
    -o .

```

## Ftul: combinations of different quality values and read lengths

* qual: 20, 25, and 30
* len: 60

```bash
BASE_NAME=Ftul
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
REAL_G=1892775
READ_COUNT=$(( 200 / 2 * ${REAL_G} / 101 ))
parallel --no-run-if-empty -j 2 "
    seqtk sample \
        -s${READ_COUNT} \
        2_illumina/{}.uniq.fq.gz \
        ${READ_COUNT} \
        | pigz -p 4 -c \
        > 2_illumina/{}.200x.fq.gz
    " ::: R1 R2

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
        ../R1.200x.fq.gz ../R2.200x.fq.gz \
        -o stdout \
        | bash
    " ::: 20 25 30 ::: 60

```

* Stats

```bash
BASE_NAME=Ftul
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
    $(echo "PacBio";   faops n50 -H -S -C 3_pacbio/pacbio.fasta;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "Illumina"; faops n50 -H -S -C 2_illumina/R1.fq.gz 2_illumina/R2.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "uniq";     faops n50 -H -S -C 2_illumina/R1.uniq.fq.gz 2_illumina/R2.uniq.fq.gz;) >> stat.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "200x";     faops n50 -H -S -C 2_illumina/R1.200x.fq.gz 2_illumina/R2.200x.fq.gz;) >> stat.md

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
| Genome   | 1892775 |    1892775 |        1 |
| Paralogs |   33912 |      93531 |       10 |
| PacBio   |   10022 | 1161069478 |   151564 |
| Illumina |     101 | 2144257270 | 21230270 |
| uniq     |     101 | 2122919000 | 21019000 |
| 200x     |     101 |  378554868 |  3748068 |
| Q20L60   |     101 |  367096899 |  3645544 |
| Q25L60   |     101 |  358221620 |  3563774 |
| Q30L60   |     101 |  348913664 |  3507509 |

## Ftul: quorum

```bash
BASE_NAME=Ftul
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

```

Clear intermediate files.

```bash
BASE_NAME=Ftul
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
BASE_NAME=Ftul
cd ${HOME}/data/anchr/${BASE_NAME}

REAL_G=1892775

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

| Name   | SumIn |  CovIn | SumOut | CovOut | Discard% | AvgRead | Kmer | RealG |  EstG | Est/Real |   RunTime |
|:-------|------:|-------:|-------:|-------:|---------:|--------:|-----:|------:|------:|---------:|----------:|
| Q20L60 | 2.06G | 1087.9 |  1.96G | 1033.3 |   5.015% |     100 | "71" | 1.89M | 1.92M |     1.01 | 0:05'31'' |
| Q25L60 | 2.01G | 1061.5 |  1.92G | 1016.4 |   4.253% |     100 | "71" | 1.89M | 1.89M |     1.00 | 0:05'29'' |
| Q30L60 | 1.96G | 1034.1 |  1.89G |  998.3 |   3.465% |      99 | "71" | 1.89M | 1.86M |     0.98 | 0:05'29'' |

| Name   |   SumIn | CovIn |  SumOut | CovOut | Discard% | AvgRead | Kmer | RealG | EstG | Est/Real |   RunTime |
|:-------|--------:|------:|--------:|-------:|---------:|--------:|-----:|------:|-----:|---------:|----------:|
| Q20L60 |  367.1M | 193.9 | 348.22M |  184.0 |   5.143% |     100 | "71" | 1.89M | 1.8M |     0.95 | 0:01'15'' |
| Q25L60 | 358.22M | 189.3 | 342.63M |  181.0 |   4.353% |     100 | "71" | 1.89M | 1.8M |     0.95 | 0:01'10'' |
| Q30L60 | 349.03M | 184.4 | 336.65M |  177.9 |   3.546% |      99 | "71" | 1.89M | 1.8M |     0.95 | 0:01'10'' |

* kmergenie

```bash
BASE_NAME=Ftul
cd ${HOME}/data/anchr/${BASE_NAME}

mkdir -p 2_illumina/kmergenie
cd 2_illumina/kmergenie

kmergenie -l 21 -k 91 -s 10 -t 8 ../R1.fq.gz -o oriR1
kmergenie -l 21 -k 91 -s 10 -t 8 ../R2.fq.gz -o oriR2
kmergenie -l 21 -k 91 -s 10 -t 8 ../Q30L60/pe.cor.fa -o Q30L60

```

## Ftul: down sampling

```bash
BASE_NAME=Ftul
cd ${HOME}/data/anchr/${BASE_NAME}

REAL_G=1892775

for QxxLxx in $( parallel "echo 'Q{1}L{2}'" ::: 25 30 ::: 60 ); do
    echo "==> ${QxxLxx}"

    if [ ! -e 2_illumina/${QxxLxx}/pe.cor.fa ]; then
        echo "2_illumina/${QxxLxx}/pe.cor.fa not exists"
        continue;
    fi

    for X in 40 80 120 160; do
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

```bash
BASE_DIR=$HOME/data/anchr/Ftul
cd ${BASE_DIR}

head -n 20000 3_pacbio/pacbio.fasta > 3_pacbio/pacbio.40x.fasta
faops n50 -S -C 3_pacbio/pacbio.40x.fasta

head -n 40000 3_pacbio/pacbio.fasta > 3_pacbio/pacbio.80x.fasta
faops n50 -S -C 3_pacbio/pacbio.80x.fasta

```

## Ftul: k-unitigs and anchors (sampled)

```bash
BASE_NAME=Ftul
cd ${HOME}/data/anchr/${BASE_NAME}

# k-unitigs (sampled)
parallel --no-run-if-empty -j 3 "
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
        -p 8 \
        --kmer 31,41,51,61,71,81 \
        -o kunitigs.sh
    bash kunitigs.sh

    echo >&2
    " ::: 25 30 ::: 60 ::: 40 80 120 160 ::: 000 001 002 003 004 005 006

# anchors (sampled)
parallel --no-run-if-empty -j 3 "
    echo >&2 '==> Group Q{1}L{2}X{3}P{4}'

    if [ -e Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa ]; then
        exit;
    fi

    rm -fr Q{1}L{2}X{3}P{4}/anchor
    bash ~/Scripts/cpan/App-Anchr/share/anchor.sh Q{1}L{2}X{3}P{4} 8 false
    
    echo >&2
    " ::: 25 30 ::: 60 ::: 40 80 120 160 ::: 000 001 002 003 004 005 006

# Stats of anchors
REAL_G=1892775

bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 header \
    > stat2.md

parallel -k --no-run-if-empty -j 6 "
    if [ ! -e Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa ]; then
        exit;
    fi

    bash ~/Scripts/cpan/App-Anchr/share/sr_stat.sh 2 Q{1}L{2}X{3}P{4} ${REAL_G}
    " ::: 25 30 ::: 60 ::: 40 80 120 160 ::: 000 001 002 003 004 005 006 \
    >> stat2.md

cat stat2.md
```

| Name           |  SumCor | CovCor | N50SR |   Sum |  # | N50Anchor |   Sum |  # | N50Others |    Sum | # |                Kmer | RunTimeKU | RunTimeAN |
|:---------------|--------:|-------:|------:|------:|---:|----------:|------:|---:|----------:|-------:|--:|--------------------:|----------:|:----------|
| Q25L60X40P000  |  75.71M |   40.0 | 35248 |  1.8M | 72 |     35248 |  1.8M | 71 |       865 |    865 | 1 | "31,41,51,61,71,81" | 0:01'13'' | 0:00'52'' |
| Q25L60X40P001  |  75.71M |   40.0 | 32751 |  1.8M | 75 |     32751 | 1.79M | 72 |      4293 |  9.43K | 3 | "31,41,51,61,71,81" | 0:01'15'' | 0:00'52'' |
| Q25L60X40P002  |  75.71M |   40.0 | 32751 |  1.8M | 76 |     32751 | 1.79M | 73 |      4293 |  9.45K | 3 | "31,41,51,61,71,81" | 0:01'13'' | 0:00'54'' |
| Q25L60X40P003  |  75.71M |   40.0 | 32751 | 1.82M | 75 |     32803 | 1.77M | 72 |     23232 | 47.32K | 3 | "31,41,51,61,71,81" | 0:01'14'' | 0:00'47'' |
| Q25L60X80P000  | 151.42M |   80.0 | 32751 |  1.8M | 78 |     32751 |  1.8M | 74 |       645 |  2.58K | 4 | "31,41,51,61,71,81" | 0:01'48'' | 0:01'09'' |
| Q25L60X80P001  | 151.42M |   80.0 | 31667 |  1.8M | 79 |     31667 |  1.8M | 77 |       865 |  1.44K | 2 | "31,41,51,61,71,81" | 0:01'49'' | 0:01'12'' |
| Q25L60X120P000 | 227.13M |  120.0 | 32404 |  1.8M | 83 |     32404 |  1.8M | 78 |       650 |  3.55K | 5 | "31,41,51,61,71,81" | 0:02'27'' | 0:01'21'' |
| Q25L60X160P000 | 302.84M |  160.0 | 31667 |  1.8M | 84 |     31667 |  1.8M | 83 |       865 |    865 | 1 | "31,41,51,61,71,81" | 0:03'05'' | 0:01'42'' |
| Q30L60X40P000  |  75.71M |   40.0 | 35248 |  1.8M | 72 |     35248 |  1.8M | 71 |       855 |    855 | 1 | "31,41,51,61,71,81" | 0:01'14'' | 0:00'56'' |
| Q30L60X40P001  |  75.71M |   40.0 | 32751 | 1.84M | 76 |     32813 | 1.76M | 71 |     32374 | 74.19K | 5 | "31,41,51,61,71,81" | 0:01'13'' | 0:00'45'' |
| Q30L60X40P002  |  75.71M |   40.0 | 32751 |  1.8M | 73 |     32751 |  1.8M | 72 |       855 |    855 | 1 | "31,41,51,61,71,81" | 0:01'13'' | 0:00'44'' |
| Q30L60X40P003  |  75.71M |   40.0 | 32741 |  1.8M | 75 |     32741 |  1.8M | 74 |       865 |    865 | 1 | "31,41,51,61,71,81" | 0:01'13'' | 0:00'45'' |
| Q30L60X80P000  | 151.42M |   80.0 | 32751 |  1.8M | 74 |     32751 |  1.8M | 73 |       865 |    865 | 1 | "31,41,51,61,71,81" | 0:01'49'' | 0:01'08'' |
| Q30L60X80P001  | 151.42M |   80.0 | 32751 |  1.8M | 74 |     32751 |  1.8M | 73 |       865 |    865 | 1 | "31,41,51,61,71,81" | 0:01'50'' | 0:01'12'' |
| Q30L60X120P000 | 227.13M |  120.0 | 32751 |  1.8M | 77 |     32751 |  1.8M | 75 |       865 |  1.49K | 2 | "31,41,51,61,71,81" | 0:02'26'' | 0:01'32'' |
| Q30L60X160P000 | 302.84M |  160.0 | 32404 |  1.8M | 79 |     32404 |  1.8M | 77 |       865 |  1.49K | 2 | "31,41,51,61,71,81" | 0:03'00'' | 0:01'37'' |

## Ftul: merge anchors

```bash
BASE_NAME=Ftul
cd ${HOME}/data/anchr/${BASE_NAME}

# merge anchors
mkdir -p merge
anchr contained \
    $(
        parallel -k --no-run-if-empty -j 6 "
            if [ -e Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa ]; then
                echo Q{1}L{2}X{3}P{4}/anchor/pe.anchor.fa
            fi
            " ::: 25 30 ::: 60 ::: 40 80 120 160 ::: 000 001 002 003 004 005 006
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
            " ::: 25 30 ::: 60 ::: 40 80 120 160 ::: 000 001 002 003 004 005 006
    ) \
    --len 1000 --idt 0.98 --proportion 0.99999 --parallel 16 \
    -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.contained.fasta
anchr orient merge/others.contained.fasta --len 1000 --idt 0.98 -o merge/others.orient.fasta
anchr merge merge/others.orient.fasta --len 1000 --idt 0.999 -o stdout \
    | faops filter -a 1000 -l 0 stdin merge/others.merge.fasta

# anchors sorted on ref
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
    merge/anchor.merge.fasta \
    merge/others.merge.fasta \
    1_genome/paralogs.fas \
    --label "merge,others,paralogs" \
    -o 9_qa

```

## Ftul: 3GS

```bash
BASE_NAME=Ftul
GENOME_SIZE=1.9m
cd $HOME/data/anchr/${BASE_NAME}

canu \
    -p ${BASE_NAME} -d canu-raw-40x \
    gnuplot=$(brew --prefix)/Cellar/$(brew list --versions gnuplot | sed 's/ /\//')/bin/gnuplot \
    genomeSize=${GENOME_SIZE} \
    -pacbio-raw 3_pacbio/pacbio.40x.fasta

canu \
    -p ${BASE_NAME} -d canu-raw-80x \
    gnuplot=$(brew --prefix)/Cellar/$(brew list --versions gnuplot | sed 's/ /\//')/bin/gnuplot \
    genomeSize=${GENOME_SIZE} \
    -pacbio-raw 3_pacbio/pacbio.80x.fasta

faops n50 -S -C canu-raw-40x/${BASE_NAME}.trimmedReads.fasta.gz
faops n50 -S -C canu-raw-80x/${BASE_NAME}.trimmedReads.fasta.gz

```

## Ftul: expand anchors

* anchorLong

```bash
BASE_NAME=Ftul
cd ${HOME}/data/anchr/${BASE_NAME}

anchr cover \
    --parallel 16 \
    -c 2 -m 40 \
    -b 20 --len 1000 --idt 0.9 \
    merge/anchor.merge.fasta \
    canu-raw-40x/${BASE_NAME}.trimmedReads.fasta.gz \
    -o merge/anchor.cover.fasta

rm -fr anchorLong
anchr overlap2 \
    --parallel 16 \
    merge/anchor.cover.fasta \
    canu-raw-40x/${BASE_NAME}.trimmedReads.fasta.gz \
    -d anchorLong \
    -b 20 --len 1000 --idt 0.98

anchr overlap \
    merge/anchor.cover.fasta \
    --serial --len 10 --idt 0.9999 \
    -o stdout \
    | perl -nla -e '
        BEGIN {
            our %seen;
            our %count_of;
        }

        @F == 13 or next;
        $F[3] > 0.9999 or next;

        my $pair = join( "-", sort { $a <=> $b } ( $F[0], $F[1], ) );
        next if $seen{$pair};
        $seen{$pair} = $_;

        $count_of{ $F[0] }++;
        $count_of{ $F[1] }++;

        END {
            for my $pair ( keys %seen ) {
                my ($f_id, $g_id) = split "-", $pair;
                next if $count_of{$f_id} > 2;
                next if $count_of{$g_id} > 2;
                print $seen{$pair};
            }
        }
    ' \
    | sort -k 1n,1n -k 2n,2n \
    > anchorLong/anchor.ovlp.tsv

ANCHOR_COUNT=$(faops n50 -H -N 0 -C anchorLong/anchor.fasta)
echo ${ANCHOR_COUNT}

rm -fr anchorLong/group
anchr group \
    anchorLong/anchorLong.db \
    anchorLong/anchorLong.ovlp.tsv \
    --oa anchorLong/anchor.ovlp.tsv \
    --parallel 16 \
    --range "1-${ANCHOR_COUNT}" --len 1000 --idt 0.98 --max "-14" -c 4

pushd anchorLong
cat group/groups.txt \
    | parallel --no-run-if-empty -j 8 '
        echo {};
        anchr orient \
            --len 1000 --idt 0.98 \
            group/{}.anchor.fasta \
            group/{}.long.fasta \
            -r group/{}.restrict.tsv \
            -o group/{}.strand.fasta;

        anchr overlap --len 1000 --idt 0.98 \
            group/{}.strand.fasta \
            -o stdout \
            | anchr restrict \
                stdin group/{}.restrict.tsv \
                -o group/{}.ovlp.tsv;

        anchr overlap --len 10 --idt 0.9999 \
            group/{}.strand.fasta \
            -o stdout \
            | perl -nla -e '\''
                @F == 13 or next;
                $F[3] > 0.98 or next;
                $F[9] == 0 or next;
                $F[5] > 0 and $F[6] == $F[7] or next;
                /anchor.+anchor/ or next;
                print;
            '\'' \
            > group/{}.anchor.ovlp.tsv
            
        anchr layout \
            group/{}.ovlp.tsv \
            group/{}.relation.tsv \
            group/{}.strand.fasta \
            --oa group/{}.anchor.ovlp.tsv \
            -o group/{}.contig.fasta
    '
popd

# false strand
cat anchorLong/group/*.ovlp.tsv \
    | perl -nla -e '/anchor.+long/ or next; print $F[0] if $F[8] == 1;' \
    | sort | uniq -c

cat \
   anchorLong/group/non_grouped.fasta\
   anchorLong/group/*.contig.fasta \
   | faops filter -l 0 -a 1000 stdin anchorLong/contig.fasta

```

* contigTrim

```bash
BASE_NAME=Ftul
cd ${HOME}/data/anchr/${BASE_NAME}

rm -fr contigTrim
anchr overlap2 \
    --parallel 16 \
    anchorLong/contig.fasta \
    canu-raw-40x/${BASE_NAME}.contigs.fasta \
    -d contigTrim \
    -b 20 --len 1000 --idt 0.98 --all

CONTIG_COUNT=$(faops n50 -H -N 0 -C contigTrim/anchor.fasta)
echo ${CONTIG_COUNT}

rm -fr contigTrim/group
anchr group \
    --parallel 16 \
    --keep \
    contigTrim/anchorLong.db \
    contigTrim/anchorLong.ovlp.tsv \
    --range "1-${CONTIG_COUNT}" --len 1000 --idt 0.98 --max 20000 -c 1

pushd contigTrim
cat group/groups.txt \
    | parallel --no-run-if-empty -j 8 '
        echo {};
        anchr orient \
            --len 1000 --idt 0.98 \
            group/{}.anchor.fasta \
            group/{}.long.fasta \
            -r group/{}.restrict.tsv \
            -o group/{}.strand.fasta;

        anchr overlap --len 1000 --idt 0.98 --all \
            group/{}.strand.fasta \
            -o stdout \
            | anchr restrict \
                stdin group/{}.restrict.tsv \
                -o group/{}.ovlp.tsv;

        anchr layout \
            group/{}.ovlp.tsv \
            group/{}.relation.tsv \
            group/{}.strand.fasta \
            -o group/{}.contig.fasta
    '
popd

cat \
    contigTrim/group/non_grouped.fasta \
    contigTrim/group/*.contig.fasta \
    >  contigTrim/contig.fasta

```

* quast

```bash
BASE_NAME=Ftul
cd ${HOME}/data/anchr/${BASE_NAME}

rm -fr 9_qa_contig
quast --no-check --threads 16 \
    -R 1_genome/genome.fa \
    merge/anchor.merge.fasta \
    merge/anchor.cover.fasta \
    anchorLong/contig.fasta \
    contigTrim/contig.fasta \
    canu-raw-40x/Ftul.contigs.fasta \
    canu-raw-80x/Ftul.contigs.fasta \
    1_genome/paralogs.fas \
    --label "merge,cover,contig,contigTrim,canu-40x,canu-80x,paralogs" \
    -o 9_qa_contig

```

* Stats

```bash
BASE_NAME=Ftul
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
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchor.cover"; faops n50 -H -S -C merge/anchor.cover.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "anchorLong"; faops n50 -H -S -C anchorLong/contig.fasta;) >> stat3.md
printf "| %s | %s | %s | %s |\n" \
    $(echo "contigTrim"; faops n50 -H -S -C contigTrim/contig.fasta;) >> stat3.md

cat stat3.md
```

| Name         |     N50 |     Sum |  # |
|:-------------|--------:|--------:|---:|
| Genome       | 1892775 | 1892775 |  1 |
| Paralogs     |   33912 |   93531 | 10 |
| anchor.merge |   32813 | 1801122 | 73 |
| others.merge |   32404 |   64274 |  3 |
| anchor.cover |   32813 | 1796007 | 71 |
| anchorLong   |   35248 | 1795927 | 70 |
| contigTrim   | 1027458 | 1856949 |  4 |

* Clear QxxLxxXxx.

```bash
BASE_NAME=Ftul
cd ${HOME}/data/anchr/${BASE_NAME}

rm -fr 2_illumina/Q{20,25,30}L{1,60,90,120}X*
rm -fr Q{20,25,30}L{1,60,90,120}X*
```

# Haemophilus influenzae FDAARGOS_199, 流感嗜血杆菌

* Project
[SRP040661](https://trace.ncbi.nlm.nih.gov/Traces/sra/?study=SRP040661)

* Other name: ATCC 51907D; Rd KW20

* BioSample: [SAMN04875536](https://www.ncbi.nlm.nih.gov/biosample/SAMN04875536)

## Hinf: download

* Reference genome

    * Strain: Haemophilus influenzae Rd KW20 (g-proteobacteria)
    * Taxid: [71421](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=71421)
    * RefSeq assembly accession:
      [GCF_000027305.1](ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/027/305/GCF_000027305.1_ASM2730v1/GCF_000027305.1_ASM2730v1_assembly_report.txt)
    * Proportion of paralogs (> 1000 bp): 0.0324

```bash
mkdir -p ~/data/anchr/Hinf/1_genome
cd ~/data/anchr/Hinf/1_genome

aria2c -x 9 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/027/305/GCF_000027305.1_ASM2730v1/GCF_000027305.1_ASM2730v1_genomic.fna.gz

TAB=$'\t'
cat <<EOF > replace.tsv
NC_000907.1${TAB}1
EOF

faops replace GCF_000027305.1_ASM2730v1_genomic.fna.gz replace.tsv genome.fa

cp ~/data/anchr/paralogs/otherbac/Results/Hinf/Hinf.multi.fas paralogs.fas

```

* Illumina

    * [SRX2104758](https://www.ncbi.nlm.nih.gov/sra/SRX2104758) SRR4123928

```bash
mkdir -p ~/data/anchr/Hinf/2_illumina
cd ~/data/anchr/Hinf/2_illumina

cat << EOF > sra_ftp.txt
EOF

aria2c -x 9 -s 3 -c -i sra_ftp.txt

cat << EOF > sra_md5.txt
EOF

md5sum --check sra_md5.txt

ln -s SRR4124773_1.fastq.gz R1.fq.gz
ln -s SRR4124773_2.fastq.gz R2.fq.gz

```

# Listeria monocytogenes FDAARGOS_351, 单核细胞增生李斯特氏菌

Project
[SRP040661](https://trace.ncbi.nlm.nih.gov/Traces/sra/?study=SRP040661)

## Lmon: download

* Reference genome

    * Strain: Listeria monocytogenes EGD-e
    * Taxid: [169963](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=169963)
    * RefSeq assembly accession:
      [GCF_000196035.1](ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/196/035/GCF_000196035.1_ASM19603v1/GCF_000196035.1_ASM19603v1_assembly_report.txt)
    * Proportion of paralogs (> 1000 bp): 0.0133

```bash
mkdir -p ~/data/anchr/Lmon/1_genome
cd ~/data/anchr/Lmon/1_genome

aria2c -x 9 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/196/035/GCF_000196035.1_ASM19603v1/GCF_000196035.1_ASM19603v1_genomic.fna.gz

TAB=$'\t'
cat <<EOF > replace.tsv
NC_003210.1${TAB}1
EOF

faops replace GCF_000196035.1_ASM19603v1_genomic.fna.gz replace.tsv genome.fa

cp ~/data/anchr/paralogs/otherbac/Results/Lmon/Lmon.multi.fas paralogs.fas

```

* Illumina

    * [SRX2717967](https://www.ncbi.nlm.nih.gov/sra/SRX2717967)

```bash
mkdir -p ~/data/anchr/Vpar/2_illumina
cd ~/data/anchr/Vpar/2_illumina

cat << EOF > sra_ftp.txt
EOF

aria2c -x 9 -s 3 -c -i sra_ftp.txt

cat << EOF > sra_md5.txt
EOF

md5sum --check sra_md5.txt

ln -s SRR4244665_1.fastq.gz R1.fq.gz
ln -s SRR4244665_2.fastq.gz R2.fq.gz

```

# Clostridioides difficile 630

Project
[SRP040661](https://trace.ncbi.nlm.nih.gov/Traces/sra/?study=SRP040661)

## Cdif: download

* Reference genome

    * Strain: Clostridioides difficile 630
    * Taxid: [272563](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=272563)
    * RefSeq assembly accession:
      [GCF_000009205.1](ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/009/205/GCF_000009205.1_ASM920v1/GCF_000009205.1_ASM920v1_assembly_report.txt)
    * Proportion of paralogs (> 1000 bp): 0.0661

```bash
mkdir -p ~/data/anchr/Cdif/1_genome
cd ~/data/anchr/Cdif/1_genome

aria2c -x 9 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/009/205/GCF_000009205.1_ASM920v1/GCF_000009205.1_ASM920v1_genomic.fna.gz

TAB=$'\t'
cat <<EOF > replace.tsv
NC_009089.1${TAB}1
NC_008226.1${TAB}pCD630
EOF

faops replace GCF_000009205.1_ASM920v1_genomic.fna.gz replace.tsv genome.fa

cp ~/data/anchr/paralogs/otherbac/Results/Cdif/Cdif.multi.fas paralogs.fas

```

SRX2107163

# Campylobacter jejuni subsp. jejuni ATCC 700819, 空肠弯曲杆菌

Project
[SRP040661](https://trace.ncbi.nlm.nih.gov/Traces/sra/?study=SRP040661)

## Cjej: download

* Reference genome

    * Strain: Campylobacter jejuni subsp. jejuni NCTC 11168 = ATCC 700819
    * Taxid: [192222](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id=192222&lvl=3&lin=f&keep=1&srchmode=1&unlock)
    * RefSeq assembly accession:
      [GCF_000009085.1](ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/009/085/GCF_000009085.1_ASM908v1/GCF_000009085.1_ASM908v1_assembly_report.txt)
    * Proportion of paralogs (> 1000 bp): 0.0196

```bash
mkdir -p ~/data/anchr/Cjej/1_genome
cd ~/data/anchr/Cjej/1_genome

aria2c -x 9 -s 3 -c ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/009/085/GCF_000009085.1_ASM908v1/GCF_000009085.1_ASM908v1_genomic.fna.gz

TAB=$'\t'
cat <<EOF > replace.tsv
NC_002163.1${TAB}1
EOF

faops replace GCF_000009085.1_ASM908v1_genomic.fna.gz replace.tsv genome.fa

cp ~/data/anchr/paralogs/otherbac/Results/Cjej/Cjej.multi.fas paralogs.fas

```

SRX2107012
