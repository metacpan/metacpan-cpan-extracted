@echo off

set VALUE=123456

IF %VALUE:~-2% == 56

goto label

cp file2 file3

:label

cp file1 file2

IF %VALUE:~-4,2% == 34 goto label2

goto fin

:label2

cp file4 file7

:fin

