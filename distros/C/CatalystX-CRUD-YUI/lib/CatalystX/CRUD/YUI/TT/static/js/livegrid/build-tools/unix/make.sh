#!/bin/bash


echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
echo "               Ext.ux.Livegrid Build Tool            "
echo " (c) 2008 Thorsten Suckow-Homberg ts@siteartwork.de  "
echo "-----------------------------------------------------"
echo " Using yuicompressor:                                "
echo " http://developer.yahoo.com/yui/compressor/          "
echo "-----------------------------------------------------"

if [ "$#" -eq 1 ] then
	echo "Usage: $0 [path to yuicompressor.jar]"
	echo "Example: $0 /temp/yuicompressor-2.4.jar"
	echo "Download yuicompressor at http://developer.yahoo.com/yui/compressor/"
else
	TP="../../"
	yuicompressor_path=$1
	livegrid_file_list_core="${TP}src/GridPanel.js+${TP}src/GridView.js+${TP}src/JsonReader.js+${TP}src/RowSelectionModel.js+${TP}src/Store.js"
	livegrid_file_list_all="${livegrid_file_list_core}+${TP}src/Toolbar.js+{TP}src/DragZone.js+${TP}src/EditorGridPanel.js"

	echo "...building CSS file..."
	java -jar ${yuicompressor_path} -o ${TP}build/resources/css/ext-ux-livegrid.css --charset UTF-8 ${TP}src/resources/css/ext-ux-livegrid.css
	echo "Done"

	echo "...merging files for livegrid-core.js..."
	cp ${livegrid_file_list_core} ${tp}build/_tmp.js

	echo ...building livegrid-core.js file...
	java -jar ${yuicompressor_path} -o ${TP}build/ext-ux-livegrid-core.js --charset UTF-8 ${TP}build/_tmp.js
	echo "Done!"

	echo "...merging files for livegrid-all.js..."
	cp ${livegrid_file_list_all} ${TP}build/_tmp.js
	echo "Done"

	echo "...building livegrid-all.js file..."
	java -jar ${yuicompressor_path} -o ${TP}build/livegrid-all.js --charset UTF-8 ${TP}build/_tmp.js
	echo "Done"

	echo "...merging files for livegrid-all-debug.js..."
	cp ${livegrid_file_list_all} ${TP}build/livegrid-all-debug.js
	echo "Done"

	echo "...building livegrid-debug-all.js file..."
	java -jar ${yuicompressor_path} -o ${TP}build/livegrid-debug-all.js --nomunge --disable-optimizations --charset UTF-8 ${TP}build/_tmp.js
	echo "Done"

	echo "...removing temp file..."
	rm -f ${TP}build\_tmp.js

	echo "FINISHED!"
fi