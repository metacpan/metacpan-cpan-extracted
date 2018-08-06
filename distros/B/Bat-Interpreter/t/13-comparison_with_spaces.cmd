@echo off

set FOO=    bar    
If %FOO%==bar goto label

rm file1

:label

cp file1 file2

