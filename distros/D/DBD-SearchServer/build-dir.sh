#!/bin/ksh
# build-dir.sh $Revision: 1.1 $
# This is not strictly related to DBD::SearchServer.
# It creates an usable directory for SearchServer tables, by copying needed files
# from Fulcrum home.
# 
# build-dir $FULCRUM_HOME destionation-directory (must already exist)

cp $1/fultext/fultext.eft $2
cp $1/fultext/fultext.ftc $2
if [ -f $1/fultext/ftpdf.ini ];
then
	cp $1/fultext/ftpdf.ini $2
fi
cp $1/fultext/*mess $2

FULCREATE=$2
FULSEARCH=$2
FULTEMP=$2

export FULCREATE FULSEARCH FULTEMP

$1/bin/execsql -0test.fte -1build-dir.log -2build-dir.log



