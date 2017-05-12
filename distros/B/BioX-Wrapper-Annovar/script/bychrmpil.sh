#!/bin/bash - 
#===============================================================================
#
#          FILE: bychrmpil.sh
# 
#         USAGE: ./bychrmpil.sh 
# 
#   DESCRIPTION: Output commands for mpileup by chromosome in parallel
#               Adapted from a blog post here
#               http://www.research.janahang.com/efficient-way-to-generate-vcf-files-using-samtools/
#                And updated to run to with samtools 1.2
#                Works with bam and cram files
#       OPTIONS: $1 fasta file
#  REQUIREMENTS: samtools, bcftools, hstlib
#         NOTES: To run these commands you need samtools and bcftools
#        AUTHOR: Jillian Rowe, 
#  ORGANIZATION: WCMC-Q
#       CREATED: 21/01/15 14:33
#      REVISION:  ---
#===============================================================================

#Checked with samtools 1.2, htslib 1.2, and bcftools 1.2
#
# samtools mpileup -t DP,DPR,DV,DP4,INFO/DPR,SP -gus -f human_g1k_v37.fasta -r GL000237.1 HG00096.mapped.illumina.mosaik.GBR.exome.20110411.cram | bcftools call -mO z --output tmp.vcf.gz

cd `pwd`

mkdir -p tmpbcf

#Making htis refdir for a moment
REF=$1

find `pwd`/ |grep -e "bam$" -e "cram$" > bamlist.txt

cat bamlist.txt | xargs -n 1 -I % bash -c "samtools view -H % " |  grep "\@SQ" | sed 's/^.*SN://g' | cut -f 1 >> tt

cat tt | sort | uniq > coord.txt

rm tt

#Lets shuffle the input to distribute it better

#Getting rid of having a bcftools view on each chromosome - save it for the end
# cat coord.txt | shuf | xargs -I {} -n 1 bash -c "echo 'samtools mpileup -gu -f $REF -r {} -b `pwd`/bamlist.txt | bcftools call -mO z --output `pwd`/tmpbcf/tmp.{}.bcf'"
cat coord.txt | shuf | xargs -I {} -n 1 bash -c "echo 'samtools mpileup -t DP,DPR,DV,DP4,INFO/DPR,SP -gu -f $REF/{}.fasta -r {} -b `pwd`/bamlist.txt | bcftools call -mO z --output `pwd`/tmpbcf/tmp.{}.bcf'"

#Wait for these to finish
echo -e "wait\n" 

# Got to cat the bcf files back together
# echo "find `pwd`/tmpbcf/*bcf > bcflist.txt && bcftools concat -f `pwd`/bcflist.txt > `pwd`/merge.bcf && bcftools call -mO b `pwd`/merge.bcf --output `pwd`/merge.call.bcf"
#Already did the calling now just need to concat
echo "find `pwd`/tmpbcf/*bcf > bcflist.txt && bcftools concat -f `pwd`/bcflist.txt > `pwd`/merge.bcf"

rm coord.txt
