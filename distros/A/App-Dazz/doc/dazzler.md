# dazzler: basic usage of dazz_db and daligner

## dazz_db

`DBsplit`

* If the `-x` option is set then all reads less than the given length are ignored.
* Each block is of size `-s` * 1 Mbp except for the last.

### Rename sequences for dazzler

Create two files, `renamed.fasta`, `stdout.replace.tsv`.

```shell script
# Dmel iso_1 reference genome
mkdir -p ~/data/dazz/ref
cd ~/data/dazz/ref

rsync -avP \
    ftp.ncbi.nlm.nih.gov::genomes/all/GCF/000/001/215/GCF_000001215.4_Release_6_plus_ISO1_MT/ \
    iso_1/

# rename
mkdir -p ~/data/dazz/dazzler
cd ~/data/dazz/dazzler

gzip -dcf ../ref/iso_1/GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fna.gz |
    dazz dazzname stdin -o stdout |
    faops filter -l 0 stdin renamed.fasta

```

### Create and split DB

`myDB.db` and its hidden companions.

```shell script
cd ~/data/dazz/dazzler

echo "Make the dazzler DB"
DBrm myDB
fasta2DB myDB renamed.fasta
DBdust myDB
# each block is of size 50 MB
DBsplit -s50 myDB

BLOCK_NUMBER=$(cat myDB.db | perl -nl -e '/^blocks\s+=\s+(\d+)/ and print $1')
echo ${BLOCK_NUMBER}

```

### Retrieve some records from DB

* If the `-n` option is set then the DNA sequence is **not** displayed

```shell script
cd ~/data/dazz/dazzler

# headers
DBshow -n myDB 5-10 102 100-101

# sequences from the original file
faops some -l 0 renamed.fasta <(DBshow -n myDB 5-10 102 100-101 | sed 's/^>//') stdout

```

## daligner

`HPC.daligner`

* local alignments involving at least `-l` base pairs (default 1000)
* An average correlation rate of `-e` (default 70%) set to 80%
* The default number of threads is 4, set by `-T` option (power of 2)
* Set the `-t` parameter which suppresses the use of any *k*-mer that occurs more than *t* times in
  either the subject or target block.
* Let the program automatically select a value of *t* that meets a given memory usage limit
  specified (in Gb) by the `-M` parameter
* one or more interval tracks specified with the `-m` option (m for mask)

### Create jobs by `HPC.daligner` and execute it

Three .las (`myDB.[1-3].las`) files are generated then concatenated to `myDB.las`.

```shell script
cd ~/data/dazz/dazzler

if [[ -e myDB.las || -e myDB.1.las ]]; then
    rm myDB*.las
fi
HPC.daligner -v -M16 -e.96 -l500 -s500 -mdust myDB > job.sh
bash job.sh

LAcat -v myDB.@.las > myDB.las

```

Contents of `job.sh`

```shell script
# Daligner jobs (3)
daligner -v -e0.96 -l500 -s500 -M16 -mdust myDB.1 myDB.@1-1
daligner -v -e0.96 -l500 -s500 -M16 -mdust myDB.2 myDB.@1-2
daligner -v -e0.96 -l500 -s500 -M16 -mdust myDB.3 myDB.@1-3
# Check initial .las files jobs (3) (optional but recommended)
LAcheck -vS myDB myDB.1.myDB.@
LAcheck -vS myDB myDB.2.myDB.@
LAcheck -vS myDB myDB.3.myDB.@
# Merge jobs (3)
LAmerge -v myDB.1 myDB.1.myDB.@ && LAcheck -vS myDB myDB.1
LAmerge -v myDB.2 myDB.2.myDB.@ && LAcheck -vS myDB myDB.2
LAmerge -v myDB.3 myDB.3.myDB.@ && LAcheck -vS myDB myDB.3
# Remove block .las files (optional)
rm myDB.1.myDB.*.las
rm myDB.2.myDB.*.las
rm myDB.3.myDB.*.las

```

The 3 lines of daligner are equivalent to the following:

```shell script
daligner -v -e0.96 -l500 -s500 -M16 -mdust myDB.1 myDB.1
daligner -v -e0.96 -l500 -s500 -M16 -mdust myDB.1 myDB.2
daligner -v -e0.96 -l500 -s500 -M16 -mdust myDB.1 myDB.3
daligner -v -e0.96 -l500 -s500 -M16 -mdust myDB.2 myDB.2
daligner -v -e0.96 -l500 -s500 -M16 -mdust myDB.2 myDB.3
daligner -v -e0.96 -l500 -s500 -M16 -mdust myDB.3 myDB.3

```

Results.

```shell script
cd ~/data/dazz/dazzler

LAshow myDB.db myDB.las
LAshow -o myDB.db myDB.las
LAshow -co myDB.db myDB.las

```

## Between two files

`daligner` *不能* 对两个数据库之间做 overlap 比较. 现在的策略是将两个 fasta 文件放到一个数据库里, 再将数据库 split
成多个子库, 将包含有第一个序列的子库对其它子库做比较. 还是可以减少很多计算量的.

Only between other than all-vs-all to reduce computational tasks.

```shell script
mkdir -p ~/data/dazz/dazzler2
cd ~/data/dazz/dazzler2

cat ~/data/dazz/e_coli/4_kunitigs/Q20L60X80P000/anchor/anchor.fasta |
    dazz dazzname --prefix first stdin -o stdout |
    faops filter -l 0 stdin first.fasta
mv stdout.replace.tsv first.replace.tsv

gzip -dcf ~/data/dazz/e_coli/3_long/L.X80.trim.fasta.gz |
    head -n 20000 |
    dazz dazzname --prefix second stdin -o stdout |
    faops filter -l 0 -a 1000 stdin second.fasta
mv stdout.replace.tsv second.replace.tsv

echo "Make the dazzler DB"
DBrm myDB
fasta2DB myDB first.fasta
fasta2DB myDB second.fasta
DBdust myDB
DBsplit -s20 myDB

BLOCK_NUMBER=$(cat myDB.db | perl -nl -e '/^blocks\s+=\s+(\d+)/ and print $1')
echo ${BLOCK_NUMBER}

if [[ -e myDB.las || -e myDB.1.las ]]; then
    rm myDB*.las
fi

seq 1 1 ${BLOCK_NUMBER} |
    parallel --no-run-if-empty --keep-order -j 4 '
        daligner -e0.96 -l500 -s500 -M16 -mdust myDB.1 myDB.{};
        LAcheck -vS myDB myDB.1.myDB.{};
        LAcheck -vS myDB myDB.{}.myDB.1;
    '

LAmerge -v myDB.1 myDB.1.myDB.1 myDB.1.myDB.2 myDB.1.myDB.3 myDB.1.myDB.4 myDB.1.myDB.5
LAcheck -vS myDB myDB.1

LAmerge -v myDB.2 myDB.2.myDB.1 myDB.3.myDB.1 myDB.4.myDB.1 myDB.5.myDB.1
LAcheck -vS myDB myDB.2

rm myDB.*.myDB.*.las

LAcat -v myDB.@.las > myDB.las
LAcheck -vS myDB myDB
rm myDB.*.las

LAshow -o myDB.db myDB.las

```
