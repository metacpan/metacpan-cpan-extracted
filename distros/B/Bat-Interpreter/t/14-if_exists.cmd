@echo off

echo test

IF EXIST t\14-if_exists.cmd cp 14-if_exists.cmd 14-if_exists.cmd.bkp

IF NOT EXIST another_file 

touch another_file
