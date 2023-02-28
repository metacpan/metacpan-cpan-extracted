#!/bin/bash

# see if global variable is set
# global variable SeismicUnixGui locates main folder

 if [ -z "${SeismicUnixGui}" ]; then

 	echo "global variable SeismicUnixGui must first be set"
 	echo "e.g. in .bashrc: "
 	echo " export SeismicUnixGui_script=/Location/of/script/folder"

 else
	echo "SeismicUnixGui =" ${SeismicUnixGui}
fi
