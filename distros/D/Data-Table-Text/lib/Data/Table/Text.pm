#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Write data in tabular text format
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2016-2018
#-------------------------------------------------------------------------------
# podDocumentation
# line 1025 - handle: sub a::b
# deprecate parseFileName in this file too!
# formatTableA returns "[]" if passed an empty array

package Data::Table::Text;
use v5.8.0;
our $VERSION = '20180724';
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess carp cluck);
use Cwd;
use File::Path qw(make_path);
use File::Glob qw(:bsd_glob);
use File::Temp qw(tempfile tempdir);
use POSIX qw(strftime);                                                         # http://www.cplusplus.com/reference/ctime/strftime/
use Data::Dump qw(dump);
use JSON;
use MIME::Base64;
use Storable qw(store retrieve); ## Add to manifest
use String::Numeric qw(is_float);
use Time::HiRes qw(gettimeofday);
use utf8;

#1 Time stamps                                                                  # Date and timestamps as used in logs of long running commands

sub dateTimeStamp                                                               # Year-monthNumber-day at hours:minute:seconds
 {strftime('%Y-%m-%d at %H:%M:%S', localtime)
 }

sub dateStamp                                                                   # Year-monthName-day
 {strftime('%Y-%b-%d', localtime)
 }

sub versionCode                                                                 # YYYmmdd-HHMMSS
 {strftime('%Y%m%d-%H%M%S', localtime)
 }

sub versionCodeDashed                                                                 # YYYmmdd-HHMMSS
 {strftime('%Y-%m-%d-%H:%M:%S', localtime)
 }

sub timeStamp                                                                   # hours:minute:seconds
 {strftime('%H:%M:%S', localtime)
 }

