# Prebuilt karyotype bands for Circos

[TOC levels=1-3]: # " "
- [Prebuilt karyotype bands for Circos](#prebuilt-karyotype-bands-for-circos)
- [Coming with Circos](#coming-with-circos)
- [Arabidopsis](#arabidopsis)


# Coming with Circos

Circos tarball contains some karyotype files, in `circos/data/karyotype/`.

```bash
# BSD readlink doesn't support -f
PATH_CIRCOS=$(dirname $(readlink $(which circos)))

ll ${PATH_CIRCOS}/../data/karyotype

```

# Arabidopsis

Taxonomy ID: 3702

A. tha centromere positions from
[this file](ftp://ftp.arabidopsis.org/home/tair/Sequences/whole_chromosomes/tair9_Assembly_gaps.gff)

```text
chr1 14511722	14803970
chr2 3611839	3633423
chr3 13589757	13867121
chr4 3133664	3133674
chr5 11194538	11723210
```

Hosouchi, T., Kumekawa, N., Tsuruoka, H. & Kotani, H. Physical Map-Based Sizes of the Centromeric
Regions of Arabidopsis thaliana Chromosomes 1, 2, and 3. DNA Res 9, 117-121 (2002).

```bash
pushd ~/Scripts/cpan/App-Egaz/share/karyotype/

TAB=$'\t'
cat <<EOF > Atha.karyo.tsv
#chrom${TAB}chromStart${TAB}chromEnd${TAB}name${TAB}gieStain
1${TAB}1${TAB}14200000${TAB}p1${TAB}gpos50${TAB}#14.2M
1${TAB}14200000${TAB}15627671${TAB}p1${TAB}acen
1${TAB}15627671${TAB}30427671${TAB}q1${TAB}gpos50${TAB}#14.8M
2${TAB}1${TAB}3000000${TAB}p2${TAB}gpos50${TAB}#3.0M
2${TAB}3000000${TAB}3898289${TAB}p2${TAB}acen
2${TAB}3898289${TAB}19698289${TAB}q2${TAB}gpos50${TAB}#15.8M
3${TAB}1${TAB}13200000${TAB}p3${TAB}gpos50${TAB}#13.2M
3${TAB}13200000${TAB}14459830${TAB}p3${TAB}acen
3${TAB}14459830${TAB}23459830${TAB}q3${TAB}gpos50${TAB}#9M
4${TAB}1${TAB}3000000${TAB}p4${TAB}gpos50${TAB}#3M
4${TAB}3000000${TAB}5085056${TAB}p4${TAB}acen
4${TAB}5085056${TAB}18585056${TAB}q4${TAB}gpos50${TAB}#13.5M
5${TAB}1${TAB}11100000${TAB}p5${TAB}gpos50${TAB}#1.1M
5${TAB}11100000${TAB}12575502${TAB}p5${TAB}acen
5${TAB}12575502${TAB}26975502${TAB}q5${TAB}gpos50${TAB}#14.4M
EOF

# On linux
bash $(dirname $(readlink $(which circos)))/../data/karyotype/parse.karyotype \
    Atha.karyo.tsv \
    > karyotype.3702.txt

popd

```

# Rice

```bash

perl ~/Scripts/withncbi/ensembl/chr_kary.pl -e oryza_sativa_core_29_82_7
bash ~/share/circos/data/karyotype/parse.karyotype oryza_sativa_core_29_82_7.kary.tsv > Processing/OsatJap/karyotype.OsatJap.txt

# ensembldb.ensembl.org         5306
# mysql-eg-publicsql.ebi.ac.uk  4157
mysql -hmysql-eg-publicsql.ebi.ac.uk -P4157 -uanonymous
perl ~/Scripts/withncbi/ensembl/chr_kary.pl -s mysql-eg-publicsql.ebi.ac.uk --port 4157 -u anonymous -p '' -e oryza_sativa_core_29_82_7

```
