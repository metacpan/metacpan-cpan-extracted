@echo off
echo -----------------------------------------------------
echo -----------------------------------------------------
echo                Ext.ux.Livegrid Build Tool
echo  (c) 2008 Thorsten Suckow-Homberg ts@siteartwork.de
echo -----------------------------------------------------
echo  Using yuicompressor:
echo  http://developer.yahoo.com/yui/compressor/
echo -----------------------------------------------------
echo.

if "%1"=="" goto help

set yuicompressor_path=%1

if not exist %yuicompressor_path% goto error_message

:process
set tp=..\..\
set livegrid_file_list_core=%tp%src\GridPanel.js+%tp%src\GridView.js+%tp%src\JsonReader.js+%tp%src\RowSelectionModel.js+%tp%src\Store.js
set livegrid_file_list_all=%livegrid_file_list_core%+%tp%src\Toolbar.js+%tp%src\DragZone.js+%tp%src\EditorGridPanel.js

echo ...building CSS file...
java -jar %yuicompressor_path% -o %tp%build\resources\css\ext-ux-livegrid.css --charset UTF-8 %tp%src\resources\css\ext-ux-livegrid.css
echo Done

echo ...merging files for livegrid-core.js...
copy /B /Y %livegrid_file_list_core% %tp%build\_tmp.js
echo ...building livegrid-core.js file...
java -jar %yuicompressor_path% -o %tp%build\livegrid-core.js --charset UTF-8 %tp%build\_tmp.js
echo Done!

echo ...merging files for livegrid-all.js...
copy /B /Y %livegrid_file_list_all% %tp%build\_tmp.js
echo ...building livegrid-all.js file...
java -jar %yuicompressor_path% -o %tp%build\livegrid-all.js --charset UTF-8 %tp%build\_tmp.js
echo Done

echo ...merging files for livegrid-all-debug.js...
copy /B /Y %livegrid_file_list_all% %tp%build\livegrid-all-debug.js
rem echo ...building livegrid-all-debug.js file...
rem java -jar %yuicompressor_path% -o %tp%build\livegrid-all-debug.js --nomunge --disable-optimizations --charset UTF-8 %tp%build\_tmp.js
echo Done

echo ...removing temp file...
del %tp%build\_tmp.js

echo FINISHED!
goto end

:help
echo Usage: make.bat [path to yuicompressor.jar]
echo Example: make.bat C:/Tools/yuicompressor-2.4.jar
echo Download yuicompressor at http://developer.yahoo.com/yui/compressor/
echo.
goto end

:error_message
echo.
echo Error: %yuicompressor_path% does not seem to point to the yuicompressor jar
echo.

:end