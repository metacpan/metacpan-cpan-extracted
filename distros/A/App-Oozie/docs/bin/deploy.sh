#!/bin/bash

# This won't run as-is, but it is here to give you an idea.

export TEST_BIN=$(perl -wE 'use FindBin qw($Bin); say $Bin;')
export TEST_LIB=$TEST_BIN"/lib"

echo "TEST_LIB:"$TEST_LIB;
echo "TEST_BIN:"$TEST_BIN;

perl -I$TEST_LIB \
-MCarp::Always \
-MData::Dumper \
-MApp::Oozie::Deploy -wE 'warn Dumper \@ARGV; App::Oozie::Deploy->new_with_options->run( \@ARGV )' -- \
--local_oozie_code_path $TEST_BIN"/eg"                  \
--webhdfs_hostname hadoop-httpfs.example.com            \
--oozie_uri http://hadoop-oozie.example.com:11000/oozie \
--verbose                                               \
--oozie_client_jar /local/path/oozie-client.jar         \
--git_repo_path ~/gitrepo/where/workflows/are           \
--oozie_cli ~/bin/oozie                                 \
"$@"                                                    \
cpan-sample-workflow                                    \

echo "FIN."
