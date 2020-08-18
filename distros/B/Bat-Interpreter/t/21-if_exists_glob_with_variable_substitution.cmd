@echo off

echo test

SET FILES=t\21-if_exists_glob_with_*.cmd

IF EXIST %FILES% cp 21-if_exists_glob_with_variable_substitution.cmd 21-if_exists_glob_with_variable_substitution.cmd.bkp

IF NOT EXIST *another_file 

touch another_file
