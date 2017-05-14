#!/bin/sh

#hostname=`hostname`
hostname=127.0.0.1
dbfile=/tmp/ird
boa_dbfile=/tmp/micod

if [ -f "$HOME/.micorc" ]; then
  echo "We are going to override $HOME/.micorc file"
  echo "Should we continue? (press <ENTER> or <CTRL-C>)"
  read
fi

rm -f $HOME/.micorc
#echo "-ORBDebugLevel 10" > $HOME/.micorc

killall ird # micod

echo "Giving ird/micod a little time to die..."
sleep 1;

rm -f $dbfile.idl
rm -f $boa_dbfile

if [ -n "$MICORC" ];then
  echo "Please, unset MICORC environment var to start tests"
  unset MICORC
fi

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

savIFS=$IFS
IFS=":"
for p in $PATH; do
  if [ -x $p/mico-c++ ]; then
    MICOPREFIX=`dirname $p`
    break;
  fi
done
IFS=$savIFS

IDLS="Tictactoe.idl Account.idl $MICOPREFIX/include/mico/ir_base.idl $MICOPREFIX/include/mico/ir.idl"

for i in $IDLS ; do
   idl --no-codegen-c++ --feed-ir -I .  -I$MICOPREFIX/include $i 
done

#imr create Banking shared "perl -Mblib `pwd`/server" IDL:Account/Account:1.0
