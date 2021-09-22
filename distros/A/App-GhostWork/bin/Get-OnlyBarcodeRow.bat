@echo off
for /f "usebackq delims=" %%a in (`findstr /v "***REMOVE_THIS_TIMESTAMP***" %*`) do echo %%a
