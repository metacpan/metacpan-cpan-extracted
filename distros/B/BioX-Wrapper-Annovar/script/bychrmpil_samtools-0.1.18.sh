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
#               These commands work with samtools-0.1.18
#       OPTIONS: $1 fasta file
#  REQUIREMENTS: samtools, bcftools
#         NOTES: To run these commands you need samtools and bcftools
#        AUTHOR: Jillian Rowe, 
#  ORGANIZATION: WCMC-Q
#       CREATED: 21/01/15 14:33
#      REVISION:  ---
#===============================================================================

cd `pwd`

mkdir -p tmpbcf

REF=$1

find `pwd`/ |grep -e "bam$" > bamlist.txt

cat bamlist.txt | xargs -n 1 -I % bash -c "samtools view -H % " |  grep "\@SQ" | sed 's/^.*SN://g' | cut -f 1 >> tt

cat tt | sort | uniq > coord.txt

rm tt

#Lets shuffle the input to distribute it better

# cat coord.txt | shuf | xargs -I {} -n 1 bash -c 'echo -e "samtools mpileup -DguS -f $1 -r {} -b bamlist.txt | bcftools view -bvcg - > tmpbcf/tmp.{}.bcf && bcftools view tmpbcf/tmp.{}.bcf > tmpbcf/tmp.{}.vcf\n"'

#Getting rid of having a bcftools view on each chromosome - save it for the end
cat coord.txt | shuf | xargs -I {} -n 1 bash -c "echo 'samtools mpileup -DguS -f $REF -r {} -b `pwd`/bamlist.txt | bcftools view -bvcg - > `pwd`/tmpbcf/tmp.{}.bcf'"

#Wait for these to finish
echo -e "wait\n" 

# Got to cat the bcf files back together
# find `pwd`/tmpbcf | grep -e "bcf$" > bcflist.txt
# Didn't work with the -f option not sure why
echo "find `pwd`/tmpbcf/*bcf | xargs bcftools cat > `pwd`/merge.bcf && bcftools view `pwd`/merge.bcf > `pwd`/merge.vcf"

rm coord.txt
