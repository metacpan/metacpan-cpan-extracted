# fftrim - concatenate, trim and compress video files 

## Description

fftrim processes raw videos from a camcorder by
concatenating, trimming and compressing them
according to arguments you supply on the 
command line, or in a CONTROL file. 

## Synopsis
  
### Processing a single file

    fftrim --in 000001.MTS --out output.mp4 --start 15.5 --end 44:13

### Handling concatenated sources

    fftrim --in "000001.MTS 00002.MTS" --out output.mp4 --start 45:13 -- 2-1:12

The expression 2-1:12 means a position in the concatenated
file that includes the full length of the first clip and
1:12 minutes of the second clip. Similarly, 3-65 and 3-1:05
both mean a position of 1:05 into the third clip.

The source files are concatenated into an intermediate file 
using the name of the first source file appended with .mp4.

### Batch mode

    fftrim --source-dir raw --target-dir final

### CONTROL file format

The CONTROL file is used for batch processing
and appears in the same directory as the source
video files. It contains multiple lines
of the following format:


    # source file(s)    output file   start  end
    # ---------------   -----------   -----  ----
    000001.MTS        : part1.mp4   : 15.5 : 44:13 

Arguments are separated by a colon character
flanked by whitespace. Commented lines are ignored.

The following line creates part2.mp4 from source files
000001.MTS and 000002.MTS:

    000001.MTS 000002.MTS : part2.mp4 :  44:13 : 2-24:55 

The extracted video starts 44:13 into the first source file.
and ends at 24:55 into the second file.

### Help 

fftrim [-mnr] [long options...]
	--in STR          input file(s)
	--out STR         output file
	--start STR       start time
	--end STR         end time
	--profile STR     merge ffmpeg options from named file in
	                  $HOME/.fftrim
	--source-dir STR  batch mode, source directory
	--target-dir STR  batch mode, destination directory
	-r --frame-rate   specify framerate (with no arg: fallback to source
	                  file frame rate)
	-n                simulate: print commands but do not run them
	-m                simulate: print commands omitting file checks
	--old-concat      use old, broken naming style for concat target
	--help            print usage message and exit

Note that --in, --out, --start and --end options are not available with batch mode

### Bugs

Please report any bugs you encounter.

