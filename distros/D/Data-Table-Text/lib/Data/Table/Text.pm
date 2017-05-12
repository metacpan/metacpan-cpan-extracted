#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Write data in tabular text format
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2016
#-------------------------------------------------------------------------------
# xxx - add an error qr()
# xxx - a way of making it quiet
package Data::Table::Text;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;
use File::Path qw(make_path);
use File::Glob qw(:bsd_glob);
use POSIX qw(strftime);                                                         # http://www.cplusplus.com/reference/ctime/strftime/
use Data::Dump qw(dump);

our $VERSION = '2017.505';

&saveToS3('DataTableText') if 0;                                                # Save code

#-------------------------------------------------------------------------------
# Save source to S3
#-------------------------------------------------------------------------------

sub saveToS3($)                                                                 # Save to S3:- this will not work, unless you're me, or you happen, to know the key
 {my ($Z) = @_;                                                                 # File name to be used on S3
  my $z = $Z.'.zip';
  print for qx(zip $z $0 && aws s3 cp $z s3://AppaAppsSourceVersions/$z && rm $z);
 }

#-------------------------------------------------------------------------------
# Current date and time
#-------------------------------------------------------------------------------

sub dateTimeStamp() {strftime('%Y-%m-%d at %H:%M:%S', localtime)}
sub dateStamp()     {strftime('%Y-%b-%d', localtime)}
sub timeStamp()     {strftime('%H:%M:%S', localtime)}

#-------------------------------------------------------------------------------
# Get the size of a file
#-------------------------------------------------------------------------------

sub fileSize($)
 {my ($file) = @_;
  (stat($file))[7]
 }


#-------------------------------------------------------------------------------
# Get the modified time of a file in seconds since epoch
#-------------------------------------------------------------------------------

sub fileModTime($)
 {my ($file) = @_;
  (stat($file))[9] // 0
 }

#-------------------------------------------------------------------------------
# Check whether a target is out of date relative to an array of files.
#-------------------------------------------------------------------------------

# Used when one file is dependent on many files to make sure that the target is
# younger than all its sources. Allows for an easy test of the form:
#
# if (fileOutOfDate($target, $source1,$source2,$source3))
#
# as in 'make' to decide whether the target needs to be updated from its sources.
#
# Returns the first out of date source file to make debugging easier, or undef if
# no files are out of date.

sub fileOutOfDate($@)
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

#-------------------------------------------------------------------------------
# Create a file path from file name components
#-------------------------------------------------------------------------------

sub filePath(@)                                                                 # File
 {my (@file) = @_;                                                              # File componenets
  $_ or confess "Missing file component\n" for @file;                           # Check that there are no undefined file components
  my $t = join '/', map {s/[\/\\]+\Z//r} @file;
  $t
 }

sub filePathDir(@)                                                              # Directory
 {my $f = filePath(@_);
  $f =~ s/[\/\\]+\Z//s;
  $f.'/';
 }

sub filePathExt(@)                                                              # File with extension
 {my $x = pop @_;
  my $n = pop @_;
  my $f = "$n.$x";
  filePath(@_, $f)
 }

sub quoteFile($)                                                                # Quote a file name
 {my ($f) = @_;
  "\"$f\""
 }

sub currentDirectory()                                                          # Directory
 {my $f = qx(pwd);
  chomp($f);
  $f.'/'
 }

sub containingFolder($)                                                         # Path to folder containing a file
 {my ($file) = @_;
  return './' unless $file =~ m/\//;
  my @w = split /\//, $file;
  pop @w;
  join '/', @w, ''
 }

sub xxx(@)                                                                      # Execute a command
 {my @cmd = @_;                                                                 # Command to execute in phrases, although last phrase ccan be an error checking regular expression to apply to confess to any errors in the output
  $_ or confess "Missing command component\n" for @cmd;                         # Check that there are no undefined command components
  my $error = $cmd[-1];
  my $check = ref($error) =~ /RegExp/i;
  pop @cmd if $check;
  my $c = join ' ', @cmd;                                                       # Command to execute
  say STDERR timeStamp, " ", $c;
  my $r = qx($c 2>&1);
  print STDERR $r;
  confess $r if $r and $check and $r =~ m/$error/;                              # Error check if an error checking regular expression has been supplied
  $r
 }

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

#-------------------------------------------------------------------------------
# Make a path for a file name or a folder
#-------------------------------------------------------------------------------

sub makePath($)
 {my ($path) = @_;
  my @p = split /[\\\/]+/, $path;
  return 1 unless @p > 1;
  pop @p unless $path =~ /[\\\/]\Z/;
  my $p = join '/', @p;
  return 2 if -d $p;
  eval {make_path($p)};
  -d $p or confess "Cannot makePath $p";
  0
 }

#-------------------------------------------------------------------------------
# File list
#-------------------------------------------------------------------------------

sub fileList($)
 {my ($pattern) = @_;
  bsd_glob($pattern, GLOB_MARK | GLOB_TILDE)
 }

#-------------------------------------------------------------------------------
# Read file
#-------------------------------------------------------------------------------

sub readFile($)
 {my ($file) = @_;
  my $f = $file;
  -e $f or confess "Cannot read file $f because it does not exist";
  open(my $F, "<:encoding(UTF-8)", $f) or confess
    "Cannot open $f for unicode input";
  local $/ = undef;
  my $s = eval {<$F>};
  $@ and confess $@;
  $s
 }

#-------------------------------------------------------------------------------
# Read binary file - a file whose contents are not to be interpreted as unicode
#-------------------------------------------------------------------------------

sub readBinaryFile($)
 {my ($file) = @_;
  my $f = $file;
  -e $f or confess "Cannot read binary file $f because it does not exist";
  open my $F, "<$f" or confess "Cannot open binary file $f for input";
  local $/ = undef;
  <$F>;
 }

#-------------------------------------------------------------------------------
# Write file
#-------------------------------------------------------------------------------

sub writeFile($$)
 {my ($file, $string) = @_;
  $file or confess "No file name supplied";
  $string or carp "No string for file $file";
  makePath($file);
  open my $F, ">$file" or confess "Cannot open $file for write";
  binmode($F, ":utf8");
  print  {$F} $string;
  close  ($F);
  -e $file or confess "Failed to write to file $file";
 }

#-------------------------------------------------------------------------------
# Append file
#-------------------------------------------------------------------------------

sub appendFile($$)
 {my ($file, $string) = @_;
  $file or confess "No file name supplied";
  $string or carp "No string for file $file";
  makePath($file);
  open my $F, ">>$file" or confess "Cannot open $file for write";
  binmode($F, ":utf8");
  print  {$F} $string;
  close  ($F);
  -e $file or confess "Failed to write to file $file";
 }

#-------------------------------------------------------------------------------
# Write binary file
#-------------------------------------------------------------------------------

sub writeBinaryFile($$)
 {my ($file, $string) = @_;
  $file or confess "No file name supplied";
  $string or confess "No string for file $file";
  makePath($file);
  open my $F, ">$file" or confess "Cannot open $file for binary write";
  binmode($F);
  print  {$F} $string;
  close  ($F);
  -e $file or confess "Failed to write in binary to file $file";
 }

#-------------------------------------------------------------------------------
# Dimensions of an image via ImageMagick identify
#-------------------------------------------------------------------------------

sub imageSize($)                                                                # Return (width, height) of an image
 {my ($image) = @_;
  -e $image or confess "Cannot get size of image $image as file does not exist";
  my $s = qx(identify -verbose "$image");
  if ($s =~ /Geometry: (\d+)x(\d+)/s)
   {return ($1, $2);
   }
  else
   {confess "Cannot get image size for $image from:\n$s";
   }
 }

#-------------------------------------------------------------------------------
# Convert an image to Jpx format
#-------------------------------------------------------------------------------

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

#-------------------------------------------------------------------------------
# Tabularize text - basic version
#-------------------------------------------------------------------------------

sub formatTableBasic($;$)
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

#-------------------------------------------------------------------------------
# Tabularize text depending on structure
#-------------------------------------------------------------------------------

sub formatTableAA($;$)                                                          # Array of Arrays
 {my ($data, $separator) = @_;                                                  # Data to be formatted, optional line separator
  return dump($data) unless ref($data) =~ /array/i and @$data;
  my $d = [['', @{$data->[0]}]];                                                # Column headers are row 0
  push @$d, [$_, @{$data->[$_]}] for 1..$#$data;
  formatTableBasic($d, $separator);
 }

sub formatTableHA($;$)                                                          # Hash of Arrays
 {my ($data, $separator) = @_;                                                  # Data to be formatted, optional line separator
  return dump($data) unless ref($data) =~ /hash/i and keys %$data;
  my $d;                                                                        # Column headers are row 0
  push @$d, [$_, @{$data->{$_}}] for sort keys %$data;
  formatTableBasic($d, $separator);
 }

sub formatTableAH($;$)                                                          # Array of hashes
 {my ($data, $separator) = @_;                                                  # Data to be formatted, optional line separator
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

sub formatTableHH($;$)                                                          # Hash of hashes
 {my ($data, $separator) = @_;                                                  # Data to be formatted, optional line separator
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

sub formatTableA($;$)                                                           # Array with mixed elements
 {my ($data, $separator) = @_;                                                  # Data to be formatted, optional line separator
  return dump($data) unless ref($data) =~ /array/i and @$data;

  my $d;
  for(keys @$data)
   {push @$d, @$data > 1 ? [$_, $data->[$_]] : [$data->[$_]];                   # Skip line number if the array is degenerate
   }
  formatTableBasic($d, $separator);
 }

sub formatTableH($;$)                                                           # Hash with mixed elements
 {my ($data, $separator) = @_;                                                  # Data to be formatted, optional line separator
  return dump($data) unless ref($data) =~ /hash/i and keys %$data;

  my $d;
  for(sort keys %$data)
   {push @$d, [$_, $data->{$_}];
   }
  formatTableBasic($d, $separator);
 }

sub formatTable($;$)                                                            # Format various data structures
 {my ($data, $separator) = @_;                                                  # Data to be formatted, optional line separator
  my ($a, $h, $o) = (0, 0, 0);
  my $checkStructure = sub
   {for(@_)
     {my $r = ref($_[0]);
      if ($r =~ /array/i) {++$a} elsif ($r =~ /hash/i) {++$h} else {++$o}
     }
   };
  if    (ref($data) =~ /array/i)
   {$checkStructure->(       @$data);
    return formatTableAA($data, $separator) if  $a and !$h and !$o;
    return formatTableAH($data, $separator) if !$a and  $h and !$o;
    return formatTableA ($data, $separator);
   }
  elsif (ref($data) =~ /hash/i)
   {$checkStructure->(values %$data);
    return formatTableHA($data, $separator) if  $a and !$h and !$o;
    return formatTableHH($data, $separator) if !$a and  $h and !$o;
    return formatTableH ($data, $separator);
   }
 }

#-------------------------------------------------------------------------------
# Load an array from lines of text in a string
#-------------------------------------------------------------------------------

sub loadArrayFromLines($)
 {my ($string) = @_;                                                            # The string of lines from which to create an array
  [split "\n", $string]
 }

#-------------------------------------------------------------------------------
# Load a hash: first word of each line is the key and the rest is the value
#-------------------------------------------------------------------------------

sub loadHashFromLines($)
 {my ($string) = @_;                                                            # The string of lines from which to create a hash
  +{map{split /\s+/, $_, 2} split "\n", $string}
 }

#-------------------------------------------------------------------------------
# Load an array of arrays from lines of text: each line is an array of words
#-------------------------------------------------------------------------------

sub loadArrayArrayFromLines($)
 {my ($string) = @_;                                                            # The string of lines from which to create an array of arrays
  [map{[split /\s+/]} split "\n", $string]
 }

#-------------------------------------------------------------------------------
# Load a hash of arrays from lines of text: the first word of each line
# is the key, the remaining words are the array contents
#-------------------------------------------------------------------------------

sub loadHashArrayFromLines($)
 {my ($string) = @_;                                                            # The string of lines from which to create a hash of arrays
  +{map{my @a = split /\s+/; (shift @a, [@a])} split "\n", $string}
 }

#-------------------------------------------------------------------------------
# Check the keys in a hash
#-------------------------------------------------------------------------------

sub checkKeys($$)
 {my ($test, $permitted) = @_;                                                  # The hash to test, the permitted keys and their meanings
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

#-------------------------------------------------------------------------------
# Generate LVALUE methods
#-------------------------------------------------------------------------------

sub genLValueScalarMethods(@)                                                   # Scalar methods
 {my ($package) = caller;                                                       # Package
  for(@_)                                                                       # Name each method
   {my $s = 'sub '.$package.'::'.$_.':lvalue {my $v; $_[0]{"'.$_.'"} //= $v}';
    eval $s;
    confess "Unable to create LValue scalar method for: '$_' because\n$@" if $@;
   }
 }
sub genLValueScalarMethodsWithDefaultValues(@)                                  # Scalar methods with default values
 {my ($package) = caller;                                                       # Package
  for(@_)                                                                       # Name each method
   {my $s = 'sub '.$package.'::'.$_.':lvalue {my $v = "'.$_.'"; $_[0]{"'.$_.'"} //= $v}';
    eval $s;
    confess "Unable to create LValue scalar method for: '$_' because\n$@" if $@;
   }
 }

sub genLValueArrayMethods(@)                                                    # Array methods
 {my ($package) = caller;                                                       # Package
  for(@_)                                                                       # Name each method
   {my $s = 'sub '.$package.'::'.$_.':lvalue {$_[0]{"'.$_.'"} //= []}';
    eval $s;
    confess "Unable to create LValue array method for: '$_' because\n$@" if $@;
   }
 }

sub genLValueHashMethods(@)                                                     # Hash methods
 {my ($package) = caller;                                                       # Package
  for(@_)                                                                       # Name each method
   {my $s = 'sub '.$package.'::'.$_.':lvalue {$_[0]{"'.$_.'"} //= {}}';
    eval $s;
    confess "Unable to create LValue array method for: '$_' because\n$@" if $@;
   }
 }

#-------------------------------------------------------------------------------
# Indent lines contained in a string or formatted table by the specified amount
#-------------------------------------------------------------------------------

sub indentString($$)
 {my ($string, $indent) = @_;                                                   # The string of lines to indent, the indenting string
  join "\n", map {$indent.$_} split "\n", (ref($string) ? $$string  : $string)
 }

#-------------------------------------------------------------------------------
# Trim off white space from from front and end of string
#-------------------------------------------------------------------------------

sub trim($)
 {my ($string) = @_;
  $string =~ s/\A\s+//r =~ s/\s+\Z//r
 }

#-------------------------------------------------------------------------------
# Pad a string with blanks to a multiple of a specified length
#-------------------------------------------------------------------------------

sub pad($$)
 {my ($string, $length) = @_;
  $string =~ s/\s+\Z//;
  my $l = length($string);
  return $string if $l % $length == 0;
  my $p = $length - $l % $length;
  $string .= ' ' x $p;
 }

#1 Documented methods

sub nws($)                                                                      # Normalize white space in a string to make comparisons easier
 {my ($string) = @_;                                                            # String to normalize
  $string =~ s/\A\s+//r =~ s/\s+\Z//r =~ s/\s+/ /gr
 }

#0
#-------------------------------------------------------------------------------
# Test whether a number is a power of two, return the power if it is else undef
#-------------------------------------------------------------------------------

sub powerOfTwo($)                                                               # Test whether a number is a power of two, return the power if it is else undef
 {my ($n) = @_;                                                                 # Number to check
  for(0..128)
   {return $_  if 1<<$_ == $n;
    last       if 1<<$_ >  $n;
   }
  undef
 }

#-------------------------------------------------------------------------------
# Find log two of the lowest power of two greater than or equal to a number
#-------------------------------------------------------------------------------

sub containingPowerOfTwo($)
 {my ($n) = @_;                                                                 # Number to check
  for(0..128)
   {return $_  if $n <= 1<<$_;
   }
  undef
 }

#-------------------------------------------------------------------------------
# Extract package name from java file
#-------------------------------------------------------------------------------

sub javaPackage($)
 {my ($javaFile) = @_;                                                          # Java file
  my $s = readFile($javaFile);
  my ($p) = $s =~ m(package\s+(\S+)\s*;);
  $p
 }

#-------------------------------------------------------------------------------
# Documentation
#-------------------------------------------------------------------------------

sub extractDocumentation()                                                      # Extract documentation from a perl script between lines marked with \A#n and \A# as illustrated just above this line - sections are marked with #n, sub name and parameters are on two lines, private methods are marked with ##
 {my %methodParms;                                                              # Method names including parameters
  my %methods;                                                                  # Method names not including parameters
  my @d;                                                                        # Documentation
  my $level = 0; my $off = 0;                                                   # Header levels
  my @l = split /\n/, readFile($0);                                             # Read this file
  for my $l(keys @l)
   {my $L = $l[$l];                                                             # This line
    my $M = $l[$l+1];                                                           # The next line

    if ($L =~ /\A#(\d)\s+(.*?)\s*(#\s*(.+)\s*)?\Z/)                             # Sections are marked with #n in column 1-2 followed by title followed by optional text
     {$level = $1;
      my $h = $level+$off;
      push @d, "\n=head$h $2" if $level;
      push @d, "\n$4"         if $level and $4;                                 # Text of section
     }
    elsif ($L =~ /\A#/)                                                         # Switch documentation off
     {$level = 0;
     }
    elsif ($level and $L =~ /\A\s*sub\s*(.+?)\s*#\s*(.+?)\s*\Z/)                # Documentation for a method = sub name comment
     {my ($n, $d) = ($1, $2);                                                   # Name from sub, description from comment
      next if $d =~ /\A#/;                                                      # Private method if ##
      $n =~ s/\(.+?\)//;                                                        # Method name
      my $D = eval '"'.$d.'"'; confess $@ if $@;                                # Evaluate the description
      my ($p, $c) = $M =~ /\A\s*(.+?)\s*#\s*(.+?)\s*\Z/;                        # Parameters, parameter descriptions from comment
          $p //= ''; $c //= '';                                                 # No parameters
      my @p = split /,\s*/, $p =~ s/\A\s*\{my\s*\(//r =~ s/\)\s*=\s*\@_;//r;
      my @c = split /,\s*/, $c;
      my $P = join ', ', @p;
      my $h = $level+$off+1;
      my $N = "$n($P)";                                                         # Method
      $methodParms{$N}++;                                                       # Method names including parameters
      $methods{$n}++;                                                           # Method names not including parameters
      push @d, "\n=head$h $N\n\n$D\n";                                          # Method description
      push @d, indentString(formatTable([[qw(Parameter Description)], map{[$p[$_], $c[$_]]} keys @p]), '  ')
        if $p and $c and $c !~ /\A#/;                                           # Add parameter description if present
     }
   }
  push @d, "=head1 Index\n\n";
  push @d, "L</$_>" for sort keys %methodParms;                                 # Alphabetic listing of methods
  push @d, "\n";
  writeFile("doc.data",     join "\n", @d);                                     # Write documentation file
  writeFile("methods.data", join "\n", sort keys %methods);                     # Write methods file
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

sub test
 {eval join('', <Data::Table::Text::DATA>) || die $@
 }

test unless caller();

# Documentation
#extractDocumentation unless caller;

#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw(formatTable);
@EXPORT_OK    = qw(appendFile
checkKeys containingPowerOfTwo
containingFolder convertImageToJpx currentDirectory
dateStamp dateTimeStamp
extractDocumentation
fileList fileModTime fileOutOfDate
filePath filePathDir filePathExt fileSize findDirs findFiles formatTableBasic
genLValueArrayMethods genLValueHashMethods
genLValueScalarMethods genLValueScalarMethodsWithDefaultValues
imageSize indentString
javaPackage
loadArrayArrayFromLines loadArrayFromLines
loadHashArrayFromLines loadHashFromLines
makePath nws pad powerOfTwo quoteFile
readBinaryFile readFile saveToS3 timeStamp trim writeBinaryFile writeFile
xxx);
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

1;

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

Prints an array or a hash or an array of arrays or an array of hashes or a hash
of arrays or a hash of hashes in a tabular format that is easier to read than a
raw data dump.

=head1 Installation

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

This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

=cut

__DATA__
use Test::More tests => 60;
if (1)                                                                          # File paths
 {ok filePath   (qw(/aaa bbb ccc ddd.eee)) eq "/aaa/bbb/ccc/ddd.eee";
  ok filePathDir(qw(/aaa bbb ccc ddd))     eq "/aaa/bbb/ccc/ddd/";
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
 {my $d = [[qw(. aa bb cc)], [qw(1 A B C)], [qw(2 AA BB CC)], [qw(3 AAA BBB CCC)],  [qw(4 1 22 333)]];
  ok formatTableBasic($d, '|') eq '.  aa   bb   cc   |1  A    B    C    |2  AA   BB   CC   |3  AAA  BBB  CCC  |4    1   22  333  |';
  ok formatTable($d, '|') eq '   .  aa   bb   cc   |1  1  A    B    C    |2  2  AA   BB   CC   |3  3  AAA  BBB  CCC  |4  4    1   22  333  |';
 }
if (1)                                                                          # AH
 {my $d = [{aa=>'A', bb=>'B', cc=>'C'}, {aa=>'AA', bb=>'BB', cc=>'CC'}, {aa=>'AAA', bb=>'BBB', cc=>'CCC'}, {aa=>'1', bb=>'22', cc=>'333'}];
  ok formatTable($d, '|') eq '   aa   bb   cc   |1  A    B    C    |2  AA   BB   CC   |3  AAA  BBB  CCC  |4    1   22  333  |';
 }
if (1)                                                                          # HA
 {my $d = {''=>[qw(aa bb cc)], 1=>[qw(A B C)], 22=>[qw(AA BB CC)], 333=>[qw(AAA BBB CCC)],  4444=>[qw(1 22 333)]};
  ok formatTable($d, '|') eq '      aa   bb   cc   |   1  A    B    C    |  22  AA   BB   CC   | 333  AAA  BBB  CCC  |4444    1   22  333  |';
 }
if (1)                                                                          # HH
 {my $d = {a=>{aa=>'A', bb=>'B', cc=>'C'}, aa=>{aa=>'AA', bb=>'BB', cc=>'CC'}, aaa=>{aa=>'AAA', bb=>'BBB', cc=>'CCC'}, aaaa=>{aa=>'1', bb=>'22', cc=>'333'}};
  ok formatTable($d, '|') eq '      aa   bb   cc   |a     A    B    C    |aa    AA   BB   CC   |aaa   AAA  BBB  CCC  |aaaa    1   22  333  |';
 }
if (1)                                                                          # A
 {my $d = [qw(a bb ccc 4444)];
  ok formatTable($d, '|') eq '0  a     |1  bb    |2  ccc   |3  4444  |';
 }
if (1)                                                                          # H
 {my $d = {aa=>'A', bb=>'B', cc=>'C'};
  ok formatTable($d, '|') eq 'aa  A  |bb  B  |cc  C  |';
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
 {my $d = [[qw(. aa bb cc)], [qw(1 A B C)], [qw(2 AA BB CC)], [qw(3 AAA BBB CCC)],  [qw(4 1 22 333)]];
  my $s = indentString(formatTable($d), '  ') =~ s/\n/|/gr;
  ok $s eq '     .  aa   bb   cc   |  1  1  A    B    C    |  2  2  AA   BB   CC   |  3  3  AAA  BBB  CCC  |  4  4    1   22  333  ';
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
  ok $@ =~ /aaa/;
 }
