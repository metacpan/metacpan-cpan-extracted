#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Write data in tabular text format
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2016
#-------------------------------------------------------------------------------
# podDocumentation

package Data::Table::Text;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;
use File::Path qw(make_path);
use File::Glob qw(:bsd_glob);
use POSIX qw(strftime);                                                         # http://www.cplusplus.com/reference/ctime/strftime/
use Data::Dump qw(dump);

our $VERSION = '20170728';

#1 Time stamps                                                                  # Date and timestamps as used in logs

sub dateTimeStamp                                                               # Year-monthNumber-day at hours:minute:seconds
 {strftime('%Y-%m-%d at %H:%M:%S', localtime)
 }

sub dateStamp                                                                   # Year-monthName-day
 {strftime('%Y-%b-%d', localtime)
 }

sub timeStamp                                                                   # hours:minute:seconds
 {strftime('%H:%M:%S', localtime)
 }

sub xxx(@)                                                                      # Execute a command checking and logging the results with a time stamp
 {my @cmd = @_;                                                                 # Command to execute in phrases, although last phrase can be an error checking regular expression to apply to confess to any errors in the output
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

sub fileSize($)                                                                 # Get the size of a file
 {my ($file) = @_;                                                              # File name
  (stat($file))[7]
 }

sub fileModTime($)                                                              # Get the modified time of a file in seconds since epoch
 {my ($file) = @_;                                                              # File name
  (stat($file))[9] // 0
 }

sub fileOutOfDate($@)                                                           # Check whether a target is out of date relative to an array of files. Used when one file is dependent on many files to make sure that the target is younger than all its sources. Allows for an easy test of the Example: ... if fileOutOfDate($target, $source1, $source2, $source3):as in 'make' to decide whether the target needs to be updated from its sources. Returns the first out of date source file to make debugging easier, or undef if no files are out of date.
 {my ($target, @sources) = @_;                                                  # Target, sources
  return $target unless -e $target;                                             # Out of date if target does not exist
  my $t = fileModTime($target);                                                 # Time of target
  for(@sources)                                                                 # Each source
   {return $_ unless -e $_;                                                     # Out of date if source does not exist
    my $T = fileModTime($_);                                                    # Time of source
    return $_ if $T > $t;                                                       # Out of date if source newer than target
   }
  undef                                                                         # Not out of date as : target and all sources exist and target later than all of the sources
 }

sub filePath(@)                                                                 # Create a file path from an array of file name components
 {my (@file) = @_;                                                              # File components
  $_ or confess "Missing file component\n" for @file;                           # Check that there are no undefined file components
  my $t = join '/', map {s/[\/\\]+\Z//r} @file;
  $t
 }

sub filePathDir(@)                                                              # Directory from an array of file name components
 {my (@file) = @_;                                                              # File components
  my $f = filePath(@_);
  $f =~ s/[\/\\]+\Z//s;
  $f.'/';
 }

sub filePathExt(@)                                                              # File name from file name components and extension
 {my (@file) = @_;                                                              # File components and extension
  my $x = pop @_;
  my $n = pop @_;
  my $f = "$n.$x";
  filePath(@_, $f)
 }

sub quoteFile($)                                                                # Quote a file name
 {my ($file) = @_;                                                              # File name
  "\"$file\""
 }

sub currentDirectory                                                            # Get the current working directory
 {my $f = qx(pwd);
  chomp($f);
  $f.'/'
 }

sub currentDirectoryAbove                                                       # The path to the folder above the current working folder
 {my @p = split m(/)s, currentDirectory;
  @p or confess "No directory above\n:".currentDirectory;
  pop @p;
  my $r = shift @p;
  filePathDir("/$r", @p)
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

#2 Find files and folders                                                       # Find files and folders below a folder

sub findFiles($)                                                                # Find all the file under a folder
 {my ($dir) = @_;                                                               # Folder to start the search with
  my @f;
  for(qx(find $dir))
   {chomp;
    next if -d $_;                                                              # Do not include folder names
    push @f, $_;
   }
  @f
 }

sub findDirs($)                                                                 # Find all the folders under a folder
 {my ($dir) = @_;                                                               # Folder to start the search with
  my @d;
  for(qx(find $dir))
   {chomp;
    next unless -d $_;                                                          # Include only folders
    push @d, $_;
   }
  @d
 }

sub fileList($)                                                                 # File list
 {my ($pattern) = @_;                                                           # Search pattern
  bsd_glob($pattern, GLOB_MARK | GLOB_TILDE)
 }

#1 Read and write files                                                         # Read and write strings from files creating paths as needed

sub readFile($)                                                                 # Read file
 {my ($file) = @_;                                                              # File to read
  my $f = $file;
  defined($f) or confess "Cannot read undefined file";
  $f =~ m(\n) and confess "File name contains a new line:\n=$file=";
  -e $f or confess "Cannot read file $f because it does not exist";
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

sub writeFile($$)                                                               # Write a string to a file after creating a path to the file if necessary
 {my ($file, $string) = @_;                                                     # File to write to, string to write
  $file or confess "No file name supplied";
  $string or carp "No string for file $file";
  makePath($file);
  open my $F, ">$file" or confess "Cannot open $file for write";
  binmode($F, ":utf8");
  print  {$F} $string;
  close  ($F);
  -e $file or confess "Failed to write to file $file";
 }

sub appendFile($$)                                                              # Append a string to a file after creating a path to the file if necessary
 {my ($file, $string) = @_;                                                     # File to append to, string to write
  $file or confess "No file name supplied";
  $string or carp "No string for file $file";
  makePath($file);
  open my $F, ">>$file" or confess "Cannot open $file for write";
  binmode($F, ":utf8");
  print  {$F} $string;
  close  ($F);
  -e $file or confess "Failed to write to file $file";
 }

sub writeBinaryFile($$)                                                         # Write a string to a file in binmode after creating a path to the file if necessary
 {my ($file, $string) = @_;                                                     # File to write to, string to write
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

#1 Powers                                                                       # Power

sub powerOfTwo($)                                                               # Test whether a number is a power of two, return the power if it is else undef
 {my ($n) = @_;                                                                 # Number to check
  for(0..128)
   {return $_  if 1<<$_ == $n;
    last       if 1<<$_ >  $n;
   }
  undef
 }

sub containingPowerOfTwo($)                                                     # Find log two of the lowest power of two greater than or equal to a number
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

sub formatTableAA($;$$)                                                         ## Tabularize an array of arrays
 {my ($data, $title, $separator) = @_;                                          # Data to be formatted, optional title, optional line separator
  return dump($data) unless ref($data) =~ /array/i and @$data;
  my $d;
  push @$d, ['', @$title] if $title;
  push @$d, [$_, @{$data->[$_]}] for 1..$#$data;
  formatTableBasic($d, $separator);
 }

sub formatTableHA($;$$)                                                         ## Tabularize a hash of arrays
 {my ($data, $title, $separator) = @_;                                          # Data to be formatted, optional title, optional line separator
  return dump($data) unless ref($data) =~ /hash/i and keys %$data;
  my $d;
  push @$d, [['', @$title]] if $title;
  push @$d, [$_, @{$data->{$_}}] for sort keys %$data;
  formatTableBasic($d, $separator);
 }

sub formatTableAH($;$$)                                                         ## Tabularize an array of hashes
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

sub formatTableHH($;$$)                                                         ## Tabularize a hash of hashes
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

sub formatTableA($;$$)                                                          ## Tabularize an array
 {my ($data, $title, $separator) = @_;                                          # Data to be formatted, optional title, optional line separator
  return dump($data) unless ref($data) =~ /array/i and @$data;

  my $d;
  push @$d, $title if $title;
  for(keys @$data)
   {push @$d, @$data > 1 ? [$_, $data->[$_]] : [$data->[$_]];                   # Skip line number if the array is degenerate
   }
  formatTableBasic($d, $separator);
 }

sub formatTableH($;$$)                                                          ## Tabularize a hash
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

#1 LVALUE methods                                                               # Object oriented methods using LVALUE methods
sub genLValueScalarMethods(@)                                                   # Generate LVALUE scalar methods
 {my (@names) = @_;                                                             # Method names
  my ($package) = caller;                                                       # Package
  for(@_)                                                                       # Name each method
   {my $s = 'sub '.$package.'::'.$_.':lvalue {my $v; $_[0]{"'.$_.'"} //= $v}';
    eval $s;
    confess "Unable to create LValue scalar method for: '$_' because\n$@" if $@;
   }
 }
sub genLValueScalarMethodsWithDefaultValues(@)                                  # Generate LVALUE scalar methods with default values
 {my (@names) = @_;                                                             # Method names
  my ($package) = caller;                                                       # Package
  for(@_)                                                                       # Name each method
   {my $s = 'sub '.$package.'::'.$_.':lvalue {my $v = "'.$_.'"; $_[0]{"'.$_.'"} //= $v}';
    eval $s;
    confess "Unable to create LValue scalar method for: '$_' because\n$@" if $@;
   }
 }

sub genLValueArrayMethods(@)                                                    # Generate LVALUE array methods
 {my (@names) = @_;                                                             # Method names
  my ($package) = caller;                                                       # Package
  for(@_)                                                                       # Name each method
   {my $s = 'sub '.$package.'::'.$_.':lvalue {$_[0]{"'.$_.'"} //= []}';
    eval $s;
    confess "Unable to create LValue array method for: '$_' because\n$@" if $@;
   }
 }

sub genLValueHashMethods(@)                                                     # Generate LVALUE hash methods
 {my (@names) = @_;                                                             # Method names
  my ($package) = caller;                                                       # Package
  for(@_)                                                                       # Name each method
   {my $s = 'sub '.$package.'::'.$_.':lvalue {$_[0]{"'.$_.'"} //= {}}';
    eval $s;
    confess "Unable to create LValue array method for: '$_' because\n$@" if $@;
   }
 }

#1 Strings                                                                      # Actions on strings

sub indentString($$)                                                            # Indent lines contained in a string or formatted table by the specified amount
 {my ($string, $indent) = @_;                                                   # The string of lines to indent, the indenting string
  join "\n", map {$indent.$_} split "\n", (ref($string) ? $$string  : $string)
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

sub javaPackage($)                                                              # Extract package name from java file
 {my ($javaFile) = @_;                                                          # Java file
  my $s = readFile($javaFile);
  my ($p) = $s =~ m(package\s+(\S+)\s*;);
  $p
 }

sub extractDocumentation()                                                      # Extract documentation from a perl script between lines marked with \A#n and \A# as illustrated just above this line - sections are marked with #n, sub name and parameters are on two lines, private methods are marked with ##

 {my %methodParms;                                                              # Method names including parameters
  my %methods;                                                                  # Method names not including parameters
  my @d = (qq(=head1 Description));                                             # Documentation
  my $level = 0; my $off = 1;                                                   # Header levels
  my @l = split /\n/, readFile($0);                                             # Read this file
  for my $l(keys @l)
   {my $line     = $l[$l];                                                      # This line
    my $nextLine = $l[$l+1];                                                    # The next line

    if ($line =~ /\A#(\d)\s+(.*?)\s*(#\s*(.+)\s*)?\Z/)                          # Sections are marked with #n in column 1-2 followed by title followed by optional text
     {$level = $1;
      my $h = $level+$off;
      push @d, "\n=head$h $2" if $level;
      push @d, "\n$4"         if $level and $4;                                 # Text of section
     }
    elsif ($line =~ /\A#/)                                                      # Switch documentation off
     {$level = 0;
     }
    elsif ($level and $line =~ /\A\s*sub\s*(.+?)\s*#\s*(.+?)\s*\Z/)             # Documentation for a method = sub name comment
     {my ($n, $comment, $example, $produces) = ($1, $2);                        # Name from sub, description from comment

      next if $comment  =~ /\A#/;                                               # Private method if ##
      if ($comment =~ m/\A(.*)Example:(.+?)\Z/is)                               # Extract example
       {$comment = $1;
       ($example, $produces) = split /:/, $2, 2;
       }

      my $signature = $n =~ s/\A\s*\w+//gsr =~                                  # Signature
                            s/\A\(//gsr     =~
                            s/\)\s*(:lvalue\s*)?\Z//gsr =~
                            s/;//gsr;                                           # Remove optional parameters marker from signature
      $n =~ s/\(.+?\)//;                                                        # Method name after removing parameters

      my ($p, $c);
      ($p, $c) = $nextLine =~ /\A\s*(.+?)\s*#\s*(.+?)\s*\Z/ if $signature;      # Parameters, parameter descriptions from comment
       $p //= ''; $c //= '';                                                    # No parameters

      my @p = split /,\s*/, $p =~ s/\A\s*\{my\s*\(//r =~ s/\)\s*=\s*\@_;//r;    # Parameter names
      @p == length($signature) or confess "Signature $signature for method: $n".# Check signature length
        " has wrong number of parameters";

      my @c = map {ucfirst()} split /,\s*/, $c;                                 # Parameter descriptions with first letter uppercased
      my $P = join ', ', @p;
      my $h = $level+$off+1;                                                    # Heading level
      my $N = "$n($P)";                                                         # Method(signature)
      $methodParms{$n} = $n;                                                    # Method names not including parameters
      $methods{$n}++;                                                           # Method names not including parameters
      push @d, "\n=head$h $n\n\n$comment\n";                                    # Method description
      push @d, indentString(formatTable([[qw(Parameter Description)],
        map{[$p[$_], $c[$_]]} keys @p]), '  ')
        if $p and $c and $c !~ /\A#/;                                           # Add parameter description if present
      push @d, "\nExample:\n\n  $example" if $example;
      push @d, "\n$produces"              if $produces;
     }
    elsif ($level and $line =~                                                  # Documentation for a generated lvalue * method = sub name comment
     /\A\s*genLValue(?:\w+?)Methods\s*\(qw\((\w+)\)\);\s*#\s*(.+?)\s*\Z/)
     {my ($n, $d) = ($1, $2);                                                   # Name from sub, description from comment
      next if $d =~ /\A#/;                                                      # Private method if ##
      my $h = $level+$off+1;                                                    # Heading level
      $methodParms{$n} = $n;                                                    # Method names not including parameters
      $methods{$n}++;                                                           # Method names not including parameters
      push @d, "\n=head$h $n :lvalue\n\n$d\n";                                  # Method description
     }
   }

  push @d, "\n\n=head1 Index\n\n";
  for my $s(sort {lc($a) cmp lc($b)} keys %methodParms)                         # Alphabetic listing of methods
   {my $n = $methodParms{$s};
    push @d, "L<$n|/$s>\n"
   }
  push @d, <<END =~ s/`/=/gsr;                                                  # Standard stuff
`head1 Installation

This module is written in 100% Pure Perl and is thus easy to read, use, modify
and install.

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

`head1 Author

philiprbrenan\@gmail.com

http://www.appaapps.com

`head1 Copyright

Copyright (c) 2016-2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

`cut
END

  writeFile(my $d = "doc.data",     join "\n", @d);                             # Write documentation file
# writeFile("methods.data", join "\n", sort keys %methods);                     # Write methods file
  my $D = filePath(currentDirectory, $d);
  say STDERR "Documentation in:\n$D";
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
# Test
#-------------------------------------------------------------------------------

sub test {eval join('', <Data::Table::Text::DATA>) || die $@} test unless caller();

# podDocumentation
extractDocumentation unless caller;

#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw(formatTable);
@EXPORT_OK    = qw(appendFile
checkKeys containingPowerOfTwo
containingFolder convertImageToJpx currentDirectory currentDirectoryAbove
dateStamp dateTimeStamp
extractDocumentation
fileList fileModTime fileOutOfDate
filePath filePathDir filePathExt fileSize findDirs findFiles formatTableBasic
genLValueArrayMethods genLValueHashMethods
genLValueScalarMethods genLValueScalarMethodsWithDefaultValues
imageSize indentString
javaPackage
keyCount
loadArrayArrayFromLines loadArrayFromLines
loadHashArrayFromLines loadHashFromLines
makePath nws pad parseFileName powerOfTwo quoteFile
readBinaryFile readFile saveToS3 timeStamp trim writeBinaryFile writeFile
xxx);
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

1;

# podDocumentation

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

=head2 Time stamps

Date and timestamps as used in logs

=head3 dateTimeStamp

Year-monthNumber-day at hours:minute:seconds


=head3 dateStamp

Year-monthName-day


=head3 timeStamp

hours:minute:seconds


=head3 xxx

Execute a command checking and logging the results with a time stamp

  1  {my @cmd = @_;  Command to execute in phrases

=head2 Files and paths

Operations on files and paths

=head3 fileSize

Get the size of a file

  1  $file  File name

=head3 fileModTime

Get the modified time of a file in seconds since epoch

  1  $file  File name

=head3 fileOutOfDate

Check whether a target is out of date relative to an array of files. Used when one file is dependent on many files to make sure that the target is younger than all its sources. Allows for an easy test of the

  1  $target   Target
  2  @sources  Sources

Example:

   ... if fileOutOfDate($target, $source1, $source2, $source3)

as in 'make' to decide whether the target needs to be updated from its sources. Returns the first out of date source file to make debugging easier, or undef if no files are out of date.

=head3 filePath

Create a file path from an array of file name components

  1  @file  File components

=head3 filePathDir

Directory from an array of file name components

  1  @file  File components

=head3 filePathExt

File name from file name components and extension

  1  @file  File components and extension

=head3 quoteFile

Quote a file name

  1  $file  File name

=head3 currentDirectory

Get the current working directory


=head3 currentDirectoryAbove

The path to the folder above the current working folder


=head3 parseFileName

Parse a file name into (path, name, extension)

  1  $file  File name to parse

=head3 containingFolder

Path to the folder that contains this file, or use L</parseFileName>

  1  $file  File name

=head3 Find files and folders

Find files and folders below a folder

=head4 findFiles

Find all the file under a folder

  1  $dir  Folder to start the search with

=head4 findDirs

Find all the folders under a folder

  1  $dir  Folder to start the search with

=head4 fileList

File list

  1  $pattern  Search pattern

=head2 Read and write files

Read and write strings from files creating paths as needed

=head3 readFile

Read file

  1  $file  File to read

=head3 readBinaryFile

Read binary file - a file whose contents are not to be interpreted as unicode

  1  $file  File to read

=head3 makePath

Make a path for a file name or a folder

  1  $path  Path

=head3 writeFile

Write a string to a file after creating a path to the file if necessary

  1  $file    File to write to
  2  $string  String to write

=head3 appendFile

Append a string to a file after creating a path to the file if necessary

  1  $file    File to append to
  2  $string  String to write

=head3 writeBinaryFile

Write a string to a file in binmode after creating a path to the file if necessary

  1  $file    File to write to
  2  $string  String to write

=head2 Images

Image operations

=head3 imageSize

Return (width, height) of an image obtained via imagemagick

  1  $image  File containing image

=head3 convertImageToJpx

Convert an image to jpx format

  1  $source  Source file
  2  $target  Target folder (as multiple files will be created)
  3  $size    Size of each tile

=head2 Powers

Power

=head3 powerOfTwo

Test whether a number is a power of two, return the power if it is else undef

  1  $n  Number to check

=head3 containingPowerOfTwo

Find log two of the lowest power of two greater than or equal to a number

  1  $n  Number to check

=head2 Format

Format data structures as tables

=head3 formatTableBasic

Tabularize text - basic version

  1  $data       Data to be formatted
  2  $separator  Optional line separator

=head3 formatTable

Format various data structures

  1  $data       Data to be formatted
  2  $title      Optional title
  3  $separator  Optional line separator

=head3 keyCount

Count keys down to the specified level

  1  $maxDepth  Maximum depth to count to
  2  $ref       Reference to an array or a hash

=head2 Lines

Load data structures from lines

=head3 loadArrayFromLines

Load an array from lines of text in a string

  1  $string  The string of lines from which to create an array

=head3 loadHashFromLines

Load a hash: first word of each line is the key and the rest is the value

  1  $string  The string of lines from which to create a hash

=head3 loadArrayArrayFromLines

Load an array of arrays from lines of text: each line is an array of words

  1  $string  The string of lines from which to create an array of arrays

=head3 loadHashArrayFromLines

Load a hash of arrays from lines of text: the first word of each line is the key, the remaining words are the array contents

  1  $string  The string of lines from which to create a hash of arrays

=head3 checkKeys

Check the keys in a hash

  1  $test       The hash to test
  2  $permitted  The permitted keys and their meanings

=head2 LVALUE methods

Object oriented methods using LVALUE methods

=head3 genLValueScalarMethods

Generate LVALUE scalar methods

  1  @names  Method names

=head3 genLValueScalarMethodsWithDefaultValues

Generate LVALUE scalar methods with default values

  1  @names  Method names

=head3 genLValueArrayMethods

Generate LVALUE array methods

  1  @names  Method names

=head3 genLValueHashMethods

Generate LVALUE hash methods

  1  @names  Method names

=head2 Strings

Actions on strings

=head3 indentString

Indent lines contained in a string or formatted table by the specified amount

  1  $string  The string of lines to indent
  2  $indent  The indenting string

=head3 trim

Trim off white space from from front and end of string

  1  $string  String

=head3 pad

Pad a string with blanks to a multiple of a specified length

  1  $string  String
  2  $length  Tab width

=head3 nws

Normalize white space in a string to make comparisons easier

  1  $string  String to normalize

=head3 javaPackage

Extract package name from java file

  1  $javaFile  Java file

=head3 extractDocumentation()

Extract documentation from a perl script between lines marked with \A#n and \A# as illustrated just above this line - sections are marked with #n, sub name and parameters are on two lines, private methods are marked with ##



=head1 Index


L<appendFile|/appendFile>

L<checkKeys|/checkKeys>

L<containingFolder|/containingFolder>

L<containingPowerOfTwo|/containingPowerOfTwo>

L<convertImageToJpx|/convertImageToJpx>

L<currentDirectory|/currentDirectory>

L<currentDirectoryAbove|/currentDirectoryAbove>

L<dateStamp|/dateStamp>

L<dateTimeStamp|/dateTimeStamp>

L<extractDocumentation()|/extractDocumentation()>

L<fileList|/fileList>

L<fileModTime|/fileModTime>

L<fileOutOfDate|/fileOutOfDate>

L<filePath|/filePath>

L<filePathDir|/filePathDir>

L<filePathExt|/filePathExt>

L<fileSize|/fileSize>

L<findDirs|/findDirs>

L<findFiles|/findFiles>

L<formatTable|/formatTable>

L<formatTableBasic|/formatTableBasic>

L<genLValueArrayMethods|/genLValueArrayMethods>

L<genLValueHashMethods|/genLValueHashMethods>

L<genLValueScalarMethods|/genLValueScalarMethods>

L<genLValueScalarMethodsWithDefaultValues|/genLValueScalarMethodsWithDefaultValues>

L<imageSize|/imageSize>

L<indentString|/indentString>

L<javaPackage|/javaPackage>

L<keyCount|/keyCount>

L<loadArrayArrayFromLines|/loadArrayArrayFromLines>

L<loadArrayFromLines|/loadArrayFromLines>

L<loadHashArrayFromLines|/loadHashArrayFromLines>

L<loadHashFromLines|/loadHashFromLines>

L<makePath|/makePath>

L<nws|/nws>

L<pad|/pad>

L<parseFileName|/parseFileName>

L<powerOfTwo|/powerOfTwo>

L<quoteFile|/quoteFile>

L<readBinaryFile|/readBinaryFile>

L<readFile|/readFile>

L<timeStamp|/timeStamp>

L<trim|/trim>

L<writeBinaryFile|/writeBinaryFile>

L<writeFile|/writeFile>

L<xxx|/xxx>

=head1 Installation

This module is written in 100% Pure Perl and is thus easy to read, use, modify
and install.

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

philiprbrenan@gmail.com

http://www.appaapps.com

=head1 Copyright

Copyright (c) 2016-2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut
# podDocumentation
## pod2html --infile=lib/Data/Table/Text.pm --outfile=zzz.html

__DATA__
use Test::More tests => 68;

#Test::More->builder->output("/dev/null");

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
 }

if (1)                                                                          # Parse file names
 {is_deeply [parseFileName "/home/phil/test.data"], ["/home/phil/", "test", "data"];
  is_deeply [parseFileName "/home/phil/test"],      ["/home/phil/", "test"];
  is_deeply [parseFileName "phil/test.data"],       ["phil/",       "test", "data"];
  is_deeply [parseFileName "phil/test"],            ["phil/",       "test"];
  is_deeply [parseFileName "test.data"],            [undef,         "test", "data"];
 }

if (1)                                                                          # Unicode to local file
 {use utf8;
  my $z = "𝝰𝝱𝝲";
  my $f = "$z.data";
  unlink $f if -e $f;
  ok !-e $f;
  writeFile($f, $z);
  ok  -e $f;
  my $s = readFile($f);
  ok $s eq $z;
  ok length($s) == 3;
  unlink $f;
  ok !-e $f;
  qx(rmdir $z) if -d $z;
  ok !-d $z;
 }

if (1)                                                                          # Unicode
 {use utf8;
  my $z = "𝝰𝝱𝝲";
  my $f = "$z/$z.data";
  unlink $f if -e $f;
  ok !-e $f;
  writeFile($f, $z);
  ok  -e $f;
  my $s = readFile($f);
  ok $s eq $z;
  ok length($s) == 3;
  unlink $f;
  ok !-e $f;
  qx(rmdir $z);
  ok !-d $z;
 }
if (1)                                                                          # Binary
 {my $z = "𝝰𝝱𝝲";
  my $f = "$z/$z.data";
  unlink $f if -e $f;
  ok !-e $f;
  writeBinaryFile($f, $z);
  ok  -e $f;
  my $s = readBinaryFile($f);
  ok $s eq $z;
  ok length($s) == 12;
  unlink $f;
  ok !-e $f;
  qx(rmdir $z);
  ok !-d $z;
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

 ok trim(" a b ") eq join ' ', qw(a b);                                         # Trim

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

ok xxx("echo aaa")       =~ /aaa/;
ok xxx("a=aaa;echo \$a") =~ /aaa/;

if (1)
 {eval {xxx "echo aaa", qr(aaa)};
  ok !$@, 'aaa';
  eval {xxx "echo aaa", qr(bbb)};
  ok $@ =~ /aaa/, 'bbb';
 }
