@echo off
for /f "delims=	: tokens=2 usebackq" %%a in (`findstr /v "***REMOVE_THIS_TIMESTAMP***" %*`) do echo %%a
