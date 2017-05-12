#!/bin/bash - 
#===============================================================================
#
#          FILE: bamtocram.sh
# 
#         USAGE: ./bamtocram.sh 
# 
#   DESCRIPTION: Using samtools 1.2 and htslib 1.2 convert bam files to cram files using a reference file 
# 
#  REQUIREMENTS: Reference fasta file
#         NOTES: Only tested on samtools 1.2
#        AUTHOR: Jillian Rowe, 
#  ORGANIZATION: WCMCQ
#       CREATED: 17/02/15 10:51
#      REVISION:  ---
#===============================================================================

#set -o nounset                              # Treat unset variables as an error

cd `pwd`

REF=$1

if [ ! -f $REF ]; then
    echo "Reference file not found!"
fi

find `pwd`/ |grep -e "bam$" | sed 's/bam$//' > bamlist.txt

#Had the order of things WRONG here before
cat bamlist.txt | xargs -n 1 -I % bash -c "echo 'samtools view -T $REF %bam -C -o %cram && samtools index %cram'"

rm bamlist.txt
