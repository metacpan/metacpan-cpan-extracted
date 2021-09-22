@echo off
for /f "delims=	: tokens=2 usebackq" %%a in (`type %*`) do echo %%a
