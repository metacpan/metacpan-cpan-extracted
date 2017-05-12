#!/bin/bash

for i in `ls script/update_template` ; do 
	/usr/bin/perl script/update_template/$i
done
