@echo off

set VALUE=2

IF %VALUE% LSS 5

goto label

cp file2 file3

:label

cp file1 file2
