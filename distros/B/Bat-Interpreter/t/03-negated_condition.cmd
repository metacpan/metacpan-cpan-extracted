@echo off

SET VALUE = 4

IF NOT VALUE == 3

goto label

cp file2 file3

:label

cp file1 file2



