#!/bin/bash

source /root/.bash_profile

cd /etc/yadw
FILES=*

for f in $FILES
do
	yadw inc -c $f 1>/dev/null && \
	yadw expire -c $f 1>/dev/null
done
