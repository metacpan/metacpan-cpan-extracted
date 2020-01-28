@echo off

goto :copy
rm file2
GOTO :eof

:copy
cp file1 file2
GOTO :eof
rm file1
