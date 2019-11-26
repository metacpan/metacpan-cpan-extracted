@echo off

set VALUE=5

IF %VALUE% leq 5

goto label

cp file2 file3

:label

cp file1 file2
