@echo off
echo:#####################################################################
echo:
echo: GhostWork - Barcode Logger
echo:
echo:#####################################################################
echo:
echo:** USAGE **
echo:   Press [Q] to Quit this software
echo:   Press [R] to Retry last operation
echo:

setlocal
set Q_WHO=Your name?
set Q_TOWHICH=Which work you do?
set Q_WHAT=What number?
set Q_WHY=....Why?
set INFO_LOGFILE_IS=Logfile is: 
set INFO_DOUBLE_SCANNED=ERROR: Double Scanned.
set INFO_ANY_KEY_TO_EXIT=Press any key to exit.

call GhostWork.bat %*
endlocal
