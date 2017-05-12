#!/bin/sh

#hostname=`hostname`
hostname=127.0.0.1
dbfile=/tmp/ird
boa_dbfile=/tmp/micod

rm -f $HOME/.micorc
#echo "-ORBDebugLevel 10" > $HOME/.micorc

killall ird # micod

echo "Giving ird/micod a little time to die..."
sleep 1;

IDLS="Tictactoe.idl Account.idl mico/ir_base.idl mico/ir.idl"

rm -f $dbfile.idl
rm -f $boa_dbfile

ird -ORBIIOPAddr inet:$hostname:8888 --db $dbfile &

echo "Giving ird a little time to start..."
sleep 5;

echo "-ORBIfaceRepoAddr inet:$hostname:8888" >> $HOME/.micorc

#micod -ORBIIOPAddr inet:$hostname:9999 --db $boa_dbfile &

#echo "Giving micod a little time to start..."
#sleep 1;


#echo "-ORBImplRepoAddr inet:$hostname:9999" >> $HOME/.micorc
#echo "-ORBBindAddr inet:$hostname:9999" >> $HOME/.micorc
#echo "-ORBDebugLevel 5" >> $HOME/.micorc

for i in $IDLS ; do
   idl --no-codegen-c++ --feed-ir -I . $i 
done

#imr create Banking shared "perl -Mblib `pwd`/server" IDL:Account/Account:1.0
