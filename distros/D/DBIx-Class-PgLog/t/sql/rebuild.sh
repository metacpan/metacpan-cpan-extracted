#!/bin/sh

#
# rebuild.sh
#
# Developed by Sheeju Alex
# Licensed under terms of GNU General Public License.
# All rights reserved.
#
# Changelog:
# 2014-08-18 - created
#

export PGPASSWORD=sheeju

dropdb pg_log_test
createdb pg_log_test

psql -h localhost pg_log_test sheeju -f pg_log_test.sql

# $Platon$

