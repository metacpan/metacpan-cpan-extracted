@echo off

cp file1 file2

goto label

echo Never get executed

:label: all this text will be ignored

::Comment with : especial characters and keywords: if, goto, set...
REM Alternative form of comment

:label2: more stuff nobody is going to read



