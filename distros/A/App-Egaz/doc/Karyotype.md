# Prebuilt karyotype bands for Circos

[TOC levels=1-3]: # ""

- [Prebuilt karyotype bands for Circos](#prebuilt-karyotype-bands-for-circos)
    * [Coming with Circos](#coming-with-circos)
    * [Ensembl public databases](#ensembl-public-databases)
    * [Arabidopsis thaliana](#arabidopsis-thaliana)
    * [Rice](#rice)

## Coming with Circos

Circos tarball contains some karyotype files, in `circos/data/karyotype/`.

```bash
# BSD readlink doesn't support -f
PATH_CIRCOS=$(dirname $(perl -MCwd -e 'print Cwd::abs_path(shift)' $(which circos)))

ls -l ${PATH_CIRCOS}/../data/karyotype

```

## Ensembl public databases

* ensembldb.ensembl.org 5306
* mysql-eg-publicsql.ebi.ac.uk 4157

* `chr_kary.pl` can access local or remote Ensembl databases
    * Needs the [Ensembl Perl API](https://github.com/Ensembl/ensembl)

## Arabidopsis thaliana

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
pushd share/karyotype/

cat <<EOF | mlr --icsv --otsv cat > Atha.karyo.tsv
#chrom,chromStart,chromEnd,name,gieStain
1,1,14200000,p1,gpos50
1,14200000,15627671,p1,acen
1,15627671,30427671,q1,gpos50
2,1,3000000,p2,gpos50
2,3000000,3898289,p2,acen
2,3898289,19698289,q2,gpos50
3,1,13200000,p3,gpos50
3,13200000,14459830,p3,acen
3,14459830,23459830,q3,gpos50
4,1,3000000,p4,gpos50
4,3000000,5085056,p4,acen
4,5085056,18585056,q4,gpos50
5,1,11100000,p5,gpos50
5,11100000,12575502,p5,acen
5,12575502,26975502,q5,gpos50
EOF

bash ${PATH_CIRCOS}/../data/karyotype/parse.karyotype \
    Atha.karyo.tsv \
    > karyotype.3702.txt

popd

```

## Rice

* 4530 Oryza sativa
* 39947 Oryza sativa Japonica Group

```bash
pushd share/karyotype/

mysql -hmysql-eg-publicsql.ebi.ac.uk -P4157 -uanonymous -e 'show databases' |
    grep oryza

perl ~/Scripts/withncbi/ensembl/chr_kary.pl \
    -s mysql-eg-publicsql.ebi.ac.uk --port 4157 -u anonymous -p '' \
    -e oryza_sativa_core_52_105_7

bash ${PATH_CIRCOS}/../data/karyotype/parse.karyotype \
    oryza_sativa_core_52_105_7.kary.tsv \
    > karyotype.4530.txt

cp karyotype.4530.txt karyotype.39947.txt

popd

```

## Yeast

* 4932 Saccharomyces cerevisiae

```bash
pushd share/karyotype/

mysql -hensembldb.ensembl.org -P5306 -uanonymous -e 'show databases' |
    grep -i Saccharomyces |
    grep 105

perl ~/Scripts/withncbi/ensembl/chr_kary.pl \
    -s ensembldb.ensembl.org --port 5306 -u anonymous -p '' \
    -e saccharomyces_cerevisiae_core_105_4

# No results

# Switch to gff
curl http://sgd-archive.yeastgenome.org/curation/chromosomal_feature/saccharomyces_cerevisiae.gff.gz |
    gzip -dcf |
    grep -i "ID=CEN" |
    grep -v -i "Parent" |
    sed 's/^chr//' |
    tsv-select -f 1,4,5,9 |
    perl -nla -F";" -e 'print $F[0]'


popd

```
