@echo off

echo test

IF EXIST t\14-if_exists_without_variable_substitution.cmd cp 14-if_exists_without_variable_substitution.cmd 14-if_exists_without_variable_substitution.cmd.bkp

IF NOT EXIST another_file 

touch another_file
