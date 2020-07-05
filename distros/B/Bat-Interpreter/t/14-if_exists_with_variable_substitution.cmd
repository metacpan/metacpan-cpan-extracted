@echo off

echo test

SET FILE=t\14-if_exists_with_variable_substitution.cmd

IF EXIST %FILE% cp 14-if_exists_with_variable_substitution.cmd 14-if_exists_with_variable_substitution.cmd.bkp

IF NOT EXIST another_file 

touch another_file
