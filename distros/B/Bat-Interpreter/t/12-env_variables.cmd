@echo off

set FIRST=some_name
set SECOND=B
set A$(BA)@@=33333
set Z=some_value

execute_madeup_command.pl --name %FIRST% --date_format %%Y%%m%%d%%H%%M  --some_parameter="A%SECOND%C(%%)" --substring %FIRST:~5,9% --another_date_format "%%d/%%m/%%Y %%H:%%M" --identifier %A$(BA)@@:~0,1%%SECOND% --environment_variable_with_one_letter %Z%
