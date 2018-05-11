@echo off

set VALUE=6

IF %VALUE% NEQ 5

goto label

cp file2 file3

:label

cp file1 file2



