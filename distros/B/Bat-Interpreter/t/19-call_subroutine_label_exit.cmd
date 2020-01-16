@echo off

CALL :copy
rm file2
GOTO :eof

:copy
cp file1 file2
EXIT  /B
