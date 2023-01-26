#!/bin/bash

source ./.temp
echo 'source .temp'

# see if global variable is set
# global variable SeismicUnixGui locates main folder

 if [ -z "${SeismicUnixGui}" ]; then

 	echo "global variable L_SU must first be set"
 	echo "e.g. in .bashrc: "
 	echo " export SeismicUnixGui_script=/Location/of/script/folder "

 else
	echo "SeismicUnixGui =" ${SeismicUnixGui}
 fi
