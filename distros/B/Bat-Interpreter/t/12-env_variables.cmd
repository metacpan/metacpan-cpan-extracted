@echo off

set FIRST=some_name
set SECOND=B

execute_madeup_command.pl --name %FIRST% --date_format %%Y%%m%%d%%H%%M  --some_parameter="A%SECOND%C(%%)" --substring %FIRST:~5,9% --another_date_format "%%d/%%m/%%Y %%H:%%M"
