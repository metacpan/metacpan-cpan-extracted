#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Write data in tabular text format
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2016-2017
#-------------------------------------------------------------------------------
# podDocumentation

package Data::Table::Text;
use v5.8.0;
our $VERSION = '20171128';
use warnings FATAL => qw(all);
use strict;
use Carp;
use Cwd;
use File::Path qw(make_path);
use File::Glob qw(:bsd_glob);
use File::Temp qw(tempfile tempdir);
use POSIX qw(strftime);                                                         # http://www.cplusplus.com/reference/ctime/strftime/
use Data::Dump qw(dump);
use JSON;
use MIME::Base64;
use String::Numeric qw(is_float);
use utf8;

#1 Time stamps                                                                  # Date and timestamps as used in logs of long running commands

sub dateTimeStamp                                                               # Year-monthNumber-day at hours:minute:seconds
 {strftime('%Y-%m-%d at %H:%M:%S', localtime)
 }

sub dateStamp                                                                   # Year-monthName-day
 {strftime('%Y-%b-%d', localtime)
 }

sub timeStamp                                                                   # hours:minute:seconds
 {strftime('%H:%M:%S', localtime)
 }

#1 Command execution                                                            # Various ways of processing commands

sub xxx(@)                                                                      # Execute a command checking and logging the results: the command to execute is specified as one or more strings with optionally the last string being a regular expression that is used to confirm that the command executed successfully and thus that it is safe to suppress the command output as uninteresting.
 {my (@cmd) = @_;                                                               # Command to execute followed by an optional regular expression to test the results
  @cmd or confess "No command\n";                                               # Check that there is a command to execute
  $_ or confess "Missing command component\n" for @cmd;                         # Check that there are no undefined command components
  my $success = $cmd[-1];                                                       # Error check if present
  my $check = ref($success) =~ /RegExp/i;                                       # Check for error check
  pop @cmd if $check;                                                           # Remove check from command
  my $c = join ' ', @cmd;                                                       # Command to execute
  say STDERR timeStamp, " ", $c unless $check;                                  # Print the command unless there is a check in place
  my $r = qx($c 2>&1);                                                          # Execute command
  $r =~ s/\s+\Z//s;                                                             # Remove trailing white space from response
  say STDERR $r if $r and !$check;                                              # Print non blank error message
  confess $r if $r and $check and $r !~ m/$success/;                            # Error check if an error checking regular expression has been supplied
  $r
 }

