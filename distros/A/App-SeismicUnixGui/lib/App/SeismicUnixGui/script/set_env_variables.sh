#!/bin/bash

local_dir=`pwd`
# echo "local directory=$local_dir"
source $local_dir/.temp
echo "source $local_dir/.temp"
# see if global variable is set
# global variable SeismicUnixGuilocates main folder

 if [ -z "${SeismicUnixGui}" ]; then

 	echo "global variable SeismicUnixGui must first be set"
 	echo "e.g. in .bashrc: "
 	echo " export SeismicUnixGui=/Location/of/folder "

 else
	echo "SeismicUnixGui =" ${SeismicUnixGui}
 fi
