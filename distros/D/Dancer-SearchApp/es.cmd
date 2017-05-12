@echo off

setlocal

cd /d %~dp0

perl -wle "$ENV{JAVA_HOME} ||= do { glob(shift) }; print $ENV{JAVA_HOME}; system(1,'start ' . glob(shift))" "C:\Progra~1\Java\jre1.8*" elasticsearch-5.*\bin\elasticsearch.bat
