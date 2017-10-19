# [MaSuRCA](http://www.genome.umd.edu/masurca.html) 安装与样例

doi:10.1093/bioinformatics/btt476

[MaSuRCA_QuickStartGuide](ftp://ftp.genome.umd.edu/pub/MaSuRCA/MaSuRCA_QuickStartGuide.pdf)


[TOC levels=1-3]: # " "
- [[MaSuRCA](http://www.genome.umd.edu/masurca.html) 安装与样例](#masurca-安装与样例)
- [特点](#特点)
- [版本](#版本)
- [依赖](#依赖)
- [安装](#安装)
- [样例数据](#样例数据)
    - [Rhodobacter sphaeroides (球形红细菌)](#rhodobacter-sphaeroides-球形红细菌)
        - [Illumina PE, Short Jump and Sanger (1x or 4x)](#illumina-pe-short-jump-and-sanger-1x-or-4x)
        - [Rhodobacter sphaeroides with `anchr superreads`](#rhodobacter-sphaeroides-with-anchr-superreads)
        - [结果比较](#结果比较)
- [SuperReads 3.1.3](#superreads-313)
- [Super-reads and anchors](#super-reads-and-anchors)
    - [E. coli sampling](#e-coli-sampling)
        - [E. coli: link anchors](#e-coli-link-anchors)


# 特点

De novo 基因组序列的拼接有以下几种主流的策略:

1. Overlap–layout–consensus (OLC) assembly

    * 主要用于长 reads, 在 Sanger 测序时代就基本发展完备, 三代时代又重新发展
    * 代表: Celera Assembler, PCAP, Canu

2. de Bruijn graph (德布鲁因图)

    * 二代测序的主流
    * 代表: Velvet, SOAPdenovo, Allpaths-LG

3. String graph

    * Myers 提出的 OLC 的扩展, 主要是 layout 部分的算法有所不同. SGA 使用 FM-index/Burrows-Wheeler transform
      来找 overlaps, 较为节省内存
    * 代表: SGA

MaSuRCA 提出了一种新的策略, Super-reads. 主要思想是将多个短 reads 按 1 bp (实际上是 unique K-mer) 延伸,
合并得到数量少得多的长 reads. 在单倍体基因组的情况下, 无论覆盖度是多少 (50x, 100x), 最终的 super-reads
覆盖度都趋向于 2x. 高杂合基因组则趋向于 4x.

合并后的 super-reads 的 N50 约为 2-4 kbp.

# 版本

version 3.1.3.

homebrew-science 里的版本是 2.3.2b, 3.1.3 的
[PR](https://github.com/Homebrew/homebrew-science/pull/3802) 也有了, 但没合并.

九月 UMD 的 ftp 上有了 3.2.1 版, 多了 CA8, MUMmer 和 PacBio 三个目录, 还末详细研究.

http://ccb.jhu.edu/software.shtml

> New modules coming soon include methods to create hybrid assemblies using both Illumina and PacBio
> data.

# 依赖

外部

* gcc-4: macOS 下的 clang 无法编译
* m4: 宏语言, 由 `autoreconf -fi` 生成, 是 `GNU autotools` 的一部分, 不用管
* swig: for Perl binding of jellyfish

自带

* Celera Assembler
* [jellyfish](https://github.com/gmarcais/Jellyfish): k-mer counting
* prepare: 无文档, 看起来是预处理数据用的.
* [Quorum](https://github.com/gmarcais/Quorum): Error correction for Illumina reads.
* samtools
* SOAPdenovo2
* SuperReads: masurca 的主程序. 这个是我们所需要的, 合并 reads 的功能就在这里. 源码约五万行.
* ufasta: UMD 的操作 fasta 的工具, 未在其它地方发现相关信息. 里面的 tests 写得不错, 值得借鉴.

# 安装

```bash
echo "==> MaSuRCA"
cd /prepare/resource/
wget -N ftp://ftp.genome.umd.edu/pub/MaSuRCA/MaSuRCA-3.1.3.tar.gz

if [ -d $HOME/share/MaSuRCA ]; then
    rm -fr $HOME/share/MaSuRCA
fi

cd $HOME/share/
tar xvfz /prepare/resource/MaSuRCA-3.1.3.tar.gz

mv MaSuRCA-* MaSuRCA
cd MaSuRCA
sh install.sh
```

编译完成后, 会生成 `bin` 目录, 里面是可执行文件, `tree bin`.

```text
bin
├── add_missing_mates.pl
├── addSurrogatesToFrgCtgFile
├── addSurrogatesToFrgctg.perl
├── bloom_query
├── closeGapsInScaffFastaFile.perl
├── closeGapsLocally.perl
├── closeGaps.oneDirectory.fromMinKmerLen.perl
├── closeGaps.oneDirectory.perl
├── closeGaps.perl
├── close_gaps.sh
├── collectReadSequencesForLocalGapClosing
├── compute_sr_cov.pl
├── compute_sr_cov.revisedForGCContig.pl
├── create_end_pairs.perl
├── create_end_pairs.pl
├── createFastaSuperReadSequences
├── createKUnitigMaxOverlaps
├── create_k_unitigs_large_k
├── create_k_unitigs_large_k2
├── create_sr_frg
├── create_sr_frg.pl
├── createSuperReadSequenceAndPlacementFileFromCombined.perl
├── createSuperReadsForDirectory.perl
├── eliminateBadSuperReadsUsingList
├── error_corrected2frg
├── expand_fastq
├── extendSuperReadsBasedOnUniqueExtensions
├── extendSuperReadsForUniqueKmerNeighbors
├── extractJoinableAndNextPassReadsFromJoinKUnitigs.perl
├── extractreads_not.pl
├── extractreads.pl
├── extract_unjoined_pairs.pl
├── fasta2frg_m.pl
├── fasta2frg.pl
├── filter_alt.pl
├── filter_library.sh
├── filter_overlap_file
├── filter_redundancy.pl
├── finalFusion
├── findMatchesBetweenKUnitigsAndReads
├── findReversePointingJumpingReads_bigGenomes.perl
├── findReversePointingJumpingReads.perl
├── fix_unitigs.sh
├── getATBiasInCoverageForIllumina_v2
├── getEndSequencesOfContigs.perl
├── getGCBiasStatistics.perl
├── getLengthStatisticsForKUnitigsFile.perl
├── getMeanAndStdevByGCCount.perl
├── getMeanAndStdevForGapsByGapNumUsingCeleraAsmFile.perl
├── getMeanAndStdevForGapsByGapNumUsingCeleraTerminatorDirectory.perl
├── getNumBasesPerReadInFastaFile.perl
├── getSequenceForClosedGaps.perl
├── getSequenceForLocallyClosedGaps.perl
├── getSuperReadInsertCountsFromReadPlacementFile
├── getSuperReadInsertCountsFromReadPlacementFileTwoPasses
├── getSuperReadPlacements.perl
├── getUnitigTypeFromAsmFile.perl
├── homo_trim
├── jellyfish
├── joinKUnitigs_v3
├── killBadKUnitigs
├── makeAdjustmentFactorsForNumReadsForAStatBasedOnGC
├── makeAdjustmentFactorsForNumReadsForAStatBasedOnGC_v2
├── masurca
├── MasurcaCelera.pm
├── MasurcaCommon.pm
├── MasurcaConf.pm
├── MasurcaSoap.pm
├── masurca-superreads
├── MasurcaSuperReads.pm
├── mergeSuperReadsUniquely.pl
├── outputAlekseysJellyfishReductionFile.perl
├── outputJoinedPairs.perl
├── outputMatedReadsAsReverseComplement.perl
├── outputRecordsNotOnList
├── parallel
├── putReadsIntoGroupsBasedOnSuperReads
├── quorum
├── quorum_create_database
├── quorum_error_correct_reads
├── recompute_astat_superreads.sh
├── reduce_sr
├── rename_filter_fastq
├── rename_filter_fastq.pl
├── reportReadsToExclude.perl
├── restore_ns.pl
├── reverse_complement
├── runByDirectory
├── run_ECR.sh
├── runSRCA.pl
├── sample_mate_pairs.pl
├── samtools
├── semaphore
├── SOAPdenovo-127mer
├── SOAPdenovo-63mer
├── sorted_merge
├── splitFileAtNs
├── splitFileByPrefix.pl
├── translateReduceFile.perl
└── ufasta

0 directories, 100 files
```

同时还生成一个配置文件样例, `sr_config_example.txt`.

# 样例数据

MaSuRCA 发表在 Bioinformatics 时自带的测试数据.

> IMPORTANT! Do not pre‐process Illumina data before providing it to MaSuRCA. Do not do any
> trimming, cleaning or error correction. This WILL deteriorate the assembly

Super-reads在 `work1/superReadSequences.fasta`, `work2/` 和 `work2.1/` 是 short jump 的处理, 不用管.
`superReadSequences_shr.frg` 里面的 super-reads 是作过截断处理的, 数量不对.

> Assembly result. The final assembly files are under CA/10-gapclose and named 'genome.ctg.fasta'
> for the contig sequences and 'genome.scf.fasta' for the scaffold sequences.

MaSuRCA-3.1.3 supports gzipped fastq files while MaSuRCA-2.1.0 doesn't.

## Rhodobacter sphaeroides (球形红细菌)

高 GC 原核生物 (68%), 基因组 4.5 Mbp.

```bash
mkdir -p ~/data/test
cd ~/data/test

wget -m ftp://ftp.genome.umd.edu/pub/MaSuRCA/test_data/rhodobacter .

mv ftp.genome.umd.edu/pub/MaSuRCA/test_data/rhodobacter .
rm -fr ftp.genome.umd.edu
find . -name ".listing" | xargs rm
```

### Illumina PE, Short Jump and Sanger (1x or 4x)

```bash
cd ~/data/test

cat <<EOF > sr_config.txt
PARAMETERS
CA_PARAMETERS = ovlMerSize=30 cgwErrorRate=0.25 merylMemory=8192 ovlMemory=4GB 
LIMIT_JUMP_COVERAGE = 60
KMER_COUNT_THRESHOLD = 1
EXTEND_JUMP_READS = 0
NUM_THREADS = 16
JF_SIZE = 50000000
END

EOF

# Illumina PE, Short Jump and Sanger4
mkdir -p rhodobacter_PE_SJ_Sanger4
cp sr_config.txt rhodobacter_PE_SJ_Sanger4/
cat <<EOF >> rhodobacter_PE_SJ_Sanger4/sr_config.txt
DATA
PE=  pe 180 20 /home/wangq/data/test/rhodobacter/PE/frag_1.fastq /home/wangq/data/test/rhodobacter/PE/frag_2.fastq
JUMP= sj 3600 200  /home/wangq/data/test/rhodobacter/SJ/short_1.fastq  /home/wangq/data/test/rhodobacter/SJ/short_2.fastq
OTHER=/home/wangq/data/test/rhodobacter/Sanger/rhodobacter_sphaeroides_2_4_1.4x.frg
END

EOF

# Illumina PE, Short Jump and Sanger
mkdir -p rhodobacter_PE_SJ_Sanger
cp sr_config.txt rhodobacter_PE_SJ_Sanger/
cat <<EOF >> rhodobacter_PE_SJ_Sanger/sr_config.txt
DATA
PE=  pe 180 20 /home/wangq/data/test/rhodobacter/PE/frag_1.fastq /home/wangq/data/test/rhodobacter/PE/frag_2.fastq
JUMP= sj 3600 200  /home/wangq/data/test/rhodobacter/SJ/short_1.fastq  /home/wangq/data/test/rhodobacter/SJ/short_2.fastq
OTHER=/home/wangq/data/test/rhodobacter/Sanger/rhodobacter_sphaeroides_2_4_1.1x.frg
END

EOF

# Illumina PE and Short Jump
mkdir -p rhodobacter_PE_SJ
cp sr_config.txt rhodobacter_PE_SJ/
cat <<EOF >> rhodobacter_PE_SJ/sr_config.txt
DATA
PE=  pe 180 20 /home/wangq/data/test/rhodobacter/PE/frag_1.fastq /home/wangq/data/test/rhodobacter/PE/frag_2.fastq
JUMP= sj 3600 200  /home/wangq/data/test/rhodobacter/SJ/short_1.fastq  /home/wangq/data/test/rhodobacter/SJ/short_2.fastq
END

EOF

# Illumina PE, and Sanger4
mkdir -p rhodobacter_PE_Sanger4
cp sr_config.txt rhodobacter_PE_Sanger4/
cat <<EOF >> rhodobacter_PE_Sanger4/sr_config.txt
DATA
PE=  pe 180 20 /home/wangq/data/test/rhodobacter/PE/frag_1.fastq /home/wangq/data/test/rhodobacter/PE/frag_2.fastq
OTHER=/home/wangq/data/test/rhodobacter/Sanger/rhodobacter_sphaeroides_2_4_1.4x.frg
END

EOF

# Illumina PE, and Sanger
mkdir -p rhodobacter_PE_Sanger
cp sr_config.txt rhodobacter_PE_Sanger/
cat <<EOF >> rhodobacter_PE_Sanger/sr_config.txt
DATA
PE=  pe 180 20 /home/wangq/data/test/rhodobacter/PE/frag_1.fastq /home/wangq/data/test/rhodobacter/PE/frag_2.fastq
OTHER=/home/wangq/data/test/rhodobacter/Sanger/rhodobacter_sphaeroides_2_4_1.1x.frg
END

EOF

# Illumina PE
mkdir -p rhodobacter_PE_Sanger
cp sr_config.txt rhodobacter_PE_Sanger/
cat <<EOF >> rhodobacter_PE_Sanger/sr_config.txt
DATA
PE=  pe 180 20 /home/wangq/data/test/rhodobacter/PE/frag_1.fastq /home/wangq/data/test/rhodobacter/PE/frag_2.fastq
END

EOF

# Run
cd ~/data/test

for d in rhodobacter_PE_SJ_Sanger4 rhodobacter_PE_SJ_Sanger rhodobacter_PE_SJ rhodobacter_PE_Sanger4 rhodobacter_PE_Sanger rhodobacter_PE rhodobacter_superreads;
do
    echo "==> ${d}"
    if [ -e ${d}/work1/superReadSequences.fasta ];
    then
        continue     
    fi

    pushd ~/data/test/rhodobacter_PE_SJ_Sanger4 > /dev/null
    $HOME/share/MaSuRCA/bin/masurca sr_config.txt
    bash assemble.sh
    popd > /dev/null
done
```

### Rhodobacter sphaeroides with `anchr superreads`

```bash
# gzip original fastq
mkdir -p ~/data/test/rhodobacter/PEgz
gzip -c ~/data/test/rhodobacter/PE/frag_1.fastq > ~/data/test/rhodobacter/PEgz/frag_1.fq.gz
gzip -c ~/data/test/rhodobacter/PE/frag_2.fastq > ~/data/test/rhodobacter/PEgz/frag_2.fq.gz

mkdir -p ~/data/test/rhodobacter_superreads
cd ~/data/test/rhodobacter_superreads

perl ~/Scripts/sra/superreads.pl \
    ~/data/test/rhodobacter/PEgz/frag_1.fq.gz \
    ~/data/test/rhodobacter/PEgz/frag_2.fq.gz \
    -s 180 -d 20

```

### 结果比较

```bash
cd ~/data/test/

printf "| %s | %s | %s | %s | %s | %s | %s | %s |\n" \
    "Name" "N50SR" "#SR" "N50Contig" "#Contig" "N50Scaffold" "#Scaffold" "EstG" \
    > stat.md
printf "|:--|--:|--:|--:|--:|--:|--:|--:|\n" >> stat.md

for d in rhodobacter_PE_SJ_Sanger4 rhodobacter_PE_SJ_Sanger rhodobacter_PE_SJ rhodobacter_PE_Sanger4 rhodobacter_PE_Sanger rhodobacter_PE rhodobacter_superreads;
do
    printf "| %s | %s | %s | %s | %s | %s | %s | %s |\n" \
        ${d} \
        $( faops n50 -H -N 50 -C ${d}/work1/superReadSequences.fasta ) \
        $( faops n50 -H -N 50 -C ${d}/CA/10-gapclose/genome.ctg.fasta ) \
        $( faops n50 -H -N 50 -C ${d}/CA/10-gapclose/genome.scf.fasta ) \
        $( cat ${d}/environment.sh \
            | perl -n -e '/ESTIMATED_GENOME_SIZE=\"(\d+)\"/ and print $1' )
done >> stat.md

cat stat.md
```

| name          | N50SR |  #SR | N50Contig | #Contig | N50Scaffold | #Scaffold |    EstG |
|:--------------|------:|-----:|----------:|--------:|------------:|----------:|--------:|
| PE_SJ_Sanger4 |  4586 | 4187 |    205225 |      69 |     3196849 |        35 | 4602968 |
| PE_SJ_Sanger  |  4586 | 4187 |     63274 |     141 |     3070846 |        28 | 4602968 |
| PE_SJ         |  4586 | 4187 |     43125 |     219 |     3058404 |        59 | 4602968 |
| PE_Sanger4    |  4705 | 4042 |    125228 |      67 |      534852 |        30 | 4595684 |
| PE_Sanger     |  4705 | 4042 |     19435 |     412 |       21957 |       359 | 4595684 |
| PE            |  4705 | 4043 |     20826 |     407 |       34421 |       278 | 4595684 |
| superreads    |  4705 | 4043 |           |         |             |           | 4595684 |

有足够多的 long reads 支持下, 不需要 short jump.

# SuperReads 3.1.3

2017 年 2 月, UMD ftp 上多了一个新程序
[SuperReads_RNA](ftp://ftp.genome.umd.edu/pub/MaSuRCA/beta/SuperReads_RNA-1.0.1.tar.gz), 是 MaSuRCA
3.2.1 的简化版. 很可能是 `StringTie` 用了 super-reads 来处理 RNA-seq, 在很多人的要求下做的.

根据这个版本, 我将 MaSuRCA 3.1.3 简化, 去掉所有的依赖, 去掉配合 `Celera Assembler` 的部分, 只留下了
`SuperReads`, 可以用 `Linuxbrew` 安装.

```bash
brew install homebrew/science/jellyfish
brew install wang-q/tap/quorum@1.1.1
brew install wang-q/tap/superreads
```

# Super-reads and anchors

## E. coli: link anchors

```bash
cd ~/zlc/Ecoli/anchorAlign

for id in 0_11 10_13 11_7 12_3 13_33 14_8 15_11 16_20 17_4 18_17 19_19 1_4 20_15 21_13 22_8 23_15 24_34 25_8 26_3 27_30 28_2 29_13 2_27 30_25 31_15 32_28 33_2 34_16 35_3 36_23 37_5 38_29 39_5 3_12 40_9 41_19 4_5 5_7 6_56 7_12 8_15 9_6;
do
    bash ~/Scripts/cpan/App-Anchr/share/link_anchor.sh ${id}.anchor.fasta ${id}.pac.fasta ${id};
    GROUP_COUNT=$(id=${id} perl -e '@p = split q{_}, $ENV{id}; print $p[1];')
    perl ~/Scripts/cpan/App-Anchr/share/ovlp_layout.pl ${id}.ovlp.tsv --range "1-${GROUP_COUNT}"
done

# Exceeded memory bound: 502169772
#poa -preserve_seqorder -read_fasta 9_2.renamed.fasta -clustal 9_2.aln -hb ~/Scripts/sra/poa-blosum80.mat 

#cp 9_2.renamed.fasta myDB.pp.fasta
#
#DBrm myDB
#fasta2DB myDB myDB.pp.fasta
#DBdust myDB
#
#if [ -e myDB.las ]; then
#    rm myDB.las
#fi
#HPC.daligner myDB -v -M4 -e.70 -l1000 -s1000 -mdust > job.sh
#bash job.sh
#rm job.sh
#
#LA4Falcon -o myDB.db myDB.las 1-2
#
#perl ~/Scripts/sra/las2ovlp.pl 9_2.renamed.fasta <(LAshow -o myDB.db myDB.las 1)
#
#perl ~/Scripts/sra/las2ovlp.pl 9_2.renamed.fasta 9_2.show.txt -r 9_2.replace.tsv


# 3 5 10 8 4 9 7 2 11 6 1
perl ~/Scripts/egaz/sparsemem_exact.pl \
    -f 0_11.renamed.fasta -g ~/data/dna-seq/e_coli/superreads/NC_000913.fa \
    --length 500 -o 0_11.chr.tsv
perl ~/Scripts/sra/ovlp_layout.pl 0_11.ovlp.tsv --range 1-11

# 16 47 19 51 28 22 15 11 43 5 34 44 4 37 6 9 53 24 40 52 46 23 32 38 55 54 18 31 10 26 2 8 48 36 27 29 30 45 50 33 35 42 41 3 25 20 17 14 7 56 21 13 39 49 12 1
perl ~/Scripts/egaz/sparsemem_exact.pl \
    -f 6_56.renamed.fasta -g ~/data/dna-seq/e_coli/superreads/NC_000913.fa \
    --length 500 -o 6_56.chr.tsv
perl ~/Scripts/sra/ovlp_layout.pl 6_56.ovlp.tsv --range 1-56

# pip install pysam biopython
python ~/Scripts/sra/nanocorrect.py myDB all > corrected.fasta

```
