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
--git_repo_path         $TEST_BIN"/eg"                              \
--local_oozie_code_path $TEST_BIN"/eg"                              \
--oozie_cli             /usr/bin/oozie                              \
--oozie_client_jar      /usr/lib/oozie/lib/oozie-client-5.2.1.jar   \
--oozie_uri             http://hadoop-oozie.example.com:11000/oozie \
--webhdfs_hostname      hadoop-httpfs.example.com                   \
--webhdfs_port          9870                                        \
--verbose                                                           \
"$@"                                                                \
cpan-sample-workflow                                                \

echo "FIN."
