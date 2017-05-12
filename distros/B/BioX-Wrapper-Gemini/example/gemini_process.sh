#!/bin/bash

#######################################################################
# This file was generated with the following options
#	--indir	/home/guests/jir2004/perlmodule/BioX-Wrapper-Gemini/example
#	--outdir	/home/guests/jir2004/perlmodule/BioX-Wrapper-Gemini/example/processed
#######################################################################



#######################################################################
# Starting Sample Info Section
#######################################################################

# test1, test2

#######################################################################
# Ending Sample Info Section
#######################################################################


#######################################################################
# Starting Bgzip Section
#######################################################################
# The following samples must be bgzipped before processing can begin
# /home/guests/jir2004/perlmodule/BioX-Wrapper-Gemini/example/test1.vcf
#######################################################################

bgzip /home/guests/jir2004/perlmodule/BioX-Wrapper-Gemini/example/test1.vcf && tabix /home/guests/jir2004/perlmodule/BioX-Wrapper-Gemini/example/test1.vcf.gz
wait


#######################################################################
# Finished Bgzip Section
#######################################################################

#######################################################################
# Normalizing with VT and annotating with SNPEFF the following samples
# test1, test2
#######################################################################

bcftools view /home/guests/jir2004/perlmodule/BioX-Wrapper-Gemini/example/test1.vcf.gz | sed 's/ID=AD,Number=./ID=AD,Number=R/' \
    | vt decompose -s - \
    | vt normalize -r $REFGENOME - \
    | java -Xmx4G -jar $SNPEFF/snpEff.jar -c \$SNPEFF/snpEff.config -formatEff -classic GRCh37.75  \
    | bgzip -c > \
    /home/guests/jir2004/perlmodule/BioX-Wrapper-Gemini/example/processed/gemini-wrapper/norm_annot_vcf/test1.norm.snpeff.gz && tabix /home/guests/jir2004/perlmodule/BioX-Wrapper-Gemini/example/processed/gemini-wrapper/norm_annot_vcf/test1.norm.snpeff.gz


bcftools view /home/guests/jir2004/perlmodule/BioX-Wrapper-Gemini/example/test2.vcf.gz | sed 's/ID=AD,Number=./ID=AD,Number=R/' \
    | vt decompose -s - \
    | vt normalize -r $REFGENOME - \
    | java -Xmx4G -jar $SNPEFF/snpEff.jar -c \$SNPEFF/snpEff.config -formatEff -classic GRCh37.75  \
    | bgzip -c > \
    /home/guests/jir2004/perlmodule/BioX-Wrapper-Gemini/example/processed/gemini-wrapper/norm_annot_vcf/test2.norm.snpeff.gz && tabix /home/guests/jir2004/perlmodule/BioX-Wrapper-Gemini/example/processed/gemini-wrapper/norm_annot_vcf/test2.norm.snpeff.gz


wait


#######################################################################
# Finished Normalize Annotate Section
#######################################################################

#######################################################################
# Gemini is loading the following samples
# test1, test2
#######################################################################

gemini load -v /home/guests/jir2004/perlmodule/BioX-Wrapper-Gemini/example/processed/gemini-wrapper/norm_annot_vcf/test1.norm.snpeff.gz \
    --skip-cadd -t snpEff \
     /home/guests/jir2004/perlmodule/BioX-Wrapper-Gemini/example/processed/gemini-wrapper/gemini_sqlite/test1.vcf.db


gemini load -v /home/guests/jir2004/perlmodule/BioX-Wrapper-Gemini/example/processed/gemini-wrapper/norm_annot_vcf/test2.norm.snpeff.gz \
    --skip-cadd -t snpEff \
     /home/guests/jir2004/perlmodule/BioX-Wrapper-Gemini/example/processed/gemini-wrapper/gemini_sqlite/test2.vcf.db


wait


#######################################################################
# Finished Gemini Load Section
#######################################################################
