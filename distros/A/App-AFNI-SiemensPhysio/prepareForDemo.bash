#!/usr/bin/env bash
cd $(dirname $0)
# to save space, github repo only inclues first and last dicom
# but siemphysdat checks time, count, and TR, so we need to match the count
# we can do this by linking the first file a bunch of times
MRcnt=$(ls data/MR/*|wc -l)
if [ $MRcnt -lt 200 ]; then 
   for i in $(seq 1 198); do
     ln -s $(pwd)/data/MR/MR.1.3.12.2.1107.5.2.32.35217.2011110816454395397392106 data/MR/MR.fake.$i;
   done
fi

# make an output directory to save files to
# (git wont track empty folders)
[ ! -d data/phys ] && mkdir data/phys/

# exvolt (extract voltage) is a c++ program that should do about the same thing
#    it is shifted by 340 msecs (17 samples)?
[ ! -r exvolt ] && wget https://cfn.upenn.edu/aguirre/public/exvolt/exvolt
# ./exvolt  ../App-AFNI-SiemensPhysio/data/MR ../App-AFNI-SiemensPhysio/data/wpc4951_10824_20111108_110811.resp test.dat


echo "
TRY:

  perl -Ilib lib/bin/siemphysdat -o data/phys/ data/wpc4951_10824_20111108_110811.* data/MR/

Then look in data/phys/
"
