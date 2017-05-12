#!/bin/bash

YEAR=`grep Year $1 | cut -f2`
NOW=`date +%Y`
echo $(($NOW-$YEAR))
