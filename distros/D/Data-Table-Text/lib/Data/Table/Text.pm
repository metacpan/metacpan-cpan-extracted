#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Write data in tabular text format
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2016-2017
#-------------------------------------------------------------------------------
# podDocumentation

package Data::Table::Text;
use v5.16.0;
our $VERSION = '20170824';
use warnings FATAL => qw(all);
use strict;
use Carp;
use Cwd;
use File::Path qw(make_path);
use File::Glob qw(:bsd_glob);
use File::Temp qw(tempfile tempdir);
use POSIX qw(strftime);                                                         # http://www.cplusplus.com/reference/ctime/strftime/
use Data::Dump qw(dump);
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

sub xxx(@)                                                                      # Execute a command checking and logging the results: the command to execute is specified as one or more strings with optionally the last string being a regular expression that is used to confirm that the command executed successfully and thus that it is safe to suppress the command output as uninteresting.
 {my (@cmd) = @_;                                                               # Command to execute followed by an optional regular expression to test the results
  @cmd or confess "No command";                                                 # Check that there is a command to execute
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

#1 Files and paths                                                              # Operations on files and paths
#2 Statistics                                                                   # Information about each file

sub fileSize($)                                                                 # Get the size of a file
 {my ($file) = @_;                                                              # File name
  (stat($file))[7]
 }

sub fileModTime($)                                                              # Get the modified time of a file in seconds since the epoch
 {my ($file) = @_;                                                              # File name
  (stat($file))[9] // 0
 }

sub fileOutOfDate($@)                                                           #X Returns undef if all the files exist and the first file is younger than all the following files; else returns the first file that does not exist or is younger than the first file. Example: make($target) if fileOutOfDate($target, $source1, $source2, $source3)
 {my ($target, @sources) = @_;                                                  # Target, sources
  return $target unless -e $target;                                             # Out of date if target does not exist
  my $t = fileModTime($target);                                                 # Time of target
  for(@sources)                                                                 # Each source
   {return $_ unless -e $_;                                                     # Out of date if source does not exist
    my $T = fileModTime($_);                                                    # Time of source
    return $_ if $T > $t;                                                       # Out of date if source newer than target
   }
  undef                                                                         # Not out of date as target and all sources files exist and target was created later than all of the sources
 }

#2 Components                                                                   # Create file names from file name components

sub denormalizeFolderName($)                                                    #P Remove any trailing folder separator from a folder name component
 {my ($name) = @_;                                                              # Name
  $name =~ s([\/\\]+\Z) ()gsr;
 }

sub renormalizeFolderName($)                                                    #P Normalize a folder name component by adding a trailing separator
 {my ($name) = @_;                                                              # Name
  ($name =~ s([\/\\]+\Z) ()gsr).'/';
 }

sub filePath(@)                                                                 # Create a file path from an array of file name components. If all the components are blank then a blank file name is returned
 {my (@file) = @_;                                                              # File components
  defined($_) or confess "Missing file component\n" for @file;                  # Check that there are no undefined file components
  my @c = grep {$_} map {denormalizeFolderName($_)} @file;                      # Skip blank components
  return '' unless @c;                                                          # No components resolves to '' rather than '/'
  join '/', @c;                                                                 # Separate components
 }

sub filePathDir(@)                                                              # Directory from an array of file name components. If all the components are blank then a blank file name is returned
 {my (@file) = @_;                                                              # File components
  my $f = filePath(@_);
  return '' unless $f;                                                          # No components resolves to '' rather than '/'
  renormalizeFolderName($f)                                                     # Normalize with trailing separator
 }

sub filePathExt(@)                                                              # File name from file name components and extension
 {my (@File) = @_;                                                              # File components and extension
  my @file = grep{$_} @_;                                                       # Remove undefined and blank components
  @file > 1 or confess "At least two non blank file name components required";
  my $x = pop @file;
  my $n = pop @file;
  my $f = "$n.$x";
  return $f unless @file;
  filePath(@file, $f)
 }

sub checkFile($)                                                                # Return the name of the specified file if it exists, else confess the maximum extent of the path that does exist.
 {my ($file) = @_;                                                              # File to check
  unless(-e $file)
   {confess "Can only find the prefix (below) of the file (further below):\n".
      matchPath($file)."\n$file\n";
   }
  $file
 }

sub checkFilePath(@)                                                            # L<Check|/checkFile> a folder name constructed from its L<components|/filePath>.
 {my (@file) = @_;                                                              # File components
  checkFile(filePath(@_))                                                       # Return the constructed file name if it exists
 }

sub checkFilePathExt(@)                                                         # L<Check|/checkFile> a file name constructed from its  L<components|/filePathExt>.
 {my (@File) = @_;                                                              # File components and extension
  checkFile(filePathExt(@_))                                                    # Return the constructed file name if it exists
 }

sub checkFilePathDir(@)                                                         # L<Check|/checkFile> a folder name constructed from its L<components|/filePathDir>.
 {my (@file) = @_;                                                              # File components
  checkFile(filePathDir(@_))                                                    # Return the constructed folder name if it exists
 }

sub quoteFile($)                                                                # Quote a file name
 {my ($file) = @_;                                                              # File name
  "\"$file\""
 }

#2 Position                                                                     # Position in the file system

sub currentDirectory                                                            # Get the current working directory
 {renormalizeFolderName(getcwd)
 }

sub currentDirectoryAbove                                                       # The path to the folder above the current working folder
 {my $p = currentDirectory;
  my @p = split m(/)s, $p;
  shift @p if @p and $p[0] =~ m/\A\s*\Z/;
  @p or confess "No directory above\n:".currentDirectory;
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

sub fullFileName                                                                # Full name of a file
 {my ($file) = @_;                                                              # File name
  filePath(currentDirectory, $file)                                             # Full file name
 }

sub printFullFileName                                                           # Print a file name on a separate line with escaping so it can be use easily from the command line
 {my ($file) = @_;                                                              # File name
  "\n\'".dump(fullFileName($file))."\'\n'"
 }

#2 Temporary                                                                    # Temporary files and folders

sub temporaryFile                                                               # Create a temporary file that will automatically be L<unlinked|/unlink> during END
 {tempfile()
 }

sub temporaryFolder                                                             # Create a temporary folder that will automatically be L<rmdired|/rmdir> during END
 {my $d = tempdir();
     $d =~ s/[\/\\]+\Z//s;
  $d.'/';
 }

sub temporaryDirectory                                                          # Create a temporary directory that will automatically be L<rmdired|/rmdir> during END
 {temporaryFolder
 }

#2 Find                                                                         # Find files and folders below a folder

sub findFiles($)                                                                # Find all the file under a folder
 {my ($dir) = @_;                                                               # Folder to start the search with
  my @f;
  for(split /\0/, qx(find $dir -print0))
   {next if -d $_;                                                              # Do not include folder names
    push @f, $_;
   }
  @f
 }

sub findDirs($)                                                                 # Find all the folders under a folder
 {my ($dir) = @_;                                                               # Folder to start the search with
  my @d;
  for(split /\0/, qx(find $dir -print0))
   {next unless -d $_;                                                          # Include only folders
    push @d, $_;
   }
  @d
 }

sub fileList($)                                                                 # File list
 {my ($pattern) = @_;                                                           # Search pattern
  bsd_glob($pattern, GLOB_MARK | GLOB_TILDE)
 }

sub searchDirectoryTreesForMatchingFiles(@)                                     # Search the specified directory trees for files that match the specified extensions -  the argument list should include at least one folder and one extension to be useful
 {my (@foldersandExtensions) = @_;                                              # Mixture of folder names and extensions
  my @folder     = grep { -d $_ } @_;                                           # Folders
  my @extensions = grep {!-d $_ } @_;                                           # Extensions
  my @f;                                                                        # Files
  for my $dir(@folder)                                                          # Directory
   {for my $ext(@extensions)                                                    # Extensions
     {push @f, fileList(filePathExt($dir, qq(*), $ext));                        # Record files that match
     }
   }
  sort @f
 } # searchDirectoryTreesForMatchingFiles

sub matchPath($)                                                                # Given an absolute path find out how much of the path exists
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

#2 Read and write files                                                         # Read and write strings from and to files creating paths as needed

sub readFile($)                                                                 # Read a file containing unicode
 {my ($file) = @_;                                                              # Name of unicode file to read
  my $f = $file;
  defined($f) or confess "Cannot read undefined file";
  $f =~ m(\n) and confess "File name contains a new line:\n=$file=";
  -e $f or confess "Cannot read file because it does not exist, file:\n$f\n";
  open(my $F, "<:encoding(UTF-8)", $f) or confess
    "Cannot open $f for unicode input";
  local $/ = undef;
  my $s = eval {<$F>};
  $@ and confess $@;
  $s
 }

sub readBinaryFile($)                                                           # Read binary file - a file whose contents are not to be interpreted as unicode
 {my ($file) = @_;                                                              # File to read
  my $f = $file;
  -e $f or confess "Cannot read binary file $f because it does not exist";
  open my $F, "<$f" or confess "Cannot open binary file $f for input";
  local $/ = undef;
  <$F>;
 }

sub makePath($)                                                                 # Make a path for a file name or a folder
 {my ($path) = @_;                                                              # Path
  my @p = split /[\\\/]+/, $path;
  return 1 unless @p > 1;
  pop @p unless $path =~ /[\\\/]\Z/;
  my $p = join '/', @p;
  return 2 if -d $p;
  eval {make_path($p)};
  -d $p or confess "Cannot makePath $p";
  0
 }

sub writeFile($$)                                                               # Write a unicode string to a file after creating a path to the file if necessary
 {my ($file, $string) = @_;                                                     # File to write to, unicode string to write
  $file or confess "No file name supplied";
  $string or carp "No string for file $file";
  makePath($file);
  open my $F, ">$file" or confess "Cannot open $file for write";
  binmode($F, ":utf8");
  print  {$F} $string;
  close  ($F);
  -e $file or confess "Failed to write to file $file";
 }

sub appendFile($$)                                                              # Append a unicode string to a file after creating a path to the file if necessary
 {my ($file, $string) = @_;                                                     # File to append to, unicode string to append
  $file or confess "No file name supplied";
  $string or carp "No string for file $file";
  makePath($file);
  open my $F, ">>$file" or confess "Cannot open $file for write";
  binmode($F, ":utf8");
  print  {$F} $string;
  close  ($F);
  -e $file or confess "Failed to write to file $file";
 }

sub writeBinaryFile($$)                                                         # Write a non unicode string to a file in after creating a path to the file if necessary
 {my ($file, $string) = @_;                                                     # File to write to, non unicode string to write
  $file or confess "No file name supplied";
  $string or confess "No string for file $file";
  makePath($file);
  open my $F, ">$file" or confess "Cannot open $file for binary write";
  binmode($F);
  print  {$F} $string;
  close  ($F);
  -e $file or confess "Failed to write in binary to file $file";
 }

#1 Images                                                                       # Image operations
sub imageSize($)                                                                # Return (width, height) of an image obtained via imagemagick
 {my ($image) = @_;                                                             # File containing image
  -e $image or confess "Cannot get size of image $image as file does not exist";
  my $s = qx(identify -verbose "$image");
  if ($s =~ /Geometry: (\d+)x(\d+)/s)
   {return ($1, $2);
   }
  else
   {confess "Cannot get image size for $image from:\n$s";
   }
 }

sub convertImageToJpx($$$)                                                      # Convert an image to jpx format
 {my ($source, $target, $size) = @_;                                            # Source file, target folder (as multiple files will be created),  size of each tile
  -e $source or confess
   "convertImageJpx: cannot convert image file $source, as file does not exist";
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
        rename $s, $t or confess "Cannot rename $s to $t";
        -e $t or confess "Cannot create $t";
        ++$k;
       }
     }
   }
 }

