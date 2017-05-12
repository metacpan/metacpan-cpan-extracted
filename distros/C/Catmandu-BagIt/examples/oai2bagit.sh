#!/bin/bash 
# Example script to download metadata + files from an institutional archive.
# This requires a working installation of Catmandu::OAI.
#
# Hint:
#      sudo cpanm Catmandu::OAI
#
OAI_BASE_URL=http://pub.uni-bielefeld.de/oai
SET_SPEC=workingPaperFtxt
MAX_NUM_RECORDS=10
FIX_FILE=examples/pub-uni-bielefeld-de.fix

# Here we fetch OAI data from a repository, grep only those records that are not 
# deleted, take the first MAX_NUM_RECORDS and extract with a Catmandu Fix only
# those fields that we need for BagIt creation
catmandu convert OAI --url ${OAI_BASE_URL} --set ${SET_SPEC} | \
    grep -v deleted | \
    head -${MAX_NUM_RECORDS} | \
    catmandu convert JSON --fix ${FIX_FILE} to BagIt --overwrite 1  

# Hints
#  - on line 19: change 'to Bagit --overwrite 1' into 'to JSON'
#  - this will be the JSON you need to create to generate bag files
#  - if you can create JSON this way than you could you a UNIX pipe to
#  generate BagIts like:
#       
#     $ myprogram | catmandu JSON to BagIt --overwrite 1