sub XXX($)                                                                      # Execute a block of shell commands line by line after removing comments
 {my ($cmd) = @_;                                                               # Commands to execute separated by new lines
  for(split /\n/, $cmd)                                                         # Split commands on new lines
   {s(#.*\Z)()gs;                                                               # Remove comments
    next if !$_ or m(\A\s*\Z);                                                  # Skip blank lines
    say   STDERR $_;                                                            # Say command
    print STDERR for qx($_);                                                    # Execute command
    say STDERR '';
   }
 }

sub zzz($;$)                                                                    # Execute lines of commands as one long command string separated by added &&'s and then check that the pipeline results in a return code of zero and that the execution results match the optional regular expression if one has been supplied; confess() to an error if either check fails.
 {my ($cmd, $success) = @_;                                                     # Commands to execute - one per line with no trailing &&, optional regular expression to check the results
  $cmd or confess "No command\n";                                               # Check that there is a command to execute
  my @c;                                                                        # Commands
  for(split /\n/, $cmd)                                                         # Split commands on new lines
   {s(#.*\Z)()gs;                                                               # Remove comments
    next if !$_ or m(\A\s*\Z);                                                  # Skip blank lines
    push @c, $_;                                                                # Save command
   }
  my $c = join ' && ', @c;                                                      # Command string to execute
  my $r = qx($c 2>&1);                                                          # Execute command
  my $R = $?;
  $r =~ s/\s+\Z//s;                                                             # Remove trailing white space from response
  confess "$cmd\n\n$c\n$r\n" if $R or $success && $r !~ m/$success/s;                 # Error check with return code and an error checking regular expression if one has been supplied
  $r
 }

sub parseCommandLineArguments(&@)                                               # Classify the specified array of words into positional parameters and keyword parameters, then call the specified sub with a reference to an array of positional parameters followed by a reference to a hash of keywords and their values and return the value returned by the sub
 {my ($sub, @args) = @_;                                                        # Sub to call, list of arguments to parse
  my %h;
  my @a;
  for(@args)
   {if (m/\A-+(\S+?)(=(.+))?\Z/)
     {$h{$1} = $3;
     }
    else
     {push @a, $_;
     }
   }
  $sub->([@a], {%h})
 }

#1 Files and paths                                                              # Operations on files and paths
#2 Statistics                                                                   # Information about each file

sub fileSize($)                                                                 # Get the size of a file.
 {my ($file) = @_;                                                              # File name
  (stat($file))[7]
 }

sub fileModTime($)                                                              # Get the modified time of a file in seconds since the epoch.
 {my ($file) = @_;                                                              # File name
  (stat($file))[9] // 0
 }

sub fileOutOfDate(&$@)                                                          # Calls the specified sub once for each source file that is missing, then calls the sub for the target if there were any missing files or if the target is older than any of the non missing source files or if the target does not exist. The file name is passed to the sub each time in $_. Returns the files to be remade in the order they should be made. Example:fileOutOfDate {make($_)}  $target, $source1, $source2, $source3;
 {my ($make, $target, @source) = @_;                                            # Make with this sub, target file, source files
  my $e = -e $target;                                                           # Existence of target
  my @m = grep {!-e $_} @source;                                                # Missing files that do not exist will need to be remade
  push @m, $target unless $e and !@m;                                           # Add the target if there were missing files
  if (!@m)                                                                      # If there were no missing files that forced a remake, then check for a source file younger than the target that would force a remake of the target
   {my $t = fileModTime($target);                                               # Time of target
    if (grep {-e $$_[0] and $$_[0] ne $target and $$_[1] > $t}                  # Target will ahve to be remade if there are younger source files
        map {[$_, fileModTime($_)]}
        @source)
     {@m = $target;
     }
   }
  my %m;                                                                        # Files that have been remade
  my @o;                                                                        # Files that have been remade in make order
  for(@m)
   {&$make, push @o, $_ unless $m{$_}++;                                        # Make each missing file once and then the target file
   }
  @o                                                                            # Return a list of the files that were remade
 }

#2 Components                                                                   # Create file names from file name components

sub denormalizeFolderName($)                                                    #P Remove any trailing folder separator from a folder name component.
 {my ($name) = @_;                                                              # Name
  $name =~ s([\/\\]+\Z) ()gsr;
 }

sub renormalizeFolderName($)                                                    #P Normalize a folder name component by adding a trailing separator.
 {my ($name) = @_;                                                              # Name
  ($name =~ s([\/\\]+\Z) ()gsr).'/';                                            # Put a trailing / on the folder name
 }

sub filePath(@)                                                                 # Create a file path from an array of file name components. If all the components are blank then a blank file name is returned.
 {my (@file) = @_;                                                              # File components
  defined($_) or confess "Missing file component\n" for @file;                  # Check that there are no undefined file components
  my @c = grep {$_} map {denormalizeFolderName($_)} @file;                      # Skip blank components
  return '' unless @c;                                                          # No components resolves to '' rather than '/'
  join '/', @c;                                                                 # Join separate components
 }

sub filePathDir(@)                                                              # Directory from an array of file name components. If all the components are blank then a blank file name is returned.
 {my (@file) = @_;                                                              # File components
  my $f = filePath(@_);
  return '' unless $f;                                                          # No components resolves to '' rather than '/'
  renormalizeFolderName($f)                                                     # Normalize with trailing separator
 }

sub filePathExt(@)                                                              # File name from file name components and extension.
 {my (@File) = @_;                                                              # File components and extension
  my @file = grep{defined and /\S/} @_;                                         # Remove undefined and blank components
  @file > 1 or confess "At least two non blank file name components required\n";
  my $x = pop @file;
  my $n = pop @file;
  my $f = "$n.$x";
  return $f unless @file;
  filePath(@file, $f)
 }

BEGIN                                                                           # Some undocumented shorter names for these useful routines
 {*fpd = *filePathDir;
  *fpe = *filePathExt;
  *fpf = *filePath;
 }

sub checkFile($)                                                                # Return the name of the specified file if it exists, else confess the maximum extent of the path that does exist.
 {my ($file) = @_;                                                              # File to check
  unless(-e $file)
   {confess "Can only find the prefix (below) of the file (further below):\n".
      matchPath($file)."\n$file\n";
   }
  $file
 }

sub checkFilePath(@)                                                            # L<Check|/checkFile> a folder name constructed from its L<components|/filePath>
 {my (@file) = @_;                                                              # File components
  checkFile(filePath(@_))                                                       # Return the constructed file name if it exists
 }

sub checkFilePathExt(@)                                                         # L<Check|/checkFile> a file name constructed from its  L<components|/filePathExt>
 {my (@File) = @_;                                                              # File components and extension
  checkFile(filePathExt(@_))                                                    # Return the constructed file name if it exists
 }

sub checkFilePathDir(@)                                                         # L<Check|/checkFile> a folder name constructed from its L<components|/filePathDir>
 {my (@file) = @_;                                                              # File components
  checkFile(filePathDir(@_))                                                    # Return the constructed folder name if it exists
 }

sub quoteFile($)                                                                # Quote a file name.
 {my ($file) = @_;                                                              # File name
  "\"$file\""
 }

sub removeFilePrefix($@)                                                        # Removes a file prefix from an array of files.
 {my ($prefix, @files) = @_;                                                    # File prefix, array of file names
  map {s(\A$prefix) ()r} @files
 }

#2 Position                                                                     # Position in the file system

sub currentDirectory                                                            # Get the current working directory.
 {renormalizeFolderName(getcwd)
 }

sub currentDirectoryAbove                                                       # The path to the folder above the current working folder.
 {my $p = currentDirectory;
  my @p = split m(/)s, $p;
  shift @p if @p and $p[0] =~ m/\A\s*\Z/;
  @p or confess "No directory above\n:".currentDirectory, "\n";
  pop @p;
  my $r = shift @p;
  filePathDir("/$r", @p);
 }

sub parseFileName($)                                                            # Parse a file name into (path, name, extension)
 {my ($file) = @_;                                                              # File name to parse
  if ($file =~ m/\.[^\/]+\Z/s)                                                  # The file name has an extension
   {if ($file =~ m/\A.+[\/]/s)                                                  # The file name has a preceding path
     {my @f = $file =~ m/(\A.+[\/])([^\/]+)\.([^\/]+)\Z/s;                      # File components
      return @f;
     }
    else                                                                        # There is no preceding path
     {my @f = $file =~ m/(\A.+)\.([^\/]+)\Z/s;                                  # File components
      return (undef, @f)
     }
   }
  else                                                                          # The file name has no extension
   {if ($file =~ m/\A.+[\/]/s)                                                  # The file name has a preceding path
     {my @f = $file =~ m/(\A.+\/)([^\/]+)\Z/s;                                  # File components
      return @f;
     }
    else                                                                        # There is no preceding path
     {return (undef, $file)
     }
   }
 }

sub containingFolder($)                                                         # Path to the folder that contains this file, or use L</parseFileName>
 {my ($file) = @_;                                                              # File name
  return './' unless $file =~ m/\//;
  my @w = split /\//, $file;
  pop @w;
  join '/', @w, ''
 }

sub fullFileName                                                                # Full name of a file.
 {my ($file) = @_;                                                              # File name
  filePath(currentDirectory, $file)                                             # Full file name
 }

sub printFullFileName                                                           # Print a file name on a separate line with escaping so it can be used easily from the command line.
 {my ($file) = @_;                                                              # File name
  "\n\'".dump(fullFileName($file))."\'\n'"
 }

#2 Temporary                                                                    # Temporary files and folders

sub temporaryFile                                                               # Create a temporary file that will automatically be L<unlinked|/unlink> during END
 {my ($fh, $filename) = tempfile;
  $filename
 }

sub temporaryFolder                                                             # Create a temporary folder that will automatically be L<rmdired|/rmdir> during END
 {my $d = tempdir();
     $d =~ s/[\/\\]+\Z//s;
  $d.'/';
 }

sub temporaryDirectory                                                          # Create a temporary directory that will automatically be L<rmdired|/rmdir> during END
 {temporaryFolder
 }

#2 Find                                                                         # Find files and folders below a folder.

sub findFiles($)                                                                # Find all the files under a folder.
 {my ($dir) = @_;                                                               # Folder to start the search with
  my @f;
  for(split /\0/, qx(find $dir -print0))
   {next if -d $_;                                                              # Do not include folder names
    push @f, $_;
   }
  @f
 }

sub findDirs($)                                                                 # Find all the folders under a folder.
 {my ($dir) = @_;                                                               # Folder to start the search with
  my @d;
  for(split /\0/, qx(find $dir -print0))
   {next unless -d $_;                                                          # Include only folders
    push @d, $_;
   }
  @d
 }

sub fileList($)                                                                 # File list.
 {my ($pattern) = @_;                                                           # Search pattern
  bsd_glob($pattern, GLOB_MARK | GLOB_TILDE)
 }

sub searchDirectoryTreesForMatchingFiles(@)                                     # Search the specified directory trees for files that match the specified extensions - the argument list should include at least one folder and one extension to be useful.
 {my (@foldersandExtensions) = @_;                                              # Mixture of folder names and extensions
  my @folder     = grep { -d $_ } @_;                                           # Folders
  my @extensions = grep {!-d $_ } @_;                                           # Extensions
  my $e = join '|', @extensions;                                                # Files
  my @f;                                                                        # Files
  for my $dir(@folder)                                                          # Directory
   {for(split /\0/, qx(find $dir -print0))
     {next if -d $_;                                                            # Do not include folder names
      push @f, $_ if m(($e)\Z)s;
     }
   }
  sort @f
 } # searchDirectoryTreesForMatchingFiles

sub matchPath($)                                                                # Given an absolute path find out how much of the path actually exists.
 {my ($file) = @_;                                                              # File name
  return $file if -e $file;                                                     # File exists so nothing more to match
  my @p = split /[\/\\]/, $file;                                                # Split path into components
  while(@p)                                                                     # Remove components one by one
   {my $d = join '/', @p;                                                       # Containing folder
    return $d if -d $d;                                                         # Containing folder exists
    pop @p;                                                                     # Remove deepest component and try again
   }
  ''                                                                            # Nothing matches
 } # matchPath

sub clearFolder($$)                                                             # Remove all the files and folders under and including the specified folder as long as the number of files to be removed is less than the specified limit.
 {my ($folder, $limitCount) = @_;                                               # Folder, maximum number of files to remove to limit damage
  return unless -d $folder;                                                     # Only works on a folder that exists
  my @f = findFiles($folder);                                                   # Find files to be removed
  if (@f > $limitCount)                                                         # Limit the number of files that can be deleted to limit potential opportunity for damage
   {my $f = @f;
    confess "Limit is $limitCount, but $f files under folder:\n$folder\n";
   }
  my @d = findDirs($folder);                                                    # These directories should be empty and thus removable after removing the files
  unlink $_ for @f;                                                             # Remove files
  rmdir $_  for reverse @d;                                                     # Remove empty folders
  -e $folder and carp "Unable to completely remove folder:\n$folder\n";         # Complain if the folder still exists
 }

#2 Read and write files                                                         # Read and write strings from and to files creating paths as needed

sub readFile($)                                                                 # Read a file containing unicode.
 {my ($file) = @_;                                                              # Name of unicode file to read
  my $f = $file;
  defined($f) or  confess "Cannot read undefined file\n";
  $f =~ m(\n) and confess "File name contains a new line:\n=$file=\n";
  -e $f or confess "Cannot read file because it does not exist, file:\n$f\n";
  open(my $F, "<:encoding(UTF-8)", $f) or confess
    "Cannot open file for unicode input, file:\n$f\n";
  local $/ = undef;
  my $s = eval {<$F>};
  $@ and confess $@;
  $s
 }

sub readBinaryFile($)                                                           # Read binary file - a file whose contents are not to be interpreted as unicode.
 {my ($file) = @_;                                                              # File to read
  my $f = $file;
  -e $f or confess "Cannot read binary file because it does not exist:\n$f\n";
  open my $F, "<$f" or confess "Cannot open binary file for input:\n$f\n";
  local $/ = undef;
  <$F>;
 }

sub makePath($)                                                                 # Make the path for the specified file name or folder.
 {my ($file) = @_;                                                              # File
  my @p = split /[\\\/]+/, $file;
  return 1 unless @p > 1;
  pop @p unless $file =~ /[\\\/]\Z/;
  my $p = join '/', @p;
  return 2 if -d $p;
  eval {make_path($p)};
  -d $p or confess "Cannot make path:\n$p\n";
  0
 }

sub writeFile($$)                                                               # Write a unicode string to a file after creating a path to the file if necessary.
 {my ($file, $string) = @_;                                                     # File to write to, unicode string to write
  $file or confess "No file name supplied\n";
  $string or carp "No string for file:\n$file\n";
  makePath($file);
  open my $F, ">$file" or confess "Cannot open for write file:\n$file\n";
  binmode($F, ":utf8");
  print  {$F} $string;
  close  ($F);
  -e $file or confess "Failed to write to file:\n$file\n";
 }

sub appendFile($$)                                                              # Append a unicode string to a file after creating a path to the file if necessary.
 {my ($file, $string) = @_;                                                     # File to append to, unicode string to append
  $file or confess "No file name supplied\n";
  $string or carp "No string for file:\n$file\n";
  makePath($file);
  open my $F, ">>$file" or confess "Cannot open for write file:\n$file\n";
  binmode($F, ":utf8");
  print  {$F} $string;
  close  ($F);
  -e $file or confess "Failed to write to file:\n$file\n";
 }

sub writeBinaryFile($$)                                                         # Write a non unicode string to a file in after creating a path to the file if necessary.
 {my ($file, $string) = @_;                                                     # File to write to, non unicode string to write
  $file or confess "No file name supplied\n";
  $string or confess "No string for file:\n$file\n";
  makePath($file);
  open my $F, ">$file" or confess "Cannot open file for binary write:\n$file\n";
  binmode($F);
  print  {$F} $string;
  close  ($F);
  -e $file or confess "Failed to write in binary to file:\n$file\n";
 }

sub binModeAllUtf8                                                              # Set STDOUT and STDERR to accept utf8 without complaint
 {binmode $_, ":utf8" for *STDOUT, *STDERR;
 }

#1 Images                                                                       # Image operations

sub imageSize($)                                                                # Return (width, height) of an image obtained via imagemagick.
 {my ($image) = @_;                                                             # File containing image
  -e $image or confess
    "Cannot get size of image as file does not exist:\n$image\n";
  my $s = qx(identify -verbose "$image");
  if ($s =~ /Geometry: (\d+)x(\d+)/s)
   {return ($1, $2);
   }
  else
   {confess "Cannot get image size for file:\n$image\nfrom:\n$s\n";
   }
 }

sub convertImageToJpx($$$)                                                      # Convert an image to jpx format.
 {my ($source, $target, $size) = @_;                                            # Source file, target folder (as multiple files will be created),  size of each tile
  -e $source or confess
   "Cannot convert image file as file does not exist:\n$source\n";
  makePath($target);
  my ($w, $h) = imageSize($source);
  writeFile(filePath($target, "jpx.data"), <<END);
version 1
type    jpx
size    $size
source  $source
width   $w
height  $h
END

  if (1)
   {my $s = quoteFile($source);
    my $t = quoteFile($target);
    qx(convert $s -crop ${size}x${size} $t);
   }

  if (1)
   {my $W = int($w/$size); ++$W if $w % $size;
    my $H = int($h/$size); ++$H if $h % $size;
    my $k = 0;
    for   my $Y(1..$H)
     {for my $X(1..$W)
       {my $s = "${target}-$k";
        my $t = "${target}/${Y}_${X}.jpg";
        rename $s, $t or confess "Cannot rename file:\n$s\nto:\n$t\n";
        -e $t or confess "Cannot create file:\n$t\n";
        ++$k;
       }
     }
   }
 }

#1 Encoding and Decoding                                                        # Encode and decode using Json and Mime

sub encodeJson($)                                                               # Encode Perl to Json.
 {my ($string) = @_;                                                            # Data to encode
  encode_json($string)
 }

sub decodeJson($)                                                               # Decode Perl from Json.
 {my ($string) = @_;                                                            # Data to decode
  decode_json($string)
 }

sub encodeBase64($)                                                             # Encode a string in base 64.
 {my ($string) = @_;                                                            # String to encode
  encode_base64($string, '')
 }

sub decodeBase64($)                                                             # Decode a string in base 64.
 {my ($string) = @_;                                                            # String to decode
  decode_base64($string)
 }

sub convertUnicodeToXml($)                                                      # Convert a string with unicode points that are not directly representable in ascii into string that replaces these points with their representation on Xml making the string usable in Xml documents
 {my ($s) = @_;                                                                 # String to convert
  my $t = '';
  for(split //, $s)                                                             # Each letter in the source
   {my $n = ord($_);
    my $c = $n > 127 ? "&#$n;" : $_;                                            # Use xml representation beyond u+127
    $t .= $c;
   }
  $t                                                                            # Return resulting string
 }

#1 Numbers                                                                      # Numeric operations

sub powerOfTwo($)                                                               #X Test whether a number is a power of two, return the power if it is else B<undef>
 {my ($n) = @_;                                                                 # Number to check
  for(0..128)
   {return $_  if 1<<$_ == $n;
    last       if 1<<$_ >  $n;
   }
  undef
 }

sub containingPowerOfTwo($)                                                     #X Find log two of the lowest power of two greater than or equal to a number.
 {my ($n) = @_;                                                                 # Number to check
  for(0..128)
   {return $_  if $n <= 1<<$_;
   }
  undef
 }


#1 Sets                                                                         # Set operations

sub setIntersectionOfTwoArraysOfWords($$)                                       # Intersection of two arrays of words
 {my ($a, $b) = @_;                                                             # Reference to first array of words, reference to second array of words
  my @a = @$a >  @$b ? @$a : @$b;
  my @b = @$a <= @$b ? @$a : @$b;
  my %a  = map {$_=>1} @a;
  my %b  = map {$_=>1} @b;
  grep {$a{$_}} sort keys %b
 }

sub setUnionOfTwoArraysOfWords($$)                                              # Union of two arrays of words
 {my ($a, $b) = @_;                                                             # Reference to first array of words, reference to second array of words
  my %a = map {$_=>1} @$a, @$b;
  sort keys %a
 }

sub contains($@)                                                                # Returns the indices at which an item matches elements of the specified array. If the item is a regular expression then it is matched as one, else it is a number it is matched as a number, else as a string.
 {my ($item, @array) = @_;                                                      # Item, array
  my @r;
  if (ref($item) =~ m(Regexp))                                                  # Match via a regular expression
   {for(keys @array)
     {push @r, $_ if $array[$_] =~ m($item)s;
     }
   }
  elsif (is_float($item))                                                       # Match as a number
   {for(keys @array)
     {push @r, $_ if $array[$_]+0 == $item;
     }
   }
  else                                                                          # Match as a string
   {for(keys @array)
     {push @r, $_ if $array[$_] eq $item;
     }
   }
  @r
 }

#1 Minima and Maxima                                                            # Find the smallest and largest elements of arrays

sub min(@)                                                                      # Find the minimum number in a list.
 {my (@n) = @_;                                                                 # Numbers
  return undef unless @n;
  return $n[0] if @n == 0;
  my $m = $n[0];
  for(@n)
   {$m = $_ if $_ < $m;
   }
  $m
 }

sub max(@)                                                                      # Find the maximum number in a list.
 {my (@n) = @_;                                                                 # Numbers
  return undef unless @n;
  return $n[0] if @n == 0;
  my $M = $n[0];
  for(@n)
   {$M = $_ if $_ > $M;
   }
  $M
 }

#1 Format                                                                       # Format data structures as tables

sub formatTableBasic($;$)                                                       # Tabularize text
 {my ($data, $separator) = @_;                                                  # Reference to an array of arrays of data to be formatted as a table, optional line separator to use instead of new line for each row.
  my $d = $data;
  ref($d) =~ /array/i or confess "Array reference required\n";
  my @D;
  for   my $e(@$d)
   {ref($e) =~ /array/i or confess "Array reference required\n";
    for my $D(0..$#$e)
     {my $a = $D[$D]           // 0;                                            # Maximum length of data so far
      my $b = length($e->[$D]) // 0;                                            # Length of current item
      $D[$D] = ($a > $b ? $a : $b);                                             # Update maximum length
     }
   }

  my @t;                                                                        # Formatted data
  for   my $e(@$d)
   {my $t = '';                                                                 # Formatted text
    for my $D(0..$#$e)
     {my $m = $D[$D];                                                           # Maximum width
      my $i = $e->[$D]//'';                                                     # Current item
      if ($i !~ /\A\s*[-+]?\s*[0-9,]+(\.\d+)?([Ee]\s*[-+]?\s*\d+)?\s*\Z/)       # Not a number - left justify
       {$t .= substr($i.(' 'x$m), 0, $m)."  ";
       }
      else                                                                      # Number - right justify
       {$t .= substr((' 'x$m).$i, -$m)."  ";
       }
     }
    push @t, $t;
   }

  my $s = $separator//"\n";
  join($s, @t).$s
 }

sub formatTableAA($;$$)                                                         #P Tabularize an array of arrays.
 {my ($data, $title, $separator) = @_;                                          # Data to be formatted, optional title, optional line separator
  return dump($data) unless ref($data) =~ /array/i and @$data;
  my $d;
  push @$d, ['', @$title] if $title;
  push @$d, [$_, @{$data->[$_-1]}] for 1..@$data;
  formatTableBasic($d, $separator);
 }

sub formatTableHA($;$$)                                                         #P Tabularize a hash of arrays.
 {my ($data, $title, $separator) = @_;                                          # Data to be formatted, optional title, optional line separator
  return dump($data) unless ref($data) =~ /hash/i and keys %$data;
  my $d;
  push @$d, [['', @$title]] if $title;
  push @$d, [$_, @{$data->{$_}}] for sort keys %$data;
  formatTableBasic($d, $separator);
 }

sub formatTableAH($;$$)                                                         #P Tabularize an array of hashes.
 {my ($data, $title, $separator) = @_;                                          # Data to be formatted, optional title, optional line separator
  return dump($data) unless ref($data) =~ /array/i and @$data;

  my %k; @k{keys %$_}++ for @$data;                                             # Column headers
  my @k = sort keys %k;
  $k{$k[$_-1]} = $_ for 1..@k;

  my $d = [['', @k]];
  for(1..@$data)
   {push @$d, [$_];
    my %h = %{$data->[$_-1]};
    $d->[-1][$k{$_}] = $h{$_} for keys %h;
   }
  formatTableBasic($d, $separator);
 }

sub formatTableHH($;$$)                                                         #P Tabularize a hash of hashes.
 {my ($data, $title, $separator) = @_;                                          # Data to be formatted, optional title, optional line separator
  return dump($data) unless ref($data) =~ /hash/i and keys %$data;

  my %k; @k{keys %$_}++ for values %$data;                                      # Column headers
  my @k = sort keys %k;
  $k{$k[$_-1]} = $_ for 1..@k;

  my $d = [['', @k]];
  for(sort keys %$data)
   {push @$d, [$_];
    my %h = %{$data->{$_}};
    $d->[-1][$k{$_}] = $h{$_} for keys %h;
   }
  formatTableBasic($d, $separator);
 }

sub formatTableA($;$$)                                                          #P Tabularize an array.
 {my ($data, $title, $separator) = @_;                                          # Data to be formatted, optional title, optional line separator
  return dump($data) unless ref($data) =~ /array/i and @$data;

  my $d;
  push @$d, $title if $title;
  for(keys @$data)
   {push @$d, @$data > 1 ? [$_, $data->[$_]] : [$data->[$_]];                   # Skip line number if the array is degenerate
   }
  formatTableBasic($d, $separator);
 }

sub formatTableH($;$$)                                                          #P Tabularize a hash.
 {my ($data, $title, $separator) = @_;                                          # Data to be formatted, optional title, optional line separator

  return dump($data) unless ref($data) =~ /hash/i and keys %$data;

  my $d;
  push @$d, $title if $title;
  for(sort keys %$data)
   {push @$d, [$_, $data->{$_}];
   }
  formatTableBasic($d, $separator);
 }

sub formatTable($;$$)                                                           # Format various data structures as a table
 {my ($data, $title, $separator) = @_;                                          # Data to be formatted, optional reference to an array of titles, optional line separator
  my ($a, $h, $o) = (0, 0, 0);
  my $checkStructure = sub
   {for(@_)
     {my $r = ref($_[0]);
      if ($r =~ /array/i) {++$a} elsif ($r =~ /hash/i) {++$h} else {++$o}
     }
   };

  if    (ref($data) =~ /array/i)
   {$checkStructure->(       @$data);
    return formatTableAA($data, $title, $separator) if  $a and !$h and !$o;
    return formatTableAH($data, $title, $separator) if !$a and  $h and !$o;
    return formatTableA ($data, $title, $separator);
   }
  elsif (ref($data) =~ /hash/i)
   {$checkStructure->(values %$data);
    return formatTableHA($data, $title, $separator) if  $a and !$h and !$o;
    return formatTableHH($data, $title, $separator) if !$a and  $h and !$o;
    return formatTableH ($data, $title, $separator);
   }
 }

sub keyCount($$)                                                                # Count keys down to the specified level.
 {my ($maxDepth, $ref) = @_;                                                    # Maximum depth to count to, reference to an array or a hash
  my $n = 0;
  my $count;
  $count = sub
   {my ($ref, $currentDepth) = @_;
    if (ref($ref) =~ /array/i)
     {if ($maxDepth == $currentDepth) {$n += scalar(@$ref)}
      else {$count->($_, ++$currentDepth)       for @$ref}
     }
    elsif (ref($ref) =~ /hash/i)
     {if ($maxDepth == $currentDepth)   {$n += scalar(keys %$ref)}
      else {$count->($ref->{$_}, ++$currentDepth) for keys %$ref}
     }
    else {++$n}
   };
  $count->($ref, 1);
  $n
 }

#1 Lines                                                                        # Load data structures from lines

sub loadArrayFromLines($)                                                       # Load an array from lines of text in a string.
 {my ($string) = @_;                                                            # The string of lines from which to create an array
  [split "\n", $string]
 }

sub loadHashFromLines($)                                                        # Load a hash: first word of each line is the key and the rest is the value.
 {my ($string) = @_;                                                            # The string of lines from which to create a hash
  +{map{split /\s+/, $_, 2} split "\n", $string}
 }

sub loadArrayArrayFromLines($)                                                  # Load an array of arrays from lines of text: each line is an array of words.
 {my ($string) = @_;                                                            # The string of lines from which to create an array of arrays
  [map{[split /\s+/]} split "\n", $string]
 }

sub loadHashArrayFromLines($)                                                   # Load a hash of arrays from lines of text: the first word of each line is the key, the remaining words are the array contents.
 {my ($string) = @_;                                                            # The string of lines from which to create a hash of arrays
  +{map{my @a = split /\s+/; (shift @a, [@a])} split "\n", $string}
 }

sub checkKeys($$)                                                               # Check the keys in a hash.
 {my ($test, $permitted) = @_;                                                  # The hash to test, the permitted keys and their meanings

  ref($test)      =~ /hash/igs or                                               # Check parameters
    confess "Hash reference required for first parameter\n";
  ref($permitted) =~ /hash/igs or
    confess "Hash reference required for second parameter\n";

  my %parms = %$test;                                                           # Copy keys supplied
  delete $parms{$_} for keys %$permitted;                                       # Remove permitted keys
  return '' unless keys %parms;                                                 # Success - all the keys in the test hash are permitted

  confess join "\n",                                                            # Failure - explain what went wrong
   "Invalid options chosen:",
    indentString(formatTable([sort keys %parms]), '  '),
   "",
   "Permitted options are:",
    indentString(formatTable($permitted),         '  '),
   "",
 }

#1 LVALUE methods                                                               # Replace $a->{value} = $b with $a->value = $b which reduces the amount of typing required, is easier to read and provides a hard check that {value} is spelt correctly.
sub genLValueScalarMethods(@)                                                   # Generate LVALUE scalar methods in the current package, A method whose value has not yet been set will return a new scalar with value undef. Suffixing B<X> to the scalar name will confess if a value has not been set.  Example: $a->value = 1;
 {my (@names) = @_;                                                             # List of method names
  my ($package) = caller;                                                       # Package
  for(@_)                                                                       # Name each method
   {my $s = 'sub '.$package.'::'.$_.':lvalue {my $v; $_[0]{"'.$_.'"} //= $v}'.
            'sub '.$package.'::'.$_.'X:lvalue {my $v = $_[0]{"'.$_.'"}; confess q(No value supplied for "'.$_.'") unless defined($v); $v}';
    eval $s;
    confess "Unable to create LValue scalar method for: '$_' because\n$@\n" if $@;
   }
 }

sub genLValueScalarMethodsWithDefaultValues(@)                                  # Generate LVALUE scalar methods with default values in the current package. A reference to a method whose value has not yet been set will return a scalar whose value is the name of the method.  Example: $a->value == qq(value);
 {my (@names) = @_;                                                             # List of method names
  my ($package) = caller;                                                       # Package
  for(@_)                                                                       # Name each method
   {my $s = 'sub '.$package.'::'.$_.':lvalue {my $v = "'.$_.'"; $_[0]{"'.$_.'"} //= $v}';
    eval $s;
    confess "Unable to create LValue scalar method for: '$_' because\n$@\n" if $@;
   }
 }

sub genLValueArrayMethods(@)                                                    # Generate LVALUE array methods in the current package. A reference to a method that has no yet been set will return a reference to an empty array.  Example: $a->value->[1] = 2;
 {my (@names) = @_;                                                             # List of method names
  my ($package) = caller;                                                       # Package
  for(@_)                                                                       # Name each method
   {my $s = 'sub '.$package.'::'.$_.':lvalue {$_[0]{"'.$_.'"} //= []}';
    eval $s;
    confess "Unable to create LValue array method for: '$_' because\n$@\n" if $@;
   }
 }

sub genLValueHashMethods(@)                                                     # Generate LVALUE hash methods in the current package. A reference to a method that has no yet been set will return a reference to an empty hash. Example: $a->value->{a} = 'b';
 {my (@names) = @_;                                                             # Method names
  my ($package) = caller;                                                       # Package
  for(@_)                                                                       # Name each method
   {my $s = 'sub '.$package.'::'.$_.':lvalue {$_[0]{"'.$_.'"} //= {}}';
    eval $s;
    confess "Unable to create LValue hash method for: '$_' because\n$@\n" if $@;
   }
 }

#1 Strings                                                                      # Actions on strings

sub indentString($$)                                                            # Indent lines contained in a string or formatted table by the specified string.
 {my ($string, $indent) = @_;                                                   # The string of lines to indent, the indenting string
  join "\n", map {$indent.$_} split "\n", (ref($string) ? $$string  : $string)
 }

sub isBlank($)                                                                  # Test whether a string is blank.
 {my ($string) = @_;                                                            # String
  $string =~ m/\A\s*\Z/
 }

sub trim($)                                                                     # Trim off white space from from front and end of string.
 {my ($string) = @_;                                                            # String
  $string =~ s/\A\s+//r =~ s/\s+\Z//r
 }

sub pad($$)                                                                     # Pad a string with blanks to a multiple of a specified length.
 {my ($string, $length) = @_;                                                   # String, tab width
  $string =~ s/\s+\Z//;
  my $l = length($string);
  return $string if $l % $length == 0;
  my $p = $length - $l % $length;
  $string .= ' ' x $p;
 }

sub nws($)                                                                      # Normalize white space in a string to make comparisons easier. Leading and trailing white space is removed; blocks of whitespace in the interior are reduced to a singe space.  In effect: this puts everything on one long line with never more than a space at a time.
 {my ($string) = @_;                                                            # String to normalize
  $string =~ s/\A\s+//r =~ s/\s+\Z//r =~ s/\s+/ /gr
 }

sub javaPackage($)                                                              # Extract the package name from a java string or file.
 {my ($java) = @_;                                                              # Java file if it exists else the string of java

  my $s = sub
   {return readFile($java) if $java !~ m/\n/s and -e $java;                     # Read file of java
    $java                                                                       # Java string
   }->();

  my ($p) = $s =~ m(package\s+(\S+)\s*;);
  $p
 }

sub javaPackageAsFileName($)                                                    # Extract the package name from a java string or file and convert it to a file name.
 {my ($java) = @_;                                                              # Java file if it exists else the string of java

  if (my $p = javaPackage($java))
   {return $p =~ s/\./\//gr;
   }
  undef
 }

sub perlPackage($)                                                              # Extract the package name from a perl string or file.
 {my ($perl) = @_;                                                              # Perl file if it exists else the string of perl
  javaPackage($perl);                                                           # Use same technique as Java
 }

sub printQw(@)                                                                  # Print an array of words in qw() format
 {my (@words) = @_;                                                             # Array of words
  'qw('.join(' ', @words).')'
 }

#1 Cloud Cover                                                                  # Useful for operating across the cloud

sub addCertificate($)                                                           # Add a certificate to the current ssh session.
 {my ($file) = @_;                                                              # File containing certificate
  qx(ssh-add -t 100000000 $file 2>/dev/null);
 }

sub hostName                                                                    # The name of the host we are running on
 {trim(qx(hostname))
 }

sub userId                                                                      # The userid we are currently running under
 {trim(qx(whoami))
 }

#1 Documentation                                                                # Extract, format and update documentation for a perl module

sub extractTest($)                                                              #P Extract a line of a test.
 {my ($string) = @_;                                                            # String containing test line
  $string =~ s/\A\s*{?(.+?)\s*#.*\Z/$1/;                                        # Remove any initial whitespace and possible { and any trailing whitespace and comments
  $string
 }

sub updateDocumentation(;$)                                                     # Update documentation from a perl script between the lines marked with:\m  #n title # description\mand:\m  #...\mwhere n is either 1, 2 or 3 indicating the heading level of the section and the # is in column 1.\mMethods are formatted as:\m  sub name(signature)      #FLAGS comment describing method\n   {my ($parameters) = @_; # comments for each parameter separated by commas.\mFLAGS can be any combination of:\m=over\m=item I\mmethod of interest to new users\m=item P\mprivate method\m=item S\mstatic method\m=item X\mdie rather than received a returned B<undef> result\m=back\mOther flags will be handed to the method extractDocumentationFlags(flags to process, method name) found in the file being documented, this method should return [the additional documentation for the method, the code to implement the flag].\mText following 'E\xxample:' in the comment (if present) will be placed after the parameters list as an example. Lines containing comments consisting of '#T'.methodName will also be aggregated as an example. \mLines formatted as:\m  #C emailAddress text\mwill be aggregated in the acknowledgments section at the end of the documentation.\mThe character sequence \\xn in the comment will be expanded to one new line and \\xm to two new lines.\mSearch for '#1': in L<https://metacpan.org/source/PRBRENAN/Data-Table-Text-20170728/lib/Data/Table/Text.pm>  to see examples.\mParameters:\n
 {my ($perlModule) = @_;                                                        # Optional file name with caller's file being the default
  $perlModule //= $0;                                                           # Extract documentation from the caller if no perl module is supplied
  my $package = perlPackage($perlModule);                                       # Package name
  my %collaborators;                                                            # Collaborators #C pause-id  comment
  my %examples;                                                                 # Examples for each method
  my %iUseful;                                                                  # Immediately useful methods
  my %methods;                                                                  # Methods that have been coded as opposed to being generated
  my %methodParms;                                                              # Method names including parameters
  my %methodX;                                                                  # Method names for methods that have an version suffixed with X that die rather than returning undef
  my %private;                                                                  # Private methods
  my %static;                                                                   # Static methods
  my %userFlags;                                                                # User flags
  my @doc = (<<END);                                                            # Documentation
`head1 Description

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.

END
  my @private;                                                                  # Documentation of private methods
  my $level = 0; my $off = 0;                                                   # Header levels

  my $Source = my $source  = readFile($perlModule);                             # Read the perl module

  if ($source =~ m(our\s+\$VERSION\s*=\s*(\S+)\s*;)s)                           # Update references to examples so we can include html and images etc. in the module
   {my $V = $1;                                                                # Quoted version
    if (my $v = eval $V)                                                        # Remove any quotes
     {my $s = $source;
      $source =~                                                                # Replace example references in source
        s((https://metacpan\.org/source/\S+?-)(\d+)(/examples/))
         ($1$v$3)gs;
     }
   }

  my @lines = split /\n/, $source;                                              # Split source into lines

  for my $l(keys @lines)                                                        # Tests associated with each method
   {my $line = $lines[$l];
    if (my @tags = $line =~ m/(?:\s#T(\w+))/g)
     {my %tags; $tags{$_}++ for @tags;

      for(grep {$tags{$_} > 1} sort keys %tags)                                 # Check for duplicate example names on the same line
       {warn "Duplicate example name $_ on line $l";
       }

      my @testLines = (extractTest($line));

      if ($line =~ m/<<(END|'END'|"END")/)                                      # Process here documents
       {for(my $L = $l + 1; $L < @lines; ++$L)
         {my $nextLine = $lines[$L];
          push @testLines, extractTest($nextLine);
          if ($nextLine =~ m/\AEND/)                                            # Add a blank line after the END
           {last
           }
         }
       }

      push @testLines, '';                                                      # Blank line between each test line

      for my $testLine(@testLines)                                              # Save test lines
       {for my $t(sort keys %tags)
         {push @{$examples{$t}}, $testLine;
         }
       }
     }
   }

  unless($perlModule =~ m(\A(Text.pm|Doc.pm)\Z)s)                               # Load the module being documented so that we can call its extractDocumentationFlags method if needed to process user flags, we do not need to load these modules as they are already loaded
   {do "$perlModule";
    confess dump($@, $!) if $@;
   }

  for my $l(keys @lines)
   {my $line     = $lines[$l];                                                  # This line
    my $nextLine = $lines[$l+1];                                                # The next line

    if ($line =~ /\A#(\d)\s+(.*?)\s*(#\s*(.+)\s*)?\Z/)                          # Sections are marked with #n in column 1-2 followed by title followed by optional text
     {$level = $1;
      my $headLevel = $level+$off;
      push @doc, "\n=head$headLevel $2" if $level;                              # Heading
      push @doc, "\n$4"                 if $level and $4;                       # Text of section
     }
    elsif ($line =~ /\A#C\s+(\S+)\s+(.+?)\s*\Z/)                                # Collaborators
     {$collaborators{$1} = $2;
     }
    elsif ($line =~ /\A#/)                                                      # Switch documentation off
     {$level = 0;
     }
    elsif ($level and $line =~ /\A\s*sub\s*(.*?)?\s*#(\w*)\s+(.+?)\s*\Z/)       # Documentation for a method
     {my ($sub, $flags, $comment, $example, $produces) =                        # Name from sub, flags, description
         ($1, $2, $3);

      $flags //= '';                                                            # No flags found

      if ($comment =~ m/\A(.*)Example:(.+?)\Z/is)                               # Extract example
       {$comment = $1;
       ($example, $produces) = split /:/, $2, 2;
       }

      my $signature = $sub =~ s/\A\s*\w+//gsr =~                                # Signature
                              s/\A\(//gsr     =~
                              s/\)\s*(:lvalue\s*)?\Z//gsr =~
                              s/;//gsr;                                         # Remove optional parameters marker from signature
      my $name      = $sub =~ s/\(.*?\)//r;                                     # Method name after removing parameters

      my $methodX   = $flags =~ m/X/;                                           # Die rather than return undef
      my $private   = $flags =~ m/P/;                                           # Private
      my $static    = $flags =~ m/S/;                                           # Static
      my $iUseful   = $flags =~ m/I/;                                           # Immediately useful
      my $userFlags = $flags =~ s/[IPSX]//gsr;                                  # User flags == all flags minus the known flags

      $methodX  {$name} = $methodX   if $methodX;                               # MethodX
      $private  {$name} = $private   if $private;                               # Private
      $static   {$name} = $static    if $static;                                # Static
      $iUseful  {$name} = $comment   if $iUseful;                               # Immediately useful

      $userFlags{$name} =                                                       # Process user flags
        &docUserFlags($userFlags, $perlModule, $package, $name)
        if $userFlags;

      my ($parmNames, $parmDescriptions);
      if ($signature)                                                           # Parameters, parameter descriptions from comment
       {($parmNames, $parmDescriptions) =
         $nextLine =~ /\A\s*(.+?)\s*#\s*(.+?)\s*\Z/;
       }
      $parmNames //= ''; $parmDescriptions //= '';                              # No parameters

      my @parameters = split /,\s*/,                                            # Parameter names
        $parmNames =~ s/\A\s*\{my\s*\(//r =~ s/\)\s*=\s*\@_;//r;

      @parameters == length($signature) or                                      # Check signature length
        confess "Wrong number of parameter descriptions for method: ".
          "$name($signature)";

      my @parmDescriptions = map {ucfirst()} split /,\s*/, $parmDescriptions;   # Parameter descriptions with first letter uppercased

      if (1)                                                                    # Check parameters comment
       {my $p = @parmDescriptions;
        my $l = length($signature);
        $p == $l or confess <<"END";
Method: $name($signature). The comment describing the parameters for this
method has descriptions for $p parameters but the signature suggests that there
are $l parameters.

The comment is split on /,/ to divide the comment into descriptions of each
parameter.

The comment supplied is:
$parmDescriptions
END
       }

      my $parametersAsString = join ', ', @parameters;                          # Parameters as a comma separated string
      my $headLevel = $level+$off+1;                                            # Heading level
      my $methodSignature = "$name($parametersAsString)";                       # Method(signature)

      $methods{$name}++;                                                        # Methods that have been coded as opposed to being generated
      $methodParms{$name} = $name;                                              # Method names not including parameters
      $methodParms{$name.'X'} = $name if $methodX;                              # Method names not including parameters
      $methodX{$name}++ if $methodX;                                            # Method names that have an X version
      if (my $u = $userFlags{$name})                                            # Add names of any generated methods
       {$methodParms{$_} = $name for @{$u->[2]};                                # Generated names array
       }

      my   @method;                                                             # Accumulate method documentation

      if (1)                                                                    # Section title
       {my $h = $private ? 2 : $headLevel;
        push @method, "\n=head$h $name($signature)\n\n$comment\n";              # Method description
       }

      push @method, indentString(formatTable([[qw(Parameter Description)],
        map{[$parameters[$_], $parmDescriptions[$_]]} keys @parameters]), '  ')
        if $parmNames and $parmDescriptions and $parmDescriptions !~ /\A#/;     # Add parameter description if present

      push @method,                                                             # Add user documentation
       "\n".$userFlags{$name}[0]."\n"          if $userFlags{$name}[0];

      push @method,                                                             # Add example
       "\nExample:\n\n  $example"              if $example;

      push @method,                                                             # Produces
       "\n$produces"                           if $produces;

      if (my $examples = $examples{$name})                                      # Format examples
       {if (my @examples = @$examples)
         {push @method, '\nExample:\m', map {"  $_"} @examples;
         }
       }

      push @method,                                                             # Add a note about the availability of an X method
       "\nUse B<${name}X> to execute L<$name|/$name> but B<die> '$name'".
       " instead of returning B<undef>"        if $methodX;

      push @method,                                                             # Static method
       "\nThis is a static method and so should be invoked as:\n\n".
       "  $package::$name\n"                   if $static;

      push @{$private ? \@private : \@doc}, @method;                            # Save method documentation in correct section
     }
    elsif ($level and $line =~                                                  # Documentation for a generated lvalue * method = sub name comment
     /\A\s*genLValue(?:\w+?)Methods\s*\(qw\((\w+)\)\);\s*#\s*(.+?)\s*\Z/)
     {my ($name, $description) = ($1, $2);                                      # Name from sub, description from comment
      next if $description =~ /\A#/;                                            # Private method if #P
      my $headLevel = $level+$off+1;                                            # Heading level
      $methodParms{$name} = $name;                                              # Method names not including parameters
      push @doc, "\n=head$headLevel $name :lvalue\n\n$description\n";           # Method description
     }
   }

  if (1)                                                                        # Alphabetic listing of methods that still need examples
   {my %m = %methods;
    delete @m{$_, "$_ :lvalue"} for keys %examples;
    delete @m{$_, "$_ :lvalue"} for keys %private;
    my $n = keys %m;
    my $N = keys %methods;
    say STDERR formatTable(\%m), "\n$n of $N methods still need tests" if $n;
   }

  if (keys %iUseful)                                                            # Alphabetic listing of immediately useful methods
    {my @d;
     push @d, <<END;

`head1 Immediately useful methods

These methods are the ones most likely to be of immediate use to anyone using
this module for the first time:

END
    for my $m(sort {lc($a) cmp lc($b)} keys %iUseful)
     {my $c = $iUseful{$m};
       push @d, "L<$m|/$m>\n\n$c\n"
     }
    push @d, <<END;

END
    unshift @doc, (shift @doc, @d)                                              # Put first after title
   }

  push @doc, qq(\n\n=head1 Private Methods), @private if @private;              # Private methods in a separate section if there are any

  push @doc, "\n\n=head1 Index\n\n";
  if (1)
   {my $n = 0;
    for my $s(sort {lc($a) cmp lc($b)} keys %methodParms)                       # Alphabetic listing of methods
     {my $t = $methodParms{$s};
      push @doc, ++$n." L<$s|/$t>\n"
     }
   }

  push @doc, <<END;                                                             # Standard stuff
`head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read, use,
modify and install.

Standard L<Module::Build> process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

`head1 Author

L<philiprbrenan\@gmail.com|mailto:philiprbrenan\@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

`head1 Copyright

Copyright (c) 2016-2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.
END

  if (keys %collaborators)                                                      # Acknowledge any collaborators
   {push @doc,
     '\n=head1 Acknowledgements\m'.
     'Thanks to the following people for their help with this module:\m'.
     '=over\m';
    for(sort keys %collaborators)
     {my $p = "L<$_|mailto:$_>";
      my $r = $collaborators{$_};
      push @doc, "=item $p\n\n$r\n\n";
     }
    push @doc, '=back\m';
   }

  push @doc, '=cut\m';                                                          # Finish documentation

  if (keys %methodX)                                                            # Insert X method definitions
   {my @x;
    for my $x(sort keys %methodX)
     {push @x, ["sub ${x}X", "{&$x", "(\@_) || die '$x'}"];
     }
    push @doc, formatTableBasic(\@x);
   }

  for my $name(sort keys %userFlags)                                            # Insert generated method definitions
   {if (my $doc = $userFlags{$name})
     {push @doc, $doc->[1] if $doc->[1];
     }
   }

  push @doc, <<'END';                                                           # Standard test sequence

# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
 }

test unless caller;
END


  s/\\m/\n\n/gs for @doc;                                                       # Expand \\m to two new lines in documentation
  s/\\n/\n/gs   for @doc;                                                       # Expand \\n to one new line  in documentation
  s/\\x//gs     for @doc;                                                       # Expand \\x to ''            in documentation
  s/`/=/gs      for @doc;                                                       # Convert ` to =

  my $doc = join "\n", @doc;                                                    # Documentation
  $source =~ s/\n+=head1 Description.+?\n+1;\n+/\n\n$doc\n1;\n/gs;              # Edit module source from =head1 description to final 1;

  if ($source ne $Source)                                                       # Save source only if it has changed
   {writeFile(filePathExt($perlModule, qq(backup)), $source);                   # Backup module source
    writeFile($perlModule, $source);                                            # Write updated module source
   }
 }

sub docUserFlags($$$$)                                                          # Generate documentation for a method
 {my ($flags, $perlModule, $package, $name) = @_;                               # Flags, file containing documentation, package containing documentation, name of method to be processed
  my $s = <<END;
${package}::extractDocumentationFlags("$flags", "$name");
END

  use Data::Dump qw(dump);
  my $r = eval $s;
  confess "$s\n". dump($@, $!) if $@;
  $r
 }

sub updatePerlModuleDocumentation($)                                            # Update the documentation in a perl file and show said documentation in a web browser.
 {my ($perlModule) = @_;                                                        # File containing the code of the perl module
  -e $perlModule or confess "No such file:\n$perlModule\n";
  updateDocumentation($perlModule);                                             # Update documentation

  xxx("pod2html --infile=$perlModule --outfile=zzz.html && ".                   # View documentation
      " google-chrome zzz.html pods2 && ".
      " rm zzz.html pod2htmd.tmp");
 }

#-------------------------------------------------------------------------------
# Examples
#-------------------------------------------------------------------------------

if (0 and !caller)
 {say STDERR "\n","\nsay STDERR formatTable(",dump($_), ");\n# ", formatTable($_) =~ s/\n/\n# /gr for
[[qw(. aa bb cc)], [qw(1 A B C)], [qw(2 AA BB CC)], [qw(3 AAA BBB CCC)],  [qw(4 1 22 333)]],
[{aa=>'A', bb=>'B', cc=>'C'}, {aa=>'AA', bb=>'BB', cc=>'CC'}, {aa=>'AAA', bb=>'BBB', cc=>'CCC'}, {aa=>'1', bb=>'22', cc=>'333'}],
{''=>[qw(aa bb cc)], 1=>[qw(A B C)], 22=>[qw(AA BB CC)], 333=>[qw(AAA BBB CCC)],  4444=>[qw(1 22 333)]},
{a=>{aa=>'A', bb=>'B', cc=>'C'}, aa=>{aa=>'AA', bb=>'BB', cc=>'CC'}, aaa=>{aa=>'AAA', bb=>'BBB', cc=>'CCC'}, aaaa=>{aa=>'1', bb=>'22', cc=>'333'}},
[qw(a bb ccc 4444)],
{aa=>'A', bb=>'B', cc=>'C'};
 }

#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw(formatTable);
@EXPORT_OK    = qw(
addCertificate appendFile
binModeAllUtf8
checkFile checkFilePath checkFilePathExt checkFilePathDir
checkKeys clearFolder contains containingPowerOfTwo
containingFolder convertImageToJpx convertUnicodeToXml currentDirectory currentDirectoryAbove
dateStamp dateTimeStamp decodeJson decodeBase64
encodeJson encodeBase64
fileList fileModTime fileOutOfDate
filePath filePathDir filePathExt fpd fpe fpf fileSize findDirs findFiles
formatTableBasic fullFileName
genLValueArrayMethods genLValueHashMethods
genLValueScalarMethods genLValueScalarMethodsWithDefaultValues
hostName
imageSize indentString isBlank
javaPackage javaPackageAsFileName
keyCount
loadArrayArrayFromLines loadArrayFromLines
loadHashArrayFromLines loadHashFromLines
makePath matchPath max min
nws
pad parseFileName parseCommandLineArguments powerOfTwo printFullFileName printQw
quoteFile
readBinaryFile readFile removeFilePrefix
saveToS3 searchDirectoryTreesForMatchingFiles
setIntersectionOfTwoArraysOfWords setUnionOfTwoArraysOfWords
temporaryDirectory temporaryFile temporaryFolder timeStamp trim
updateDocumentation updatePerlModuleDocumentation userId
writeBinaryFile writeFile
xxx XXX
zzz);
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation
#C mim@cpan.org Testing on windows

=pod

=encoding utf-8

=head1 Name

Data::Table::Text - Write data in tabular text format

=head1 Synopsis

Print an array of hashes:

 use Data::Table::Text;

 say STDERR formatTable([
   { aa => "A", bb => "B", cc => "C" },
   { aa => "AA", bb => "BB", cc => "CC" },
   { aa => "AAA", bb => "BBB", cc => "CCC" },
   { aa => 1, bb => 22, cc => 333 }]);

 #    aa   bb   cc
 # 1  A    B    C
 # 2  AA   BB   CC
 # 3  AAA  BBB  CCC
 # 4    1   22  333

Print a hash of arrays:

 say STDERR formatTable({
   "" => ["aa", "bb", "cc"],
   "1" => ["A", "B", "C"],
   "22" => ["AA", "BB", "CC"],
   "333" => ["AAA", "BBB", "CCC"],
   "4444" => [1, 22, 333]});

 #       aa   bb   cc
 #    1  A    B    C
 #   22  AA   BB   CC
 #  333  AAA  BBB  CCC
 # 4444    1   22  333

Print a hash of hashes:

 say STDERR formatTable({
   a => { aa => "A", bb => "B", cc => "C" },
   aa => { aa => "AA", bb => "BB", cc => "CC" },
   aaa => { aa => "AAA", bb => "BBB", cc => "CCC" },
   aaaa => { aa => 1, bb => 22, cc => 333 }});
 #       aa   bb   cc
 # a     A    B    C
 # aa    AA   BB   CC
 # aaa   AAA  BBB  CCC
 # aaaa    1   22  333

Print an array of scalars:

 say STDERR formatTable(["a", "bb", "ccc", 4]);
 # 0  a
 # 1  bb
 # 2  ccc
 # 3    4

Print a hash of scalars:

 say STDERR formatTable({ aa => "A", bb => "B", cc => "C" });
 # aa  A
 # bb  B
 # cc  C

=head1 Description

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Time stamps

Date and timestamps as used in logs of long running commands

=head2 dateTimeStamp()

Year-monthNumber-day at hours:minute:seconds


=head2 dateStamp()

Year-monthName-day


=head2 timeStamp()

hours:minute:seconds


=head1 Command execution

Various ways of processing commands

=head2 xxx(@)

Execute a command checking and logging the results: the command to execute is specified as one or more strings with optionally the last string being a regular expression that is used to confirm that the command executed successfully and thus that it is safe to suppress the command output as uninteresting.

  1  Parameter  Description
  2  @cmd       Command to execute followed by an optional regular expression to test the results

=head2 XXX($)

Execute a block of shell commands line by line after removing comments

  1  Parameter  Description
  2  $cmd       Commands to execute separated by new lines

=head2 zzz($$)

Execute lines of commands as one long command string separated by added &&'s and then check that the pipeline results in a return code of zero and that the execution results match the optional regular expression if one has been supplied; confess() to an error if either check fails.

  1  Parameter  Description
  2  $cmd       Commands to execute - one per line with no trailing &&
  3  $success   Optional regular expression to check the results

=head2 parseCommandLineArguments(&@)

Classify the specified array of words into positional parameters and keyword parameters, then call the specified sub with a reference to an array of positional parameters followed by a reference to a hash of keywords and their values and return the value returned by the sub

  1  Parameter  Description
  2  $sub       Sub to call
  3  @args      List of arguments to parse

=head1 Files and paths

Operations on files and paths

=head2 Statistics

Information about each file

=head3 fileSize($)

Get the size of a file.

  1  Parameter  Description
  2  $file      File name

=head3 fileModTime($)

Get the modified time of a file in seconds since the epoch.

  1  Parameter  Description
  2  $file      File name

=head3 fileOutOfDate(&$@)

Calls the specified sub once for each source file that is missing, then calls the sub for the target if there were any missing files or if the target is older than any of the non missing source files or if the target does not exist. The file name is passed to the sub each time in $_. Returns the files to be remade in the order they should be made.

  1  Parameter  Description
  2  $make      Make with this sub
  3  $target    Target file
  4  @source    Source files

Example:

  fileOutOfDate {make($_)}  $target, $source1, $source2, $source3;

=head2 Components

Create file names from file name components

=head3 filePath(@)

Create a file path from an array of file name components. If all the components are blank then a blank file name is returned.

  1  Parameter  Description
  2  @file      File components

=head3 filePathDir(@)

Directory from an array of file name components. If all the components are blank then a blank file name is returned.

  1  Parameter  Description
  2  @file      File components

=head3 filePathExt(@)

File name from file name components and extension.

  1  Parameter  Description
  2  @File      File components and extension

=head3 checkFile($)

Return the name of the specified file if it exists, else confess the maximum extent of the path that does exist.

  1  Parameter  Description
  2  $file      File to check

=head3 checkFilePath(@)

L<Check|/checkFile> a folder name constructed from its L<components|/filePath>

  1  Parameter  Description
  2  @file      File components

=head3 checkFilePathExt(@)

L<Check|/checkFile> a file name constructed from its  L<components|/filePathExt>

  1  Parameter  Description
  2  @File      File components and extension

=head3 checkFilePathDir(@)

L<Check|/checkFile> a folder name constructed from its L<components|/filePathDir>

  1  Parameter  Description
  2  @file      File components

=head3 quoteFile($)

Quote a file name.

  1  Parameter  Description
  2  $file      File name

=head3 removeFilePrefix($@)

Removes a file prefix from an array of files.

  1  Parameter  Description
  2  $prefix    File prefix
  3  @files     Array of file names

=head2 Position

Position in the file system

=head3 currentDirectory()

Get the current working directory.


=head3 currentDirectoryAbove()

The path to the folder above the current working folder.


=head3 parseFileName($)

Parse a file name into (path, name, extension)

  1  Parameter  Description
  2  $file      File name to parse

=head3 containingFolder($)

Path to the folder that contains this file, or use L</parseFileName>

  1  Parameter  Description
  2  $file      File name

=head3 fullFileName()

Full name of a file.


=head3 printFullFileName()

Print a file name on a separate line with escaping so it can be used easily from the command line.


=head2 Temporary

Temporary files and folders

=head3 temporaryFile()

Create a temporary file that will automatically be L<unlinked|/unlink> during END


=head3 temporaryFolder()

Create a temporary folder that will automatically be L<rmdired|/rmdir> during END


=head3 temporaryDirectory()

Create a temporary directory that will automatically be L<rmdired|/rmdir> during END


=head2 Find

Find files and folders below a folder.

=head3 findFiles($)

Find all the files under a folder.

  1  Parameter  Description
  2  $dir       Folder to start the search with

=head3 findDirs($)

Find all the folders under a folder.

  1  Parameter  Description
  2  $dir       Folder to start the search with

=head3 fileList($)

File list.

  1  Parameter  Description
  2  $pattern   Search pattern

=head3 searchDirectoryTreesForMatchingFiles(@)

Search the specified directory trees for files that match the specified extensions - the argument list should include at least one folder and one extension to be useful.

  1  Parameter              Description
  2  @foldersandExtensions  Mixture of folder names and extensions

=head3 matchPath($)

Given an absolute path find out how much of the path actually exists.

  1  Parameter  Description
  2  $file      File name

=head3 clearFolder($$)

Remove all the files and folders under and including the specified folder as long as the number of files to be removed is less than the specified limit.

  1  Parameter    Description
  2  $folder      Folder
  3  $limitCount  Maximum number of files to remove to limit damage

=head2 Read and write files

Read and write strings from and to files creating paths as needed

=head3 readFile($)

Read a file containing unicode.

  1  Parameter  Description
  2  $file      Name of unicode file to read

=head3 readBinaryFile($)

Read binary file - a file whose contents are not to be interpreted as unicode.

  1  Parameter  Description
  2  $file      File to read

=head3 makePath($)

Make the path for the specified file name or folder.

  1  Parameter  Description
  2  $file      File

=head3 writeFile($$)

Write a unicode string to a file after creating a path to the file if necessary.

  1  Parameter  Description
  2  $file      File to write to
  3  $string    Unicode string to write

=head3 appendFile($$)

Append a unicode string to a file after creating a path to the file if necessary.

  1  Parameter  Description
  2  $file      File to append to
  3  $string    Unicode string to append

=head3 writeBinaryFile($$)

Write a non unicode string to a file in after creating a path to the file if necessary.

  1  Parameter  Description
  2  $file      File to write to
  3  $string    Non unicode string to write

=head3 binModeAllUtf8()

Set STDOUT and STDERR to accept utf8 without complaint


=head1 Images

Image operations

=head2 imageSize($)

Return (width, height) of an image obtained via imagemagick.

  1  Parameter  Description
  2  $image     File containing image

=head2 convertImageToJpx($$$)

Convert an image to jpx format.

  1  Parameter  Description
  2  $source    Source file
  3  $target    Target folder (as multiple files will be created)
  4  $size      Size of each tile

=head1 Encoding and Decoding

Encode and decode using Json and Mime

=head2 encodeJson($)

Encode Perl to Json.

  1  Parameter  Description
  2  $string    Data to encode

=head2 decodeJson($)

Decode Perl from Json.

  1  Parameter  Description
  2  $string    Data to decode

=head2 encodeBase64($)

Encode a string in base 64.

  1  Parameter  Description
  2  $string    String to encode

=head2 decodeBase64($)

Decode a string in base 64.

  1  Parameter  Description
  2  $string    String to decode

=head2 convertUnicodeToXml($)

Convert a string with unicode points that are not directly representable in ascii into string that replaces these points with their representation on Xml making the string usable in Xml documents

  1  Parameter  Description
  2  $s         String to convert

=head1 Numbers

Numeric operations

=head2 powerOfTwo($)

Test whether a number is a power of two, return the power if it is else B<undef>

  1  Parameter  Description
  2  $n         Number to check

Use B<powerOfTwoX> to execute L<powerOfTwo|/powerOfTwo> but B<die> 'powerOfTwo' instead of returning B<undef>

=head2 containingPowerOfTwo($)

Find log two of the lowest power of two greater than or equal to a number.

  1  Parameter  Description
  2  $n         Number to check

Use B<containingPowerOfTwoX> to execute L<containingPowerOfTwo|/containingPowerOfTwo> but B<die> 'containingPowerOfTwo' instead of returning B<undef>

=head1 Sets

Set operations

=head2 setIntersectionOfTwoArraysOfWords($$)

Intersection of two arrays of words

  1  Parameter  Description
  2  $a         Reference to first array of words
  3  $b         Reference to second array of words

=head2 setUnionOfTwoArraysOfWords($$)

Union of two arrays of words

  1  Parameter  Description
  2  $a         Reference to first array of words
  3  $b         Reference to second array of words

=head2 contains($@)

Returns the indices at which an item matches elements of the specified array. If the item is a regular expression then it is matched as one, else it is a number it is matched as a number, else as a string.

  1  Parameter  Description
  2  $item      Item
  3  @array     Array

=head1 Minima and Maxima

Find the smallest and largest elements of arrays

=head2 min(@)

Find the minimum number in a list.

  1  Parameter  Description
  2  @n         Numbers

=head2 max(@)

Find the maximum number in a list.

  1  Parameter  Description
  2  @n         Numbers

=head1 Format

Format data structures as tables

=head2 formatTableBasic($$)

Tabularize text

  1  Parameter   Description
  2  $data       Reference to an array of arrays of data to be formatted as a table
  3  $separator  Optional line separator to use instead of new line for each row.

=head2 formatTable($$$)

Format various data structures as a table

  1  Parameter   Description
  2  $data       Data to be formatted
  3  $title      Optional reference to an array of titles
  4  $separator  Optional line separator

=head2 keyCount($$)

Count keys down to the specified level.

  1  Parameter  Description
  2  $maxDepth  Maximum depth to count to
  3  $ref       Reference to an array or a hash

=head1 Lines

Load data structures from lines

=head2 loadArrayFromLines($)

Load an array from lines of text in a string.

  1  Parameter  Description
  2  $string    The string of lines from which to create an array

=head2 loadHashFromLines($)

Load a hash: first word of each line is the key and the rest is the value.

  1  Parameter  Description
  2  $string    The string of lines from which to create a hash

=head2 loadArrayArrayFromLines($)

Load an array of arrays from lines of text: each line is an array of words.

  1  Parameter  Description
  2  $string    The string of lines from which to create an array of arrays

=head2 loadHashArrayFromLines($)

Load a hash of arrays from lines of text: the first word of each line is the key, the remaining words are the array contents.

  1  Parameter  Description
  2  $string    The string of lines from which to create a hash of arrays

=head2 checkKeys($$)

Check the keys in a hash.

  1  Parameter   Description
  2  $test       The hash to test
  3  $permitted  The permitted keys and their meanings

=head1 LVALUE methods

Replace $a->{value} = $b with $a->value = $b which reduces the amount of typing required, is easier to read and provides a hard check that {value} is spelt correctly.

=head2 genLValueScalarMethods(@)

Generate LVALUE scalar methods in the current package, A method whose value has not yet been set will return a new scalar with value undef. Suffixing B<X> to the scalar name will confess if a value has not been set.

  1  Parameter  Description
  2  @names     List of method names

Example:

   $a->value = 1;

=head2 genLValueScalarMethodsWithDefaultValues(@)

Generate LVALUE scalar methods with default values in the current package. A reference to a method whose value has not yet been set will return a scalar whose value is the name of the method.

  1  Parameter  Description
  2  @names     List of method names

Example:

   $a->value == qq(value);

=head2 genLValueArrayMethods(@)

Generate LVALUE array methods in the current package. A reference to a method that has no yet been set will return a reference to an empty array.

  1  Parameter  Description
  2  @names     List of method names

Example:

   $a->value->[1] = 2;

=head2 genLValueHashMethods(@)

Generate LVALUE hash methods in the current package. A reference to a method that has no yet been set will return a reference to an empty hash.

  1  Parameter  Description
  2  @names     Method names

Example:

   $a->value->{a} = 'b';

=head1 Strings

Actions on strings

=head2 indentString($$)

Indent lines contained in a string or formatted table by the specified string.

  1  Parameter  Description
  2  $string    The string of lines to indent
  3  $indent    The indenting string

=head2 isBlank($)

Test whether a string is blank.

  1  Parameter  Description
  2  $string    String

=head2 trim($)

Trim off white space from from front and end of string.

  1  Parameter  Description
  2  $string    String

=head2 pad($$)

Pad a string with blanks to a multiple of a specified length.

  1  Parameter  Description
  2  $string    String
  3  $length    Tab width

=head2 nws($)

Normalize white space in a string to make comparisons easier. Leading and trailing white space is removed; blocks of whitespace in the interior are reduced to a singe space.  In effect: this puts everything on one long line with never more than a space at a time.

  1  Parameter  Description
  2  $string    String to normalize

=head2 javaPackage($)

Extract the package name from a java string or file.

  1  Parameter  Description
  2  $java      Java file if it exists else the string of java

=head2 javaPackageAsFileName($)

Extract the package name from a java string or file and convert it to a file name.

  1  Parameter  Description
  2  $java      Java file if it exists else the string of java

=head2 perlPackage($)

Extract the package name from a perl string or file.

  1  Parameter  Description
  2  $perl      Perl file if it exists else the string of perl

=head1 Cloud Cover

Useful for operating across the cloud

=head2 addCertificate($)

Add a certificate to the current ssh session.

  1  Parameter  Description
  2  $file      File containing certificate

=head2 hostName()

The name of the host we are running on


=head2 userId()

The userid we are currently running under


=head1 Documentation

Extract, format and update documentation for a perl module

=head2 updateDocumentation($)

Update documentation from a perl script between the lines marked with:

  #n title # description

and:

  #...

where n is either 1, 2 or 3 indicating the heading level of the section and the # is in column 1.

Methods are formatted as:

  sub name(signature)      #FLAGS comment describing method
   {my ($parameters) = @_; # comments for each parameter separated by commas.

FLAGS can be any combination of:

=over

=item I

method of interest to new users

=item P

private method

=item S

static method

=item X

die rather than received a returned B<undef> result

=back

Other flags will be handed to the method extractDocumentationFlags(flags to process, method name) found in the file being documented, this method should return [the additional documentation for the method, the code to implement the flag].

Text following 'Example:' in the comment (if present) will be placed after the parameters list as an example. Lines containing comments consisting of '#T'.methodName will also be aggregated as an example.

Lines formatted as:

  #C emailAddress text

will be aggregated in the acknowledgments section at the end of the documentation.

The character sequence \n in the comment will be expanded to one new line and \m to two new lines.

Search for '#1': in L<https://metacpan.org/source/PRBRENAN/Data-Table-Text-20170728/lib/Data/Table/Text.pm>  to see examples.

Parameters:


  1  Parameter    Description
  2  $perlModule  Optional file name with caller's file being the default


=head1 Private Methods

=head2 denormalizeFolderName($)

Remove any trailing folder separator from a folder name component.

  1  Parameter  Description
  2  $name      Name

=head2 renormalizeFolderName($)

Normalize a folder name component by adding a trailing separator.

  1  Parameter  Description
  2  $name      Name

=head2 formatTableAA($$$)

Tabularize an array of arrays.

  1  Parameter   Description
  2  $data       Data to be formatted
  3  $title      Optional title
  4  $separator  Optional line separator

=head2 formatTableHA($$$)

Tabularize a hash of arrays.

  1  Parameter   Description
  2  $data       Data to be formatted
  3  $title      Optional title
  4  $separator  Optional line separator

=head2 formatTableAH($$$)

Tabularize an array of hashes.

  1  Parameter   Description
  2  $data       Data to be formatted
  3  $title      Optional title
  4  $separator  Optional line separator

=head2 formatTableHH($$$)

Tabularize a hash of hashes.

  1  Parameter   Description
  2  $data       Data to be formatted
  3  $title      Optional title
  4  $separator  Optional line separator

=head2 formatTableA($$$)

Tabularize an array.

  1  Parameter   Description
  2  $data       Data to be formatted
  3  $title      Optional title
  4  $separator  Optional line separator

=head2 formatTableH($$$)

Tabularize a hash.

  1  Parameter   Description
  2  $data       Data to be formatted
  3  $title      Optional title
  4  $separator  Optional line separator

=head2 extractTest($)

Extract a line of a test.

  1  Parameter  Description
  2  $string    String containing test line


=head1 Index


1 L<addCertificate|/addCertificate>

2 L<appendFile|/appendFile>

3 L<binModeAllUtf8|/binModeAllUtf8>

4 L<checkFile|/checkFile>

5 L<checkFilePath|/checkFilePath>

6 L<checkFilePathDir|/checkFilePathDir>

7 L<checkFilePathExt|/checkFilePathExt>

8 L<checkKeys|/checkKeys>

9 L<clearFolder|/clearFolder>

10 L<containingFolder|/containingFolder>

11 L<containingPowerOfTwo|/containingPowerOfTwo>

12 L<containingPowerOfTwoX|/containingPowerOfTwo>

13 L<contains|/contains>

14 L<convertImageToJpx|/convertImageToJpx>

15 L<convertUnicodeToXml|/convertUnicodeToXml>

16 L<currentDirectory|/currentDirectory>

17 L<currentDirectoryAbove|/currentDirectoryAbove>

18 L<dateStamp|/dateStamp>

19 L<dateTimeStamp|/dateTimeStamp>

20 L<decodeBase64|/decodeBase64>

21 L<decodeJson|/decodeJson>

22 L<denormalizeFolderName|/denormalizeFolderName>

23 L<encodeBase64|/encodeBase64>

24 L<encodeJson|/encodeJson>

25 L<extractTest|/extractTest>

26 L<fileList|/fileList>

27 L<fileModTime|/fileModTime>

28 L<fileOutOfDate|/fileOutOfDate>

29 L<filePath|/filePath>

30 L<filePathDir|/filePathDir>

31 L<filePathExt|/filePathExt>

32 L<fileSize|/fileSize>

33 L<findDirs|/findDirs>

34 L<findFiles|/findFiles>

35 L<formatTable|/formatTable>

36 L<formatTableA|/formatTableA>

37 L<formatTableAA|/formatTableAA>

38 L<formatTableAH|/formatTableAH>

39 L<formatTableBasic|/formatTableBasic>

40 L<formatTableH|/formatTableH>

41 L<formatTableHA|/formatTableHA>

42 L<formatTableHH|/formatTableHH>

43 L<fullFileName|/fullFileName>

44 L<genLValueArrayMethods|/genLValueArrayMethods>

45 L<genLValueHashMethods|/genLValueHashMethods>

46 L<genLValueScalarMethods|/genLValueScalarMethods>

47 L<genLValueScalarMethodsWithDefaultValues|/genLValueScalarMethodsWithDefaultValues>

48 L<hostName|/hostName>

49 L<imageSize|/imageSize>

50 L<indentString|/indentString>

51 L<isBlank|/isBlank>

52 L<javaPackage|/javaPackage>

53 L<javaPackageAsFileName|/javaPackageAsFileName>

54 L<keyCount|/keyCount>

55 L<loadArrayArrayFromLines|/loadArrayArrayFromLines>

56 L<loadArrayFromLines|/loadArrayFromLines>

57 L<loadHashArrayFromLines|/loadHashArrayFromLines>

58 L<loadHashFromLines|/loadHashFromLines>

59 L<makePath|/makePath>

60 L<matchPath|/matchPath>

61 L<max|/max>

62 L<min|/min>

63 L<nws|/nws>

64 L<pad|/pad>

65 L<parseCommandLineArguments|/parseCommandLineArguments>

66 L<parseFileName|/parseFileName>

67 L<perlPackage|/perlPackage>

68 L<powerOfTwo|/powerOfTwo>

69 L<powerOfTwoX|/powerOfTwo>

70 L<printFullFileName|/printFullFileName>

71 L<quoteFile|/quoteFile>

72 L<readBinaryFile|/readBinaryFile>

73 L<readFile|/readFile>

74 L<removeFilePrefix|/removeFilePrefix>

75 L<renormalizeFolderName|/renormalizeFolderName>

76 L<searchDirectoryTreesForMatchingFiles|/searchDirectoryTreesForMatchingFiles>

77 L<setIntersectionOfTwoArraysOfWords|/setIntersectionOfTwoArraysOfWords>

78 L<setUnionOfTwoArraysOfWords|/setUnionOfTwoArraysOfWords>

79 L<temporaryDirectory|/temporaryDirectory>

80 L<temporaryFile|/temporaryFile>

81 L<temporaryFolder|/temporaryFolder>

82 L<timeStamp|/timeStamp>

83 L<trim|/trim>

84 L<updateDocumentation|/updateDocumentation>

85 L<userId|/userId>

86 L<writeBinaryFile|/writeBinaryFile>

87 L<writeFile|/writeFile>

88 L<xxx|/xxx>

89 L<XXX|/XXX>

90 L<zzz|/zzz>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read, use,
modify and install.

Standard L<Module::Build> process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.


=head1 Acknowledgements

Thanks to the following people for their help with this module:

=over


=item L<mim@cpan.org|mailto:mim@cpan.org>

Testing on windows


=back


=cut


sub containingPowerOfTwoX  {&containingPowerOfTwo  (@_) || die 'containingPowerOfTwo'}
sub powerOfTwoX            {&powerOfTwo            (@_) || die 'powerOfTwo'}


# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
 }

test unless caller;

1;
# podDocumentation
__DATA__
use Test::More tests => 121;

#Test::More->builder->output("/dev/null");

if (1)                                                                          # Unicode to local file
 {use utf8;
  my $z = "𝝰 𝝱 𝝲";
  my $t = temporaryFolder;
  my $f = filePathExt($t, $z, qq(data));
  unlink $f if -e $f;
  ok !-e $f, $f;
  writeFile($f, $z);
  ok  -e $f, $f;
  my $s = readFile($f);
  ok $s eq $z;
  ok length($s) == length($z);
  unlink $f;
  ok !-e $f,    "unlink $f";
  rmdir $t;
  ok !-d $t,    "rmDir $t";
 }

if (1)                                                                          # Key counts
 {my $a = [[1..3],       {map{$_=>1} 1..3}];
  my $h = {a=>[1..3], b=>{map{$_=>1} 1..3}};
  ok keyCount(2, $a) == 6;
  ok keyCount(2, $h) == 6;
 }

if (1)                                                                          # File paths
 {ok filePath   (qw(/aaa bbb ccc ddd.eee)) eq "/aaa/bbb/ccc/ddd.eee";
  ok filePathDir(qw(/aaa bbb ccc ddd))     eq "/aaa/bbb/ccc/ddd/";
  ok filePathDir('', qw(aaa))              eq "aaa/";
  ok filePathDir('')                       eq "";
  ok filePathExt(qw(aaa xxx))              eq "aaa.xxx";
  ok filePathExt(qw(aaa bbb xxx))          eq "aaa/bbb.xxx";
 }

if (1)                                                                          # Parse file names
 {is_deeply [parseFileName "/home/phil/test.data"], ["/home/phil/", "test", "data"];
  is_deeply [parseFileName "/home/phil/test"],      ["/home/phil/", "test"];
  is_deeply [parseFileName "phil/test.data"],       ["phil/",       "test", "data"];
  is_deeply [parseFileName "phil/test"],            ["phil/",       "test"];
  is_deeply [parseFileName "test.data"],            [undef,         "test", "data"];
 }

if (1)                                                                          # Unicode
 {use utf8;
  my $z = "𝝰 𝝱 𝝲";
  my $T = temporaryFolder;
  my $t = filePath($T, $z);
  my $f = filePathExt($t, $z, qq(data));
  unlink $f if -e $f;
  ok !-e $f, $f;
  writeFile($f, $z);
  ok  -e $f, $f;
  my $s = readFile($f);
  ok $s eq $z;
  ok length($s) == length($z);
  unlink $f;
  ok !-e $f, $f;
  rmdir $t;
  ok !-d $t, $t;
  rmdir $T;
  ok !-d $T, $T;
 }

if (1)                                                                          # Binary
 {my $z = "𝝰 𝝱 𝝲";
  my $Z = join '', map {chr($_)} 0..11;
  my $T = temporaryFolder;
  my $t = filePath($T, $z);
  my $f = filePathExt($t, $z, qq(data));
  unlink $f if -e $f;
  ok !-e $f, $f;
  writeBinaryFile($f, $Z);
  ok  -e $f, $f;
  my $s = readBinaryFile($f);
  ok $s eq $Z;
  ok length($s) == 12;
  unlink $f;
  ok !-e $f, $f;
  rmdir $t;
  ok !-d $t, $t;
  rmdir $T;
  ok !-d $T, $T;
 }

if (1)                                                                          # Check files
 {my @d =             qw(a b c d);
  my $d = filePath   (qw(a b c d));
  my $f = filePathExt(qw(a b c d e x));
  my $F = filePathExt(qw(a b c e d));
  writeFile($f, '1');
  ok checkFile($d), $d;
  ok checkFile($f), $f;
  eval {checkFile($F)};
  my @m = split m/\n/, $@;
  ok $m[1] eq  "a/b/c";
  unlink $f;
  ok !-e $f, $f;
  while(@d)                                                                     # Remove path
   {my $d = filePathDir(@d);
    rmdir $d;
    ok !-e $d, $d;
    pop @d;
   }
 }

if (1)                                                                          # Clear folder
 {my $d = 'a';
  my @d = qw(a b c d);
  my @D = @d;
  while(@D)
   {my $f = filePathExt(@D, qw(test data));
    writeFile($f, '1');
    pop @D;
   }
  ok findFiles($d) == 4;
  eval {clearFolder($d, 3)};
  ok $@ =~ m(\ALimit is 3, but 4 files under folder:)s;
  clearFolder($d, 4);
  ok !-e $d;
 }

if (1)                                                                          # Format table and AA
 {my $t = [qw(aa bb cc)];
  my $d = [[qw(A   B   C)],
           [qw(AA  BB  CC)],
           [qw(AAA BBB CCC)],
           [qw(1   22  333)]];
  ok formatTableBasic($d,     '|') eq                       'A    B    C    |AA   BB   CC   |AAA  BBB  CCC  |  1   22  333  |';
  ok formatTable     ($d, $t, '|') eq '   aa   bb   cc   |1  A    B    C    |2  AA   BB   CC   |3  AAA  BBB  CCC  |4    1   22  333  |';
 }

if (1)                                                                          # AH
 {my $d = [{aa=>'A', bb=>'B', cc=>'C'},
           {aa=>'AA', bb=>'BB', cc=>'CC'},
           {aa=>'AAA', bb=>'BBB', cc=>'CCC'},
           {aa=>'1', bb=>'22', cc=>'333'}
          ];
  ok formatTable($d, undef, '|') eq '   aa   bb   cc   |1  A    B    C    |2  AA   BB   CC   |3  AAA  BBB  CCC  |4    1   22  333  |';
 }

if (1)                                                                          # HA
 {my $d = {''=>[qw(aa bb cc)], 1=>[qw(A B C)], 22=>[qw(AA BB CC)], 333=>[qw(AAA BBB CCC)],  4444=>[qw(1 22 333)]};
  ok formatTable($d, undef, '|') eq '      aa   bb   cc   |   1  A    B    C    |  22  AA   BB   CC   | 333  AAA  BBB  CCC  |4444    1   22  333  |';
 }

if (1)                                                                          # HH
 {my $d = {a=>{aa=>'A', bb=>'B', cc=>'C'}, aa=>{aa=>'AA', bb=>'BB', cc=>'CC'}, aaa=>{aa=>'AAA', bb=>'BBB', cc=>'CCC'}, aaaa=>{aa=>'1', bb=>'22', cc=>'333'}};
  ok formatTable($d, undef, '|') eq '      aa   bb   cc   |a     A    B    C    |aa    AA   BB   CC   |aaa   AAA  BBB  CCC  |aaaa    1   22  333  |';
 }

if (1)                                                                          # A
 {my $d = [qw(a bb ccc 4444)];
  ok formatTable($d, undef, '|') eq '0  a     |1  bb    |2  ccc   |3  4444  |';
 }

if (1)                                                                          # H
 {my $d = {aa=>'A', bb=>'B', cc=>'C'};
  ok formatTable($d, undef, '|') eq 'aa  A  |bb  B  |cc  C  |';
 }

if (1)                                                                          # CheckKeys, nsw
 {eval {checkKeys({qw(go 1 Went 2 gone 3)},
                  {qw(go present went past gone presentPast)})};
  my $s = $@;
     $s =~ s/\s*at.*\Z//s;
     $s =~ s/\n/|/g;
  my $S = 'Invalid options chosen:|  Went  ||Permitted options are:|  go    present      |  gone  presentPast  |  went  past         ';
  ok nws($s) eq nws($S);
 }

if (1)                                                                          # AL
 {my $s = loadArrayFromLines <<END;
a a
b b
END
  ok dump($s) eq '["a a", "b b"]';
 }

if (1)                                                                          # HL
 {my $s = loadHashFromLines <<END;
a 10 11 12
b 20 21 22
END
  ok dump($s) eq '{ a => "10 11 12", b => "20 21 22" }';
 }

if (1)                                                                          # AAL
 {my $s = loadArrayArrayFromLines <<END;
A B C
AA BB CC
END
  ok dump($s) eq '[["A", "B", "C"], ["AA", "BB", "CC"]]';
 }

if (1)                                                                          # HAL
 {my $s = loadHashArrayFromLines <<END;
a A B C
b AA BB CC
END
  ok dump($s) eq '{ a => ["A", "B", "C"], b => ["AA", "BB", "CC"] }';
 }

if (1)                                                                          # SM
 {package Scalars;
  my $a = bless{};
  Data::Table::Text::genLValueScalarMethods(qw(aa bb cc));
  $a->aa = 'aa';
  Test::More::ok  $a->aa eq 'aa';
  Test::More::ok !$a->bb;
  eval {$a->bbX};
  Test::More::ok $@ =~ m(\ANo value supplied for "bb")s;
 }

if (1)                                                                          # SM
 {package ScalarsWithDefaults;
  my $a = bless{};
  Data::Table::Text::genLValueScalarMethodsWithDefaultValues(qw(aa bb cc));
  Test::More::ok $a->aa eq 'aa';
 }

if (1)                                                                          # AM
 {package Arrays;
  my $a = bless{};
  Data::Table::Text::genLValueArrayMethods(qw(aa bb cc));
  $a->aa->[1] = 'aa';
  Test::More::ok $a->aa->[1] eq 'aa';
 }

if (1)                                                                          # AM
 {package Hashes;
  my $a = bless{};
  Data::Table::Text::genLValueHashMethods(qw(aa bb cc));
  $a->aa->{a} = 'aa';
  Test::More::ok $a->aa->{a} eq 'aa';
 }

if (1)                                                                          # indentString
 {my $t = [qw(aa bb cc)];
  my $d = [[qw(A B C)], [qw(AA BB CC)], [qw(AAA BBB CCC)],  [qw(1 22 333)]];
  my $s = indentString(formatTable($d), '  ') =~ s/\n/|/gr;
  ok $s eq "  1  A    B    C    |  2  AA   BB   CC   |  3  AAA  BBB  CCC  |  4    1   22  333  ", "indent";
 }

ok trim(" a b ") eq join ' ', qw(a b);                                          # Trim
ok isBlank("");                                                                 # isBlank
ok isBlank(" \n ");

ok  powerOfTwo(1) == 0;                                                         # Power of two
ok  powerOfTwo(2) == 1;
ok !powerOfTwo(3);
ok  powerOfTwo(4) == 2;

ok  containingPowerOfTwo(1) == 0;                                               # Containing power of two
ok  containingPowerOfTwo(2) == 1;
ok  containingPowerOfTwo(3) == 2;
ok  containingPowerOfTwo(4) == 2;
ok  containingPowerOfTwo(5) == 3;
ok  containingPowerOfTwo(7) == 3;

ok  pad('abc  ', 2).'=' eq "abc =";
ok  pad('abc  ', 3).'=' eq "abc=";
ok  pad('abc  ', 4).'=' eq "abc =";
ok  pad('abc  ', 5).'=' eq "abc  =";
ok  pad('abc  ', 6).'=' eq "abc   =";

ok containingFolder("/home/phil/test.data") eq "/home/phil/";
ok containingFolder("phil/test.data")       eq "phil/";
ok containingFolder("test.data")            eq "./";

if (1)
 {my $f = temporaryFile;
  writeFile($f, <<END);
// Test
package com.xyz;
END
  ok javaPackage($f) eq "com.xyz", $f;
  ok javaPackageAsFileName($f) eq "com/xyz";
  unlink $f;
 }

if ($^O !~ m/\AMSWin32\Z/)                                                      # Ignore windows for this test
 {ok xxx("echo aaa")       =~ /aaa/;
  ok xxx("a=bbb;echo \$a") =~ /bbb/;

  eval {xxx "echo ccc", qr(ccc)};
  ok !$@, "ccc $@";

  eval {xxx "echo ddd", qr(eee)};
  ok $@ =~ /ddd/, "ddd";
 }
else
 {ok 1 for 1..4;
 }

if (1)
 {my $a = {a=>1,b=>2, c=>[1..2]};
  my $A = encodeJson($a);
  my $b = decodeJson($A);
  is_deeply $a, $b, "json $A";
 }

if (1)
 {my $a = "Hello World" x 10;
  my $A = encodeBase64($a);
  my $B = $A =~ s([\n# ]) ()gsr;
  my $b = decodeBase64($B);
  ok $a eq $b, "Mime $B";
  ok $a eq $b, "$b";
 }

ok !max;
ok max(1) == 1;
ok max(1,4,2,3) == 4;

ok min(1) == 1;
ok min(5,4,2,3) == 2;

is_deeply [1],       [contains(1,0..1)];
is_deeply [1,3],     [contains(1, qw(0 1 0 1 0 0))];
is_deeply [0, 5],    [contains('a', qw(a b c d e a b c d e))];
is_deeply [0, 1, 5], [contains(qr(a+), qw(a baa c d e aa b c d e))];

is_deeply [qw(a b)], [&removeFilePrefix(qw(a/ a/a a/b))];

if (0)                                                                          # fileOutOfDate
 {my @Files = qw(a b c);
  my @files = (@Files, qw(d));
  writeFile($_, $_), sleep 1 for @Files;

  my $a = '';
  my @a = fileOutOfDate {$a .= $_} q(a), @files;
  ok $a eq 'da', "outOfDate a";
  is_deeply [@a], [qw(d a)];

  my $b = '';
  my @b = fileOutOfDate {$b .= $_} q(b), @files;
  ok $b eq 'db', "outOfDate b";
  is_deeply [@b], [qw(d b)];

  my $c = '';
  my @c = fileOutOfDate {$c .= $_} q(c), @files;
  ok $c eq 'dc', "outOfDate c";
  is_deeply [@c], [qw(d c)];

  my $d = '';
  my @d = fileOutOfDate {$d .= $_} q(d), @files;
  ok $d eq 'd', "outOfDate d";
  is_deeply [@d], [qw(d)];

  my @A = fileOutOfDate {} q(a), @Files;
  my @B = fileOutOfDate {} q(b), @Files;
  my @C = fileOutOfDate {} q(c), @Files;
  is_deeply [@A], [qw(a)], 'aaa';
  is_deeply [@B], [qw(b)], 'bbb';
  is_deeply [@C], [],      'ccc';
  unlink for @Files;
 }
else
 { SKIP:
   {skip "Takes too much time", 11;
   }
 }

ok convertUnicodeToXml('setenta e três') eq "setenta e tr&#234;s";

ok zzz(<<END, qr(aaa\s*bbb)s);
echo aaa
echo bbb
END

if (1)                                                                          # Failure
 {eval {zzz(<<END, qr(SUCCESS)s)};
echo aaa
echo bbb
END
  ok $@ =~ m(Data::Table::Text::zzz)s;
 }

if (1)
 {my $r = parseCommandLineArguments {[@_]}
   (qw( aaa bbb -c --dd --eee=EEEE -f=F), q(--gg=g g), q(--hh=h h));
  is_deeply $r,
    [["aaa", "bbb"],
     {c=>undef, dd=>undef, eee=>"EEEE", f=>"F", gg=>"g g", hh=>"h h"},
    ];
 }

is_deeply [qw(a b c)],
  [setIntersectionOfTwoArraysOfWords([qw(e f g a b c )], [qw(a A b B c C)])];

is_deeply [qw(a b c)],
  [setUnionOfTwoArraysOfWords([qw(a b c )], [qw(a b)])];

ok printQw(qw(a  b  c)) eq "qw(a b c)";
