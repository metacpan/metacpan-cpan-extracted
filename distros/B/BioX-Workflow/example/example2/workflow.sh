#!/bin/bash

#
# Generated at: 2015-12-23T10:39:02
# This file was generated with the following options
#	--workflow	gemini.yml
#

#
# Samples: SAMPLE1, SAMPLE2, SAMPLE3
#
#
# Starting Workflow
#
#
# Global Variables:
#	ROOT: data/raw
#	indir: data/raw
#	outdir: data/processed
#	file_rule: (.vcf)$|(.vcf.gz)$
#

#
#

# Starting bgzip
#



#
# Variables 
# Indir: data/raw
# Outdir: data/processed/bgzip
#

bgzip data/raw/SAMPLE1.vcf && tabix data/raw/SAMPLE1.vcf.gz










wait

#
# Ending bgzip
#


#
#

# Starting normalize_snpeff
#



#
# Variables 
# Indir: {$self->ROOT}
# Outdir: data/processed/normalize_snpeff
# Local Variables:
#	indir: {$self->ROOT}
#	outdir: data/processed/normalize_snpeff
#

bcftools view data/raw/SAMPLE1.vcf.gz | sed 's/ID=AD,Number=./ID=AD,Number=R/' \
    | vt decompose -s - \
    | vt normalize -r $REFGENOME - \
    | java -Xmx4G -jar $SNPEFF/snpEff.jar -c \$SNPEFF/snpEff.config -formatEff -classic GRCh37.75  \
    | bgzip -c > \
    data/processed/normalize_snpeff/SAMPLE1.norm.snpeff.gz && tabix data/processed/normalize_snpeff/SAMPLE1.norm.snpeff.gz


bcftools view data/raw/SAMPLE2.vcf.gz | sed 's/ID=AD,Number=./ID=AD,Number=R/' \
    | vt decompose -s - \
    | vt normalize -r $REFGENOME - \
    | java -Xmx4G -jar $SNPEFF/snpEff.jar -c \$SNPEFF/snpEff.config -formatEff -classic GRCh37.75  \
    | bgzip -c > \
    data/processed/normalize_snpeff/SAMPLE2.norm.snpeff.gz && tabix data/processed/normalize_snpeff/SAMPLE2.norm.snpeff.gz


bcftools view data/raw/SAMPLE3.vcf.gz | sed 's/ID=AD,Number=./ID=AD,Number=R/' \
    | vt decompose -s - \
    | vt normalize -r $REFGENOME - \
    | java -Xmx4G -jar $SNPEFF/snpEff.jar -c \$SNPEFF/snpEff.config -formatEff -classic GRCh37.75  \
    | bgzip -c > \
    data/processed/normalize_snpeff/SAMPLE3.norm.snpeff.gz && tabix data/processed/normalize_snpeff/SAMPLE3.norm.snpeff.gz



wait

#
# Ending normalize_snpeff
#


#
#

# Starting gemini_sqlite
#



#
# Variables 
# Indir: data/processed/normalize_snpeff
# Outdir: data/processed/gemini_sqlite
#

gemini load -v data/processed/normalize_snpeff/SAMPLE1.norm.snpeff.gz \
    --skip-cadd -t snpEff \
   data/processed/gemini_sqlite/SAMPLE1.vcf.db


gemini load -v data/processed/normalize_snpeff/SAMPLE2.norm.snpeff.gz \
    --skip-cadd -t snpEff \
   data/processed/gemini_sqlite/SAMPLE2.vcf.db


gemini load -v data/processed/normalize_snpeff/SAMPLE3.norm.snpeff.gz \
    --skip-cadd -t snpEff \
   data/processed/gemini_sqlite/SAMPLE3.vcf.db



wait

#
# Ending gemini_sqlite
#

#
# Ending Workflow
#
