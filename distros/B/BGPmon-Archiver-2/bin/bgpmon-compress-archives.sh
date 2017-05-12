#!/bin/bash
$VERSION = 1.04;

# *
# *
# *      Copyright (c) 2012 Colorado State University
# *
# *      Permission is hereby granted, free of charge, to any person
# *      obtaining a copy of this software and associated documentation
# *      files (the "Software"), to deal in the Software without
# *      restriction, including without limitation the rights to use,
# *      copy, modify, merge, publish, distribute, sublicense, and/or
# *      sell copies of the Software, and to permit persons to whom
# *      the Software is furnished to do so, subject to the following
# *      conditions:
# *
# *      The above copyright notice and this permission notice shall be
# *      included in all copies or substantial portions of the Software.
# *
# *      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# *      EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# *      OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# *      NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# *      HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# *      WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# *      FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# *      OTHER DEALINGS IN THE SOFTWARE.
# *
# *
# *  File: bgpmon_compress_archives.sh
# *  Authors: Kaustubh Gadkari
# *  Date: Aug 17, 2012
# *

#---- Function definitions. ----
# Given a path, compress all files in that path.
compress_files () {
	# Path of files to be compressed.
	local date_path=$1
	local collector_path=$2
	local year_month=$3
	local file_type=$4

	# Store current path, so that we can restore pwd before returning.
	local working_dir=$(pwd)

	# Change to current path.
	cd $date_path

	# Compress all files in path.
	local files=$(ls)
	for file in $files ; do
		# Check if the file has previously been compressed
		file_ext=${file##*.}
		file_name=${file%.*}

		if [ $file_ext != "bz2" ] ; then
			$ZIP $file
		fi

		# Fix the symlink to point to the compressed file.
		collector=$(echo $file_name | cut -d'.' -f4-)
		symlink_path="$collector_path/$collector/$year_month/$file_type"
		new_file_name="$file.bz2"

		# Create new symlink
		ln -s $new_file_name "$symlink_path/$new_file_name"

		# Delete symlink to previous file
		rm "$symlink_path/$file"
	done

	# Reset path to current working directory.
	cd $working_dir
}

#---- Begin main. ----
# Check what system we are running on.
# Currently, support only linux.
sys=$(uname)
if [ "$sys" != "Linux" ] ; then
	echo "This script runs correctly on Linux system. You seem be running a $sys system."
	exit 1
fi

# Try and find bzip2 in path
ZIP=$(which bzip2)
if [ -z "$ZIP" ] ; then
	echo 'Could not find bzip2 in path.'
	exit 1
fi

# Path to location of top directory of archives. Can be given as a command line argument.
# If not specified as a command line argument, use default
if [ -z "$1" ] ; then
	path_to_archive='/raid2/bgpmon_archive'
else
	path_to_archive=$1
fi

# Check if the path specified exists.
if [ ! -d "$path_to_archive" ] ; then
	echo "Invalid path to archives $path_to_archive"
	exit 1
fi

# Set paths for date and collector archives.
date_path="$path_to_archive/date"
collector_path="$path_to_archive/collector"

# Get dates for last 3 months in YYYY.mm format
compress[0]=$(date -d "last month" '+%Y.%m')
compress[1]=$(date -d "2 months ago" '+%Y.%m')
compress[2]=$(date -d "3 months ago" '+%Y.%m')

# Now, loop through the directories and compress all files.
for i in "${compress[@]}" ; do
	for day in {1..31} ; do
		compress_path="$date_path/$i/$day"

		# Compress UPDATES and fix symlinks in collector directory
		if [ -d "$compress_path/UPDATES" ] ; then
			compress_files "$compress_path/UPDATES" $collector_path $i "UPDATES"
		fi

		# Compress RIBS and fix symlinks in collector directory
		if [ -d "$compress_path/RIBS" ] ; then
			compress_files "$compress_path/RIBS" $collector_path "RIBS"
		fi

	done
done

exit 0
