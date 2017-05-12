#
# Samples: sample1, sample2, sample3, sample4, sample5
#
#
# Starting Workflow
#
#
# Global Variables:
#	resample: 0
#	wait: 1
#	auto_input: 1
#	coerce_paths: 1
#	auto_name: 1
#	indir: t/example/data/raw/test005
#	outdir: t/example/data/processed/test005
#	min: 1
#	override_process: 0
#	rule_based: 1
#	verbose: 1
#	create_outdir: 1
#	file_rule: (.*).csv
#

#
#

# Starting backup
#



#
# Variables 
# Indir: $Bin/example/data/raw/test005
# Outdir: $Bin/example/data/processed/test005/backup
#

cp $Bin/example/data/raw/test005/${SAMPLE}.csv $Bin/example/data/processed/test005/backup/${SAMPLE}.csv


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
# Indir: $Bin/example/data/processed/test005/backup
# Outdir: $Bin/example/data/processed/test005/grep_VARA
#

echo "Working on $Bin/example/data/processed/test005/backup/${SAMPLE}.csv"
grep -i "VARA" $Bin/example/data/processed/test005/backup/${SAMPLE}.csv >> $Bin/example/data/processed/test005/grep_VARA/${SAMPLE}.grep_VARA.csv



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
# Indir: $Bin/example/data/processed/test005/grep_VARA
# Outdir: $Bin/example/data/processed/test005/grep_VARB
#

grep -i "VARB" $Bin/example/data/processed/test005/grep_VARA/${SAMPLE}.grep_VARA.csv >> $Bin/example/data/processed/test005/grep_VARB/${SAMPLE}.grep_VARA.grep_VARB.csv



wait

#
# Ending grep_VARB
#

#
# Ending Workflow
#