sub microSecondsSinceEpoch                                                      # Micro seconds since unix epoch
 {my ($s, $u) = gettimeofday();
  $s*1e6 + $u
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

sub yyy($)                                                                      # Execute a block of shell commands line by line after removing comments - stop if there is a non zero return code from any command
 {my ($cmd) = @_;                                                               # Commands to execute separated by new lines
  for(split /\n/, $cmd)                                                         # Split commands on new lines
   {s(#.*\Z)()gs;                                                               # Remove comments
    next if !$_ or m(\A\s*\Z);                                                  # Skip blank lines
    say   STDERR timeStamp, " ", $_;                                            # Say command
    print STDERR $_ for qx($_);                                                 # Execute command
    say STDERR '';
   }
 }

sub zzz($;$$$)                                                                  # Execute lines of commands as one long command string separated by added &&'s and then check that the pipeline results in a return code of zero and that the execution results match the optional regular expression if one has been supplied; confess() to an error if either check fails.
 {my ($cmd, $success, $returnCode, $message) = @_;                              # Commands to execute - one per line with no trailing &&, optional regular expression to check for acceptable results, optional regular expression to check the acceptable return codes, message of explanation if any of the checks fail
  $cmd or confess "No command\n";                                               # Check that there is a command to execute
  my @c;                                                                        # Commands
  for(split /\n/, $cmd)                                                         # Split commands on new lines
   {s(#.*\Z)()gs;                                                               # Remove comments
    next unless m(\S);                                                          # Skip blank lines
    push @c, $_;                                                                # Save command
   }
  my $c = join ' && ', @c;                                                      # Command string to execute
  my $r = qx($c 2>&1);                                                          # Execute command
  my $R = $?;
  $r =~ s/\s+\Z//s;                                                             # Remove trailing white space from response

  confess "Error:\n".                                                           # Check the error code and results
    ($message ? "$message\n" : '').                                             # Explanation if supplied
    "$cmd\n".                                                                   # Commands being executed
    "Return code: $R\n".                                                        # Return code
    "Result:\n$r\n" if                                                          # Outout from commands so far
    $R && (!$returnCode or $R !~ /$returnCode/) or                              # Return code not zero and either no retirn code check or the return code checker failed
    $success && $r !~ m/$success/s;                                             # Results check failed
  $r
 }

sub parseCommandLineArguments(&$;$)                                             # Classify the specified array of words into positional parameters and keyword parameters, then call the specified sub with a reference to an array of positional parameters followed by a reference to a hash of keywords and their values and return the value returned by the sub
 {my ($sub, $args, $valid) = @_;                                                # Sub to call, list of arguments to parse, optional list of valid parameters else all parameters will be accepted
  my %v = $valid ? map {lc($_)=>1} @$valid : ();                                # Hash of valid normalized parameters
  my %h;
  my @a;
  for(@$args)
   {if (m/\A-+(\S+?)(=(.+))?\Z/)                                                # Keyword parameter
     {confess "Invalid parameter: $_\n" if $valid and !$v{lc($1)};              # Optionally validate parameters
      $h{lc($1)} = $3;                                                          # Save  valid parameter
     }
    else                                                                        # Positional parameter
     {push @a, $_;
     }
   }
  $sub->([@a], {%h})
 }

sub call(&@)                                                                    # Call the specified sub in a separate process, wait for it to complete, copy back the named L<our|https://perldoc.perl.org/functions/our.html> variables, free the memory used.
 {my ($sub, @our) = @_;                                                         # Sub to call, our variable names with preceding sigils to copy back
  my ($p) = caller;                                                             # Caller's package
  unless(my $pid = fork)                                                        # Fork - child
   {&$sub;                                                                      # Execute the sub
    my $m = join ", ", map {q(\\).$p.q(::).$_} @our;                            # Addresses for our variables
    my @s = '';                                                                 # Code to copy back our variables
    for my $our(@our)                                                           # Each variable
     {my ($sigil, $var) = $our =~ m(\A(.)(.+)\Z)s;                              # Sigil, variable name
      my $Our = $sigil.$p.q(::).$var;                                           # Add caller's package to variable name
      my $c = ord($sigil);                                                      # Differentiate between variables with the same type but different sigils
      my $file = qq(${$}$var$c.data);
      push @s, <<END                                                            # Save each our variable in a file
store \\$Our, q($file);
END
     }
    my $s = join "\n", @s;                                                      # Perl code to store our variables
    eval $s;                                                                    # Eavluate code to store our variables
    confess $@ if $@;                                                           # Confess any errors
    exit;                                                                       # End of child process
   }
  else                                                                          # Fork - parent
   {waitpid $pid,0;                                                             # Wait for child
    my @s = '';                                                                 # Code to retrieve our variables
    my @file;                                                                   # Transfer files
    for my $our(@our)
     {my ($sigil, $var) = $our =~ m(\A(.)(.+)\Z)s;                              # Sigil, variable name
      my $Our = $sigil.$p.q(::).$var;                                           # Add caller's package to variable name
      my $c = ord($sigil);                                                      # Differentiate between variables with the same type but different sigils
      my $file = qq($pid$var$c.data);                                           # Save file
      push @s, <<END;                                                           # Perl code to retrieve our variables
$Our = ${sigil}{retrieve q($file)};
END
      push @file, $file;                                                        # Remove transfer files
     }
    my $s = join "\n", @s;
    eval $s;                                                                    # Evaluate perl code
    unlink $_ for @file;                                                        # Remove transfer files
    confess "$@\n$s\n" if $@;                                                   # Confess to any errors
   }
 }

#1 Files and paths                                                              # Operations on files and paths
#2 Statistics                                                                   # Information about each file

sub fileSize($)                                                                 # Get the size of a file.
 {my ($file) = @_;                                                              # File name
  return (stat($file))[7] if -e $file;                                          # Size if file exists
  undef                                                                         # File does not exist
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

sub firstFileThatExists(@)                                                      # Returns the name of the first file that exists or undef if none of the named files exist
 {my (@files) = @_;                                                             # Files to check
  for(@files)
   {return $_ if -e $_;
   }
  undef                                                                         # No such file
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

BEGIN                                                                           # Some shorter undocumented names for these useful routines.
 {*fpd = *filePathDir;
  *fpe = *filePathExt;
  *fpf = *filePath;
 }

sub fp($)                                                                       # Get path from file name
 {my ($file) = @_;                                                              # File name
  return '' unless $file =~ m(\/);                                              # Must have a / in it else no path
  $file =~ s([^/]*+\Z) ()gsr
 }

sub fpn($)                                                                      # Remove extension from file name
 {my ($file) = @_;                                                              # File name
  return '' unless $file =~ m(/);                                               # Must have a / in it else no path
  $file =~ s(\.[^.]+?\Z) ()gsr
 }

sub fn($)                                                                       # Remove path and extension from file name
 {my ($file) = @_;                                                              # File name
  $file =~ s(\A.*/) ()gsr =~ s(\.[^.]+?\Z) ()gsr
 }

sub fne($)                                                                      # Remove path from file name
 {my ($file) = @_;                                                              # File name
  $file =~ s(\A.*/) ()gsr;
 }

sub fe($)                                                                       # Get extension of file name
 {my ($file) = @_;                                                              # File name
  return '' unless $file =~ m(\.)s;                                             # Must have a period
  my $f = $file =~ s(\.[^.]+?\Z) ()gsr;
  substr($file, length($f)+1)
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

sub trackFiles($@)                                                              # Track the existence of files
 {my ($label, @files) = @_;                                                     # Label, files
  say STDERR "$label ", dump([map{[fileSize($_), $_]} @files]);
 }

sub titleToUniqueFileName($$$$)                                                 # Create a file name from a title that is unique within the set %uniqueNames.
 {my ($uniqueFileNames, $title, $suffix, $ext) = @_;                            # Unique file names hash {} which will be updated by this method, title, file name suffix, file extension
  my $t = $title;                                                               # Title
     $t =~ s/[^a-z0-9_-]//igs;                                                  # Edit out characters that would produce annoying file names

  my $n = 1 + keys %$uniqueFileNames;                                           # Make the file name unique
  my $f = $t =~ m(\S) ?                                                         # File name without unique number if possible
        fpe(qq(${t}_${suffix}), $ext):
        fpe(        ${suffix},  $ext);

     $f = $t =~ m(\S) ?                                                         # Otherwise file name with unique number
      fpe(qq(${t}_${suffix}_${n}), $ext):
      fpe(     qq(${suffix}_${n}), $ext)
        if $$uniqueFileNames{$f};

  $$uniqueFileNames{$f}++;
  $f
 } # titleToUniqueFileName

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
# cluck "parseFileName is deprecated, please use fp, fn, fe, fpn, fne instead";
  return ($file) if $file =~ m{\/\Z}s or $file =~ m/\.\.\Z/s;                   # Its a folder
  if ($file =~ m/\.[^\/]+?\Z/s)                                                 # The file name has an extension
   {if ($file =~ m/\A.+[\/]/s)                                                  # The file name has a preceding path
     {my @f = $file =~ m/(\A.+[\/])([^\/]+)\.([^\/]+?)\Z/s;                     # File components
      return @f;
     }
    else                                                                        # There is no preceding path
     {my @f = $file =~ m/(\A.+)\.([^\/]+?)\Z/s;                                 # File components
      return (undef, @f)
     }
   }
  else                                                                          # The file name has no extension
   {if ($file =~ m/\A.+[\/]/s)                                                  # The file name has a preceding path
     {my @f = $file =~ m/(\A.+\/)([^\/]+?)\Z/s;                                 # File components
      return @f;
     }
    elsif ($file =~ m/\A[\/]./s)                                                # The file name has a single preceding /
     {return (q(/), substr($file, 1));
     }
    elsif ($file =~ m/\A[\/]\Z/s)                                               # The file name is a single /
     {my @f = $file =~ m/(\A.+\/)([^\/]+?)\Z/s;                                 # File components
      return (q(/));
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

sub absFromAbsPlusRel($$)                                                       # Create an absolute file from a an absolute file and a following relative file.
 {my ($a, $f) = @_;                                                             # Absolute file name, relative file name

  defined $a or confess "Specify an absolute file name for the first parameter";
  defined $f or confess "Specify a relative file name for the second parameter";

  $a =~ m(\A/)s or confess "$a is not an absolute file name";

  my ($ap, $af, $ax) = parseFileName($a);
  my ($fp, $ff, $fx) = parseFileName($f);

  return $ap if defined($f) and $f eq q();                                      # Blank file name relative to
  return fpf($ap, $f) if defined($ap) and !defined($fp);                        # Short file name relative to

  my @a = split m(/), $ap;
  my @f = split m(/), $fp;
  shift @f while @f and $f[0] eq q(.);                                          # Remove leading ./
  while(@a and @f and $f[0] eq q(..)) {pop @a; shift @f};                       # Remove leading ../
  @f && $f[0] eq q(..) and confess "$f has too many leading ../";
  return q(/).fpe(grep {$_ and m/\S/} @a, @f, $ff, $fx) if defined $fx;

  my @A = grep {$_ and m/\S/} @a, @f, $ff, $fx;                                 # Components of new file
  return q(/).fpe(@A)    if @A >  1 and  defined($fx);
  return q(/).fpf(@A)    if @A >  1 and !defined($fx) and  defined($ff);
  return q(/).fpd(@A)    if @A >  1 and !defined($fx) and !defined($ff);
  return q(/).$A[0].q(/) if @A == 1 and !defined($ff);
  return q(/).$A[0]      if @A == 1 and  defined($ff);
  q(/)
 }

sub relFromAbsAgainstAbs($$)                                                    # Derive a relative file name for the first absolute file relative to the second absolute file name.
 {my ($f, $a) = @_;                                                             # Absolute file to be made relative, absolute file to compare against
  defined $f or confess "Specify an absolute file name for the first parameter";
  defined $a or confess "Specify an absolute file name for the second parameter";
  $f =~ m(\A/)s or confess "$f is not an absolute file name";
  $a =~ m(\A/)s or confess "$a is not an absolute file name";

  my ($fp, $ff, $fx) = parseFileName($f);
  my ($ap, $af, $ax) = parseFileName($a);

  my @a = $ap ? split m(/), $ap : q(/);
  my @f = $fp ? split m(/), $fp : q(/);

  while(@a and @f and $a[0] eq $f[0]) {shift @a; shift @f};
  my @l = (q(..)) x scalar(@a);
  pop @l if $fp && $fp eq "/";
  push @l, q(..) if $ap && $ap eq "/" and defined $af;
  return fpe(@l, @f, grep{$_ and m/\S/} $ff, $fx) if  defined($fx);
  return fpf(@l, @f, grep{$_ and m/\S/} $ff)      if !defined($fx) and  defined($ff);
  my $s = fpd(@l, @f, grep{$_ and m/\S/} $ff);
  return "./" unless $s;
  $s;
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

sub findFiles($;$)                                                              # Find all the files under a folder and optionally filter the selected files with a regular expression
 {my ($dir, $filter) = @_;                                                      # Folder to start the search with, optional regular expression to filter files
  my @f;
  my $s = qx(find $dir -print0);
  utf8::decode($s);                                                             # Decode unicode file names
  for(split /\0/, $s)                                                           # Split out file names on \0
   {next if -d $_;                                                              # Do not include folder names
    next if $filter and $filter and !m($filter)s;                               # Filter out files that do not match the regular expression
    push @f, $_;
   }
  @f
 }

sub findDirs($;$)                                                               # Find all the folders under a folder and optionally filter the selected folders with a regular expression
 {my ($dir, $filter) = @_;                                                      # Folder to start the search with, optional regular expression to filter files
  my @d;
  my $s = qx(find $dir -print0);
  utf8::decode($s);                                                             # Decode unicode file names
  for(split /\0/, $s)                                                           # Split out file names on \0
   {next unless -d $_;                                                          # Include only folders
    next if $filter and $filter and !m($filter)s;                               # Filter out directories that do not match the regular expression
    push @d, $_;
   }
  @d
 }

sub fileList($)                                                                 # Files that match a given search pattern.
 {my ($pattern) = @_;                                                           # Search pattern
  bsd_glob($pattern, GLOB_MARK | GLOB_TILDE)
 }

sub searchDirectoryTreesForMatchingFiles(@)                                     # Search the specified directory trees for files that match the specified extensions - the argument list should include at least one folder and one extension to be useful.
 {my (@foldersandExtensions) = @_;                                              # Mixture of folder names and extensions
  my @folder     = grep { -d $_ } @_;                                           # Folders
  my @extensions = grep {!-d $_ } @_;                                           # Extensions
  for(@extensions)                                                              # Prefix period to extension of not all ready there
   {$_ = qq(\.$_) unless m(\A\.)s
   }
  my $e = join '|', @extensions;                                                # Files
  my @f;                                                                        # Files
  for my $dir(@folder)                                                          # Directory
   {for my $d(split /\0/, qx(find $dir -print0))
     {next if -d $d;                                                            # Do not include folder names
      push @f, $d if $d =~ m(($e)\Z)is;
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

sub findFileWithExtension($@)                                                   # Find the first extension from the specified extensions that produces a file that exists when appended to the specified file
 {my ($file, @ext) = @_;                                                        # File name minus extensions, possible extensions
  for my $ext(@ext)
   {my $f = fpe($file, $ext);
    return $ext if -e $f;                                                       # First matching file
   }
  undef                                                                         # No matching file
 } # findFileWithExtension

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
    "Cannot open file for unicode input, file:\n$f\n$!\n";
  local $/ = undef;
  my $s = eval {<$F>};
  $@ and confess $@;
  $s
 }

sub readUtf16File($)                                                            # Read a file containing unicode in utf-16 format
 {my ($file) = @_;                                                              # Name of file to read
  my $f = $file;
  defined($f) or  confess "Cannot read undefined file\n";
  $f =~ m(\n) and confess "File name contains a new line:\n=$file=\n";
  -e $f or confess "Cannot read file because it does not exist, file:\n$f\n";
  open(my $F, "<:encoding(UTF-16)", $f) or confess
    "Cannot open file for utf16 input, file:\n$f\n$!\n";
  local $/ = undef;
  my $s = eval {<$F>};
  $@ and confess $@;
  $s
 }

sub readBinaryFile($)                                                           # Read binary file - a file whose contents are not to be interpreted as unicode.
 {my ($file) = @_;                                                              # File to read
  my $f = $file;
  -e $f or confess "Cannot read binary file because it does not exist:\n$f\n";
  open my $F, "<$f" or confess "Cannot open binary file for input:\n$f\n$!\n";
  local $/ = undef;
  <$F>;
 }

sub removeBOM($)                                                                # Remove BOM from a string
 {my ($s) = @_;                                                                 # String
  $s =~ s(\A\xff\xfe) ()r;
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

sub writeFile($$)                                                               # Write a unicode string to a file after creating a path to the file if necessary and return the name of the file on success else confess.
 {my ($file, $string) = @_;                                                     # File to write to or undef for a temporary file, unicode string to write
  $file //= temporaryFile;
  $string or carp "No string for file:\n$file\n";
  makePath($file);
  open my $F, ">$file" or confess "Cannot open file for write because:\n".
               "$file\n$!\n";
  binmode($F, ":utf8");
  print  {$F} $string;
  close  ($F);
  -e $file or confess "Failed to write to file:\n$file\n";
  $file
 }

sub writeFiles($;$)                                                             # Write the values of a hash as a file identified by the key of the value
 {my ($hash, $folder) = @_;                                                     # Hash of key value pairs representing files and data, optional folder to contain files else the current folder
  for my $file(sort keys %$hash)                                                # Write file data for each hash key
   {writeFile(fpf($folder ? $folder : '.', $file), $hash->{$file})
   }
 }

sub appendFile($$)                                                              # Append a unicode string to a file after creating a path to the file if necessary and return the name of the file on success else confess.
 {my ($file, $string) = @_;                                                     # File to append to, unicode string to append
  $file or confess "No file name supplied\n";
  $string or carp "No string for file:\n$file\n";
  makePath($file);
  open my $F, ">>$file" or confess "Cannot open for write file:\n$file\n$!\n";
  binmode($F, ":utf8");
  print  {$F} $string;
  close  ($F);
  -e $file or confess "Failed to write to file:\n$file\n";
  $file
 }

sub writeBinaryFile($$)                                                         # Write a non unicode string to a file in after creating a path to the file if necessary and return the name of the file on success else confess.
 {my ($file, $string) = @_;                                                     # File to write to, non unicode string to write
  $file or confess "No file name supplied\n";
  $string or confess "No string for file:\n$file\n";
  makePath($file);
  open my $F, ">$file" or confess "Cannot open file for binary write:\n".
               "$file\n$!\n";
  binmode($F);
  print  {$F} $string;
  close  ($F);
  -e $file or confess "Failed to write in binary to file:\n$file\n";
  $file
 }

sub createEmptyFile($)                                                          # Create an empty file - L<writeFile|/writeFile> complains if no data is written to the file -  and return the name of the file on success else confess.
 {my ($file) = @_;                                                              # File to create
  $file or confess "No file name supplied\n";
  return $file if -e $file;                                                     # Return file name as proxy for success if file already exists
  makePath($file);
  open my $F, ">$file" or confess "Cannot create empty file:\n$file\n$!\n";
  binmode($F);
  print  {$F} '';
  close  ($F);
  -e $file or confess "Failed to create empty file:\n$file\n";
  $file                                                                         # Return file name on success
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

sub convertImageToJpx690($$;$)                                                  # Convert an image to jpx format using versions of ImageMagick version 6.9.0 and above
 {my ($source, $target, $Size) = @_;                                            # Source file, target folder (as multiple files will be created),  optional size of each tile - defaults to 256
  my $size = $Size // 256;                                                      # Size of each tile
  my $N    = 4;                                                                 # Power of ten representing the maximum number of tiles
  -e $source or confess "Image file does not exist:\n$source\n";                # Check source
  $target  = fpd($target);                                                      # Make sure the target is a folder
  makePath($target);                                                            # Make target folder
  my ($w, $h) = imageSize($source);                                             # Image size
  my $W = int($w/$size); ++$W if $w % $size;                                    # Image size in tiles
  my $H = int($h/$size); ++$H if $h % $size;
  writeFile(filePath($target, "jpx.data"), <<END);                              # Write jpx header
version 1
type    jpx
size    $size
source  $source
width   $w
height  $h
END

  if (1)                                                                        # Create tiles
   {my $s = quoteFile($source);
    my $t = quoteFile($target."%0${N}d.jpg");
    my $c = qq(convert $s -crop ${size}x${size} $t);
    say STDERR $c;
    say STDERR $_ for qx($c 2>&1);
   }

  if (1)                                                                        # Rename tiles in two dimensions
   {my $W = int($w/$size); ++$W if $w % $size;
    my $H = int($h/$size); ++$H if $h % $size;
    my $k = 0;
    for   my $Y(1..$H)
     {for my $X(1..$W)
       {my $s = sprintf("${target}%0${N}d.jpg", $k++);
        my $t = "${target}/${Y}_${X}.jpg";
        rename $s, $t or confess "Cannot rename file:\n$s\nto:\n$t\n";
        -e $t or confess "Cannot create file:\n$t\n";
       }
     }
   }
 }

#convertImageToJpx690(
#"/home/phil/audioImageCache/images/Blacktipshark.JPG",
#"/tmp/AppaAppsPhotoApp/users/philiprbrenan/GoneFishing/assets/images/Shark.Blacktip/"
#); exit;

sub convertImageToJpx($$;$)                                                     # Convert an image to jpx format - works with: Version: ImageMagick 6.8.9-9 Q16 x86_64 2017-03-14. Later versions are handled by convertImageToJpx690.
 {my ($source, $target, $Size) = @_;                                            # Source file, target folder (as multiple files will be created),  optional size of each tile - defaults to 256

  if (1)
   {my $r = qx(convert --version);
    if ($r =~ m(\AVersion: ImageMagick ((\d|\.)+)))
     {my $version = join '', map {sprintf("%04d", $_)} split /\./, $1;
      return &convertImageToJpx690(@_) if $version >= 600090000;
     }
    else {confess "Please install Imagemagick:\nsudo apt install imagemagick"}
   }

  -e $source or confess "Image file does not exist:\n$source\n";
  my $size = $Size // 256;

  makePath($target);

  my ($w, $h) = imageSize($source);                                             # Write Jpx header
  writeFile(filePath($target, "jpx.data"), <<END);
version 1
type    jpx
size    $size
source  $source
width   $w
height  $h
END

  if (1)                                                                        # Create tiles
   {my $s = quoteFile($source);
    my $t = quoteFile($target);
    my $c = qq(convert $s -crop ${size}x${size} $t);
    say STDERR $c;
    say STDERR $_ for qx($c 2>&1);
   }

  if (1)                                                                        # Rename tiles in two dimensions
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

sub convertDocxToFodt($$)                                                       # Convert a .docx file to .fodt using unoconv which must not be running elsewhere at the time.  L<Unoconv|/https://github.com/dagwieers/unoconv> can be installed via:\m  sudo apt install sharutils unoconv
 {my ($inputFile, $outputFile) = @_;                                            # Input file, output file
  my $r = qx(unoconv -f fodt -o "$outputFile" "$inputFile");                    # Perform conversion
  !$r or confess "unoconv failed, try closing libreoffice if it is open\n". $r;
 }

# Tests in: /home/phil/perl/z/unoconv/testCutOutImagesInFodtFile.pl
sub cutOutImagesInFodtFile($$$)                                                 # Cut out the images embedded in a .fodt file, perhaps produced via L<convertDocxToFodt|/convertDocxToFodt>, placing them in the specified folder and replacing them in the source file with:\m  <image href="$imageFile" outputclass="imageType">\mThis conversion requires that you have both L<imagmagick|/https://www.imagemagick.org/script/index.php> and L<unoconv|/https://github.com/dagwieers/unoconv> installed on your system:\m    sudo apt install sharutils  imagemagick unoconv
 {my ($inputFile, $outputFolder, $imagePrefix) = @_;                            # Input file,  output folder for images, a prefix to be added to image file names
  my $source = readFile($inputFile);                                            # Read .fodt file
  say STDERR "Start image location in string of ", length($source);

  my @p;
  my $p = 0;
  my ($s1, $s2) = ('<office:binary-data>', '</office:binary-data>');
  for(;;)                                                                       # Locate images
   {my $q = index($source, $s1, $p);  last if $q < 0;
    my $Q = index($source, $s2, $q);  last if $Q < 0;
    push @p, [$q+length($s1), $Q-$q-length($s1)];
    $p = $Q;
   }
  say STDERR "Cutting out ", scalar(@p), " images";                             # Cut out images

  my $imageNumber = @p;                                                         # Number the image files

  for(reverse @p)                                                               # We cut out in reverse to preserve the offsets of the images yet to be cut out
   {my ($p, $l) = @$_;                                                          # Position, length of image

    my $i = substr($source, $p, $l);                                            # Image text uuencoded
       $i =~ s/ //g;                                                            # Remove leading spaces on each line

    my ($ext, $type, $im) =                                                     # Decide on final image type, possibly via an external imagemagick conversion on windows, or an internal imagemagick conversion locally
      $i =~ m/\AiVBOR/    ? ('png')            :
      $i =~ m/\AAQAAAG/   ? ('png', 'emf')     :
      $i =~ m/\AVkNMT/    ? ('png', 'svm')     :
      $i =~ m/\A183G/     ? ('png', '', 'wmf') :
      $i =~ m/\A\/9j/     ? ('jpg')            :
      $i =~ m/\AR0lGODlh/ ? ('gif')            :
      confess "Unknown image type: ". substr($i, 0, 16);

    say STDERR "$imageNumber cut $ext from $p for $l";

    my $imageBinary = decodeBase64($i);                                         # Decode image
    my $imageFile =                                                             # Image file anme
      fpe($outputFolder, join(q(), $imagePrefix, q(_), $imageNumber), $ext);

    if (!$type)
     {writeBinaryFile($imageFile, $imageBinary);
     }

    my $xml = "<image href=\"$imageFile\" outputclass=\"$ext\"\/>";             # Create image command
    substr($source, $p, $l) = $xml;                                             # Replace the image source with an image command
    $imageNumber--;
   }
  $source
 }

=pod
       fpe($outputfolder, join(q(), $imagePrefix, q(_), $imageNumber, $ext);
    my $imageDir = sub
     {return fpf($outImages, $projectGroup) if $project->energistics;
      fpf($outDir, $projectGroup, q(images));
     }->();

    my $imageTarget  = fpe($imageDir, $imageNumber, $type);                 # Image file target after conversion
    my $imageTargetX = fpe($imageDir, $imageNumber, $ext);                  # Image file target after intermediate conversion
    my $imageTargetR = sub                                                  # Image file relative to Dita
     {fpe(qw(images), $imageNumber, $type)
     }->();

    if ($project->energistics)                                              # EO21 EO22 Image naming convention for Energistics and auto convert file to run on windows
     {my $n = $projectGroup;
      my $v = $project->energisticsVersion;
      my $N = substr(('0'x6).$imageNumber, -6) =~ s((\d\d\d)(\d)) ($1-$2)gr;
      my $i = $n.q(_IMAGES);                                                # Images sub folder
      my $f = $n."-$N-0-$v";                                                # Image file name
      $imageTarget  = fpe($outDir, $n, $n.q(_TOPICS), $i, $f, $type);
      $imageTargetX = fpe($outDir, $n, $n.q(_TOPICS), $i, $f, $ext);
      makePath($imageTarget);
      $imageTargetR = fpe($i, $f, $type);                                   # Image file relative to Dita

# https://www.imagemagick.org/discourse-server/viewtopic.php?t=20611 - convert emf to png on Windows
        if ($ext)                                                             # External conversion script
         {my $dir = q(..\\).$n.q(\\).$n.q(_TOPICS);
          push @imageConversionsOnWindows,
q("C:\Program Files\ImageMagick-7.0.7-Q16\magick.exe" ).
qq(-density $imageDensity $dir\\$i\\$f.$ext $dir\\$i\\$f.$type);
           }
         }

        if ($im)                                                                # Decoded intermediate via image magick running locally
         {my $f = filePathExt($imageNumber, $im);                               # Intermediate file type
          writeFile($imageUue, "begin-base64 664 $f\n$i====");                  # Uudecode to .emf
          zzz(<<"END");                                                         # Image conversion commands
cd "$imageDirTmp" && uudecode < $imageUue
convert -density 600 "$f" "$imageTarget"
END
         }
        elsif ($ext)                                                            # Decoded intermediate via image magick running remotely on Windows
         {my $f = filePathExt($imageNumber, $ext);                              # Intermediate file type
          writeFile($imageUue, "begin-base64 664 $imageTargetX\n$i====");       # Uudecode to internediate type
          zzz(<<"END");                                                         # Image conversion commands
cd "$imageDirTmp" && uudecode < $imageUue
END
         }
        else                                                                    # Decode directly
         {writeFile($imageUue, "begin-base64 664 $imageTarget\n$i====");        # Uudecode
          makePath($imageTarget);
          zzz(<<"END");                                                         # Image conversion commands
cd "$imageDirTmp" && uudecode < "$imageUue"
END
         }
=cut

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
  my $s = eval {encode_base64($string, '')};
  confess $@ if $@;                                                             # So we get a trace back
  $s
 }

sub decodeBase64($)                                                             # Decode a string in base 64.
 {my ($string) = @_;                                                            # String to decode
  my $s   = eval {decode_base64($string)};
  confess $@ if $@;                                                             # So we get a trace back
  $s
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
  ref($d) =~ /array/i or confess "Array reference required not:\n".dump($d);
  my @D;                                                                        # Maximum width of each column
# my @C;                                                                        # Whether column has non numeric
  for   my $e(@$d)
   {ref($e) =~ /array/i or confess "Array reference required not:\n".dump($e);
    for my $D(0..$#$e)                                                          # Each column index
     {my $a  = $D[$D]           // 0;                                           # Maximum length of data so far
      my $b  = length($e->[$D]) // 0;                                           # Length of current item
      $D[$D] = ($a > $b ? $a : $b);                                             # Update maximum length
#      $C[$D] = 1 if !$C[$D] and                                                 # Not a number in this column
#          $e->[$D] !~ /\A\s*[-+]?\s*[0-9,]+(\.\d+)?([Ee]\s*[-+]?\s*\d+)?\s*\Z/;
     }
   }

  my @t;                                                                        # Formatted data
  for   my $e(@$d)
   {my $t = '';                                                                 # Formatted text
    for my $D(0..$#$e)
     {my $m = $D[$D];                                                           # Maximum width
      my $i = $e->[$D]//'';                                                     # Current item
#     if ($C[$D])                                                               # Not a number - left justify
      if ($i !~ /\A\s*[-+]?\s*[0-9,]+(\.\d+)?([Ee]\s*[-+]?\s*\d+)?\s*\Z/)       # Not a number - left justify                                                        # Not a number - left justify
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
 {my ($data, $title, $separator) = @_;                                          # Data to be formatted, optional referebce to an array of titles, optional line separator
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

#1 LVALUE methods                                                               # Replace $a->{value} = $b with $a->value = $b which reduces the amount of typing required, is easier to read and provides a hard check that {value} is spelled correctly.
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

sub assertRef(@)                                                                # Confirm that the specified references are to the package into which this routine has been exported.
 {my (@refs) = @_;                                                              # References
  my ($package) = caller;                                                       # Package
  for(@_)                                                                       # Check each reference
   {my $r = ref($_);
    $r && $r eq $package or confess "Wanted reference to $package, but got $r";
   }
  1
 }

sub ˢ(&)                                                                        # Immediately executed inline sub to allow a code block before if.
 {my ($sub) = @_;                                                               # Sub as {} without the word "sub"
  &$sub
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

sub nws($)                                                                      # Normalize white space in a string to make comparisons easier. Leading and trailing white space is removed; blocks of white space in the interior are reduced to a singe space.  In effect: this puts everything on one long line with never more than a space at a time.
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

sub saveCodeToS3($$$;$)                                                         # Save source code files
 {my ($saveCodeEvery, $zipFileName, $bucket, $S3Parms) = @_;                    # Save every seconds, zip file name, bucket/key, additional S3 parameters like profile or region as a string
  my $saveTimeFile = q(.codeSaveTimes);                                         # Get last save time if any
  my $s3Parms = $S3Parms // '';
  my $lastSaveTime = -e $saveTimeFile ? retrieve($saveTimeFile) : undef;        # Get last save time
  return if $lastSaveTime and $lastSaveTime->[0] > time - $saveCodeEvery;       # Too soon

  return if fork;                                                               # Fork zip and upload
  say STDERR &timeStamp." Saving latest version of code to S3";

  my $z = filePathExt($zipFileName, q(zip));                                    # Zip file
  unlink $z;                                                                    # Remove old zip file

  if (my $c = <<END =~ s/\n/ /gsr)                                              # Zip command
zip -qr $z *
END
   {my $r = qx($c);
    confess "$c\n$r\n" if $r =~ m(\S);                                          # Confirm zip
   }

  if (my $c = "aws s3 cp $z s3://$bucket/$zipFileName.zip $s3Parms")            # Upload zip
   {my $r = qx($c);
    confess "$c\n$r\n" if $r =~ m(\S);                                          # Confirm upload
   }

  store([time], $saveTimeFile);                                                 # Save last save time
  unlink $z;                                                                    # Remove old zip file
  say STDERR &timeStamp." Saved latest version of code to S3";
  exit;
 }

sub saveSourceToS3($;$)                                                         # Save source code
 {my ($aws, $saveIntervalInSeconds) = @_;                                       # Aws target file and keywords, save internal
  $saveIntervalInSeconds //= 1200;                                              # Default save time
  cluck "saveSourceToS3 is deprecated, please use saveCodeToS3 instead";
  unless(fork())
   {my $saveTime = "/tmp/saveTime/$0";                                          # Get last save time if any
    makePath($saveTime);

    if (my $lastSaveTime = fileModTime($saveTime))                              # Get last save time
     {return if $lastSaveTime > time - $saveIntervalInSeconds;                  # Already saved
     }

    say STDERR &timeStamp." Saving latest version of code to S3";
    unlink my $z = qq(/tmp/DataTableText/save/$0.zip);                          # Zip file
    makePath($z);                                                               # Zip file folder
    my $c = qq(zip -r $z $0);                                                   # Zip command
    print STDERR $_ for qx($c);                                                 # Zip file to be saved
    my $a = qq(aws s3 cp $z $aws);                                              # Aws command
    my $r = qx($a);                                                             # Copy zip to S3
    #!$r or confess $r;
    writeFile($saveTime, time);                                                 # Save last save time
    say STDERR &timeStamp." Saved latest version of code to S3";
    exit;
   }
 }

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

sub wwwEncode($)                                                                # Replace spaces in a string with %20
 {my ($string) = @_;                                                            # String
  $string =~ s(\s) (%20)gsr;
 }

#1 Documentation                                                                # Extract, format and update documentation for a perl module

sub htmlToc($@)                                                                 # Generate a table of contents for some html
 {my ($replace, $html) = @_;                                                    # Substring within the html to be replaced with the toc, string of html
  my @toc;
  my %toc;

  for(split /\n/, $html)
   {next unless  /\A\s*<h(\d)\s+id="(.+?)"\s*>(.+?)<\/h\d>\s*\Z/;
    confess "Duplicate id $2\n" if $toc{$2}++;
    push @toc, [$1, $2, $3];
   }

  my @h;
  for my $head(keys @toc)
   {my ($level, $id, $title) = @{$toc[$head]};
    my $spacer = '&nbsp;' x (4*$level);
    push @h, <<END if $level < 2;
<tr><td>&nbsp;
END
    my $n = $head+1;
    push @h, <<END;
<tr><td align=right>$n<td>$spacer<a href="#$id">$title</a>
END
   }

  my $h = <<END.join "\n", @h, <<END;
<table cellspacing=10 border=0>
END
</table>
END

  $html =~ s($replace) ($h)gsr;
 }

sub extractTest($)                                                              #P Extract a line of a test.
 {my ($string) = @_;                                                            # String containing test line
  $string =~ s/\A\s*{?(.+?)\s*#.*\Z/$1/;                                        # Remove any initial white space and possible { and any trailing white space and comments
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
  my %exported;                                                                 # Exported methods
  my %userFlags;                                                                # User flags
  my $oneLineDescription = qq(\n);                                              # One line description from =head1 Name
  my $install = '';                                                             # Additional installation notes
  my @doc;                                                                      # Documentation
  my @private;                                                                  # Documentation of private methods
  my $level = 0; my $off = 0;                                                   # Header levels

  my $Source = my $source  = readFile($perlModule);                             # Read the perl module

  if ($source =~ m(our\s+\$VERSION\s*=\s*(\S+)\s*;)s)                           # Update references to examples so we can include html and images etc. in the module
   {my $V = $1;                                                                 # Quoted version
    if (my $v = eval $V)                                                        # Remove any quotes
     {my $s = $source;
      $source =~                                                                # Replace example references in source
        s((https://metacpan\.org/source/\S+?-)(\d+)(/examples/))
         ($1$v$3)gs;
     }
   }

  if ($source =~ m(\n=head1\s+Name\s+(?:\w|:)+\s+(.+?)\n)s)                     # Extract one line description from =head1 Name ... Module name ... one line description
   {my $s = $1;
    $s =~ s(\A\s*-\s*) ();                                                      # Remove optional leading -
    $s =~ s(\s+\Z)     ();                                                      # Remove any trailing spaces
    $oneLineDescription = "\n$s\n";                                             # Save description
   }

  push @doc, <<"END";                                                           # Documentation
`head1 Description
$oneLineDescription
The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.

END

  my @lines = split /\n/, $source;                                              # Split source into lines

  for my $l(keys @lines)                                                        # Tests associated with each method
   {my $line = $lines[$l];
    if (my @tags = $line =~ m/(?:\s#T((?:\w|:)+))/g)
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
   {do "./$perlModule";
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
    elsif ($line =~ /\A#C(?:ollaborators)?\s+(\S+)\s+(.+?)\s*\Z/)               # Collaborators
     {$collaborators{$1} = $2;
     }
    elsif ($line =~ /\A#I(?:nstall(?:ation)?)?\s+(.+)\Z/)                       # Extra install instructions
     {$install = "\\m$1\\m";
     }
    elsif ($line =~ /\A#/)                                                      # Switch documentation off
     {$level = 0;
     }
    elsif ($level and $line =~                                                  # Documentation for a method
     /\A\s*sub\s*(.*?)?(\s*:lvalue)?\s*#(\w*)\s+(.+?)\s*\Z/)
     {my ($sub, $lvalue, $flags, $comment, $example, $produces) =               # Name from sub, flags, description
         ($1, $2, $3, $4);

      $flags //= '';                                                            # No flags found

      if ($comment =~ m/\A(.*)Example:(.+?)\Z/is)                               # Extract example
       {$comment = $1;
       ($example, $produces) = split /:/, $2, 2;
       }

      my $signature = $sub =~ s/\A\s*(\w|:)+//gsr =~                            # Signature
                              s/\A\(//gsr     =~
                              s/\)\s*(:lvalue\s*)?\Z//gsr =~
                              s/;//gsr;                                         # Remove optional parameters marker from signature
      my $name      = $sub =~ s/\(.*?\)//r;                                     # Method name after removing parameters

      my $methodX   = $flags =~ m/X/;                                           # Die rather than return undef
      my $private   = $flags =~ m/P/;                                           # Private
      my $static    = $flags =~ m/S/;                                           # Static
      my $iUseful   = $flags =~ m/I/;                                           # Immediately useful
      my $exported  = $flags =~ m/E/;                                           # Exported
      my $userFlags = $flags =~ s/[EIPSX]//gsr;                                 # User flags == all flags minus the known flags

      $methodX  {$name} = $methodX   if $methodX;                               # MethodX
      $private  {$name} = $private   if $private;                               # Private
      $static   {$name} = $static    if $static;                                # Static
      $iUseful  {$name} = $comment   if $iUseful;                               # Immediately useful
      $exported {$name} = $exported  if $exported;                              # Exported

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

      my @method;                                                               # Accumulate method documentation

      if (1)                                                                    # Section title
       {my $h = $private ? 2 : $headLevel;
        push @method, "\n=head$h $name($signature)\n\n$comment\n";              # Method description
       }

      push @method, indentString(formatTable
       ([map{[$parameters[$_], $parmDescriptions[$_]]} keys @parameters],
        [qw(Parameter Description)]), '  ')
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
       "  $package\:\:$name\n"                 if $static;

      push @method,                                                             # Exported
       "\nThis method can be imported via:\n\n".
       "  use $package qw($name)\n"            if $exported;

      push @{$private ? \@private : \@doc}, @method;                            # Save method documentation in correct section
     }
    elsif ($level and $line =~                                                  # Documentation for a generated lvalue * method = sub name comment
     /\A\s*genLValue(?:\w+?)Methods\s*\(q(?:w|q)?\((\w+)\)\);\s*#\s*(.+?)\s*\Z/)
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

  if (keys %exported)                                                           # Exported methods available
   {push @doc, <<"END";


`head1 Exports

All of the following methods can be imported via:

  use $package qw(:all);

Or individually via:

  use $package qw(<method>);


END

    my $n = 0;
    for my $s(sort {lc($a) cmp lc($b)} keys %exported)                          # Alphabetic listing of exported methods
     {push @doc, ++$n." L<$s|/$s>\n"
     }
   }

  push @doc, <<END;                                                             # Standard stuff
`head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install $package

`head1 Author

L<philiprbrenan\@gmail.com|mailto:philiprbrenan\@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

`head1 Copyright

Copyright (c) 2016-2018 Philip R Brenan.

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

  zzz("pod2html --infile=$perlModule --outfile=zzz.html && ".                   # View documentation
      " firefox file:zzz.html && ".
      " (sleep 5 && rm zzz.html pod2htmd.tmp) &");
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
# Export - eeee
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw(formatTable);
@EXPORT_OK    = qw(
absFromAbsPlusRel addCertificate appendFile assertRef
binModeAllUtf8
call checkFile checkFilePath checkFilePathExt checkFilePathDir
checkKeys clearFolder contains containingPowerOfTwo
containingFolder convertDocxToFodt convertImageToJpx convertUnicodeToXml
createEmptyFile currentDirectory currentDirectoryAbove cutOutImagesInFodtFile
dateStamp dateTimeStamp decodeJson decodeBase64
encodeJson encodeBase64
fileList fileModTime fileOutOfDate
filePath filePathDir filePathExt fileSize findDirs findFiles
findFileWithExtension
firstFileThatExists
formatTableBasic fpd fpe fpf fp fe fn fpn fne fullFileName
genLValueArrayMethods genLValueHashMethods
genLValueScalarMethods genLValueScalarMethodsWithDefaultValues
hostName htmlToc
imageSize indentString isBlank
javaPackage javaPackageAsFileName
keyCount
loadArrayArrayFromLines loadArrayFromLines
loadHashArrayFromLines loadHashFromLines
makePath matchPath max microSecondsSinceEpoch min
nws
pad parseFileName parseCommandLineArguments powerOfTwo printFullFileName printQw
quoteFile
readBinaryFile readFile readUtf16File relFromAbsAgainstAbs removeBOM removeFilePrefix
saveCodeToS3 saveSourceToS3 searchDirectoryTreesForMatchingFiles
setIntersectionOfTwoArraysOfWords setUnionOfTwoArraysOfWords
temporaryDirectory temporaryFile temporaryFolder timeStamp trackFiles trim
updateDocumentation updatePerlModuleDocumentation userId
versionCode versionCodeDashed
wwwEncode writeBinaryFile writeFile writeFiles
xxx XXX
zzz
ˢ
);
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation
#C mim@cpan.org Testing on windows

=pod

=encoding utf-8

=head1 Name

Data::Table::Text - Write data in tabular text format.

=head1 Synopsis

 use Data::Table::Text;

Print an array of arrays:

 say STDERR formatTable
    ([[qw(A   B   C  )],
      [qw(AA  BB  CC )],
      [qw(AAA BBB CCC)],
      [qw(1   22  333)]],
     [qw (aa  bb  cc)]);

 #    aa   bb   cc
 # 1  A    B    C
 # 2  AA   BB   CC
 # 3  AAA  BBB  CCC
 # 4    1   22  333

Print an array of hashes:

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

Write data in tabular text format.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Time stamps

Date and timestamps as used in logs of long running commands

=head2 dateTimeStamp()

Year-monthNumber-day at hours:minute:seconds


=head2 dateStamp()

Year-monthName-day


=head2 versionCode()

YYYmmdd-HHMMSS


=head2 versionCodeDashed()

YYYmmdd-HHMMSS


=head2 timeStamp()

hours:minute:seconds


=head2 microSecondsSinceEpoch()

Micro seconds since unix epoch


=head1 Command execution

Various ways of processing commands

=head2 xxx(@)

Execute a command checking and logging the results: the command to execute is specified as one or more strings with optionally the last string being a regular expression that is used to confirm that the command executed successfully and thus that it is safe to suppress the command output as uninteresting.

     Parameter  Description
  1  @cmd       Command to execute followed by an optional regular expression to test the results

=head2 yyy($)

Execute a block of shell commands line by line after removing comments - stop if there is a non zero return code from any command

     Parameter  Description
  1  $cmd       Commands to execute separated by new lines

=head2 zzz($$$$)

Execute lines of commands as one long command string separated by added &&'s and then check that the pipeline results in a return code of zero and that the execution results match the optional regular expression if one has been supplied; confess() to an error if either check fails.

     Parameter    Description
  1  $cmd         Commands to execute - one per line with no trailing &&
  2  $success     Optional regular expression to check for acceptable results
  3  $returnCode  Optional regular expression to check the acceptable return codes
  4  $message     Message of explanation if any of the checks fail

=head2 parseCommandLineArguments(&$$)

Classify the specified array of words into positional parameters and keyword parameters, then call the specified sub with a reference to an array of positional parameters followed by a reference to a hash of keywords and their values and return the value returned by the sub

     Parameter  Description
  1  $sub       Sub to call
  2  $args      List of arguments to parse
  3  $valid     Optional list of valid parameters else all parameters will be accepted

=head2 call(&@)

Call the specified sub in a separate process, wait for it to complete, copy back the named L<our|https://perldoc.perl.org/functions/our.html> variables, free the memory used.

     Parameter  Description
  1  $sub       Sub to call
  2  @our       Our variable names with preceding sigils to copy back

Example:


  ˢ{our $a = q(1);


=head1 Files and paths

Operations on files and paths

=head2 Statistics

Information about each file

=head3 fileSize($)

Get the size of a file.

     Parameter  Description
  1  $file      File name

=head3 fileModTime($)

Get the modified time of a file in seconds since the epoch.

     Parameter  Description
  1  $file      File name

=head3 fileOutOfDate(&$@)

Calls the specified sub once for each source file that is missing, then calls the sub for the target if there were any missing files or if the target is older than any of the non missing source files or if the target does not exist. The file name is passed to the sub each time in $_. Returns the files to be remade in the order they should be made.

     Parameter  Description
  1  $make      Make with this sub
  2  $target    Target file
  3  @source    Source files

Example:

  fileOutOfDate {make($_)}  $target, $source1, $source2, $source3;

=head3 firstFileThatExists(@)

Returns the name of the first file that exists or undef if none of the named files exist

     Parameter  Description
  1  @files     Files to check

=head2 Components

Create file names from file name components

=head3 filePath(@)

Create a file path from an array of file name components. If all the components are blank then a blank file name is returned.

     Parameter  Description
  1  @file      File components

=head3 filePathDir(@)

Directory from an array of file name components. If all the components are blank then a blank file name is returned.

     Parameter  Description
  1  @file      File components

=head3 filePathExt(@)

File name from file name components and extension.

     Parameter  Description
  1  @File      File components and extension

=head3 fp($)

Get path from file name

     Parameter  Description
  1  $file      File name

=head3 fpn($)

Remove extension from file name

     Parameter  Description
  1  $file      File name

=head3 fn($)

Remove path and extension from file name

     Parameter  Description
  1  $file      File name

=head3 fne($)

Remove path from file name

     Parameter  Description
  1  $file      File name

=head3 fe($)

Get extension of file name

     Parameter  Description
  1  $file      File name

=head3 checkFile($)

Return the name of the specified file if it exists, else confess the maximum extent of the path that does exist.

     Parameter  Description
  1  $file      File to check

=head3 checkFilePath(@)

L<Check|/checkFile> a folder name constructed from its L<components|/filePath>

     Parameter  Description
  1  @file      File components

=head3 checkFilePathExt(@)

L<Check|/checkFile> a file name constructed from its  L<components|/filePathExt>

     Parameter  Description
  1  @File      File components and extension

=head3 checkFilePathDir(@)

L<Check|/checkFile> a folder name constructed from its L<components|/filePathDir>

     Parameter  Description
  1  @file      File components

=head3 quoteFile($)

Quote a file name.

     Parameter  Description
  1  $file      File name

=head3 removeFilePrefix($@)

Removes a file prefix from an array of files.

     Parameter  Description
  1  $prefix    File prefix
  2  @files     Array of file names

=head3 trackFiles($@)

Track the existence of files

     Parameter  Description
  1  $label     Label
  2  @files     Files

=head3 titleToUniqueFileName($$$$)

Create a file name from a title that is unique within the set %uniqueNames.

     Parameter         Description
  1  $uniqueFileNames  Unique file names hash {} which will be updated by this method
  2  $title            Title
  3  $suffix           File name suffix
  4  $ext              File extension

=head2 Position

Position in the file system

=head3 currentDirectory()

Get the current working directory.


=head3 currentDirectoryAbove()

The path to the folder above the current working folder.


=head3 parseFileName($)

Parse a file name into (path, name, extension)

     Parameter  Description
  1  $file      File name to parse

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

=head3 findFiles($$)

Find all the files under a folder and optionally filter the selected files with a regular expression

     Parameter  Description
  1  $dir       Folder to start the search with
  2  $filter    Optional regular expression to filter files

=head3 findDirs($$)

Find all the folders under a folder and optionally filter the selected folders with a regular expression

     Parameter  Description
  1  $dir       Folder to start the search with
  2  $filter    Optional regular expression to filter files

=head3 fileList($)

Files that match a given search pattern.

     Parameter  Description
  1  $pattern   Search pattern

=head3 searchDirectoryTreesForMatchingFiles(@)

Search the specified directory trees for files that match the specified extensions - the argument list should include at least one folder and one extension to be useful.

     Parameter              Description
  1  @foldersandExtensions  Mixture of folder names and extensions

=head3 matchPath($)

Given an absolute path find out how much of the path actually exists.

     Parameter  Description
  1  $file      File name

=head3 findFileWithExtension($@)

Find the first extension from the specified extensions that produces a file that exists when appended to the specified file

     Parameter  Description
  1  $file      File name minus extensions
  2  @ext       Possible extensions

=head3 clearFolder($$)

Remove all the files and folders under and including the specified folder as long as the number of files to be removed is less than the specified limit.

     Parameter    Description
  1  $folder      Folder
  2  $limitCount  Maximum number of files to remove to limit damage

=head2 Read and write files

Read and write strings from and to files creating paths as needed

=head3 readFile($)

Read a file containing unicode.

     Parameter  Description
  1  $file      Name of unicode file to read

=head3 readUtf16File($)

Read a file containing unicode in utf-16 format

     Parameter  Description
  1  $file      Name of file to read

=head3 readBinaryFile($)

Read binary file - a file whose contents are not to be interpreted as unicode.

     Parameter  Description
  1  $file      File to read

=head3 removeBOM($)

Remove BOM from a string

     Parameter  Description
  1  $s         String

=head3 makePath($)

Make the path for the specified file name or folder.

     Parameter  Description
  1  $file      File

=head3 writeFile($$)

Write a unicode string to a file after creating a path to the file if necessary and return the name of the file on success else confess.

     Parameter  Description
  1  $file      File to write to or undef for a temporary file
  2  $string    Unicode string to write

=head3 writeFiles($$)

Write the values of a hash as a file identified by the key of the value

     Parameter  Description
  1  $hash      Hash of key value pairs representing files and data
  2  $folder    Optional folder to contain files else the current folder

=head3 appendFile($$)

Append a unicode string to a file after creating a path to the file if necessary and return the name of the file on success else confess.

     Parameter  Description
  1  $file      File to append to
  2  $string    Unicode string to append

=head3 writeBinaryFile($$)

Write a non unicode string to a file in after creating a path to the file if necessary and return the name of the file on success else confess.

     Parameter  Description
  1  $file      File to write to
  2  $string    Non unicode string to write

=head3 createEmptyFile($)

Create an empty file - L<writeFile|/writeFile> complains if no data is written to the file -  and return the name of the file on success else confess.

     Parameter  Description
  1  $file      File to create

=head3 binModeAllUtf8()

Set STDOUT and STDERR to accept utf8 without complaint


=head1 Images

Image operations

=head2 imageSize($)

Return (width, height) of an image obtained via imagemagick.

     Parameter  Description
  1  $image     File containing image

=head2 convertImageToJpx690($$$)

Convert an image to jpx format using versions of ImageMagick version 6.9.0 and above

     Parameter  Description
  1  $source    Source file
  2  $target    Target folder (as multiple files will be created)
  3  $Size      Optional size of each tile - defaults to 256

=head1 Encoding and Decoding

Encode and decode using Json and Mime

=head2 encodeJson($)

Encode Perl to Json.

     Parameter  Description
  1  $string    Data to encode

=head2 decodeJson($)

Decode Perl from Json.

     Parameter  Description
  1  $string    Data to decode

=head2 encodeBase64($)

Encode a string in base 64.

     Parameter  Description
  1  $string    String to encode

=head2 decodeBase64($)

Decode a string in base 64.

     Parameter  Description
  1  $string    String to decode

=head2 convertUnicodeToXml($)

Convert a string with unicode points that are not directly representable in ascii into string that replaces these points with their representation on Xml making the string usable in Xml documents

     Parameter  Description
  1  $s         String to convert

=head1 Numbers

Numeric operations

=head2 powerOfTwo($)

Test whether a number is a power of two, return the power if it is else B<undef>

     Parameter  Description
  1  $n         Number to check

Use B<powerOfTwoX> to execute L<powerOfTwo|/powerOfTwo> but B<die> 'powerOfTwo' instead of returning B<undef>

=head2 containingPowerOfTwo($)

Find log two of the lowest power of two greater than or equal to a number.

     Parameter  Description
  1  $n         Number to check

Use B<containingPowerOfTwoX> to execute L<containingPowerOfTwo|/containingPowerOfTwo> but B<die> 'containingPowerOfTwo' instead of returning B<undef>

=head1 Sets

Set operations

=head2 setIntersectionOfTwoArraysOfWords($$)

Intersection of two arrays of words

     Parameter  Description
  1  $a         Reference to first array of words
  2  $b         Reference to second array of words

=head2 setUnionOfTwoArraysOfWords($$)

Union of two arrays of words

     Parameter  Description
  1  $a         Reference to first array of words
  2  $b         Reference to second array of words

=head2 contains($@)

Returns the indices at which an item matches elements of the specified array. If the item is a regular expression then it is matched as one, else it is a number it is matched as a number, else as a string.

     Parameter  Description
  1  $item      Item
  2  @array     Array

=head1 Minima and Maxima

Find the smallest and largest elements of arrays

=head2 min(@)

Find the minimum number in a list.

     Parameter  Description
  1  @n         Numbers

=head2 max(@)

Find the maximum number in a list.

     Parameter  Description
  1  @n         Numbers

=head1 Format

Format data structures as tables

=head2 formatTableBasic($$)

Tabularize text

     Parameter   Description
  1  $data       Reference to an array of arrays of data to be formatted as a table
  2  $separator  Optional line separator to use instead of new line for each row.

=head1 Lines

Load data structures from lines

=head2 loadArrayFromLines($)

Load an array from lines of text in a string.

     Parameter  Description
  1  $string    The string of lines from which to create an array

=head2 loadHashFromLines($)

Load a hash: first word of each line is the key and the rest is the value.

     Parameter  Description
  1  $string    The string of lines from which to create a hash

=head2 loadArrayArrayFromLines($)

Load an array of arrays from lines of text: each line is an array of words.

     Parameter  Description
  1  $string    The string of lines from which to create an array of arrays

=head2 loadHashArrayFromLines($)

Load a hash of arrays from lines of text: the first word of each line is the key, the remaining words are the array contents.

     Parameter  Description
  1  $string    The string of lines from which to create a hash of arrays

=head2 checkKeys($$)

Check the keys in a hash.

     Parameter   Description
  1  $test       The hash to test
  2  $permitted  The permitted keys and their meanings

=head1 LVALUE methods

Replace $a->{value} = $b with $a->value = $b which reduces the amount of typing required, is easier to read and provides a hard check that {value} is spelled correctly.

=head2 genLValueScalarMethods(@)

Generate LVALUE scalar methods in the current package, A method whose value has not yet been set will return a new scalar with value undef. Suffixing B<X> to the scalar name will confess if a value has not been set.

     Parameter  Description
  1  @names     List of method names

Example:

   $a->value = 1;

=head2 genLValueScalarMethodsWithDefaultValues(@)

Generate LVALUE scalar methods with default values in the current package. A reference to a method whose value has not yet been set will return a scalar whose value is the name of the method.

     Parameter  Description
  1  @names     List of method names

Example:

   $a->value == qq(value);

=head2 genLValueArrayMethods(@)

Generate LVALUE array methods in the current package. A reference to a method that has no yet been set will return a reference to an empty array.

     Parameter  Description
  1  @names     List of method names

Example:

   $a->value->[1] = 2;

=head2 genLValueHashMethods(@)

Generate LVALUE hash methods in the current package. A reference to a method that has no yet been set will return a reference to an empty hash.

     Parameter  Description
  1  @names     Method names

Example:

   $a->value->{a} = 'b';

=head2 assertRef(@)

Confirm that the specified references are to the package into which this routine has been exported.

     Parameter  Description
  1  @refs      References

=head2 ˢ(&)

Immediately executed inline sub to allow a code block before if.

     Parameter  Description
  1  $sub       Sub as {} without the word "sub"

Example:


  ok ˢ{1};


=head1 Strings

Actions on strings

=head2 indentString($$)

Indent lines contained in a string or formatted table by the specified string.

     Parameter  Description
  1  $string    The string of lines to indent
  2  $indent    The indenting string

=head2 isBlank($)

Test whether a string is blank.

     Parameter  Description
  1  $string    String

=head2 trim($)

Trim off white space from from front and end of string.

     Parameter  Description
  1  $string    String

=head2 pad($$)

Pad a string with blanks to a multiple of a specified length.

     Parameter  Description
  1  $string    String
  2  $length    Tab width

=head2 nws($)

Normalize white space in a string to make comparisons easier. Leading and trailing white space is removed; blocks of white space in the interior are reduced to a singe space.  In effect: this puts everything on one long line with never more than a space at a time.

     Parameter  Description
  1  $string    String to normalize

=head2 javaPackage($)

Extract the package name from a java string or file.

     Parameter  Description
  1  $java      Java file if it exists else the string of java

=head2 javaPackageAsFileName($)

Extract the package name from a java string or file and convert it to a file name.

     Parameter  Description
  1  $java      Java file if it exists else the string of java

=head2 perlPackage($)

Extract the package name from a perl string or file.

     Parameter  Description
  1  $perl      Perl file if it exists else the string of perl

=head2 printQw(@)

Print an array of words in qw() format

     Parameter  Description
  1  @words     Array of words

=head1 Cloud Cover

Useful for operating across the cloud

=head2 saveCodeToS3($$$$)

Save source code files

     Parameter       Description
  1  $saveCodeEvery  Save every seconds
  2  $zipFileName    Zip file name
  3  $bucket         Bucket/key
  4  $S3Parms        Additional S3 parameters like profile or region as a string

=head2 saveSourceToS3($$)

Save source code

     Parameter               Description
  1  $aws                    Aws target file and keywords
  2  $saveIntervalInSeconds  Save internal

=head2 addCertificate($)

Add a certificate to the current ssh session.

     Parameter  Description
  1  $file      File containing certificate

=head2 hostName()

The name of the host we are running on


=head2 userId()

The userid we are currently running under


=head2 wwwEncode($)

Replace spaces in a string with %20

     Parameter  Description
  1  $string    String

=head1 Documentation

Extract, format and update documentation for a perl module

=head2 htmlToc($@)

Generate a table of contents for some html

     Parameter  Description
  1  $replace   Substring within the html to be replaced with the toc
  2  $html      String of html

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


     Parameter    Description
  1  $perlModule  Optional file name with caller's file being the default


=head1 Private Methods

=head2 denormalizeFolderName($)

Remove any trailing folder separator from a folder name component.

     Parameter  Description
  1  $name      Name

=head2 renormalizeFolderName($)

Normalize a folder name component by adding a trailing separator.

     Parameter  Description
  1  $name      Name

=head2 extractTest($)

Extract a line of a test.

     Parameter  Description
  1  $string    String containing test line


=head1 Index


1 L<addCertificate|/addCertificate>

2 L<appendFile|/appendFile>

3 L<assertRef|/assertRef>

4 L<binModeAllUtf8|/binModeAllUtf8>

5 L<call|/call>

6 L<checkFile|/checkFile>

7 L<checkFilePath|/checkFilePath>

8 L<checkFilePathDir|/checkFilePathDir>

9 L<checkFilePathExt|/checkFilePathExt>

10 L<checkKeys|/checkKeys>

11 L<clearFolder|/clearFolder>

12 L<containingPowerOfTwo|/containingPowerOfTwo>

13 L<containingPowerOfTwoX|/containingPowerOfTwo>

14 L<contains|/contains>

15 L<convertImageToJpx690|/convertImageToJpx690>

16 L<convertUnicodeToXml|/convertUnicodeToXml>

17 L<createEmptyFile|/createEmptyFile>

18 L<currentDirectory|/currentDirectory>

19 L<currentDirectoryAbove|/currentDirectoryAbove>

20 L<dateStamp|/dateStamp>

21 L<dateTimeStamp|/dateTimeStamp>

22 L<decodeBase64|/decodeBase64>

23 L<decodeJson|/decodeJson>

24 L<denormalizeFolderName|/denormalizeFolderName>

25 L<encodeBase64|/encodeBase64>

26 L<encodeJson|/encodeJson>

27 L<extractTest|/extractTest>

28 L<fe|/fe>

29 L<fileList|/fileList>

30 L<fileModTime|/fileModTime>

31 L<fileOutOfDate|/fileOutOfDate>

32 L<filePath|/filePath>

33 L<filePathDir|/filePathDir>

34 L<filePathExt|/filePathExt>

35 L<fileSize|/fileSize>

36 L<findDirs|/findDirs>

37 L<findFiles|/findFiles>

38 L<findFileWithExtension|/findFileWithExtension>

39 L<firstFileThatExists|/firstFileThatExists>

40 L<fn|/fn>

41 L<fne|/fne>

42 L<formatTableBasic|/formatTableBasic>

43 L<fp|/fp>

44 L<fpn|/fpn>

45 L<genLValueArrayMethods|/genLValueArrayMethods>

46 L<genLValueHashMethods|/genLValueHashMethods>

47 L<genLValueScalarMethods|/genLValueScalarMethods>

48 L<genLValueScalarMethodsWithDefaultValues|/genLValueScalarMethodsWithDefaultValues>

49 L<hostName|/hostName>

50 L<htmlToc|/htmlToc>

51 L<imageSize|/imageSize>

52 L<indentString|/indentString>

53 L<isBlank|/isBlank>

54 L<javaPackage|/javaPackage>

55 L<javaPackageAsFileName|/javaPackageAsFileName>

56 L<loadArrayArrayFromLines|/loadArrayArrayFromLines>

57 L<loadArrayFromLines|/loadArrayFromLines>

58 L<loadHashArrayFromLines|/loadHashArrayFromLines>

59 L<loadHashFromLines|/loadHashFromLines>

60 L<makePath|/makePath>

61 L<matchPath|/matchPath>

62 L<max|/max>

63 L<microSecondsSinceEpoch|/microSecondsSinceEpoch>

64 L<min|/min>

65 L<nws|/nws>

66 L<pad|/pad>

67 L<parseCommandLineArguments|/parseCommandLineArguments>

68 L<parseFileName|/parseFileName>

69 L<perlPackage|/perlPackage>

70 L<powerOfTwo|/powerOfTwo>

71 L<powerOfTwoX|/powerOfTwo>

72 L<printQw|/printQw>

73 L<quoteFile|/quoteFile>

74 L<readBinaryFile|/readBinaryFile>

75 L<readFile|/readFile>

76 L<readUtf16File|/readUtf16File>

77 L<removeBOM|/removeBOM>

78 L<removeFilePrefix|/removeFilePrefix>

79 L<renormalizeFolderName|/renormalizeFolderName>

80 L<saveCodeToS3|/saveCodeToS3>

81 L<saveSourceToS3|/saveSourceToS3>

82 L<searchDirectoryTreesForMatchingFiles|/searchDirectoryTreesForMatchingFiles>

83 L<setIntersectionOfTwoArraysOfWords|/setIntersectionOfTwoArraysOfWords>

84 L<setUnionOfTwoArraysOfWords|/setUnionOfTwoArraysOfWords>

85 L<temporaryDirectory|/temporaryDirectory>

86 L<temporaryFile|/temporaryFile>

87 L<temporaryFolder|/temporaryFolder>

88 L<timeStamp|/timeStamp>

89 L<titleToUniqueFileName|/titleToUniqueFileName>

90 L<trackFiles|/trackFiles>

91 L<trim|/trim>

92 L<updateDocumentation|/updateDocumentation>

93 L<userId|/userId>

94 L<versionCode|/versionCode>

95 L<versionCodeDashed|/versionCodeDashed>

96 L<writeBinaryFile|/writeBinaryFile>

97 L<writeFile|/writeFile>

98 L<writeFiles|/writeFiles>

99 L<wwwEncode|/wwwEncode>

100 L<xxx|/xxx>

101 L<yyy|/yyy>

102 L<zzz|/zzz>

103 L<ˢ|/ˢ>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Data::Table::Text

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2018 Philip R Brenan.

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
#Test::More->builder->output("/dev/null");
use Test::More tests => 267;
my $windows = $^O =~ m(MSWin32)is;
my $mac     = $^O =~ m(darwin)is;

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

if (1)                                                                          # File paths
 {my $h =
   {"aaa/1.txt"=>"1111",
    "aaa/2.txt"=>"2222",
   };
  writeFiles($h);
  for(sort keys %$h)
   {ok -e $_;
    ok readFile($_) eq $h->{$_};
    unlink $_;
    ok !-e $_;
   }
  rmdir "aaa";
  ok !-d "aaa";
 }

if (1)                                                                          # Parse file names
 {is_deeply [parseFileName "/home/phil/test.data"], ["/home/phil/", "test", "data"];
  is_deeply [parseFileName "/home/phil/test"],      ["/home/phil/", "test"];
  is_deeply [parseFileName "phil/test.data"],       ["phil/",       "test", "data"];
  is_deeply [parseFileName "phil/test"],            ["phil/",       "test"];
  is_deeply [parseFileName "test.data"],            [undef,         "test", "data"];
  is_deeply [parseFileName "phil/"],                [qw(phil/)];
  is_deeply [parseFileName "/var/www/html/translations/"], [qw(/var/www/html/translations/)];
  is_deeply [parseFileName "a.b/c.d.e"],            [qw(a.b/ c.d e)];
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

  if ($windows or $mac) {ok 1}
  else
   {my @f = findFiles($T);
    ok $f[0] eq $f, "Find unicode file name";
   }

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
  if ($windows) {ok 1 for 1..3}
  else
   {ok findFiles($d) == 4;
    eval {clearFolder($d, 3)};
    ok $@ =~ m(\ALimit is 3, but 4 files under folder:)s;
    clearFolder($d, 4);
    ok !-e $d;
   }
 }

if (1)                                                                          # Format table and AA
 {my $t = [qw(aa bb cc)];
  my $d = [[qw(A   B   C)],
           [qw(AA  BB  CC)],
           [qw(AAA BBB CCC)],
           [qw(1   22  333)]];

  ok formatTableBasic($d,     '|') eq "A    B    C    |AA   BB   CC   |AAA  BBB  CCC  |  1   22  333  |";
  ok formatTable     ($d, $t, '|') eq "   aa   bb   cc   |1  A    B    C    |2  AA   BB   CC   |3  AAA  BBB  CCC  |4    1   22  333  |";
 }

if (1)                                                                          # Format table and AA
 {my $t = [qw(aa bb cc)];
  my $d = [[qw(1     B   C)],
           [qw(22    BB  CC)],
           [qw(333   BBB CCC)],
           [qw(4444  22  333)]];

  ok formatTableBasic($d,     '|') eq "   1  B    C    |  22  BB   CC   | 333  BBB  CCC  |4444   22  333  |";
  ok formatTable     ($d, $t, '|') eq "   aa    bb   cc   |1     1  B    C    |2    22  BB   CC   |3   333  BBB  CCC  |4  4444   22  333  |";
 }

if (1)                                                                          # AH
 {my $d = [{aa=>'A', bb=>'B', cc=>'C'},
           {aa=>'AA', bb=>'BB', cc=>'CC'},
           {aa=>'AAA', bb=>'BBB', cc=>'CCC'},
           {aa=>'1', bb=>'22', cc=>'333'}
          ];
  ok formatTable($d, undef, '|') eq "   aa   bb   cc   |1  A    B    C    |2  AA   BB   CC   |3  AAA  BBB  CCC  |4    1   22  333  |";
 }

if (1)                                                                          # HA
 {my $d = {''=>[qw(aa bb cc)], 1=>[qw(A B C)], 22=>[qw(AA BB CC)], 333=>[qw(AAA BBB CCC)],  4444=>[qw(1 22 333)]};
  ok formatTable($d, undef, '|') eq "      aa   bb   cc   |   1  A    B    C    |  22  AA   BB   CC   | 333  AAA  BBB  CCC  |4444    1   22  333  |";
 }

if (1)                                                                          # HH
 {my $d = {a=>{aa=>'A', bb=>'B', cc=>'C'}, aa=>{aa=>'AA', bb=>'BB', cc=>'CC'}, aaa=>{aa=>'AAA', bb=>'BBB', cc=>'CCC'}, aaaa=>{aa=>'1', bb=>'22', cc=>'333'}};
  ok formatTable($d, undef, '|') eq "      aa   bb   cc   |a     A    B    C    |aa    AA   BB   CC   |aaa   AAA  BBB  CCC  |aaaa    1   22  333  |";
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
is_deeply [qw(b)],   [&removeFilePrefix("a/", "a/b")];

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
   [qw( aaa bbb -c --dd --eee=EEEE -f=F), q(--gg=g g), q(--hh=h h)];
  is_deeply $r,
    [["aaa", "bbb"],
     {c=>undef, dd=>undef, eee=>"EEEE", f=>"F", gg=>"g g", hh=>"h h"},
    ], 'parse valid 1';
 }

if (1)
 {my $r = parseCommandLineArguments
   {ok 1, 'parse valid 2';
    $_[1]
   }
   [qw(--aAa=AAA --bbB=BBB)], [qw(aaa bbb ccc)];
  is_deeply $r, {aaa=>'AAA', bbb=>'BBB'}, 'parse valid 3';
 }

if (1)
 {eval
   {parseCommandLineArguments
     {$_[1]} [qw(aaa bbb ddd --aAa=AAA --dDd=DDD)], [qw(aaa bbb ccc)];
   };
  my $r = $@;
  ok $r =~ m(\AInvalid parameter: --dDd=DDD), "parse invalid 2";
 }

is_deeply [qw(a b c)],
  [setIntersectionOfTwoArraysOfWords([qw(e f g a b c )], [qw(a A b B c C)])];

is_deeply [qw(a b c)],
  [setUnionOfTwoArraysOfWords([qw(a b c )], [qw(a b)])];

ok printQw(qw(a  b  c)) eq "qw(a b c)";

if (1)
 {my $f = createEmptyFile("zzz.data");
  ok -e $f;
  ok !fileSize($f);
  unlink $f;
  ok !-e $f;
 }

if (1)
 {my $d = temporaryFolder;
  my $f = createEmptyFile(fpe($d, qw(a jpg)));
  my $F = findFileWithExtension(fpf($d, q(a)), qw(txt data jpg));
  ok -e $f, "jpg file exists";
  ok $F eq "jpg", "jpg extension";
  unlink $f;
  ok !-e $f;
  rmdir $d;
  ok !-d $d;
 }

if (1)
 {my $d = temporaryFolder;
  ok $d eq firstFileThatExists($d);
  ok $d eq firstFileThatExists("$d/$d", $d);
 }

if (1)
 {my $r = bless {};
  ok assertRef($r);
          bless $r, "aaa";
  eval {assertRef($r)};
  ok $@ =~ m(\AWanted reference to Data::Table::Text, but got aaa);
 }

# Relative and absolute files
ok "../../../"              eq relFromAbsAgainstAbs("/",                    "/home/la/perl/bbb.pl");
ok "../../../home"          eq relFromAbsAgainstAbs("/home",                "/home/la/perl/bbb.pl");
ok "../../"                 eq relFromAbsAgainstAbs("/home/",               "/home/la/perl/bbb.pl");
ok "aaa.pl"                 eq relFromAbsAgainstAbs("/home/la/perl/aaa.pl", "/home/la/perl/bbb.pl");
ok "aaa"                    eq relFromAbsAgainstAbs("/home/la/perl/aaa",    "/home/la/perl/bbb.pl");
ok "./"                     eq relFromAbsAgainstAbs("/home/la/perl/",       "/home/la/perl/bbb.pl");
ok "aaa.pl"                 eq relFromAbsAgainstAbs("/home/la/perl/aaa.pl", "/home/la/perl/bbb");
ok "aaa"                    eq relFromAbsAgainstAbs("/home/la/perl/aaa",    "/home/la/perl/bbb");
ok "./"                     eq relFromAbsAgainstAbs("/home/la/perl/",       "/home/la/perl/bbb");
ok "../java/aaa.jv"         eq relFromAbsAgainstAbs("/home/la/java/aaa.jv", "/home/la/perl/bbb.pl");
ok "../java/aaa"            eq relFromAbsAgainstAbs("/home/la/java/aaa",    "/home/la/perl/bbb.pl");
ok "../java/"               eq relFromAbsAgainstAbs("/home/la/java/",       "/home/la/perl/bbb.pl");
ok "../../la/perl/aaa.pl"   eq relFromAbsAgainstAbs("/home/la/perl/aaa.pl", "/home/il/perl/bbb.pl");
ok "../../la/perl/aaa"      eq relFromAbsAgainstAbs("/home/la/perl/aaa",    "/home/il/perl/bbb.pl");
ok "../../la/perl/"         eq relFromAbsAgainstAbs("/home/la/perl/",       "/home/il/perl/bbb.pl");
ok "../../la/perl/aaa.pl"   eq relFromAbsAgainstAbs("/home/la/perl/aaa.pl", "/home/il/perl/bbb");
ok "../../la/perl/aaa"      eq relFromAbsAgainstAbs("/home/la/perl/aaa",    "/home/il/perl/bbb");
ok "../../la/perl/"         eq relFromAbsAgainstAbs("/home/la/perl/",       "/home/il/perl/bbb");
ok "../../la/perl/"         eq relFromAbsAgainstAbs("/home/la/perl/",       "/home/il/perl/bbb");
ok "../../la/perl/aaa"      eq relFromAbsAgainstAbs("/home/la/perl/aaa",    "/home/il/perl/");
ok "../../la/perl/"         eq relFromAbsAgainstAbs("/home/la/perl/",       "/home/il/perl/");
ok "../../la/perl/"         eq relFromAbsAgainstAbs("/home/la/perl/",       "/home/il/perl/");
ok "home/la/perl/bbb.pl"    eq relFromAbsAgainstAbs("/home/la/perl/bbb.pl", "/");
ok "../home/la/perl/bbb.pl" eq relFromAbsAgainstAbs("/home/la/perl/bbb.pl", "/home");
ok "la/perl/bbb.pl"         eq relFromAbsAgainstAbs("/home/la/perl/bbb.pl", "/home/");
ok "bbb.pl"                 eq relFromAbsAgainstAbs("/home/la/perl/bbb.pl", "/home/la/perl/aaa.pl");
ok "bbb.pl"                 eq relFromAbsAgainstAbs("/home/la/perl/bbb.pl", "/home/la/perl/aaa");
ok "bbb.pl"                 eq relFromAbsAgainstAbs("/home/la/perl/bbb.pl", "/home/la/perl/");
ok "bbb"                    eq relFromAbsAgainstAbs("/home/la/perl/bbb",    "/home/la/perl/aaa.pl");
ok "bbb"                    eq relFromAbsAgainstAbs("/home/la/perl/bbb",    "/home/la/perl/aaa");
ok "bbb"                    eq relFromAbsAgainstAbs("/home/la/perl/bbb",    "/home/la/perl/");
ok "../perl/bbb.pl"         eq relFromAbsAgainstAbs("/home/la/perl/bbb.pl", "/home/la/java/aaa.jv");
ok "../perl/bbb.pl"         eq relFromAbsAgainstAbs("/home/la/perl/bbb.pl", "/home/la/java/aaa");
ok "../perl/bbb.pl"         eq relFromAbsAgainstAbs("/home/la/perl/bbb.pl", "/home/la/java/");
ok "../../il/perl/bbb.pl"   eq relFromAbsAgainstAbs("/home/il/perl/bbb.pl", "/home/la/perl/aaa.pl");
ok "../../il/perl/bbb.pl"   eq relFromAbsAgainstAbs("/home/il/perl/bbb.pl", "/home/la/perl/aaa");
ok "../../il/perl/bbb.pl"   eq relFromAbsAgainstAbs("/home/il/perl/bbb.pl", "/home/la/perl/");
ok "../../il/perl/bbb"      eq relFromAbsAgainstAbs("/home/il/perl/bbb",    "/home/la/perl/aaa.pl");
ok "../../il/perl/bbb"      eq relFromAbsAgainstAbs("/home/il/perl/bbb",    "/home/la/perl/aaa");
ok "../../il/perl/bbb"      eq relFromAbsAgainstAbs("/home/il/perl/bbb",    "/home/la/perl/");
ok "../../il/perl/bbb"      eq relFromAbsAgainstAbs("/home/il/perl/bbb",    "/home/la/perl/");
ok "../../il/perl/"         eq relFromAbsAgainstAbs("/home/il/perl/",       "/home/la/perl/aaa");
ok "../../il/perl/"         eq relFromAbsAgainstAbs("/home/il/perl/",       "/home/la/perl/");
ok "../../il/perl/"         eq relFromAbsAgainstAbs("/home/il/perl/",       "/home/la/perl/");

ok "/"                      eq absFromAbsPlusRel("/home/la/perl/bbb.pl",   "../../..");
ok "/home"                  eq absFromAbsPlusRel("/home/la/perl/bbb.pl",   "../../../home");
ok "/home/"                 eq absFromAbsPlusRel("/home/la/perl/bbb.pl",   "../..");
ok "/home/la/perl/aaa.pl"   eq absFromAbsPlusRel("/home/la/perl/bbb.pl",   "aaa.pl");
ok "/home/la/perl/aaa"      eq absFromAbsPlusRel("/home/la/perl/bbb.pl",   "aaa");
ok "/home/la/perl/"         eq absFromAbsPlusRel("/home/la/perl/bbb.pl",   "");
ok "/home/la/perl/aaa.pl"   eq absFromAbsPlusRel("/home/la/perl/bbb",      "aaa.pl");
ok "/home/la/perl/aaa"      eq absFromAbsPlusRel("/home/la/perl/bbb",      "aaa");
ok "/home/la/perl/"         eq absFromAbsPlusRel("/home/la/perl/bbb",      "");
ok "/home/la/java/aaa.jv"   eq absFromAbsPlusRel("/home/la/perl/bbb.pl",   "../java/aaa.jv");
ok "/home/la/java/aaa"      eq absFromAbsPlusRel("/home/la/perl/bbb.pl",   "../java/aaa");
ok "/home/la/java"          eq absFromAbsPlusRel("/home/la/perl/bbb.pl",   "../java");
ok "/home/la/java/"         eq absFromAbsPlusRel("/home/la/perl/bbb.pl",   "../java/");
ok "/home/la/perl/aaa.pl"   eq absFromAbsPlusRel("/home/il/perl/bbb.pl",   "../../la/perl/aaa.pl");
ok "/home/la/perl/aaa"      eq absFromAbsPlusRel("/home/il/perl/bbb.pl",   "../../la/perl/aaa");
ok "/home/la/perl"          eq absFromAbsPlusRel("/home/il/perl/bbb.pl",   "../../la/perl");
ok "/home/la/perl/"         eq absFromAbsPlusRel("/home/il/perl/bbb.pl",   "../../la/perl/");
ok "/home/la/perl/aaa.pl"   eq absFromAbsPlusRel("/home/il/perl/bbb",      "../../la/perl/aaa.pl");
ok "/home/la/perl/aaa"      eq absFromAbsPlusRel("/home/il/perl/bbb",      "../../la/perl/aaa");
ok "/home/la/perl"          eq absFromAbsPlusRel("/home/il/perl/bbb",      "../../la/perl");
ok "/home/la/perl/"         eq absFromAbsPlusRel("/home/il/perl/bbb",      "../../la/perl/");
ok "/home/la/perl/aaa"      eq absFromAbsPlusRel("/home/il/perl/",         "../../la/perl/aaa");
ok "/home/la/perl"          eq absFromAbsPlusRel("/home/il/perl/",         "../../la/perl");
ok "/home/la/perl/"         eq absFromAbsPlusRel("/home/il/perl/",         "../../la/perl/");
ok "/home/la/perl/bbb.pl"   eq absFromAbsPlusRel("/",                      "home/la/perl/bbb.pl");
#ok "/home/la/perl/bbb.pl"   eq absFromAbsPlusRel("/home",                  "../home/la/perl/bbb.pl");
ok "/home/la/perl/bbb.pl"   eq absFromAbsPlusRel("/home/",                 "la/perl/bbb.pl");
ok "/home/la/perl/bbb.pl"   eq absFromAbsPlusRel("/home/la/perl/aaa.pl",   "bbb.pl");
ok "/home/la/perl/bbb.pl"   eq absFromAbsPlusRel("/home/la/perl/aaa",      "bbb.pl");
ok "/home/la/perl/bbb.pl"   eq absFromAbsPlusRel("/home/la/perl/",         "bbb.pl");
ok "/home/la/perl/bbb"      eq absFromAbsPlusRel("/home/la/perl/aaa.pl",   "bbb");
ok "/home/la/perl/bbb"      eq absFromAbsPlusRel("/home/la/perl/aaa",      "bbb");
ok "/home/la/perl/bbb"      eq absFromAbsPlusRel("/home/la/perl/",         "bbb");
ok "/home/la/perl/bbb.pl"   eq absFromAbsPlusRel("/home/la/java/aaa.jv",   "../perl/bbb.pl");
ok "/home/la/perl/bbb.pl"   eq absFromAbsPlusRel("/home/la/java/aaa",      "../perl/bbb.pl");
ok "/home/la/perl/bbb.pl"   eq absFromAbsPlusRel("/home/la/java/",         "../perl/bbb.pl");
ok "/home/il/perl/bbb.pl"   eq absFromAbsPlusRel("/home/la/perl/aaa.pl",   "../../il/perl/bbb.pl");
ok "/home/il/perl/bbb.pl"   eq absFromAbsPlusRel("/home/la/perl/aaa",      "../../il/perl/bbb.pl");
ok "/home/il/perl/bbb.pl"   eq absFromAbsPlusRel("/home/la/perl/",         "../../il/perl/bbb.pl");
ok "/home/il/perl/bbb"      eq absFromAbsPlusRel("/home/la/perl/aaa.pl",   "../../il/perl/bbb");
ok "/home/il/perl/bbb"      eq absFromAbsPlusRel("/home/la/perl/aaa",      "../../il/perl/bbb");
ok "/home/il/perl/bbb"      eq absFromAbsPlusRel("/home/la/perl/",         "../../il/perl/bbb");
ok "/home/il/perl/bbb"      eq absFromAbsPlusRel("/home/la/perl/",         "../../il/perl/bbb");
ok "/home/il/perl"          eq absFromAbsPlusRel("/home/la/perl/aaa",      "../../il/perl");
ok "/home/il/perl/"         eq absFromAbsPlusRel("/home/la/perl/",         "../../il/perl/");

ok ˢ{1};                                                                        #Tˢ

ˢ{my $f = {};
  ok q(a_p.txt)   eq &titleToUniqueFileName($f, qw(a p txt));
  ok q(a_p_2.txt) eq &titleToUniqueFileName($f, qw(a p txt));
  ok q(a_p_3.txt) eq &titleToUniqueFileName($f, qw(a p txt));
  ok q(a_q.txt)   eq &titleToUniqueFileName($f, qw(a q txt));
  ok q(a_q_5.txt) eq &titleToUniqueFileName($f, qw(a q txt));
  ok q(a_q_6.txt) eq &titleToUniqueFileName($f, qw(a q txt));
 };

  ok fp (q(a/b/c.d.e))  eq q(a/b/),    q(f1);
  ok fpn(q(a/b/c.d.e))  eq q(a/b/c.d), q(f2);
  ok fn (q(a/b/c.d.e))  eq q(c.d),     q(f3);
  ok fne(q(a/b/c.d.e))  eq q(c.d.e),   q(f4);
  ok fe (q(a/b/c.d.e))  eq q(e),       q(f5);
  ok fp (q(/a/b/c.d.e)) eq q(/a/b/),    q(f1);
  ok fpn(q(/a/b/c.d.e)) eq q(/a/b/c.d), q(f2);
  ok fn (q(/a/b/c.d.e)) eq q(c.d),     q(f3);
  ok fne(q(/a/b/c.d.e)) eq q(c.d.e),   q(f4);
  ok fe (q(/a/b/c.d.e)) eq q(e),       q(f5);

ˢ{our $a = q(1);                                                                #Tcall
  our @a = qw(1);
  our %a = (a=>1);
  our $b = q(1);
  for(2..4)
   {call {$a = $_  x 1000; $a[0] = $_; $a{a} = $_; $b = 2;} qw($a @a %a);
    ok $a    == $_ x 1000;
    ok $a[0] == $_;
    ok $a{a} == $_;
    ok $b    == 1;
   }
 };

 ok wwwEncode(q(a  b c)) eq q(a%20%20b%20c);

1
