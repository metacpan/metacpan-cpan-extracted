#!/bin/bash

# Copyright 2009 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.


script=../lib/App/Chart/chart.bash
echo "load $script"
. $script

count=0
fail=0

#-----------------------------------------------------------------------------

name="complete --aler"
_chart_completions chart --aler
len=${#COMPREPLY[*]}
if [ $len != 1 -o "${COMPREPLY[0]}" != --alerts ]; then
  let fail++
  echo "fail: $name"
  echo "  got len $len first '${COMPREPLY[0]}'"
fi
let count++

#-----------------------------------------------------------------------------

name="complete nosuchsymbolatall"
_chart_completions chart nosuchsymbolatall
len=${#COMPREPLY[*]}
if [ "$COMPREPLY" != '' ]; then
  let fail++
  echo "fail: $name"
  echo "  got whole '$COMPLREPLY'"
fi
let count++

#-----------------------------------------------------------------------------

name="complete with ' char"
_chart_completions chart "foo'bar"
if [ "$COMPREPLY" != '' ]; then
  let fail++
  echo "fail: $name"
  echo "  got whole '$COMPLREPLY'"
fi
let count++

#-----------------------------------------------------------------------------

echo "$count tests, $fail fail" 
if [ $fail = 0 ]; then
  exit 0
else
  exit 1
fi