#1 Powers                                                                       # Integer powers of two

sub powerOfTwo($)                                                               #X Test whether a number is a power of two, return the power if it is else undef
 {my ($n) = @_;                                                                 # Number to check
  for(0..128)
   {return $_  if 1<<$_ == $n;
    last       if 1<<$_ >  $n;
   }
  undef
 }

sub containingPowerOfTwo($)                                                     #X Find log two of the lowest power of two greater than or equal to a number
 {my ($n) = @_;                                                                 # Number to check
  for(0..128)
   {return $_  if $n <= 1<<$_;
   }
  undef
 }

#1 Format                                                                       # Format data structures as tables
sub formatTableBasic($;$)                                                       # Tabularize text - basic version
 {my ($data, $separator) = @_;                                                  # Data to be formatted, optional line separator
  my $d = $data;
  ref($d) =~ /array/i or confess "Array reference required";
  my @D;
  for   my $e(@$d)
   {ref($e) =~ /array/i or confess "Array reference required";
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

sub formatTableAA($;$$)                                                         #P Tabularize an array of arrays
 {my ($data, $title, $separator) = @_;                                          # Data to be formatted, optional title, optional line separator
  return dump($data) unless ref($data) =~ /array/i and @$data;
  my $d;
  push @$d, ['', @$title] if $title;
  push @$d, [$_, @{$data->[$_]}] for 1..$#$data;
  formatTableBasic($d, $separator);
 }

sub formatTableHA($;$$)                                                         #P Tabularize a hash of arrays
 {my ($data, $title, $separator) = @_;                                          # Data to be formatted, optional title, optional line separator
  return dump($data) unless ref($data) =~ /hash/i and keys %$data;
  my $d;
  push @$d, [['', @$title]] if $title;
  push @$d, [$_, @{$data->{$_}}] for sort keys %$data;
  formatTableBasic($d, $separator);
 }

sub formatTableAH($;$$)                                                         #P Tabularize an array of hashes
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

sub formatTableHH($;$$)                                                         #P Tabularize a hash of hashes
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

sub formatTableA($;$$)                                                          #P Tabularize an array
 {my ($data, $title, $separator) = @_;                                          # Data to be formatted, optional title, optional line separator
  return dump($data) unless ref($data) =~ /array/i and @$data;

  my $d;
  push @$d, $title if $title;
  for(keys @$data)
   {push @$d, @$data > 1 ? [$_, $data->[$_]] : [$data->[$_]];                   # Skip line number if the array is degenerate
   }
  formatTableBasic($d, $separator);
 }

sub formatTableH($;$$)                                                          #P Tabularize a hash
 {my ($data, $title, $separator) = @_;                                          # Data to be formatted, optional title, optional line separator

  return dump($data) unless ref($data) =~ /hash/i and keys %$data;

  my $d;
  push @$d, $title if $title;
  for(sort keys %$data)
   {push @$d, [$_, $data->{$_}];
   }
  formatTableBasic($d, $separator);
 }

sub formatTable($;$$)                                                           # Format various data structures
 {my ($data, $title, $separator) = @_;                                          # Data to be formatted, optional title, optional line separator
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

sub keyCount($$)                                                                # Count keys down to the specified level
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

sub loadArrayFromLines($)                                                       # Load an array from lines of text in a string
 {my ($string) = @_;                                                            # The string of lines from which to create an array
  [split "\n", $string]
 }

sub loadHashFromLines($)                                                        # Load a hash: first word of each line is the key and the rest is the value
 {my ($string) = @_;                                                            # The string of lines from which to create a hash
  +{map{split /\s+/, $_, 2} split "\n", $string}
 }

sub loadArrayArrayFromLines($)                                                  # Load an array of arrays from lines of text: each line is an array of words
 {my ($string) = @_;                                                            # The string of lines from which to create an array of arrays
  [map{[split /\s+/]} split "\n", $string]
 }

sub loadHashArrayFromLines($)                                                   # Load a hash of arrays from lines of text: the first word of each line is the key, the remaining words are the array contents
 {my ($string) = @_;                                                            # The string of lines from which to create a hash of arrays
  +{map{my @a = split /\s+/; (shift @a, [@a])} split "\n", $string}
 }

sub checkKeys($$)                                                               # Check the keys in a hash
 {my ($test, $permitted) = @_;                                                  # The hash to test, the permitted keys and their meanings

  ref($test)      =~ /hash/igs or                                               # Check parameters
    confess "Hash reference required for first parameter";
  ref($permitted) =~ /hash/igs or
    confess "Hash referebce required for second parameter";

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
sub genLValueScalarMethods(@)                                                   # Generate LVALUE scalar methods in the current package, A method whose value has not yet been set will return a new scalar with value undef. Example: $a->value = 1;
 {my (@names) = @_;                                                             # List of method names
  my ($package) = caller;                                                       # Package
  for(@_)                                                                       # Name each method
   {my $s = 'sub '.$package.'::'.$_.':lvalue {my $v; $_[0]{"'.$_.'"} //= $v}';
    eval $s;
    confess "Unable to create LValue scalar method for: '$_' because\n$@" if $@;
   }
 }
sub genLValueScalarMethodsWithDefaultValues(@)                                  # Generate LVALUE scalar methods with default values in the current package. A reference to a method whose value has not yet been set will return a scalar whose value is the name of the method.  Example: $a->value == qq(value);
 {my (@names) = @_;                                                             # List of method names
  my ($package) = caller;                                                       # Package
  for(@_)                                                                       # Name each method
   {my $s = 'sub '.$package.'::'.$_.':lvalue {my $v = "'.$_.'"; $_[0]{"'.$_.'"} //= $v}';
    eval $s;
    confess "Unable to create LValue scalar method for: '$_' because\n$@" if $@;
   }
 }

sub genLValueArrayMethods(@)                                                    # Generate LVALUE array methods in the current package. A reference to a method that has no yet been set will return a reference to an empty array.  Example: $a->value->[1] = 2;
 {my (@names) = @_;                                                             # List of method names
  my ($package) = caller;                                                       # Package
  for(@_)                                                                       # Name each method
   {my $s = 'sub '.$package.'::'.$_.':lvalue {$_[0]{"'.$_.'"} //= []}';
    eval $s;
    confess "Unable to create LValue array method for: '$_' because\n$@" if $@;
   }
 }

sub genLValueHashMethods(@)                                                     # Generate LVALUE hash methods in the current package. A reference to a method that has no yet been set will return a reference to an empty hash. Example: $a->value->{a} = 'b';
 {my (@names) = @_;                                                             # Method names
  my ($package) = caller;                                                       # Package
  for(@_)                                                                       # Name each method
   {my $s = 'sub '.$package.'::'.$_.':lvalue {$_[0]{"'.$_.'"} //= {}}';
    eval $s;
    confess "Unable to create LValue hash method for: '$_' because\n$@" if $@;
   }
 }

#1 Strings                                                                      # Actions on strings

sub indentString($$)                                                            # Indent lines contained in a string or formatted table by the specified amount
 {my ($string, $indent) = @_;                                                   # The string of lines to indent, the indenting string
  join "\n", map {$indent.$_} split "\n", (ref($string) ? $$string  : $string)
 }

sub isBlank($)                                                                  # Test whether a string is blank
 {my ($string) = @_;                                                            # String
  $string =~ m/\A\s*\Z/
 }

sub trim($)                                                                     # Trim off white space from from front and end of string
 {my ($string) = @_;                                                            # String
  $string =~ s/\A\s+//r =~ s/\s+\Z//r
 }

sub pad($$)                                                                     # Pad a string with blanks to a multiple of a specified length
 {my ($string, $length) = @_;                                                   # String, tab width
  $string =~ s/\s+\Z//;
  my $l = length($string);
  return $string if $l % $length == 0;
  my $p = $length - $l % $length;
  $string .= ' ' x $p;
 }

sub nws($)                                                                      # Normalize white space in a string to make comparisons easier
 {my ($string) = @_;                                                            # String to normalize
  $string =~ s/\A\s+//r =~ s/\s+\Z//r =~ s/\s+/ /gr
 }

sub javaPackage($)                                                              # Extract the package name from a java string or file,
 {my ($java) = @_;                                                              # Java file if it exists else the string of java

  my $s = sub
   {return readFile($java) if $java !~ m/\n/s and -e $java;                     # Read file of java
    $java                                                                       # Java string
   }->();

  my ($p) = $s =~ m(package\s+(\S+)\s*;);
  $p
 }

sub perlPackage($)                                                              # Extract the package name from a perl string or file,
 {my ($perl) = @_;                                                              # Perl file if it exists else the string of perl
  javaPackage($perl);                                                           # Use same technique as Java
 }

#1 Documentation                                                                # Extract, format and update documentation for a perl module

sub extractTest($)                                                              #P Extract a line of a test
 {my ($string) = @_;                                                            # String containing test line
  $string =~ s/\A\s*{?(.+?)\s*#.*\Z/$1/;                                        # Remove any initial whitespace and possible { and any trailing whitespace and comments
  $string
 }

sub extractDocumentation(;$)                                                    # Extract documentation from a perl script between the lines marked with:\m  #n title # description\mand:\m  #...\mwhere n is either 1 or 2 indicating the heading level of the section and the # is in column 1.\mMethods are formatted as:\m  sub name(signature)      #FLAGS comment describing method\n   {my ($parameters) = @_; # comments for each parameter separated by commas.\mFLAGS can be any combination of:\m=over\m=item P\mprivate method\m=item S\mstatic method\m=item X\mdie rather than received a returned B<undef> result\m=back\mOther flags will be handed to the method extractDocumentationFlags(flags to process, method name) found in the file being documented, this method should return [the additional documentation for the method, the code to implement the flag].\mText following 'E\xxample:' in the comment (if present) will be placed after the parameters list as an example. \mThe character sequence \\xn in the comment will be expanded to one new line and \\xm to two new lines.\mSearch for '#1': in L<https://metacpan.org/source/PRBRENAN/Data-Table-Text-20170728/lib/Data/Table/Text.pm>  to see examples.\mParameters:\n
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

  my @l = split /\n/, readFile($perlModule);                                    # Read the perl module

  for my $l(keys @l)                                                            # Tests associated with each method
   {my $line = $l[$l];
    if (my @tags = $line =~ m/(?:\s#T(\w+))/g)
     {my %tags; $tags{$_}++ for @tags;

      for(grep {$tags{$_} > 1} sort keys %tags)                                 # Check for duplicate example names on the same line
       {warn "Duplicate example name $_ on line $l";
       }

       my @testLines = (extractTest($line));

      if ($line =~ m/<<(END|'END'|"END")/)                                      # Process here documents
       {for(my $L = $l + 1; $L < @l; ++$L)
         {my $nextLine = $l[$L];
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

  unless($perlModule eq qq(Text.pm))                                            # Load the module being documented so that we can call its extractDocumentationFlags method if needed to process user flags, we do not need to load this module as it is already loaded
   {do "$perlModule";
    confess dump($@, $!) if $@;
   }

  for my $l(keys @l)
   {my $line     = $l[$l];                                                      # This line
    my $nextLine = $l[$l+1];                                                    # The next line

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
    elsif ($level and $line =~ /\A\s*sub\s*(.*?)\s*#(\w*)\s+(.+?)\s*\Z/)        # Documentation for a method
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
      my $name      = $sub =~ s/\(.+?\)//r;                                     # Method name after removing parameters

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
        confess "Signature $signature for method: $name".
                " has wrong number of parameters";

      my @parmDescriptions = map {ucfirst()} split /,\s*/, $parmDescriptions;   # Parameter descriptions with first letter uppercased
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

These methods are the ones most likely to be of immediate useful to anyone
using this module for the first time:

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
  for my $s(sort {lc($a) cmp lc($b)} keys %methodParms)                         # Alphabetic listing of methods
   {my $t = $methodParms{$s};
    push @doc, "L<$s|/$t>\n"
   }

  push @doc, <<END;                                                             # Standard stuff
`head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read, use,
modify and install.

Standard Module::Build process for building and installing modules:

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

  join "\n", @doc                                                               # Return documentation
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

sub updatePerlModuleDocumentation($)                                            # Update the documentation in a perl file and show said documentation in a web browser
 {my ($perlModule) = @_;                                                        # File containing the code of the perl module
  -e $perlModule or confess "No such file: $perlModule";
  my $t = extractDocumentation($perlModule);                                    # Get documentation
  my $s = readFile($perlModule);                                                # Read module source
  writeFile(filePathExt($perlModule, qq(backup)), $s);                          # Backup module source
  $s =~ s/\n+=head1 Description.+?\n+1;\n+/\n\n$t\n1;\n/gs;                     # Edit module source from =head1 description to final 1;
  writeFile($perlModule, $s);                                                   # Write updated module source

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

require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw(formatTable);
@EXPORT_OK    = qw(appendFile
checkFile checkFilePath checkFilePathExt checkFilePathDir
checkKeys containingPowerOfTwo
containingFolder convertImageToJpx currentDirectory currentDirectoryAbove
dateStamp dateTimeStamp
extractDocumentation
fileList fileModTime fileOutOfDate
filePath filePathDir filePathExt fileSize findDirs findFiles
formatTableBasic fullFileName
genLValueArrayMethods genLValueHashMethods
genLValueScalarMethods genLValueScalarMethodsWithDefaultValues
imageSize indentString isBlank
javaPackage
keyCount
loadArrayArrayFromLines loadArrayFromLines
loadHashArrayFromLines loadHashFromLines
makePath matchPath
nws pad parseFileName powerOfTwo quoteFile
readBinaryFile readFile
printFullFileName
saveToS3 searchDirectoryTreesForMatchingFiles
temporaryDirectory temporaryFile temporaryFolder timeStamp trim
updatePerlModuleDocumentation writeBinaryFile writeFile
xxx);
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation
#C mim@cpan.org Testing on windows

=pod

=encoding utf-8

=head1 Name

Data::Table::Text - Write data in tabular text format

=head1 Synopsis

 use Data::Table::Text;

 say STDERR formatTable([
   [".", "aa", "bb", "cc"],
   [1, "A", "B", "C"],
   [2, "AA", "BB", "CC"],
   [3, "AAA", "BBB", "CCC"],
   [4, 1, 22, 333]]);

 #    .  aa   bb   cc
 # 1  1  A    B    C
 # 2  2  AA   BB   CC
 # 3  3  AAA  BBB  CCC
 # 4  4    1   22  333


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


 say STDERR formatTable(["a", "bb", "ccc", 4444]);
 # 0  a
 # 1  bb
 # 2  ccc
 # 3  4444


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


=head2 xxx(@)

Execute a command checking and logging the results: the command to execute is specified as one or more strings with optionally the last string being a regular expression that is used to confirm that the command executed successfully and thus that it is safe to suppress the command output as uninteresting.

  1  @cmd  Command to execute followed by an optional regular expression to test the results

=head1 Files and paths

Operations on files and paths

=head2 Statistics

Information about each file

=head3 fileSize($)

Get the size of a file

  1  $file  File name

=head3 fileModTime($)

Get the modified time of a file in seconds since the epoch

  1  $file  File name

=head3 fileOutOfDate($@)

Returns undef if all the files exist and the first file is younger than all the following files; else returns the first file that does not exist or is younger than the first file.

  1  $target   Target
  2  @sources  Sources

Example:

   make($target) if fileOutOfDate($target, $source1, $source2, $source3)

Use B<fileOutOfDateX> to execute L<fileOutOfDate|/fileOutOfDate> but B<die> 'fileOutOfDate' instead of returning B<undef>

=head2 Components

Create file names from file name components

=head3 filePath(@)

Create a file path from an array of file name components. If all the components are blank then a blank file name is returned

  1  @file  File components

=head3 filePathDir(@)

Directory from an array of file name components. If all the components are blank then a blank file name is returned

  1  @file  File components

=head3 filePathExt(@)

File name from file name components and extension

  1  @File  File components and extension

=head3 checkFile($)

Return the name of the specified file if it exists, else confess the maximum extent of the path that does exist.

  1  $file  File to check

=head3 checkFilePath(@)

L<Check|/checkFile> a folder name constructed from its L<components|/filePath>.

  1  @file  File components

=head3 checkFilePathExt(@)

L<Check|/checkFile> a file name constructed from its  L<components|/filePathExt>.

  1  @File  File components and extension

=head3 checkFilePathDir(@)

L<Check|/checkFile> a folder name constructed from its L<components|/filePathDir>.

  1  @file  File components

=head3 quoteFile($)

Quote a file name

  1  $file  File name

=head2 Position

Position in the file system

=head3 currentDirectory()

Get the current working directory


=head3 currentDirectoryAbove()

The path to the folder above the current working folder


=head3 parseFileName($)

Parse a file name into (path, name, extension)

  1  $file  File name to parse

=head3 containingFolder($)

Path to the folder that contains this file, or use L</parseFileName>

  1  $file  File name

=head3 fullFileName()

Full name of a file


=head3 printFullFileName()

Print a file name on a separate line with escaping so it can be use easily from the command line


=head2 Temporary

Temporary files and folders

=head3 temporaryFile()

Create a temporary file that will automatically be L<unlinked|/unlink> during END


=head3 temporaryFolder()

Create a temporary folder that will automatically be L<rmdired|/rmdir> during END


=head3 temporaryDirectory()

Create a temporary directory that will automatically be L<rmdired|/rmdir> during END


=head2 Find

Find files and folders below a folder

=head3 findFiles($)

Find all the file under a folder

  1  $dir  Folder to start the search with

=head3 findDirs($)

Find all the folders under a folder

  1  $dir  Folder to start the search with

=head3 fileList($)

File list

  1  $pattern  Search pattern

=head3 searchDirectoryTreesForMatchingFiles(@)

Search the specified directory trees for files that match the specified extensions -  the argument list should include at least one folder and one extension to be useful

  1  @foldersandExtensions  Mixture of folder names and extensions

=head3 matchPath($)

Given an absolute path find out how much of the path exists

  1  $file  File name

=head2 Read and write files

Read and write strings from and to files creating paths as needed

=head3 readFile($)

Read a file containing unicode

  1  $file  Name of unicode file to read

=head3 readBinaryFile($)

Read binary file - a file whose contents are not to be interpreted as unicode

  1  $file  File to read

=head3 makePath($)

Make a path for a file name or a folder

  1  $path  Path

=head3 writeFile($$)

Write a unicode string to a file after creating a path to the file if necessary

  1  $file    File to write to
  2  $string  Unicode string to write

=head3 appendFile($$)

Append a unicode string to a file after creating a path to the file if necessary

  1  $file    File to append to
  2  $string  Unicode string to append

=head3 writeBinaryFile($$)

Write a non unicode string to a file in after creating a path to the file if necessary

  1  $file    File to write to
  2  $string  Non unicode string to write

=head1 Images

Image operations

=head2 imageSize($)

Return (width, height) of an image obtained via imagemagick

  1  $image  File containing image

=head2 convertImageToJpx($$$)

Convert an image to jpx format

  1  $source  Source file
  2  $target  Target folder (as multiple files will be created)
  3  $size    Size of each tile

=head1 Powers

Integer powers of two

=head2 powerOfTwo($)

Test whether a number is a power of two, return the power if it is else undef

  1  $n  Number to check

Use B<powerOfTwoX> to execute L<powerOfTwo|/powerOfTwo> but B<die> 'powerOfTwo' instead of returning B<undef>

=head2 containingPowerOfTwo($)

Find log two of the lowest power of two greater than or equal to a number

  1  $n  Number to check

Use B<containingPowerOfTwoX> to execute L<containingPowerOfTwo|/containingPowerOfTwo> but B<die> 'containingPowerOfTwo' instead of returning B<undef>

=head1 Format

Format data structures as tables

=head2 formatTableBasic($$)

Tabularize text - basic version

  1  $data       Data to be formatted
  2  $separator  Optional line separator

=head2 formatTable($$$)

Format various data structures

  1  $data       Data to be formatted
  2  $title      Optional title
  3  $separator  Optional line separator

=head2 keyCount($$)

Count keys down to the specified level

  1  $maxDepth  Maximum depth to count to
  2  $ref       Reference to an array or a hash

=head1 Lines

Load data structures from lines

=head2 loadArrayFromLines($)

Load an array from lines of text in a string

  1  $string  The string of lines from which to create an array

=head2 loadHashFromLines($)

Load a hash: first word of each line is the key and the rest is the value

  1  $string  The string of lines from which to create a hash

=head2 loadArrayArrayFromLines($)

Load an array of arrays from lines of text: each line is an array of words

  1  $string  The string of lines from which to create an array of arrays

=head2 loadHashArrayFromLines($)

Load a hash of arrays from lines of text: the first word of each line is the key, the remaining words are the array contents

  1  $string  The string of lines from which to create a hash of arrays

=head2 checkKeys($$)

Check the keys in a hash

  1  $test       The hash to test
  2  $permitted  The permitted keys and their meanings

=head1 LVALUE methods

Replace $a->{value} = $b with $a->value = $b which reduces the amount of typing required, is easier to read and provides a hard check that {value} is spelt correctly.

=head2 genLValueScalarMethods(@)

Generate LVALUE scalar methods in the current package, A method whose value has not yet been set will return a new scalar with value undef.

  1  @names  List of method names

Example:

   $a->value = 1;

=head2 genLValueScalarMethodsWithDefaultValues(@)

Generate LVALUE scalar methods with default values in the current package. A reference to a method whose value has not yet been set will return a scalar whose value is the name of the method.

  1  @names  List of method names

Example:

   $a->value == qq(value);

=head2 genLValueArrayMethods(@)

Generate LVALUE array methods in the current package. A reference to a method that has no yet been set will return a reference to an empty array.

  1  @names  List of method names

Example:

   $a->value->[1] = 2;

=head2 genLValueHashMethods(@)

Generate LVALUE hash methods in the current package. A reference to a method that has no yet been set will return a reference to an empty hash.

  1  @names  Method names

Example:

   $a->value->{a} = 'b';

=head1 Strings

Actions on strings

=head2 indentString($$)

Indent lines contained in a string or formatted table by the specified amount

  1  $string  The string of lines to indent
  2  $indent  The indenting string

=head2 isBlank($)

Test whether a string is blank

  1  $string  String

=head2 trim($)

Trim off white space from from front and end of string

  1  $string  String

=head2 pad($$)

Pad a string with blanks to a multiple of a specified length

  1  $string  String
  2  $length  Tab width

=head2 nws($)

Normalize white space in a string to make comparisons easier

  1  $string  String to normalize

=head2 javaPackage($)

Extract the package name from a java string or file,

  1  $java  Java file if it exists else the string of java

=head2 perlPackage($)

Extract the package name from a perl string or file,

  1  $perl  Perl file if it exists else the string of perl

=head1 Documentation

Extract, format and update documentation for a perl module

=head2 extractDocumentation($)

Extract documentation from a perl script between the lines marked with:

  #n title # description

and:

  #...

where n is either 1 or 2 indicating the heading level of the section and the # is in column 1.

Methods are formatted as:

  sub name(signature)      #FLAGS comment describing method
   {my ($parameters) = @_; # comments for each parameter separated by commas.

FLAGS can be any combination of:

=over

=item P

private method

=item S

static method

=item X

die rather than received a returned B<undef> result

=back

Other flags will be handed to the method extractDocumentationFlags(flags to process, method name) found in the file being documented, this method should return [the additional documentation for the method, the code to implement the flag].

Text following 'Example:' in the comment (if present) will be placed after the parameters list as an example.

The character sequence \n in the comment will be expanded to one new line and \m to two new lines.

Search for '#1': in L<https://metacpan.org/source/PRBRENAN/Data-Table-Text-20170728/lib/Data/Table/Text.pm>  to see examples.

Parameters:


  1  $perlModule  Optional file name with caller's file being the default


=head1 Private Methods

=head2 denormalizeFolderName($)

Remove any trailing folder separator from a folder name component

  1  $name  Name

=head2 renormalizeFolderName($)

Normalize a folder name component by adding a trailing separator

  1  $name  Name

=head2 formatTableAA($$$)

Tabularize an array of arrays

  1  $data       Data to be formatted
  2  $title      Optional title
  3  $separator  Optional line separator

=head2 formatTableHA($$$)

Tabularize a hash of arrays

  1  $data       Data to be formatted
  2  $title      Optional title
  3  $separator  Optional line separator

=head2 formatTableAH($$$)

Tabularize an array of hashes

  1  $data       Data to be formatted
  2  $title      Optional title
  3  $separator  Optional line separator

=head2 formatTableHH($$$)

Tabularize a hash of hashes

  1  $data       Data to be formatted
  2  $title      Optional title
  3  $separator  Optional line separator

=head2 formatTableA($$$)

Tabularize an array

  1  $data       Data to be formatted
  2  $title      Optional title
  3  $separator  Optional line separator

=head2 formatTableH($$$)

Tabularize a hash

  1  $data       Data to be formatted
  2  $title      Optional title
  3  $separator  Optional line separator

=head2 extractTest($)

Extract a line of a test

  1  $string  String containing test line


=head1 Index


L<appendFile|/appendFile>

L<checkFile|/checkFile>

L<checkFilePath|/checkFilePath>

L<checkFilePathDir|/checkFilePathDir>

L<checkFilePathExt|/checkFilePathExt>

L<checkKeys|/checkKeys>

L<containingFolder|/containingFolder>

L<containingPowerOfTwo|/containingPowerOfTwo>

L<containingPowerOfTwoX|/containingPowerOfTwo>

L<convertImageToJpx|/convertImageToJpx>

L<currentDirectory|/currentDirectory>

L<currentDirectoryAbove|/currentDirectoryAbove>

L<dateStamp|/dateStamp>

L<dateTimeStamp|/dateTimeStamp>

L<denormalizeFolderName|/denormalizeFolderName>

L<extractDocumentation|/extractDocumentation>

L<extractTest|/extractTest>

L<fileList|/fileList>

L<fileModTime|/fileModTime>

L<fileOutOfDate|/fileOutOfDate>

L<fileOutOfDateX|/fileOutOfDate>

L<filePath|/filePath>

L<filePathDir|/filePathDir>

L<filePathExt|/filePathExt>

L<fileSize|/fileSize>

L<findDirs|/findDirs>

L<findFiles|/findFiles>

L<formatTable|/formatTable>

L<formatTableA|/formatTableA>

L<formatTableAA|/formatTableAA>

L<formatTableAH|/formatTableAH>

L<formatTableBasic|/formatTableBasic>

L<formatTableH|/formatTableH>

L<formatTableHA|/formatTableHA>

L<formatTableHH|/formatTableHH>

L<fullFileName|/fullFileName>

L<genLValueArrayMethods|/genLValueArrayMethods>

L<genLValueHashMethods|/genLValueHashMethods>

L<genLValueScalarMethods|/genLValueScalarMethods>

L<genLValueScalarMethodsWithDefaultValues|/genLValueScalarMethodsWithDefaultValues>

L<imageSize|/imageSize>

L<indentString|/indentString>

L<isBlank|/isBlank>

L<javaPackage|/javaPackage>

L<keyCount|/keyCount>

L<loadArrayArrayFromLines|/loadArrayArrayFromLines>

L<loadArrayFromLines|/loadArrayFromLines>

L<loadHashArrayFromLines|/loadHashArrayFromLines>

L<loadHashFromLines|/loadHashFromLines>

L<makePath|/makePath>

L<matchPath|/matchPath>

L<nws|/nws>

L<pad|/pad>

L<parseFileName|/parseFileName>

L<perlPackage|/perlPackage>

L<powerOfTwo|/powerOfTwo>

L<powerOfTwoX|/powerOfTwo>

L<printFullFileName|/printFullFileName>

L<quoteFile|/quoteFile>

L<readBinaryFile|/readBinaryFile>

L<readFile|/readFile>

L<renormalizeFolderName|/renormalizeFolderName>

L<searchDirectoryTreesForMatchingFiles|/searchDirectoryTreesForMatchingFiles>

L<temporaryDirectory|/temporaryDirectory>

L<temporaryFile|/temporaryFile>

L<temporaryFolder|/temporaryFolder>

L<timeStamp|/timeStamp>

L<trim|/trim>

L<writeBinaryFile|/writeBinaryFile>

L<writeFile|/writeFile>

L<xxx|/xxx>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read, use,
modify and install.

Standard Module::Build process for building and installing modules:

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
sub fileOutOfDateX         {&fileOutOfDate         (@_) || die 'fileOutOfDate'}
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
use Test::More tests => 87;

#Test::More->builder->output("/dev/null");

if (1)                                                                          # Unicode to local file
 {use utf8;
  my $z = "𝝰𝝱𝝲";
  my $t = temporaryFolder;
  my $f = filePathExt($t, $z, qq(data));
  unlink $f if -e $f;
  ok !-e $f;
  writeFile($f, $z);
  ok  -e $f;
  my $s = readFile($f);
  ok $s eq $z;
  ok length($s) == 3;
  unlink $f;
  ok !-e $f,    'unlink1';
  rmdir $t;
  ok !-d $t,    'rmDir1';
  rmdir 'tmp';
  ok !-d 'tmp', 'rmDir2';
 }

if (1)                                                                          # Key counts
 {my $a = [[1..3],       {map{$_=>1} 1..3}];
  my $h = {a=>[1..3], b=>{map{$_=>1} 1..3}};
  use Data::Dump qw(dump);
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
  my $z = "𝝰𝝱𝝲";
  my $T = temporaryFolder;
  my $t = filePath($T, $z);
  my $f = filePathExt($t, $z, qq(data));
  unlink $f if -e $f;
  ok !-e $f;
  writeFile($f, $z);
  ok  -e $f;
  my $s = readFile($f);
  ok $s eq $z;
  ok length($s) == 3;
  unlink $f;
  ok !-e $f;
  rmdir $t;
  ok !-d $t;
  rmdir $T;
  ok !-d $T;
  rmdir 'tmp';
  ok !-d 'tmp';
 }

if (1)                                                                          # Binary
 {my $z = "𝝰𝝱𝝲";
  my $Z = join '', map {chr($_)} 0..11;
  my $T = temporaryFolder;
  my $t = filePath($T, $z);
  my $f = filePathExt($t, $z, qq(data));
  unlink $f if -e $f;
  ok !-e $f;
  writeBinaryFile($f, $Z);
  ok  -e $f;
  my $s = readBinaryFile($f);
  ok $s eq $Z;
  ok length($s) == 12;
  unlink $f;
  ok !-e $f;
  rmdir $t;
  ok !-d $t;
  rmdir $T;
  ok !-d $T;
  rmdir 'tmp';
  ok !-d 'tmp';
 }

if (1)                                                                          # Check files
 {my @d =             qw(a b c d);
  my $d = filePath   (qw(a b c d));
  my $f = filePathExt(qw(a b c d e x));
  my $F = filePathExt(qw(a b c e d));
  writeFile($f, '1');
  ok checkFile($d);
  ok checkFile($f);
  eval {checkFile($F)};
  my @m = split m/\n/, $@;
  ok $m[1] eq  "a/b/c";
  unlink $f;
  ok !-e $f;
  while(@d)                                                                     # Remove path
   {my $d = filePathDir(@d);
    rmdir $d;
    ok !-e $d;
    pop @d;
   }
 }

if (1)                                                                          # Format table and AA
 {my $t = [qw(aa bb cc)];
  my $d = [[qw(1 A   B   C)],
           [qw(2 AA  BB  CC)],
           [qw(3 AAA BBB CCC)],
           [qw(4 1   22  333)]];
  ok formatTableBasic($d,   '|') eq '1  A    B    C    |2  AA   BB   CC   |3  AAA  BBB  CCC  |4    1   22  333  |';
  ok formatTable($d, $t, '|') eq '   aa  bb   cc   |1   2  AA   BB   CC   |2   3  AAA  BBB  CCC  |3   4    1   22  333  |';
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
  Test::More::ok $a->aa eq 'aa';
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
  my $d = [[qw(1 A B C)], [qw(2 AA BB CC)], [qw(3 AAA BBB CCC)],  [qw(4 1 22 333)]];
  my $s = indentString(formatTable($d), '  ') =~ s/\n/|/gr;
  ok $s eq '  1  2  AA   BB   CC   |  2  3  AAA  BBB  CCC  |  3  4    1   22  333  ';
 }

ok trim(" a b ") eq join ' ', qw(a b);                                          # Trim
ok isBlank("");                                                                  # isBlank
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
 {my $f = "test.java";
  writeFile("test.java", <<END);
// Test
package com.xyz;
END
  ok javaPackage($f) eq "com.xyz";
  unlink $f;
 }

if ($^O !~ m/\AMSWin32\Z/)                                                      # Ignore windows for this test
 {ok xxx("echo aaa")       =~ /aaa/;
  ok xxx("a=aaa;echo \$a") =~ /aaa/;

  eval {xxx "echo aaa", qr(aaa)};
  ok !$@, 'aaa';

  eval {xxx "echo aaa", qr(bbb)};
  ok $@ =~ /aaa/, 'bbb';
 }
else
 {ok 1 for 1..4;
 }
