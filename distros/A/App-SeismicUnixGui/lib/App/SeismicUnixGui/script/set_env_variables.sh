#!/bin/bash

source ./.temp
echo 'source .temp'

# see if global variable is set
# global variable SeismicUnixGuilocates main folder

 if [ -z "${SeismicUnixGui}" ]; then

 	echo "global variable SeismicUnixGui must first be set"
 	echo "e.g. in .bashrc: "
 	echo " export SeismicUnixGui=/Location/of/folder "

 else
	echo "SeismicUnixGui =" ${SeismicUnixGui}
 fi
