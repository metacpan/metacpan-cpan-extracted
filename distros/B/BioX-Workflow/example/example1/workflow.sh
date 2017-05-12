#!/bin/bash

#
# Generated at: 2015-12-23T10:38:47
# This file was generated with the following options
#	--workflow	config.yml
#

#
# Samples: SAMPLE1, SAMPLE2
#
#
# Starting Workflow
#
#
# Global Variables:
#	indir: data/raw
#	outdir: data/processed
#	file_rule: (.csv)$
#

#
#

# Starting backup
#



#
# Variables 
# Indir: data/raw
# Outdir: data/processed/backup
#

cp data/raw/SAMPLE1.csv data/processed/backup/SAMPLE1.csv

cp data/raw/SAMPLE2.csv data/processed/backup/SAMPLE2.csv


wait

#
# Ending backup
#


#
#

# Starting grep_VARA
#



#
# Variables 
# Indir: data/processed/backup
# Outdir: data/processed/grep_VARA
#

echo "Working on data/processed/backup/SAMPLE1csv"
grep -i "VARA" data/processed/backup/SAMPLE1.csv >> data/processed/grep_VARA/SAMPLE1.grep_VARA.csv


echo "Working on data/processed/backup/SAMPLE2csv"
grep -i "VARA" data/processed/backup/SAMPLE2.csv >> data/processed/grep_VARA/SAMPLE2.grep_VARA.csv



wait

#
# Ending grep_VARA
#


#
#

# Starting grep_VARB
#



#
# Variables 
# Indir: data/processed/grep_VARA
# Outdir: data/processed/grep_VARB
#

grep -i "VARB" data/processed/grep_VARA/SAMPLE1.grep_VARA.csv >> data/processed/grep_VARB/SAMPLE1.grep_VARA.grep_VARB.csv


grep -i "VARB" data/processed/grep_VARA/SAMPLE2.grep_VARA.csv >> data/processed/grep_VARB/SAMPLE2.grep_VARA.grep_VARB.csv



wait

#
# Ending grep_VARB
#

#
# Ending Workflow
#
