@echo off

echo test

IF EXIST t\21-if_exists_*.cmd cp 21-if_exists_glob_without_variable_substitution.cmd 21-if_exists_glob_without_variable_substitution.cmd.bkp

IF NOT EXIST another_file* 

touch another_file
