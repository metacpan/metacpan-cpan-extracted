@echo off

set VALUE=123456

IF %VALUE:~-2% == 56

goto label

cp file2 file3

:label

cp file1 file2



