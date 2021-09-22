@echo off
echo:#####################################################################
echo:
echo: GhostWork - Barcode Logger
echo:
echo:#####################################################################
echo:
echo:** HELP **
echo:   Press [Q] to Save data and Quit
echo:   Press [R] to Retry last operation
echo:
echo:   Do Not Click [X] of the Window. Or you will lost your data.
echo:

set Q_WHO=Your name?
set Q_TOWHICH=Which work you do?
set INFO_LOGFILE_IS=Logfile is: 
set Q_WHAT=What number?
set Q_WHY=....Why?
set INFO_ANY_KEY_TO_EXIT=Press any key to exit.

GhostWork.bat %*

