@echo off

set VALUE=6
set GOTOLABEL=NO

for %%m in (1,3,6) do if %%m GEQ %VALUE% set GOTOLABEL=YES

If %GOTOLABEL% EQU YES goto label

cp file2 file3

:label

cp file1 file2
