# Description

Write data in tabular text format.

Version 20230616.

The following sections describe the methods in each functional area of this [module](https://en.wikipedia.org/wiki/Modular_programming).  For an alphabetic listing of all methods by name see [Index](#index).

# Immediately useful methods

These methods are the ones most likely to be of immediate use to anyone using
this [module](https://en.wikipedia.org/wiki/Modular_programming) for the first time:

[absFromAbsPlusRel($a, $r)](#absfromabsplusrel-a-r)

Absolute [file](https://en.wikipedia.org/wiki/Computer_file) from an absolute [file](https://en.wikipedia.org/wiki/Computer_file) **$a** plus a relative [file](https://en.wikipedia.org/wiki/Computer_file) **$r**. In the event that the relative [file](https://en.wikipedia.org/wiki/Computer_file) $r is, in fact, an absolute [file](https://en.wikipedia.org/wiki/Computer_file) then it is returned as the result.

[awsParallelProcessFiles($userData, $parallel, $results, $files, %options)](#awsparallelprocessfiles-userdata-parallel-results-files-options)

Process files in parallel across multiple [Amazon Web Services](http://aws.amazon.com) instances if available or in series if not.  The data located by **$userData** is transferred from the primary instance, as determined by [awsParallelPrimaryInstanceId](https://metacpan.org/pod/awsParallelPrimaryInstanceId), to all the secondary instances. **$parallel** contains a reference to a [sub](https://perldoc.perl.org/perlsub.html), parameterized by [array](https://en.wikipedia.org/wiki/Dynamic_array) @\_ = (a copy of the [user](https://en.wikipedia.org/wiki/User_(computing)) data, the name of the [file](https://en.wikipedia.org/wiki/Computer_file) to process), which will be executed upon each session instance including the primary instance to update $userData. **$results** contains a reference to a [sub](https://perldoc.perl.org/perlsub.html), parameterized by [array](https://en.wikipedia.org/wiki/Dynamic_array) @\_ = (the [user](https://en.wikipedia.org/wiki/User_(computing)) data, an [array](https://en.wikipedia.org/wiki/Dynamic_array) of results returned by each execution of $parallel), that will be called on the primary instance to [process](https://en.wikipedia.org/wiki/Process_management_(computing)) the results folders from each instance once their results folders have been copied back and merged into the results [folder](https://en.wikipedia.org/wiki/File_folder) of the primary instance. $results should update its copy of $userData with the information received from each instance. **$files** is a reference to an [array](https://en.wikipedia.org/wiki/Dynamic_array) of the files to be processed: each [file](https://en.wikipedia.org/wiki/Computer_file) will be copied from the primary instance to each of the secondary instances before parallel processing starts. **%options** contains any parameters needed to interact with [EC2](https://aws.amazon.com/ec2/)  via the [Amazon Web Services Command Line Interface](https://aws.amazon.com/cli/).  The returned result is that returned by [sub](https://perldoc.perl.org/perlsub.html) $results.

[clearFolder($folder, $limitCount, $noMsg)](#clearfolder-folder-limitcount-nomsg)

Remove all the files and folders under and including the specified **$folder** as long as the number of files to be removed is less than the specified **$limitCount**. Sometimes the [folder](https://en.wikipedia.org/wiki/File_folder) can be emptied but not removed - perhaps because it a link, in this case a message is produced unless suppressed by the optional **$nomsg** parameter.

[dateTimeStamp](#datetimestamp)

Year-monthNumber-day at hours:minute:seconds.

[execPerlOnRemote($code, $ip)](#execperlonremote-code-ip)

Execute some Perl **$code** on the [server](https://en.wikipedia.org/wiki/Server_(computing)) whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp).

[filePathExt(@File)](#filepathext-file)

Create a [file](https://en.wikipedia.org/wiki/Computer_file) name from a [list](https://en.wikipedia.org/wiki/Linked_list) of  names the last of which is assumed to be the extension of the [file](https://en.wikipedia.org/wiki/Computer_file) name. Identical to [fpe](#fpe).

[fn($file)](#fn-file)

Remove the path and extension from a [file](https://en.wikipedia.org/wiki/Computer_file) name.

[formatTable($data, $columnTitles, @options)](#formattable-data-columntitles-options)

Format various **$data** structures as a [table](https://en.wikipedia.org/wiki/Table_(information)) with titles as specified by **$columnTitles**: either a reference to an [array](https://en.wikipedia.org/wiki/Dynamic_array) of column titles or a [string](https://en.wikipedia.org/wiki/String_(computer_science)) each line of which contains the column title as the first [word](https://en.wikipedia.org/wiki/Doc_(computing)) with the rest of the line describing that column.

Optionally create a report from the [table](https://en.wikipedia.org/wiki/Table_(information)) using the report **%options** described in [formatTableCheckKeys](https://metacpan.org/pod/formatTableCheckKeys).

[genHash($bless, %attributes)](#genhash-bless-attributes)

Return a **$bless**ed [hash](https://en.wikipedia.org/wiki/Hash_table) with the specified **$attributes** accessible via [lvalue method](http://perldoc.perl.org/perlsub.html#Lvalue-subroutines) method calls. [updateDocumentation](#updatedocumentation) will generate [documentation](https://en.wikipedia.org/wiki/Software_documentation) at ["Hash Definitions"](#hash-definitions) for the [hash](https://en.wikipedia.org/wiki/Hash_table) defined by the call to [genHash](#genhash) if the call is laid out as in the example below.

[readFile($file)](#readfile-file)

Return the content of a [file](https://en.wikipedia.org/wiki/Computer_file) residing on the local machine interpreting the content of the [file](https://en.wikipedia.org/wiki/Computer_file) as [utf8](https://en.wikipedia.org/wiki/UTF-8).

[readFileFromRemote($file, $ip)](#readfilefromremote-file-ip)

Copy and read a **$file** from the remote machine whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp) and return the content of $file interpreted as [utf8](https://en.wikipedia.org/wiki/UTF-8) .

[relFromAbsAgainstAbs($a, $b)](#relfromabsagainstabs-a-b)

Relative [file](https://en.wikipedia.org/wiki/Computer_file) from one absolute [file](https://en.wikipedia.org/wiki/Computer_file) **$a** against another **$b**.

[runInParallel($maximumNumberOfProcesses, $parallel, $results, @array)](#runinparallel-maximumnumberofprocesses-parallel-results-array)

Process the elements of an [array](https://en.wikipedia.org/wiki/Dynamic_array) in parallel using a maximum of **$maximumNumberOfProcesses** [processes](https://en.wikipedia.org/wiki/Process_management_(computing)). [sub](https://perldoc.perl.org/perlsub.html) **&$parallel** is forked to [process](https://en.wikipedia.org/wiki/Process_management_(computing)) each [array](https://en.wikipedia.org/wiki/Dynamic_array) element in parallel. The results returned by the forked copies of &$parallel are presented as a single [array](https://en.wikipedia.org/wiki/Dynamic_array) to [sub](https://perldoc.perl.org/perlsub.html) **&$results** which is run in series. **@array** contains the elements to be processed. Returns the result returned by &$results.

[searchDirectoryTreeForSubFolders($folder)](#searchdirectorytreeforsubfolders-folder)

Search the specified directory under the specified [folder](https://en.wikipedia.org/wiki/File_folder) for [sub](https://perldoc.perl.org/perlsub.html) folders.

[searchDirectoryTreesForMatchingFiles(@FoldersandExtensions)](#searchdirectorytreesformatchingfiles-foldersandextensions)

Search the specified directory [trees](https://en.wikipedia.org/wiki/Tree_(data_structure)) for the files (not folders) that match the specified [file name extensions](https://en.wikipedia.org/wiki/List_of_filename_extensions). The argument [list](https://en.wikipedia.org/wiki/Linked_list) should include at least one path name to be useful. If no [file](https://en.wikipedia.org/wiki/Computer_file) [file name extensions](https://en.wikipedia.org/wiki/List_of_filename_extensions) are supplied then all the files below the specified paths are returned.  Arguments wrapped in \[\] will be unwrapped.

[writeFile($file, $string)](#writefile-file-string)

Write to a new **$file**, after creating a path to the $file with [makePath](https://metacpan.org/pod/makePath) if necessary, a **$string** of [Unicode](https://en.wikipedia.org/wiki/Unicode) content encoded as [utf8](https://en.wikipedia.org/wiki/UTF-8). Return the name of the $file written to on success else [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) if the [file](https://en.wikipedia.org/wiki/Computer_file) already exists or any other error occurs.

[writeFileToRemote($file, $string, $ip)](#writefiletoremote-file-string-ip)

Write to a new **$file**, after creating a path to the [file](https://en.wikipedia.org/wiki/Computer_file) with [makePath](https://metacpan.org/pod/makePath) if necessary, a **$string** of [Unicode](https://en.wikipedia.org/wiki/Unicode) content encoded as [utf8](https://en.wikipedia.org/wiki/UTF-8) then copy the $file to the remote [server](https://en.wikipedia.org/wiki/Server_(computing)) whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp). Return the name of the $file on success else [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) if the [file](https://en.wikipedia.org/wiki/Computer_file) already exists or any other error occurs.

[xxxr($cmd, $ip)](#xxxr-cmd-ip)

Execute a command **$cmd** via [Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) on the [server](https://en.wikipedia.org/wiki/Server_(computing)) whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp). The command will be run using the [userid](https://en.wikipedia.org/wiki/User_identifier) listed in `.ssh/config`.

# Time stamps

Date and timestamps as used in logs of long running commands.

## dateTimeStamp()

Year-monthNumber-day at hours:minute:seconds.

**Example:**

    ok dateTimeStamp     =~ m(\A\d{4}-\d\d-\d\d at \d\d:\d\d:\d\d\Z), q(dts);         # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## dateTimeStampName()

Date time stamp without white space.

**Example:**

    ok dateTimeStampName =~ m(\A_on_\d{4}_\d\d_\d\d_at_\d\d_\d\d_\d\d\Z);             # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## dateStamp()

Year-monthName-day.

**Example:**

    ok dateStamp         =~ m(\A\d{4}-\w{3}-\d\d\Z);                                  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## versionCode()

YYYYmmdd-HHMMSS.

**Example:**

    ok versionCode       =~ m(\A\d{8}-\d{6}\Z);                                       # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## versionCodeDashed()

YYYY-mm-dd-HH:MM:SS.

**Example:**

    ok versionCodeDashed =~ m(\A\d{4}-\d\d-\d\d-\d\d:\d\d:\d\d\Z);                    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## timeStamp()

Hours:minute:seconds.

**Example:**

    ok timeStamp         =~ m(\A\d\d:\d\d:\d\d\Z);                                    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## microSecondsSinceEpoch()

Micro seconds since [Unix](https://en.wikipedia.org/wiki/Unix) epoch.

**Example:**

    ok microSecondsSinceEpoch > 47*365*24*60*60*1e6;                                  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

# Command execution

Various ways of processing commands and writing results.

## ddd(@data)

Dump data.

       Parameter  Description
    1  @data      Messages

**Example:**

    ddd "Hello";                                                                      # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## fff($line, $file, @m)

Confess a message with a line position and a [file](https://en.wikipedia.org/wiki/Computer_file) that Geany will jump to if clicked on.

       Parameter  Description
    1  $line      Line
    2  $file      File
    3  @m         Messages

**Example:**

    fff __LINE__, __FILE__, "Hello world";                                            # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## lll(@messages)

Log messages with a time stamp and originating [file](https://en.wikipedia.org/wiki/Computer_file) and line number.

       Parameter  Description
    1  @messages  Messages

**Example:**

    lll "Hello world";                                                                # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## mmm(@messages)

Log messages with a differential time in milliseconds and originating [file](https://en.wikipedia.org/wiki/Computer_file) and line number.

       Parameter  Description
    1  @messages  Messages

**Example:**

    mmm "Hello world";                                                                # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## xxx(@cmd)

Execute a [shell](https://en.wikipedia.org/wiki/Shell_(computing)) command optionally checking its response. The command to execute is specified as one or more [strings](https://en.wikipedia.org/wiki/String_(computer_science)) which are joined together after removing any new lines. Optionally the last [string](https://en.wikipedia.org/wiki/String_(computer_science)) can be a regular expression that is used to [test](https://en.wikipedia.org/wiki/Software_testing) any non blank output generated by the execution of the command: if the regular expression fails the command and the command output are printed, else it is suppressed as being uninteresting. If such a regular expression is not supplied then the command and its non blank output lines are always printed.

       Parameter  Description
    1  @cmd       Command to execute followed by an optional regular expression to [test](https://en.wikipedia.org/wiki/Software_testing) the results

**Example:**

     {ok xxx("echo aaa")       =~ /aaa/;                                              # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## xxxr($cmd, $ip)

Execute a command **$cmd** via [Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) on the [server](https://en.wikipedia.org/wiki/Server_(computing)) whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp). The command will be run using the [userid](https://en.wikipedia.org/wiki/User_identifier) listed in `.ssh/config`.

       Parameter  Description
    1  $cmd       Command [string](https://en.wikipedia.org/wiki/String_(computer_science))     2  $ip        Optional [IP address](https://en.wikipedia.org/wiki/IP_address) address

**Example:**

    if (0)                                                                          
    
     {ok xxxr q(pwd);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## yyy($cmd)

Execute a block of [shell](https://en.wikipedia.org/wiki/Shell_(computing)) commands line by line after removing comments - stop if there is a non zero return [code](https://en.wikipedia.org/wiki/Computer_program) from any command.

       Parameter  Description
    1  $cmd       Commands to execute separated by new lines

**Example:**

      ok !yyy <<END;                                                                  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    echo aaa
    echo bbb
    END
    

## zzz($cmd, $success, $returnCode, $message)

Execute lines of commands after replacing new lines with && then check that the pipeline execution results in a return [code](https://en.wikipedia.org/wiki/Computer_program) of zero and that the execution results match the optional regular expression if one has been supplied; confess() to an error if either check fails. To execute remotely, add "ssh ... 'echo start" as the first line and "echo end'" as the last line with the commands to be executed on the lines in between.

       Parameter    Description
    1  $cmd         Commands to execute - one per line with no trailing &&
    2  $success     Optional regular expression to check for acceptable results
    3  $returnCode  Optional regular expression to check the acceptable return codes
    4  $message     Message of explanation if any of the checks [fail](https://1lib.eu/book/2468851/544b50) 
**Example:**

    ok zzz(<<END, qr(aaa\s*bbb)s);                                                    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    echo aaa
    echo bbb
    END
    

## execPerlOnRemote($code, $ip)

Execute some Perl **$code** on the [server](https://en.wikipedia.org/wiki/Server_(computing)) whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp).

       Parameter  Description
    1  $code      Code to execute
    2  $ip        Optional [IP address](https://en.wikipedia.org/wiki/IP_address) address

**Example:**

      ok execPerlOnRemote(<<'END') =~ m(Hello from: t2.micro)i;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    #!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
    use Data::Table::Text qw(:all);
    
    say STDERR "Hello from: ", awsCurrentInstanceType;
    END
    

## parseCommandLineArguments($sub, $args, $valid)

Call the specified **$sub** after classifying the specified [array](https://en.wikipedia.org/wiki/Dynamic_array) of \[arguments\] in **$args** into positional and keyword parameters. Keywords are always preceded by one or more **-** and separated from their values by **=**. $sub(\[$positional\], {keyword=>value}) will be called  with a reference to an [array](https://en.wikipedia.org/wiki/Dynamic_array) of positional parameters followed by a reference to a [hash](https://en.wikipedia.org/wiki/Hash_table) of keywords and their values. The value returned by $sub will be returned to the caller. The keywords names will be validated if **$valid** is either a reference to an [array](https://en.wikipedia.org/wiki/Dynamic_array) of valid keywords names or a [hash](https://en.wikipedia.org/wiki/Hash_table) of {valid keyword name => textual description}. Confess with a [table](https://en.wikipedia.org/wiki/Table_(information)) of valid keywords definitions if $valid is specified and an invalid keyword argument is presented.

       Parameter  Description
    1  $sub       Sub to call
    2  $args      List of arguments to [parse](https://en.wikipedia.org/wiki/Parsing)     3  $valid     Optional [list](https://en.wikipedia.org/wiki/Linked_list) of valid parameters else all parameters will be accepted

**Example:**

      my $r = parseCommandLineArguments {[@_]}  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       [qw( aaa bbb -c --dd --eee=EEEE -f=F), q(--gg=g g), q(--hh=h h)];
      is_deeply $r,
        [["aaa", "bbb"],
         {c=>undef, dd=>undef, eee=>"EEEE", f=>"F", gg=>"g g", hh=>"h h"},
        ];
    
    if (1)                                                                          
    
     {my $r = parseCommandLineArguments  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {ok 1;
        $_[1]
       }
       [qw(--aAa=AAA --bbB=BBB)], [qw(aaa bbb ccc)];
      is_deeply $r, {aaa=>'AAA', bbb=>'BBB'};
     }
    

## call($sub, @our)

Call the specified **$sub** in a separate child [process](https://en.wikipedia.org/wiki/Process_management_(computing)), wait for it to complete, then copy back the named **@our** variables from the child [process](https://en.wikipedia.org/wiki/Process_management_(computing)) to the calling parent [process](https://en.wikipedia.org/wiki/Process_management_(computing)) effectively freeing any [memory](https://en.wikipedia.org/wiki/Computer_memory) used during the call.

       Parameter  Description
    1  $sub       Sub to call
    2  @our       Names of our variable names with preceding sigils to copy back

**Example:**

      our $a = q(1);
      our @a = qw(1);
      our %a = (a=>1);
      our $b = q(1);
      for(2..4) {
    
        call {$a = $_  x 1e3; $a[0] = $_ x 1e2; $a{a} = $_ x 1e1; $b = 2;} qw($a @a %a);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        ok $a    == $_ x 1e3;
        ok $a[0] == $_ x 1e2;
        ok $a{a} == $_ x 1e1;
        ok $b    == 1;
       }
    

## evalOrConfess(@c)

Evaluate some [code](https://en.wikipedia.org/wiki/Computer_program) successfully or [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) as to why it failed to evaluate successfully.

       Parameter  Description
    1  @c         Code to evaluate

**Example:**

      ok evalOrConfess("1") == 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $r = [eval](http://perldoc.perl.org/functions/eval.html) {evalOrConfess "++ ++"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $@ =~ m(syntax error);
    

# Files and paths

Operations on files and paths.

## Statistics

Information about each [file](https://en.wikipedia.org/wiki/Computer_file). 
### fileSize($file)

Get the size of a **$file** in bytes.

       Parameter  Description
    1  $file      File name

**Example:**

      my $f = writeFile("zzz.data", "aaa");                                         
    
    
      ok fileSize($f) == 3;                                                           # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### fileLargestSize(@files)

Return the largest **$file**.

       Parameter  Description
    1  @files     File names

**Example:**

      my $d = temporaryFolder;
      my @f = map {owf(fpe($d, $_, q(txt)), 'X' x ($_ ** 2 % 11))} 1..9;
    
    
      my $f = fileLargestSize(@f);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok fn($f) eq '3', 'aaa';
    
    #  my $b = folderSize($d);                                                       # Needs du
    #  ok $b > 0, 'bbb';
    
      my $c = processFilesInParallel(
        [sub](https://perldoc.perl.org/perlsub.html)          {my ($file) = @_;
          [&fileSize($file), $file]
         },
        [sub](https://perldoc.perl.org/perlsub.html)          {scalar @_;
         }, (@f) x 12);
    
      ok 108 == $c, 'cc11';
    
      my $C = processSizesInParallel
        [sub](https://perldoc.perl.org/perlsub.html)          {my ($file) = @_;
          [&fileSize($file), $file]
         },
        [sub](https://perldoc.perl.org/perlsub.html)          {scalar @_;
         }, map {[fileSize($_), $_]} (@f) x 12;
    
      ok 108 == $C, 'cc2';
    
      my $J = processJavaFilesInParallel
        [sub](https://perldoc.perl.org/perlsub.html)          {my ($file) = @_;
          [&fileSize($file), $file]
         },
        [sub](https://perldoc.perl.org/perlsub.html)          {scalar @_;
         }, (@f) x 12;
    
      ok 108 == $J, 'cc3';
    
      clearFolder($d, 12);
    

### folderSize($folder)

Get the size of a **$folder** in bytes.

       Parameter  Description
    1  $folder    Folder name

**Example:**

      my $d = temporaryFolder;
      my @f = map {owf(fpe($d, $_, q(txt)), 'X' x ($_ ** 2 % 11))} 1..9;
    
      my $f = fileLargestSize(@f);
      ok fn($f) eq '3', 'aaa';
    
    
    #  my $b = folderSize($d);                                                       # Needs du  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    #  ok $b > 0, 'bbb';
    
      my $c = processFilesInParallel(
        [sub](https://perldoc.perl.org/perlsub.html)          {my ($file) = @_;
          [&fileSize($file), $file]
         },
        [sub](https://perldoc.perl.org/perlsub.html)          {scalar @_;
         }, (@f) x 12);
    
      ok 108 == $c, 'cc11';
    
      my $C = processSizesInParallel
        [sub](https://perldoc.perl.org/perlsub.html)          {my ($file) = @_;
          [&fileSize($file), $file]
         },
        [sub](https://perldoc.perl.org/perlsub.html)          {scalar @_;
         }, map {[fileSize($_), $_]} (@f) x 12;
    
      ok 108 == $C, 'cc2';
    
      my $J = processJavaFilesInParallel
        [sub](https://perldoc.perl.org/perlsub.html)          {my ($file) = @_;
          [&fileSize($file), $file]
         },
        [sub](https://perldoc.perl.org/perlsub.html)          {scalar @_;
         }, (@f) x 12;
    
      ok 108 == $J, 'cc3';
    
      clearFolder($d, 12);
    

### fileMd5Sum($file)

Get the Md5 sum of the content of a **$file**.

       Parameter  Description
    1  $file      File or [string](https://en.wikipedia.org/wiki/String_(computer_science)) 
**Example:**

      fileMd5Sum(q(/etc/hosts));                                                      # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $s = join '', 1..100;
      my $m = q(ef69caaaeea9c17120821a9eb6c7f1de);
    
      ok stringMd5Sum($s) eq $m;
    
      my $f = writeFile(undef, $s);
    
      ok fileMd5Sum($f) eq $m;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      unlink $f;
    
      ok guidFromString(join '', 1..100) eq
         q(GUID-ef69caaa-eea9-c171-2082-1a9eb6c7f1de);
    
      ok guidFromMd5(stringMd5Sum(join('', 1..100))) eq
         q(GUID-ef69caaa-eea9-c171-2082-1a9eb6c7f1de);
    
      ok md5FromGuid(q(GUID-ef69caaa-eea9-c171-2082-1a9eb6c7f1de)) eq
                          q(ef69caaaeea9c17120821a9eb6c7f1de);
    
      ok stringMd5Sum(q(𝝰 𝝱 𝝲)) eq q(3c2b7c31b1011998bd7e1f66fb7c024d);
    }
    
    if (1)
     {ok arraySum   (1..10) ==  55;                                                 
      ok arrayProduct(1..5) == 120;                                                 
      is_deeply[arrayTimes(2, 1..5)], [qw(2 4 6 8 10)];                             
    

### guidFromMd5($m)

Create a [guid](https://en.wikipedia.org/wiki/Universally_unique_identifier) from an [MD5](https://en.wikipedia.org/wiki/MD5) [hash](https://en.wikipedia.org/wiki/Hash_table). 
       Parameter  Description
    1  $m         Md5 [hash](https://en.wikipedia.org/wiki/Hash_table) 
**Example:**

      my $s = join '', 1..100;
      my $m = q(ef69caaaeea9c17120821a9eb6c7f1de);
    
      ok stringMd5Sum($s) eq $m;
    
      my $f = writeFile(undef, $s);
      ok fileMd5Sum($f) eq $m;
      unlink $f;
    
      ok guidFromString(join '', 1..100) eq
         q(GUID-ef69caaa-eea9-c171-2082-1a9eb6c7f1de);
    
    
      ok guidFromMd5(stringMd5Sum(join('', 1..100))) eq  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         q(GUID-ef69caaa-eea9-c171-2082-1a9eb6c7f1de);
    
      ok md5FromGuid(q(GUID-ef69caaa-eea9-c171-2082-1a9eb6c7f1de)) eq
                          q(ef69caaaeea9c17120821a9eb6c7f1de);
    
      ok stringMd5Sum(q(𝝰 𝝱 𝝲)) eq q(3c2b7c31b1011998bd7e1f66fb7c024d);
    }
    
    if (1)
     {ok arraySum   (1..10) ==  55;                                                 
      ok arrayProduct(1..5) == 120;                                                 
      is_deeply[arrayTimes(2, 1..5)], [qw(2 4 6 8 10)];                             
    

### md5FromGuid($G)

Recover an [MD5](https://en.wikipedia.org/wiki/MD5) sum from a [guid](https://en.wikipedia.org/wiki/Universally_unique_identifier). 
       Parameter  Description
    1  $G         Guid

**Example:**

      my $s = join '', 1..100;
      my $m = q(ef69caaaeea9c17120821a9eb6c7f1de);
    
      ok stringMd5Sum($s) eq $m;
    
      my $f = writeFile(undef, $s);
      ok fileMd5Sum($f) eq $m;
      unlink $f;
    
      ok guidFromString(join '', 1..100) eq
         q(GUID-ef69caaa-eea9-c171-2082-1a9eb6c7f1de);
    
      ok guidFromMd5(stringMd5Sum(join('', 1..100))) eq
         q(GUID-ef69caaa-eea9-c171-2082-1a9eb6c7f1de);
    
    
      ok md5FromGuid(q(GUID-ef69caaa-eea9-c171-2082-1a9eb6c7f1de)) eq  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                          q(ef69caaaeea9c17120821a9eb6c7f1de);
    
      ok stringMd5Sum(q(𝝰 𝝱 𝝲)) eq q(3c2b7c31b1011998bd7e1f66fb7c024d);
    }
    
    if (1)
     {ok arraySum   (1..10) ==  55;                                                 
      ok arrayProduct(1..5) == 120;                                                 
      is_deeply[arrayTimes(2, 1..5)], [qw(2 4 6 8 10)];                             
    

### guidFromString($string)

Create a [guid](https://en.wikipedia.org/wiki/Universally_unique_identifier) representation of the [MD5](https://en.wikipedia.org/wiki/MD5) of the content of a [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
       Parameter  Description
    1  $string    String

**Example:**

      my $s = join '', 1..100;
      my $m = q(ef69caaaeea9c17120821a9eb6c7f1de);
    
      ok stringMd5Sum($s) eq $m;
    
      my $f = writeFile(undef, $s);
      ok fileMd5Sum($f) eq $m;
      unlink $f;
    
    
      ok guidFromString(join '', 1..100) eq  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         q(GUID-ef69caaa-eea9-c171-2082-1a9eb6c7f1de);
    
      ok guidFromMd5(stringMd5Sum(join('', 1..100))) eq
         q(GUID-ef69caaa-eea9-c171-2082-1a9eb6c7f1de);
    
      ok md5FromGuid(q(GUID-ef69caaa-eea9-c171-2082-1a9eb6c7f1de)) eq
                          q(ef69caaaeea9c17120821a9eb6c7f1de);
    
      ok stringMd5Sum(q(𝝰 𝝱 𝝲)) eq q(3c2b7c31b1011998bd7e1f66fb7c024d);
    }
    
    if (1)
     {ok arraySum   (1..10) ==  55;                                                 
      ok arrayProduct(1..5) == 120;                                                 
      is_deeply[arrayTimes(2, 1..5)], [qw(2 4 6 8 10)];                             
    

### fileModTime($file)

Get the modified time of a **$file** as seconds since the epoch.

       Parameter  Description
    1  $file      File name

**Example:**

    ok fileModTime($0) =~ m(\A\d+\Z)s;                                                # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### fileOutOfDate($make, $target, @source)

Calls the specified [sub](https://perldoc.perl.org/perlsub.html) **$make** for each source [file](https://en.wikipedia.org/wiki/Computer_file) that is missing and then again against the **$target** [file](https://en.wikipedia.org/wiki/Computer_file) if any of the **@source** files were missing or the $target [file](https://en.wikipedia.org/wiki/Computer_file) is older than any of the @source files or if the target does not exist. The [file](https://en.wikipedia.org/wiki/Computer_file) name is passed to the [sub](https://perldoc.perl.org/perlsub.html) each time in $\_. Returns the files to be remade in the order they should be made.

       Parameter  Description
    1  $make      Make with this [sub](https://perldoc.perl.org/perlsub.html)     2  $target    Target [file](https://en.wikipedia.org/wiki/Computer_file)     3  @source    Source files

**Example:**

      my @Files = qw(a b c);
      my @files = (@Files, qw(d));
      writeFile($_, $_), sleep 1 for @Files;
    
      my $a = '';
    
      my @a = fileOutOfDate {$a .= $_} q(a), @files;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $a eq 'da';
      is_deeply [@a], [qw(d a)];
    
      my $b = '';
    
      my @b = fileOutOfDate {$b .= $_} q(b), @files;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $b eq 'db';
      is_deeply [@b], [qw(d b)];
    
      my $c = '';
    
      my @c = fileOutOfDate {$c .= $_} q(c), @files;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $c eq 'dc';
      is_deeply [@c], [qw(d c)];
    
      my $d = '';
    
      my @d = fileOutOfDate {$d .= $_} q(d), @files;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $d eq 'd';
      is_deeply [@d], [qw(d)];
    
    
      my @A = fileOutOfDate {} q(a), @Files;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my @B = fileOutOfDate {} q(b), @Files;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my @C = fileOutOfDate {} q(c), @Files;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply [@A], [qw(a)];
      is_deeply [@B], [qw(b)];
      is_deeply [@C], [];
      unlink for @Files;
    

### firstFileThatExists(@files)

Returns the name of the first [file](https://en.wikipedia.org/wiki/Computer_file) from **@files** that exists or **undef** if none of the named @files exist.

       Parameter  Description
    1  @files     Files to check

**Example:**

      my $d = temporaryFolder;                                                      
    
    
      ok $d eq firstFileThatExists("$d/$d", $d);                                      # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### fileInWindowsFormat($file)

Convert a [Unix](https://en.wikipedia.org/wiki/Unix) **$file** name to windows format.

       Parameter  Description
    1  $file      File

**Example:**

    if (1)                                                                          
    
     {ok fileInWindowsFormat(fpd(qw(/a b c d))) eq q(\a\b\c\d\\);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## Components

File names and components.

### Fusion

Create [file](https://en.wikipedia.org/wiki/Computer_file) names from [file](https://en.wikipedia.org/wiki/Computer_file) name components.

#### filePath(@file)

Create a [file](https://en.wikipedia.org/wiki/Computer_file) name from a [list](https://en.wikipedia.org/wiki/Linked_list) of  names. Identical to [fpf](#fpf).

       Parameter  Description
    1  @file      File name components

**Example:**

      is_deeply filePath   (qw(/aaa bbb ccc ddd.eee)) , prefferedFileName "/aaa/bbb/ccc/ddd.eee";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply filePathDir(qw(/aaa bbb ccc ddd))     , prefferedFileName "/aaa/bbb/ccc/ddd/";
      is_deeply filePathDir('', qw(aaa))              , prefferedFileName "aaa/";
      is_deeply filePathDir('')                       , prefferedFileName "";
      is_deeply filePathExt(qw(aaa xxx))              , prefferedFileName "aaa.xxx";
      is_deeply filePathExt(qw(aaa bbb xxx))          , prefferedFileName "aaa/bbb.xxx";
    
      is_deeply fpd        (qw(/aaa bbb ccc ddd))     , prefferedFileName "/aaa/bbb/ccc/ddd/";
      is_deeply fpf        (qw(/aaa bbb ccc ddd.eee)) , prefferedFileName "/aaa/bbb/ccc/ddd.eee";
      is_deeply fpe        (qw(aaa bbb xxx))          , prefferedFileName "aaa/bbb.xxx";
    

**fpf** is a synonym for [filePath](#filepath).

#### filePathDir(@file)

Create a [folder](https://en.wikipedia.org/wiki/File_folder) name from a [list](https://en.wikipedia.org/wiki/Linked_list) of  names. Identical to [fpd](#fpd).

       Parameter  Description
    1  @file      Directory name components

**Example:**

      is_deeply filePath   (qw(/aaa bbb ccc ddd.eee)) , prefferedFileName "/aaa/bbb/ccc/ddd.eee";
    
      is_deeply filePathDir(qw(/aaa bbb ccc ddd))     , prefferedFileName "/aaa/bbb/ccc/ddd/";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply filePathDir('', qw(aaa))              , prefferedFileName "aaa/";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply filePathDir('')                       , prefferedFileName "";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply filePathExt(qw(aaa xxx))              , prefferedFileName "aaa.xxx";
      is_deeply filePathExt(qw(aaa bbb xxx))          , prefferedFileName "aaa/bbb.xxx";
    
      is_deeply fpd        (qw(/aaa bbb ccc ddd))     , prefferedFileName "/aaa/bbb/ccc/ddd/";
      is_deeply fpf        (qw(/aaa bbb ccc ddd.eee)) , prefferedFileName "/aaa/bbb/ccc/ddd.eee";
      is_deeply fpe        (qw(aaa bbb xxx))          , prefferedFileName "aaa/bbb.xxx";
    

**fpd** is a synonym for [filePathDir](#filepathdir).

#### filePathExt(@File)

Create a [file](https://en.wikipedia.org/wiki/Computer_file) name from a [list](https://en.wikipedia.org/wiki/Linked_list) of  names the last of which is assumed to be the extension of the [file](https://en.wikipedia.org/wiki/Computer_file) name. Identical to [fpe](#fpe).

       Parameter  Description
    1  @File      File name components and extension

**Example:**

      is_deeply filePath   (qw(/aaa bbb ccc ddd.eee)) , prefferedFileName "/aaa/bbb/ccc/ddd.eee";
      is_deeply filePathDir(qw(/aaa bbb ccc ddd))     , prefferedFileName "/aaa/bbb/ccc/ddd/";
      is_deeply filePathDir('', qw(aaa))              , prefferedFileName "aaa/";
      is_deeply filePathDir('')                       , prefferedFileName "";
    
      is_deeply filePathExt(qw(aaa xxx))              , prefferedFileName "aaa.xxx";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply filePathExt(qw(aaa bbb xxx))          , prefferedFileName "aaa/bbb.xxx";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply fpd        (qw(/aaa bbb ccc ddd))     , prefferedFileName "/aaa/bbb/ccc/ddd/";
      is_deeply fpf        (qw(/aaa bbb ccc ddd.eee)) , prefferedFileName "/aaa/bbb/ccc/ddd.eee";
      is_deeply fpe        (qw(aaa bbb xxx))          , prefferedFileName "aaa/bbb.xxx";
    

**fpe** is a synonym for [filePathExt](#filepathext).

### Fission

Get [file](https://en.wikipedia.org/wiki/Computer_file) name components from a [file](https://en.wikipedia.org/wiki/Computer_file) name.

#### fp($file)

Get the path from a [file](https://en.wikipedia.org/wiki/Computer_file) name.

       Parameter  Description
    1  $file      File name

**Example:**

    ok fp (prefferedFileName q(a/b/c.d.e))  eq prefferedFileName q(a/b/);                               # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

#### fpn($file)

Remove the extension from a [file](https://en.wikipedia.org/wiki/Computer_file) name.

       Parameter  Description
    1  $file      File name

**Example:**

    ok fpn(prefferedFileName q(a/b/c.d.e))  eq prefferedFileName q(a/b/c.d);                            # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

#### fn($file)

Remove the path and extension from a [file](https://en.wikipedia.org/wiki/Computer_file) name.

       Parameter  Description
    1  $file      File name

**Example:**

    ok fn (prefferedFileName q(a/b/c.d.e))  eq prefferedFileName q(c.d);                                # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

#### fne($file)

Remove the path from a [file](https://en.wikipedia.org/wiki/Computer_file) name.

       Parameter  Description
    1  $file      File name

**Example:**

    ok fne(prefferedFileName q(a/b/c.d.e))  eq prefferedFileName q(c.d.e);                              # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

#### fe($file)

Get the extension of a [file](https://en.wikipedia.org/wiki/Computer_file) name.

       Parameter  Description
    1  $file      File name

**Example:**

    ok fe (prefferedFileName q(a/b/c.d.e))  eq prefferedFileName q(e);                                  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

#### checkFile($file)

Return the name of the specified [file](https://en.wikipedia.org/wiki/Computer_file) if it exists, else [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) the maximum extent of the path that does exist.

       Parameter  Description
    1  $file      File to check

**Example:**

      my $d = filePath   (my @d = qw(a b c d));                                      
    
      my $f = filePathExt(qw(a b c d e x));                                         
    
      my $F = filePathExt(qw(a b c e d));                                           
    
      createEmptyFile($f);                                                          
    
    
      ok  eval{checkFile($d)};                                                        # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    
      ok  eval{checkFile($f)};                                                        # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

#### quoteFile($file)

Quote a [file](https://en.wikipedia.org/wiki/Computer_file) name.

       Parameter  Description
    1  $file      File name

**Example:**

    is_deeply quoteFile(fpe(qw(a "b" c))), onWindows ? q("a\\\"b\".c") : q("a/\"b\".c");   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

#### removeFilePrefix($prefix, @files)

Removes a [file](https://en.wikipedia.org/wiki/Computer_file) **$prefix** from an [array](https://en.wikipedia.org/wiki/Dynamic_array) of **@files**.

       Parameter  Description
    1  $prefix    File prefix
    2  @files     Array of [file](https://en.wikipedia.org/wiki/Computer_file) names

**Example:**

    is_deeply [qw(a b)], [&removeFilePrefix(qw(a/ a/a a/b))];                         # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    
    is_deeply [qw(b)],   [&removeFilePrefix("a/", "a/b")];                            # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

#### swapFilePrefix($file, $known, $new)

Swaps the start of a **$file** name from a **$known** name to a **$new** one if the [file](https://en.wikipedia.org/wiki/Computer_file) does in fact start with the $known name otherwise returns the original [file](https://en.wikipedia.org/wiki/Computer_file) name as it is. If the optional $new prefix is omitted then the $known prefix is removed from the $file name.

       Parameter  Description
    1  $file      File name
    2  $known     Existing prefix
    3  $new       Optional new prefix defaults to q()

**Example:**

    ok swapFilePrefix(q(/aaa/bbb.txt), q(/aaa/), q(/AAA/)) eq q(/AAA/bbb.txt);        # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

#### setFileExtension($file, $extension)

Given a **$file**, change its extension to **$extension**. Removes the extension if no $extension is specified.

       Parameter   Description
    1  $file       File name
    2  $extension  Optional new extension

**Example:**

    ok setFileExtension(q(.c),     q(d)) eq q(.d);                                    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    
    ok setFileExtension(q(b.c),    q(d)) eq q(b.d);                                   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    
    ok setFileExtension(q(/a/b.c), q(d)) eq q(/a/b.d);                                # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

#### swapFolderPrefix($file, $known, $new)

Given a **$file**, swap the [folder](https://en.wikipedia.org/wiki/File_folder) name of the $file from **$known** to **$new** if the [file](https://en.wikipedia.org/wiki/Computer_file) $file starts with the $known [folder](https://en.wikipedia.org/wiki/File_folder) name else return the $file as it is.

       Parameter  Description
    1  $file      File name
    2  $known     Existing prefix
    3  $new       New prefix

**Example:**

      my $g = fpd(qw(a b c d));
      my $h = fpd(qw(a b cc dd));
      my $i = fpe($g, qw(aaa txt));
    
    
      my $j = swapFolderPrefix($i, $g, $h);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $j =~ m(a/b/cc/dd/)s     unless onWindows;
      ok $j =~ m(a\\b\\cc\\dd\\)s if     onWindows;
    

#### fullyQualifiedFile($file, $prefix)

Check whether a **$file** name is fully qualified or not and, optionally, whether it is fully qualified with a specified **$prefix** or not.

       Parameter  Description
    1  $file      File name to [test](https://en.wikipedia.org/wiki/Software_testing)     2  $prefix    File name prefix

**Example:**

    ok  fullyQualifiedFile(q(/a/b/c.d));                                              # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    
    ok  fullyQualifiedFile(q(/a/b/c.d), q(/a/b));                                     # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    
    ok !fullyQualifiedFile(q(/a/b/c.d), q(/a/c));                                     # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    
    ok !fullyQualifiedFile(q(c.d));                                                   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

#### fullyQualifyFile($file)

Return the fully qualified name of a [file](https://en.wikipedia.org/wiki/Computer_file). 
       Parameter  Description
    1  $file      File name

**Example:**

    if (0)                                                                          
    
     {ok fullyQualifyFile(q(perl/cpan)) eq q(/home/phil/perl/cpan/);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

#### removeDuplicatePrefixes($file)

Remove duplicated leading directory names from a [file](https://en.wikipedia.org/wiki/Computer_file) name.

       Parameter  Description
    1  $file      File name

**Example:**

    ok q(a/b.c) eq removeDuplicatePrefixes("a/a/b.c");                                # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    
    ok q(a/b.c) eq removeDuplicatePrefixes("a/b.c");                                  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    
    ok q(b.c) eq removeDuplicatePrefixes("b.c");                                      # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

#### containingFolderName($file)

The name of a [folder](https://en.wikipedia.org/wiki/File_folder) containing a [file](https://en.wikipedia.org/wiki/Computer_file). 
       Parameter  Description
    1  $file      File name

**Example:**

    ok containingFolderName(q(/a/b/c.d)) eq q(b);                                     # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## Position

Position in the [file](https://en.wikipedia.org/wiki/Computer_file) system.

### currentDirectory()

Get the current working directory.

**Example:**

      currentDirectory;                                                               # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### currentDirectoryAbove()

Get the path to the [folder](https://en.wikipedia.org/wiki/File_folder) above the current working [folder](https://en.wikipedia.org/wiki/File_folder). 
**Example:**

      currentDirectoryAbove;                                                          # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### parseFileName($file)

Parse a [file](https://en.wikipedia.org/wiki/Computer_file) name into (path, name, extension) considering .. to be always part of the path and using **undef** to mark missing components.  This differs from (fp, fn, fe) which return q() for missing components and do not interpret . or .. as anything special.

       Parameter  Description
    1  $file      File name to [parse](https://en.wikipedia.org/wiki/Parsing) 
**Example:**

    if (1)                                                                          
    
     {is_deeply [parseFileName "/home/phil/test.data"], ["/home/phil/", "test", "data"];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseFileName "/home/phil/test"],      ["/home/phil/", "test"];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseFileName "phil/test.data"],       ["phil/",       "test", "data"];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseFileName "phil/test"],            ["phil/",       "test"];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseFileName "test.data"],            [undef,         "test", "data"];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseFileName "phil/"],                [qw(phil/)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseFileName "/phil"],                [qw(/ phil)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseFileName "/"],                    [qw(/)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseFileName "/var/www/html/translations/"], [qw(/var/www/html/translations/)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseFileName "a.b/c.d.e"],            [qw(a.b/ c.d e)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseFileName "./a.b"],                [qw(./ a b)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseFileName "./../../a.b"],          [qw(./../../ a b)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

### fullFileName()

Full name of a [file](https://en.wikipedia.org/wiki/Computer_file). 
**Example:**

      fullFileName(fpe(qw(a txt)));                                                   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### relFromAbsAgainstAbs($a, $b)

Relative [file](https://en.wikipedia.org/wiki/Computer_file) from one absolute [file](https://en.wikipedia.org/wiki/Computer_file) **$a** against another **$b**.

       Parameter  Description
    1  $a         Absolute [file](https://en.wikipedia.org/wiki/Computer_file) to be made relative
    2  $b         Against this absolute [file](https://en.wikipedia.org/wiki/Computer_file). 
**Example:**

    ok "bbb.pl"                 eq relFromAbsAgainstAbs("/home/la/perl/bbb.pl", "/home/la/perl/aaa.pl");    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    
    ok "../perl/bbb.pl"         eq relFromAbsAgainstAbs("/home/la/perl/bbb.pl", "/home/la/java/aaa.jv");    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### absFromAbsPlusRel($a, $r)

Absolute [file](https://en.wikipedia.org/wiki/Computer_file) from an absolute [file](https://en.wikipedia.org/wiki/Computer_file) **$a** plus a relative [file](https://en.wikipedia.org/wiki/Computer_file) **$r**. In the event that the relative [file](https://en.wikipedia.org/wiki/Computer_file) $r is, in fact, an absolute [file](https://en.wikipedia.org/wiki/Computer_file) then it is returned as the result.

       Parameter  Description
    1  $a         Absolute [file](https://en.wikipedia.org/wiki/Computer_file)     2  $r         Relative [file](https://en.wikipedia.org/wiki/Computer_file) 
**Example:**

    ok "/home/la/perl/aaa.pl"   eq absFromAbsPlusRel("/home/la/perl/bbb",      "aaa.pl");                   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    
    ok "/home/la/perl/aaa.pl"   eq absFromAbsPlusRel("/home/il/perl/bbb.pl",   "../../la/perl/aaa.pl");      # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### absFile($file)

Return the name of the given [file](https://en.wikipedia.org/wiki/Computer_file) if it a fully qualified [file](https://en.wikipedia.org/wiki/Computer_file) name else returns **undef**. See: [fullyQualifiedFile](https://metacpan.org/pod/fullyQualifiedFile) to check the initial prefix of the [file](https://en.wikipedia.org/wiki/Computer_file) name as well.

       Parameter  Description
    1  $file      File to [test](https://en.wikipedia.org/wiki/Software_testing) 
**Example:**

    ok "/aaa/"                  eq absFile(qw(/aaa/));                                # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### sumAbsAndRel(@files)

Combine zero or more absolute and relative names of **@files** starting at the current working [folder](https://en.wikipedia.org/wiki/File_folder) to get an absolute [file](https://en.wikipedia.org/wiki/Computer_file) name.

       Parameter  Description
    1  @files     Absolute and relative [file](https://en.wikipedia.org/wiki/Computer_file) names

**Example:**

    ok "/aaa/bbb/ccc/ddd.txt"   eq sumAbsAndRel(qw(/aaa/AAA/ ../bbb/bbb/BBB/ ../../ccc/ddd.txt));   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## Temporary

Temporary files and folders

### temporaryFile()

Create a new, empty, temporary [file](https://en.wikipedia.org/wiki/Computer_file). 
**Example:**

      my $d = fpd(my $D = temporaryDirectory, qw(a));
      my $f = fpe($d, qw(bbb txt));
      ok !-d $d;
      [eval](http://perldoc.perl.org/functions/eval.html) q{checkFile($f)};
      my $r = $@;
      my $q = quotemeta($D);
      ok nws($r) =~ m(Can only find.+?: $q)s;
      makePath($f);
      ok -d $d;
      ok -d $D;
      rmdir $_ for $d, $D;
    
      my $e = temporaryFolder;                                                      # Same as temporyDirectory
      ok -d $e;
      clearFolder($e, 2);
    
    
      my $t = temporaryFile;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok  -f $t;
      unlink $t;
      ok !-f $t;
    
      if (0)
       {makePathRemote($e);                                                         # Make a path on the remote system
       }
    

### temporaryFolder()

Create a new, empty, temporary [folder](https://en.wikipedia.org/wiki/File_folder). 
**Example:**

      my $D = temporaryFolder;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok  -d $D;
    
      my $d = fpd($D, q(ddd));
      ok !-d $d;
    
      my @f = map {createEmptyFile(fpe($d, $_, qw(txt)))} qw(a b c);
      is_deeply [sort map {fne $_} findFiles($d, qr(txt\Z))], [qw(a.txt b.txt c.txt)];
    
      my @D = findDirs($D);
      my @e = ($D, $d);
      my @E = [sort](https://en.wikipedia.org/wiki/Sorting) @e;
      is_deeply [@D], [@E];
    
      is_deeply [sort map {fne $_} searchDirectoryTreesForMatchingFiles($d)],
                ["a.txt", "b.txt", "c.txt"];
    
      is_deeply [sort map {fne $_} fileList(prefferedFileName "$d/*.txt")],
                ["a.txt", "b.txt", "c.txt"];
    
      ok -e $_ for @f;
    
      is_deeply scalar(searchDirectoryTreeForSubFolders $D), 2;
    
      my @g = fileList(qq($D/*/*.txt));
      ok @g == 3;
    
      clearFolder($D, 5);
      ok onWindows ? 1 : !-e $_ for @f;
      ok onWindows ? 1 : !-d $D;
    
      my $d = fpd(my $D = temporaryDirectory, qw(a));
      my $f = fpe($d, qw(bbb txt));
      ok !-d $d;
      [eval](http://perldoc.perl.org/functions/eval.html) q{checkFile($f)};
      my $r = $@;
      my $q = quotemeta($D);
      ok nws($r) =~ m(Can only find.+?: $q)s;
      makePath($f);
      ok -d $d;
      ok -d $D;
      rmdir $_ for $d, $D;
    
    
      my $e = temporaryFolder;                                                      # Same as temporyDirectory  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok -d $e;
      clearFolder($e, 2);
    
      my $t = temporaryFile;
      ok  -f $t;
      unlink $t;
      ok !-f $t;
    
      if (0)
       {makePathRemote($e);                                                         # Make a path on the remote system
       }
    

**temporaryDirectory** is a synonym for [temporaryFolder](#temporaryfolder).

## Find

Find files and folders below a [folder](https://en.wikipedia.org/wiki/File_folder). 
### findFiles($folder, $filter)

Find all the files under a **$folder** and optionally **$filter** the selected files with a regular expression.

       Parameter  Description
    1  $folder    Folder to start the search with
    2  $filter    Optional regular expression to filter files

**Example:**

      my $D = temporaryFolder;
      ok  -d $D;
    
      my $d = fpd($D, q(ddd));
      ok !-d $d;
    
      my @f = map {createEmptyFile(fpe($d, $_, qw(txt)))} qw(a b c);
    
      is_deeply [sort map {fne $_} findFiles($d, qr(txt\Z))], [qw(a.txt b.txt c.txt)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my @D = findDirs($D);
      my @e = ($D, $d);
      my @E = [sort](https://en.wikipedia.org/wiki/Sorting) @e;
      is_deeply [@D], [@E];
    
      is_deeply [sort map {fne $_} searchDirectoryTreesForMatchingFiles($d)],
                ["a.txt", "b.txt", "c.txt"];
    
      is_deeply [sort map {fne $_} fileList(prefferedFileName "$d/*.txt")],
                ["a.txt", "b.txt", "c.txt"];
    
      ok -e $_ for @f;
    
      is_deeply scalar(searchDirectoryTreeForSubFolders $D), 2;
    
      my @g = fileList(qq($D/*/*.txt));
      ok @g == 3;
    
      clearFolder($D, 5);
      ok onWindows ? 1 : !-e $_ for @f;
      ok onWindows ? 1 : !-d $D;
    

### findDirs($folder, $filter)

Find all the folders under a **$folder** and optionally **$filter** the selected folders with a regular expression.

       Parameter  Description
    1  $folder    Folder to start the search with
    2  $filter    Optional regular expression to filter files

**Example:**

      my $D = temporaryFolder;
      ok  -d $D;
    
      my $d = fpd($D, q(ddd));
      ok !-d $d;
    
      my @f = map {createEmptyFile(fpe($d, $_, qw(txt)))} qw(a b c);
      is_deeply [sort map {fne $_} findFiles($d, qr(txt\Z))], [qw(a.txt b.txt c.txt)];
    
    
      my @D = findDirs($D);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my @e = ($D, $d);
      my @E = [sort](https://en.wikipedia.org/wiki/Sorting) @e;
      is_deeply [@D], [@E];
    
      is_deeply [sort map {fne $_} searchDirectoryTreesForMatchingFiles($d)],
                ["a.txt", "b.txt", "c.txt"];
    
      is_deeply [sort map {fne $_} fileList(prefferedFileName "$d/*.txt")],
                ["a.txt", "b.txt", "c.txt"];
    
      ok -e $_ for @f;
    
      is_deeply scalar(searchDirectoryTreeForSubFolders $D), 2;
    
      my @g = fileList(qq($D/*/*.txt));
      ok @g == 3;
    
      clearFolder($D, 5);
      ok onWindows ? 1 : !-e $_ for @f;
      ok onWindows ? 1 : !-d $D;
    

### fileList($pattern)

Files that match a given search pattern interpreted by ["bsd\_glob" in perlfunc](https://metacpan.org/pod/perlfunc#bsd_glob).

       Parameter  Description
    1  $pattern   Search pattern

**Example:**

      my $D = temporaryFolder;
      ok  -d $D;
    
      my $d = fpd($D, q(ddd));
      ok !-d $d;
    
      my @f = map {createEmptyFile(fpe($d, $_, qw(txt)))} qw(a b c);
      is_deeply [sort map {fne $_} findFiles($d, qr(txt\Z))], [qw(a.txt b.txt c.txt)];
    
      my @D = findDirs($D);
      my @e = ($D, $d);
      my @E = [sort](https://en.wikipedia.org/wiki/Sorting) @e;
      is_deeply [@D], [@E];
    
      is_deeply [sort map {fne $_} searchDirectoryTreesForMatchingFiles($d)],
                ["a.txt", "b.txt", "c.txt"];
    
    
      is_deeply [sort map {fne $_} fileList(prefferedFileName "$d/*.txt")],  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                ["a.txt", "b.txt", "c.txt"];
    
      ok -e $_ for @f;
    
      is_deeply scalar(searchDirectoryTreeForSubFolders $D), 2;
    
    
      my @g = fileList(qq($D/*/*.txt));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok @g == 3;
    
      clearFolder($D, 5);
      ok onWindows ? 1 : !-e $_ for @f;
      ok onWindows ? 1 : !-d $D;
    

### searchDirectoryTreesForMatchingFiles(@FoldersandExtensions)

Search the specified directory [trees](https://en.wikipedia.org/wiki/Tree_(data_structure)) for the files (not folders) that match the specified [file name extensions](https://en.wikipedia.org/wiki/List_of_filename_extensions). The argument [list](https://en.wikipedia.org/wiki/Linked_list) should include at least one path name to be useful. If no [file](https://en.wikipedia.org/wiki/Computer_file) [file name extensions](https://en.wikipedia.org/wiki/List_of_filename_extensions) are supplied then all the files below the specified paths are returned.  Arguments wrapped in \[\] will be unwrapped.

       Parameter              Description
    1  @FoldersandExtensions  Mixture of [folder](https://en.wikipedia.org/wiki/File_folder) names and [file name extensions](https://en.wikipedia.org/wiki/List_of_filename_extensions) 
**Example:**

      my $D = temporaryFolder;
      ok  -d $D;
    
      my $d = fpd($D, q(ddd));
      ok !-d $d;
    
      my @f = map {createEmptyFile(fpe($d, $_, qw(txt)))} qw(a b c);
      is_deeply [sort map {fne $_} findFiles($d, qr(txt\Z))], [qw(a.txt b.txt c.txt)];
    
      my @D = findDirs($D);
      my @e = ($D, $d);
      my @E = [sort](https://en.wikipedia.org/wiki/Sorting) @e;
      is_deeply [@D], [@E];
    
    
      is_deeply [sort map {fne $_} searchDirectoryTreesForMatchingFiles($d)],  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                ["a.txt", "b.txt", "c.txt"];
    
      is_deeply [sort map {fne $_} fileList(prefferedFileName "$d/*.txt")],
                ["a.txt", "b.txt", "c.txt"];
    
      ok -e $_ for @f;
    
      is_deeply scalar(searchDirectoryTreeForSubFolders $D), 2;
    
      my @g = fileList(qq($D/*/*.txt));
      ok @g == 3;
    
      clearFolder($D, 5);
      ok onWindows ? 1 : !-e $_ for @f;
      ok onWindows ? 1 : !-d $D;
    

### searchDirectoryTreeForSubFolders($folder)

Search the specified directory under the specified [folder](https://en.wikipedia.org/wiki/File_folder) for [sub](https://perldoc.perl.org/perlsub.html) folders.

       Parameter  Description
    1  $folder    The [folder](https://en.wikipedia.org/wiki/File_folder) at which to start the search

**Example:**

      my $D = temporaryFolder;
      ok  -d $D;
    
      my $d = fpd($D, q(ddd));
      ok !-d $d;
    
      my @f = map {createEmptyFile(fpe($d, $_, qw(txt)))} qw(a b c);
      is_deeply [sort map {fne $_} findFiles($d, qr(txt\Z))], [qw(a.txt b.txt c.txt)];
    
      my @D = findDirs($D);
      my @e = ($D, $d);
      my @E = [sort](https://en.wikipedia.org/wiki/Sorting) @e;
      is_deeply [@D], [@E];
    
      is_deeply [sort map {fne $_} searchDirectoryTreesForMatchingFiles($d)],
                ["a.txt", "b.txt", "c.txt"];
    
      is_deeply [sort map {fne $_} fileList(prefferedFileName "$d/*.txt")],
                ["a.txt", "b.txt", "c.txt"];
    
      ok -e $_ for @f;
    
    
      is_deeply scalar(searchDirectoryTreeForSubFolders $D), 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my @g = fileList(qq($D/*/*.txt));
      ok @g == 3;
    
      clearFolder($D, 5);
      ok onWindows ? 1 : !-e $_ for @f;
      ok onWindows ? 1 : !-d $D;
    

### hashifyFolderStructure(@files)

Hashify a [list](https://en.wikipedia.org/wiki/Linked_list) of [file](https://en.wikipedia.org/wiki/Computer_file) names to get the corresponding [folder](https://en.wikipedia.org/wiki/File_folder) structure.

       Parameter  Description
    1  @files     File names

**Example:**

      is_deeply hashifyFolderStructure(qw(/a/a/a /a/a/b /a/b/a /a/b/b)),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {"" => {a => {a => { a => "/a/a/a", b => "/a/a/b" },
                     b => { a => "/a/b/a", b => "/a/b/b" },
                    },
              },
       };
    

### countFileExtensions(@folders)

Return a [hash](https://en.wikipedia.org/wiki/Hash_table) which counts the [file](https://en.wikipedia.org/wiki/Computer_file) [file name extensions](https://en.wikipedia.org/wiki/List_of_filename_extensions) in and below the folders in the specified [list](https://en.wikipedia.org/wiki/Linked_list). 
       Parameter  Description
    1  @folders   Folders to search

**Example:**

      countFileExtensions(q(/home/phil/perl/));                                       # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### countFileTypes($maximumNumberOfProcesses, @folders)

Return a [hash](https://en.wikipedia.org/wiki/Hash_table) which counts, in parallel with a maximum number of [processes](https://en.wikipedia.org/wiki/Process_management_(computing)): **$maximumNumberOfProcesses**, the results of applying the **file** command to each [file](https://en.wikipedia.org/wiki/Computer_file) in and under the specified **@folders**.

       Parameter                  Description
    1  $maximumNumberOfProcesses  Maximum number of [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) to run in parallel
    2  @folders                   Folders to search

**Example:**

      countFileTypes(4, q(/home/phil/perl/));                                         # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### matchPath($file)

Return the deepest [folder](https://en.wikipedia.org/wiki/File_folder) that exists along a given [file](https://en.wikipedia.org/wiki/Computer_file) name path.

       Parameter  Description
    1  $file      File name

**Example:**

      my $d = filePath   (my @d = qw(a b c d));                                      
    
    
      ok matchPath($d) eq $d;                                                         # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### findFileWithExtension($file, @ext)

Find the first [file](https://en.wikipedia.org/wiki/Computer_file) that exists with a path and name of **$file** and an extension drawn from <@ext>.

       Parameter  Description
    1  $file      File name minus [file name extensions](https://en.wikipedia.org/wiki/List_of_filename_extensions)     2  @ext       Possible [file name extensions](https://en.wikipedia.org/wiki/List_of_filename_extensions) 
**Example:**

      my $f = createEmptyFile(fpe(my $d = temporaryFolder, qw(a jpg)));             
    
    
      my $F = findFileWithExtension(fpf($d, q(a)), qw(txt data jpg));                 # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok $F eq "jpg";                                                               
    

### clearFolder($folder, $limitCount, $noMsg)

Remove all the files and folders under and including the specified **$folder** as long as the number of files to be removed is less than the specified **$limitCount**. Sometimes the [folder](https://en.wikipedia.org/wiki/File_folder) can be emptied but not removed - perhaps because it a link, in this case a message is produced unless suppressed by the optional **$nomsg** parameter.

       Parameter    Description
    1  $folder      Folder
    2  $limitCount  Maximum number of files to remove to limit damage
    3  $noMsg       No message if the [folder](https://en.wikipedia.org/wiki/File_folder) cannot be completely removed.

**Example:**

      my $D = temporaryFolder;
      ok  -d $D;
    
      my $d = fpd($D, q(ddd));
      ok !-d $d;
    
      my @f = map {createEmptyFile(fpe($d, $_, qw(txt)))} qw(a b c);
      is_deeply [sort map {fne $_} findFiles($d, qr(txt\Z))], [qw(a.txt b.txt c.txt)];
    
      my @D = findDirs($D);
      my @e = ($D, $d);
      my @E = [sort](https://en.wikipedia.org/wiki/Sorting) @e;
      is_deeply [@D], [@E];
    
      is_deeply [sort map {fne $_} searchDirectoryTreesForMatchingFiles($d)],
                ["a.txt", "b.txt", "c.txt"];
    
      is_deeply [sort map {fne $_} fileList(prefferedFileName "$d/*.txt")],
                ["a.txt", "b.txt", "c.txt"];
    
      ok -e $_ for @f;
    
      is_deeply scalar(searchDirectoryTreeForSubFolders $D), 2;
    
      my @g = fileList(qq($D/*/*.txt));
      ok @g == 3;
    
    
      clearFolder($D, 5);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok onWindows ? 1 : !-e $_ for @f;
      ok onWindows ? 1 : !-d $D;
    

## Read and write files

Read and write [strings](https://en.wikipedia.org/wiki/String_(computer_science)) from and to files creating paths to any created files as needed.

### readFile($file)

Return the content of a [file](https://en.wikipedia.org/wiki/Computer_file) residing on the local machine interpreting the content of the [file](https://en.wikipedia.org/wiki/Computer_file) as [utf8](https://en.wikipedia.org/wiki/UTF-8).

       Parameter  Description
    1  $file      Name of [file](https://en.wikipedia.org/wiki/Computer_file) to read

**Example:**

      my $f = writeFile(undef,  "aaa");
    
      is_deeply [readFile $f], ["aaa"];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      appendFile($f, "bbb");
    
      is_deeply [readFile $f], ["aaabbb"];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $F = writeTempFile(qw(aaa bbb));
    
      is_deeply [readFile $F], ["aaa
  ", "bbb
  "];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      [eval](http://perldoc.perl.org/functions/eval.html) {writeFile($f,  q(ccc))};
      ok $@ =~ m(File already exists:)i;
    
      overWriteFile($F,    q(ccc));
    
      ok   readFile($F) eq q(ccc);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      unlink $f, $F;
    

### readStdIn()

Return the contents of STDIN and return the results as either an [array](https://en.wikipedia.org/wiki/Dynamic_array) or a [string](https://en.wikipedia.org/wiki/String_(computer_science)). Terminate with Ctrl-D if testing manually - STDIN remains open allowing this method to be called again to receive another block of data.

**Example:**

      my $d = qq(aaaa);
      open(STDIN, "<", writeTempFile($d));
    
      ok qq($d
  ) eq readStdIn;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### readFileFromRemote($file, $ip)

Copy and read a **$file** from the remote machine whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp) and return the content of $file interpreted as [utf8](https://en.wikipedia.org/wiki/UTF-8) .

       Parameter  Description
    1  $file      Name of [file](https://en.wikipedia.org/wiki/Computer_file) to read
    2  $ip        Optional [IP address](https://en.wikipedia.org/wiki/IP_address) address of [server](https://en.wikipedia.org/wiki/Server_(computing)) 
**Example:**

      my $f = writeFileToRemote(undef, q(aaaa));
      unlink $f;
    
      ok readFileFromRemote($f) eq q(aaaa);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      unlink $f;
    

### evalFile($file)

Read a [file](https://en.wikipedia.org/wiki/Computer_file) containing [Unicode](https://en.wikipedia.org/wiki/Unicode) content represented as [utf8](https://en.wikipedia.org/wiki/UTF-8), ["eval" in perlfunc](https://metacpan.org/pod/perlfunc#eval) the content, [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) to any errors and then return any result with [lvalue method](http://perldoc.perl.org/perlsub.html#Lvalue-subroutines) methods to access each [hash](https://en.wikipedia.org/wiki/Hash_table) element.

       Parameter  Description
    1  $file      File to read

**Example:**

      my $d = [qw(aaa bbb ccc), [{aaa=>'AAA', bbb=>'BBB'}]];
      my $f = dumpFile(undef, $d);
    
      is_deeply evalFile($f), $d;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply evalFile(my $F = dumpTempFile($d)), $d;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      unlink $f, $F;
    
      my $j = dumpFileAsJson(undef, $d);
      is_deeply evalFileAsJson($j), $d;
      is_deeply evalFileAsJson(my $J = dumpTempFileAsJson($d)), $d;
      unlink $j, $J;
    

### evalFileAsJson($file)

Read a **$file** containing [Json](https://en.wikipedia.org/wiki/JSON) and return the corresponding [Perl](http://www.perl.org/) data structure.

       Parameter  Description
    1  $file      File to read

**Example:**

      my $d = [qw(aaa bbb ccc), [{aaa=>'AAA', bbb=>'BBB'}]];
      my $f = dumpFile(undef, $d);
      is_deeply evalFile($f), $d;
      is_deeply evalFile(my $F = dumpTempFile($d)), $d;
      unlink $f, $F;
    
      my $j = dumpFileAsJson(undef, $d);
    
      is_deeply evalFileAsJson($j), $d;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply evalFileAsJson(my $J = dumpTempFileAsJson($d)), $d;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      unlink $j, $J;
    

### evalGZipFile($file)

Read a [file](https://en.wikipedia.org/wiki/Computer_file) compressed with [gzip](https://en.wikipedia.org/wiki/Gzip) containing [Unicode](https://en.wikipedia.org/wiki/Unicode) content represented as [utf8](https://en.wikipedia.org/wiki/UTF-8), ["eval" in perlfunc](https://metacpan.org/pod/perlfunc#eval) the content, [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) to any errors and then return any result with [lvalue method](http://perldoc.perl.org/perlsub.html#Lvalue-subroutines) methods to access each [hash](https://en.wikipedia.org/wiki/Hash_table) element. This is slower than using [Storable](https://metacpan.org/pod/Storable) but does produce much smaller files, see also: [dumpGZipFile](#dumpgzipfile).

       Parameter  Description
    1  $file      File to read

**Example:**

      my $d = [1, 2, 3=>{a=>4, b=>5}];
      my $file = dumpGZipFile(q(zzz.zip), $d);
      ok -e $file;
    
      my $D = evalGZipFile($file);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply $d, $D;
      unlink $file;
    

### retrieveFile($file)

Retrieve a **$file** created via [Storable](https://metacpan.org/pod/Storable).  This is much faster than [evalFile](#evalfile) as the stored data is not in text format.

       Parameter  Description
    1  $file      File to read

**Example:**

      my $f = storeFile(undef, my $d = [qw(aaa bbb ccc)]);
    
      my $s = retrieveFile($f);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply $s, $d;
      unlink $f;
    

### readBinaryFile($file)

Read a binary [file](https://en.wikipedia.org/wiki/Computer_file) on the local machine.

       Parameter  Description
    1  $file      File to read

**Example:**

      my $f = writeBinaryFile(undef, 0xff x 8);                                      
    
    
      my $s = readBinaryFile($f);                                                      # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok $s eq 0xff x 8;                                                             
    

### readGZipFile($file)

Read the specified [file](https://en.wikipedia.org/wiki/Computer_file) containing compressed [Unicode](https://en.wikipedia.org/wiki/Unicode) content represented as [utf8](https://en.wikipedia.org/wiki/UTF-8) through [gzip](https://en.wikipedia.org/wiki/Gzip).

       Parameter  Description
    1  $file      File to read.

**Example:**

      my $s = '𝝰'x1e3;
      my $file = writeGZipFile(q(zzz.zip), $s);
      ok -e $file;
    
      my $S = readGZipFile($file);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $s eq $S;
      ok length($s) == length($S);
      unlink $file;
    

### makePath($file)

Make the path for the specified [file](https://en.wikipedia.org/wiki/Computer_file) name or [folder](https://en.wikipedia.org/wiki/File_folder) on the local machine. Confess to any failure.

       Parameter  Description
    1  $file      File or [folder](https://en.wikipedia.org/wiki/File_folder) name

**Example:**

      my $d = fpd(my $D = temporaryDirectory, qw(a));
      my $f = fpe($d, qw(bbb txt));
      ok !-d $d;
      [eval](http://perldoc.perl.org/functions/eval.html) q{checkFile($f)};
      my $r = $@;
      my $q = quotemeta($D);
      ok nws($r) =~ m(Can only find.+?: $q)s;
    
      makePath($f);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok -d $d;
      ok -d $D;
      rmdir $_ for $d, $D;
    
      my $e = temporaryFolder;                                                      # Same as temporyDirectory
      ok -d $e;
      clearFolder($e, 2);
    
      my $t = temporaryFile;
      ok  -f $t;
      unlink $t;
      ok !-f $t;
    
      if (0)
       {makePathRemote($e);                                                         # Make a path on the remote system
       }
    

### makePathRemote($file, $ip)

Make the path for the specified **$file** or [folder](https://en.wikipedia.org/wiki/File_folder) on the [Amazon Web Services](http://aws.amazon.com) instance whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp). Confess to any failures.

       Parameter  Description
    1  $file      File or [folder](https://en.wikipedia.org/wiki/File_folder) name
    2  $ip        Optional [IP address](https://en.wikipedia.org/wiki/IP_address) address

**Example:**

      my $d = fpd(my $D = temporaryDirectory, qw(a));
      my $f = fpe($d, qw(bbb txt));
      ok !-d $d;
      [eval](http://perldoc.perl.org/functions/eval.html) q{checkFile($f)};
      my $r = $@;
      my $q = quotemeta($D);
      ok nws($r) =~ m(Can only find.+?: $q)s;
      makePath($f);
      ok -d $d;
      ok -d $D;
      rmdir $_ for $d, $D;
    
      my $e = temporaryFolder;                                                      # Same as temporyDirectory
      ok -d $e;
      clearFolder($e, 2);
    
      my $t = temporaryFile;
      ok  -f $t;
      unlink $t;
      ok !-f $t;
    
      if (0)
    
       {makePathRemote($e);                                                         # Make a path on the remote system  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       }
    

### overWriteFile($file, $string)

Write to a **$file**, after creating a path to the $file with [makePath](https://metacpan.org/pod/makePath) if necessary, a **$string** of [Unicode](https://en.wikipedia.org/wiki/Unicode) content encoded as [utf8](https://en.wikipedia.org/wiki/UTF-8). Return the name of the $file on success else [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) to any failures. If the [file](https://en.wikipedia.org/wiki/Computer_file) already exists it will be overwritten.

       Parameter  Description
    1  $file      File to write to or B<undef> for a temporary [file](https://en.wikipedia.org/wiki/Computer_file)     2  $string    Unicode [string](https://en.wikipedia.org/wiki/String_(computer_science)) to write

**Example:**

      my $f = writeFile(undef,  "aaa");
      is_deeply [readFile $f], ["aaa"];
    
      appendFile($f, "bbb");
      is_deeply [readFile $f], ["aaabbb"];
    
      my $F = writeTempFile(qw(aaa bbb));
      is_deeply [readFile $F], ["aaa
  ", "bbb
  "];
    
      [eval](http://perldoc.perl.org/functions/eval.html) {writeFile($f,  q(ccc))};
      ok $@ =~ m(File already exists:)i;
    
    
      overWriteFile($F,    q(ccc));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok   readFile($F) eq q(ccc);
    
      unlink $f, $F;
    

**owf** is a synonym for [overWriteFile](#overwritefile).

### writeFile($file, $string)

Write to a new **$file**, after creating a path to the $file with [makePath](https://metacpan.org/pod/makePath) if necessary, a **$string** of [Unicode](https://en.wikipedia.org/wiki/Unicode) content encoded as [utf8](https://en.wikipedia.org/wiki/UTF-8). Return the name of the $file written to on success else [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) if the [file](https://en.wikipedia.org/wiki/Computer_file) already exists or any other error occurs.

       Parameter  Description
    1  $file      New [file](https://en.wikipedia.org/wiki/Computer_file) to write to or B<undef> for a temporary [file](https://en.wikipedia.org/wiki/Computer_file)     2  $string    String to write

**Example:**

      my $f = writeFile(undef,  "aaa");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply [readFile $f], ["aaa"];
    
      appendFile($f, "bbb");
      is_deeply [readFile $f], ["aaabbb"];
    
      my $F = writeTempFile(qw(aaa bbb));
      is_deeply [readFile $F], ["aaa
  ", "bbb
  "];
    
    
      [eval](http://perldoc.perl.org/functions/eval.html) {writeFile($f,  q(ccc))};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $@ =~ m(File already exists:)i;
    
      overWriteFile($F,    q(ccc));
      ok   readFile($F) eq q(ccc);
    
      unlink $f, $F;
    

### writeTempFile(@strings)

Write an [array](https://en.wikipedia.org/wiki/Dynamic_array) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)) as lines to a temporary [file](https://en.wikipedia.org/wiki/Computer_file) and return the [file](https://en.wikipedia.org/wiki/Computer_file) name.

       Parameter  Description
    1  @strings   Array of lines

**Example:**

      my $f = writeFile(undef,  "aaa");
      is_deeply [readFile $f], ["aaa"];
    
      appendFile($f, "bbb");
      is_deeply [readFile $f], ["aaabbb"];
    
    
      my $F = writeTempFile(qw(aaa bbb));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply [readFile $F], ["aaa
  ", "bbb
  "];
    
      [eval](http://perldoc.perl.org/functions/eval.html) {writeFile($f,  q(ccc))};
      ok $@ =~ m(File already exists:)i;
    
      overWriteFile($F,    q(ccc));
      ok   readFile($F) eq q(ccc);
    
      unlink $f, $F;
    

### writeFileToRemote($file, $string, $ip)

Write to a new **$file**, after creating a path to the [file](https://en.wikipedia.org/wiki/Computer_file) with [makePath](https://metacpan.org/pod/makePath) if necessary, a **$string** of [Unicode](https://en.wikipedia.org/wiki/Unicode) content encoded as [utf8](https://en.wikipedia.org/wiki/UTF-8) then copy the $file to the remote [server](https://en.wikipedia.org/wiki/Server_(computing)) whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp). Return the name of the $file on success else [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) if the [file](https://en.wikipedia.org/wiki/Computer_file) already exists or any other error occurs.

       Parameter  Description
    1  $file      New [file](https://en.wikipedia.org/wiki/Computer_file) to write to or B<undef> for a temporary [file](https://en.wikipedia.org/wiki/Computer_file)     2  $string    String to write
    3  $ip        Optional [IP address](https://en.wikipedia.org/wiki/IP_address) address

**Example:**

      my $f = writeFileToRemote(undef, q(aaaa));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      unlink $f;
      ok readFileFromRemote($f) eq q(aaaa);
      unlink $f;
    

### overWriteBinaryFile($file, $string)

Write to **$file**, after creating a path to the [file](https://en.wikipedia.org/wiki/Computer_file) with [makePath](https://metacpan.org/pod/makePath) if necessary, the binary content in **$string**. If the $file already exists it is overwritten. Return the name of the $file on success else [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/). 
       Parameter  Description
    1  $file      File to write to or B<undef> for a temporary [file](https://en.wikipedia.org/wiki/Computer_file)     2  $string    L<Unicode|https://en.wikipedia.org/wiki/Unicode> [string](https://en.wikipedia.org/wiki/String_(computer_science)) to write

**Example:**

    if (1)                                                                            
     {vec(my $a = '', 0, 8) = 254;
      vec(my $b = '', 0, 8) = 255;
      ok dump($a) eq dump("FE");
      ok dump($b) eq dump("FF");
      ok length($a) == 1;
      ok length($b) == 1;
    
      my $s = $a.$a.$b.$b;
      ok length($s) == 4;
    
      my $f = [eval](http://perldoc.perl.org/functions/eval.html) {writeFile(undef, $s)};
      ok fileSize($f) == 8;
    
      [eval](http://perldoc.perl.org/functions/eval.html) {writeBinaryFile($f, $s)};
      ok $@ =~ m(Binary [file](https://en.wikipedia.org/wiki/Computer_file) already exists:)s;
    
    
      [eval](http://perldoc.perl.org/functions/eval.html) {overWriteBinaryFile($f, $s)};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok !$@;
      ok fileSize($f) == 4;
    
      ok $s eq [eval](http://perldoc.perl.org/functions/eval.html) {readBinaryFile($f)};
    
      copyBinaryFile($f, my $F = temporaryFile);
      ok $s eq readBinaryFile($F);
      unlink $f, $F;
     }
    

### writeBinaryFile($file, $string)

Write to a new **$file**, after creating a path to the [file](https://en.wikipedia.org/wiki/Computer_file) with [makePath](https://metacpan.org/pod/makePath) if necessary, the binary content in **$string**. Return the name of the $file on success else [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) if the [file](https://en.wikipedia.org/wiki/Computer_file) already exists or any other error occurs.

       Parameter  Description
    1  $file      New [file](https://en.wikipedia.org/wiki/Computer_file) to write to or B<undef> for a temporary [file](https://en.wikipedia.org/wiki/Computer_file)     2  $string    String to write

**Example:**

      my $f = writeBinaryFile(undef, 0xff x 8);                                        # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $s = readBinaryFile($f);                                                    
    
      ok $s eq 0xff x 8;                                                             
    
    if (1)                                                                            
     {vec(my $a = '', 0, 8) = 254;
      vec(my $b = '', 0, 8) = 255;
      ok dump($a) eq dump("FE");
      ok dump($b) eq dump("FF");
      ok length($a) == 1;
      ok length($b) == 1;
    
      my $s = $a.$a.$b.$b;
      ok length($s) == 4;
    
      my $f = [eval](http://perldoc.perl.org/functions/eval.html) {writeFile(undef, $s)};
      ok fileSize($f) == 8;
    
    
      [eval](http://perldoc.perl.org/functions/eval.html) {writeBinaryFile($f, $s)};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $@ =~ m(Binary [file](https://en.wikipedia.org/wiki/Computer_file) already exists:)s;
    
      [eval](http://perldoc.perl.org/functions/eval.html) {overWriteBinaryFile($f, $s)};
      ok !$@;
      ok fileSize($f) == 4;
    
      ok $s eq [eval](http://perldoc.perl.org/functions/eval.html) {readBinaryFile($f)};
    
      copyBinaryFile($f, my $F = temporaryFile);
      ok $s eq readBinaryFile($F);
      unlink $f, $F;
     }
    

### dumpFile($file, $structure)

Dump to a **$file** the referenced data **$structure**.

       Parameter   Description
    1  $file       File to write to or B<undef> for a temporary [file](https://en.wikipedia.org/wiki/Computer_file)     2  $structure  Address of data structure to write

**Example:**

      my $d = [qw(aaa bbb ccc), [{aaa=>'AAA', bbb=>'BBB'}]];
    
      my $f = dumpFile(undef, $d);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply evalFile($f), $d;
      is_deeply evalFile(my $F = dumpTempFile($d)), $d;
      unlink $f, $F;
    
      my $j = dumpFileAsJson(undef, $d);
      is_deeply evalFileAsJson($j), $d;
      is_deeply evalFileAsJson(my $J = dumpTempFileAsJson($d)), $d;
      unlink $j, $J;
    

### dumpTempFile($structure)

Dump a data structure to a temporary [file](https://en.wikipedia.org/wiki/Computer_file) and return the name of the [file](https://en.wikipedia.org/wiki/Computer_file) created.

       Parameter   Description
    1  $structure  Data structure to write

**Example:**

      my $d = [qw(aaa bbb ccc), [{aaa=>'AAA', bbb=>'BBB'}]];
      my $f = dumpFile(undef, $d);
      is_deeply evalFile($f), $d;
    
      is_deeply evalFile(my $F = dumpTempFile($d)), $d;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      unlink $f, $F;
    
      my $j = dumpFileAsJson(undef, $d);
      is_deeply evalFileAsJson($j), $d;
      is_deeply evalFileAsJson(my $J = dumpTempFileAsJson($d)), $d;
      unlink $j, $J;
    

### dumpFileAsJson($file, $structure)

Dump to a **$file** the referenced data **$structure** represented as [Json](https://en.wikipedia.org/wiki/JSON) [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
       Parameter   Description
    1  $file       File to write to or B<undef> for a temporary [file](https://en.wikipedia.org/wiki/Computer_file)     2  $structure  Address of data structure to write

**Example:**

      my $d = [qw(aaa bbb ccc), [{aaa=>'AAA', bbb=>'BBB'}]];
      my $f = dumpFile(undef, $d);
      is_deeply evalFile($f), $d;
      is_deeply evalFile(my $F = dumpTempFile($d)), $d;
      unlink $f, $F;
    
    
      my $j = dumpFileAsJson(undef, $d);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply evalFileAsJson($j), $d;
      is_deeply evalFileAsJson(my $J = dumpTempFileAsJson($d)), $d;
      unlink $j, $J;
    

### dumpTempFileAsJson($structure)

Dump a data structure represented as [Json](https://en.wikipedia.org/wiki/JSON) [string](https://en.wikipedia.org/wiki/String_(computer_science)) to a temporary [file](https://en.wikipedia.org/wiki/Computer_file) and return the name of the [file](https://en.wikipedia.org/wiki/Computer_file) created.

       Parameter   Description
    1  $structure  Data structure to write

**Example:**

      my $d = [qw(aaa bbb ccc), [{aaa=>'AAA', bbb=>'BBB'}]];
      my $f = dumpFile(undef, $d);
      is_deeply evalFile($f), $d;
      is_deeply evalFile(my $F = dumpTempFile($d)), $d;
      unlink $f, $F;
    
      my $j = dumpFileAsJson(undef, $d);
      is_deeply evalFileAsJson($j), $d;
    
      is_deeply evalFileAsJson(my $J = dumpTempFileAsJson($d)), $d;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      unlink $j, $J;
    

### storeFile($file, $structure)

Store into a **$file**, after creating a path to the [file](https://en.wikipedia.org/wiki/Computer_file) with [makePath](https://metacpan.org/pod/makePath) if necessary, a data **$structure** via [Storable](https://metacpan.org/pod/Storable).  This is much faster than [dumpFile](#dumpfile) but the stored results are not easily modified.

       Parameter   Description
    1  $file       File to write to or B<undef> for a temporary [file](https://en.wikipedia.org/wiki/Computer_file)     2  $structure  Address of data structure to write

**Example:**

      my $f = storeFile(undef, my $d = [qw(aaa bbb ccc)]);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $s = retrieveFile($f);
      is_deeply $s, $d;
      unlink $f;
    

### writeGZipFile($file, $string)

Write to a **$file**, after creating a path to the [file](https://en.wikipedia.org/wiki/Computer_file) with [makePath](https://metacpan.org/pod/makePath) if necessary, through [gzip](https://en.wikipedia.org/wiki/Gzip) a **$string** whose content is encoded as [utf8](https://en.wikipedia.org/wiki/UTF-8).

       Parameter  Description
    1  $file      File to write to
    2  $string    String to write

**Example:**

      my $s = '𝝰'x1e3;
    
      my $file = writeGZipFile(q(zzz.zip), $s);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok -e $file;
      my $S = readGZipFile($file);
      ok $s eq $S;
      ok length($s) == length($S);
      unlink $file;
    

### dumpGZipFile($file, $structure)

Write to a **$file** a data **$structure** through [gzip](https://en.wikipedia.org/wiki/Gzip). This technique produces files that are a lot more compact files than those produced by [Storable](https://metacpan.org/pod/Storable), but the execution time is much longer. See also: [evalGZipFile](#evalgzipfile).

       Parameter   Description
    1  $file       File to write
    2  $structure  Reference to data

**Example:**

      my $d = [1, 2, 3=>{a=>4, b=>5}];
    
      my $file = dumpGZipFile(q(zzz.zip), $d);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok -e $file;
      my $D = evalGZipFile($file);
      is_deeply $d, $D;
      unlink $file;
    

### writeFiles($hash, $old, $new)

Write the values of a **$hash** reference into files identified by the key of each value using [overWriteFile](#overwritefile) optionally swapping the prefix of each [file](https://en.wikipedia.org/wiki/Computer_file) from **$old** to **$new**.

       Parameter  Description
    1  $hash      Hash of key value pairs representing files and data
    2  $old       Optional old prefix
    3  $new       New prefix

**Example:**

      my $d = temporaryFolder;
      my $a = fpd($d, q(aaa));
      my $b = fpd($d, q(bbb));
      my $c = fpd($d, q(ccc));
      my ($a1, $a2) = map {fpe($a, $_, q(txt))} 1..2;
      my ($b1, $b2) = map {fpe($b, $_, q(txt))} 1..2;
      my $files = {$a1 => "1111", $a2 => "2222"};
    
    
      writeFiles($files);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $ra = readFiles($a);
      is_deeply $files, $ra;
      copyFolder($a, $b);
      my $rb = readFiles($b);
      is_deeply [sort values %$ra], [sort values %$rb];
    
      unlink $a2;
      mergeFolder($a, $b);
      ok -e $b1; ok  -e $b2;
    
      copyFolder($a, $b);
      ok -e $b1; ok !-e $b2;
    
      copyFile($a1, $a2);
      ok readFile($a1) eq readFile($a2);
    
    
      writeFiles($files);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok !moveFileNoClobber  ($a1, $a2);
      ok  moveFileWithClobber($a1, $a2);
      ok !-e $a1;
      ok readFile($a2) eq q(1111);
      ok  moveFileNoClobber  ($a2, $a1);
      ok !-e $a2;
      ok readFile($a1) eq q(1111);
    
      clearFolder(q(aaa), 11);
      clearFolder(q(bbb), 11);
    

### readFiles(@folders)

Read all the files in the specified [list](https://en.wikipedia.org/wiki/Linked_list) of folders into a [hash](https://en.wikipedia.org/wiki/Hash_table). 
       Parameter  Description
    1  @folders   Folders to read

**Example:**

      my $d = temporaryFolder;
      my $a = fpd($d, q(aaa));
      my $b = fpd($d, q(bbb));
      my $c = fpd($d, q(ccc));
      my ($a1, $a2) = map {fpe($a, $_, q(txt))} 1..2;
      my ($b1, $b2) = map {fpe($b, $_, q(txt))} 1..2;
      my $files = {$a1 => "1111", $a2 => "2222"};
    
      writeFiles($files);
    
      my $ra = readFiles($a);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply $files, $ra;
      copyFolder($a, $b);
    
      my $rb = readFiles($b);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply [sort values %$ra], [sort values %$rb];
    
      unlink $a2;
      mergeFolder($a, $b);
      ok -e $b1; ok  -e $b2;
    
      copyFolder($a, $b);
      ok -e $b1; ok !-e $b2;
    
      copyFile($a1, $a2);
      ok readFile($a1) eq readFile($a2);
    
      writeFiles($files);
      ok !moveFileNoClobber  ($a1, $a2);
      ok  moveFileWithClobber($a1, $a2);
      ok !-e $a1;
      ok readFile($a2) eq q(1111);
      ok  moveFileNoClobber  ($a2, $a1);
      ok !-e $a2;
      ok readFile($a1) eq q(1111);
    
      clearFolder(q(aaa), 11);
      clearFolder(q(bbb), 11);
    

### includeFiles($expand)

Read the given [file](https://en.wikipedia.org/wiki/Computer_file) and expand all lines that start "includeThisFile " with the [file](https://en.wikipedia.org/wiki/Computer_file) named by the rest of the line and keep doing this until all the included files have been expanded or a repetition is detected.  Returns the expanded [file](https://en.wikipedia.org/wiki/Computer_file) or confesses if one of the included files cannot be located.

       Parameter  Description
    1  $expand    File to expand

**Example:**

    if (1)                                                                          
     {my $d = temporaryFolder;
      my $a = "$d/a.txt";
      my $b = "$d/b.txt";
      my %d = ($a => <<END,
    aaa
    includeThisFile $d/b.txt
    ccc
    END
               $b => <<END,
    bbb
    END
      );
    
      writeFiles(\%d);
    
      is_deeply [includeFiles($a)], ["aaa
  ", "bbb
  ", "ccc
  "];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      unlink $a, $b;
     }
    

### appendFile($file, $string)

Append to **$file** a **$string** of [Unicode](https://en.wikipedia.org/wiki/Unicode) content encoded with [utf8](https://en.wikipedia.org/wiki/UTF-8), creating the $file first if necessary. Return the name of the $file on success else [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/). The $file being appended to is locked before the write with ["flock" in perlfunc](https://metacpan.org/pod/perlfunc#flock) to allow  multiple [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) to append linearly to the same [file](https://en.wikipedia.org/wiki/Computer_file). 
       Parameter  Description
    1  $file      File to append to
    2  $string    String to append

**Example:**

      my $f = writeFile(undef,  "aaa");
      is_deeply [readFile $f], ["aaa"];
    
    
      appendFile($f, "bbb");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply [readFile $f], ["aaabbb"];
    
      my $F = writeTempFile(qw(aaa bbb));
      is_deeply [readFile $F], ["aaa
  ", "bbb
  "];
    
      [eval](http://perldoc.perl.org/functions/eval.html) {writeFile($f,  q(ccc))};
      ok $@ =~ m(File already exists:)i;
    
      overWriteFile($F,    q(ccc));
      ok   readFile($F) eq q(ccc);
    
      unlink $f, $F;
    

### createEmptyFile($file)

Create an empty [file](https://en.wikipedia.org/wiki/Computer_file) unless the [file](https://en.wikipedia.org/wiki/Computer_file) already exists and return the name of the [file](https://en.wikipedia.org/wiki/Computer_file) else [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) if the [file](https://en.wikipedia.org/wiki/Computer_file) cannot be created.

       Parameter  Description
    1  $file      File to create or B<undef> for a temporary [file](https://en.wikipedia.org/wiki/Computer_file) 
**Example:**

      my $D = temporaryFolder;
      ok  -d $D;
    
      my $d = fpd($D, q(ddd));
      ok !-d $d;
    
    
      my @f = map {createEmptyFile(fpe($d, $_, qw(txt)))} qw(a b c);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply [sort map {fne $_} findFiles($d, qr(txt\Z))], [qw(a.txt b.txt c.txt)];
    
      my @D = findDirs($D);
      my @e = ($D, $d);
      my @E = [sort](https://en.wikipedia.org/wiki/Sorting) @e;
      is_deeply [@D], [@E];
    
      is_deeply [sort map {fne $_} searchDirectoryTreesForMatchingFiles($d)],
                ["a.txt", "b.txt", "c.txt"];
    
      is_deeply [sort map {fne $_} fileList(prefferedFileName "$d/*.txt")],
                ["a.txt", "b.txt", "c.txt"];
    
      ok -e $_ for @f;
    
      is_deeply scalar(searchDirectoryTreeForSubFolders $D), 2;
    
      my @g = fileList(qq($D/*/*.txt));
      ok @g == 3;
    
      clearFolder($D, 5);
      ok onWindows ? 1 : !-e $_ for @f;
      ok onWindows ? 1 : !-d $D;
    

### setPermissionsForFile($file, $permissions)

Apply [chmod](https://linux.die.net/man/1/chmod) to a **$file** to set its **$permissions**.

       Parameter     Description
    1  $file         File
    2  $permissions  Permissions settings per [chmod](https://linux.die.net/man/1/chmod) 
**Example:**

    if (1)                                                                          
     {my $f = temporaryFile();
    
      setPermissionsForFile($f, q(ugo=r));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $a = qx(ls -la $f);
      ok $a =~ m(-r--r--r--)s;
    
      setPermissionsForFile($f, q(u=rwx));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $b = qx(ls -la $f);
      ok $b =~ m(-rwxr--r--)s;
     }
    

### numberOfLinesInFile($file)

Return the number of lines in a [file](https://en.wikipedia.org/wiki/Computer_file). 
       Parameter  Description
    1  $file      File

**Example:**

      my $f = writeFile(undef, "a
  b
  ");                                           
    
    
      ok numberOfLinesInFile($f) == 2;                                                # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### overWriteHtmlFile($file, $data)

Write an [HTML](https://en.wikipedia.org/wiki/HTML) [file](https://en.wikipedia.org/wiki/Computer_file) to /var/www/html and make it readable.

       Parameter  Description
    1  $file      Target [file](https://en.wikipedia.org/wiki/Computer_file) relative to /var/www/html
    2  $data      Data to write

**Example:**

      overWriteHtmlFile   (q(index.html), q(<html><h1>Hello</h1></html>));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      overWritePerlCgiFile(q(gen.pl),     q(...));
    

### overWritePerlCgiFile($file, $data)

Write a [Perl](http://www.perl.org/) [file](https://en.wikipedia.org/wiki/Computer_file) to /usr/lib/cgi-bin and make it executable after checking it for syntax errors.

       Parameter  Description
    1  $file      Target [file](https://en.wikipedia.org/wiki/Computer_file) relative to /var/www/html
    2  $data      Data to write

**Example:**

      overWriteHtmlFile   (q(index.html), q(<html><h1>Hello</h1></html>));
    
      overWritePerlCgiFile(q(gen.pl),     q(...));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## Copy

Copy files and folders. The **\\Acopy.\*Md5Normalized.\*\\Z** methods can be used to ensure that files have collision proof names that collapse duplicate content even when copied to another [folder](https://en.wikipedia.org/wiki/File_folder). 
### copyFile($source, $target)

Copy the **$source** [file](https://en.wikipedia.org/wiki/Computer_file) encoded in [utf8](https://en.wikipedia.org/wiki/UTF-8) to the specified **$target** [file](https://en.wikipedia.org/wiki/Computer_file) in and return $target.

       Parameter  Description
    1  $source    Source [file](https://en.wikipedia.org/wiki/Computer_file)     2  $target    Target [file](https://en.wikipedia.org/wiki/Computer_file) 
**Example:**

      my $d = temporaryFolder;
      my $a = fpd($d, q(aaa));
      my $b = fpd($d, q(bbb));
      my $c = fpd($d, q(ccc));
      my ($a1, $a2) = map {fpe($a, $_, q(txt))} 1..2;
      my ($b1, $b2) = map {fpe($b, $_, q(txt))} 1..2;
      my $files = {$a1 => "1111", $a2 => "2222"};
    
      writeFiles($files);
      my $ra = readFiles($a);
      is_deeply $files, $ra;
      copyFolder($a, $b);
      my $rb = readFiles($b);
      is_deeply [sort values %$ra], [sort values %$rb];
    
      unlink $a2;
      mergeFolder($a, $b);
      ok -e $b1; ok  -e $b2;
    
      copyFolder($a, $b);
      ok -e $b1; ok !-e $b2;
    
    
      copyFile($a1, $a2);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok readFile($a1) eq readFile($a2);
    
      writeFiles($files);
      ok !moveFileNoClobber  ($a1, $a2);
      ok  moveFileWithClobber($a1, $a2);
      ok !-e $a1;
      ok readFile($a2) eq q(1111);
      ok  moveFileNoClobber  ($a2, $a1);
      ok !-e $a2;
      ok readFile($a1) eq q(1111);
    
      clearFolder(q(aaa), 11);
      clearFolder(q(bbb), 11);
    

### moveFileNoClobber($source, $target)

Rename the **$source** [file](https://en.wikipedia.org/wiki/Computer_file), which must exist, to the **$target** [file](https://en.wikipedia.org/wiki/Computer_file) but only if the $target [file](https://en.wikipedia.org/wiki/Computer_file) does not exist already.  Returns 1 if the $source [file](https://en.wikipedia.org/wiki/Computer_file) was successfully renamed to the $target [file](https://en.wikipedia.org/wiki/Computer_file) else 0.

       Parameter  Description
    1  $source    Source [file](https://en.wikipedia.org/wiki/Computer_file)     2  $target    Target [file](https://en.wikipedia.org/wiki/Computer_file) 
**Example:**

      my $d = temporaryFolder;
      my $a = fpd($d, q(aaa));
      my $b = fpd($d, q(bbb));
      my $c = fpd($d, q(ccc));
      my ($a1, $a2) = map {fpe($a, $_, q(txt))} 1..2;
      my ($b1, $b2) = map {fpe($b, $_, q(txt))} 1..2;
      my $files = {$a1 => "1111", $a2 => "2222"};
    
      writeFiles($files);
      my $ra = readFiles($a);
      is_deeply $files, $ra;
      copyFolder($a, $b);
      my $rb = readFiles($b);
      is_deeply [sort values %$ra], [sort values %$rb];
    
      unlink $a2;
      mergeFolder($a, $b);
      ok -e $b1; ok  -e $b2;
    
      copyFolder($a, $b);
      ok -e $b1; ok !-e $b2;
    
      copyFile($a1, $a2);
      ok readFile($a1) eq readFile($a2);
    
      writeFiles($files);
    
      ok !moveFileNoClobber  ($a1, $a2);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok  moveFileWithClobber($a1, $a2);
      ok !-e $a1;
      ok readFile($a2) eq q(1111);
    
      ok  moveFileNoClobber  ($a2, $a1);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok !-e $a2;
      ok readFile($a1) eq q(1111);
    
      clearFolder(q(aaa), 11);
      clearFolder(q(bbb), 11);
    

### moveFileWithClobber($source, $target)

Rename the **$source** [file](https://en.wikipedia.org/wiki/Computer_file), which must exist, to the **$target** [file](https://en.wikipedia.org/wiki/Computer_file) but only if the $target [file](https://en.wikipedia.org/wiki/Computer_file) does not exist already.  Returns 1 if the $source [file](https://en.wikipedia.org/wiki/Computer_file) was successfully renamed to the $target [file](https://en.wikipedia.org/wiki/Computer_file) else 0.

       Parameter  Description
    1  $source    Source [file](https://en.wikipedia.org/wiki/Computer_file)     2  $target    Target [file](https://en.wikipedia.org/wiki/Computer_file) 
**Example:**

      my $d = temporaryFolder;
      my $a = fpd($d, q(aaa));
      my $b = fpd($d, q(bbb));
      my $c = fpd($d, q(ccc));
      my ($a1, $a2) = map {fpe($a, $_, q(txt))} 1..2;
      my ($b1, $b2) = map {fpe($b, $_, q(txt))} 1..2;
      my $files = {$a1 => "1111", $a2 => "2222"};
    
      writeFiles($files);
      my $ra = readFiles($a);
      is_deeply $files, $ra;
      copyFolder($a, $b);
      my $rb = readFiles($b);
      is_deeply [sort values %$ra], [sort values %$rb];
    
      unlink $a2;
      mergeFolder($a, $b);
      ok -e $b1; ok  -e $b2;
    
      copyFolder($a, $b);
      ok -e $b1; ok !-e $b2;
    
      copyFile($a1, $a2);
      ok readFile($a1) eq readFile($a2);
    
      writeFiles($files);
      ok !moveFileNoClobber  ($a1, $a2);
    
      ok  moveFileWithClobber($a1, $a2);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok !-e $a1;
      ok readFile($a2) eq q(1111);
      ok  moveFileNoClobber  ($a2, $a1);
      ok !-e $a2;
      ok readFile($a1) eq q(1111);
    
      clearFolder(q(aaa), 11);
      clearFolder(q(bbb), 11);
    

### copyFileToFolder($source, $targetFolder)

Copy the [file](https://en.wikipedia.org/wiki/Computer_file) named in **$source** to the specified **$targetFolder/** or if $targetFolder/ is in fact a [file](https://en.wikipedia.org/wiki/Computer_file) into the [folder](https://en.wikipedia.org/wiki/File_folder) containing this [file](https://en.wikipedia.org/wiki/Computer_file) and return the target [file](https://en.wikipedia.org/wiki/Computer_file) name. Confesses instead of copying if the target already exists.

       Parameter      Description
    1  $source        Source [file](https://en.wikipedia.org/wiki/Computer_file)     2  $targetFolder  Target [folder](https://en.wikipedia.org/wiki/File_folder) 
**Example:**

      my $sd = temporaryFolder;
      my $td = temporaryFolder;
      my $sf = writeFile fpe($sd, qw(test data)), q(aaaa);
    
      my $tf = copyFileToFolder($sf, $td);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok readFile($tf) eq q(aaaa);
      ok fp ($tf) eq $td;
      ok fne($tf) eq q(test.data);
    

### nameFromString($string, %options)

Create a readable name from an arbitrary [string](https://en.wikipedia.org/wiki/String_(computer_science)) of text.

       Parameter  Description
    1  $string    String
    2  %options   Options

**Example:**

    ok q(help) eq nameFromString(q(!@#$%^help___<>?><?>));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    ok q(bm_The_skyscraper_analogy) eq nameFromString(<<END);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    <bookmap id="b1">
    <title>The skyscraper analogy</title>
    </bookmap>
    END
    
    ok q(bm_The_skyscraper_analogy_An_exciting_tale_of_two_skyscrapers_that_meet_in_downtown_Houston)
    
       eq nameFromString(<<END);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    <bookmap id="b1">
    <title>The skyscraper analogy</title>
    An exciting tale of two skyscrapers that meet in downtown Houston
    <concept><html>
    </bookmap>
    END
    
    ok q(bm_the_skyscraper_analogy) eq nameFromStringRestrictedToTitle(<<END);
    <bookmap id="b1">
    <title>The skyscraper analogy</title>
    An exciting tale of two skyscrapers that meet in downtown Houston
    <concept><html>
    </bookmap>
    END
    

### nameFromStringRestrictedToTitle($string, %options)

Create a readable name from a [string](https://en.wikipedia.org/wiki/String_(computer_science)) of text that might contain a title tag - fall back to [nameFromString](#namefromstring) if that is not possible.

       Parameter  Description
    1  $string    String
    2  %options   Options

**Example:**

    ok q(help) eq nameFromString(q(!@#$%^help___<>?><?>));
    ok q(bm_The_skyscraper_analogy) eq nameFromString(<<END);
    <bookmap id="b1">
    <title>The skyscraper analogy</title>
    </bookmap>
    END
    
    ok q(bm_The_skyscraper_analogy_An_exciting_tale_of_two_skyscrapers_that_meet_in_downtown_Houston)
       eq nameFromString(<<END);
    <bookmap id="b1">
    <title>The skyscraper analogy</title>
    An exciting tale of two skyscrapers that meet in downtown Houston
    <concept><html>
    </bookmap>
    END
    
    
    ok q(bm_the_skyscraper_analogy) eq nameFromStringRestrictedToTitle(<<END);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    <bookmap id="b1">
    <title>The skyscraper analogy</title>
    An exciting tale of two skyscrapers that meet in downtown Houston
    <concept><html>
    </bookmap>
    END
    

### uniqueNameFromFile($source)

Create a unique name from a [file](https://en.wikipedia.org/wiki/Computer_file) name and the [MD5](https://en.wikipedia.org/wiki/MD5) sum of its content.

       Parameter  Description
    1  $source    Source [file](https://en.wikipedia.org/wiki/Computer_file) 
**Example:**

      my $f = owf(q(test.txt), join "", 1..100);
    
      ok uniqueNameFromFile($f) eq q(test_ef69caaaeea9c17120821a9eb6c7f1de.txt);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      unlink $f;
    

### nameFromFolder($file)

Create a name from the last [folder](https://en.wikipedia.org/wiki/File_folder) in the path of a [file](https://en.wikipedia.org/wiki/Computer_file) name.  Return [undef](https://perldoc.perl.org/functions/undef.html) if the [file](https://en.wikipedia.org/wiki/Computer_file) does not have a path.

       Parameter  Description
    1  $file      File name

**Example:**

      ok nameFromFolder(fpe(qw( a b c d e))) eq q(c);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### copyBinaryFile($source, $target)

Copy the binary [file](https://en.wikipedia.org/wiki/Computer_file) **$source** to a [file](https://en.wikipedia.org/wiki/Computer_file) named <%target> and return the target [file](https://en.wikipedia.org/wiki/Computer_file) name,.

       Parameter  Description
    1  $source    Source [file](https://en.wikipedia.org/wiki/Computer_file)     2  $target    Target [file](https://en.wikipedia.org/wiki/Computer_file) 
**Example:**

    if (1)                                                                            
     {vec(my $a = '', 0, 8) = 254;
      vec(my $b = '', 0, 8) = 255;
      ok dump($a) eq dump("FE");
      ok dump($b) eq dump("FF");
      ok length($a) == 1;
      ok length($b) == 1;
    
      my $s = $a.$a.$b.$b;
      ok length($s) == 4;
    
      my $f = [eval](http://perldoc.perl.org/functions/eval.html) {writeFile(undef, $s)};
      ok fileSize($f) == 8;
    
      [eval](http://perldoc.perl.org/functions/eval.html) {writeBinaryFile($f, $s)};
      ok $@ =~ m(Binary [file](https://en.wikipedia.org/wiki/Computer_file) already exists:)s;
    
      [eval](http://perldoc.perl.org/functions/eval.html) {overWriteBinaryFile($f, $s)};
      ok !$@;
      ok fileSize($f) == 4;
    
      ok $s eq [eval](http://perldoc.perl.org/functions/eval.html) {readBinaryFile($f)};
    
    
      copyBinaryFile($f, my $F = temporaryFile);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $s eq readBinaryFile($F);
      unlink $f, $F;
     }
    

### copyFileToRemote($file, $ip)

Copy the specified local **$file** to the [server](https://en.wikipedia.org/wiki/Server_(computing)) whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp).

       Parameter  Description
    1  $file      Source [file](https://en.wikipedia.org/wiki/Computer_file)     2  $ip        Optional [IP address](https://en.wikipedia.org/wiki/IP_address) address

**Example:**

    if (0)                                                                             
    
     {copyFileToRemote     (q(/home/phil/perl/cpan/aaa.txt));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      copyFileFromRemote   (q(/home/phil/perl/cpan/aaa.txt));
      copyFolderToRemote   (q(/home/phil/perl/cpan/));
      mergeFolderFromRemote(q(/home/phil/perl/cpan/));
     }
    

### copyFileFromRemote($file, $ip)

Copy the specified **$file** from the [server](https://en.wikipedia.org/wiki/Server_(computing)) whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp).

       Parameter  Description
    1  $file      Source [file](https://en.wikipedia.org/wiki/Computer_file)     2  $ip        Optional [IP address](https://en.wikipedia.org/wiki/IP_address) address

**Example:**

    if (0)                                                                             
     {copyFileToRemote     (q(/home/phil/perl/cpan/aaa.txt));
    
      copyFileFromRemote   (q(/home/phil/perl/cpan/aaa.txt));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      copyFolderToRemote   (q(/home/phil/perl/cpan/));
      mergeFolderFromRemote(q(/home/phil/perl/cpan/));
     }
    

### copyFolder($source, $target)

Copy the **$source** [folder](https://en.wikipedia.org/wiki/File_folder) to the **$target** [folder](https://en.wikipedia.org/wiki/File_folder) after clearing the $target [folder](https://en.wikipedia.org/wiki/File_folder). 
       Parameter  Description
    1  $source    Source [file](https://en.wikipedia.org/wiki/Computer_file)     2  $target    Target [file](https://en.wikipedia.org/wiki/Computer_file) 
**Example:**

      my $d = temporaryFolder;
      my $a = fpd($d, q(aaa));
      my $b = fpd($d, q(bbb));
      my $c = fpd($d, q(ccc));
      my ($a1, $a2) = map {fpe($a, $_, q(txt))} 1..2;
      my ($b1, $b2) = map {fpe($b, $_, q(txt))} 1..2;
      my $files = {$a1 => "1111", $a2 => "2222"};
    
      writeFiles($files);
      my $ra = readFiles($a);
      is_deeply $files, $ra;
    
      copyFolder($a, $b);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $rb = readFiles($b);
      is_deeply [sort values %$ra], [sort values %$rb];
    
      unlink $a2;
      mergeFolder($a, $b);
      ok -e $b1; ok  -e $b2;
    
    
      copyFolder($a, $b);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok -e $b1; ok !-e $b2;
    
      copyFile($a1, $a2);
      ok readFile($a1) eq readFile($a2);
    
      writeFiles($files);
      ok !moveFileNoClobber  ($a1, $a2);
      ok  moveFileWithClobber($a1, $a2);
      ok !-e $a1;
      ok readFile($a2) eq q(1111);
      ok  moveFileNoClobber  ($a2, $a1);
      ok !-e $a2;
      ok readFile($a1) eq q(1111);
    
      clearFolder(q(aaa), 11);
      clearFolder(q(bbb), 11);
    

### mergeFolder($source, $target)

Copy the **$source** [folder](https://en.wikipedia.org/wiki/File_folder) into the **$target** [folder](https://en.wikipedia.org/wiki/File_folder) retaining any existing files not replaced by copied files.

       Parameter  Description
    1  $source    Source [file](https://en.wikipedia.org/wiki/Computer_file)     2  $target    Target [file](https://en.wikipedia.org/wiki/Computer_file) 
**Example:**

      my $d = temporaryFolder;
      my $a = fpd($d, q(aaa));
      my $b = fpd($d, q(bbb));
      my $c = fpd($d, q(ccc));
      my ($a1, $a2) = map {fpe($a, $_, q(txt))} 1..2;
      my ($b1, $b2) = map {fpe($b, $_, q(txt))} 1..2;
      my $files = {$a1 => "1111", $a2 => "2222"};
    
      writeFiles($files);
      my $ra = readFiles($a);
      is_deeply $files, $ra;
      copyFolder($a, $b);
      my $rb = readFiles($b);
      is_deeply [sort values %$ra], [sort values %$rb];
    
      unlink $a2;
    
      mergeFolder($a, $b);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok -e $b1; ok  -e $b2;
    
      copyFolder($a, $b);
      ok -e $b1; ok !-e $b2;
    
      copyFile($a1, $a2);
      ok readFile($a1) eq readFile($a2);
    
      writeFiles($files);
      ok !moveFileNoClobber  ($a1, $a2);
      ok  moveFileWithClobber($a1, $a2);
      ok !-e $a1;
      ok readFile($a2) eq q(1111);
      ok  moveFileNoClobber  ($a2, $a1);
      ok !-e $a2;
      ok readFile($a1) eq q(1111);
    
      clearFolder(q(aaa), 11);
      clearFolder(q(bbb), 11);
    

### copyFolderToRemote($Source, $ip)

Copy the specified local **$Source** [folder](https://en.wikipedia.org/wiki/File_folder) to the corresponding remote [folder](https://en.wikipedia.org/wiki/File_folder) on the [server](https://en.wikipedia.org/wiki/Server_(computing)) whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp). The default [userid](https://en.wikipedia.org/wiki/User_identifier) supplied by `.ssh/config` will be used on the remote [server](https://en.wikipedia.org/wiki/Server_(computing)). 
       Parameter  Description
    1  $Source    Source [file](https://en.wikipedia.org/wiki/Computer_file)     2  $ip        Optional [IP address](https://en.wikipedia.org/wiki/IP_address) address of [server](https://en.wikipedia.org/wiki/Server_(computing)) 
**Example:**

    if (0)                                                                             
     {copyFileToRemote     (q(/home/phil/perl/cpan/aaa.txt));
      copyFileFromRemote   (q(/home/phil/perl/cpan/aaa.txt));
    
      copyFolderToRemote   (q(/home/phil/perl/cpan/));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      mergeFolderFromRemote(q(/home/phil/perl/cpan/));
     }
    

### mergeFolderFromRemote($Source, $ip)

Merge the specified **$Source** [folder](https://en.wikipedia.org/wiki/File_folder) from the corresponding remote [folder](https://en.wikipedia.org/wiki/File_folder) on the [server](https://en.wikipedia.org/wiki/Server_(computing)) whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp). The default [userid](https://en.wikipedia.org/wiki/User_identifier) supplied by `.ssh/config` will be used on the remote [server](https://en.wikipedia.org/wiki/Server_(computing)). 
       Parameter  Description
    1  $Source    Source [file](https://en.wikipedia.org/wiki/Computer_file)     2  $ip        Optional [IP address](https://en.wikipedia.org/wiki/IP_address) address of [server](https://en.wikipedia.org/wiki/Server_(computing)) 
**Example:**

    if (0)                                                                             
     {copyFileToRemote     (q(/home/phil/perl/cpan/aaa.txt));
      copyFileFromRemote   (q(/home/phil/perl/cpan/aaa.txt));
      copyFolderToRemote   (q(/home/phil/perl/cpan/));
    
      mergeFolderFromRemote(q(/home/phil/perl/cpan/));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

# Testing

Methods to assist with testing

## removeFilePathsFromStructure($structure)

Remove all [file](https://en.wikipedia.org/wiki/Computer_file) paths from a specified **$structure** to make said $structure testable with ["is\_deeply" in Test::More](https://metacpan.org/pod/Test%3A%3AMore#is_deeply).

       Parameter   Description
    1  $structure  Data structure reference

**Example:**

    if (1)                                                                           
     {my $d = {"/home/aaa/bbb.txt"=>1, "ccc/ddd.txt"=>2, "eee.txt"=>3};
    
      my $D = removeFilePathsFromStructure($d);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    
      is_deeply removeFilePathsFromStructure($d),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {"bbb.txt"=>1, "ddd.txt"=>2, "eee.txt"=>3};
    
      ok writeStructureTest($d, q($d)) eq <<'END';
    
      is_deeply removeFilePathsFromStructure($d),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       { "bbb.txt" => 1, "ddd.txt" => 2, "eee.txt" => 3 };
    END
     }
    

## writeStructureTest($structure, $expr)

Write a [test](https://en.wikipedia.org/wiki/Software_testing) for a data **$structure** with [file](https://en.wikipedia.org/wiki/Computer_file) names in it.

       Parameter   Description
    1  $structure  Data structure reference
    2  $expr       Expression

**Example:**

    if (1)                                                                           
     {my $d = {"/home/aaa/bbb.txt"=>1, "ccc/ddd.txt"=>2, "eee.txt"=>3};
      my $D = removeFilePathsFromStructure($d);
    
      is_deeply removeFilePathsFromStructure($d),
       {"bbb.txt"=>1, "ddd.txt"=>2, "eee.txt"=>3};
    
    
      ok writeStructureTest($d, q($d)) eq <<'END';  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply removeFilePathsFromStructure($d),
       { "bbb.txt" => 1, "ddd.txt" => 2, "eee.txt" => 3 };
    END
     }
    

## subNameTraceBack()

Find the names of the calling subroutines and return them as a blank separated [string](https://en.wikipedia.org/wiki/String_(computer_science)) of names.

**Example:**

      [sub](https://perldoc.perl.org/perlsub.html) aaa
       {&bbb;
       }
    
      [sub](https://perldoc.perl.org/perlsub.html) bbb
       {&ccc;
       }
    
      [sub](https://perldoc.perl.org/perlsub.html) ccc
    
       {subNameTraceBack;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       }
    
      ok aaa =~ s(Data::Table::Text::) ()gsr =~ m(\Accc bbb aaa);
    

# Images

Image operations.

## imageSize($image)

Return (width, height) of an **$image**.

       Parameter  Description
    1  $image     File containing image

**Example:**

      my ($width, $height) = imageSize(fpe(qw(a image jpg)));                         # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## convertDocxToFodt($inputFile, $outputFile)

Convert a _docx_ **$inputFile** [file](https://en.wikipedia.org/wiki/Computer_file) to a _fodt_ **$outputFile** using **unoconv** which must not be running elsewhere at the time.  [Unoconv](#https-github-com-dagwieers-unoconv) can be installed via:

    sudo apt [install](https://en.wikipedia.org/wiki/Installation_(computer_programs)) sharutils [unoconv](https://github.com/unoconv/unoconv) 
Parameters:.

       Parameter    Description
    1  $inputFile   Input [file](https://en.wikipedia.org/wiki/Computer_file)     2  $outputFile  Output [file](https://en.wikipedia.org/wiki/Computer_file) 
**Example:**

      convertDocxToFodt(fpe(qw(a docx)), fpe(qw(a fodt)));                            # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## cutOutImagesInFodtFile($inputFile, $outputFolder, $imagePrefix)

Cut out the images embedded in a **fodt** [file](https://en.wikipedia.org/wiki/Computer_file), perhaps produced via [convertDocxToFodt](#convertdocxtofodt), placing them in the specified [folder](https://en.wikipedia.org/wiki/File_folder) and replacing them in the source [file](https://en.wikipedia.org/wiki/Computer_file) with:

    <image href="$imageFile" outputclass="imageType">.

This conversion requires that you have both [Imagemagick](https://www.imagemagick.org/script/index.php) and [unoconv](#https-github-com-dagwieers-unoconv) installed on your system:

    sudo apt [install](https://en.wikipedia.org/wiki/Installation_(computer_programs)) sharutils  [Imagemagick](https://www.imagemagick.org/script/index.php) [unoconv](https://github.com/unoconv/unoconv) 
Parameters:.

       Parameter      Description
    1  $inputFile     Input [file](https://en.wikipedia.org/wiki/Computer_file)     2  $outputFolder  Output [folder](https://en.wikipedia.org/wiki/File_folder) for images
    3  $imagePrefix   A prefix to be added to image [file](https://en.wikipedia.org/wiki/Computer_file) names

**Example:**

      cutOutImagesInFodtFile(fpe(qw(source fodt)), fpd(qw(images)), q(image));        # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

# Encoding and Decoding

Encode and decode using [Json](https://en.wikipedia.org/wiki/JSON) and Mime.

## unbless($d)

Remove the effects of bless from a [Perl](http://www.perl.org/) data **$structure** enabling it to be converted to [Json](https://en.wikipedia.org/wiki/JSON) or compared with [Test::More::is\_deeply](https://metacpan.org/pod/Test%3A%3AMore%3A%3Ais_deeply).

       Parameter  Description
    1  $d         Unbless a L<Perl|http://www.perl.org/> data structure.

**Example:**

    if (1)                                                                          
     {my $a = {};
      ok ref($a)      eq  q(HASH);
      my $b =   bless $a, q(aaaa);
      ok ref($a)      eq  q(aaaa);
    
      my $c = unbless $b;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok ref($c)      eq  q(HASH);
     }
    

## encodeJson($structure)

Convert a [Perl](http://www.perl.org/) data **$structure** to a [Json](https://en.wikipedia.org/wiki/JSON) [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
       Parameter   Description
    1  $structure  Data to encode

**Example:**

      my $A = encodeJson(my $a = {a=>1,b=>2, c=>[1..2]});  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $b = decodeJson($A);
      is_deeply $a, $b;
    

## decodeJson($string)

Convert a [Json](https://en.wikipedia.org/wiki/JSON) **$string** to a [Perl](http://www.perl.org/) data structure.

       Parameter  Description
    1  $string    Data to decode

**Example:**

      my $A = encodeJson(my $a = {a=>1,b=>2, c=>[1..2]});
    
      my $b = decodeJson($A);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply $a, $b;
    

## encodeBase64($string)

Encode an [Ascii](https://en.wikipedia.org/wiki/ASCII) **$string** in base 64.

       Parameter  Description
    1  $string    String to encode

**Example:**

      my $A = encodeBase64(my $a = "Hello World" x 10);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $b = decodeBase64($A);
      ok $a eq $b;
    

## decodeBase64($string)

Decode an [Ascii](https://en.wikipedia.org/wiki/ASCII) **$string** in base 64.

       Parameter  Description
    1  $string    String to decode

**Example:**

      my $A = encodeBase64(my $a = "Hello World" x 10);
    
      my $b = decodeBase64($A);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $a eq $b;
    

## convertUnicodeToXml($string)

Convert a **$string** with [Unicode](https://en.wikipedia.org/wiki/Unicode) [code](https://en.wikipedia.org/wiki/Computer_program) points that are not directly representable in [Ascii](https://en.wikipedia.org/wiki/ASCII) into [string](https://en.wikipedia.org/wiki/String_(computer_science)) that replaces these [code](https://en.wikipedia.org/wiki/Computer_program) points with their representation in [Xml](https://en.wikipedia.org/wiki/XML) making the [string](https://en.wikipedia.org/wiki/String_(computer_science)) usable in [Xml](https://en.wikipedia.org/wiki/XML) documents.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok convertUnicodeToXml('setenta e três') eq q(setenta e tr&#234;s);               # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## asciiToHexString($ascii)

Encode an [Ascii](https://en.wikipedia.org/wiki/ASCII) [string](https://en.wikipedia.org/wiki/String_(computer_science)) as a [string](https://en.wikipedia.org/wiki/String_(computer_science)) of [hexadecimal](https://en.wikipedia.org/wiki/Hexadecimal) digits.

       Parameter  Description
    1  $ascii     Ascii [string](https://en.wikipedia.org/wiki/String_(computer_science)) 
**Example:**

      ok asciiToHexString("Hello World!") eq                  "48656c6c6f20576f726c6421";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok                  "Hello World!"  eq hexToAsciiString("48656c6c6f20576f726c6421");
    

## hexToAsciiString($hex)

Decode a [string](https://en.wikipedia.org/wiki/String_(computer_science)) of [hexadecimal](https://en.wikipedia.org/wiki/Hexadecimal) digits as an [Ascii](https://en.wikipedia.org/wiki/ASCII) [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
       Parameter  Description
    1  $hex       Hexadecimal [string](https://en.wikipedia.org/wiki/String_(computer_science)) 
**Example:**

      ok asciiToHexString("Hello World!") eq                  "48656c6c6f20576f726c6421";
    
      ok                  "Hello World!"  eq hexToAsciiString("48656c6c6f20576f726c6421");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## wwwEncode($string)

Percent encode a [url](https://en.wikipedia.org/wiki/URL) per: https://en.wikipedia.org/wiki/Percent-encoding#Percent-encoding\_reserved\_characters.

       Parameter  Description
    1  $string    String

**Example:**

      ok wwwEncode(q(a  {b} <c>)) eq q(a%20%20%7bb%7d%20%3cc%3e);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok wwwEncode(q(../))        eq q(%2e%2e/);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok wwwDecode(wwwEncode $_)  eq $_ for q(a  {b} <c>), q(a  b|c),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        q(%), q(%%), q(%%.%%);
    
    
    [sub](https://perldoc.perl.org/perlsub.html) wwwEncode($)                                                                 # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     {my ($string) = @_;                                                            # String
      join '', map {$translatePercentEncoding{$_}//$_} split //, $string
     }
    

## wwwDecode($string)

Percent decode a [url](https://en.wikipedia.org/wiki/URL) **$string** per: https://en.wikipedia.org/wiki/Percent-encoding#Percent-encoding\_reserved\_characters.

       Parameter  Description
    1  $string    String

**Example:**

      ok wwwEncode(q(a  {b} <c>)) eq q(a%20%20%7bb%7d%20%3cc%3e);
      ok wwwEncode(q(../))        eq q(%2e%2e/);
    
      ok wwwDecode(wwwEncode $_)  eq $_ for q(a  {b} <c>), q(a  b|c),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        q(%), q(%%), q(%%.%%);
    
    
    [sub](https://perldoc.perl.org/perlsub.html) wwwDecode($)                                                                 # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     {my ($string) = @_;                                                            # String
      my $r = '';
      my @s = split //, $string;
      while(@s)
       {my $c = shift @s;
        if ($c eq q(%) and @s >= 2)
         {$c .= shift(@s).shift(@s);
          $r .= $TranslatePercentEncoding{$c}//$c;
         }
        else
         {$r .= $c;
         }
       }
      $r =~ s(%0d0a) (
  )gs;                                                        # Awkward characters that appear in urls
      $r =~ s(\+)     ( )gs;
      $r
     }
    

# Numbers

Numeric operations,

## powerOfTwo($n)

Test whether a number **$n** is a power of two, return the power if it is else **undef**.

       Parameter  Description
    1  $n         Number to check

**Example:**

      ok  powerOfTwo(1) == 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok  powerOfTwo(2) == 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok !powerOfTwo(3);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok  powerOfTwo(4) == 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## containingPowerOfTwo($n)

Find [log](https://en.wikipedia.org/wiki/Log_file) two of the lowest power of two greater than or equal to a number **$n**.

       Parameter  Description
    1  $n         Number to check

**Example:**

      ok containingPowerOfTwo(1) == 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok containingPowerOfTwo(2) == 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok containingPowerOfTwo(3) == 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok containingPowerOfTwo(4) == 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok containingPowerOfTwo(5) == 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok containingPowerOfTwo(7) == 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## numberWithCommas($n)

Place commas in a number.

       Parameter  Description
    1  $n         Number to add commas to

**Example:**

      is_deeply numberWithCommas(1),                 q(1);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply numberWithCommas(12345678), q(12,345,678);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## divideIntegersIntoRanges(@s)

Divide an [array](https://en.wikipedia.org/wiki/Dynamic_array) of integers into ranges.

       Parameter  Description
    1  @s         Integers to be divided into ranges

**Example:**

    is_deeply [divideIntegersIntoRanges   1, 3, 4, 5, 7, 8, 10], [[1], [3..5], [7..8], [10]];    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## divideCharactersIntoRanges($s)

Divide a [string](https://en.wikipedia.org/wiki/String_(computer_science)) of characters into ranges.

       Parameter  Description
    1  $s         String

**Example:**

    is_deeply [divideCharactersIntoRanges "jahiefcb"], [qw(abc ef hij)];                         # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## Minima and Maxima

Find the smallest and largest elements of [arrays](https://en.wikipedia.org/wiki/Dynamic_array). 
### min(@m)

Find the minimum number in a [list](https://en.wikipedia.org/wiki/Linked_list) of numbers confessing to any ill defined values.

       Parameter  Description
    1  @m         Numbers

**Example:**

      ok !max;
      ok max(1) == 1;
      ok max(1,4,2,3) == 4;
    
    
      ok min(1) == 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok min(5,4,2,3) == 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### indexOfMin(@m)

Find the index of the minimum number in a [list](https://en.wikipedia.org/wiki/Linked_list) of numbers confessing to any ill defined values.

       Parameter  Description
    1  @m         Numbers

**Example:**

      ok indexOfMin(qw(2 3 1 2)) == 2;                                                # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### max(@m)

Find the maximum number in a [list](https://en.wikipedia.org/wiki/Linked_list) of numbers confessing to any ill defined values.

       Parameter  Description
    1  @m         Numbers

**Example:**

      ok !max;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok max(1) == 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok max(1,4,2,3) == 4;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok min(1) == 1;
      ok min(5,4,2,3) == 2;
    

### indexOfMax(@m)

Find the index of the maximum number in a [list](https://en.wikipedia.org/wiki/Linked_list) of numbers confessing to any ill defined values.

       Parameter  Description
    1  @m         Numbers

**Example:**

     {ok indexOfMax(qw(2 3 1 2)) == 1;                                                # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### arraySum(@a)

Find the sum of any [strings](https://en.wikipedia.org/wiki/String_(computer_science)) that look like numbers in an [array](https://en.wikipedia.org/wiki/Dynamic_array). 
       Parameter  Description
    1  @a         Array to sum

**Example:**

     {ok arraySum   (1..10) ==  55;                                                   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### arrayProduct(@a)

Find the product of any [strings](https://en.wikipedia.org/wiki/String_(computer_science)) that look like numbers in an [array](https://en.wikipedia.org/wiki/Dynamic_array). 
       Parameter  Description
    1  @a         Array to multiply

**Example:**

      ok arrayProduct(1..5) == 120;                                                   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

### arrayTimes($multiplier, @a)

Multiply by **$multiplier** each element of the [array](https://en.wikipedia.org/wiki/Dynamic_array) **@a** and return as the result.

       Parameter    Description
    1  $multiplier  Multiplier
    2  @a           Array to multiply and return

**Example:**

      is_deeply[arrayTimes(2, 1..5)], [qw(2 4 6 8 10)];                               # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

# Sets

Set operations.

## mergeHashesBySummingValues(@h)

Merge a [list](https://en.wikipedia.org/wiki/Linked_list) of hashes **@h** by summing their values.

       Parameter  Description
    1  @h         List of hashes to be summed

**Example:**

      is_deeply +{a=>1, b=>2, c=>3},
    
        mergeHashesBySummingValues  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

          +{a=>1,b=>1, c=>1}, +{b=>1,c=>1}, +{c=>1};
    

## invertHashOfHashes($h)

Invert a [hash](https://en.wikipedia.org/wiki/Hash_table) of hashes: given {a}{b} = c return {b}{c} = c.

       Parameter  Description
    1  $h         Hash of hashes

**Example:**

      my $h =  {a=>{A=>q(aA), B=>q(aB)}, b=>{A=>q(bA), B=>q(bB)}};
      my $g =  {A=>{a=>q(aA), b=>q(bA)}, B=>{a=>q(aB), b=>q(bB)}};
    
    
      is_deeply invertHashOfHashes($h), $g;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply invertHashOfHashes($g), $h;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## unionOfHashKeys(@h)

Form the union of the keys of the specified hashes **@h** as one [hash](https://en.wikipedia.org/wiki/Hash_table) whose keys represent the union.

       Parameter  Description
    1  @h         List of hashes to be united

**Example:**

    if (1)                                                                           
    
     {is_deeply  unionOfHashKeys  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       ({a=>1,b=>2}, {b=>1,c=>1}, {c=>2}),
        {a=>1, b=>2, c=>2};
    
      is_deeply  intersectionOfHashKeys
       ({a=>1,b=>2},{b=>1,c=>1},{b=>3,c=>2}),
        {b=>1};
     }
    

## intersectionOfHashKeys(@h)

Form the intersection of the keys of the specified hashes **@h** as one [hash](https://en.wikipedia.org/wiki/Hash_table) whose keys represent the intersection.

       Parameter  Description
    1  @h         List of hashes to be intersected

**Example:**

    if (1)                                                                           
     {is_deeply  unionOfHashKeys
       ({a=>1,b=>2}, {b=>1,c=>1}, {c=>2}),
        {a=>1, b=>2, c=>2};
    
    
      is_deeply  intersectionOfHashKeys  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       ({a=>1,b=>2},{b=>1,c=>1},{b=>3,c=>2}),
        {b=>1};
     }
    

## unionOfHashesAsArrays(@h)

Form the union of the specified hashes **@h** as one [hash](https://en.wikipedia.org/wiki/Hash_table) whose values are a [array](https://en.wikipedia.org/wiki/Dynamic_array) of corresponding values from each [hash](https://en.wikipedia.org/wiki/Hash_table). 
       Parameter  Description
    1  @h         List of hashes to be united

**Example:**

    if (1)                                                                           
    
     {is_deeply  unionOfHashesAsArrays  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       ({a=>1,b=>2}, {b=>1,c=>1}, {c=>2}),
        {a=>[1], b=>[2,1], c=>[undef,1,2]};
    
      is_deeply  intersectionOfHashesAsArrays
       ({a=>1,b=>2},{b=>1,c=>1},{b=>3,c=>2}),
        {b=>[2,1,3]};
     }
    

## intersectionOfHashesAsArrays(@h)

Form the intersection of the specified hashes **@h** as one [hash](https://en.wikipedia.org/wiki/Hash_table) whose values are an [array](https://en.wikipedia.org/wiki/Dynamic_array) of corresponding values from each [hash](https://en.wikipedia.org/wiki/Hash_table). 
       Parameter  Description
    1  @h         List of hashes to be intersected

**Example:**

    if (1)                                                                           
     {is_deeply  unionOfHashesAsArrays
       ({a=>1,b=>2}, {b=>1,c=>1}, {c=>2}),
        {a=>[1], b=>[2,1], c=>[undef,1,2]};
    
    
      is_deeply  intersectionOfHashesAsArrays  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       ({a=>1,b=>2},{b=>1,c=>1},{b=>3,c=>2}),
        {b=>[2,1,3]};
     }
    

## setUnion(@s)

Union of sets **@s** represented as [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)) and/or the keys of hashes.

       Parameter  Description
    1  @s         Array of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)) and/or hashes

**Example:**

      is_deeply [qw(a b c)],     [setUnion(qw(a b c a a b b b))];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [qw(a b c d e)], [setUnion {a=>1, b=>2, e=>3}, [qw(c d e)], qw(e)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## setIntersection(@s)

Intersection of sets **@s** represented as [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)) and/or the keys of hashes.

       Parameter  Description
    1  @s         Array of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)) and/or hashes

**Example:**

      is_deeply [qw(a b c)], [setIntersection[qw(e f g a b c )],[qw(a A b B c C)]];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [qw(e)],   [setIntersection {a=>1, b=>2, e=>3}, [qw(c d e)], qw(e)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## setDifference($a, $b)

Subtract the keys in the second set represented as a [hash](https://en.wikipedia.org/wiki/Hash_table) from the first set represented as a [hash](https://en.wikipedia.org/wiki/Hash_table) to create a new [hash](https://en.wikipedia.org/wiki/Hash_table) showing the set difference between the two.

       Parameter  Description
    1  $a         First set as a [hash](https://en.wikipedia.org/wiki/Hash_table)     2  $b         Second set as a [hash](https://en.wikipedia.org/wiki/Hash_table) 
**Example:**

      is_deeply {a=>1}, setDifference({a=>1, b=>2}, {b=>3,c=>4});  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply {a=>1}, setDifference({a=>1, b=>2}, [qw(b c)]);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply {a=>1}, setDifference({a=>1, b=>2},   q(b c));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## setIntersectionOverUnion(@s)

Returns the size of the intersection over the size of the union of one or more sets **@s** represented as [arrays](https://en.wikipedia.org/wiki/Dynamic_array) and/or hashes.

       Parameter  Description
    1  @s         Array of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)) and/or hashes

**Example:**

      my $f = setIntersectionOverUnion {a=>1, b=>2, e=>3}, [qw(c d e)], qw(e);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $f > 0.199999 && $f < 0.200001;
    

## setPartitionOnIntersectionOverUnion($confidence, @sets)

Partition, at a level of **$confidence** between 0 and 1, a set of sets **@sets** so that within each partition the [setIntersectionOverUnion](#setintersectionoverunion) of any two sets in the partition is never less than the specified level of _$confidence\*\*2_.

       Parameter    Description
    1  $confidence  Minimum setIntersectionOverUnion
    2  @sets        Array of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)) and/or hashes representing sets

**Example:**

      is_deeply [setPartitionOnIntersectionOverUnion  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       (0.80,
         [qw(a A   b c d e)],
         [qw(a A B b c d e)],
         [qw(a A B C b c d)],
       )],
      [[["A", "B", "a".."e"],
        ["A",      "a".."e"]],
       [["A".."C", "a".."d"]],
      ];
    }
    
    
    
    
    if (1) {                                                                        
    is_deeply [setPartitionOnIntersectionOverUnionOfSetsOfWords
       (0.80,
         [qw(a A   b c d e)],
         [qw(a A B b c d e)],
         [qw(a A B C b c d)],
       )],
     [[["a", "A", "B", "C", "b", "c", "d"]],
      [["a", "A", "B", "b" .. "e"], ["a", "A", "b" .. "e"]],
     ];
    

## setPartitionOnIntersectionOverUnionOfSetsOfWords($confidence, @sets)

Partition, at a level of **$confidence** between 0 and 1, a set of sets **@sets** of words so that within each partition the [setIntersectionOverUnion](#setintersectionoverunion) of any two sets of words in the partition is never less than the specified _$confidence\*\*2_.

       Parameter    Description
    1  $confidence  Minimum setIntersectionOverUnion
    2  @sets        Array of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)) and/or hashes representing sets

**Example:**

    is_deeply [setPartitionOnIntersectionOverUnionOfSetsOfWords  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       (0.80,
         [qw(a A   b c d e)],
         [qw(a A B b c d e)],
         [qw(a A B C b c d)],
       )],
     [[["a", "A", "B", "C", "b", "c", "d"]],
      [["a", "A", "B", "b" .. "e"], ["a", "A", "b" .. "e"]],
     ];
    

## setPartitionOnIntersectionOverUnionOfStringSets($confidence, @strings)

Partition, at a level of **$confidence** between 0 and 1, a set of sets **@strings**, each set represented by a [string](https://en.wikipedia.org/wiki/String_(computer_science)) containing words and punctuation, each [word](https://en.wikipedia.org/wiki/Doc_(computing)) possibly capitalized, so that within each partition the [setPartitionOnIntersectionOverUnionOfSetsOfWords](#setpartitiononintersectionoverunionofsetsofwords) of any two sets of words in the partition is never less than the specified _$confidence\*\*2_.

       Parameter    Description
    1  $confidence  Minimum setIntersectionOverUnion
    2  @strings     Sets represented by [strings](https://en.wikipedia.org/wiki/String_(computer_science)) 
**Example:**

    is_deeply [setPartitionOnIntersectionOverUnionOfStringSets  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       (0.80,
         q(The Emu            are seen here sometimes.),
         q(The Emu, Gnu       are seen here sometimes.),
         q(The Emu, Gnu, Colt are seen here.),
       )],
     [["The Emu, Gnu, Colt are seen here."],
      ["The Emu, Gnu       are seen here sometimes.",
       "The Emu            are seen here sometimes.",
      ]];
    

## setPartitionOnIntersectionOverUnionOfHashStringSets($confidence, $hashSet)

Partition, at a level of **$confidence** between 0 and 1, a set of sets **$hashSet** represented by a [hash](https://en.wikipedia.org/wiki/Hash_table), each [hash](https://en.wikipedia.org/wiki/Hash_table) value being a [string](https://en.wikipedia.org/wiki/String_(computer_science)) containing words and punctuation, each [word](https://en.wikipedia.org/wiki/Doc_(computing)) possibly capitalized, so that within each partition the [setPartitionOnIntersectionOverUnionOfSetsOfWords](#setpartitiononintersectionoverunionofsetsofwords) of any two sets of words in the partition is never less than the specified **$confidence\*\*2** and the partition entries are the [hash](https://en.wikipedia.org/wiki/Hash_table) keys of the [string](https://en.wikipedia.org/wiki/String_(computer_science)) sets.

       Parameter    Description
    1  $confidence  Minimum setIntersectionOverUnion
    2  $hashSet     Sets represented by the [hash](https://en.wikipedia.org/wiki/Hash_table) value [strings](https://en.wikipedia.org/wiki/String_(computer_science)) 
**Example:**

      is_deeply [setPartitionOnIntersectionOverUnionOfHashStringSets  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       (0.80,
         {e  =>q(The Emu            are seen here sometimes.),
          eg =>q(The Emu, Gnu       are seen here sometimes.),
          egc=>q(The Emu, Gnu, Colt are seen here.),
         }
       )],
     [["e", "eg"], ["egc"]];
    

## setPartitionOnIntersectionOverUnionOfHashStringSetsInParallel($confidence, $hashSet)

Partition, at a level of **$confidence** between 0 and 1, a set of sets **$hashSet** represented by a [hash](https://en.wikipedia.org/wiki/Hash_table), each [hash](https://en.wikipedia.org/wiki/Hash_table) value being a [string](https://en.wikipedia.org/wiki/String_(computer_science)) containing words and punctuation, each [word](https://en.wikipedia.org/wiki/Doc_(computing)) possibly capitalized, so that within each partition the [setPartitionOnIntersectionOverUnionOfSetsOfWords](#setpartitiononintersectionoverunionofsetsofwords) of any two sets of words in the partition is never less than the specified **$confidence\*\*2** and the partition entries are the [hash](https://en.wikipedia.org/wiki/Hash_table) keys of the [string](https://en.wikipedia.org/wiki/String_(computer_science)) sets. The partition is performed in square root parallel.

       Parameter    Description
    1  $confidence  Minimum setIntersectionOverUnion
    2  $hashSet     Sets represented by the [hash](https://en.wikipedia.org/wiki/Hash_table) value [strings](https://en.wikipedia.org/wiki/String_(computer_science)) 
**Example:**

      my $N = 8;
      my %s;
      for     my $a('a'..'z')
       {my @w;
        for   my $b('a'..'e')
         {for my $c('a'..'e')
           {push @w, qq($a$b$c);
           }
         }
    
        for   my $i(1..$N)
         {$s{qq($a$i)} = join ' ', @w;
         }
       }
    
      my $expected =
       [["a1" .. "a8"],
        ["b1" .. "b8"],
        ["c1" .. "c8"],
        ["d1" .. "d8"],
        ["e1" .. "e8"],
        ["f1" .. "f8"],
        ["g1" .. "g8"],
        ["h1" .. "h8"],
        ["i1" .. "i8"],
        ["j1" .. "j8"],
        ["k1" .. "k8"],
        ["l1" .. "l8"],
        ["m1" .. "m8"],
        ["n1" .. "n8"],
        ["o1" .. "o8"],
        ["p1" .. "p8"],
        ["q1" .. "q8"],
        ["r1" .. "r8"],
        ["s1" .. "s8"],
        ["t1" .. "t8"],
        ["u1" .. "u8"],
        ["v1" .. "v8"],
        ["w1" .. "w8"],
        ["x1" .. "x8"],
        ["y1" .. "y8"],
        ["z1" .. "z8"],
       ];
    
      is_deeply $expected,
       [setPartitionOnIntersectionOverUnionOfHashStringSets          (0.50, \%s)];
    
      my $expectedInParallel =
       ["a1 a2 a3 a4 a5 a6 a7 a8",                                                  # Same [strings](https://en.wikipedia.org/wiki/String_(computer_science)) in multiple parallel [processes](https://en.wikipedia.org/wiki/Process_management_(computing))         "b1 b2 b3 b4 b5 b6 b7 b8",
        "b1 b2 b3 b4 b5 b6 b7 b8",
        "c1 c2 c3 c4 c5 c6 c7 c8",
        "d1 d2 d3 d4 d5 d6 d7 d8",
        "d1 d2 d3 d4 d5 d6 d7 d8",
        "e1 e2 e3 e4 e5 e6 e7 e8",
        "f1 f2 f3 f4 f5 f6 f7 f8",
        "f1 f2 f3 f4 f5 f6 f7 f8",
        "g1 g2 g3 g4 g5 g6 g7 g8",
        "h1 h2 h3 h4 h5 h6 h7 h8",
        "h1 h2 h3 h4 h5 h6 h7 h8",
        "i1 i2 i3 i4 i5 i6 i7 i8",
        "j1 j2 j3 j4 j5 j6 j7 j8",
        "j1 j2 j3 j4 j5 j6 j7 j8",
        "k1 k2 k3 k4 k5 k6 k7 k8",
        "l1 l2 l3 l4 l5 l6 l7 l8",
        "l1 l2 l3 l4 l5 l6 l7 l8",
        "m1 m2 m3 m4 m5 m6 m7 m8",
        "n1 n2 n3 n4 n5 n6 n7 n8",
        "n1 n2 n3 n4 n5 n6 n7 n8",
        "o1 o2 o3 o4 o5 o6 o7 o8",
        "p1 p2 p3 p4 p5 p6 p7 p8",
        "q1 q2 q3 q4 q5 q6 q7 q8",
        "q1 q2 q3 q4 q5 q6 q7 q8",
        "r1 r2 r3 r4 r5 r6 r7 r8",
        "s1 s2 [S3](https://aws.amazon.com/s3/) s4 s5 s6 s7 s8",
        "s1 s2 [S3](https://aws.amazon.com/s3/) s4 s5 s6 s7 s8",
        "t1 t2 t3 t4 t5 t6 t7 t8",
        "u1 u2 u3 u4 u5 u6 u7 u8",
        "u1 u2 u3 u4 u5 u6 u7 u8",
        "v1 v2 v3 v4 v5 v6 v7 v8",
        "w1 w2 w3 w4 w5 w6 w7 w8",
        "w1 w2 w3 w4 w5 w6 w7 w8",
        "x1 x2 x3 x4 x5 x6 x7 x8",
        "y1 y2 y3 y4 y5 y6 y7 y8",
        "y1 y2 y3 y4 y5 y6 y7 y8",
        "z1 z2 z3 z4 z5 z6 z7 z8",
       ];
    
      if (1)
    
       {my @p = setPartitionOnIntersectionOverUnionOfHashStringSetsInParallel  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         (0.50, \%s);
    
        is_deeply $expectedInParallel, [sort map {join ' ', @$_} @p];
       }
    

## contains($item, @array)

Returns the indices at which an **$item** matches elements of the specified **@array**. If the item is a regular expression then it is matched as one, else it is a number it is matched as a number, else as a [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
       Parameter  Description
    1  $item      Item
    2  @array     Array

**Example:**

    is_deeply [1],       [contains(1,0..1)];                                          # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    
    is_deeply [1,3],     [contains(1, qw(0 1 0 1 0 0))];                              # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    
    is_deeply [0, 5],    [contains('a', qw(a b c d e a b c d e))];                    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    
    is_deeply [0, 1, 5], [contains(qr(a+), qw(a baa c d e aa b c d e))];              # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## countOccurencesInString($inString, $searchFor)

Returns the number of occurrences in **$inString** of **$searchFor**.

       Parameter   Description
    1  $inString   String to search in
    2  $searchFor  String to search for.

**Example:**

    if (1)                                                                          
    
     {ok countOccurencesInString(q(a<b>c<b><b>d), q(<b>)) == 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## partitionStringsOnPrefixBySize()

Partition a [hash](https://en.wikipedia.org/wiki/Hash_table) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)) and associated sizes into partitions with either a maximum size **$maxSize** or only one element; the [hash](https://en.wikipedia.org/wiki/Hash_table) **%Sizes** consisting of a mapping {string=>size}; with each partition being named with the shortest [string](https://en.wikipedia.org/wiki/String_(computer_science)) prefix that identifies just the [strings](https://en.wikipedia.org/wiki/String_(computer_science)) in that partition. Returns a [list](https://en.wikipedia.org/wiki/Linked_list) of {prefix => size}... describing each partition.

**Example:**

    if (1)                                                                          
    
     {my $ps = \&partitionStringsOnPrefixBySize;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply {&$ps(1)}, {};
      is_deeply {&$ps(1, 1=>0)},      {q()=>0};
      is_deeply {&$ps(1, 1=>1)},      {q()=>1};
      is_deeply {&$ps(1, 1=>2)},      {1=>2};
      is_deeply {&$ps(1, 1=>1,2=>1)}, {1=>1,2=>1};
      is_deeply {&$ps(2, 11=>1,12=>1, 21=>1,22=>1)}, {1=>2, 2=>2};
      is_deeply {&$ps(2, 111=>1,112=>1,113=>1, 121=>1,122=>1,123=>1, 131=>1,132=>1,133=>1)}, { 111 => 1, 112 => 1, 113 => 1, 121 => 1, 122 => 1, 123 => 1, 131 => 1, 132 => 1, 133 => 1 };
    
      for(3..8)
       {is_deeply {&$ps($_, 111=>1,112=>1,113=>1, 121=>1,122=>1,123=>1, 131=>1,132=>1,133=>1)}, { 11 => 3, 12 => 3, 13 => 3 };
       }
    
      is_deeply {&$ps(9, 111=>1,112=>1,113=>1, 121=>1,122=>1,123=>1, 131=>1,132=>1,133=>1)}, { q()=> 9};
      is_deeply {&$ps(3, 111=>1,112=>1,113=>1, 121=>1,122=>1,123=>1, 131=>1,132=>1,133=>2)}, { 11 => 3, 12 => 3, 131 => 1, 132 => 1, 133 => 2 };
      is_deeply {&$ps(4, 111=>1,112=>1,113=>1, 121=>1,122=>1,123=>1, 131=>1,132=>1,133=>2)}, { 11 => 3, 12 => 3, 13 => 4 };
    
     }
    

## transitiveClosure($h)

Transitive closure of a [hash](https://en.wikipedia.org/wiki/Hash_table) of hashes.

       Parameter  Description
    1  $h         Hash of hashes

**Example:**

    if (1)                                                                          
    
     {is_deeply transitiveClosure({a=>{b=>1, c=>2}, b=>{d=>3}, c=>{d=>4}}),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {end => [{ b => 1, c => 1, d => 4 }, { d => 1 }],
        start => { a => 0, b => 1, c => 1 },
       };
     }
    

# Format

Format data structures as tables.

## maximumLineLength($string)

Find the longest line in a **$string**.

       Parameter  Description
    1  $string    String of lines of text

**Example:**

    ok 3 == maximumLineLength(<<END);                                                 # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    a
    bb
    ccc
    END
    

## formatTableBasic($data)

Tabularize an [array](https://en.wikipedia.org/wiki/Dynamic_array) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of text.

       Parameter  Description
    1  $data      Reference to an [array](https://en.wikipedia.org/wiki/Dynamic_array) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of data to be formatted as a [table](https://en.wikipedia.org/wiki/Table_(information)). 
**Example:**

      my $d = [[qw(a 1)], [qw(bb 22)], [qw(ccc 333)], [qw(dddd 4444)]];
    
      ok formatTableBasic($d) eq <<END, q(ftb);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    a        1
    bb      22
    ccc    333
    dddd  4444
    END
      }
    
    if (0) {                                                                         
      my %pids;
      sub{startProcess {} %pids, 1; ok 1 >= keys %pids}->() for 1..8;
      waitForAllStartedProcessesToFinish(%pids);
      ok !keys(%pids)
    

## formatTable($data, $columnTitles, @options)

Format various **$data** structures as a [table](https://en.wikipedia.org/wiki/Table_(information)) with titles as specified by **$columnTitles**: either a reference to an [array](https://en.wikipedia.org/wiki/Dynamic_array) of column titles or a [string](https://en.wikipedia.org/wiki/String_(computer_science)) each line of which contains the column title as the first [word](https://en.wikipedia.org/wiki/Doc_(computing)) with the rest of the line describing that column.

Optionally create a report from the [table](https://en.wikipedia.org/wiki/Table_(information)) using the report **%options** described in [formatTableCheckKeys](https://metacpan.org/pod/formatTableCheckKeys).

       Parameter      Description
    1  $data          Data to be formatted
    2  $columnTitles  Optional reference to an [array](https://en.wikipedia.org/wiki/Dynamic_array) of titles or [string](https://en.wikipedia.org/wiki/String_(computer_science)) of column descriptions
    3  @options       Options

**Example:**

    ok formatTable                                                                    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
     ([[qw(A    B    C    D   )],                                                   
    
       [qw(AA   BB   CC   DD  )],                                                   
    
       [qw(AAA  BBB  CCC  DDD )],                                                   
    
       [qw(AAAA BBBB CCCC DDDD)],                                                   
    
       [qw(1    22   333  4444)]], [qw(aa bb cc)]) eq <<END;   
       aa    bb    cc
    1  A     B     C     D
    2  AA    BB    CC    DD
    3  AAA   BBB   CCC   DDD
    4  AAAA  BBBB  CCCC  DDDD
    5     1    22   333  4444
    END
    
    
    ok formatTable                                                                    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
     ([[qw(1     B   C)],                                                           
    
       [qw(22    BB  CC)],                                                          
    
       [qw(333   BBB CCC)],                                                         
    
       [qw(4444  22  333)]], [qw(aa bb cc)]) eq <<END;         
       aa    bb   cc
    1     1  B    C
    2    22  BB   CC
    3   333  BBB  CCC
    4  4444   22  333
    END
    
    
    ok formatTable                                                                    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
     ([{aa=>'A',   bb=>'B',   cc=>'C'},                                             
    
       {aa=>'AA',  bb=>'BB',  cc=>'CC'},                                            
    
       {aa=>'AAA', bb=>'BBB', cc=>'CCC'},                                           
    
       {aa=>'1',   bb=>'22',  cc=>'333'}                                            
    
       ]) eq <<END;                                                                 
       aa   bb   cc
    1  A    B    C
    2  AA   BB   CC
    3  AAA  BBB  CCC
    4    1   22  333
    END
    
    
    ok formatTable                                                                    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
     ({''=>[qw(aa bb cc)],                                                          
    
        1=>[qw(A B C)],                                                             
    
        22=>[qw(AA BB CC)],                                                         
    
        333=>[qw(AAA BBB CCC)],                                                     
    
        4444=>[qw(1 22 333)]}) eq <<END;                                            
          aa   bb   cc
       1  A    B    C
      22  AA   BB   CC
     333  AAA  BBB  CCC
    4444    1   22  333
    END
    
    
    ok formatTable                                                                    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
     ({1=>{aa=>'A', bb=>'B', cc=>'C'},                                              
    
       22=>{aa=>'AA', bb=>'BB', cc=>'CC'},                                          
    
       333=>{aa=>'AAA', bb=>'BBB', cc=>'CCC'},                                      
    
       4444=>{aa=>'1', bb=>'22', cc=>'333'}}) eq <<END;                             
          aa   bb   cc
       1  A    B    C
      22  AA   BB   CC
     333  AAA  BBB  CCC
    4444    1   22  333
    END
    
    
    ok formatTable({aa=>'A', bb=>'B', cc=>'C'}, [qw(aaaa bbbb)]) eq <<END;            # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    aaaa  bbbb
    aa    A
    bb    B
    cc    C
    END
    
      my $d = temporaryFolder;
      my $f = fpe($d, qw(report txt));                                              # Create a report
    
      my $t = formatTable  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       ([["a",undef], [undef, "b0ac"]],                                           # Data - please replace 0a with a new line
        [undef, "BC"],                                                              # Column titles
        file=>$f,                                                                   # Output [file](https://en.wikipedia.org/wiki/Computer_file)         head=><<END);                                                               # Header
    Sample report.
    
    Table has NNNN rows.
    END
      ok -e $f;
    
      ok readFile($f) eq $t;
      is_deeply nws($t), nws(<<END);
    Sample report.
    
    Table has 2 rows.
    
    This [file](https://en.wikipedia.org/wiki/Computer_file): ${d}report.txt
    
          BC
    1  a
    2     b
          c
    END
      clearFolder($d, 2);
    

## formattedTablesReport(@options)

Report of all the reports created. The optional parameters are the same as for [formatTable](#formattable).

       Parameter  Description
    1  @options   Options

**Example:**

      @formatTables = ();
    
      for my $m(2..8)
       {formatTable([map {[$_, $_*$m]} 1..$m], [q(Single), qq(* $m)],
          title=>qq(Multiply by $m));
       }
    
    
      ok nws(formattedTablesReport) eq nws(<<END);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       Rows  Title          File
    1     2  Multiply by 2
    2     3  Multiply by 3
    3     4  Multiply by 4
    4     5  Multiply by 5
    5     6  Multiply by 6
    6     7  Multiply by 7
    7     8  Multiply by 8
    END
    

## summarizeColumn($data, $column)

Count the number of unique instances of each value a column in a [table](https://en.wikipedia.org/wiki/Table_(information)) assumes.

       Parameter  Description
    1  $data      Table == [array](https://en.wikipedia.org/wiki/Dynamic_array) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array)     2  $column    Column number to summarize.

**Example:**

      is_deeply
    
       [summarizeColumn([map {[$_]} qw(A B D B C D C D A C D C B B D)], 0)],  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       [[5, "D"], [4, "B"], [4, "C"], [2, "A"]];
    
      ok nws(formatTable
       ([map {[split m//, $_]} qw(AA CB CD BC DC DD CD AD AA DC CD CC BB BB BD)],
        [qw(Col-1 Col-2)],
         summarize=>1)) eq nws(<<'END');
    
    Summary_of_column                - Count of unique values found in each column                     Use the Geany flick capability by placing your cursor on the first [word](https://en.wikipedia.org/wiki/Doc_(computing))     Comma_Separated_Values_of_column - Comma separated [list](https://en.wikipedia.org/wiki/Linked_list) of the unique values found in each column  of these lines and pressing control + down arrow to see each [sub](https://perldoc.perl.org/perlsub.html) report.
    
        Col-1  Col-2
     1  A      A
     2  C      B
     3  C      D
     4  B      C
     5  D      C
     6  D      D
     7  C      D
     8  A      D
     9  A      A
    10  D      C
    11  C      D
    12  C      C
    13  B      B
    14  B      B
    15  B      D
    
    Summary_of_column_Col-1
       Count  Col-1
    1      5  C
    2      4  B
    3      3  A
    4      3  D
    
    Comma_Separated_Values_of_column_Col-1: "A","B","C","D"
    
    Summary_of_column_Col-2
       Count  Col-2
    1      6  D
    2      4  C
    3      3  B
    4      2  A
    
    Comma_Separated_Values_of_column_Col-2: "A","B","C","D"
    END
    

## keyCount($maxDepth, $ref)

Count keys down to the specified level.

       Parameter  Description
    1  $maxDepth  Maximum depth to count to
    2  $ref       Reference to an [array](https://en.wikipedia.org/wiki/Dynamic_array) or a [hash](https://en.wikipedia.org/wiki/Hash_table) 
**Example:**

      my $a = [[1..3],       {map{$_=>1} 1..3}];                                    
    
      my $h = {a=>[1..3], b=>{map{$_=>1} 1..3}};                                    
    
    
      ok keyCount(2, $a) == 6;                                                        # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    
      ok keyCount(2, $h) == 6;                                                        # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## formatHtmlTable($data, %options)

Format an [array](https://en.wikipedia.org/wiki/Dynamic_array) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of scalars as an [HTML](https://en.wikipedia.org/wiki/HTML) [table](https://en.wikipedia.org/wiki/Table_(information)) using the  **%options** described in [formatTableCheckKeys](https://metacpan.org/pod/formatTableCheckKeys).

       Parameter  Description
    1  $data      Data to be formatted
    2  %options   Options

**Example:**

    if (1)                                                                          
    
     {my $t = formatHtmlTable  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       ([
          [qw(1 a)],
          [qw(2 b)],
        ],
       title  => q(Sample [HTML](https://en.wikipedia.org/wiki/HTML) table),
       head   => q(Head NNNN rows),
       foot   => q(Footer),
       columns=> <<END,
    source The source number
    target The target letter
    END
       );
    
      my $T = <<'END';
    <h1>Sample [HTML](https://en.wikipedia.org/wiki/HTML) table</h1>
    
    <p>Head 2 rows</p>
    
    <p><table borders="0" cellpadding="10" cellspacing="5">
    
    <tr><th><span title="The source number">source</span><th><span title="The target letter">target</span>
    <tr><td>1<td>a
    <tr><td>2<td>b
    </table></p>
    
    <p><pre>
    source  The source number
    target  The target letter
    
    </pre></p>
    
    <p>Footer</p>
    
    <span class="options" style="display: none">{
      columns => "source The source number
  target The target letter
  ",
      foot    => "Footer",
      head    => "Head NNNN rows",
      rows    => 2,
      title   => "Sample [HTML](https://en.wikipedia.org/wiki/HTML) [table](https://en.wikipedia.org/wiki/Table_(information))",     }</span>
    END
    
      ok "$t
  " eq $T;
     }
    

## formatHtmlTablesIndex($reports, $title, $url, $columns)

Create an index of [HTML](https://en.wikipedia.org/wiki/HTML) reports.

       Parameter  Description
    1  $reports   Reports [folder](https://en.wikipedia.org/wiki/File_folder)     2  $title     Title of report of reports
    3  $url       $url to get files
    4  $columns   Number of columns - defaults to 1

**Example:**

    if (1)                                                                            
     {my $reports = temporaryFolder;
    
      formatHtmlAndTextTables
       ($reports, $reports, q(/cgi-bin/getFile.pl?), q(/a/),
         [[qw(1 /a/a)],
          [qw(2 /a/b)],
         ],
       title   => q(Bad files),
       head    => q(Head NNNN rows),
       foot    => q(Footer),
       [file](https://en.wikipedia.org/wiki/Computer_file)    => q(bad.html),
       facet   => q(files), aspectColor => "red",
       columns => <<END,
    source The source number
    target The target letter
    END
       );
    
      formatHtmlAndTextTables
       ($reports, $reports, q(/cgi-bin/getFile.pl?file=), q(/a/),
         [[qw(1 /a/a1)],
          [qw(2 /a/b2)],
          [qw(3 /a/b3)],
         ],
       title   => q(Good files),
       head    => q(Head NNNN rows),
       foot    => q(Footer),
       [file](https://en.wikipedia.org/wiki/Computer_file)    => q(good.html),
       facet   => q(files), aspectColor => "green",
       columns => <<END,
    source The source number
    target The target letter
    END
       );
    
      formatHtmlAndTextTablesWaitPids;
    
    
      my $result = formatHtmlTablesIndex($reports, q(TITLE), q(/cgi-bin/getFile.pl?file=));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $result =~ m(3.*Good files);
      ok $result =~ m(2.*Bad files);
    #  ok $result =~ m(green.*>3<.*>Good files);
    #  ok $result =~ m(red.*>2<.*>Bad files);
    
      clearFolder($reports, 11);
     }
    

## formatHtmlAndTextTablesWaitPids()

Wait on all [table](https://en.wikipedia.org/wiki/Table_(information)) formatting pids to complete.

**Example:**

    if (1)                                                                            
     {my $reports = temporaryFolder;
    
      formatHtmlAndTextTables
       ($reports, $reports, q(/cgi-bin/getFile.pl?), q(/a/),
         [[qw(1 /a/a)],
          [qw(2 /a/b)],
         ],
       title   => q(Bad files),
       head    => q(Head NNNN rows),
       foot    => q(Footer),
       [file](https://en.wikipedia.org/wiki/Computer_file)    => q(bad.html),
       facet   => q(files), aspectColor => "red",
       columns => <<END,
    source The source number
    target The target letter
    END
       );
    
      formatHtmlAndTextTables
       ($reports, $reports, q(/cgi-bin/getFile.pl?file=), q(/a/),
         [[qw(1 /a/a1)],
          [qw(2 /a/b2)],
          [qw(3 /a/b3)],
         ],
       title   => q(Good files),
       head    => q(Head NNNN rows),
       foot    => q(Footer),
       [file](https://en.wikipedia.org/wiki/Computer_file)    => q(good.html),
       facet   => q(files), aspectColor => "green",
       columns => <<END,
    source The source number
    target The target letter
    END
       );
    
    
      formatHtmlAndTextTablesWaitPids;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $result = formatHtmlTablesIndex($reports, q(TITLE), q(/cgi-bin/getFile.pl?file=));
      ok $result =~ m(3.*Good files);
      ok $result =~ m(2.*Bad files);
    #  ok $result =~ m(green.*>3<.*>Good files);
    #  ok $result =~ m(red.*>2<.*>Bad files);
    
      clearFolder($reports, 11);
     }
    

## formatHtmlAndTextTables($reports, $html, $getFile, $filePrefix, $data, %options)

Create text and [HTML](https://en.wikipedia.org/wiki/HTML) versions of a tabular report.

       Parameter    Description
    1  $reports     Folder to contain text reports
    2  $html        Folder to contain [HTML](https://en.wikipedia.org/wiki/HTML) reports
    3  $getFile     L<url|https://en.wikipedia.org/wiki/URL> to get files
    4  $filePrefix  File prefix to be removed from [file](https://en.wikipedia.org/wiki/Computer_file) entries or [array](https://en.wikipedia.org/wiki/Dynamic_array) of [file](https://en.wikipedia.org/wiki/Computer_file) prefixes
    5  $data        Data
    6  %options     Options

**Example:**

    if (1)                                                                            
     {my $reports = temporaryFolder;
    
    
      formatHtmlAndTextTables  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       ($reports, $reports, q(/cgi-bin/getFile.pl?), q(/a/),
         [[qw(1 /a/a)],
          [qw(2 /a/b)],
         ],
       title   => q(Bad files),
       head    => q(Head NNNN rows),
       foot    => q(Footer),
       [file](https://en.wikipedia.org/wiki/Computer_file)    => q(bad.html),
       facet   => q(files), aspectColor => "red",
       columns => <<END,
    source The source number
    target The target letter
    END
       );
    
    
      formatHtmlAndTextTables  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       ($reports, $reports, q(/cgi-bin/getFile.pl?file=), q(/a/),
         [[qw(1 /a/a1)],
          [qw(2 /a/b2)],
          [qw(3 /a/b3)],
         ],
       title   => q(Good files),
       head    => q(Head NNNN rows),
       foot    => q(Footer),
       [file](https://en.wikipedia.org/wiki/Computer_file)    => q(good.html),
       facet   => q(files), aspectColor => "green",
       columns => <<END,
    source The source number
    target The target letter
    END
       );
    
      formatHtmlAndTextTablesWaitPids;
    
      my $result = formatHtmlTablesIndex($reports, q(TITLE), q(/cgi-bin/getFile.pl?file=));
      ok $result =~ m(3.*Good files);
      ok $result =~ m(2.*Bad files);
    #  ok $result =~ m(green.*>3<.*>Good files);
    #  ok $result =~ m(red.*>2<.*>Bad files);
    
      clearFolder($reports, 11);
     }
    

# Lines

Load data structures from lines.

## loadArrayFromLines($string)

Load an [array](https://en.wikipedia.org/wiki/Dynamic_array) from lines of text in a [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
       Parameter  Description
    1  $string    The [string](https://en.wikipedia.org/wiki/String_(computer_science)) of lines from which to create an [array](https://en.wikipedia.org/wiki/Dynamic_array) 
**Example:**

      my $s = loadArrayFromLines <<END;                                               # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    a a
    b b
    END
    
      is_deeply $s, [q(a a), q(b b)];                                               
    
      ok formatTable($s) eq <<END;                             
    0  a a
    1  b b
    END
    

## loadHashFromLines($string)

Load a [hash](https://en.wikipedia.org/wiki/Hash_table): first [word](https://en.wikipedia.org/wiki/Doc_(computing)) of each line is the key and the rest is the value.

       Parameter  Description
    1  $string    The [string](https://en.wikipedia.org/wiki/String_(computer_science)) of lines from which to create a [hash](https://en.wikipedia.org/wiki/Hash_table) 
**Example:**

      my $s = loadHashFromLines <<END;                                                # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    a 10 11 12
    b 20 21 22
    END
    
      is_deeply $s, {a => q(10 11 12), b =>q(20 21 22)};                            
    
      ok formatTable($s) eq <<END;                             
    a  10 11 12
    b  20 21 22
    END
    

## loadArrayArrayFromLines($string)

Load an [array](https://en.wikipedia.org/wiki/Dynamic_array) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) from lines of text: each line is an [array](https://en.wikipedia.org/wiki/Dynamic_array) of words.

       Parameter  Description
    1  $string    The [string](https://en.wikipedia.org/wiki/String_(computer_science)) of lines from which to create an [array](https://en.wikipedia.org/wiki/Dynamic_array) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) 
**Example:**

      my $s = loadArrayArrayFromLines <<END;                                          # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    A B C
    AA BB CC
    END
    
      is_deeply $s, [[qw(A B C)], [qw(AA BB CC)]];                                  
    
      ok formatTable($s) eq <<END;                             
    1  A   B   C
    2  AA  BB  CC
    END
    

## loadHashArrayFromLines($string)

Load a [hash](https://en.wikipedia.org/wiki/Hash_table) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) from lines of text: the first [word](https://en.wikipedia.org/wiki/Doc_(computing)) of each line is the key, the remaining words are the [array](https://en.wikipedia.org/wiki/Dynamic_array) contents.

       Parameter  Description
    1  $string    The [string](https://en.wikipedia.org/wiki/String_(computer_science)) of lines from which to create a [hash](https://en.wikipedia.org/wiki/Hash_table) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) 
**Example:**

      my $s = loadHashArrayFromLines <<END;                                           # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    a A B C
    b AA BB CC
    END
    
      is_deeply $s, {a =>[qw(A B C)], b => [qw(AA BB CC)] };                        
    
      ok formatTable($s) eq <<END;                             
    a  A   B   C
    b  AA  BB  CC
    END
    

## loadArrayHashFromLines($string)

Load an [array](https://en.wikipedia.org/wiki/Dynamic_array) of hashes from lines of text: each line is a [hash](https://en.wikipedia.org/wiki/Hash_table) of words.

       Parameter  Description
    1  $string    The [string](https://en.wikipedia.org/wiki/String_(computer_science)) of lines from which to create an [array](https://en.wikipedia.org/wiki/Dynamic_array) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) 
**Example:**

      my $s = loadArrayHashFromLines <<END;                                           # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    A 1 B 2
    AA 11 BB 22
    END
    
      is_deeply $s, [{A=>1, B=>2}, {AA=>11, BB=>22}];                               
    
      ok formatTable($s) eq <<END;                             
       A  AA  B  BB
    1  1      2
    2     11     22
    END
    

## loadHashHashFromLines($string)

Load a [hash](https://en.wikipedia.org/wiki/Hash_table) of hashes from lines of text: the first [word](https://en.wikipedia.org/wiki/Doc_(computing)) of each line is the key, the remaining words are the [sub](https://perldoc.perl.org/perlsub.html) [hash](https://en.wikipedia.org/wiki/Hash_table) contents.

       Parameter  Description
    1  $string    The [string](https://en.wikipedia.org/wiki/String_(computer_science)) of lines from which to create a [hash](https://en.wikipedia.org/wiki/Hash_table) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) 
**Example:**

      my $s = loadHashHashFromLines <<END;                                            # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    a A 1 B 2
    b AA 11 BB 22
    END
    
      is_deeply $s, {a=>{A=>1, B=>2}, b=>{AA=>11, BB=>22}};                         
    
      ok formatTable($s) eq <<END;                             
       A  AA  B  BB
    a  1      2
    b     11     22
    END
    

## checkKeys($hash, $permitted)

Check the keys in a **hash** confirm to those **$permitted**.

       Parameter   Description
    1  $hash       The [hash](https://en.wikipedia.org/wiki/Hash_table) to [test](https://en.wikipedia.org/wiki/Software_testing)     2  $permitted  A [hash](https://en.wikipedia.org/wiki/Hash_table) of the permitted keys and their meanings

**Example:**

      [eval](http://perldoc.perl.org/functions/eval.html) q{checkKeys({a=>1, b=>2, d=>3}, {a=>1, b=>2, c=>3})};                      # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok nws($@) =~ m(\AInvalid options chosen: d Permitted.+?: a 1 b 2 c 3);       
    

# LVALUE methods

Replace $a->{**value**} = $b with $a->**value** = $b which reduces the amount of typing required, is easier to read and provides a hard check that {**value**} is spelled correctly.

## genLValueScalarMethods(@names)

Generate [lvalue method](http://perldoc.perl.org/perlsub.html#Lvalue-subroutines) scalar methods in the current package, A method whose value has not yet been set will return a new scalar with value **undef**. Suffixing **X** to the scalar name will [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) if a value has not been set.

       Parameter  Description
    1  @names     List of method names

**Example:**

      package Scalars;                                                              
    
      my $a = bless{};                                                              
    
    
      Data::Table::Text::genLValueScalarMethods(qw(aa bb cc));                        # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      $a->aa = 'aa';                                                                
    
      Test::More::ok  $a->aa eq 'aa';                                               
    
      Test::More::ok !$a->bb;                                                       
    
      Test::More::ok  $a->bbX eq q();                                               
    
      $a->aa = [undef](https://perldoc.perl.org/functions/undef.html);                                                               
    
      Test::More::ok !$a->aa;                                                       
    

## addLValueScalarMethods(@names)

Generate [lvalue method](http://perldoc.perl.org/perlsub.html#Lvalue-subroutines) scalar methods in the current package if they do not already exist. A method whose value has not yet been set will return a new scalar with value **undef**. Suffixing **X** to the scalar name will [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) if a value has not been set.

       Parameter  Description
    1  @names     List of method names

**Example:**

      my $class = "Data::Table::Text::Test";                                        
    
      my $a = bless{}, $class;                                                      
    
    
      addLValueScalarMethods(qq(${class}::$_)) for qw(aa bb aa bb);                   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      $a->aa = 'aa';                                                                
    
      ok  $a->aa eq 'aa';                                                           
    
      ok !$a->bb;                                                                   
    
      ok  $a->bbX eq q();                                                           
    
      $a->aa = [undef](https://perldoc.perl.org/functions/undef.html);                                                               
    
      ok !$a->aa;                                                                   
    

## genLValueScalarMethodsWithDefaultValues(@names)

Generate [lvalue method](http://perldoc.perl.org/perlsub.html#Lvalue-subroutines) scalar methods with default values in the current package. A reference to a method whose value has not yet been set will return a scalar whose value is the name of the method.

       Parameter  Description
    1  @names     List of method names

**Example:**

      package ScalarsWithDefaults;                                                  
    
      my $a = bless{};                                                              
    
    
      Data::Table::Text::genLValueScalarMethodsWithDefaultValues(qw(aa bb cc));       # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Test::More::ok $a->aa eq 'aa';                                                
    

## genLValueArrayMethods(@names)

Generate [lvalue method](http://perldoc.perl.org/perlsub.html#Lvalue-subroutines) [array](https://en.wikipedia.org/wiki/Dynamic_array) methods in the current package. A reference to a method that has no yet been set will return a reference to an empty [array](https://en.wikipedia.org/wiki/Dynamic_array). 
       Parameter  Description
    1  @names     List of method names

**Example:**

      package Arrays;                                                               
    
      my $a = bless{};                                                              
    
    
      Data::Table::Text::genLValueArrayMethods(qw(aa bb cc));                         # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      $a->aa->[1] = 'aa';                                                           
    
      Test::More::ok $a->aa->[1] eq 'aa';                                           
    

## genLValueHashMethods(@names)

Generate [lvalue method](http://perldoc.perl.org/perlsub.html#Lvalue-subroutines) [hash](https://en.wikipedia.org/wiki/Hash_table) methods in the current package. A reference to a method that has no yet been set will return a reference to an empty [hash](https://en.wikipedia.org/wiki/Hash_table). 
       Parameter  Description
    1  @names     Method names

**Example:**

      package Hashes;                                                               
    
      my $a = bless{};                                                              
    
    
      Data::Table::Text::genLValueHashMethods(qw(aa bb cc));                          # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      $a->aa->{a} = 'aa';                                                           
    
      Test::More::ok $a->aa->{a} eq 'aa';                                           
    

## genHash($bless, %attributes)

Return a **$bless**ed [hash](https://en.wikipedia.org/wiki/Hash_table) with the specified **$attributes** accessible via [lvalue method](http://perldoc.perl.org/perlsub.html#Lvalue-subroutines) method calls. [updateDocumentation](#updatedocumentation) will generate [documentation](https://en.wikipedia.org/wiki/Software_documentation) at ["Hash Definitions"](#hash-definitions) for the [hash](https://en.wikipedia.org/wiki/Hash_table) defined by the call to [genHash](#genhash) if the call is laid out as in the example below.

       Parameter    Description
    1  $bless       Package name
    2  %attributes  Hash of attribute names and values

**Example:**

      my $o = genHash(q(TestHash),                                                  # Definition of a blessed [hash](https://en.wikipedia.org/wiki/Hash_table).  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

          a=>q(aa),                                                                 # Definition of attribute aa.
          b=>q(bb),                                                                 # Definition of attribute bb.
         );
      ok $o->a eq q(aa);
      is_deeply $o, {a=>"aa", b=>"bb"};
    
      my $p = genHash(q(TestHash),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        c=>q(cc),                                                                   # Definition of attribute cc.
       );
      ok $p->c eq q(cc);
      ok $p->a =  q(aa);
      ok $p->a eq q(aa);
      is_deeply $p, {a=>"aa", c=>"cc"};
    
      loadHash($p, a=>11, b=>22);                                                   # Load the [hash](https://en.wikipedia.org/wiki/Hash_table)       is_deeply $p, {a=>11, b=>22, c=>"cc"};
    
      my $r = [eval](http://perldoc.perl.org/functions/eval.html) {loadHash($p, d=>44)};                                           # Try to load the [hash](https://en.wikipedia.org/wiki/Hash_table)       ok $@ =~ m(Cannot load attribute: d);
    

## loadHash($hash, %attributes)

Load the specified blessed **$hash** generated with [genHash](#genhash) with **%attributes**. Confess to any unknown attribute names.

       Parameter    Description
    1  $hash        Hash
    2  %attributes  Hash of attribute names and values to be loaded

**Example:**

      my $o = genHash(q(TestHash),                                                  # Definition of a blessed [hash](https://en.wikipedia.org/wiki/Hash_table).           a=>q(aa),                                                                 # Definition of attribute aa.
          b=>q(bb),                                                                 # Definition of attribute bb.
         );
      ok $o->a eq q(aa);
      is_deeply $o, {a=>"aa", b=>"bb"};
      my $p = genHash(q(TestHash),
        c=>q(cc),                                                                   # Definition of attribute cc.
       );
      ok $p->c eq q(cc);
      ok $p->a =  q(aa);
      ok $p->a eq q(aa);
      is_deeply $p, {a=>"aa", c=>"cc"};
    
    
      loadHash($p, a=>11, b=>22);                                                   # Load the [hash](https://en.wikipedia.org/wiki/Hash_table)  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply $p, {a=>11, b=>22, c=>"cc"};
    
    
      my $r = [eval](http://perldoc.perl.org/functions/eval.html) {loadHash($p, d=>44)};                                           # Try to load the [hash](https://en.wikipedia.org/wiki/Hash_table)  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $@ =~ m(Cannot load attribute: d);
    

## reloadHashes($d)

Ensures that all the hashes within a tower of data structures have LValue methods to get and set their current keys.

       Parameter  Description
    1  $d         Data structure

**Example:**

    if (1)                                                                          
     {my $a = bless [bless {aaa=>42}, "AAAA"], "BBBB";
      [eval](http://perldoc.perl.org/functions/eval.html) {$a->[0]->aaa};
      ok $@ =~ m(\ACan.t locate object method .aaa. via package .AAAA.);
    
      reloadHashes($a);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $a->[0]->aaa == 42;
     }
    
    if (1)                                                                          
     {my $a = bless [bless {ccc=>42}, "CCCC"], "DDDD";
      [eval](http://perldoc.perl.org/functions/eval.html) {$a->[0]->ccc};
      ok $@ =~ m(\ACan.t locate object method .ccc. via package .CCCC.);
    
      reloadHashes($a);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $a->[0]->ccc == 42;
     }
    

## setPackageSearchOrder($set, @search)

Set a package search order for methods requested in the current package via AUTOLOAD.

       Parameter  Description
    1  $set       Package to set
    2  @search    Package names in search order.

**Example:**

    if (1)                                                                          
     {if (1)
       {package AAAA;
    
        [sub](https://perldoc.perl.org/perlsub.html) aaaa{q(AAAAaaaa)}
        [sub](https://perldoc.perl.org/perlsub.html) bbbb{q(AAAAbbbb)}
        [sub](https://perldoc.perl.org/perlsub.html) cccc{q(AAAAcccc)}
       }
      if (1)
       {package BBBB;
    
        [sub](https://perldoc.perl.org/perlsub.html) aaaa{q(BBBBaaaa)}
        [sub](https://perldoc.perl.org/perlsub.html) bbbb{q(BBBBbbbb)}
        [sub](https://perldoc.perl.org/perlsub.html) dddd{q(BBBBdddd)}
       }
      if (1)
       {package CCCC;
    
        [sub](https://perldoc.perl.org/perlsub.html) aaaa{q(CCCCaaaa)}
        [sub](https://perldoc.perl.org/perlsub.html) dddd{q(CCCCdddd)}
        [sub](https://perldoc.perl.org/perlsub.html) eeee{q(CCCCeeee)}
       }
    
    
      setPackageSearchOrder(__PACKAGE__, qw(CCCC BBBB AAAA));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok &aaaa eq q(CCCCaaaa);
      ok &bbbb eq q(BBBBbbbb);
      ok &cccc eq q(AAAAcccc);
    
      ok &aaaa eq q(CCCCaaaa);
      ok &bbbb eq q(BBBBbbbb);
      ok &cccc eq q(AAAAcccc);
    
      ok &dddd eq q(CCCCdddd);
      ok &eeee eq q(CCCCeeee);
    
    
      setPackageSearchOrder(__PACKAGE__, qw(AAAA BBBB CCCC));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok &aaaa eq q(AAAAaaaa);
      ok &bbbb eq q(AAAAbbbb);
      ok &cccc eq q(AAAAcccc);
    
      ok &aaaa eq q(AAAAaaaa);
      ok &bbbb eq q(AAAAbbbb);
      ok &cccc eq q(AAAAcccc);
    
      ok &dddd eq q(BBBBdddd);
      ok &eeee eq q(CCCCeeee);
     }
    

## isSubInPackage($package, $sub)

Test whether the specified **$package** contains the subroutine &lt;$sub>.

       Parameter  Description
    1  $package   Package name
    2  $sub       Subroutine name

**Example:**

    if (1)                                                                           
     {sub AAAA::Call {q(AAAA)}
    
      [sub](https://perldoc.perl.org/perlsub.html) BBBB::Call {q(BBBB)}
      [sub](https://perldoc.perl.org/perlsub.html) BBBB::call {q(bbbb)}
    
      if (1)
       {package BBBB;
        use Test::More;
        *ok = *Test::More::ok;
    
        *isSubInPackage = *Data::Table::Text::isSubInPackage;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
        ok  isSubInPackage(q(AAAA), q(Call));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
        ok !isSubInPackage(q(AAAA), q(call));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
        ok  isSubInPackage(q(BBBB), q(Call));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
        ok  isSubInPackage(q(BBBB), q(call));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        ok Call eq q(BBBB);
        ok call eq q(bbbb);
        &Data::Table::Text::overrideMethods(qw(AAAA BBBB Call call));
    
        *isSubInPackage = *Data::Table::Text::isSubInPackage;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
        ok  isSubInPackage(q(AAAA), q(Call));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
        ok  isSubInPackage(q(AAAA), q(call));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
        ok  isSubInPackage(q(BBBB), q(Call));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
        ok  isSubInPackage(q(BBBB), q(call));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        ok Call eq q(AAAA);
        ok call eq q(bbbb);
        package AAAA;
        use Test::More;
        *ok = *Test::More::ok;
        ok  Call eq q(AAAA);
        ok &call eq q(bbbb);
       }
     }
    

## overrideMethods($from, $to, @methods)

For each method, if it exists in package **$from** then export it to package **$to** replacing any existing method in **$to**, otherwise export the method from package **$to** to package **$from** in order to merge the behavior of the **$from** and **$to** packages with respect to the named methods with duplicates resolved if favour of package **$from**.

       Parameter  Description
    1  $from      Name of package from which to import methods
    2  $to        Package into which to import the methods
    3  @methods   List of methods to try importing.

**Example:**

    if (1)                                                                           
     {sub AAAA::Call {q(AAAA)}
    
      [sub](https://perldoc.perl.org/perlsub.html) BBBB::Call {q(BBBB)}
      [sub](https://perldoc.perl.org/perlsub.html) BBBB::call {q(bbbb)}
    
      if (1)
       {package BBBB;
        use Test::More;
        *ok = *Test::More::ok;
        *isSubInPackage = *Data::Table::Text::isSubInPackage;
        ok  isSubInPackage(q(AAAA), q(Call));
        ok !isSubInPackage(q(AAAA), q(call));
        ok  isSubInPackage(q(BBBB), q(Call));
        ok  isSubInPackage(q(BBBB), q(call));
        ok Call eq q(BBBB);
        ok call eq q(bbbb);
    
        &Data::Table::Text::overrideMethods(qw(AAAA BBBB Call call));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        *isSubInPackage = *Data::Table::Text::isSubInPackage;
        ok  isSubInPackage(q(AAAA), q(Call));
        ok  isSubInPackage(q(AAAA), q(call));
        ok  isSubInPackage(q(BBBB), q(Call));
        ok  isSubInPackage(q(BBBB), q(call));
        ok Call eq q(AAAA);
        ok call eq q(bbbb);
        package AAAA;
        use Test::More;
        *ok = *Test::More::ok;
        ok  Call eq q(AAAA);
        ok &call eq q(bbbb);
       }
     }
    

This is a static method and so should either be imported or invoked as:

    Data::Table::Text::overrideMethods

## overrideAndReabsorbMethods(@packages)

Override methods down the [list](https://en.wikipedia.org/wiki/Linked_list) of **@packages** then reabsorb any unused methods back up the [list](https://en.wikipedia.org/wiki/Linked_list) of packages so that all the packages have the same methods as the last package with methods from packages mentioned earlier overriding methods from packages mentioned later.  The methods to override and reabsorb are listed by the [sub](https://perldoc.perl.org/perlsub.html) **overridableMethods** in the last package in the packages [list](https://en.wikipedia.org/wiki/Linked_list). Confess to any errors.

       Parameter  Description
    1  @packages  List of packages

**Example:**

      ok overrideAndReabsorbMethods(qw(main Edit::Xml Data::Edit::Xml));              # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

This is a static method and so should either be imported or invoked as:

    Data::Table::Text::overrideAndReabsorbMethods

## assertPackageRefs($package, @refs)

Confirm that the specified references are to the specified package.

       Parameter  Description
    1  $package   Package
    2  @refs      References

**Example:**

      [eval](http://perldoc.perl.org/functions/eval.html) q{assertPackageRefs(q(bbb), bless {}, q(aaa))};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $@ =~ m(\AWanted reference to bbb, but got aaa);
    

## assertRef(@refs)

Confirm that the specified references are to the package into which this routine has been exported.

       Parameter  Description
    1  @refs      References

**Example:**

      [eval](http://perldoc.perl.org/functions/eval.html) q{assertRef(bless {}, q(aaa))};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $@ =~ m(\AWanted reference to Data::Table::Text, but got aaa);
    

## arrayToHash(@array)

Create a [hash](https://en.wikipedia.org/wiki/Hash_table) reference from an [array](https://en.wikipedia.org/wiki/Dynamic_array). 
       Parameter  Description
    1  @array     Array

**Example:**

    is_deeply arrayToHash(qw(a b c)), {a=>1, b=>1, c=>1};                             # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## flattenArrayAndHashValues(@array)

Flatten an [array](https://en.wikipedia.org/wiki/Dynamic_array) of scalars, [array](https://en.wikipedia.org/wiki/Dynamic_array) and [hash](https://en.wikipedia.org/wiki/Hash_table) references to make an [array](https://en.wikipedia.org/wiki/Dynamic_array) of scalars by flattening the [array](https://en.wikipedia.org/wiki/Dynamic_array) references and [hash](https://en.wikipedia.org/wiki/Hash_table) values.

       Parameter  Description
    1  @array     Array to flatten

**Example:**

    is_deeply [1..5], [flattenArrayAndHashValues([1], [[2]], {a=>3, b=>[4, [5]]})], 'ggg';   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## getSubName($sub)

Returns the (package, name, [file](https://en.wikipedia.org/wiki/Computer_file), line) of a [Perl](http://www.perl.org/) **$sub** reference.

       Parameter  Description
    1  $sub       Reference to a [sub](https://perldoc.perl.org/perlsub.html) with a name.

**Example:**

    is_deeply [(getSubName(\&dateTime))[0,1]], ["Data::Table::Text", "dateTime"];     # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

# Strings

Actions on [strings](https://en.wikipedia.org/wiki/String_(computer_science)). 
## stringMd5Sum($string)

Get the Md5 sum of a **$string** that might contain [utf8](https://en.wikipedia.org/wiki/UTF-8) [code](https://en.wikipedia.org/wiki/Computer_program) points.

       Parameter  Description
    1  $string    String

**Example:**

      my $s = join '', 1..100;
      my $m = q(ef69caaaeea9c17120821a9eb6c7f1de);
    
    
      ok stringMd5Sum($s) eq $m;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $f = writeFile(undef, $s);
      ok fileMd5Sum($f) eq $m;
      unlink $f;
    
      ok guidFromString(join '', 1..100) eq
         q(GUID-ef69caaa-eea9-c171-2082-1a9eb6c7f1de);
    
    
      ok guidFromMd5(stringMd5Sum(join('', 1..100))) eq  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         q(GUID-ef69caaa-eea9-c171-2082-1a9eb6c7f1de);
    
      ok md5FromGuid(q(GUID-ef69caaa-eea9-c171-2082-1a9eb6c7f1de)) eq
                          q(ef69caaaeea9c17120821a9eb6c7f1de);
    
    
      ok stringMd5Sum(q(𝝰 𝝱 𝝲)) eq q(3c2b7c31b1011998bd7e1f66fb7c024d);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    }
    
    if (1)
     {ok arraySum   (1..10) ==  55;                                                 
      ok arrayProduct(1..5) == 120;                                                 
      is_deeply[arrayTimes(2, 1..5)], [qw(2 4 6 8 10)];                             
    

## indentString($string, $indent)

Indent lines contained in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) or formatted [table](https://en.wikipedia.org/wiki/Table_(information)) by the specified [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
       Parameter  Description
    1  $string    The [string](https://en.wikipedia.org/wiki/String_(computer_science)) of lines to indent
    2  $indent    The indenting [string](https://en.wikipedia.org/wiki/String_(computer_science)) 
**Example:**

      my $t = [qw(aa bb cc)];
      my $d = [[qw(A B C)], [qw(AA BB CC)], [qw(AAA BBB CCC)],  [qw(1 22 333)]];
    
      my $s = indentString(formatTable($d), '  ')."
  ";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok $s eq <<END;
      1  A    B    C
      2  AA   BB   CC
      3  AAA  BBB  CCC
      4    1   22  333
    END
    

## replaceStringWithString($string, $source, $target)

Replace all instances in **$string** of **$source** with **$target**.

       Parameter  Description
    1  $string    String in which to replace substrings
    2  $source    The [string](https://en.wikipedia.org/wiki/String_(computer_science)) to be replaced
    3  $target    The replacement [string](https://en.wikipedia.org/wiki/String_(computer_science)) 
**Example:**

    ok replaceStringWithString(q(abababZ), q(ab), q(c)) eq q(cccZ), 'eee';            # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## formatString($string, $width)

Format the specified **$string** so it can be displayed in **$width** columns.

       Parameter  Description
    1  $string    The [string](https://en.wikipedia.org/wiki/String_(computer_science)) of text to format
    2  $width     The formatted width.

**Example:**

    ok formatString(<<END, 16) eq  <<END, 'fff';                                      # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    Now is the time for all
    good men to come to the rescue
    of the ailing B<party>.
    END
    

## isBlank($string)

Test whether a [string](https://en.wikipedia.org/wiki/String_(computer_science)) is blank.

       Parameter  Description
    1  $string    String

**Example:**

     ok isBlank("");                                                                   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     
     
     ok isBlank(" 
    ");                                                               # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     

## trim($string)

Remove any white space from the front and end of a [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
       Parameter  Description
    1  $string    String

**Example:**

    ok trim(" a b ") eq join ' ', qw(a b);                                            # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## pad($string, $length, $padding)

Pad the specified **$string** to a multiple of the specified **$length**  with blanks or the specified padding character to a multiple of a specified length.

       Parameter  Description
    1  $string    String
    2  $length    Tab width
    3  $padding   Padding [string](https://en.wikipedia.org/wiki/String_(computer_science)) 
**Example:**

      is_deeply pad('abc  ', 2).'='         , "abc =";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply pad('abc  ', 3).'='         , "abc=";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply pad('abc  ', 4, q(.)).'='   , "abc.=";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply pad('abc  ', 5).'='         , "abc  =";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply pad('abc  ', 6).'='         , "abc   =";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply  ppp(2, 'abc  ').'='        , "abc =";
      is_deeply  ppp(3, 'abc  ').'='        , "abc=";
      is_deeply  ppp(4, 'abc  ', q(.)).'='  , "abc.=";
      is_deeply  ppp(5, 'abc  ').'='        , "abc  =";
      is_deeply  ppp(6, 'abc  ').'='        , "abc   =";
    
      is_deeply lpad('abc  ', 2).'='        , " abc=";
      is_deeply lpad('abc  ', 3).'='        , "abc=";
      is_deeply lpad('abc  ', 4, q(.)).'='  , ".abc=";
      is_deeply lpad('abc  ', 5).'='        , "  abc=";
      is_deeply lpad('abc  ', 6).'='        , "   abc=";
    

## lpad($string, $length, $padding)

Left Pad the specified **$string** to a multiple of the specified **$length**  with blanks or the specified padding character to a multiple of a specified length.

       Parameter  Description
    1  $string    String
    2  $length    Tab width
    3  $padding   Padding [string](https://en.wikipedia.org/wiki/String_(computer_science)) 
**Example:**

      is_deeply pad('abc  ', 2).'='         , "abc =";
      is_deeply pad('abc  ', 3).'='         , "abc=";
      is_deeply pad('abc  ', 4, q(.)).'='   , "abc.=";
      is_deeply pad('abc  ', 5).'='         , "abc  =";
      is_deeply pad('abc  ', 6).'='         , "abc   =";
    
      is_deeply  ppp(2, 'abc  ').'='        , "abc =";
      is_deeply  ppp(3, 'abc  ').'='        , "abc=";
      is_deeply  ppp(4, 'abc  ', q(.)).'='  , "abc.=";
      is_deeply  ppp(5, 'abc  ').'='        , "abc  =";
      is_deeply  ppp(6, 'abc  ').'='        , "abc   =";
    
    
      is_deeply lpad('abc  ', 2).'='        , " abc=";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply lpad('abc  ', 3).'='        , "abc=";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply lpad('abc  ', 4, q(.)).'='  , ".abc=";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply lpad('abc  ', 5).'='        , "  abc=";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply lpad('abc  ', 6).'='        , "   abc=";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## ppp($length, $string, $padding)

Pad the specified **$string** to a multiple of the specified **$length**  with blanks or the specified padding character to a multiple of a specified length.

       Parameter  Description
    1  $length    Tab width
    2  $string    String
    3  $padding   Padding [string](https://en.wikipedia.org/wiki/String_(computer_science)) 
**Example:**

      is_deeply pad('abc  ', 2).'='         , "abc =";
      is_deeply pad('abc  ', 3).'='         , "abc=";
      is_deeply pad('abc  ', 4, q(.)).'='   , "abc.=";
      is_deeply pad('abc  ', 5).'='         , "abc  =";
      is_deeply pad('abc  ', 6).'='         , "abc   =";
    
    
      is_deeply  ppp(2, 'abc  ').'='        , "abc =";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply  ppp(3, 'abc  ').'='        , "abc=";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply  ppp(4, 'abc  ', q(.)).'='  , "abc.=";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply  ppp(5, 'abc  ').'='        , "abc  =";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply  ppp(6, 'abc  ').'='        , "abc   =";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply lpad('abc  ', 2).'='        , " abc=";
      is_deeply lpad('abc  ', 3).'='        , "abc=";
      is_deeply lpad('abc  ', 4, q(.)).'='  , ".abc=";
      is_deeply lpad('abc  ', 5).'='        , "  abc=";
      is_deeply lpad('abc  ', 6).'='        , "   abc=";
    

## firstNChars($string, $length)

First N characters of a [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
       Parameter  Description
    1  $string    String
    2  $length    Length

**Example:**

    ok firstNChars(q(abc), 2) eq q(ab);                                               # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    
    ok firstNChars(q(abc), 4) eq q(abc);                                              # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## nws($string, $length)

Normalize white space in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to make comparisons easier. Leading and trailing white space is removed; blocks of white space in the interior are reduced to a single space.  In effect: this puts everything on one long line with never more than one space at a time. Optionally a maximum length is applied to the normalized [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
       Parameter  Description
    1  $string    String to normalize
    2  $length    Maximum length of result

**Example:**

    ok nws(qq(a  b    c)) eq q(a b c);                                                # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## deduplicateSequentialWordsInString($s)

Remove sequentially duplicate words in a [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
       Parameter  Description
    1  $s         String to deduplicate

**Example:**

      ok deduplicateSequentialWordsInString(<<END) eq qq(\(aa \[bb \-cc dd ee
  );  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    (aa [bb bb -cc cc dd dd dd dd ee ee ee ee
    END
    

## detagString($string)

Remove [HTML](https://en.wikipedia.org/wiki/HTML) or [Xml](https://en.wikipedia.org/wiki/XML) tags from a [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
       Parameter  Description
    1  $string    String to detag

**Example:**

    ok detagString(q(<a><a href="aaaa">a </a><a/>b </a>c)) eq q(a b c), 'hhh';        # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## parseIntoWordsAndStrings($string)

Parse a **$string** into words and quoted [strings](https://en.wikipedia.org/wiki/String_(computer_science)). A quote following a space introduces a [string](https://en.wikipedia.org/wiki/String_(computer_science)), else a quote is just part of the containing [word](https://en.wikipedia.org/wiki/Doc_(computing)). 
       Parameter  Description
    1  $string    String to [parse](https://en.wikipedia.org/wiki/Parsing) 
**Example:**

    if (1)                                                                          
     {is_deeply
    
       [parseIntoWordsAndStrings(  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    q( aa12!    a'b   "aa !! ++ bb"  '  ',      '"'  "'"  ""   ''.))  ],
     ["aa12!", "a'b", "aa !! ++ bb", "  ", ",", '"', "'", "",  "", '.'];
     }
    

## stringsAreNotEqual($a, $b)

Return the common start followed by the two non equal tails of two non equal [strings](https://en.wikipedia.org/wiki/String_(computer_science)) or an empty [list](https://en.wikipedia.org/wiki/Linked_list) if the [strings](https://en.wikipedia.org/wiki/String_(computer_science)) are equal.

       Parameter  Description
    1  $a         First [string](https://en.wikipedia.org/wiki/String_(computer_science))     2  $b         Second [string](https://en.wikipedia.org/wiki/String_(computer_science)) 
**Example:**

      ok        !stringsAreNotEqual(q(abc), q(abc));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok         stringsAreNotEqual(q(abc), q(abd));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [stringsAreNotEqual(q(abc), q(abd))], [qw(ab c d)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [stringsAreNotEqual(q(ab),  q(abd))], [q(ab), '', q(d)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply showGotVersusWanted("aaaa
  bbbb
  cccc
  dddd
  ",
                                    "aaaa
  bbbb
  ccee
  ffff
  "), <<END;
    Comparing wanted with got failed at line: 3, character: 3
    Start:
    aaaa
    bbbb
    cc
    Want ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    ee
    ffff
    
    Got  ________________________________________________________________________________
    
    cc
    dddd
    END
    

## showGotVersusWanted($g, $e)

Show the difference between the wanted [string](https://en.wikipedia.org/wiki/String_(computer_science)) and the wanted [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
       Parameter  Description
    1  $g         First [string](https://en.wikipedia.org/wiki/String_(computer_science))     2  $e         Second [string](https://en.wikipedia.org/wiki/String_(computer_science)) 
**Example:**

      ok        !stringsAreNotEqual(q(abc), q(abc));
      ok         stringsAreNotEqual(q(abc), q(abd));
      is_deeply [stringsAreNotEqual(q(abc), q(abd))], [qw(ab c d)];
      is_deeply [stringsAreNotEqual(q(ab),  q(abd))], [q(ab), '', q(d)];
    
      is_deeply showGotVersusWanted("aaaa
  bbbb
  cccc
  dddd
  ",  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                                    "aaaa
  bbbb
  ccee
  ffff
  "), <<END;
    Comparing wanted with got failed at line: 3, character: 3
    Start:
    aaaa
    bbbb
    cc
    Want ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    ee
    ffff
    
    Got  ________________________________________________________________________________
    
    cc
    dddd
    END
    

## printQw(@words)

Print an [array](https://en.wikipedia.org/wiki/Dynamic_array) of words in qw() format.

       Parameter  Description
    1  @words     Array of words

**Example:**

    is_deeply       printQw(qw(a b c)),    q(qw(a b c));                              # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## numberOfLinesInString($string)

The number of lines in a [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
       Parameter  Description
    1  $string    String

**Example:**

      ok numberOfLinesInString("a
  b
  ") == 2;                                        # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## javaPackage($java)

Extract the package name from a [Java](https://en.wikipedia.org/wiki/Java_(programming_language)) [string](https://en.wikipedia.org/wiki/String_(computer_science)) or [file](https://en.wikipedia.org/wiki/Computer_file). 
       Parameter  Description
    1  $java      Java [file](https://en.wikipedia.org/wiki/Computer_file) if it exists else the [string](https://en.wikipedia.org/wiki/String_(computer_science)) of [Java](https://en.wikipedia.org/wiki/Java_(programming_language)) 
**Example:**

      my $j = writeFile(undef, <<END);
    // Test
    package com.xyz;
    END
    
      ok javaPackage($j)           eq "com.xyz";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok javaPackageAsFileName($j) eq "com/xyz";
      unlink $j;
    
      my $p = writeFile(undef, <<END);                                              
    package a::b;
    END
      ok perlPackage($p)           eq "a::b";                                       
      unlink $p;
    

## javaPackageAsFileName($java)

Extract the package name from a [Java](https://en.wikipedia.org/wiki/Java_(programming_language)) [string](https://en.wikipedia.org/wiki/String_(computer_science)) or [file](https://en.wikipedia.org/wiki/Computer_file) and convert it to a [file](https://en.wikipedia.org/wiki/Computer_file) name.

       Parameter  Description
    1  $java      Java [file](https://en.wikipedia.org/wiki/Computer_file) if it exists else the [string](https://en.wikipedia.org/wiki/String_(computer_science)) of [Java](https://en.wikipedia.org/wiki/Java_(programming_language)) 
**Example:**

      my $j = writeFile(undef, <<END);
    // Test
    package com.xyz;
    END
      ok javaPackage($j)           eq "com.xyz";
    
      ok javaPackageAsFileName($j) eq "com/xyz";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      unlink $j;
    
      my $p = writeFile(undef, <<END);                                              
    package a::b;
    END
      ok perlPackage($p)           eq "a::b";                                       
      unlink $p;
    

## perlPackage($perl)

Extract the package name from a [Perl](http://www.perl.org/) [string](https://en.wikipedia.org/wiki/String_(computer_science)) or [file](https://en.wikipedia.org/wiki/Computer_file). 
       Parameter  Description
    1  $perl      Perl [file](https://en.wikipedia.org/wiki/Computer_file) if it exists else the [string](https://en.wikipedia.org/wiki/String_(computer_science)) of [Perl](http://www.perl.org/) 
**Example:**

      my $j = writeFile(undef, <<END);
    // Test
    package com.xyz;
    END
      ok javaPackage($j)           eq "com.xyz";
      ok javaPackageAsFileName($j) eq "com/xyz";
      unlink $j;
    
      my $p = writeFile(undef, <<END);                                              
    package a::b;
    END
    
      ok perlPackage($p)           eq "a::b";                                         # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      unlink $p;
    
      my $p = writeFile(undef, <<END);                                              
    package a::b;
    END
    
    
      ok perlPackage($p)           eq "a::b";                                         # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## javaScriptExports($fileOrString)

Extract the Javascript functions marked for export in a [file](https://en.wikipedia.org/wiki/Computer_file) or [string](https://en.wikipedia.org/wiki/String_(computer_science)).  Functions are marked for export by placing function in column 1 followed by //E on the same line.  The end of the exported function is located by 
 }.

       Parameter      Description
    1  $fileOrString  File or [string](https://en.wikipedia.org/wiki/String_(computer_science)) 
**Example:**

      ok javaScriptExports(<<END) eq <<END;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    function aaa()            //E
     {console.log('aaa');
    

## chooseStringAtRandom(@strings)

Choose a [string](https://en.wikipedia.org/wiki/String_(computer_science)) at random from the [list](https://en.wikipedia.org/wiki/Linked_list) of **@strings** supplied.

       Parameter  Description
    1  @strings   Strings to chose from

**Example:**

    ok q(a) eq chooseStringAtRandom(qw(a a a a));                                     # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## randomizeArray(@a)

Randomize an [array](https://en.wikipedia.org/wiki/Dynamic_array). 
       Parameter  Description
    1  @a         Array to randomize

**Example:**

    is_deeply [randomizeArray(qw(a a a a))], [qw(a a a a)];                             # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

# Arrays and Hashes

Operations on [arrays](https://en.wikipedia.org/wiki/Dynamic_array) and hashes and [array](https://en.wikipedia.org/wiki/Dynamic_array) of of hashesh and ghashes of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) and  so on a infinitum.

## lengthOfLongestSubArray($a)

Given an [array](https://en.wikipedia.org/wiki/Dynamic_array) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) [find](https://en.wikipedia.org/wiki/Find_(Unix)) the length of the longest [sub](https://perldoc.perl.org/perlsub.html) [array](https://en.wikipedia.org/wiki/Dynamic_array). 
       Parameter  Description
    1  $a         Array reference

**Example:**

    if (1)                                                                          
    
     {ok 3 == lengthOfLongestSubArray [[1..2], [1..3], [1..3], []];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## cmpArrays($a, $b)

Compare two [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)). 
       Parameter  Description
    1  $a         Array A
    2  $b         Array B

**Example:**

      ok cmpArrays([qw(a b)],   [qw(a a)])   == +1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok cmpArrays([qw(a b)],   [qw(a c)])   == -1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok cmpArrays([qw(a b)],   [qw(a b a)]) == -1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok cmpArrays([qw(a b a)], [qw(a b)])   == +1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok cmpArrays([qw(a b)],   [qw(a b)])   ==  0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok dump(compareArraysAndExplain([qw(a b c)], [qw(a B c)])) eq dump("Differs at index 1:
  b
  B
  ");
      ok dump(compareArraysAndExplain([qw(a b)],   [qw(a b c)])) eq dump("Second [array](https://en.wikipedia.org/wiki/Dynamic_array) has an additional line at index: 2
  c
  ")
      ;
    

## compareArraysAndExplain($A, $B)

Compare two [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)) and provide an explanation as to why they differ if they differ or [undef](https://perldoc.perl.org/functions/undef.html) if they do not.

       Parameter  Description
    1  $A         Array A
    2  $B         Array B

## forEachKeyAndValue($body, %hash)

Iterate over a [hash](https://en.wikipedia.org/wiki/Hash_table) for each key and value.

       Parameter  Description
    1  $body      Body to be executed
    2  %hash      Hash to be iterated

**Example:**

      forEachKeyAndValue  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($letter, $number) = @_;
        push @t,  "Letter=$letter, number=$number";
       } %h;
    
      is_deeply join("
  ", @t, ''), <<END;
    Letter=a, number=1
    Letter=b, number=2
    Letter=c, number=3
    END
    }
    
    if (1) {                                                                        
      is_deeply convertUtf8ToUtf32(0x24),          0x24;
      is_deeply convertUtf8ToUtf32(0xc2a2),        0xa2;
      is_deeply convertUtf8ToUtf32(0xe0a4b9),      0x939;
      is_deeply convertUtf8ToUtf32(0xe282ac),      0x20ac;
      is_deeply convertUtf8ToUtf32(0xed959c),      0xd55c;
      is_deeply convertUtf8ToUtf32(0xf0908d88),    0x10348;
    
      is_deeply convertUtf32ToUtf8(0x24),    0x24;                                  
      is_deeply convertUtf32ToUtf8(0xa2),    0xc2a2;
      is_deeply convertUtf32ToUtf8(0x939),   0xe0a4b9;
      is_deeply convertUtf32ToUtf8(0x20ac),  0xe282ac;
      is_deeply convertUtf32ToUtf8(0xd55c),  0xed959c;
      is_deeply convertUtf32ToUtf8(0x10348), 0xf0908d88;
    
      is_deeply convertUtf32ToUtf8LE(0x24),    0x24;                                
      is_deeply convertUtf32ToUtf8LE(0xa2),    0xa2c2;
      is_deeply convertUtf32ToUtf8LE(0x939),   0xb9a4e0;
      is_deeply convertUtf32ToUtf8LE(0x20ac),  0xac82e2;
      is_deeply convertUtf32ToUtf8LE(0xd55c),  0x9c95ed;
      is_deeply convertUtf32ToUtf8LE(0x10348), 0x888d90f0;
    };
    
    #latest:;
    if (1) {                                                                        
      ok evalOrConfess("1") == 1;
      my $r = [eval](http://perldoc.perl.org/functions/eval.html) {evalOrConfess "++ ++"};
      ok $@ =~ m(syntax error);
    

# Unicode

Translate [Ascii](https://en.wikipedia.org/wiki/ASCII) alphanumerics in [strings](https://en.wikipedia.org/wiki/String_(computer_science)) to various [Unicode](https://en.wikipedia.org/wiki/Unicode) blocks.

## mathematicalItalicString($string)

Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Italic.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok mathematicalItalicString                 (q(APPLES and ORANGES)) eq q(𝐴𝑃𝑃𝐿𝐸𝑆 𝑎𝑛𝑑 𝑂𝑅𝐴𝑁𝐺𝐸𝑆);    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## mathematicalBoldString($string)

Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Bold.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok mathematicalBoldString                   (q(APPLES and ORANGES)) eq q(𝐀𝐏𝐏𝐋𝐄𝐒 𝐚𝐧𝐝 𝐎𝐑𝐀𝐍𝐆𝐄𝐒);    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## mathematicalBoldStringUndo($string)

Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Bold.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok mathematicalBoldStringUndo               (q(𝐀𝐏𝐏𝐋𝐄𝐒 𝐚𝐧𝐝 𝐎𝐑𝐀𝐍𝐆𝐄𝐒)) eq q(APPLES and ORANGES);    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## mathematicalBoldItalicString($string)

Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Bold Italic.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok mathematicalBoldItalicString             (q(APPLES and ORANGES)) eq q(𝑨𝑷𝑷𝑳𝑬𝑺 𝒂𝒏𝒅 𝑶𝑹𝑨𝑵𝑮𝑬𝑺);     # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## mathematicalBoldItalicStringUndo($string)

Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Bold Italic.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok mathematicalBoldItalicStringUndo         (q(𝑨𝑷𝑷𝑳𝑬𝑺 𝒂𝒏𝒅 𝑶𝑹𝑨𝑵𝑮𝑬𝑺))  eq q(APPLES and ORANGES);    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## mathematicalSansSerifString($string)

Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Sans Serif.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok mathematicalSansSerifString              (q(APPLES and ORANGES)) eq q(𝖠𝖯𝖯𝖫𝖤𝖲 𝖺𝗇𝖽 𝖮𝖱𝖠𝖭𝖦𝖤𝖲);     # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## mathematicalSansSerifStringUndo($string)

Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Sans Serif.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok mathematicalSansSerifStringUndo          (q(𝖠𝖯𝖯𝖫𝖤𝖲 𝖺𝗇𝖽 𝖮𝖱𝖠𝖭𝖦𝖤𝖲))  eq q(APPLES and ORANGES);    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## mathematicalSansSerifBoldString($string)

Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Sans Serif Bold.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok mathematicalSansSerifBoldString          (q(APPLES and ORANGES)) eq q(𝗔𝗣𝗣𝗟𝗘𝗦 𝗮𝗻𝗱 𝗢𝗥𝗔𝗡𝗚𝗘𝗦);     # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## mathematicalSansSerifBoldStringUndo($string)

Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Sans Serif Bold.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok mathematicalSansSerifBoldStringUndo      (q(𝗔𝗣𝗣𝗟𝗘𝗦 𝗮𝗻𝗱 𝗢𝗥𝗔𝗡𝗚𝗘𝗦)) eq q(APPLES and ORANGES);     # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## mathematicalSansSerifItalicString($string)

Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Sans Serif Italic.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok mathematicalSansSerifItalicString        (q(APPLES and ORANGES)) eq q(𝘈𝘗𝘗𝘓𝘌𝘚 𝘢𝘯𝘥 𝘖𝘙𝘈𝘕𝘎𝘌𝘚);      # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## mathematicalSansSerifItalicStringUndo($string)

Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Sans Serif Italic.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok mathematicalSansSerifItalicStringUndo    (q(𝘈𝘗𝘗𝘓𝘌𝘚 𝘢𝘯𝘥 𝘖𝘙𝘈𝘕𝘎𝘌𝘚)) eq q(APPLES and ORANGES);      # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## mathematicalSansSerifBoldItalicString($string)

Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Sans Serif Bold Italic.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok mathematicalSansSerifBoldItalicString    (q(APPLES and ORANGES)) eq q(𝘼𝙋𝙋𝙇𝙀𝙎 𝙖𝙣𝙙 𝙊𝙍𝘼𝙉𝙂𝙀𝙎);     # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## mathematicalSansSerifBoldItalicStringUndo($string)

Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Sans Serif Bold Italic.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok mathematicalSansSerifBoldItalicStringUndo(q(𝘼𝙋𝙋𝙇𝙀𝙎 𝙖𝙣𝙙 𝙊𝙍𝘼𝙉𝙂𝙀𝙎)) eq q(APPLES and ORANGES);     # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## mathematicalMonoSpaceString($string)

Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical MonoSpace.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok mathematicalMonoSpaceString              (q(APPLES and ORANGES)) eq q(𝙰𝙿𝙿𝙻𝙴𝚂 𝚊𝚗𝚍 𝙾𝚁𝙰𝙽𝙶𝙴𝚂);    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## mathematicalMonoSpaceStringUndo($string)

Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical MonoSpace.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok mathematicalMonoSpaceStringUndo          (q(𝙰𝙿𝙿𝙻𝙴𝚂 𝚊𝚗𝚍 𝙾𝚁𝙰𝙽𝙶𝙴𝚂)) eq q(APPLES and ORANGES);    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## boldString($string)

Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to bold.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok boldString(q(zZ)) eq q(𝘇𝗭);                                                    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## boldStringUndo($string)

Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to bold.

       Parameter  Description
    1  $string    String to convert

**Example:**

    if (1)                                                                              
     {my $n = 1234567890;
    
      ok boldStringUndo            (boldString($n))             == $n;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok enclosedStringUndo        (enclosedString($n))         == $n;
      ok enclosedReversedStringUndo(enclosedReversedString($n)) == $n;
      ok superScriptStringUndo     (superScriptString($n))      == $n;
      ok subScriptStringUndo       (subScriptString($n))        == $n;
     }
    

## enclosedString($string)

Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to enclosed alphanumerics.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok enclosedString(q(hello world 1234)) eq q(ⓗⓔⓛⓛⓞ ⓦⓞⓡⓛⓓ ①②③④);           # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## enclosedStringUndo($string)

Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to enclosed alphanumerics.

       Parameter  Description
    1  $string    String to convert

**Example:**

    if (1)                                                                              
     {my $n = 1234567890;
      ok boldStringUndo            (boldString($n))             == $n;
    
      ok enclosedStringUndo        (enclosedString($n))         == $n;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok enclosedReversedStringUndo(enclosedReversedString($n)) == $n;
      ok superScriptStringUndo     (superScriptString($n))      == $n;
      ok subScriptStringUndo       (subScriptString($n))        == $n;
     }
    

## enclosedReversedString($string)

Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to enclosed reversed alphanumerics.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok enclosedReversedString(q(hello world 1234)) eq q(🅗🅔🅛🅛🅞 🅦🅞🅡🅛🅓 ➊➋➌➍);   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## enclosedReversedStringUndo($string)

Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to enclosed reversed alphanumerics.

       Parameter  Description
    1  $string    String to convert

**Example:**

    if (1)                                                                              
     {my $n = 1234567890;
      ok boldStringUndo            (boldString($n))             == $n;
      ok enclosedStringUndo        (enclosedString($n))         == $n;
    
      ok enclosedReversedStringUndo(enclosedReversedString($n)) == $n;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok superScriptStringUndo     (superScriptString($n))      == $n;
      ok subScriptStringUndo       (subScriptString($n))        == $n;
     }
    

## superScriptString($string)

Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to super scripts.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok superScriptString(1234567890) eq q(¹²³⁴⁵⁶⁷⁸⁹⁰);                                # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## superScriptStringUndo($string)

Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to super scripts.

       Parameter  Description
    1  $string    String to convert

**Example:**

    if (1)                                                                              
     {my $n = 1234567890;
      ok boldStringUndo            (boldString($n))             == $n;
      ok enclosedStringUndo        (enclosedString($n))         == $n;
      ok enclosedReversedStringUndo(enclosedReversedString($n)) == $n;
    
      ok superScriptStringUndo     (superScriptString($n))      == $n;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok subScriptStringUndo       (subScriptString($n))        == $n;
     }
    

## subScriptString($string)

Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [sub](https://perldoc.perl.org/perlsub.html) scripts.

       Parameter  Description
    1  $string    String to convert

**Example:**

    ok subScriptString(1234567890)   eq q(₁₂₃₄₅₆₇₈₉₀);                                # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## subScriptStringUndo($string)

Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [sub](https://perldoc.perl.org/perlsub.html) scripts.

       Parameter  Description
    1  $string    String to convert

**Example:**

    if (1)                                                                              
     {my $n = 1234567890;
      ok boldStringUndo            (boldString($n))             == $n;
      ok enclosedStringUndo        (enclosedString($n))         == $n;
      ok enclosedReversedStringUndo(enclosedReversedString($n)) == $n;
      ok superScriptStringUndo     (superScriptString($n))      == $n;
    
      ok subScriptStringUndo       (subScriptString($n))        == $n;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## isFileUtf8($file)

Return the [file](https://en.wikipedia.org/wiki/Computer_file) name quoted if its contents are in [utf8](https://en.wikipedia.org/wiki/UTF-8) else return [undef](https://perldoc.perl.org/functions/undef.html). 
       Parameter  Description
    1  $file      File to [test](https://en.wikipedia.org/wiki/Software_testing) 
**Example:**

      my $f = writeFile(undef, "aaa");
    
      ok isFileUtf8 $f;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## convertUtf8ToUtf32($c)

Convert a number representing a single [Unicode](https://en.wikipedia.org/wiki/Unicode) point coded in [utf8](https://en.wikipedia.org/wiki/UTF-8) to utf32.

       Parameter  Description
    1  $c         Unicode point encoded as [utf8](https://en.wikipedia.org/wiki/UTF-8) 
**Example:**

      is_deeply convertUtf8ToUtf32(0x24),          0x24;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply convertUtf8ToUtf32(0xc2a2),        0xa2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply convertUtf8ToUtf32(0xe0a4b9),      0x939;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply convertUtf8ToUtf32(0xe282ac),      0x20ac;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply convertUtf8ToUtf32(0xed959c),      0xd55c;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply convertUtf8ToUtf32(0xf0908d88),    0x10348;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply convertUtf32ToUtf8(0x24),    0x24;                                  
      is_deeply convertUtf32ToUtf8(0xa2),    0xc2a2;
      is_deeply convertUtf32ToUtf8(0x939),   0xe0a4b9;
      is_deeply convertUtf32ToUtf8(0x20ac),  0xe282ac;
      is_deeply convertUtf32ToUtf8(0xd55c),  0xed959c;
      is_deeply convertUtf32ToUtf8(0x10348), 0xf0908d88;
    
      is_deeply convertUtf32ToUtf8LE(0x24),    0x24;                                
      is_deeply convertUtf32ToUtf8LE(0xa2),    0xa2c2;
      is_deeply convertUtf32ToUtf8LE(0x939),   0xb9a4e0;
      is_deeply convertUtf32ToUtf8LE(0x20ac),  0xac82e2;
      is_deeply convertUtf32ToUtf8LE(0xd55c),  0x9c95ed;
      is_deeply convertUtf32ToUtf8LE(0x10348), 0x888d90f0;
    };
    
    #latest:;
    if (1) {                                                                        
      ok evalOrConfess("1") == 1;
      my $r = [eval](http://perldoc.perl.org/functions/eval.html) {evalOrConfess "++ ++"};
      ok $@ =~ m(syntax error);
    

## convertUtf32ToUtf8($c)

Convert a number representing a single [Unicode](https://en.wikipedia.org/wiki/Unicode) point coded in utf32 to [utf8](https://en.wikipedia.org/wiki/UTF-8) big endian.

       Parameter  Description
    1  $c         Unicode point encoded as utf32

**Example:**

      is_deeply convertUtf32ToUtf8(0x24),    0x24;                                    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## convertUtf32ToUtf8LE($c)

Convert a number representing a single [Unicode](https://en.wikipedia.org/wiki/Unicode) point coded in utf32 to [utf8](https://en.wikipedia.org/wiki/UTF-8) little endian.

       Parameter  Description
    1  $c         Unicode point encoded as utf32

**Example:**

      is_deeply convertUtf32ToUtf8LE(0x24),    0x24;                                  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

# System Constants

Extract system constants

## getSystemConstantsFromIncludeFile($file, @constants)

Get the value of the named system constants from an include [file](https://en.wikipedia.org/wiki/Computer_file). 
       Parameter   Description
    1  $file       File to read
    2  @constants  Constants to get

**Example:**

    if (1)                                                                          
    
     {my %c = (getSystemConstantsFromIncludeFile("linux/mman.h", qw(MAP_PRIVATE PROT_READ)),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
               getSystemConstantsFromIncludeFile("linux/mman.h", qw(MAP_PRIVATE PROT_WRITE)));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply \%c, { MAP_PRIVATE => 2, PROT_READ => 1, PROT_WRITE => 2 };
     }
    

## getStructureSizeFromIncludeFile($file, $structure)

Get the size of a system structure from an include [file](https://en.wikipedia.org/wiki/Computer_file). 
       Parameter   Description
    1  $file       File to read
    2  $structure  Structure name

**Example:**

    if (1)                                                                          
     {my $o = getFieldOffsetInStructureFromIncludeFile("sys/stat.h", q(struct stat), q(st_size));
      is_deeply $o, 48;
     }
    

## getFieldOffsetInStructureFromIncludeFile($file, $structure, $field)

Get the offset of a field in a system structures from an include [file](https://en.wikipedia.org/wiki/Computer_file). 
       Parameter   Description
    1  $file       File to read
    2  $structure  Structure name
    3  $field      Field name

**Example:**

    if (1)                                                                          
     {my $s = getStructureSizeFromIncludeFile("sys/stat.h", q(struct stat));
      is_deeply $s, 144;
     }
    

# Unix [domain name](https://en.wikipedia.org/wiki/Domain_name) communications

Send messages between [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) via a [Unix](https://en.wikipedia.org/wiki/Unix) [domain name](https://en.wikipedia.org/wiki/Domain_name) [socket](https://en.wikipedia.org/wiki/Network_socket). 
## newUdsrServer(@parms)

Create a communications [server](https://en.wikipedia.org/wiki/Server_(computing)) - a means to communicate between [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) on the same machine via [Udsr::read](#udsr-read) and [Udsr::write](#udsr-write).

       Parameter  Description
    1  @parms     Attributes per L<Udsr Definition|/Udsr Definition>

**Example:**

      my $N = 20;
    
      my $s = newUdsrServer(serverAction=>sub  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($u) = @_;
        my $r = $u->read;
        $u->write(qq(Hello from [server](https://en.wikipedia.org/wiki/Server_(computing)) $r));
       });
    
      my $p = newProcessStarter(min(100, $N));                                      # Run some clients
      for my $i(1..$N)
       {$p->start(sub
         {my $count = 0;
          for my $j(1..$N)
           {my $c = newUdsrClient;
            my $m = qq(Hello from client $i x $j);
            $c->write($m);
            my $r = $c->read;
            ++$count if $r eq qq(Hello from [server](https://en.wikipedia.org/wiki/Server_(computing)) $m);
           }
          [$count]
         });
       }
    
      my $count;
      for my $r($p->finish)                                                         # Consolidate results
       {my ($c) = @$r;
        $count += $c;
       }
    
      ok $count == $N*$N;                                                           # Check results and kill
      $s->kill;
    

## newUdsrClient(@parms)

Create a new communications client - a means to communicate between [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) on the same machine via [Udsr::read](#udsr-read) and [Udsr::write](#udsr-write).

       Parameter  Description
    1  @parms     Attributes per L<Udsr Definition|/Udsr Definition>

**Example:**

      my $N = 20;
      my $s = newUdsrServer(serverAction=>sub
       {my ($u) = @_;
        my $r = $u->read;
        $u->write(qq(Hello from [server](https://en.wikipedia.org/wiki/Server_(computing)) $r));
       });
    
      my $p = newProcessStarter(min(100, $N));                                      # Run some clients
      for my $i(1..$N)
       {$p->start(sub
         {my $count = 0;
          for my $j(1..$N)
    
           {my $c = newUdsrClient;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

            my $m = qq(Hello from client $i x $j);
            $c->write($m);
            my $r = $c->read;
            ++$count if $r eq qq(Hello from [server](https://en.wikipedia.org/wiki/Server_(computing)) $m);
           }
          [$count]
         });
       }
    
      my $count;
      for my $r($p->finish)                                                         # Consolidate results
       {my ($c) = @$r;
        $count += $c;
       }
    
      ok $count == $N*$N;                                                           # Check results and kill
      $s->kill;
    

## Udsr::write($u, $msg)

Write a communications message to the [newUdsrServer](#newudsrserver) or the [newUdsrClient](#newudsrclient).

       Parameter  Description
    1  $u         Communicator
    2  $msg       Message

**Example:**

      my $N = 20;
      my $s = newUdsrServer(serverAction=>sub
       {my ($u) = @_;
        my $r = $u->read;
        $u->write(qq(Hello from [server](https://en.wikipedia.org/wiki/Server_(computing)) $r));
       });
    
      my $p = newProcessStarter(min(100, $N));                                      # Run some clients
      for my $i(1..$N)
       {$p->start(sub
         {my $count = 0;
          for my $j(1..$N)
           {my $c = newUdsrClient;
            my $m = qq(Hello from client $i x $j);
            $c->write($m);
            my $r = $c->read;
            ++$count if $r eq qq(Hello from [server](https://en.wikipedia.org/wiki/Server_(computing)) $m);
           }
          [$count]
         });
       }
    
      my $count;
      for my $r($p->finish)                                                         # Consolidate results
       {my ($c) = @$r;
        $count += $c;
       }
    
      ok $count == $N*$N;                                                           # Check results and kill
      $s->kill;
    

## Udsr::read($u)

Read a message from the [newUdsrServer](#newudsrserver) or the [newUdsrClient](#newudsrclient).

       Parameter  Description
    1  $u         Communicator

**Example:**

      my $N = 20;
      my $s = newUdsrServer(serverAction=>sub
       {my ($u) = @_;
        my $r = $u->read;
        $u->write(qq(Hello from [server](https://en.wikipedia.org/wiki/Server_(computing)) $r));
       });
    
      my $p = newProcessStarter(min(100, $N));                                      # Run some clients
      for my $i(1..$N)
       {$p->start(sub
         {my $count = 0;
          for my $j(1..$N)
           {my $c = newUdsrClient;
            my $m = qq(Hello from client $i x $j);
            $c->write($m);
            my $r = $c->read;
            ++$count if $r eq qq(Hello from [server](https://en.wikipedia.org/wiki/Server_(computing)) $m);
           }
          [$count]
         });
       }
    
      my $count;
      for my $r($p->finish)                                                         # Consolidate results
       {my ($c) = @$r;
        $count += $c;
       }
    
      ok $count == $N*$N;                                                           # Check results and kill
      $s->kill;
    

## Udsr::kill($u)

Kill a communications [server](https://en.wikipedia.org/wiki/Server_(computing)). 
       Parameter  Description
    1  $u         Communicator

**Example:**

      my $N = 20;
      my $s = newUdsrServer(serverAction=>sub
       {my ($u) = @_;
        my $r = $u->read;
        $u->write(qq(Hello from [server](https://en.wikipedia.org/wiki/Server_(computing)) $r));
       });
    
      my $p = newProcessStarter(min(100, $N));                                      # Run some clients
      for my $i(1..$N)
       {$p->start(sub
         {my $count = 0;
          for my $j(1..$N)
           {my $c = newUdsrClient;
            my $m = qq(Hello from client $i x $j);
            $c->write($m);
            my $r = $c->read;
            ++$count if $r eq qq(Hello from [server](https://en.wikipedia.org/wiki/Server_(computing)) $m);
           }
          [$count]
         });
       }
    
      my $count;
      for my $r($p->finish)                                                         # Consolidate results
       {my ($c) = @$r;
        $count += $c;
       }
    
      ok $count == $N*$N;                                                           # Check results and kill
      $s->kill;
    

## Udsr::webUser($u, $folder)

Create a systemd installed [server](https://en.wikipedia.org/wiki/Server_(computing)) that [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) [HTTP](https://en.wikipedia.org/wiki/HTTP) requests using a specified [userid](https://en.wikipedia.org/wiki/User_identifier). The systemd and CGI files plus an installation script are written to the specified [folder](https://en.wikipedia.org/wiki/File_folder) after it has been cleared. The [serverAction](https://metacpan.org/pod/serverAction) attribute contains the [code](https://en.wikipedia.org/wiki/Computer_program) to be executed by the [server](https://en.wikipedia.org/wiki/Server_(computing)): it should contain a [sub](https://perldoc.perl.org/perlsub.html) **genResponse($hash)** which will be called with a [hash](https://en.wikipedia.org/wiki/Hash_table) of the CGI variables. This [sub](https://perldoc.perl.org/perlsub.html) should return the response to be sent back to the client. Returns the installation script [file](https://en.wikipedia.org/wiki/Computer_file) name.

       Parameter  Description
    1  $u         Communicator
    2  $folder    Folder to contain [server](https://en.wikipedia.org/wiki/Server_(computing)) [code](https://en.wikipedia.org/wiki/Computer_program) 
**Example:**

    if (0)                                                                          
     {my $fold = fpd(qw(/home phil zzz));                                           # Folder to contain [server](https://en.wikipedia.org/wiki/Server_(computing)) [code](https://en.wikipedia.org/wiki/Computer_program)       my $name = q(test);                                                           # Service
      my $user = q(phil);                                                           # User
    
      my $udsr = newUdsr                                                            # Create a Udsr parameter [list](https://en.wikipedia.org/wiki/Linked_list)        (serviceName => $name,
        serviceUser => $user,
        socketPath  => qq(/home/phil/$name.socket),
        serverAction=> <<'END'
    my $user = userId;
    my $list = qx(ls -l);
    my $dtts = dateTimeStamp;
    return <<END2;
    Content-type: text/html
    
    <h1>Hello World to you $user on $dtts!</h1>
    
    <pre>
    $list
    </pre>
    END2
    END
       );
    
    
      Udsr::webUser($udsr, $fold);                                                  # Create and [install](https://en.wikipedia.org/wiki/Installation_(computer_programs)) web service interface  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $ip = awsIp;
      say STDERR qx(curl http://$ip/cgi-bin/$name/client.pl);                       # Enable port 80 on AWS first
     }
    

## www

Web processing

### wwwGitHubAuth($saveUserDetails, $clientId, $clientSecret, $code, $state)

Logon as a [GitHub](https://github.com/philiprbrenan) [Oauth](https://en.wikipedia.org/wiki/OAuth) app per: [https://github.com/settings/developers](https://github.com/settings/developers). If no [Oauth](https://en.wikipedia.org/wiki/OAuth) [code](https://en.wikipedia.org/wiki/Computer_program) is supplied then a web page is printed that allows the [user](https://en.wikipedia.org/wiki/User_(computing)) to request that such a [code](https://en.wikipedia.org/wiki/Computer_program) be sent to the [server](https://en.wikipedia.org/wiki/Server_(computing)).  If a valid [code](https://en.wikipedia.org/wiki/Computer_program) is received, by the [server](https://en.wikipedia.org/wiki/Server_(computing)) then it is converted to a [Oauth](https://en.wikipedia.org/wiki/OAuth) token which is handed to [sub](https://perldoc.perl.org/perlsub.html) [saveUserDetails](https://metacpan.org/pod/saveUserDetails).

       Parameter         Description
    1  $saveUserDetails  Process [user](https://en.wikipedia.org/wiki/User_(computing)) token once obtained from GitHub
    2  $clientId         Client id
    3  $clientSecret     Client secret
    4  $code             Authorization [code](https://en.wikipedia.org/wiki/Computer_program)     5  $state            Random [string](https://en.wikipedia.org/wiki/String_(computer_science)) 
**Example:**

      wwwHeader;
    
    
      wwwGitHubAuth  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($user, $state, $token, $scope, $type) = @_;
       }
      q(12345678901234567890), q(1234567890123456789012345678901234567890),
      q(12345678901234567890123456789012), q(12345678901234567890);
    

# Cloud Cover

Useful for operating across the cloud.

## makeDieConfess()

Force [die](http://perldoc.perl.org/functions/die.html) to [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) where the death occurred.

**Example:**

      makeDieConfess                                                                  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## ipAddressOfHost($host)

Get the first [IP address](https://en.wikipedia.org/wiki/IP_address) address of the specified host via Domain Name Services.

       Parameter  Description
    1  $host      Host name

**Example:**

      ok saveAwsIp(q(0.0.0.0)) eq awsIp;
      ok saveAwsIp(q(example.org));
      ok saveAwsDomain(q(example.org));
      ok awsR53a   (q(XXXXX), q(www.example.org), q(22.12.232.1));
      ok awsR53aaaa(q(XXXXX), q(www.example.org), q([1232:1232:1232:1232:1232:1232:1232:1232:]));
    

## awsIp()

Get [IP address](https://en.wikipedia.org/wiki/IP_address) address of [server](https://en.wikipedia.org/wiki/Server_(computing)) at [Amazon Web Services](http://aws.amazon.com).

**Example:**

      ok saveAwsIp(q(0.0.0.0)) eq awsIp;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok saveAwsIp(q(example.org));
      ok saveAwsDomain(q(example.org));
      ok awsR53a   (q(XXXXX), q(www.example.org), q(22.12.232.1));
      ok awsR53aaaa(q(XXXXX), q(www.example.org), q([1232:1232:1232:1232:1232:1232:1232:1232:]));
    

## saveAwsIp()

Make the [server](https://en.wikipedia.org/wiki/Server_(computing)) at [Amazon Web Services](http://aws.amazon.com) with the given IP address the default primary [server](https://en.wikipedia.org/wiki/Server_(computing)) as used by all the methods whose names end in **r** or **Remote**. Returns the given IP address.

**Example:**

      ok saveAwsIp(q(0.0.0.0)) eq awsIp;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok saveAwsIp(q(example.org));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok saveAwsDomain(q(example.org));
      ok awsR53a   (q(XXXXX), q(www.example.org), q(22.12.232.1));
      ok awsR53aaaa(q(XXXXX), q(www.example.org), q([1232:1232:1232:1232:1232:1232:1232:1232:]));
    

## saveAwsDomain()

Make the [server](https://en.wikipedia.org/wiki/Server_(computing)) at [Amazon Web Services](http://aws.amazon.com) with the given [domain name](https://en.wikipedia.org/wiki/Domain_name) name the default primary [server](https://en.wikipedia.org/wiki/Server_(computing)) as used by all the methods whose names end in **r** or **Remote**. Returns the given IP address.

**Example:**

      ok saveAwsIp(q(0.0.0.0)) eq awsIp;
      ok saveAwsIp(q(example.org));
    
      ok saveAwsDomain(q(example.org));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok awsR53a   (q(XXXXX), q(www.example.org), q(22.12.232.1));
      ok awsR53aaaa(q(XXXXX), q(www.example.org), q([1232:1232:1232:1232:1232:1232:1232:1232:]));
    

## awsMetaData($item)

Get an item of meta data for the [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) we are currently running on if we are running on an [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) else return a blank [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
       Parameter  Description
    1  $item      Meta data field

**Example:**

      ok awsMetaData(q(instance-id))    eq q(i-06a4b221b30bf7a37);                    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## awsCurrentIp()

Get the [IP address](https://en.wikipedia.org/wiki/IP_address) address of the AWS [server](https://en.wikipedia.org/wiki/Server_(computing)) we are currently running on if we are running on an [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) else return a blank [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
**Example:**

      awsCurrentIp;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      confirmHasCommandLineCommand(q(find));
    
    
      ok awsCurrentIp                   eq q(31.41.59.26);                            # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## awsCurrentInstanceId()

Get the instance id of the [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) we are currently running on if we are running on an [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) else return a blank [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
**Example:**

      ok awsCurrentInstanceId           eq q(i-06a4b221b30bf7a37);                    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## awsCurrentAvailabilityZone()

Get the availability zone of the [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) we are currently running on if we are running on an [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) else return a blank [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
**Example:**

      ok awsCurrentAvailabilityZone     eq q(us-east-2a);                             # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## awsCurrentRegion()

Get the region of the [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) we are currently running on if we are running on an [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) else return a blank [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
**Example:**

      ok awsCurrentRegion               eq q(us-east-2);                              # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## awsCurrentInstanceType()

Get the instance type of the [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) if we are running on an [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) else return a blank [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
**Example:**

      ok awsCurrentInstanceType         eq q(r4.4xlarge);                             # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## awsExecCli($command, %options)

Execute an AWs command and return its response.

       Parameter  Description
    1  $command   Command to execute
    2  %options   Aws cli options

**Example:**

      ok awsExecCli(q(aws [S3](https://aws.amazon.com/s3/) ls)) =~ m(ryffine)i;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $p = awsExecCliJson(q(aws [EC2](https://aws.amazon.com/ec2/) describe-vpcs), region=>q(us-east-1));
      ok $p->Vpcs->[0]->VpcId =~ m(\Avpc-)i;
    

## awsExecCliJson($command, %options)

Execute an AWs command and decode the [Json](https://en.wikipedia.org/wiki/JSON) so produced.

       Parameter  Description
    1  $command   Command to execute
    2  %options   Aws cli options

**Example:**

      ok awsExecCli(q(aws [S3](https://aws.amazon.com/s3/) ls)) =~ m(ryffine)i;
    
      my $p = awsExecCliJson(q(aws [EC2](https://aws.amazon.com/ec2/) describe-vpcs), region=>q(us-east-1));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $p->Vpcs->[0]->VpcId =~ m(\Avpc-)i;
    

## awsEc2DescribeInstances(%options)

Describe the [Amazon Web Services](http://aws.amazon.com) instances running in a **$region**.

       Parameter  Description
    1  %options   Options

**Example:**

      my %options = (region => q(us-east-2), profile=>q(fmc));
    
      my $r = awsEc2DescribeInstances              (%options);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my %i = awsEc2DescribeInstancesGetIPAddresses(%options);
      is_deeply \%i, { "i-068a7176ba9140057" => { "18.221.162.39" => 1 } };
    

## awsEc2DescribeInstancesGetIPAddresses(%options)

Return a [hash](https://en.wikipedia.org/wiki/Hash_table) of {instanceId => public [IP address](https://en.wikipedia.org/wiki/IP_address) address} for all running instances on [Amazon Web Services](http://aws.amazon.com) with [IP address](https://en.wikipedia.org/wiki/IP_address) addresses.

       Parameter  Description
    1  %options   Options

**Example:**

      my %options = (region => q(us-east-2), profile=>q(fmc));
      my $r = awsEc2DescribeInstances              (%options);
    
      my %i = awsEc2DescribeInstancesGetIPAddresses(%options);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply \%i, { "i-068a7176ba9140057" => { "18.221.162.39" => 1 } };
    

## awsEc2InstanceIpAddress($instanceId, %options)

Return the IP address of a named instance on [Amazon Web Services](http://aws.amazon.com) else return **undef**.

       Parameter    Description
    1  $instanceId  Instance id
    2  %options     Options

**Example:**

      ok q(3.33.133.233) eq awsEc2InstanceIpAddress  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        ("i-xxx", region => q(us-east-2), profile=>q(fmc));
    

## awsEc2CreateImage($name, %options)

Create an image snap shot with the specified **$name** of the AWS [server](https://en.wikipedia.org/wiki/Server_(computing)) we are currently running on if we are running on an AWS [server](https://en.wikipedia.org/wiki/Server_(computing)) else return false. It is safe to shut down the instance immediately after initiating the snap shot - the snap continues even though the instance has terminated.

       Parameter  Description
    1  $name      Image name
    2  %options   Options

**Example:**

         awsEc2CreateImage(q(099 Gold));                                              # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## awsEc2FindImagesWithTagValue($value, %options)

Find images with a tag that matches the specified regular expression **$value**.

       Parameter  Description
    1  $value     Regular expression
    2  %options   Options

**Example:**

      is_deeply
    
       [awsEc2FindImagesWithTagValue(qr(boot)i, region=>'us-east-2',  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        profile=>'fmc')],
       ["ami-011b4273c6123ae76"];
    

## awsEc2DescribeImages(%options)

Describe images available.

       Parameter  Description
    1  %options   Options

**Example:**

      awsEc2DescribeImages(region => q(us-east-2), profile=>q(fmc));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## awsCurrentLinuxSpotPrices(%options)

Return {instance type} = cheapest [spot](https://aws.amazon.com/ec2/spot/) price in dollars per hour for the given region.

       Parameter  Description
    1  %options   Options

**Example:**

       awsCurrentLinuxSpotPrices(region => q(us-east-2), profile=>q(fmc));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## awsEc2DescribeInstanceType($instanceType, %options)

Return details of the specified instance type.

       Parameter      Description
    1  $instanceType  Instance type name
    2  %options       Options

**Example:**

      my $i = awsEc2DescribeInstanceType  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       ("m4.large", region=>'us-east-2', profile=>'fmc');
    
      is_deeply $i->{VCpuInfo},
       {DefaultCores          => 1,
        DefaultThreadsPerCore => 2,
        DefaultVCpus          => 2,
        ValidCores            => [1],
        ValidThreadsPerCore   => [1, 2],
        };
    

## awsEc2ReportSpotInstancePrices($instanceTypeRe, %options)

Report the prices of all the [spot](https://aws.amazon.com/ec2/spot/) instances whose type matches a regular expression **$instanceTypeRe**. The report is sorted by price in millidollars per [CPU](https://en.wikipedia.org/wiki/Central_processing_unit) ascending.

       Parameter        Description
    1  $instanceTypeRe  Regular expression for instance type name
    2  %options         Options

**Example:**

      my $a = awsEc2ReportSpotInstancePrices  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       (qr(\.metal), region=>'us-east-2', profile=>'fmc');
      ok $a->report eq <<END;
    CPUs by price
    
    10 instances types found on 2019-12-24 at 22:53:26
    
    Cheapest Instance Type: m5.metal
    Price Per Cpu hour    : 6.65      in millidollars per hour
    
       Column         Description
    1  Instance_Type  Instance type name
    2  Price          Price in millidollars per hour
    3  CPUs           Number of Cpus
    4  Price_per_CPU  The price per CPU in millidollars per hour
    
        Instance_Type  Price  CPUs  Price_per_CPU
     1  m5.metal         638    96           6.65
     2  r5.metal         668    96           6.97
     3  r5d.metal        668    96           6.97
     4  m5d.metal        826    96           8.61
     5  c5d.metal        912    96           9.50
     6  c5.metal        1037    96          10.81
     7  c5n.metal        912    72          12.67
     8  i3.metal        1497    72          20.80
     9  z1d.metal       1339    48          27.90
    10  i3en.metal      3254    96          33.90
    END
    

## awsEc2RequestSpotInstances($count, $instanceType, $ami, $price, $securityGroup, $key, %options)

Request [spot](https://aws.amazon.com/ec2/spot/) instances as long as they can be started within the next minute. Return a [list](https://en.wikipedia.org/wiki/Linked_list) of [spot](https://aws.amazon.com/ec2/spot/) instance request ids one for each instance requested.

       Parameter       Description
    1  $count          Number of instances
    2  $instanceType   Instance type
    3  $ami            AMI
    4  $price          Price in dollars per hour
    5  $securityGroup  Security group
    6  $key            Key name
    7  %options        Options.

**Example:**

      my $r = awsEc2RequestSpotInstances  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       (2, q(t2.micro), "ami-xxx", 0.01, q(xxx), q(yyy),
        region=>'us-east-2', profile=>'fmc');
    

## awsEc2DescribeSpotInstances(%options)

Return a [hash](https://en.wikipedia.org/wiki/Hash_table) {spot instance request => [spot](https://aws.amazon.com/ec2/spot/) instance details} describing the status of active [spot](https://aws.amazon.com/ec2/spot/) instances.

       Parameter  Description
    1  %options   Options.

**Example:**

      my $r = awsEc2DescribeSpotInstances(region => q(us-east-2), profile=>q(fmc));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## awsR53a($zone, $server, $ip, %options)

Create/Update a **A** [Domain Name System](https://en.wikipedia.org/wiki/Domain_Name_System) record for the specified [server](https://en.wikipedia.org/wiki/Server_(computing)). 
       Parameter  Description
    1  $zone      Zone id from R53
    2  $server    Fully qualified [domain name](https://en.wikipedia.org/wiki/Domain_name) name
    3  $ip        Ip address
    4  %options   AWS CLI global options

**Example:**

      ok saveAwsIp(q(0.0.0.0)) eq awsIp;
      ok saveAwsIp(q(example.org));
      ok saveAwsDomain(q(example.org));
    
      ok awsR53a   (q(XXXXX), q(www.example.org), q(22.12.232.1));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok awsR53aaaa(q(XXXXX), q(www.example.org), q([1232:1232:1232:1232:1232:1232:1232:1232:]));
    

## awsR53aaaa($zone, $server, $ip, %options)

Create/Update a **AAAA** [Domain Name System](https://en.wikipedia.org/wiki/Domain_Name_System) record for the specified [server](https://en.wikipedia.org/wiki/Server_(computing)). 
       Parameter  Description
    1  $zone      Zone id from R53
    2  $server    Fully qualified [domain name](https://en.wikipedia.org/wiki/Domain_name) name
    3  $ip        Ip6 address
    4  %options   AWS CLI global options

**Example:**

      ok saveAwsIp(q(0.0.0.0)) eq awsIp;
      ok saveAwsIp(q(example.org));
      ok saveAwsDomain(q(example.org));
      ok awsR53a   (q(XXXXX), q(www.example.org), q(22.12.232.1));
    
      ok awsR53aaaa(q(XXXXX), q(www.example.org), q([1232:1232:1232:1232:1232:1232:1232:1232:]));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## awsEc2Tag($resource, $name, $value, %options)

Tag an elastic compute resource with the supplied tags.

       Parameter  Description
    1  $resource  Resource
    2  $name      Tag name
    3  $value     Tag value
    4  %options   Options.

**Example:**

      awsEc2Tag  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       ("i-xxxx", Name=>q(Conversion), region => q(us-east-2), profile=>q(fmc));
    

## confirmHasCommandLineCommand($cmd, $noComplaints)

Check that the specified b&lt;$cmd> is present on the current system.  Use $ENV{PATH} to add folders containing commands as necessary.

       Parameter      Description
    1  $cmd           Command to check for
    2  $noComplaints  Do not complain if not found if this is true

**Example:**

      awsCurrentIp;
    
      confirmHasCommandLineCommand(q(find));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## numberOfCpus($scale)

Number of cpus scaled by an optional factor - but only if you have nproc. If you do not have nproc but do have a convenient way for determining the number of cpus on your system please let me know.

       Parameter  Description
    1  $scale     Scale factor

**Example:**

    ok numberOfCpus(8) >= 8, 'ddd';                                                   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## ipAddressViaArp($hostName)

Get the [IP address](https://en.wikipedia.org/wiki/IP_address) address of a [server](https://en.wikipedia.org/wiki/Server_(computing)) on the local network by hostname via arp.

       Parameter  Description
    1  $hostName  Host name

**Example:**

      ipAddressViaArp(q(secarias));                                                   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## parseS3BucketAndFolderName($name)

Parse an [S3](https://aws.amazon.com/s3/) bucket/folder name into a bucket and a [folder](https://en.wikipedia.org/wiki/File_folder) name removing any initial s3://.

       Parameter  Description
    1  $name      Bucket/folder name

**Example:**

    if (1)                                                                          
    
     {is_deeply [parseS3BucketAndFolderName(q(s3://bbbb/ffff/dddd/))], [qw(bbbb ffff/dddd/)], q(iii);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseS3BucketAndFolderName(q(s3://bbbb/))],           [qw(bbbb), q()];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseS3BucketAndFolderName(q(     bbbb/))],           [qw(bbbb), q()];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseS3BucketAndFolderName(q(     bbbb))],            [qw(bbbb), q()];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## saveCodeToS3($saveCodeEvery, $folder, $zipFileName, $bucket, $S3Parms)

Save source [code](https://en.wikipedia.org/wiki/Computer_program) every **$saveCodeEvery** seconds by zipping [folder](https://en.wikipedia.org/wiki/File_folder) **$folder** to [zip](https://linux.die.net/man/1/zip) [file](https://en.wikipedia.org/wiki/Computer_file) **$zipFileName** then saving this [zip](https://linux.die.net/man/1/zip) [file](https://en.wikipedia.org/wiki/Computer_file) in the specified [S3](https://aws.amazon.com/s3/) **$bucket** using any additional [S3](https://aws.amazon.com/s3/) parameters in **$S3Parms**.

       Parameter       Description
    1  $saveCodeEvery  Save every seconds
    2  $folder         Folder to save
    3  $zipFileName    Zip [file](https://en.wikipedia.org/wiki/Computer_file) name
    4  $bucket         Bucket/key
    5  $S3Parms        Additional S3 parameters like profile or region as a [string](https://en.wikipedia.org/wiki/String_(computer_science)) 
**Example:**

      saveCodeToS3(1200, q(.), q(projectName), q(bucket/folder), q(--quiet));         # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## addCertificate($file)

Add a certificate to the current [Secure Shell](https://www.ssh.com/ssh) session.

       Parameter  Description
    1  $file      File containing certificate

**Example:**

      addCertificate(fpf(qw(.ssh cert)));                                             # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## hostName()

The name of the host we are running on.

**Example:**

      hostName;                                                                       # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## userId($user)

Get or confirm the [userid](https://en.wikipedia.org/wiki/User_identifier) we are currently running under.

       Parameter  Description
    1  $user      Userid to confirm

**Example:**

      userId;                                                                         # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## awsTranslateText($string, $language, $cacheFolder, $Options)

Translate **$text** from English to a specified **$language** using AWS Translate with the specified global **$options** and return the translated [string](https://en.wikipedia.org/wiki/String_(computer_science)).  Translations are cached in the specified **$cacheFolder** for reuse where feasible.

       Parameter     Description
    1  $string       String to translate
    2  $language     Language [code](https://en.wikipedia.org/wiki/Computer_program)     3  $cacheFolder  Cache [folder](https://en.wikipedia.org/wiki/File_folder)     4  $Options      Aws global options [string](https://en.wikipedia.org/wiki/String_(computer_science)) 
**Example:**

      ok awsTranslateText("Hello", "it", ".translations/") eq q(Ciao);                # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

# AWS parallel

Parallel computing across multiple instances running on [Amazon Web Services](http://aws.amazon.com).

## onAws()

Returns 1 if we are on AWS else return 0.

**Example:**

      ok  onAws;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok !onAwsSecondary;
      ok  onAwsPrimary;
    

## onAwsPrimary()

Return 1 if we are on [Amazon Web Services](http://aws.amazon.com) and we are on the primary session instance as defined by [awsParallelPrimaryInstanceId](https://metacpan.org/pod/awsParallelPrimaryInstanceId), return 0 if we are on a secondary session instance, else return **undef** if we are not on [Amazon Web Services](http://aws.amazon.com).

**Example:**

      ok  onAws;
      ok !onAwsSecondary;
    
      ok  onAwsPrimary;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## onAwsSecondary()

Return 1 if we are on [Amazon Web Services](http://aws.amazon.com) but we are not on the primary session instance as defined by [awsParallelPrimaryInstanceId](https://metacpan.org/pod/awsParallelPrimaryInstanceId), return 0 if we are on the primary session instance, else return **undef** if we are not on [Amazon Web Services](http://aws.amazon.com).

**Example:**

      ok  onAws;
    
      ok !onAwsSecondary;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok  onAwsPrimary;
    

## awsParallelPrimaryInstanceId(%options)

Return the instance id of the primary instance. The primary instance is the instance at [Amazon Web Services](http://aws.amazon.com) that we communicate with - it controls all the secondary instances that form part of the parallel session. The primary instance is located by finding the first running instance in instance Id order whose Name tag contains the [word](https://en.wikipedia.org/wiki/Doc_(computing)) _primary_. If no running instance has been identified as the primary instance, then the first viable instance is made the primary. The [IP address](https://en.wikipedia.org/wiki/IP_address) address of the primary is recorded in `/tmp/awsPrimaryIpAddress.data` so that it can be quickly reused by [xxxr](https://metacpan.org/pod/xxxr), [copyFolderToRemote](https://metacpan.org/pod/copyFolderToRemote), [mergeFolderFromRemote](https://metacpan.org/pod/mergeFolderFromRemote) etc. Returns the instanceId of the primary instance or **undef** if no suitable instance exists.

       Parameter  Description
    1  %options   Options

**Example:**

      ok "i-xxx" eq awsParallelPrimaryInstanceId  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       (region => q(us-east-2), profile=>q(fmc));
    

## awsParallelSpreadFolder($folder, %options)

On [Amazon Web Services](http://aws.amazon.com): copies a specified **$folder** from the primary instance, see: [awsParallelPrimaryInstanceId](https://metacpan.org/pod/awsParallelPrimaryInstanceId), in parallel, to all the secondary instances in the session. If running locally: copies the specified [folder](https://en.wikipedia.org/wiki/File_folder) to all [Amazon Web Services](http://aws.amazon.com) session instances both primary and secondary.

       Parameter  Description
    1  $folder    Fully qualified [folder](https://en.wikipedia.org/wiki/File_folder) name
    2  %options   Options

**Example:**

      my $d = temporaryFolder;
      my ($f1, $f2) = map {fpe($d, $_, q(txt))} 1..2;
      my $files = {$f1 => "1111", $f2 => "2222"};
    
      writeFiles($files);
    
      awsParallelSpreadFolder($d);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      clearFolder($d, 3);
    
      awsParallelGatherFolder($d);
      my $r = readFiles($d);
      is_deeply $files, $r;
      clearFolder($d, 3);
    

## awsParallelGatherFolder($folder, %options)

On [Amazon Web Services](http://aws.amazon.com): merges all the files in the specified **$folder** on each secondary instance to the corresponding [folder](https://en.wikipedia.org/wiki/File_folder) on the primary instance in parallel.  If running locally: merges all the files in the specified [folder](https://en.wikipedia.org/wiki/File_folder) on each [Amazon Web Services](http://aws.amazon.com) session instance (primary and secondary) to the corresponding [folder](https://en.wikipedia.org/wiki/File_folder) on the local machine.  The [folder](https://en.wikipedia.org/wiki/File_folder) merges are done in parallel which makes it impossible to rely on the order of the merges.

       Parameter  Description
    1  $folder    Fully qualified [folder](https://en.wikipedia.org/wiki/File_folder) name
    2  %options   Options

**Example:**

      my $d = temporaryFolder;
      my ($f1, $f2) = map {fpe($d, $_, q(txt))} 1..2;
      my $files = {$f1 => "1111", $f2 => "2222"};
    
      writeFiles($files);
      awsParallelSpreadFolder($d);
      clearFolder($d, 3);
    
    
      awsParallelGatherFolder($d);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $r = readFiles($d);
      is_deeply $files, $r;
      clearFolder($d, 3);
    

## awsParallelPrimaryIpAddress(%options)

Return the IP addresses of any primary instance on [Amazon Web Services](http://aws.amazon.com).

       Parameter  Description
    1  %options   Options

**Example:**

      ok awsParallelPrimaryIpAddress eq      q(3.1.4.4);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [awsParallelSecondaryIpAddresses], [qw(3.1.4.5 3.1.4.6)];
    
      is_deeply [awsParallelIpAddresses],  [qw(3.1.4.4 3.1.4.5 3.1.4.6)];
    

## awsParallelSecondaryIpAddresses(%options)

Return a [list](https://en.wikipedia.org/wiki/Linked_list) containing the IP addresses of any secondary instances on [Amazon Web Services](http://aws.amazon.com).

       Parameter  Description
    1  %options   Options

**Example:**

      ok awsParallelPrimaryIpAddress eq      q(3.1.4.4);
    
    
      is_deeply [awsParallelSecondaryIpAddresses], [qw(3.1.4.5 3.1.4.6)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [awsParallelIpAddresses],  [qw(3.1.4.4 3.1.4.5 3.1.4.6)];
    

## awsParallelIpAddresses(%options)

Return the IP addresses of all the [Amazon Web Services](http://aws.amazon.com) session instances.

       Parameter  Description
    1  %options   Options

**Example:**

      ok awsParallelPrimaryIpAddress eq      q(3.1.4.4);
    
      is_deeply [awsParallelSecondaryIpAddresses], [qw(3.1.4.5 3.1.4.6)];
    
    
      is_deeply [awsParallelIpAddresses],  [qw(3.1.4.4 3.1.4.5 3.1.4.6)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## getCodeContext($sub)

Recreate the [code](https://en.wikipedia.org/wiki/Computer_program) context for a referenced [sub](https://perldoc.perl.org/perlsub.html). 
       Parameter  Description
    1  $sub       Sub reference

**Example:**

    ok getCodeContext(\&getCodeContext) =~ m(use strict)ims;                          # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## awsParallelProcessFiles($userData, $parallel, $results, $files, %options)

Process files in parallel across multiple [Amazon Web Services](http://aws.amazon.com) instances if available or in series if not.  The data located by **$userData** is transferred from the primary instance, as determined by [awsParallelPrimaryInstanceId](https://metacpan.org/pod/awsParallelPrimaryInstanceId), to all the secondary instances. **$parallel** contains a reference to a [sub](https://perldoc.perl.org/perlsub.html), parameterized by [array](https://en.wikipedia.org/wiki/Dynamic_array) @\_ = (a copy of the [user](https://en.wikipedia.org/wiki/User_(computing)) data, the name of the [file](https://en.wikipedia.org/wiki/Computer_file) to process), which will be executed upon each session instance including the primary instance to update $userData. **$results** contains a reference to a [sub](https://perldoc.perl.org/perlsub.html), parameterized by [array](https://en.wikipedia.org/wiki/Dynamic_array) @\_ = (the [user](https://en.wikipedia.org/wiki/User_(computing)) data, an [array](https://en.wikipedia.org/wiki/Dynamic_array) of results returned by each execution of $parallel), that will be called on the primary instance to [process](https://en.wikipedia.org/wiki/Process_management_(computing)) the results folders from each instance once their results folders have been copied back and merged into the results [folder](https://en.wikipedia.org/wiki/File_folder) of the primary instance. $results should update its copy of $userData with the information received from each instance. **$files** is a reference to an [array](https://en.wikipedia.org/wiki/Dynamic_array) of the files to be processed: each [file](https://en.wikipedia.org/wiki/Computer_file) will be copied from the primary instance to each of the secondary instances before parallel processing starts. **%options** contains any parameters needed to interact with [EC2](https://aws.amazon.com/ec2/)  via the [Amazon Web Services Command Line Interface](https://aws.amazon.com/cli/).  The returned result is that returned by [sub](https://perldoc.perl.org/perlsub.html) $results.

       Parameter  Description
    1  $userData  User data or [undef](https://perldoc.perl.org/functions/undef.html)     2  $parallel  Parallel [sub](https://perldoc.perl.org/perlsub.html) reference
    3  $results   Series [sub](https://perldoc.perl.org/perlsub.html) reference
    4  $files     [files to process]
    5  %options   Aws cli options.

**Example:**

      my $N = 2001;                                                                 # Number of files to [process](https://en.wikipedia.org/wiki/Process_management_(computing))       my $options = q(region => q(us-east-2), profile=>q(fmc));                     # Aws cli options
      my %options = [eval](http://perldoc.perl.org/functions/eval.html) "($options)";
    
      for my $dir(q(/home/phil/perl/cpan/DataTableText/lib/Data/Table/),            # Folders we will need on [Amazon Web Services](http://aws.amazon.com)                   q(/home/phil/.aws/))
       {awsParallelSpreadFolder($dir, %options);
       }
    
      my $d = temporaryFolder;                                                      # Create a temporary [folder](https://en.wikipedia.org/wiki/File_folder)       my $resultsFile = fpe($d, qw(results data));                                  # Save results in this temporary [file](https://en.wikipedia.org/wiki/Computer_file)     
      if (my $r = execPerlOnRemote(join "
  ",                                       # Execute some [code](https://en.wikipedia.org/wiki/Computer_program) on a [server](https://en.wikipedia.org/wiki/Server_(computing))         getCodeContext(\&awsParallelProcessFilesTestParallel),                      # Get [code](https://en.wikipedia.org/wiki/Computer_program) context of the [sub](https://perldoc.perl.org/perlsub.html) we want to call.
        <<SESSIONLEADER))                                                           # Launch [code](https://en.wikipedia.org/wiki/Computer_program) on session leader
    use Data::Table::Text qw(:all);
    
    
    my \$r = awsParallelProcessFiles                                                # Process files on multiple L<Amazon Web Services|http://aws.amazon.com> instances in parallel  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     ({file=>4, time=>timeStamp},                                                   # User data
      \\\&Data::Table::Text::awsParallelProcessFilesTestParallel,                   # Reference to [code](https://en.wikipedia.org/wiki/Computer_program) to execute in parallel on each session instance
      \\\&Data::Table::Text::awsParallelProcessFilesTestResults,                    # Reference to [code](https://en.wikipedia.org/wiki/Computer_program) to execute in series to merge the results of each parallel computation
      [map {writeFile(fpe(q($d), \$_, qw(txt)), \$_)} 1..$N],                       # Files to [process](https://en.wikipedia.org/wiki/Process_management_(computing))       $options);                                                                    # Aws cli options as we will be running on Aws
    
    storeFile(q($resultsFile), \$r);                                                # Save results in a [file](https://en.wikipedia.org/wiki/Computer_file)     
    SESSIONLEADER
    
       {copyFileFromRemote($resultsFile);                                           # Retrieve [user](https://en.wikipedia.org/wiki/User_(computing)) data
    
        my $userData = retrieveFile($resultsFile);                                  # Recover [user](https://en.wikipedia.org/wiki/User_(computing)) data
        my @i = awsParallelSecondaryIpAddresses(%options);                          # Ip addresses of secondary instances
        my @I = keys $userData->{ip}->%*;
        is_deeply [sort @i], [sort @I];                                             # Each secondary [IP address](https://en.wikipedia.org/wiki/IP_address) address was used
    
        ok $userData->{file}  == 4;                                                 # Prove we can pass data in and get it back
        ok $userData->{merge} == 1 + @i, 'ii';                                      # Number of merges
    
        my %f; my %i;                                                               # Files processed on each [IP address](https://en.wikipedia.org/wiki/IP_address)         for   my $i(sort keys $userData->{ipFile}->%*)                              # Ip
         {for my $f(sort keys $userData->{ipFile}{$i}->%*)                          # File
           {$f{fn($f)}++;                                                           # Files processed
            $i{$i}++;                                                               # Count files on each [IP address](https://en.wikipedia.org/wiki/IP_address)            }
         }
    
        is_deeply \%f, {map {$_=>1} 1..$N};                                         # Check each [file](https://en.wikipedia.org/wiki/Computer_file) was processed
    
        if (1)
         {my @rc; my @ra;                                                           # Range of number of files processed on each [IP address](https://en.wikipedia.org/wiki/IP_address) - computed, actually counted
          my $l = $N/@i-1;                                                          # Lower limit of number of files per IP address
          my $h = $N/@i+1;                                                          # Upper limit of number of files per IP address
          for   my $i(keys %i)
           {my $nc = $i{$i};                                                        # Number of files processed on this [IP address](https://en.wikipedia.org/wiki/IP_address) - computed
            my $na = $userData->{ip}{$i};                                           # Number of files processed on this [IP address](https://en.wikipedia.org/wiki/IP_address) - actually counted
            push @rc, ($nc >= $l and $nc <= $h) ? 1 : 0;                            # 1 - in range, 0 - out of range
            push @ra, ($na >= $l and $na <= $h) ? 1 : 0;                            # 1 - in range, 0 - out of range
           }
          ok @i == [grep](https://en.wikipedia.org/wiki/Grep) {$_} @ra;                                                   # Check each [IP address](https://en.wikipedia.org/wiki/IP_address) processed the expected number of files
          ok @i == [grep](https://en.wikipedia.org/wiki/Grep) {$_} @rc;
         }
    
        ok $userData->{files}{&fpe($d, qw(4 txt))} eq                               # Check the computed MD5 sum for the specified [file](https://en.wikipedia.org/wiki/Computer_file)            q(a87ff679a2f3e71d9181a67b7542122c);
       }
    
    if (0)                                                                           # Process files in series on local machine
     {my $N = 42;
      my $d = temporaryFolder;
    
    
      my $r = awsParallelProcessFiles                                               # Process files in series on local machine  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       ({file => 4},                                                                # User data
        \&Data::Table::Text::awsParallelProcessFilesTestParallel,                   # Code to execute on each session instance including the session leader written as a [string](https://en.wikipedia.org/wiki/String_(computer_science)) because it has to be shipped to each instance
        \&Data::Table::Text::awsParallelProcessFilesTestResults,                    # Code to execute in series on the session leader to analyze the results of the parallel runs
        [map {writeFile(fpe($d, $_, qw(txt)), $_)} 1..$N],                          # Files to [process](https://en.wikipedia.org/wiki/Process_management_(computing))         ());                                                                        # No Aws cli options as we are running locally
    
      ok $r->{file}            ==  4, 'aaa';                                        # Prove we can pass data in and get it back
      ok $r->{merge}           ==  1, 'bbb';                                        # Only one merge as we are running locally
    
      ok $r->{ip}{localHost}   == $N, 'ccc';                                        # Number of files processed locally
      ok keys($r->{files}->%*) == $N;                                               # Number of files processed
      ok $r->{files}{fpe($d, qw(4 txt))} eq q(a87ff679a2f3e71d9181a67b7542122c);    # Check the computed MD5 sum for the specified [file](https://en.wikipedia.org/wiki/Computer_file)     
      clearFolder($d, $N+2);
     }
    

# S3

Work with S3 as if it were a [file](https://en.wikipedia.org/wiki/Computer_file) system.

## s3ListFilesAndSizes($folderOrFile, %options)

Return {file=>size} for all the files in a specified **$folderOrFile** on S3 using the specified **%options** if any.

       Parameter      Description
    1  $folderOrFile  Source on S3 - which will be truncated to a [folder](https://en.wikipedia.org/wiki/File_folder) name
    2  %options       Options

**Example:**

      my %options = (profile => q(fmc));
    
      s3DownloadFolder
       (q(s3://bucket/folder/), q(home/phil/s3/folder/), %options, delete=>1);
    
      s3ZipFolder ( q(home/phil/s3/folder/) => q(s3://bucket/folder/),  %options);
    
      s3ZipFolders({q(home/phil/s3/folder/) => q(s3://bucket/folder/)}, %options);
    
      is_deeply
    
       {s3ListFilesAndSizes(q(s3://salesforce.dita/originals4/images), %options)  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       },
       {"s3://salesforce.dita/originals4/images/business_plan_sections.png" =>
         ["originals4/images/business_plan_sections.png",
          112525,
          "2019-08-13",
          "20:01:10",
         ],
        "s3://salesforce.dita/originals4/images/non-referenced.png" =>
         ["originals4/images/non-referenced.png",
          19076,
          "2019-08-20",
          "01:25:04",
         ],
       };
    
      my $data = q(0123456789);
      my $file = q(s3://salesforce.dita/zzz/111.txt);
    
      if (1)
       {       s3WriteString($file, $data, %options);
        my $r = s3ReadString($file,        %options);
        ok $r eq $data;
       }
    
      if (1)
       {my @r = s3FileExists($file, %options);
        ok $r[0] eq "zzz/111.txt";
        ok $r[1] ==  10;
       }
    
      if (1)
       {my $d = $data x 2;
        my $f = writeFile(undef, $d);
    
        s3WriteFile($file, $f, %options);
        unlink $f;
        s3ReadFile ($file, $f, %options);
        ok readFile($f) eq $d;
        unlink $f;
       }
    

## s3FileExists($file, %options)

Return (name, size, date, time) for a **$file** that exists on S3 else () using the specified **%options** if any.

       Parameter  Description
    1  $file      File on S3 - which will be truncated to a [folder](https://en.wikipedia.org/wiki/File_folder) name
    2  %options   Options

**Example:**

      my %options = (profile => q(fmc));
    
      s3DownloadFolder
       (q(s3://bucket/folder/), q(home/phil/s3/folder/), %options, delete=>1);
    
      s3ZipFolder ( q(home/phil/s3/folder/) => q(s3://bucket/folder/),  %options);
    
      s3ZipFolders({q(home/phil/s3/folder/) => q(s3://bucket/folder/)}, %options);
    
      is_deeply
       {s3ListFilesAndSizes(q(s3://salesforce.dita/originals4/images), %options)
       },
       {"s3://salesforce.dita/originals4/images/business_plan_sections.png" =>
         ["originals4/images/business_plan_sections.png",
          112525,
          "2019-08-13",
          "20:01:10",
         ],
        "s3://salesforce.dita/originals4/images/non-referenced.png" =>
         ["originals4/images/non-referenced.png",
          19076,
          "2019-08-20",
          "01:25:04",
         ],
       };
    
      my $data = q(0123456789);
      my $file = q(s3://salesforce.dita/zzz/111.txt);
    
      if (1)
       {       s3WriteString($file, $data, %options);
        my $r = s3ReadString($file,        %options);
        ok $r eq $data;
       }
    
      if (1)
    
       {my @r = s3FileExists($file, %options);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        ok $r[0] eq "zzz/111.txt";
        ok $r[1] ==  10;
       }
    
      if (1)
       {my $d = $data x 2;
        my $f = writeFile(undef, $d);
    
        s3WriteFile($file, $f, %options);
        unlink $f;
        s3ReadFile ($file, $f, %options);
        ok readFile($f) eq $d;
        unlink $f;
       }
    

## s3WriteFile($fileS3, $fileLocal, %options)

Write to a [file](https://en.wikipedia.org/wiki/Computer_file) **$fileS3** on S3 the contents of a local [file](https://en.wikipedia.org/wiki/Computer_file) **$fileLocal** using the specified **%options** if any.  $fileLocal will be removed if %options contains a key cleanUp with a true value.

       Parameter   Description
    1  $fileS3     File to write to on S3
    2  $fileLocal  String to write into [file](https://en.wikipedia.org/wiki/Computer_file)     3  %options    Options

**Example:**

      my %options = (profile => q(fmc));
    
      s3DownloadFolder
       (q(s3://bucket/folder/), q(home/phil/s3/folder/), %options, delete=>1);
    
      s3ZipFolder ( q(home/phil/s3/folder/) => q(s3://bucket/folder/),  %options);
    
      s3ZipFolders({q(home/phil/s3/folder/) => q(s3://bucket/folder/)}, %options);
    
      is_deeply
       {s3ListFilesAndSizes(q(s3://salesforce.dita/originals4/images), %options)
       },
       {"s3://salesforce.dita/originals4/images/business_plan_sections.png" =>
         ["originals4/images/business_plan_sections.png",
          112525,
          "2019-08-13",
          "20:01:10",
         ],
        "s3://salesforce.dita/originals4/images/non-referenced.png" =>
         ["originals4/images/non-referenced.png",
          19076,
          "2019-08-20",
          "01:25:04",
         ],
       };
    
      my $data = q(0123456789);
      my $file = q(s3://salesforce.dita/zzz/111.txt);
    
      if (1)
       {       s3WriteString($file, $data, %options);
        my $r = s3ReadString($file,        %options);
        ok $r eq $data;
       }
    
      if (1)
       {my @r = s3FileExists($file, %options);
        ok $r[0] eq "zzz/111.txt";
        ok $r[1] ==  10;
       }
    
      if (1)
       {my $d = $data x 2;
        my $f = writeFile(undef, $d);
    
    
        s3WriteFile($file, $f, %options);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        unlink $f;
        s3ReadFile ($file, $f, %options);
        ok readFile($f) eq $d;
        unlink $f;
       }
    

## s3WriteString($file, $string, %options)

Write to a **$file** on S3 the contents of **$string** using the specified **%options** if any.

       Parameter  Description
    1  $file      File to write to on S3
    2  $string    String to write into [file](https://en.wikipedia.org/wiki/Computer_file)     3  %options   Options

**Example:**

      my %options = (profile => q(fmc));
    
      s3DownloadFolder
       (q(s3://bucket/folder/), q(home/phil/s3/folder/), %options, delete=>1);
    
      s3ZipFolder ( q(home/phil/s3/folder/) => q(s3://bucket/folder/),  %options);
    
      s3ZipFolders({q(home/phil/s3/folder/) => q(s3://bucket/folder/)}, %options);
    
      is_deeply
       {s3ListFilesAndSizes(q(s3://salesforce.dita/originals4/images), %options)
       },
       {"s3://salesforce.dita/originals4/images/business_plan_sections.png" =>
         ["originals4/images/business_plan_sections.png",
          112525,
          "2019-08-13",
          "20:01:10",
         ],
        "s3://salesforce.dita/originals4/images/non-referenced.png" =>
         ["originals4/images/non-referenced.png",
          19076,
          "2019-08-20",
          "01:25:04",
         ],
       };
    
      my $data = q(0123456789);
      my $file = q(s3://salesforce.dita/zzz/111.txt);
    
      if (1)
    
       {       s3WriteString($file, $data, %options);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        my $r = s3ReadString($file,        %options);
        ok $r eq $data;
       }
    
      if (1)
       {my @r = s3FileExists($file, %options);
        ok $r[0] eq "zzz/111.txt";
        ok $r[1] ==  10;
       }
    
      if (1)
       {my $d = $data x 2;
        my $f = writeFile(undef, $d);
    
        s3WriteFile($file, $f, %options);
        unlink $f;
        s3ReadFile ($file, $f, %options);
        ok readFile($f) eq $d;
        unlink $f;
       }
    

## s3ReadFile($file, $local, %options)

Read from a **$file** on S3 and write the contents to a local [file](https://en.wikipedia.org/wiki/Computer_file) **$local** using the specified **%options** if any.  Any pre existing [version](https://en.wikipedia.org/wiki/Software_versioning) of the local [file](https://en.wikipedia.org/wiki/Computer_file) $local will be deleted.  Returns whether the local [file](https://en.wikipedia.org/wiki/Computer_file) exists after completion of the download.

       Parameter  Description
    1  $file      File to read from on S3
    2  $local     Local [file](https://en.wikipedia.org/wiki/Computer_file) to write to
    3  %options   Options

**Example:**

      my %options = (profile => q(fmc));
    
      s3DownloadFolder
       (q(s3://bucket/folder/), q(home/phil/s3/folder/), %options, delete=>1);
    
      s3ZipFolder ( q(home/phil/s3/folder/) => q(s3://bucket/folder/),  %options);
    
      s3ZipFolders({q(home/phil/s3/folder/) => q(s3://bucket/folder/)}, %options);
    
      is_deeply
       {s3ListFilesAndSizes(q(s3://salesforce.dita/originals4/images), %options)
       },
       {"s3://salesforce.dita/originals4/images/business_plan_sections.png" =>
         ["originals4/images/business_plan_sections.png",
          112525,
          "2019-08-13",
          "20:01:10",
         ],
        "s3://salesforce.dita/originals4/images/non-referenced.png" =>
         ["originals4/images/non-referenced.png",
          19076,
          "2019-08-20",
          "01:25:04",
         ],
       };
    
      my $data = q(0123456789);
      my $file = q(s3://salesforce.dita/zzz/111.txt);
    
      if (1)
       {       s3WriteString($file, $data, %options);
        my $r = s3ReadString($file,        %options);
        ok $r eq $data;
       }
    
      if (1)
       {my @r = s3FileExists($file, %options);
        ok $r[0] eq "zzz/111.txt";
        ok $r[1] ==  10;
       }
    
      if (1)
       {my $d = $data x 2;
        my $f = writeFile(undef, $d);
    
        s3WriteFile($file, $f, %options);
        unlink $f;
    
        s3ReadFile ($file, $f, %options);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        ok readFile($f) eq $d;
        unlink $f;
       }
    

## s3ReadString($file, %options)

Read from a **$file** on S3 and return the contents as a [string](https://en.wikipedia.org/wiki/String_(computer_science)) using specified **%options** if any.  Any pre existing [version](https://en.wikipedia.org/wiki/Software_versioning) of $local will be deleted.  Returns whether the local [file](https://en.wikipedia.org/wiki/Computer_file) exists after completion of the download.

       Parameter  Description
    1  $file      File to read from on S3
    2  %options   Options

**Example:**

      my %options = (profile => q(fmc));
    
      s3DownloadFolder
       (q(s3://bucket/folder/), q(home/phil/s3/folder/), %options, delete=>1);
    
      s3ZipFolder ( q(home/phil/s3/folder/) => q(s3://bucket/folder/),  %options);
    
      s3ZipFolders({q(home/phil/s3/folder/) => q(s3://bucket/folder/)}, %options);
    
      is_deeply
       {s3ListFilesAndSizes(q(s3://salesforce.dita/originals4/images), %options)
       },
       {"s3://salesforce.dita/originals4/images/business_plan_sections.png" =>
         ["originals4/images/business_plan_sections.png",
          112525,
          "2019-08-13",
          "20:01:10",
         ],
        "s3://salesforce.dita/originals4/images/non-referenced.png" =>
         ["originals4/images/non-referenced.png",
          19076,
          "2019-08-20",
          "01:25:04",
         ],
       };
    
      my $data = q(0123456789);
      my $file = q(s3://salesforce.dita/zzz/111.txt);
    
      if (1)
       {       s3WriteString($file, $data, %options);
    
        my $r = s3ReadString($file,        %options);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        ok $r eq $data;
       }
    
      if (1)
       {my @r = s3FileExists($file, %options);
        ok $r[0] eq "zzz/111.txt";
        ok $r[1] ==  10;
       }
    
      if (1)
       {my $d = $data x 2;
        my $f = writeFile(undef, $d);
    
        s3WriteFile($file, $f, %options);
        unlink $f;
        s3ReadFile ($file, $f, %options);
        ok readFile($f) eq $d;
        unlink $f;
       }
    

## s3DownloadFolder($folder, $local, %options)

Download a specified **$folder** on S3 to a **$local** [folder](https://en.wikipedia.org/wiki/File_folder) using the specified **%options** if any.  Any existing data in the $local [folder](https://en.wikipedia.org/wiki/File_folder) will be will be deleted if delete=>1 is specified as an option. Returns **undef on failure** else the name of the **$local** on success.

       Parameter  Description
    1  $folder    Folder to read from on S3
    2  $local     Local [folder](https://en.wikipedia.org/wiki/File_folder) to write to
    3  %options   Options

**Example:**

      my %options = (profile => q(fmc));
    
    
      s3DownloadFolder  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       (q(s3://bucket/folder/), q(home/phil/s3/folder/), %options, delete=>1);
    
      s3ZipFolder ( q(home/phil/s3/folder/) => q(s3://bucket/folder/),  %options);
    
      s3ZipFolders({q(home/phil/s3/folder/) => q(s3://bucket/folder/)}, %options);
    
      is_deeply
       {s3ListFilesAndSizes(q(s3://salesforce.dita/originals4/images), %options)
       },
       {"s3://salesforce.dita/originals4/images/business_plan_sections.png" =>
         ["originals4/images/business_plan_sections.png",
          112525,
          "2019-08-13",
          "20:01:10",
         ],
        "s3://salesforce.dita/originals4/images/non-referenced.png" =>
         ["originals4/images/non-referenced.png",
          19076,
          "2019-08-20",
          "01:25:04",
         ],
       };
    
      my $data = q(0123456789);
      my $file = q(s3://salesforce.dita/zzz/111.txt);
    
      if (1)
       {       s3WriteString($file, $data, %options);
        my $r = s3ReadString($file,        %options);
        ok $r eq $data;
       }
    
      if (1)
       {my @r = s3FileExists($file, %options);
        ok $r[0] eq "zzz/111.txt";
        ok $r[1] ==  10;
       }
    
      if (1)
       {my $d = $data x 2;
        my $f = writeFile(undef, $d);
    
        s3WriteFile($file, $f, %options);
        unlink $f;
        s3ReadFile ($file, $f, %options);
        ok readFile($f) eq $d;
        unlink $f;
       }
    

## s3ZipFolder($source, $target, %options)

Zip the specified **$source** [folder](https://en.wikipedia.org/wiki/File_folder) and write it to the named **$target** [file](https://en.wikipedia.org/wiki/Computer_file) on S3.

       Parameter  Description
    1  $source    Source [folder](https://en.wikipedia.org/wiki/File_folder)     2  $target    Target [file](https://en.wikipedia.org/wiki/Computer_file) on S3
    3  %options   S3 options

**Example:**

      s3ZipFolder(q(home/phil/r/), q(s3://bucket/r.zip));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my %options = (profile => q(fmc));
    
      s3DownloadFolder
       (q(s3://bucket/folder/), q(home/phil/s3/folder/), %options, delete=>1);
    
    
      s3ZipFolder ( q(home/phil/s3/folder/) => q(s3://bucket/folder/),  %options);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      s3ZipFolders({q(home/phil/s3/folder/) => q(s3://bucket/folder/)}, %options);
    
      is_deeply
       {s3ListFilesAndSizes(q(s3://salesforce.dita/originals4/images), %options)
       },
       {"s3://salesforce.dita/originals4/images/business_plan_sections.png" =>
         ["originals4/images/business_plan_sections.png",
          112525,
          "2019-08-13",
          "20:01:10",
         ],
        "s3://salesforce.dita/originals4/images/non-referenced.png" =>
         ["originals4/images/non-referenced.png",
          19076,
          "2019-08-20",
          "01:25:04",
         ],
       };
    
      my $data = q(0123456789);
      my $file = q(s3://salesforce.dita/zzz/111.txt);
    
      if (1)
       {       s3WriteString($file, $data, %options);
        my $r = s3ReadString($file,        %options);
        ok $r eq $data;
       }
    
      if (1)
       {my @r = s3FileExists($file, %options);
        ok $r[0] eq "zzz/111.txt";
        ok $r[1] ==  10;
       }
    
      if (1)
       {my $d = $data x 2;
        my $f = writeFile(undef, $d);
    
        s3WriteFile($file, $f, %options);
        unlink $f;
        s3ReadFile ($file, $f, %options);
        ok readFile($f) eq $d;
        unlink $f;
       }
    

## s3ZipFolders($map, %options)

Zip local folders and [upload](https://en.wikipedia.org/wiki/Upload) them to S3 in parallel.  **$map** maps source [folder](https://en.wikipedia.org/wiki/File_folder) names on the local machine to target folders on S3. **%options** contains any additional [Amazon Web Services](http://aws.amazon.com) cli options.

       Parameter  Description
    1  $map       Source [folder](https://en.wikipedia.org/wiki/File_folder) to S3 mapping
    2  %options   S3 options

**Example:**

      my %options = (profile => q(fmc));
    
      s3DownloadFolder
       (q(s3://bucket/folder/), q(home/phil/s3/folder/), %options, delete=>1);
    
      s3ZipFolder ( q(home/phil/s3/folder/) => q(s3://bucket/folder/),  %options);
    
    
      s3ZipFolders({q(home/phil/s3/folder/) => q(s3://bucket/folder/)}, %options);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply
       {s3ListFilesAndSizes(q(s3://salesforce.dita/originals4/images), %options)
       },
       {"s3://salesforce.dita/originals4/images/business_plan_sections.png" =>
         ["originals4/images/business_plan_sections.png",
          112525,
          "2019-08-13",
          "20:01:10",
         ],
        "s3://salesforce.dita/originals4/images/non-referenced.png" =>
         ["originals4/images/non-referenced.png",
          19076,
          "2019-08-20",
          "01:25:04",
         ],
       };
    
      my $data = q(0123456789);
      my $file = q(s3://salesforce.dita/zzz/111.txt);
    
      if (1)
       {       s3WriteString($file, $data, %options);
        my $r = s3ReadString($file,        %options);
        ok $r eq $data;
       }
    
      if (1)
       {my @r = s3FileExists($file, %options);
        ok $r[0] eq "zzz/111.txt";
        ok $r[1] ==  10;
       }
    
      if (1)
       {my $d = $data x 2;
        my $f = writeFile(undef, $d);
    
        s3WriteFile($file, $f, %options);
        unlink $f;
        s3ReadFile ($file, $f, %options);
        ok readFile($f) eq $d;
        unlink $f;
       }
    

# GitHub

Simple interactions with [GitHub](https://github.com/philiprbrenan) - for more complex interactions please use [GitHub::Crud](https://metacpan.org/pod/GitHub%3A%3ACrud).

## downloadGitHubPublicRepo($user, $repo)

Get the contents of a public repo on GitHub and place them in a temporary [folder](https://en.wikipedia.org/wiki/File_folder) whose name is returned to the caller or [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) if no such repo exists.

       Parameter  Description
    1  $user      GitHub [user](https://en.wikipedia.org/wiki/User_(computing))     2  $repo      GitHub repo

**Example:**

         downloadGitHubPublicRepo(q(philiprbrenan), q(psr));                          # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## downloadGitHubPublicRepoFile($user, $repo, $file)

Get the contents of a **$user** **$repo** **$file** from  a public repo on GitHub and return them as a [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
       Parameter  Description
    1  $user      GitHub [user](https://en.wikipedia.org/wiki/User_(computing))     2  $repo      GitHub repository
    3  $file      File name in repository

**Example:**

      ok &downloadGitHubPublicRepoFile(qw(philiprbrenan pleaseChangeDita index.html));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

# FPGAs

Load [Verilog](https://en.wikipedia.org/wiki/Verilog) into a field programmable gate [array](https://en.wikipedia.org/wiki/Dynamic_array) 
## fpgaGowin(%options)

Compile [Verilog](https://en.wikipedia.org/wiki/Verilog) to a gowin device.

       Parameter  Description
    1  %options   Parameters

# Processes

Start [processes](https://en.wikipedia.org/wiki/Process_management_(computing)), wait for them to terminate and retrieve their results

## startProcess($sub, $pids, $maximum)

Start new [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) while the number of child [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) recorded in **%$pids** is less than the specified **$maximum**.  Use [waitForAllStartedProcessesToFinish](#waitforallstartedprocessestofinish) to wait for all these [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) to finish.

       Parameter  Description
    1  $sub       Sub to start
    2  $pids      Hash in which to record the [process](https://en.wikipedia.org/wiki/Process_management_(computing)) ids
    3  $maximum   Maximum number of [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) to run at a time

**Example:**

      my %pids;
    
      sub{startProcess {} %pids, 1; ok 1 >= keys %pids}->() for 1..8;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      waitForAllStartedProcessesToFinish(%pids);
      ok !keys(%pids)
    

## waitForAllStartedProcessesToFinish($pids)

Wait until all the [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) started by [startProcess](#startprocess) have finished.

       Parameter  Description
    1  $pids      Hash of started [process](https://en.wikipedia.org/wiki/Process_management_(computing)) ids

**Example:**

      my %pids;
      sub{startProcess {} %pids, 1; ok 1 >= keys %pids}->() for 1..8;
    
      waitForAllStartedProcessesToFinish(%pids);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok !keys(%pids)
    

## newProcessStarter($maximumNumberOfProcesses, %options)

Create a new [process starter](#data-table-text-starter-definition) with which to start parallel [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) up to a specified **$maximumNumberOfProcesses** maximum number of parallel [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) at a time, wait for all the started [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) to finish and then optionally retrieve their saved results as an [array](https://en.wikipedia.org/wiki/Dynamic_array) from the [folder](https://en.wikipedia.org/wiki/File_folder) named by **$transferArea**.

       Parameter                  Description
    1  $maximumNumberOfProcesses  Maximum number of [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) to start
    2  %options                   Options

**Example:**

    if (1)                                                                            
     {my $N = 100;
      my $l = q(logFile.txt);
      unlink $l;
    
      my $s = newProcessStarter(4);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $s->processingTitle   = q(Test processes);
         $s->totalToBeStarted  = $N;
         $s->processingLogFile = $l;
    
      for my $i(1..$N)
       {Data::Table::Text::Starter::start($s, sub{$i*$i});
       }
    
      is_deeply
       [sort {$a <=> $b} Data::Table::Text::Starter::finish($s)],
       [map {$_**2} 1..$N];
    
      ok readFile($l) =~ m(Finished $N [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) for: Test processes)s;
      clearFolder($s->transferArea, 1e3);
      unlink $l;
     }
    

## Data::Table::Text::Starter::start($starter, $sub)

Start a new [process](https://en.wikipedia.org/wiki/Process_management_(computing)) to run the specified **$sub**.

       Parameter  Description
    1  $starter   Starter
    2  $sub       Sub to be run.

**Example:**

    if (1)                                                                            
     {my $N = 100;
      my $l = q(logFile.txt);
      unlink $l;
      my $s = newProcessStarter(4);
         $s->processingTitle   = q(Test processes);
         $s->totalToBeStarted  = $N;
         $s->processingLogFile = $l;
    
      for my $i(1..$N)
    
       {Data::Table::Text::Starter::start($s, sub{$i*$i});  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       }
    
      is_deeply
       [sort {$a <=> $b} Data::Table::Text::Starter::finish($s)],
       [map {$_**2} 1..$N];
    
      ok readFile($l) =~ m(Finished $N [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) for: Test processes)s;
      clearFolder($s->transferArea, 1e3);
      unlink $l;
     }
    

## Data::Table::Text::Starter::finish($starter)

Wait for all started [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) to finish and return their results as an [array](https://en.wikipedia.org/wiki/Dynamic_array). 
       Parameter  Description
    1  $starter   Starter

**Example:**

    if (1)                                                                            
     {my $N = 100;
      my $l = q(logFile.txt);
      unlink $l;
      my $s = newProcessStarter(4);
         $s->processingTitle   = q(Test processes);
         $s->totalToBeStarted  = $N;
         $s->processingLogFile = $l;
    
      for my $i(1..$N)
       {Data::Table::Text::Starter::start($s, sub{$i*$i});
       }
    
      is_deeply
    
       [sort {$a <=> $b} Data::Table::Text::Starter::finish($s)],  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       [map {$_**2} 1..$N];
    
      ok readFile($l) =~ m(Finished $N [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) for: Test processes)s;
      clearFolder($s->transferArea, 1e3);
      unlink $l;
     }
    

## squareArray(@array)

Create a two dimensional square [array](https://en.wikipedia.org/wiki/Dynamic_array) from a one dimensional linear [array](https://en.wikipedia.org/wiki/Dynamic_array). 
       Parameter  Description
    1  @array     Array

**Example:**

      is_deeply [squareArray @{[1..4]} ], [[1, 2], [3, 4]];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [squareArray @{[1..22]}],  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       [[1 .. 5], [6 .. 10], [11 .. 15], [16 .. 20], [21, 22]];
    
    
      is_deeply [1..$_], [deSquareArray squareArray @{[1..$_]}] for 1..22;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok $_ == countSquareArray         squareArray @{[1..$_]}  for 222;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [rectangularArray(3, 1..11)],
                [[1, 4, 7, 10],
                 [2, 5, 8, 11],
                 [3, 6, 9]];
    
      is_deeply [rectangularArray(3, 1..12)],
                [[1, 4, 7, 10],
                 [2, 5, 8, 11],
                 [3, 6, 9, 12]];
    
      is_deeply [rectangularArray(3, 1..13)],
                [[1, 4, 7, 10, 13],
                 [2, 5, 8, 11],
                 [3, 6, 9, 12]];
    
      is_deeply [rectangularArray2(3, 1..5)],
                [[1, 2, 3],
                 [4, 5]];
    
      is_deeply [rectangularArray2(3, 1..6)],
                [[1, 2, 3],
                 [4, 5, 6]];
    
      is_deeply [rectangularArray2(3, 1..7)],
                [[1, 2, 3],
                 [4, 5, 6],
                 [7]];
    

## deSquareArray(@square)

Create a one dimensional [array](https://en.wikipedia.org/wiki/Dynamic_array) from a two dimensional [array](https://en.wikipedia.org/wiki/Dynamic_array) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array). 
       Parameter  Description
    1  @square    Array of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) 
**Example:**

      is_deeply [squareArray @{[1..4]} ], [[1, 2], [3, 4]];
      is_deeply [squareArray @{[1..22]}],
       [[1 .. 5], [6 .. 10], [11 .. 15], [16 .. 20], [21, 22]];
    
    
      is_deeply [1..$_], [deSquareArray squareArray @{[1..$_]}] for 1..22;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $_ == countSquareArray         squareArray @{[1..$_]}  for 222;
    
      is_deeply [rectangularArray(3, 1..11)],
                [[1, 4, 7, 10],
                 [2, 5, 8, 11],
                 [3, 6, 9]];
    
      is_deeply [rectangularArray(3, 1..12)],
                [[1, 4, 7, 10],
                 [2, 5, 8, 11],
                 [3, 6, 9, 12]];
    
      is_deeply [rectangularArray(3, 1..13)],
                [[1, 4, 7, 10, 13],
                 [2, 5, 8, 11],
                 [3, 6, 9, 12]];
    
      is_deeply [rectangularArray2(3, 1..5)],
                [[1, 2, 3],
                 [4, 5]];
    
      is_deeply [rectangularArray2(3, 1..6)],
                [[1, 2, 3],
                 [4, 5, 6]];
    
      is_deeply [rectangularArray2(3, 1..7)],
                [[1, 2, 3],
                 [4, 5, 6],
                 [7]];
    

## rectangularArray($first, @array)

Create a two dimensional rectangular [array](https://en.wikipedia.org/wiki/Dynamic_array) whose first dimension is **$first** from a one dimensional linear [array](https://en.wikipedia.org/wiki/Dynamic_array). 
       Parameter  Description
    1  $first     First dimension size
    2  @array     Array

**Example:**

      is_deeply [squareArray @{[1..4]} ], [[1, 2], [3, 4]];
      is_deeply [squareArray @{[1..22]}],
       [[1 .. 5], [6 .. 10], [11 .. 15], [16 .. 20], [21, 22]];
    
      is_deeply [1..$_], [deSquareArray squareArray @{[1..$_]}] for 1..22;
      ok $_ == countSquareArray         squareArray @{[1..$_]}  for 222;
    
    
      is_deeply [rectangularArray(3, 1..11)],  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                [[1, 4, 7, 10],
                 [2, 5, 8, 11],
                 [3, 6, 9]];
    
    
      is_deeply [rectangularArray(3, 1..12)],  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                [[1, 4, 7, 10],
                 [2, 5, 8, 11],
                 [3, 6, 9, 12]];
    
    
      is_deeply [rectangularArray(3, 1..13)],  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                [[1, 4, 7, 10, 13],
                 [2, 5, 8, 11],
                 [3, 6, 9, 12]];
    
      is_deeply [rectangularArray2(3, 1..5)],
                [[1, 2, 3],
                 [4, 5]];
    
      is_deeply [rectangularArray2(3, 1..6)],
                [[1, 2, 3],
                 [4, 5, 6]];
    
      is_deeply [rectangularArray2(3, 1..7)],
                [[1, 2, 3],
                 [4, 5, 6],
                 [7]];
    

## rectangularArray2($second, @array)

Create a two dimensional rectangular [array](https://en.wikipedia.org/wiki/Dynamic_array) whose second dimension is **$second** from a one dimensional linear [array](https://en.wikipedia.org/wiki/Dynamic_array). 
       Parameter  Description
    1  $second    Second dimension size
    2  @array     Array

**Example:**

      is_deeply [squareArray @{[1..4]} ], [[1, 2], [3, 4]];
      is_deeply [squareArray @{[1..22]}],
       [[1 .. 5], [6 .. 10], [11 .. 15], [16 .. 20], [21, 22]];
    
      is_deeply [1..$_], [deSquareArray squareArray @{[1..$_]}] for 1..22;
      ok $_ == countSquareArray         squareArray @{[1..$_]}  for 222;
    
      is_deeply [rectangularArray(3, 1..11)],
                [[1, 4, 7, 10],
                 [2, 5, 8, 11],
                 [3, 6, 9]];
    
      is_deeply [rectangularArray(3, 1..12)],
                [[1, 4, 7, 10],
                 [2, 5, 8, 11],
                 [3, 6, 9, 12]];
    
      is_deeply [rectangularArray(3, 1..13)],
                [[1, 4, 7, 10, 13],
                 [2, 5, 8, 11],
                 [3, 6, 9, 12]];
    
    
      is_deeply [rectangularArray2(3, 1..5)],  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                [[1, 2, 3],
                 [4, 5]];
    
    
      is_deeply [rectangularArray2(3, 1..6)],  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                [[1, 2, 3],
                 [4, 5, 6]];
    
    
      is_deeply [rectangularArray2(3, 1..7)],  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                [[1, 2, 3],
                 [4, 5, 6],
                 [7]];
    

## callSubInParallel($sub)

Call a [sub](https://perldoc.perl.org/perlsub.html) reference in parallel to avoid [memory](https://en.wikipedia.org/wiki/Computer_memory) fragmentation and return its results.

       Parameter  Description
    1  $sub       Sub reference

**Example:**

      my %a = (a=>1, b=>2);
    
      my %b = callSubInParallel {return %a};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply \%a, \%b;
    
      my $f = temporaryFile;
      ok -e $f;
    
      my $a = callSubInOverlappedParallel
        [sub](https://perldoc.perl.org/perlsub.html) {$a{a}++; owf($f, "Hello World")},
        [sub](https://perldoc.perl.org/perlsub.html) {q(aaaa)};
    
      ok $a           =~ m(aaaa)i;
      ok $a{a}        == 1;
      ok readFile($f) =~ m(Hello World)i;
    

## callSubInOverlappedParallel($child, $parent)

Call the **$child** [sub](https://perldoc.perl.org/perlsub.html) reference in parallel in a separate child [process](https://en.wikipedia.org/wiki/Process_management_(computing)) and ignore its results while calling the **$parent** [sub](https://perldoc.perl.org/perlsub.html) reference in the parent [process](https://en.wikipedia.org/wiki/Process_management_(computing)) and returning its results.

       Parameter  Description
    1  $child     Sub reference to call in child [process](https://en.wikipedia.org/wiki/Process_management_(computing))     2  $parent    Sub reference to call in parent [process](https://en.wikipedia.org/wiki/Process_management_(computing)) 
**Example:**

      my %a = (a=>1, b=>2);
      my %b = callSubInParallel {return %a};
      is_deeply \%a, \%b;
    
      my $f = temporaryFile;
      ok -e $f;
    
    
      my $a = callSubInOverlappedParallel  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        [sub](https://perldoc.perl.org/perlsub.html) {$a{a}++; owf($f, "Hello World")},
        [sub](https://perldoc.perl.org/perlsub.html) {q(aaaa)};
    
      ok $a           =~ m(aaaa)i;
      ok $a{a}        == 1;
      ok readFile($f) =~ m(Hello World)i;
    

## runInParallel($maximumNumberOfProcesses, $parallel, $results, @array)

Process the elements of an [array](https://en.wikipedia.org/wiki/Dynamic_array) in parallel using a maximum of **$maximumNumberOfProcesses** [processes](https://en.wikipedia.org/wiki/Process_management_(computing)). [sub](https://perldoc.perl.org/perlsub.html) **&$parallel** is forked to [process](https://en.wikipedia.org/wiki/Process_management_(computing)) each [array](https://en.wikipedia.org/wiki/Dynamic_array) element in parallel. The results returned by the forked copies of &$parallel are presented as a single [array](https://en.wikipedia.org/wiki/Dynamic_array) to [sub](https://perldoc.perl.org/perlsub.html) **&$results** which is run in series. **@array** contains the elements to be processed. Returns the result returned by &$results.

       Parameter                  Description
    1  $maximumNumberOfProcesses  Maximum number of [processes](https://en.wikipedia.org/wiki/Process_management_(computing))     2  $parallel                  Parallel [sub](https://perldoc.perl.org/perlsub.html)     3  $results                   Optional [sub](https://perldoc.perl.org/perlsub.html) to [process](https://en.wikipedia.org/wiki/Process_management_(computing)) results
    4  @array                     Array of items to [process](https://en.wikipedia.org/wiki/Process_management_(computing)) 
**Example:**

      my @N = 1..100;
      my $N = 100;
      my $R = 0; $R += $_*$_ for 1..$N;
    
      ok 338350 == $R;
    
      ok $R == runInSquareRootParallel
         (4,
          [sub](https://perldoc.perl.org/perlsub.html) {my ($p) = @_; $p * $p},
          [sub](https://perldoc.perl.org/perlsub.html) {my $p = 0; $p += $_ for @_; $p},
          @{[1..$N]}
         );
    
    
      ok $R == runInParallel  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         (4,
          [sub](https://perldoc.perl.org/perlsub.html) {my ($p) = @_; $p * $p},
          [sub](https://perldoc.perl.org/perlsub.html) {my $p = 0; $p += $_ for @_; $p},
          @{[1..$N]}
         );
    

## runInSquareRootParallel($maximumNumberOfProcesses, $parallel, $results, @array)

Process the elements of an [array](https://en.wikipedia.org/wiki/Dynamic_array) in square root parallel using a maximum of **$maximumNumberOfProcesses** [processes](https://en.wikipedia.org/wiki/Process_management_(computing)). [sub](https://perldoc.perl.org/perlsub.html) **&$parallel** is forked to [process](https://en.wikipedia.org/wiki/Process_management_(computing)) each block of [array](https://en.wikipedia.org/wiki/Dynamic_array) elements in parallel. The results returned by the forked copies of &$parallel are presented as a single [array](https://en.wikipedia.org/wiki/Dynamic_array) to [sub](https://perldoc.perl.org/perlsub.html) **&$results** which is run in series. **@array** contains the elements to be processed. Returns the result returned by &$results.

       Parameter                  Description
    1  $maximumNumberOfProcesses  Maximum number of [processes](https://en.wikipedia.org/wiki/Process_management_(computing))     2  $parallel                  Parallel [sub](https://perldoc.perl.org/perlsub.html)     3  $results                   Results [sub](https://perldoc.perl.org/perlsub.html)     4  @array                     Array of items to [process](https://en.wikipedia.org/wiki/Process_management_(computing)) 
**Example:**

      my @N = 1..100;
      my $N = 100;
      my $R = 0; $R += $_*$_ for 1..$N;
    
      ok 338350 == $R;
    
    
      ok $R == runInSquareRootParallel  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         (4,
          [sub](https://perldoc.perl.org/perlsub.html) {my ($p) = @_; $p * $p},
          [sub](https://perldoc.perl.org/perlsub.html) {my $p = 0; $p += $_ for @_; $p},
          @{[1..$N]}
         );
    
      ok $R == runInParallel
         (4,
          [sub](https://perldoc.perl.org/perlsub.html) {my ($p) = @_; $p * $p},
          [sub](https://perldoc.perl.org/perlsub.html) {my $p = 0; $p += $_ for @_; $p},
          @{[1..$N]}
         );
    

## packBySize($N, @sizes)

Given **$N** buckets and a [list](https://en.wikipedia.org/wiki/Linked_list) **@sizes** of (\[size of [file](https://en.wikipedia.org/wiki/Computer_file), name of file\]...) pack the [file](https://en.wikipedia.org/wiki/Computer_file) names into buckets so that each bucket contains approximately the same number of bytes.  In general this is an NP problem.  Packing largest first into emptiest bucket produces an N\*\*2 heuristic if the buckets are scanned linearly, or N\*log(N) if a binary [tree](https://en.wikipedia.org/wiki/Tree_(data_structure)) is used.  This solution is a compromise at N\*\*3/2 which has the benefits of simple [code](https://en.wikipedia.org/wiki/Computer_program) yet good performance.  Returns (\[file names ...\]).

       Parameter  Description
    1  $N         Number of buckets
    2  @sizes     Sizes

**Example:**

      my $M = 7;
      my $N = 15;
    
      my @b = packBySize($M, map {[$_, $_]} 1..$N);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my @B; my $B = 0;
      for my $b(@b)
       {my $n = 0;
        for(@$b)
         {$n += $_;
          $B += $_;
         }
        push @B, $n;
       }
      ok $B == $N * ($N + 1) / 2;
      is_deeply [@B], [16, 20, 16, 18, 16, 18, 16];
    

## processSizesInParallel($parallel, $results, @sizes)

Process items of known size in parallel using (8 \* the number of CPUs) [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) with the [process](https://en.wikipedia.org/wiki/Process_management_(computing)) each item is assigned to depending on the size of the item so that each [process](https://en.wikipedia.org/wiki/Process_management_(computing)) is loaded with approximately the same number of bytes of data in total from the items it [processes](https://en.wikipedia.org/wiki/Process_management_(computing)). 

Each item is processed by [sub](https://perldoc.perl.org/perlsub.html) **$parallel** and the results of processing all items is processed by **$results** where the items are taken from **@sizes**. Each &$parallel() receives an item from @files. &$results() receives an [array](https://en.wikipedia.org/wiki/Dynamic_array) of all the results returned by &$parallel().

       Parameter  Description
    1  $parallel  Parallel [sub](https://perldoc.perl.org/perlsub.html)     2  $results   Results [sub](https://perldoc.perl.org/perlsub.html)     3  @sizes     Array of [size; item] to [process](https://en.wikipedia.org/wiki/Process_management_(computing)) by size

**Example:**

      my $d = temporaryFolder;
      my @f = map {owf(fpe($d, $_, q(txt)), 'X' x ($_ ** 2 % 11))} 1..9;
    
      my $f = fileLargestSize(@f);
      ok fn($f) eq '3', 'aaa';
    
    #  my $b = folderSize($d);                                                       # Needs du
    #  ok $b > 0, 'bbb';
    
      my $c = processFilesInParallel(
        [sub](https://perldoc.perl.org/perlsub.html)          {my ($file) = @_;
          [&fileSize($file), $file]
         },
        [sub](https://perldoc.perl.org/perlsub.html)          {scalar @_;
         }, (@f) x 12);
    
      ok 108 == $c, 'cc11';
    
    
      my $C = processSizesInParallel  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        [sub](https://perldoc.perl.org/perlsub.html)          {my ($file) = @_;
          [&fileSize($file), $file]
         },
        [sub](https://perldoc.perl.org/perlsub.html)          {scalar @_;
         }, map {[fileSize($_), $_]} (@f) x 12;
    
      ok 108 == $C, 'cc2';
    
      my $J = processJavaFilesInParallel
        [sub](https://perldoc.perl.org/perlsub.html)          {my ($file) = @_;
          [&fileSize($file), $file]
         },
        [sub](https://perldoc.perl.org/perlsub.html)          {scalar @_;
         }, (@f) x 12;
    
      ok 108 == $J, 'cc3';
    
      clearFolder($d, 12);
    

## processFilesInParallel($parallel, $results, @files)

Process files in parallel using (8 \* the number of CPUs) [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) with the [process](https://en.wikipedia.org/wiki/Process_management_(computing)) each [file](https://en.wikipedia.org/wiki/Computer_file) is assigned to depending on the size of the [file](https://en.wikipedia.org/wiki/Computer_file) so that each [process](https://en.wikipedia.org/wiki/Process_management_(computing)) is loaded with approximately the same number of bytes of data in total from the files it [processes](https://en.wikipedia.org/wiki/Process_management_(computing)). 

Each [file](https://en.wikipedia.org/wiki/Computer_file) is processed by [sub](https://perldoc.perl.org/perlsub.html) **$parallel** and the results of processing all files is processed by **$results** where the files are taken from **@files**. Each **&$parallel** receives a [file](https://en.wikipedia.org/wiki/Computer_file) from **@files**. **&$results** receives an [array](https://en.wikipedia.org/wiki/Dynamic_array) of all the results returned by **&$parallel**.

       Parameter  Description
    1  $parallel  Parallel [sub](https://perldoc.perl.org/perlsub.html)     2  $results   Results [sub](https://perldoc.perl.org/perlsub.html)     3  @files     Array of files to [process](https://en.wikipedia.org/wiki/Process_management_(computing)) by size

**Example:**

      my $d = temporaryFolder;
      my @f = map {owf(fpe($d, $_, q(txt)), 'X' x ($_ ** 2 % 11))} 1..9;
    
      my $f = fileLargestSize(@f);
      ok fn($f) eq '3', 'aaa';
    
    #  my $b = folderSize($d);                                                       # Needs du
    #  ok $b > 0, 'bbb';
    
    
      my $c = processFilesInParallel(  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        [sub](https://perldoc.perl.org/perlsub.html)          {my ($file) = @_;
          [&fileSize($file), $file]
         },
        [sub](https://perldoc.perl.org/perlsub.html)          {scalar @_;
         }, (@f) x 12);
    
      ok 108 == $c, 'cc11';
    
      my $C = processSizesInParallel
        [sub](https://perldoc.perl.org/perlsub.html)          {my ($file) = @_;
          [&fileSize($file), $file]
         },
        [sub](https://perldoc.perl.org/perlsub.html)          {scalar @_;
         }, map {[fileSize($_), $_]} (@f) x 12;
    
      ok 108 == $C, 'cc2';
    
      my $J = processJavaFilesInParallel
        [sub](https://perldoc.perl.org/perlsub.html)          {my ($file) = @_;
          [&fileSize($file), $file]
         },
        [sub](https://perldoc.perl.org/perlsub.html)          {scalar @_;
         }, (@f) x 12;
    
      ok 108 == $J, 'cc3';
    
      clearFolder($d, 12);
    

## processJavaFilesInParallel($parallel, $results, @files)

Process [Java](https://en.wikipedia.org/wiki/Java_(programming_language)) files of known size in parallel using (the number of CPUs) [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) with the [process](https://en.wikipedia.org/wiki/Process_management_(computing)) each item is assigned to depending on the size of the [Java](https://en.wikipedia.org/wiki/Java_(programming_language)) item so that each [process](https://en.wikipedia.org/wiki/Process_management_(computing)) is loaded with approximately the same number of bytes of data in total from the [Java](https://en.wikipedia.org/wiki/Java_(programming_language)) files it [processes](https://en.wikipedia.org/wiki/Process_management_(computing)). 

Each [Java](https://en.wikipedia.org/wiki/Java_(programming_language)) item is processed by [sub](https://perldoc.perl.org/perlsub.html) **$parallel** and the results of processing all [Java](https://en.wikipedia.org/wiki/Java_(programming_language)) files is processed by **$results** where the [Java](https://en.wikipedia.org/wiki/Java_(programming_language)) files are taken from **@sizes**. Each &$parallel() receives a [Java](https://en.wikipedia.org/wiki/Java_(programming_language)) item from @files. &$results() receives an [array](https://en.wikipedia.org/wiki/Dynamic_array) of all the results returned by &$parallel().

       Parameter  Description
    1  $parallel  Parallel [sub](https://perldoc.perl.org/perlsub.html)     2  $results   Results [sub](https://perldoc.perl.org/perlsub.html)     3  @files     Array of [size; [Java](https://en.wikipedia.org/wiki/Java_(programming_language)) item] to [process](https://en.wikipedia.org/wiki/Process_management_(computing)) by size

**Example:**

      my $d = temporaryFolder;
      my @f = map {owf(fpe($d, $_, q(txt)), 'X' x ($_ ** 2 % 11))} 1..9;
    
      my $f = fileLargestSize(@f);
      ok fn($f) eq '3', 'aaa';
    
    #  my $b = folderSize($d);                                                       # Needs du
    #  ok $b > 0, 'bbb';
    
      my $c = processFilesInParallel(
        [sub](https://perldoc.perl.org/perlsub.html)          {my ($file) = @_;
          [&fileSize($file), $file]
         },
        [sub](https://perldoc.perl.org/perlsub.html)          {scalar @_;
         }, (@f) x 12);
    
      ok 108 == $c, 'cc11';
    
      my $C = processSizesInParallel
        [sub](https://perldoc.perl.org/perlsub.html)          {my ($file) = @_;
          [&fileSize($file), $file]
         },
        [sub](https://perldoc.perl.org/perlsub.html)          {scalar @_;
         }, map {[fileSize($_), $_]} (@f) x 12;
    
      ok 108 == $C, 'cc2';
    
    
      my $J = processJavaFilesInParallel  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        [sub](https://perldoc.perl.org/perlsub.html)          {my ($file) = @_;
          [&fileSize($file), $file]
         },
        [sub](https://perldoc.perl.org/perlsub.html)          {scalar @_;
         }, (@f) x 12;
    
      ok 108 == $J, 'cc3';
    
      clearFolder($d, 12);
    

## syncFromS3InParallel($maxSize, $source, $target, $Profile, $options)

Download from [S3](https://aws.amazon.com/s3/) by using "aws [S3](https://aws.amazon.com/s3/) sync --exclude '\*' --include '...'" in parallel to sync collections of two or more files no greater then **$maxSize** or single files greater than $maxSize from the **$source** [folder](https://en.wikipedia.org/wiki/File_folder) on [S3](https://aws.amazon.com/s3/) to the local [folder](https://en.wikipedia.org/wiki/File_folder) **$target** using the specified **$Profile** and **$options** - then execute the entire command again without the --exclude and --include options in series which might now run faster due to the prior downloads.

       Parameter  Description
    1  $maxSize   The maximum collection size
    2  $source    The source [folder](https://en.wikipedia.org/wiki/File_folder) on S3
    3  $target    The target [folder](https://en.wikipedia.org/wiki/File_folder) locally
    4  $Profile   Aws cli profile
    5  $options   Aws cli options

**Example:**

    if (0)                                                                           
    
     {syncFromS3InParallel 1e5,  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        q(xxx/originals3/),
        q(/home/phil/xxx/),
        q(phil), q(--quiet);
    
      syncToS3InParallel 1e5,
        q(/home/phil/xxx/),
        q(xxx/originals3/),
        q(phil), q(--quiet);
     }
    

## syncToS3InParallel($maxSize, $source, $target, $Profile, $options)

Upload to [S3](https://aws.amazon.com/s3/) by using "aws [S3](https://aws.amazon.com/s3/) sync --exclude '\*' --include '...'" in parallel to sync collections of two or more files no greater then **$maxSize** or single files greater than $maxSize from the **$source** [folder](https://en.wikipedia.org/wiki/File_folder) locally to the target [folder](https://en.wikipedia.org/wiki/File_folder) **$target** on [S3](https://aws.amazon.com/s3/) using the specified **$Profile** and **$options** - then execute the entire command again without the --exclude and --include options in series which might now run faster due to the prior uploads.

       Parameter  Description
    1  $maxSize   The maximum collection size
    2  $source    The target [folder](https://en.wikipedia.org/wiki/File_folder) locally
    3  $target    The source [folder](https://en.wikipedia.org/wiki/File_folder) on S3
    4  $Profile   Aws cli profile
    5  $options   Aws cli options

**Example:**

    if (0)                                                                           
     {syncFromS3InParallel 1e5,
        q(xxx/originals3/),
        q(/home/phil/xxx/),
        q(phil), q(--quiet);
    
    
      syncToS3InParallel 1e5,  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        q(/home/phil/xxx/),
        q(xxx/originals3/),
        q(phil), q(--quiet);
     }
    

## childPids($p)

Recursively [find](https://en.wikipedia.org/wiki/Find_(Unix)) the pids of all the [sub](https://perldoc.perl.org/perlsub.html) [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) of a **$process** and all their [sub](https://perldoc.perl.org/perlsub.html) [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) and so on returning the specified pid and all its child pids as a [list](https://en.wikipedia.org/wiki/Linked_list). 
       Parameter  Description
    1  $p         Process

**Example:**

      is_deeply [childPids(2702)], [2702..2705];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## newServiceIncarnation($service, $file)

Create a new service incarnation to record the start up of a new instance of a service and return the description as a [Data::Exchange::Service Definition hash](#data-exchange-service-definition).

       Parameter  Description
    1  $service   Service name
    2  $file      Optional details [file](https://en.wikipedia.org/wiki/Computer_file) 
**Example:**

    if (1)                                                                           
    
     {my $s = newServiceIncarnation("aaa", q(bbb.txt));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply $s->check, $s;
    
      my $t = newServiceIncarnation("aaa", q(bbb.txt));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply $t->check, $t;
      ok $t->start >= $s->start+1;
      ok !$s->check(1);
      unlink q(bbb.txt);
     }
    

## Data::Exchange::Service::check($service, $continue)

Check that we are the current incarnation of the named service with details obtained from [newServiceIncarnation](#newserviceincarnation). If the optional **$continue** flag has been set then return the service details if this is the current service incarnation else **undef**. Otherwise if the **$continue** flag is false [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) unless this is the current service incarnation thus bringing the earlier [version](https://en.wikipedia.org/wiki/Software_versioning) of this service to an abrupt end.

       Parameter  Description
    1  $service   Current service details
    2  $continue  Return result if B<$continue> is true else [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) if the service has been replaced

**Example:**

    if (1)                                                                           
     {my $s = newServiceIncarnation("aaa", q(bbb.txt));
      is_deeply $s->check, $s;
      my $t = newServiceIncarnation("aaa", q(bbb.txt));
      is_deeply $t->check, $t;
      ok $t->start >= $s->start+1;
      ok !$s->check(1);
      unlink q(bbb.txt);
     }
    

# Conversions

Perform various conversions from STDIN to STDOUT

## convertPerlToJavaScript($in, $out)

Convert Perl to Javascript.

       Parameter  Description
    1  $in        Input [file](https://en.wikipedia.org/wiki/Computer_file) name or STDIN if [undef](https://perldoc.perl.org/functions/undef.html)     2  $out       Output [file](https://en.wikipedia.org/wiki/Computer_file) name or STDOUT if undefined

**Example:**

    if (1)                                                                          
     {my $i = writeTempFile(<<'END');
    [sub](https://perldoc.perl.org/perlsub.html) test($$)                                                                    #P A [test](https://en.wikipedia.org/wiki/Software_testing) method.
     {my ($file, $data) = @_;                                                       # Parameter 1, parameter 2
      if (fullyQualifiedFile($file)) {return qq($data)}                             # File is already fully qualified
     } # [test](https://en.wikipedia.org/wiki/Software_testing)     

# Documentation

Extract, format and update [documentation](https://en.wikipedia.org/wiki/Software_documentation) for a [Perl](http://www.perl.org/) [module](https://en.wikipedia.org/wiki/Modular_programming). 
## parseDitaRef($ref, $File, $TopicId)

Parse a [Dita](http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html) reference **$ref** into its components (file name, topic id, id) . Optionally supply a base [file](https://en.wikipedia.org/wiki/Computer_file) name **$File**> to make the the [file](https://en.wikipedia.org/wiki/Computer_file) component absolute and/or a a default the topic id **$TopicId** to use if the topic id is not present in the reference.

       Parameter  Description
    1  $ref       Reference to [parse](https://en.wikipedia.org/wiki/Parsing)     2  $File      Default absolute [file](https://en.wikipedia.org/wiki/Computer_file)     3  $TopicId   Default topic id

**Example:**

      is_deeply [parseDitaRef(q(a#b/c))], [qw(a b c)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseDitaRef(q(a#./c))], [q(a), q(), q(c)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseDitaRef(q(a#/c))],  [q(a), q(), q(c)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseDitaRef(q(a#c))],   [q(a), q(), q(c)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseDitaRef(q(#b/c))],  [q(),  qw(b c)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseDitaRef(q(#b))],    [q(),  q(), q(b)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseDitaRef(q(#./c))],  [q(),  q(), q(c)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseDitaRef(q(#/c))],   [q(),  q(), q(c)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      is_deeply [parseDitaRef(q(#c))],    [q(),  q(), q(c)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## parseXmlDocType($string)

Parse an [Xml](https://en.wikipedia.org/wiki/XML) DOCTYPE and return a [hash](https://en.wikipedia.org/wiki/Hash_table) indicating its components.

       Parameter  Description
    1  $string    String containing a DOCTYPE

**Example:**

    if (1)                                                                          
    
     {is_deeply parseXmlDocType(<<END),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    <!DOCTYPE reference PUBLIC "-//OASIS//DTD DITA Reference//EN" "reference.dtd">
    .
    END
       {localDtd => "reference.dtd",
        public   => 1,
        publicId => "-//OASIS//DTD DITA Reference//EN",
        root     => "reference",
       };
    
    
      is_deeply parseXmlDocType(<<END),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    .
    <!DOCTYPE [concept](http://docs.oasis-open.org/dita/dita/v1.3/errata02/os/complete/part3-all-inclusive/langRef/technicalContent/concept.html#concept) PUBLIC "-//OASIS//DTD DITA Task//EN" "concept.dtd" []>
    .
    )),
    END
         {localDtd => "concept.dtd",
          public   => 1,
          publicId => "-//OASIS//DTD DITA Task//EN",
          root     => "concept",
         };
     }
    

## reportSettings($sourceFile, $reportFile)

Report the current values of parameterless subs.

       Parameter    Description
    1  $sourceFile  Source [file](https://en.wikipedia.org/wiki/Computer_file)     2  $reportFile  Optional report [file](https://en.wikipedia.org/wiki/Computer_file) 
**Example:**

    reportSettings($0);                                                               # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## reportAttributes($sourceFile)

Report the attributes present in a **$sourceFile**.

       Parameter    Description
    1  $sourceFile  Source [file](https://en.wikipedia.org/wiki/Computer_file) 
**Example:**

      my $d = temporaryFile;
    
      my $f = writeFile(undef, <<'END'.<<END2);
    #!perl -I/home/phil/perl/cpan/DataTableText/lib/
    use Data::Table::Text qw(reportAttributeSettings);
    [sub](https://perldoc.perl.org/perlsub.html) attribute {1}                                                               # An attribute.
    [sub](https://perldoc.perl.org/perlsub.html) replaceable($)                                                              #r A replaceable method.
     {
    

## reportAttributeSettings($reportFile)

Report the current values of the attribute methods in the calling [file](https://en.wikipedia.org/wiki/Computer_file) and optionally write the report to **$reportFile**. Return the text of the report.

       Parameter    Description
    1  $reportFile  Optional report [file](https://en.wikipedia.org/wiki/Computer_file) 
**Example:**

      my $d = temporaryFile;
    
      my $f = writeFile(undef, <<'END'.<<END2);
    #!perl -I/home/phil/perl/cpan/DataTableText/lib/
    
    use Data::Table::Text qw(reportAttributeSettings);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    [sub](https://perldoc.perl.org/perlsub.html) attribute {1}                                                               # An attribute.
    [sub](https://perldoc.perl.org/perlsub.html) replaceable($)                                                              #r A replaceable method.
     {
    

## reportReplacableMethods($sourceFile)

Report the replaceable methods marked with #r in a **$sourceFile**.

       Parameter    Description
    1  $sourceFile  Source [file](https://en.wikipedia.org/wiki/Computer_file) 
**Example:**

      my $d = temporaryFile;
    
      my $f = writeFile(undef, <<'END'.<<END2);
    #!perl -I/home/phil/perl/cpan/DataTableText/lib/
    use Data::Table::Text qw(reportAttributeSettings);
    [sub](https://perldoc.perl.org/perlsub.html) attribute {1}                                                               # An attribute.
    [sub](https://perldoc.perl.org/perlsub.html) replaceable($)                                                              #r A replaceable method.
     {
    
    
    [sub](https://perldoc.perl.org/perlsub.html) reportReplacableMethods($)                                                   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     {my ($sourceFile) = @_;                                                        # Source [file](https://en.wikipedia.org/wiki/Computer_file)       my $s = readFile($sourceFile);
      my %s;
      for my $l(split /
  /, $s)                                                     # Find the attribute subs
       {if ($l =~ m(\Asub\s*(\w+).*?#\w*r\w*\s+(.*)\Z))
         {$s{$1} = $2;
         }
       }
      \%s
     }
    

## reportExportableMethods($sourceFile)

Report the exportable methods marked with #e in a **$sourceFile**.

       Parameter    Description
    1  $sourceFile  Source [file](https://en.wikipedia.org/wiki/Computer_file) 
**Example:**

      my $d = temporaryFile;
    
      my $f = writeFile(undef, <<'END'.<<END2);
    #!perl -I/home/phil/perl/cpan/DataTableText/lib/
    use Data::Table::Text qw(reportAttributeSettings);
    [sub](https://perldoc.perl.org/perlsub.html) attribute {1}                                                               # An attribute.
    [sub](https://perldoc.perl.org/perlsub.html) replaceable($)                                                              #r A replaceable method.
     {
    

## htmlToc($replace, $html)

Generate a [table](https://en.wikipedia.org/wiki/Table_(information)) of contents for some [HTML](https://en.wikipedia.org/wiki/HTML). 
       Parameter  Description
    1  $replace   Sub-string within the [HTML](https://en.wikipedia.org/wiki/HTML) to be replaced with the toc
    2  $html      String of [HTML](https://en.wikipedia.org/wiki/HTML) 
**Example:**

    ok nws(htmlToc("XXXX", <<END)), 'htmlToc'                                         # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    <h1 id="1" otherprops="1">Chapter 1</h1>
      <h2 id="11" otherprops="11">Section 1</h1>
    <h1 id="2" otherprops="2">Chapter 2</h1>
    XXXX
    END
    
      eq nws(<<END);                                                                
    <h1 id="1" otherprops="1">Chapter 1</h1>
      <h2 id="11" otherprops="11">Section 1</h1>
    <h1 id="2" otherprops="2">Chapter 2</h1>
    <table cellspacing=10 border=0>
    <tr><td>&nbsp;
    <tr><td align=right>1<td>&nbsp;&nbsp;&nbsp;&nbsp;<a href="#1">Chapter 1</a>
    <tr><td align=right>2<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="#11">Section 1</a>
    <tr><td>&nbsp;
    <tr><td align=right>3<td>&nbsp;&nbsp;&nbsp;&nbsp;<a href="#2">Chapter 2</a>
    </table>
    END
    

## expandWellKnownWordsAsUrlsInHtmlFormat($string)

Expand words found in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) using the [HTML](https://en.wikipedia.org/wiki/HTML) **a** tag to supply a definition of that [word](https://en.wikipedia.org/wiki/Doc_(computing)). 
       Parameter  Description
    1  $string    String containing [url](https://en.wikipedia.org/wiki/URL) names to expand

**Example:**

      ok expandWellKnownUrlsInDitaFormat(q([GitHub](https://github.com/philiprbrenan))) eq
        q(<xref scope="external" format="html" href="https://github.com/philiprbrenan">GitHub</xref>);
    
      ok expandWellKnownUrlsInHtmlFormat(q([GitHub](https://github.com/philiprbrenan))) eq
        q(<a format="html" href="https://github.com/philiprbrenan">GitHub</a>);
    
      ok expandWellKnownUrlsInPerlFormat(q(L<GitHub|https://github.com/philiprbrenan>)) eq
        q(L<GitHub|https://github.com/philiprbrenan>);
    
      ok expandWellKnownUrlsInPerlFormat(q(github))    eq q(github);
    
      ok expandWellKnownUrlsInHtmlFromPerl(q(L<GitHub|https://github.com/philiprbrenan>)) eq
        q(<a format="html" href="https://github.com/philiprbrenan">GitHub</a>);
    
    
      is_deeply expandWellKnownWordsAsUrlsInHtmlFormat(q(go to [GitHub](https://github.com/philiprbrenan) and press enter.)),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        q(go to <a href="https://github.com/philiprbrenan">GitHub</a> and press enter.), 'ex1';
    
      is_deeply expandWellKnownWordsAsUrlsInMdFormat(q(go to [GitHub](https://github.com/philiprbrenan) and press enter.)),
        q(go to [GitHub](https://github.com/philiprbrenan) and press enter.), 'ex2';
    
      ok expandWellKnownUrlsInPod2Html(<<END) eq [eval](http://perldoc.perl.org/functions/eval.html) '"aaa

bbb
"';
  aaa [GitHub](https://github.com/philiprbrenan) bbb
  END

## expandWellKnownWordsAsUrlsInMdFormat($string)

Expand words found in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) using the md [url](https://en.wikipedia.org/wiki/URL) to supply a definition of that [word](https://en.wikipedia.org/wiki/Doc_(computing)). 
       Parameter  Description
    1  $string    String containing [url](https://en.wikipedia.org/wiki/URL) names to expand

**Example:**

      ok expandWellKnownUrlsInDitaFormat(q([GitHub](https://github.com/philiprbrenan))) eq
        q(<xref scope="external" format="html" href="https://github.com/philiprbrenan">GitHub</xref>);
    
      ok expandWellKnownUrlsInHtmlFormat(q([GitHub](https://github.com/philiprbrenan))) eq
        q(<a format="html" href="https://github.com/philiprbrenan">GitHub</a>);
    
      ok expandWellKnownUrlsInPerlFormat(q(L<GitHub|https://github.com/philiprbrenan>)) eq
        q(L<GitHub|https://github.com/philiprbrenan>);
    
      ok expandWellKnownUrlsInPerlFormat(q(github))    eq q(github);
    
      ok expandWellKnownUrlsInHtmlFromPerl(q(L<GitHub|https://github.com/philiprbrenan>)) eq
        q(<a format="html" href="https://github.com/philiprbrenan">GitHub</a>);
    
      is_deeply expandWellKnownWordsAsUrlsInHtmlFormat(q(go to [GitHub](https://github.com/philiprbrenan) and press enter.)),
        q(go to <a href="https://github.com/philiprbrenan">GitHub</a> and press enter.), 'ex1';
    
    
      is_deeply expandWellKnownWordsAsUrlsInMdFormat(q(go to [GitHub](https://github.com/philiprbrenan) and press enter.)),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        q(go to [GitHub](https://github.com/philiprbrenan) and press enter.), 'ex2';
    
      ok expandWellKnownUrlsInPod2Html(<<END) eq [eval](http://perldoc.perl.org/functions/eval.html) '"aaa

bbb
"';
  aaa [GitHub](https://github.com/philiprbrenan) bbb
  END

## expandWellKnownUrlsInPerlFormat($string)

Expand short [url](https://en.wikipedia.org/wiki/URL) names found in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) in the format L&lt;url-name> using the Perl POD syntax.

       Parameter  Description
    1  $string    String containing [url](https://en.wikipedia.org/wiki/URL) names to expand

**Example:**

      ok expandWellKnownUrlsInDitaFormat(q([GitHub](https://github.com/philiprbrenan))) eq
        q(<xref scope="external" format="html" href="https://github.com/philiprbrenan">GitHub</xref>);
    
      ok expandWellKnownUrlsInHtmlFormat(q([GitHub](https://github.com/philiprbrenan))) eq
        q(<a format="html" href="https://github.com/philiprbrenan">GitHub</a>);
    
    
      ok expandWellKnownUrlsInPerlFormat(q(L<GitHub|https://github.com/philiprbrenan>)) eq  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        q(L<GitHub|https://github.com/philiprbrenan>);
    
    
      ok expandWellKnownUrlsInPerlFormat(q(github))    eq q(github);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ok expandWellKnownUrlsInHtmlFromPerl(q(L<GitHub|https://github.com/philiprbrenan>)) eq
        q(<a format="html" href="https://github.com/philiprbrenan">GitHub</a>);
    
      is_deeply expandWellKnownWordsAsUrlsInHtmlFormat(q(go to [GitHub](https://github.com/philiprbrenan) and press enter.)),
        q(go to <a href="https://github.com/philiprbrenan">GitHub</a> and press enter.), 'ex1';
    
      is_deeply expandWellKnownWordsAsUrlsInMdFormat(q(go to [GitHub](https://github.com/philiprbrenan) and press enter.)),
        q(go to [GitHub](https://github.com/philiprbrenan) and press enter.), 'ex2';
    
      ok expandWellKnownUrlsInPod2Html(<<END) eq [eval](http://perldoc.perl.org/functions/eval.html) '"aaa

bbb
"';
  aaa [GitHub](https://github.com/philiprbrenan) bbb
  END

## expandWellKnownUrlsInHtmlFormat($string)

Expand short [url](https://en.wikipedia.org/wiki/URL) names found in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) in the format L\[url-name\] using the [HTML](https://en.wikipedia.org/wiki/HTML) **a** tag.

       Parameter  Description
    1  $string    String containing [url](https://en.wikipedia.org/wiki/URL) names to expand

**Example:**

      ok expandWellKnownUrlsInDitaFormat(q([GitHub](https://github.com/philiprbrenan))) eq
        q(<xref scope="external" format="html" href="https://github.com/philiprbrenan">GitHub</xref>);
    
    
      ok expandWellKnownUrlsInHtmlFormat(q([GitHub](https://github.com/philiprbrenan))) eq  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        q(<a format="html" href="https://github.com/philiprbrenan">GitHub</a>);
    
      ok expandWellKnownUrlsInPerlFormat(q(L<GitHub|https://github.com/philiprbrenan>)) eq
        q(L<GitHub|https://github.com/philiprbrenan>);
    
      ok expandWellKnownUrlsInPerlFormat(q(github))    eq q(github);
    
      ok expandWellKnownUrlsInHtmlFromPerl(q(L<GitHub|https://github.com/philiprbrenan>)) eq
        q(<a format="html" href="https://github.com/philiprbrenan">GitHub</a>);
    
      is_deeply expandWellKnownWordsAsUrlsInHtmlFormat(q(go to [GitHub](https://github.com/philiprbrenan) and press enter.)),
        q(go to <a href="https://github.com/philiprbrenan">GitHub</a> and press enter.), 'ex1';
    
      is_deeply expandWellKnownWordsAsUrlsInMdFormat(q(go to [GitHub](https://github.com/philiprbrenan) and press enter.)),
        q(go to [GitHub](https://github.com/philiprbrenan) and press enter.), 'ex2';
    
      ok expandWellKnownUrlsInPod2Html(<<END) eq [eval](http://perldoc.perl.org/functions/eval.html) '"aaa

bbb
"';
  aaa [GitHub](https://github.com/philiprbrenan) bbb
  END

## expandWellKnownUrlsInHtmlFromPerl($string)

Expand short [url](https://en.wikipedia.org/wiki/URL) names found in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) in the format L\[url-name\] using the [HTML](https://en.wikipedia.org/wiki/HTML) **a** tag.

       Parameter  Description
    1  $string    String containing [url](https://en.wikipedia.org/wiki/URL) names to expand

**Example:**

      ok expandWellKnownUrlsInDitaFormat(q([GitHub](https://github.com/philiprbrenan))) eq
        q(<xref scope="external" format="html" href="https://github.com/philiprbrenan">GitHub</xref>);
    
      ok expandWellKnownUrlsInHtmlFormat(q([GitHub](https://github.com/philiprbrenan))) eq
        q(<a format="html" href="https://github.com/philiprbrenan">GitHub</a>);
    
      ok expandWellKnownUrlsInPerlFormat(q(L<GitHub|https://github.com/philiprbrenan>)) eq
        q(L<GitHub|https://github.com/philiprbrenan>);
    
      ok expandWellKnownUrlsInPerlFormat(q(github))    eq q(github);
    
    
      ok expandWellKnownUrlsInHtmlFromPerl(q(L<GitHub|https://github.com/philiprbrenan>)) eq  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        q(<a format="html" href="https://github.com/philiprbrenan">GitHub</a>);
    
      is_deeply expandWellKnownWordsAsUrlsInHtmlFormat(q(go to [GitHub](https://github.com/philiprbrenan) and press enter.)),
        q(go to <a href="https://github.com/philiprbrenan">GitHub</a> and press enter.), 'ex1';
    
      is_deeply expandWellKnownWordsAsUrlsInMdFormat(q(go to [GitHub](https://github.com/philiprbrenan) and press enter.)),
        q(go to [GitHub](https://github.com/philiprbrenan) and press enter.), 'ex2';
    
      ok expandWellKnownUrlsInPod2Html(<<END) eq [eval](http://perldoc.perl.org/functions/eval.html) '"aaa

bbb
"';
  aaa [GitHub](https://github.com/philiprbrenan) bbb
  END

## expandWellKnownUrlsInPod2Html($string)

Expand short [url](https://en.wikipedia.org/wiki/URL) names found in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) in the format =begin [HTML](https://en.wikipedia.org/wiki/HTML) format.

       Parameter  Description
    1  $string    String containing [url](https://en.wikipedia.org/wiki/URL) names to expand

**Example:**

      ok expandWellKnownUrlsInDitaFormat(q([GitHub](https://github.com/philiprbrenan))) eq
        q(<xref scope="external" format="html" href="https://github.com/philiprbrenan">GitHub</xref>);
    
      ok expandWellKnownUrlsInHtmlFormat(q([GitHub](https://github.com/philiprbrenan))) eq
        q(<a format="html" href="https://github.com/philiprbrenan">GitHub</a>);
    
      ok expandWellKnownUrlsInPerlFormat(q(L<GitHub|https://github.com/philiprbrenan>)) eq
        q(L<GitHub|https://github.com/philiprbrenan>);
    
      ok expandWellKnownUrlsInPerlFormat(q(github))    eq q(github);
    
      ok expandWellKnownUrlsInHtmlFromPerl(q(L<GitHub|https://github.com/philiprbrenan>)) eq
        q(<a format="html" href="https://github.com/philiprbrenan">GitHub</a>);
    
      is_deeply expandWellKnownWordsAsUrlsInHtmlFormat(q(go to [GitHub](https://github.com/philiprbrenan) and press enter.)),
        q(go to <a href="https://github.com/philiprbrenan">GitHub</a> and press enter.), 'ex1';
    
      is_deeply expandWellKnownWordsAsUrlsInMdFormat(q(go to [GitHub](https://github.com/philiprbrenan) and press enter.)),
        q(go to [GitHub](https://github.com/philiprbrenan) and press enter.), 'ex2';
    
    
      ok expandWellKnownUrlsInPod2Html(<<END) eq [eval](http://perldoc.perl.org/functions/eval.html) '"aaa

bbb
"';  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    aaa L<GitHub|https://github.com/philiprbrenan> bbb
    END
    

## expandWellKnownUrlsInDitaFormat($string)

Expand short [url](https://en.wikipedia.org/wiki/URL) names found in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) in the format L\[url-name\] in the L\[Dita\] **xref**format.

       Parameter  Description
    1  $string    String containing [url](https://en.wikipedia.org/wiki/URL) names to expand

**Example:**

      ok expandWellKnownUrlsInDitaFormat(q([GitHub](https://github.com/philiprbrenan))) eq  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        q(<xref scope="external" format="html" href="https://github.com/philiprbrenan">GitHub</xref>);
    
      ok expandWellKnownUrlsInHtmlFormat(q([GitHub](https://github.com/philiprbrenan))) eq
        q(<a format="html" href="https://github.com/philiprbrenan">GitHub</a>);
    
      ok expandWellKnownUrlsInPerlFormat(q(L<GitHub|https://github.com/philiprbrenan>)) eq
        q(L<GitHub|https://github.com/philiprbrenan>);
    
      ok expandWellKnownUrlsInPerlFormat(q(github))    eq q(github);
    
      ok expandWellKnownUrlsInHtmlFromPerl(q(L<GitHub|https://github.com/philiprbrenan>)) eq
        q(<a format="html" href="https://github.com/philiprbrenan">GitHub</a>);
    
      is_deeply expandWellKnownWordsAsUrlsInHtmlFormat(q(go to [GitHub](https://github.com/philiprbrenan) and press enter.)),
        q(go to <a href="https://github.com/philiprbrenan">GitHub</a> and press enter.), 'ex1';
    
      is_deeply expandWellKnownWordsAsUrlsInMdFormat(q(go to [GitHub](https://github.com/philiprbrenan) and press enter.)),
        q(go to [GitHub](https://github.com/philiprbrenan) and press enter.), 'ex2';
    
      ok expandWellKnownUrlsInPod2Html(<<END) eq [eval](http://perldoc.perl.org/functions/eval.html) '"aaa

bbb
"';
  aaa [GitHub](https://github.com/philiprbrenan) bbb
  END

## expandNewLinesInDocumentation($s)

Expand new lines in [documentation](https://en.wikipedia.org/wiki/Software_documentation), specifically 
 for new line and 

    for two new lines.

        Parameter  Description
     1  $s         String to be expanded

**Example:**

    ok expandNewLinesInDocumentation(q(a

    b
    c
  )) eq <<END;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    a
    
      b
      c
    END
    

## extractCodeBlock($comment, $file)

Extract the block of [code](https://en.wikipedia.org/wiki/Computer_program) delimited by **$comment**, starting at qq($comment-begin), ending at qq($comment-end) from the named **$file** else the current Perl [program](https://en.wikipedia.org/wiki/Computer_program) $0 and return it as a [string](https://en.wikipedia.org/wiki/String_(computer_science)) or [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) if this is not possible.

       Parameter  Description
    1  $comment   Comment delimiting the block of [code](https://en.wikipedia.org/wiki/Computer_program)     2  $file      File to read from if not $0

**Example:**

    ok extractCodeBlock(q(#CODEBLOCK), $INC{"Data/Table/Text.pm"}) eq <<'END';  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $a = 1;
      my $b = 2;
    END
    

## updateDocumentation($perlModule)

Update the [documentation](https://en.wikipedia.org/wiki/Software_documentation) for a Perl [module](https://en.wikipedia.org/wiki/Modular_programming) from the comments in its source [code](https://en.wikipedia.org/wiki/Computer_program). Comments between the lines marked with:

    #Dn title # description

and:

    #D

where n is either 1, 2 or 3 indicating the heading level of the section and the # is in column 1.

Methods are formatted as:

    [sub](https://perldoc.perl.org/perlsub.html) name(signature)      #FLAGS [comment](https://en.wikipedia.org/wiki/Comment_(computer_programming)) describing method
     {my ($parameters) = @_; # comments for each parameter separated by commas.

FLAGS can be chosen from:

- I

    method of interest to new users

- P

    private method

- r

    optionally replaceable method

- R

    required replaceable method

- S

    static method

- X

    [die](http://perldoc.perl.org/functions/die.html) rather than received a returned **undef** result

Other flags will be handed to the method extractDocumentationFlags(flags to [process](https://en.wikipedia.org/wiki/Process_management_(computing)), method name) found in the [file](https://en.wikipedia.org/wiki/Computer_file) being documented, this method should return \[the additional [documentation](https://en.wikipedia.org/wiki/Software_documentation) for the method, the [code](https://en.wikipedia.org/wiki/Computer_program) to implement the flag\].

Text following 'Example:' in the [comment](https://en.wikipedia.org/wiki/Comment_(computer_programming)) (if present) will be placed after the parameters [list](https://en.wikipedia.org/wiki/Linked_list) as an example. Lines containing comments consisting of '#\[T#\]'.methodName will also be aggregated and displayed as examples for that method.

Lines formatted as:

    BEGIN{*source=*target}

starting in column 1 will define a synonym for a method.

Lines formatted as:

    #C emailAddress text

will be aggregated in the acknowledgments section at the end of the [documentation](https://en.wikipedia.org/wiki/Software_documentation). 
The character sequence **\\n** in the [comment](https://en.wikipedia.org/wiki/Comment_(computer_programming)) will be expanded to one new line, **\\m** to two new lines and **L****&lt;$\_**>,**L****&lt;confess**>,**L****&lt;die**>,**L****&lt;eval**>,**L****&lt;lvalueMethod**> to links to the [Perl](http://www.perl.org/) [documentation](https://en.wikipedia.org/wiki/Software_documentation). 
Search for '#D1': in [https://metacpan.org/source/PRBRENAN/Data-Table-Text-20180810/lib/Data/Table/Text.pm](https://metacpan.org/source/PRBRENAN/Data-Table-Text-20180810/lib/Data/Table/Text.pm) to see  more examples of such [documentation](https://en.wikipedia.org/wiki/Software_documentation) in action - although it is quite difficult to see as it looks just like normal comments placed in the [code](https://en.wikipedia.org/wiki/Computer_program). 
Parameters:
.

       Parameter    Description
    1  $perlModule  Optional [file](https://en.wikipedia.org/wiki/Computer_file) name with caller's [file](https://en.wikipedia.org/wiki/Computer_file) being the default

**Example:**

     {my $s = updateDocumentation(<<'END' =~ s(#) (#)gsr =~ s(~) ()gsr);              # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    package Sample::Module;
    
    #D1 Samples                                                                      # Sample methods.
    
    [sub](https://perldoc.perl.org/perlsub.html) sample($@)                                                                  #R Documentation for the:  sample() method.  See also L<Data::Table::Text::sample2|/Data::Table::Text::sample2>. #Tsample .
     {my ($node, @context) = @_;                                                    # Node, optional context
      1
     }
    
    ~BEGIN{*smpl=*sample}
    
    [sub](https://perldoc.perl.org/perlsub.html) Data::Table::Text::sample2(\&@)                                             #PS Documentation for the sample2() method.
     {my ($sub, @context) = @_;                                                     # Sub to call, context.
      1
     }
    
    ok sample(undef, qw(a b c)) == 1;                                               #Tsample
    
    if (1)                                                                          #Tsample
     {ok sample(q(a), qw(a b c))  == 2;
      ok sample(undef, qw(a b c)) == 1;
     }
    
    ok sample(<<END2)) == 1;                                                        #Tsample
    sample data
    END2
    
      ok $s =~ m/=head2 Data::Table::Text::sample2.\$sub, \@context/;               
    

# Hash Definitions

## Data::Exchange::Service Definition

Service details.

### Output fields

#### [file](https://en.wikipedia.org/wiki/Computer_file) 
The [file](https://en.wikipedia.org/wiki/Computer_file) in which the service start details is being recorded.

#### service

The name of the service.

#### start

The time this service was started time plus a minor hack to simplify testing.

## Data::Table::Text::AwsEc2Price Definition

Prices of selected [Amazon Web Services](http://aws.amazon.com) elastic compute instance types

### Output fields

#### cheapestInstance

The instance type that has the lowest CPU cost

#### pricePerCpu

The cost of the cheapest CPU In millidollars per hour

#### report

Report showing the cost of other selected instances

## Data::Table::Text::Python::Documentation Definition

Documentation extracted from Python source files

### Output fields

#### classDefinitions

Class definitions

#### classFiles

Class files

#### comments

Comments for each def

#### errors

Errors encountered

#### parameters

Parameters for each def

#### tests

Tests for each def

#### testsCommon

Common line for tests

## Data::Table::Text::Starter Definition

Process starter definition.

### Input fields

#### processingLogFile

Optional: name of a [file](https://en.wikipedia.org/wiki/Computer_file) to which [process](https://en.wikipedia.org/wiki/Process_management_(computing)) start and end information should be appended

#### processingTitle

Optional: title describing the processing being performed.

#### totalToBeStarted

Optionally: the total number of [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) to be started - if this is supplied then an estimate of the finish time for this processing is printed to the [log](https://en.wikipedia.org/wiki/Log_file) [file](https://en.wikipedia.org/wiki/Computer_file) every time a [process](https://en.wikipedia.org/wiki/Process_management_(computing)) starts or finishes.

### Output fields

#### autoRemoveTransferArea

If true then automatically clear the transfer area at the end of processing.

#### maximumNumberOfProcesses

The maximum number of [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) to start in parallel at one time. If this limit is exceeded, the start of subsequent [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) will be delayed until [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) started earlier have finished.

#### pids

A [hash](https://en.wikipedia.org/wiki/Hash_table) of pids representing [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) started but not yet completed.

#### processFinishTime

Hash of {pid} == time the [process](https://en.wikipedia.org/wiki/Process_management_(computing)) finished.

#### processStartTime

Hash of {pid} == time the [process](https://en.wikipedia.org/wiki/Process_management_(computing)) was started.

#### processingLogFileHandle

Handle for [log](https://en.wikipedia.org/wiki/Log_file) [file](https://en.wikipedia.org/wiki/Computer_file) if a [log](https://en.wikipedia.org/wiki/Log_file) [file](https://en.wikipedia.org/wiki/Computer_file) was supplied

#### resultsArray

Consolidated [array](https://en.wikipedia.org/wiki/Dynamic_array) of results.

#### startTime

Start time

#### transferArea

The name of the [folder](https://en.wikipedia.org/wiki/File_folder) in which files transferring results from the child to the parent [process](https://en.wikipedia.org/wiki/Process_management_(computing)) will be stored.

## TestHash Definition

Definition of a blessed [hash](https://en.wikipedia.org/wiki/Hash_table). 
### Output fields

#### a

Definition of attribute aa.

#### b

Definition of attribute bb.

#### c

Definition of attribute cc.

## Udsr Definition

Package name

### Input fields

#### headerLength

Length of fixed header which carries the length of the following message

#### serverAction

Server action [sub](https://perldoc.perl.org/perlsub.html), which receives a communicator every time a client creates a new connection. If this [server](https://en.wikipedia.org/wiki/Server_(computing)) is going to be started by systemd  as a service with the specified [serverName](https://metacpan.org/pod/serverName) then this is the a actual text of the [code](https://en.wikipedia.org/wiki/Computer_program) that will be installed as a CGI script and run in response to an incoming transaction in a separate [process](https://en.wikipedia.org/wiki/Process_management_(computing)) with the [userid](https://en.wikipedia.org/wiki/User_identifier) set to [serviceUser](https://metacpan.org/pod/serviceUser). It receives the text of the [HTTP](https://en.wikipedia.org/wiki/HTTP) request from the [web browser](https://en.wikipedia.org/wiki/Web_browser) as parameter 1 and should return the text to be sent back to the [web browser](https://en.wikipedia.org/wiki/Web_browser). 
#### serviceName

Service name for [install](https://en.wikipedia.org/wiki/Installation_(computer_programs)) by systemd

#### serviceUser

Userid for service

#### socketPath

Socket [file](https://en.wikipedia.org/wiki/Computer_file) 
### Output fields

#### client

Client [socket](https://en.wikipedia.org/wiki/Network_socket) and connection [socket](https://en.wikipedia.org/wiki/Network_socket) 
#### serverPid

Server pid which can be used to kill the [server](https://en.wikipedia.org/wiki/Server_(computing)) via kill q(kill), $pid

# Attributes

The following is a [list](https://en.wikipedia.org/wiki/Linked_list) of all the attributes in this package.  A method coded
with the same name in your package will over ride the method of the same name
in this package and thus provide your value for the attribute in place of the
default value supplied for this attribute by this package.

## Replaceable Attribute List

awsEc2DescribeInstancesCache awsIpFile nameFromStringMaximumLength wwwHeader 

## awsEc2DescribeInstancesCache

File in which to cache latest results from describe instances to avoid being throttled.

## awsIpFile

File in which to save IP address of primary instance on Aws.

## nameFromStringMaximumLength

Maximum length of a name generated from a [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
## wwwHeader

Html header.

# Private Methods

## onWindows()

Are we on windows.

## onMac()

Are we on mac.

## filePathSeparatorChar()

File path separator.

## denormalizeFolderName($name)

Remove any trailing [folder](https://en.wikipedia.org/wiki/File_folder) separator from a [folder](https://en.wikipedia.org/wiki/File_folder) name.

       Parameter  Description
    1  $name      Folder name

## renormalizeFolderName($name)

Normalize a [folder](https://en.wikipedia.org/wiki/File_folder) name by ensuring it has a single trailing directory separator.

       Parameter  Description
    1  $name      Name

## prefferedFileName($name)

Normalize a [file](https://en.wikipedia.org/wiki/Computer_file) name.

       Parameter  Description
    1  $name      Name

## findAllFilesAndFolders($folder, $dirs)

Find all the files and folders under a [folder](https://en.wikipedia.org/wiki/File_folder). 
       Parameter  Description
    1  $folder    Folder to start the search with
    2  $dirs      True if only folders are required

## readUtf16File($file)

Read a [file](https://en.wikipedia.org/wiki/Computer_file) containing [Unicode](https://en.wikipedia.org/wiki/Unicode) encoded in utf-16.

       Parameter  Description
    1  $file      Name of [file](https://en.wikipedia.org/wiki/Computer_file) to read

## binModeAllUtf8()

Set STDOUT and STDERR to accept [utf8](https://en.wikipedia.org/wiki/UTF-8) without complaint.

**Example:**

      binModeAllUtf8;                                                                 # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## convertImageToJpx690($Source, $target, $Size, $Tiles)

Convert a **$source** image to a **$target** image in jpx format using versions of [Imagemagick](https://www.imagemagick.org/script/index.php) [version](https://en.wikipedia.org/wiki/Software_versioning) 6.9.0 and above. The size in pixels of each jpx tile may be specified by the optional **$Size** parameter which defaults to **256**. **$Tiles** optionally provides an upper limit on the number of each tiles in each dimension.

       Parameter  Description
    1  $Source    Source [file](https://en.wikipedia.org/wiki/Computer_file)     2  $target    Target [folder](https://en.wikipedia.org/wiki/File_folder) (as multiple files will be created)
    3  $Size      Optional size of each tile - defaults to 256
    4  $Tiles     Optional limit on the number of tiles in either dimension

## convertImageToJpx($Source, $target, $Size, $Tiles)

Convert a **$source** image to a **$target** image in jpx format. The size in pixels of each jpx tile may be specified by the optional **$Size** parameter which defaults to **256**. **$Tiles** optionally provides an upper limit on the number of each tiles in each dimension.

       Parameter  Description
    1  $Source    Source [file](https://en.wikipedia.org/wiki/Computer_file)     2  $target    Target [folder](https://en.wikipedia.org/wiki/File_folder) (as multiple files will be created)
    3  $Size      Optional size of each tile - defaults to 256
    4  $Tiles     Optional limit in either direction on the number of tiles

**Example:**

      convertImageToJpx(fpe(qw(a image jpg)), fpe(qw(a image jpg)), 256);             # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    

## setCombination(@s)

Count the elements in sets **@s** represented as [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)) and/or the keys of hashes.

       Parameter  Description
    1  @s         Array of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)) and/or hashes

## formatTableMultiLine($data, $separator)

Tabularize text that has new lines in it.

       Parameter   Description
    1  $data       Reference to an [array](https://en.wikipedia.org/wiki/Dynamic_array) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of data to be formatted as a [table](https://en.wikipedia.org/wiki/Table_(information))     2  $separator  Optional line separator to use instead of new line for each row.

## formatTableClearUpLeft($data)

Blank identical column values up and left.

       Parameter  Description
    1  $data      Array of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) 
## formatTableAA($data, $title, %options)

Tabularize an [array](https://en.wikipedia.org/wiki/Dynamic_array) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array). 
       Parameter  Description
    1  $data      Data to be formatted
    2  $title     Reference to an [array](https://en.wikipedia.org/wiki/Dynamic_array) of titles
    3  %options   Options

**Example:**

     ok formatTable
      ([[1,1,1],[1,1,2],[1,2,2],[1,2,3]], [], clearUpLeft=>1) eq <<END;             # Clear matching columns
    
    1  1  1  1
    2        2
    3     2  2
    4        3
    END
    

## formatTableHA($data, $title)

Tabularize a [hash](https://en.wikipedia.org/wiki/Hash_table) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array). 
       Parameter  Description
    1  $data      Data to be formatted
    2  $title     Optional titles

## formatTableAH($data)

Tabularize an [array](https://en.wikipedia.org/wiki/Dynamic_array) of hashes.

       Parameter  Description
    1  $data      Data to be formatted

## formatTableHH($data)

Tabularize a [hash](https://en.wikipedia.org/wiki/Hash_table) of hashes.

       Parameter  Description
    1  $data      Data to be formatted

## formatTableA($data, $title)

Tabularize an [array](https://en.wikipedia.org/wiki/Dynamic_array). 
       Parameter  Description
    1  $data      Data to be formatted
    2  $title     Optional title

## formatTableH($data, $title)

Tabularize a [hash](https://en.wikipedia.org/wiki/Hash_table). 
       Parameter  Description
    1  $data      Data to be formatted
    2  $title     Optional title

## formatTableCheckKeys()

Options available for formatting tables.

## reloadHashes2($d, $progress)

Ensures that all the hashes within a tower of data structures have LValue methods to get and set their current keys.

       Parameter  Description
    1  $d         Data structure
    2  $progress  Progress

## showHashes2($d, $keys, $progress)

Create a map of all the keys within all the hashes within a tower of data structures.

       Parameter  Description
    1  $d         Data structure
    2  $keys      Keys found
    3  $progress  Progress

## showHashes($d)

Create a map of all the keys within all the hashes within a tower of data structures.

       Parameter  Description
    1  $d         Data structure

## newUdsr(@parms)

Create a communicator - a means to communicate between [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) on the same machine via [Udsr::read](#udsr-read) and [Udsr::write](#udsr-write).

       Parameter  Description
    1  @parms     Attributes per L<Udsr Definition|/Udsr Definition>

## awsInstanceId(%options)

Create an instance-id from the specified **%options**.

       Parameter  Description
    1  %options   Options

## awsProfile(%options)

Create a profile keyword from the specified **%options**.

       Parameter  Description
    1  %options   Options

## awsRegion(%options)

Create a region keyword from the specified **%options**.

       Parameter  Description
    1  %options   Options

## getCCompiler()

Return the name of the C compiler on this system.

## getNumberOfCpus()

Number of cpus.

## saveSourceToS3($aws, $saveIntervalInSeconds)

Save source [code](https://en.wikipedia.org/wiki/Computer_program). 
       Parameter               Description
    1  $aws                    Aws target [file](https://en.wikipedia.org/wiki/Computer_file) and keywords
    2  $saveIntervalInSeconds  Save internal

## awsParallelProcessFilesTestParallel($userData, $file)

Test running on [Amazon Web Services](http://aws.amazon.com) in parallel.

       Parameter  Description
    1  $userData  User data
    2  $file      File to [process](https://en.wikipedia.org/wiki/Process_management_(computing)). 
**Example:**

      my $N = 2001;                                                                 # Number of files to [process](https://en.wikipedia.org/wiki/Process_management_(computing))       my $options = q(region => q(us-east-2), profile=>q(fmc));                     # Aws cli options
      my %options = [eval](http://perldoc.perl.org/functions/eval.html) "($options)";
    
      for my $dir(q(/home/phil/perl/cpan/DataTableText/lib/Data/Table/),            # Folders we will need on [Amazon Web Services](http://aws.amazon.com)                   q(/home/phil/.aws/))
       {awsParallelSpreadFolder($dir, %options);
       }
    
      my $d = temporaryFolder;                                                      # Create a temporary [folder](https://en.wikipedia.org/wiki/File_folder)       my $resultsFile = fpe($d, qw(results data));                                  # Save results in this temporary [file](https://en.wikipedia.org/wiki/Computer_file)     
      if (my $r = execPerlOnRemote(join "
  ",                                       # Execute some [code](https://en.wikipedia.org/wiki/Computer_program) on a [server](https://en.wikipedia.org/wiki/Server_(computing))     
        getCodeContext(\&awsParallelProcessFilesTestParallel),                      # Get [code](https://en.wikipedia.org/wiki/Computer_program) context of the [sub](https://perldoc.perl.org/perlsub.html) we want to call.  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        <<SESSIONLEADER))                                                           # Launch [code](https://en.wikipedia.org/wiki/Computer_program) on session leader
    use Data::Table::Text qw(:all);
    
    my \$r = awsParallelProcessFiles                                                # Process files on multiple L<Amazon Web Services|http://aws.amazon.com> instances in parallel
     ({file=>4, time=>timeStamp},                                                   # User data
    
      \\\&Data::Table::Text::awsParallelProcessFilesTestParallel,                   # Reference to [code](https://en.wikipedia.org/wiki/Computer_program) to execute in parallel on each session instance  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      \\\&Data::Table::Text::awsParallelProcessFilesTestResults,                    # Reference to [code](https://en.wikipedia.org/wiki/Computer_program) to execute in series to merge the results of each parallel computation
      [map {writeFile(fpe(q($d), \$_, qw(txt)), \$_)} 1..$N],                       # Files to [process](https://en.wikipedia.org/wiki/Process_management_(computing))       $options);                                                                    # Aws cli options as we will be running on Aws
    
    storeFile(q($resultsFile), \$r);                                                # Save results in a [file](https://en.wikipedia.org/wiki/Computer_file)     
    SESSIONLEADER
    
       {copyFileFromRemote($resultsFile);                                           # Retrieve [user](https://en.wikipedia.org/wiki/User_(computing)) data
    
        my $userData = retrieveFile($resultsFile);                                  # Recover [user](https://en.wikipedia.org/wiki/User_(computing)) data
        my @i = awsParallelSecondaryIpAddresses(%options);                          # Ip addresses of secondary instances
        my @I = keys $userData->{ip}->%*;
        is_deeply [sort @i], [sort @I];                                             # Each secondary [IP address](https://en.wikipedia.org/wiki/IP_address) address was used
    
        ok $userData->{file}  == 4;                                                 # Prove we can pass data in and get it back
        ok $userData->{merge} == 1 + @i, 'ii';                                      # Number of merges
    
        my %f; my %i;                                                               # Files processed on each [IP address](https://en.wikipedia.org/wiki/IP_address)         for   my $i(sort keys $userData->{ipFile}->%*)                              # Ip
         {for my $f(sort keys $userData->{ipFile}{$i}->%*)                          # File
           {$f{fn($f)}++;                                                           # Files processed
            $i{$i}++;                                                               # Count files on each [IP address](https://en.wikipedia.org/wiki/IP_address)            }
         }
    
        is_deeply \%f, {map {$_=>1} 1..$N};                                         # Check each [file](https://en.wikipedia.org/wiki/Computer_file) was processed
    
        if (1)
         {my @rc; my @ra;                                                           # Range of number of files processed on each [IP address](https://en.wikipedia.org/wiki/IP_address) - computed, actually counted
          my $l = $N/@i-1;                                                          # Lower limit of number of files per IP address
          my $h = $N/@i+1;                                                          # Upper limit of number of files per IP address
          for   my $i(keys %i)
           {my $nc = $i{$i};                                                        # Number of files processed on this [IP address](https://en.wikipedia.org/wiki/IP_address) - computed
            my $na = $userData->{ip}{$i};                                           # Number of files processed on this [IP address](https://en.wikipedia.org/wiki/IP_address) - actually counted
            push @rc, ($nc >= $l and $nc <= $h) ? 1 : 0;                            # 1 - in range, 0 - out of range
            push @ra, ($na >= $l and $na <= $h) ? 1 : 0;                            # 1 - in range, 0 - out of range
           }
          ok @i == [grep](https://en.wikipedia.org/wiki/Grep) {$_} @ra;                                                   # Check each [IP address](https://en.wikipedia.org/wiki/IP_address) processed the expected number of files
          ok @i == [grep](https://en.wikipedia.org/wiki/Grep) {$_} @rc;
         }
    
        ok $userData->{files}{&fpe($d, qw(4 txt))} eq                               # Check the computed MD5 sum for the specified [file](https://en.wikipedia.org/wiki/Computer_file)            q(a87ff679a2f3e71d9181a67b7542122c);
       }
    

## awsParallelProcessFilesTestResults($userData, @results)

Test results of running on [Amazon Web Services](http://aws.amazon.com) in parallel.

       Parameter  Description
    1  $userData  User data from primary instance instance or [process](https://en.wikipedia.org/wiki/Process_management_(computing))     2  @results   Results from each parallel instance or [process](https://en.wikipedia.org/wiki/Process_management_(computing)) 
**Example:**

      my $N = 2001;                                                                 # Number of files to [process](https://en.wikipedia.org/wiki/Process_management_(computing))       my $options = q(region => q(us-east-2), profile=>q(fmc));                     # Aws cli options
      my %options = [eval](http://perldoc.perl.org/functions/eval.html) "($options)";
    
      for my $dir(q(/home/phil/perl/cpan/DataTableText/lib/Data/Table/),            # Folders we will need on [Amazon Web Services](http://aws.amazon.com)                   q(/home/phil/.aws/))
       {awsParallelSpreadFolder($dir, %options);
       }
    
      my $d = temporaryFolder;                                                      # Create a temporary [folder](https://en.wikipedia.org/wiki/File_folder)       my $resultsFile = fpe($d, qw(results data));                                  # Save results in this temporary [file](https://en.wikipedia.org/wiki/Computer_file)     
      if (my $r = execPerlOnRemote(join "
  ",                                       # Execute some [code](https://en.wikipedia.org/wiki/Computer_program) on a [server](https://en.wikipedia.org/wiki/Server_(computing))         getCodeContext(\&awsParallelProcessFilesTestParallel),                      # Get [code](https://en.wikipedia.org/wiki/Computer_program) context of the [sub](https://perldoc.perl.org/perlsub.html) we want to call.
        <<SESSIONLEADER))                                                           # Launch [code](https://en.wikipedia.org/wiki/Computer_program) on session leader
    use Data::Table::Text qw(:all);
    
    my \$r = awsParallelProcessFiles                                                # Process files on multiple L<Amazon Web Services|http://aws.amazon.com> instances in parallel
     ({file=>4, time=>timeStamp},                                                   # User data
      \\\&Data::Table::Text::awsParallelProcessFilesTestParallel,                   # Reference to [code](https://en.wikipedia.org/wiki/Computer_program) to execute in parallel on each session instance
    
      \\\&Data::Table::Text::awsParallelProcessFilesTestResults,                    # Reference to [code](https://en.wikipedia.org/wiki/Computer_program) to execute in series to merge the results of each parallel computation  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      [map {writeFile(fpe(q($d), \$_, qw(txt)), \$_)} 1..$N],                       # Files to [process](https://en.wikipedia.org/wiki/Process_management_(computing))       $options);                                                                    # Aws cli options as we will be running on Aws
    
    storeFile(q($resultsFile), \$r);                                                # Save results in a [file](https://en.wikipedia.org/wiki/Computer_file)     
    SESSIONLEADER
    
       {copyFileFromRemote($resultsFile);                                           # Retrieve [user](https://en.wikipedia.org/wiki/User_(computing)) data
    
        my $userData = retrieveFile($resultsFile);                                  # Recover [user](https://en.wikipedia.org/wiki/User_(computing)) data
        my @i = awsParallelSecondaryIpAddresses(%options);                          # Ip addresses of secondary instances
        my @I = keys $userData->{ip}->%*;
        is_deeply [sort @i], [sort @I];                                             # Each secondary [IP address](https://en.wikipedia.org/wiki/IP_address) address was used
    
        ok $userData->{file}  == 4;                                                 # Prove we can pass data in and get it back
        ok $userData->{merge} == 1 + @i, 'ii';                                      # Number of merges
    
        my %f; my %i;                                                               # Files processed on each [IP address](https://en.wikipedia.org/wiki/IP_address)         for   my $i(sort keys $userData->{ipFile}->%*)                              # Ip
         {for my $f(sort keys $userData->{ipFile}{$i}->%*)                          # File
           {$f{fn($f)}++;                                                           # Files processed
            $i{$i}++;                                                               # Count files on each [IP address](https://en.wikipedia.org/wiki/IP_address)            }
         }
    
        is_deeply \%f, {map {$_=>1} 1..$N};                                         # Check each [file](https://en.wikipedia.org/wiki/Computer_file) was processed
    
        if (1)
         {my @rc; my @ra;                                                           # Range of number of files processed on each [IP address](https://en.wikipedia.org/wiki/IP_address) - computed, actually counted
          my $l = $N/@i-1;                                                          # Lower limit of number of files per IP address
          my $h = $N/@i+1;                                                          # Upper limit of number of files per IP address
          for   my $i(keys %i)
           {my $nc = $i{$i};                                                        # Number of files processed on this [IP address](https://en.wikipedia.org/wiki/IP_address) - computed
            my $na = $userData->{ip}{$i};                                           # Number of files processed on this [IP address](https://en.wikipedia.org/wiki/IP_address) - actually counted
            push @rc, ($nc >= $l and $nc <= $h) ? 1 : 0;                            # 1 - in range, 0 - out of range
            push @ra, ($na >= $l and $na <= $h) ? 1 : 0;                            # 1 - in range, 0 - out of range
           }
          ok @i == [grep](https://en.wikipedia.org/wiki/Grep) {$_} @ra;                                                   # Check each [IP address](https://en.wikipedia.org/wiki/IP_address) processed the expected number of files
          ok @i == [grep](https://en.wikipedia.org/wiki/Grep) {$_} @rc;
         }
    
        ok $userData->{files}{&fpe($d, qw(4 txt))} eq                               # Check the computed MD5 sum for the specified [file](https://en.wikipedia.org/wiki/Computer_file)            q(a87ff679a2f3e71d9181a67b7542122c);
       }
    

## s3Profile(%options)

Return an S3 profile keyword from an S3 option set.

       Parameter  Description
    1  %options   Options

## s3Delete(%options)

Return an S3 --delete keyword from an S3 option set.

       Parameter  Description
    1  %options   Options

## Data::Table::Text::Starter::logEntry($starter, $finish)

Create a [log](https://en.wikipedia.org/wiki/Log_file) entry showing progress and eta.

       Parameter  Description
    1  $starter   Starter
    2  $finish    0 - start; 1 - finish

## Data::Table::Text::Starter::averageProcessTime($starter)

Average elapsed time spent by each [process](https://en.wikipedia.org/wiki/Process_management_(computing)). 
       Parameter  Description
    1  $starter   Starter

## Data::Table::Text::Starter::say($starter, @message)

Write to the [log](https://en.wikipedia.org/wiki/Log_file) [file](https://en.wikipedia.org/wiki/Computer_file) if it is available.

       Parameter  Description
    1  $starter   Starter
    2  @message   Text to write to [log](https://en.wikipedia.org/wiki/Log_file) [file](https://en.wikipedia.org/wiki/Computer_file). 
## Data::Table::Text::Starter::waitOne($starter)

Wait for at least one [process](https://en.wikipedia.org/wiki/Process_management_(computing)) to finish and consolidate its results.

       Parameter  Description
    1  $starter   Starter

## countSquareArray(@square)

Count the number of elements in a square [array](https://en.wikipedia.org/wiki/Dynamic_array). 
       Parameter  Description
    1  @square    Array of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) 
## processSizesInParallelN($N, $parallel, $results, @sizes)

Process items of known size in parallel using the specified number **$N** [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) with the [process](https://en.wikipedia.org/wiki/Process_management_(computing)) each [file](https://en.wikipedia.org/wiki/Computer_file) is assigned to depending on the size of the [file](https://en.wikipedia.org/wiki/Computer_file) so that each [process](https://en.wikipedia.org/wiki/Process_management_(computing)) is loaded with approximately the same number of bytes of data in total from the files it [processes](https://en.wikipedia.org/wiki/Process_management_(computing)). 

Each [file](https://en.wikipedia.org/wiki/Computer_file) is processed by [sub](https://perldoc.perl.org/perlsub.html) **$parallel** and the results of processing all files is processed by **$results** where the files are taken from **@files**. Each **&$parallel** receives a [file](https://en.wikipedia.org/wiki/Computer_file) from **@files**. **&$results** receives an [array](https://en.wikipedia.org/wiki/Dynamic_array) of all the results returned by **&$parallel**.

       Parameter  Description
    1  $N         Number of [processes](https://en.wikipedia.org/wiki/Process_management_(computing))     2  $parallel  Parallel [sub](https://perldoc.perl.org/perlsub.html)     3  $results   Results [sub](https://perldoc.perl.org/perlsub.html)     4  @sizes     Array of [size; item] to [process](https://en.wikipedia.org/wiki/Process_management_(computing)) by size

## wellKnownUrls()

Short names for some well known urls.

## reinstateWellKnown($string)

Contract references to well known Urls to their abbreviated form.

       Parameter  Description
    1  $string    Source [string](https://en.wikipedia.org/wiki/String_(computer_science)) 
## expandWellKnownWordsInMarkDownFile($s, $t)

Expand well known words in a mark down [file](https://en.wikipedia.org/wiki/Computer_file). 
       Parameter  Description
    1  $s         Source [file](https://en.wikipedia.org/wiki/Computer_file)     2  $t         Target [file](https://en.wikipedia.org/wiki/Computer_file) 
## formatSourcePodAsHtml()

Format the [POD](https://perldoc.perl.org/perlpod.html) in the current source [file](https://en.wikipedia.org/wiki/Computer_file) as [HTML](https://en.wikipedia.org/wiki/HTML).

## extractTest($string)

Remove example markers from [test](https://en.wikipedia.org/wiki/Software_testing) [code](https://en.wikipedia.org/wiki/Computer_program). 
       Parameter  Description
    1  $string    String containing [test](https://en.wikipedia.org/wiki/Software_testing) line

## docUserFlags($flags, $perlModule, $package, $name)

Generate [documentation](https://en.wikipedia.org/wiki/Software_documentation) for a method by calling the extractDocumentationFlags method in the package being documented, passing it the flags for a method and the name of the method. The called method should return the [documentation](https://en.wikipedia.org/wiki/Software_documentation) to be inserted for the named method.

       Parameter    Description
    1  $flags       Flags
    2  $perlModule  File containing [documentation](https://en.wikipedia.org/wiki/Software_documentation)     3  $package     Package containing [documentation](https://en.wikipedia.org/wiki/Software_documentation)     4  $name        Name of method to be processed

## updatePerlModuleDocumentation($perlModule)

Update the [documentation](https://en.wikipedia.org/wiki/Software_documentation) in a **$perlModule** and display said [documentation](https://en.wikipedia.org/wiki/Software_documentation) in a web [web browser](https://en.wikipedia.org/wiki/Web_browser). 
       Parameter    Description
    1  $perlModule  File containing the [code](https://en.wikipedia.org/wiki/Computer_program) of the [Perl](http://www.perl.org/) [module](https://en.wikipedia.org/wiki/Modular_programming) 
## extractPythonDocumentationFromFiles(@sources)

Extract [Python](https://www.python.org/) [documentation](https://en.wikipedia.org/wiki/Software_documentation) from the specified files.

       Parameter  Description
    1  @sources   Python source files

# Synonyms

**fpd** is a synonym for [filePathDir](#filepathdir) - Create a [folder](https://en.wikipedia.org/wiki/File_folder) name from a [list](https://en.wikipedia.org/wiki/Linked_list) of  names.

**fpe** is a synonym for [filePathExt](#filepathext) - Create a [file](https://en.wikipedia.org/wiki/Computer_file) name from a [list](https://en.wikipedia.org/wiki/Linked_list) of  names the last of which is assumed to be the extension of the [file](https://en.wikipedia.org/wiki/Computer_file) name.

**fpf** is a synonym for [filePath](#filepath) - Create a [file](https://en.wikipedia.org/wiki/Computer_file) name from a [list](https://en.wikipedia.org/wiki/Linked_list) of  names.

**owf** is a synonym for [overWriteFile](#overwritefile) - Write to a **$file**, after creating a path to the $file with [makePath](https://metacpan.org/pod/makePath) if necessary, a **$string** of [Unicode](https://en.wikipedia.org/wiki/Unicode) content encoded as [utf8](https://en.wikipedia.org/wiki/UTF-8).

**temporaryDirectory** is a synonym for [temporaryFolder](#temporaryfolder) - Create a new, empty, temporary [folder](https://en.wikipedia.org/wiki/File_folder). 
# Index

1 [absFile](#absfile) - Return the name of the given [file](https://en.wikipedia.org/wiki/Computer_file) if it a fully qualified [file](https://en.wikipedia.org/wiki/Computer_file) name else returns **undef**.

2 [absFromAbsPlusRel](#absfromabsplusrel) - Absolute [file](https://en.wikipedia.org/wiki/Computer_file) from an absolute [file](https://en.wikipedia.org/wiki/Computer_file) **$a** plus a relative [file](https://en.wikipedia.org/wiki/Computer_file) **$r**.

3 [addCertificate](#addcertificate) - Add a certificate to the current [Secure Shell](https://www.ssh.com/ssh) session.

4 [addLValueScalarMethods](#addlvaluescalarmethods) - Generate [lvalue method](http://perldoc.perl.org/perlsub.html#Lvalue-subroutines) scalar methods in the current package if they do not already exist.

5 [appendFile](#appendfile) - Append to **$file** a **$string** of [Unicode](https://en.wikipedia.org/wiki/Unicode) content encoded with [utf8](https://en.wikipedia.org/wiki/UTF-8), creating the $file first if necessary.

6 [arrayProduct](#arrayproduct) - Find the product of any [strings](https://en.wikipedia.org/wiki/String_(computer_science)) that look like numbers in an [array](https://en.wikipedia.org/wiki/Dynamic_array). 
7 [arraySum](#arraysum) - Find the sum of any [strings](https://en.wikipedia.org/wiki/String_(computer_science)) that look like numbers in an [array](https://en.wikipedia.org/wiki/Dynamic_array). 
8 [arrayTimes](#arraytimes) - Multiply by **$multiplier** each element of the [array](https://en.wikipedia.org/wiki/Dynamic_array) **@a** and return as the result.

9 [arrayToHash](#arraytohash) - Create a [hash](https://en.wikipedia.org/wiki/Hash_table) reference from an [array](https://en.wikipedia.org/wiki/Dynamic_array). 
10 [asciiToHexString](#asciitohexstring) - Encode an [Ascii](https://en.wikipedia.org/wiki/ASCII) [string](https://en.wikipedia.org/wiki/String_(computer_science)) as a [string](https://en.wikipedia.org/wiki/String_(computer_science)) of [hexadecimal](https://en.wikipedia.org/wiki/Hexadecimal) digits.

11 [assertPackageRefs](#assertpackagerefs) - Confirm that the specified references are to the specified package.

12 [assertRef](#assertref) - Confirm that the specified references are to the package into which this routine has been exported.

13 [awsCurrentAvailabilityZone](#awscurrentavailabilityzone) - Get the availability zone of the [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) we are currently running on if we are running on an [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) else return a blank [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
14 [awsCurrentInstanceId](#awscurrentinstanceid) - Get the instance id of the [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) we are currently running on if we are running on an [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) else return a blank [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
15 [awsCurrentInstanceType](#awscurrentinstancetype) - Get the instance type of the [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) if we are running on an [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) else return a blank [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
16 [awsCurrentIp](#awscurrentip) - Get the [IP address](https://en.wikipedia.org/wiki/IP_address) address of the AWS [server](https://en.wikipedia.org/wiki/Server_(computing)) we are currently running on if we are running on an [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) else return a blank [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
17 [awsCurrentLinuxSpotPrices](#awscurrentlinuxspotprices) - Return {instance type} = cheapest [spot](https://aws.amazon.com/ec2/spot/) price in dollars per hour for the given region.

18 [awsCurrentRegion](#awscurrentregion) - Get the region of the [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) we are currently running on if we are running on an [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) else return a blank [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
19 [awsEc2CreateImage](#awsec2createimage) - Create an image snap shot with the specified **$name** of the AWS [server](https://en.wikipedia.org/wiki/Server_(computing)) we are currently running on if we are running on an AWS [server](https://en.wikipedia.org/wiki/Server_(computing)) else return false.

20 [awsEc2DescribeImages](#awsec2describeimages) - Describe images available.

21 [awsEc2DescribeInstances](#awsec2describeinstances) - Describe the [Amazon Web Services](http://aws.amazon.com) instances running in a **$region**.

22 [awsEc2DescribeInstancesGetIPAddresses](#awsec2describeinstancesgetipaddresses) - Return a [hash](https://en.wikipedia.org/wiki/Hash_table) of {instanceId => public [IP address](https://en.wikipedia.org/wiki/IP_address) address} for all running instances on [Amazon Web Services](http://aws.amazon.com) with [IP address](https://en.wikipedia.org/wiki/IP_address) addresses.

23 [awsEc2DescribeInstanceType](#awsec2describeinstancetype) - Return details of the specified instance type.

24 [awsEc2DescribeSpotInstances](#awsec2describespotinstances) - Return a [hash](https://en.wikipedia.org/wiki/Hash_table) {spot instance request => [spot](https://aws.amazon.com/ec2/spot/) instance details} describing the status of active [spot](https://aws.amazon.com/ec2/spot/) instances.

25 [awsEc2FindImagesWithTagValue](#awsec2findimageswithtagvalue) - Find images with a tag that matches the specified regular expression **$value**.

26 [awsEc2InstanceIpAddress](#awsec2instanceipaddress) - Return the IP address of a named instance on [Amazon Web Services](http://aws.amazon.com) else return **undef**.

27 [awsEc2ReportSpotInstancePrices](#awsec2reportspotinstanceprices) - Report the prices of all the [spot](https://aws.amazon.com/ec2/spot/) instances whose type matches a regular expression **$instanceTypeRe**.

28 [awsEc2RequestSpotInstances](#awsec2requestspotinstances) - Request [spot](https://aws.amazon.com/ec2/spot/) instances as long as they can be started within the next minute.

29 [awsEc2Tag](#awsec2tag) - Tag an elastic compute resource with the supplied tags.

30 [awsExecCli](#awsexeccli) - Execute an AWs command and return its response.

31 [awsExecCliJson](#awsexecclijson) - Execute an AWs command and decode the [Json](https://en.wikipedia.org/wiki/JSON) so produced.

32 [awsInstanceId](#awsinstanceid) - Create an instance-id from the specified **%options**.

33 [awsIp](#awsip) - Get [IP address](https://en.wikipedia.org/wiki/IP_address) address of [server](https://en.wikipedia.org/wiki/Server_(computing)) at [Amazon Web Services](http://aws.amazon.com).

34 [awsMetaData](#awsmetadata) - Get an item of meta data for the [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) we are currently running on if we are running on an [Amazon Web Services](http://aws.amazon.com) [server](https://en.wikipedia.org/wiki/Server_(computing)) else return a blank [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
35 [awsParallelGatherFolder](#awsparallelgatherfolder) - On [Amazon Web Services](http://aws.amazon.com): merges all the files in the specified **$folder** on each secondary instance to the corresponding [folder](https://en.wikipedia.org/wiki/File_folder) on the primary instance in parallel.

36 [awsParallelIpAddresses](#awsparallelipaddresses) - Return the IP addresses of all the [Amazon Web Services](http://aws.amazon.com) session instances.

37 [awsParallelPrimaryInstanceId](#awsparallelprimaryinstanceid) - Return the instance id of the primary instance.

38 [awsParallelPrimaryIpAddress](#awsparallelprimaryipaddress) - Return the IP addresses of any primary instance on [Amazon Web Services](http://aws.amazon.com).

39 [awsParallelProcessFiles](#awsparallelprocessfiles) - Process files in parallel across multiple [Amazon Web Services](http://aws.amazon.com) instances if available or in series if not.

40 [awsParallelProcessFilesTestParallel](#awsparallelprocessfilestestparallel) - Test running on [Amazon Web Services](http://aws.amazon.com) in parallel.

41 [awsParallelProcessFilesTestResults](#awsparallelprocessfilestestresults) - Test results of running on [Amazon Web Services](http://aws.amazon.com) in parallel.

42 [awsParallelSecondaryIpAddresses](#awsparallelsecondaryipaddresses) - Return a [list](https://en.wikipedia.org/wiki/Linked_list) containing the IP addresses of any secondary instances on [Amazon Web Services](http://aws.amazon.com).

43 [awsParallelSpreadFolder](#awsparallelspreadfolder) - On [Amazon Web Services](http://aws.amazon.com): copies a specified **$folder** from the primary instance, see: [awsParallelPrimaryInstanceId](https://metacpan.org/pod/awsParallelPrimaryInstanceId), in parallel, to all the secondary instances in the session.

44 [awsProfile](#awsprofile) - Create a profile keyword from the specified **%options**.

45 [awsR53a](#awsr53a) - Create/Update a **A** [Domain Name System](https://en.wikipedia.org/wiki/Domain_Name_System) record for the specified [server](https://en.wikipedia.org/wiki/Server_(computing)). 
46 [awsR53aaaa](#awsr53aaaa) - Create/Update a **AAAA** [Domain Name System](https://en.wikipedia.org/wiki/Domain_Name_System) record for the specified [server](https://en.wikipedia.org/wiki/Server_(computing)). 
47 [awsRegion](#awsregion) - Create a region keyword from the specified **%options**.

48 [awsTranslateText](#awstranslatetext) - Translate **$text** from English to a specified **$language** using AWS Translate with the specified global **$options** and return the translated [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
49 [binModeAllUtf8](#binmodeallutf8) - Set STDOUT and STDERR to accept [utf8](https://en.wikipedia.org/wiki/UTF-8) without complaint.

50 [boldString](#boldstring) - Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to bold.

51 [boldStringUndo](#boldstringundo) - Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to bold.

52 [call](#call) - Call the specified **$sub** in a separate child [process](https://en.wikipedia.org/wiki/Process_management_(computing)), wait for it to complete, then copy back the named **@our** variables from the child [process](https://en.wikipedia.org/wiki/Process_management_(computing)) to the calling parent [process](https://en.wikipedia.org/wiki/Process_management_(computing)) effectively freeing any [memory](https://en.wikipedia.org/wiki/Computer_memory) used during the call.

53 [callSubInOverlappedParallel](#callsubinoverlappedparallel) - Call the **$child** [sub](https://perldoc.perl.org/perlsub.html) reference in parallel in a separate child [process](https://en.wikipedia.org/wiki/Process_management_(computing)) and ignore its results while calling the **$parent** [sub](https://perldoc.perl.org/perlsub.html) reference in the parent [process](https://en.wikipedia.org/wiki/Process_management_(computing)) and returning its results.

54 [callSubInParallel](#callsubinparallel) - Call a [sub](https://perldoc.perl.org/perlsub.html) reference in parallel to avoid [memory](https://en.wikipedia.org/wiki/Computer_memory) fragmentation and return its results.

55 [checkFile](#checkfile) - Return the name of the specified [file](https://en.wikipedia.org/wiki/Computer_file) if it exists, else [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) the maximum extent of the path that does exist.

56 [checkKeys](#checkkeys) - Check the keys in a **hash** confirm to those **$permitted**.

57 [childPids](#childpids) - Recursively [find](https://en.wikipedia.org/wiki/Find_(Unix)) the pids of all the [sub](https://perldoc.perl.org/perlsub.html) [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) of a **$process** and all their [sub](https://perldoc.perl.org/perlsub.html) [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) and so on returning the specified pid and all its child pids as a [list](https://en.wikipedia.org/wiki/Linked_list). 
58 [chooseStringAtRandom](#choosestringatrandom) - Choose a [string](https://en.wikipedia.org/wiki/String_(computer_science)) at random from the [list](https://en.wikipedia.org/wiki/Linked_list) of **@strings** supplied.

59 [clearFolder](#clearfolder) - Remove all the files and folders under and including the specified **$folder** as long as the number of files to be removed is less than the specified **$limitCount**.

60 [cmpArrays](#cmparrays) - Compare two [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)). 
61 [compareArraysAndExplain](#comparearraysandexplain) - Compare two [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)) and provide an explanation as to why they differ if they differ or [undef](https://perldoc.perl.org/functions/undef.html) if they do not.

62 [confirmHasCommandLineCommand](#confirmhascommandlinecommand) - Check that the specified b&lt;$cmd> is present on the current system.

63 [containingFolderName](#containingfoldername) - The name of a [folder](https://en.wikipedia.org/wiki/File_folder) containing a [file](https://en.wikipedia.org/wiki/Computer_file). 
64 [containingPowerOfTwo](#containingpoweroftwo) - Find [log](https://en.wikipedia.org/wiki/Log_file) two of the lowest power of two greater than or equal to a number **$n**.

65 [contains](#contains) - Returns the indices at which an **$item** matches elements of the specified **@array**.

66 [convertDocxToFodt](#convertdocxtofodt) - Convert a _docx_ **$inputFile** [file](https://en.wikipedia.org/wiki/Computer_file) to a _fodt_ **$outputFile** using **unoconv** which must not be running elsewhere at the time.

67 [convertImageToJpx](#convertimagetojpx) - Convert a **$source** image to a **$target** image in jpx format.

68 [convertImageToJpx690](#convertimagetojpx690) - Convert a **$source** image to a **$target** image in jpx format using versions of [Imagemagick](https://www.imagemagick.org/script/index.php) [version](https://en.wikipedia.org/wiki/Software_versioning) 6.

69 [convertPerlToJavaScript](#convertperltojavascript) - Convert Perl to Javascript.

70 [convertUnicodeToXml](#convertunicodetoxml) - Convert a **$string** with [Unicode](https://en.wikipedia.org/wiki/Unicode) [code](https://en.wikipedia.org/wiki/Computer_program) points that are not directly representable in [Ascii](https://en.wikipedia.org/wiki/ASCII) into [string](https://en.wikipedia.org/wiki/String_(computer_science)) that replaces these [code](https://en.wikipedia.org/wiki/Computer_program) points with their representation in [Xml](https://en.wikipedia.org/wiki/XML) making the [string](https://en.wikipedia.org/wiki/String_(computer_science)) usable in [Xml](https://en.wikipedia.org/wiki/XML) documents.

71 [convertUtf32ToUtf8](#convertutf32toutf8) - Convert a number representing a single [Unicode](https://en.wikipedia.org/wiki/Unicode) point coded in utf32 to [utf8](https://en.wikipedia.org/wiki/UTF-8) big endian.

72 [convertUtf32ToUtf8LE](#convertutf32toutf8le) - Convert a number representing a single [Unicode](https://en.wikipedia.org/wiki/Unicode) point coded in utf32 to [utf8](https://en.wikipedia.org/wiki/UTF-8) little endian.

73 [convertUtf8ToUtf32](#convertutf8toutf32) - Convert a number representing a single [Unicode](https://en.wikipedia.org/wiki/Unicode) point coded in [utf8](https://en.wikipedia.org/wiki/UTF-8) to utf32.

74 [copyBinaryFile](#copybinaryfile) - Copy the binary [file](https://en.wikipedia.org/wiki/Computer_file) **$source** to a [file](https://en.wikipedia.org/wiki/Computer_file) named <%target> and return the target [file](https://en.wikipedia.org/wiki/Computer_file) name,.

75 [copyFile](#copyfile) - Copy the **$source** [file](https://en.wikipedia.org/wiki/Computer_file) encoded in [utf8](https://en.wikipedia.org/wiki/UTF-8) to the specified **$target** [file](https://en.wikipedia.org/wiki/Computer_file) in and return $target.

76 [copyFileFromRemote](#copyfilefromremote) - Copy the specified **$file** from the [server](https://en.wikipedia.org/wiki/Server_(computing)) whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp).

77 [copyFileToFolder](#copyfiletofolder) - Copy the [file](https://en.wikipedia.org/wiki/Computer_file) named in **$source** to the specified **$targetFolder/** or if $targetFolder/ is in fact a [file](https://en.wikipedia.org/wiki/Computer_file) into the [folder](https://en.wikipedia.org/wiki/File_folder) containing this [file](https://en.wikipedia.org/wiki/Computer_file) and return the target [file](https://en.wikipedia.org/wiki/Computer_file) name.

78 [copyFileToRemote](#copyfiletoremote) - Copy the specified local **$file** to the [server](https://en.wikipedia.org/wiki/Server_(computing)) whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp).

79 [copyFolder](#copyfolder) - Copy the **$source** [folder](https://en.wikipedia.org/wiki/File_folder) to the **$target** [folder](https://en.wikipedia.org/wiki/File_folder) after clearing the $target [folder](https://en.wikipedia.org/wiki/File_folder). 
80 [copyFolderToRemote](#copyfoldertoremote) - Copy the specified local **$Source** [folder](https://en.wikipedia.org/wiki/File_folder) to the corresponding remote [folder](https://en.wikipedia.org/wiki/File_folder) on the [server](https://en.wikipedia.org/wiki/Server_(computing)) whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp).

81 [countFileExtensions](#countfileextensions) - Return a [hash](https://en.wikipedia.org/wiki/Hash_table) which counts the [file](https://en.wikipedia.org/wiki/Computer_file) [file name extensions](https://en.wikipedia.org/wiki/List_of_filename_extensions) in and below the folders in the specified [list](https://en.wikipedia.org/wiki/Linked_list). 
82 [countFileTypes](#countfiletypes) - Return a [hash](https://en.wikipedia.org/wiki/Hash_table) which counts, in parallel with a maximum number of [processes](https://en.wikipedia.org/wiki/Process_management_(computing)): **$maximumNumberOfProcesses**, the results of applying the **file** command to each [file](https://en.wikipedia.org/wiki/Computer_file) in and under the specified **@folders**.

83 [countOccurencesInString](#countoccurencesinstring) - Returns the number of occurrences in **$inString** of **$searchFor**.

84 [countSquareArray](#countsquarearray) - Count the number of elements in a square [array](https://en.wikipedia.org/wiki/Dynamic_array). 
85 [createEmptyFile](#createemptyfile) - Create an empty [file](https://en.wikipedia.org/wiki/Computer_file) unless the [file](https://en.wikipedia.org/wiki/Computer_file) already exists and return the name of the [file](https://en.wikipedia.org/wiki/Computer_file) else [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) if the [file](https://en.wikipedia.org/wiki/Computer_file) cannot be created.

86 [currentDirectory](#currentdirectory) - Get the current working directory.

87 [currentDirectoryAbove](#currentdirectoryabove) - Get the path to the [folder](https://en.wikipedia.org/wiki/File_folder) above the current working [folder](https://en.wikipedia.org/wiki/File_folder). 
88 [cutOutImagesInFodtFile](#cutoutimagesinfodtfile) - Cut out the images embedded in a **fodt** [file](https://en.wikipedia.org/wiki/Computer_file), perhaps produced via [convertDocxToFodt](#convertdocxtofodt), placing them in the specified [folder](https://en.wikipedia.org/wiki/File_folder) and replacing them in the source [file](https://en.wikipedia.org/wiki/Computer_file) with:

    <image href="$imageFile" outputclass="imageType">.

89 [Data::Exchange::Service::check](#data-exchange-service-check) - Check that we are the current incarnation of the named service with details obtained from [newServiceIncarnation](#newserviceincarnation).

90 [Data::Table::Text::Starter::averageProcessTime](#data-table-text-starter-averageprocesstime) - Average elapsed time spent by each [process](https://en.wikipedia.org/wiki/Process_management_(computing)). 
91 [Data::Table::Text::Starter::finish](#data-table-text-starter-finish) - Wait for all started [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) to finish and return their results as an [array](https://en.wikipedia.org/wiki/Dynamic_array). 
92 [Data::Table::Text::Starter::logEntry](#data-table-text-starter-logentry) - Create a [log](https://en.wikipedia.org/wiki/Log_file) entry showing progress and eta.

93 [Data::Table::Text::Starter::say](#data-table-text-starter-say) - Write to the [log](https://en.wikipedia.org/wiki/Log_file) [file](https://en.wikipedia.org/wiki/Computer_file) if it is available.

94 [Data::Table::Text::Starter::start](#data-table-text-starter-start) - Start a new [process](https://en.wikipedia.org/wiki/Process_management_(computing)) to run the specified **$sub**.

95 [Data::Table::Text::Starter::waitOne](#data-table-text-starter-waitone) - Wait for at least one [process](https://en.wikipedia.org/wiki/Process_management_(computing)) to finish and consolidate its results.

96 [dateStamp](#datestamp) - Year-monthName-day.

97 [dateTimeStamp](#datetimestamp) - Year-monthNumber-day at hours:minute:seconds.

98 [dateTimeStampName](#datetimestampname) - Date time stamp without white space.

99 [ddd](#ddd) - Dump data.

100 [decodeBase64](#decodebase64) - Decode an [Ascii](https://en.wikipedia.org/wiki/ASCII) **$string** in base 64.

101 [decodeJson](#decodejson) - Convert a [Json](https://en.wikipedia.org/wiki/JSON) **$string** to a [Perl](http://www.perl.org/) data structure.

102 [deduplicateSequentialWordsInString](#deduplicatesequentialwordsinstring) - Remove sequentially duplicate words in a [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
103 [denormalizeFolderName](#denormalizefoldername) - Remove any trailing [folder](https://en.wikipedia.org/wiki/File_folder) separator from a [folder](https://en.wikipedia.org/wiki/File_folder) name.

104 [deSquareArray](#desquarearray) - Create a one dimensional [array](https://en.wikipedia.org/wiki/Dynamic_array) from a two dimensional [array](https://en.wikipedia.org/wiki/Dynamic_array) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array). 
105 [detagString](#detagstring) - Remove [HTML](https://en.wikipedia.org/wiki/HTML) or [Xml](https://en.wikipedia.org/wiki/XML) tags from a [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
106 [divideCharactersIntoRanges](#dividecharactersintoranges) - Divide a [string](https://en.wikipedia.org/wiki/String_(computer_science)) of characters into ranges.

107 [divideIntegersIntoRanges](#divideintegersintoranges) - Divide an [array](https://en.wikipedia.org/wiki/Dynamic_array) of integers into ranges.

108 [docUserFlags](#docuserflags) - Generate [documentation](https://en.wikipedia.org/wiki/Software_documentation) for a method by calling the extractDocumentationFlags method in the package being documented, passing it the flags for a method and the name of the method.

109 [downloadGitHubPublicRepo](#downloadgithubpublicrepo) - Get the contents of a public repo on GitHub and place them in a temporary [folder](https://en.wikipedia.org/wiki/File_folder) whose name is returned to the caller or [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) if no such repo exists.

110 [downloadGitHubPublicRepoFile](#downloadgithubpublicrepofile) - Get the contents of a **$user** **$repo** **$file** from  a public repo on GitHub and return them as a [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
111 [dumpFile](#dumpfile) - Dump to a **$file** the referenced data **$structure**.

112 [dumpFileAsJson](#dumpfileasjson) - Dump to a **$file** the referenced data **$structure** represented as [Json](https://en.wikipedia.org/wiki/JSON) [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
113 [dumpGZipFile](#dumpgzipfile) - Write to a **$file** a data **$structure** through [gzip](https://en.wikipedia.org/wiki/Gzip).

114 [dumpTempFile](#dumptempfile) - Dump a data structure to a temporary [file](https://en.wikipedia.org/wiki/Computer_file) and return the name of the [file](https://en.wikipedia.org/wiki/Computer_file) created.

115 [dumpTempFileAsJson](#dumptempfileasjson) - Dump a data structure represented as [Json](https://en.wikipedia.org/wiki/JSON) [string](https://en.wikipedia.org/wiki/String_(computer_science)) to a temporary [file](https://en.wikipedia.org/wiki/Computer_file) and return the name of the [file](https://en.wikipedia.org/wiki/Computer_file) created.

116 [enclosedReversedString](#enclosedreversedstring) - Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to enclosed reversed alphanumerics.

117 [enclosedReversedStringUndo](#enclosedreversedstringundo) - Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to enclosed reversed alphanumerics.

118 [enclosedString](#enclosedstring) - Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to enclosed alphanumerics.

119 [enclosedStringUndo](#enclosedstringundo) - Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to enclosed alphanumerics.

120 [encodeBase64](#encodebase64) - Encode an [Ascii](https://en.wikipedia.org/wiki/ASCII) **$string** in base 64.

121 [encodeJson](#encodejson) - Convert a [Perl](http://www.perl.org/) data **$structure** to a [Json](https://en.wikipedia.org/wiki/JSON) [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
122 [evalFile](#evalfile) - Read a [file](https://en.wikipedia.org/wiki/Computer_file) containing [Unicode](https://en.wikipedia.org/wiki/Unicode) content represented as [utf8](https://en.wikipedia.org/wiki/UTF-8), ["eval" in perlfunc](https://metacpan.org/pod/perlfunc#eval) the content, [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) to any errors and then return any result with [lvalue method](http://perldoc.perl.org/perlsub.html#Lvalue-subroutines) methods to access each [hash](https://en.wikipedia.org/wiki/Hash_table) element.

123 [evalFileAsJson](#evalfileasjson) - Read a **$file** containing [Json](https://en.wikipedia.org/wiki/JSON) and return the corresponding [Perl](http://www.perl.org/) data structure.

124 [evalGZipFile](#evalgzipfile) - Read a [file](https://en.wikipedia.org/wiki/Computer_file) compressed with [gzip](https://en.wikipedia.org/wiki/Gzip) containing [Unicode](https://en.wikipedia.org/wiki/Unicode) content represented as [utf8](https://en.wikipedia.org/wiki/UTF-8), ["eval" in perlfunc](https://metacpan.org/pod/perlfunc#eval) the content, [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) to any errors and then return any result with [lvalue method](http://perldoc.perl.org/perlsub.html#Lvalue-subroutines) methods to access each [hash](https://en.wikipedia.org/wiki/Hash_table) element.

125 [evalOrConfess](#evalorconfess) - Evaluate some [code](https://en.wikipedia.org/wiki/Computer_program) successfully or [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) as to why it failed to evaluate successfully.

126 [execPerlOnRemote](#execperlonremote) - Execute some Perl **$code** on the [server](https://en.wikipedia.org/wiki/Server_(computing)) whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp).

127 [expandNewLinesInDocumentation](#expandnewlinesindocumentation) - Expand new lines in [documentation](https://en.wikipedia.org/wiki/Software_documentation), specifically 
 for new line and 

    for two new lines.

128 [expandWellKnownUrlsInDitaFormat](#expandwellknownurlsinditaformat) - Expand short [url](https://en.wikipedia.org/wiki/URL) names found in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) in the format L\[url-name\] in the L\[Dita\] **xref**format.

129 [expandWellKnownUrlsInHtmlFormat](#expandwellknownurlsinhtmlformat) - Expand short [url](https://en.wikipedia.org/wiki/URL) names found in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) in the format L\[url-name\] using the [HTML](https://en.wikipedia.org/wiki/HTML) **a** tag.

130 [expandWellKnownUrlsInHtmlFromPerl](#expandwellknownurlsinhtmlfromperl) - Expand short [url](https://en.wikipedia.org/wiki/URL) names found in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) in the format L\[url-name\] using the [HTML](https://en.wikipedia.org/wiki/HTML) **a** tag.

131 [expandWellKnownUrlsInPerlFormat](#expandwellknownurlsinperlformat) - Expand short [url](https://en.wikipedia.org/wiki/URL) names found in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) in the format L&lt;url-name> using the Perl POD syntax.

132 [expandWellKnownUrlsInPod2Html](#expandwellknownurlsinpod2html) - Expand short [url](https://en.wikipedia.org/wiki/URL) names found in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) in the format =begin [HTML](https://en.wikipedia.org/wiki/HTML) format.

133 [expandWellKnownWordsAsUrlsInHtmlFormat](#expandwellknownwordsasurlsinhtmlformat) - Expand words found in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) using the [HTML](https://en.wikipedia.org/wiki/HTML) **a** tag to supply a definition of that [word](https://en.wikipedia.org/wiki/Doc_(computing)). 
134 [expandWellKnownWordsAsUrlsInMdFormat](#expandwellknownwordsasurlsinmdformat) - Expand words found in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) using the md [url](https://en.wikipedia.org/wiki/URL) to supply a definition of that [word](https://en.wikipedia.org/wiki/Doc_(computing)). 
135 [expandWellKnownWordsInMarkDownFile](#expandwellknownwordsinmarkdownfile) - Expand well known words in a mark down [file](https://en.wikipedia.org/wiki/Computer_file). 
136 [extractCodeBlock](#extractcodeblock) - Extract the block of [code](https://en.wikipedia.org/wiki/Computer_program) delimited by **$comment**, starting at qq($comment-begin), ending at qq($comment-end) from the named **$file** else the current Perl [program](https://en.wikipedia.org/wiki/Computer_program) $0 and return it as a [string](https://en.wikipedia.org/wiki/String_(computer_science)) or [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) if this is not possible.

137 [extractPythonDocumentationFromFiles](#extractpythondocumentationfromfiles) - Extract [Python](https://www.python.org/) [documentation](https://en.wikipedia.org/wiki/Software_documentation) from the specified files.

138 [extractTest](#extracttest) - Remove example markers from [test](https://en.wikipedia.org/wiki/Software_testing) [code](https://en.wikipedia.org/wiki/Computer_program). 
139 [fe](#fe) - Get the extension of a [file](https://en.wikipedia.org/wiki/Computer_file) name.

140 [fff](#fff) - Confess a message with a line position and a [file](https://en.wikipedia.org/wiki/Computer_file) that Geany will jump to if clicked on.

141 [fileInWindowsFormat](#fileinwindowsformat) - Convert a [Unix](https://en.wikipedia.org/wiki/Unix) **$file** name to windows format.

142 [fileLargestSize](#filelargestsize) - Return the largest **$file**.

143 [fileList](#filelist) - Files that match a given search pattern interpreted by ["bsd\_glob" in perlfunc](https://metacpan.org/pod/perlfunc#bsd_glob).

144 [fileMd5Sum](#filemd5sum) - Get the Md5 sum of the content of a **$file**.

145 [fileModTime](#filemodtime) - Get the modified time of a **$file** as seconds since the epoch.

146 [fileOutOfDate](#fileoutofdate) - Calls the specified [sub](https://perldoc.perl.org/perlsub.html) **$make** for each source [file](https://en.wikipedia.org/wiki/Computer_file) that is missing and then again against the **$target** [file](https://en.wikipedia.org/wiki/Computer_file) if any of the **@source** files were missing or the $target [file](https://en.wikipedia.org/wiki/Computer_file) is older than any of the @source files or if the target does not exist.

147 [filePath](#filepath) - Create a [file](https://en.wikipedia.org/wiki/Computer_file) name from a [list](https://en.wikipedia.org/wiki/Linked_list) of  names.

148 [filePathDir](#filepathdir) - Create a [folder](https://en.wikipedia.org/wiki/File_folder) name from a [list](https://en.wikipedia.org/wiki/Linked_list) of  names.

149 [filePathExt](#filepathext) - Create a [file](https://en.wikipedia.org/wiki/Computer_file) name from a [list](https://en.wikipedia.org/wiki/Linked_list) of  names the last of which is assumed to be the extension of the [file](https://en.wikipedia.org/wiki/Computer_file) name.

150 [filePathSeparatorChar](#filepathseparatorchar) - File path separator.

151 [fileSize](#filesize) - Get the size of a **$file** in bytes.

152 [findAllFilesAndFolders](#findallfilesandfolders) - Find all the files and folders under a [folder](https://en.wikipedia.org/wiki/File_folder). 
153 [findDirs](#finddirs) - Find all the folders under a **$folder** and optionally **$filter** the selected folders with a regular expression.

154 [findFiles](#findfiles) - Find all the files under a **$folder** and optionally **$filter** the selected files with a regular expression.

155 [findFileWithExtension](#findfilewithextension) - Find the first [file](https://en.wikipedia.org/wiki/Computer_file) that exists with a path and name of **$file** and an extension drawn from <@ext>.

156 [firstFileThatExists](#firstfilethatexists) - Returns the name of the first [file](https://en.wikipedia.org/wiki/Computer_file) from **@files** that exists or **undef** if none of the named @files exist.

157 [firstNChars](#firstnchars) - First N characters of a [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
158 [flattenArrayAndHashValues](#flattenarrayandhashvalues) - Flatten an [array](https://en.wikipedia.org/wiki/Dynamic_array) of scalars, [array](https://en.wikipedia.org/wiki/Dynamic_array) and [hash](https://en.wikipedia.org/wiki/Hash_table) references to make an [array](https://en.wikipedia.org/wiki/Dynamic_array) of scalars by flattening the [array](https://en.wikipedia.org/wiki/Dynamic_array) references and [hash](https://en.wikipedia.org/wiki/Hash_table) values.

159 [fn](#fn) - Remove the path and extension from a [file](https://en.wikipedia.org/wiki/Computer_file) name.

160 [fne](#fne) - Remove the path from a [file](https://en.wikipedia.org/wiki/Computer_file) name.

161 [folderSize](#foldersize) - Get the size of a **$folder** in bytes.

162 [forEachKeyAndValue](#foreachkeyandvalue) - Iterate over a [hash](https://en.wikipedia.org/wiki/Hash_table) for each key and value.

163 [formatHtmlAndTextTables](#formathtmlandtexttables) - Create text and [HTML](https://en.wikipedia.org/wiki/HTML) versions of a tabular report.

164 [formatHtmlAndTextTablesWaitPids](#formathtmlandtexttableswaitpids) - Wait on all [table](https://en.wikipedia.org/wiki/Table_(information)) formatting pids to complete.

165 [formatHtmlTable](#formathtmltable) - Format an [array](https://en.wikipedia.org/wiki/Dynamic_array) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of scalars as an [HTML](https://en.wikipedia.org/wiki/HTML) [table](https://en.wikipedia.org/wiki/Table_(information)) using the  **%options** described in [formatTableCheckKeys](https://metacpan.org/pod/formatTableCheckKeys).

166 [formatHtmlTablesIndex](#formathtmltablesindex) - Create an index of [HTML](https://en.wikipedia.org/wiki/HTML) reports.

167 [formatSourcePodAsHtml](#formatsourcepodashtml) - Format the [POD](https://perldoc.perl.org/perlpod.html) in the current source [file](https://en.wikipedia.org/wiki/Computer_file) as [HTML](https://en.wikipedia.org/wiki/HTML).

168 [formatString](#formatstring) - Format the specified **$string** so it can be displayed in **$width** columns.

169 [formatTable](#formattable) - Format various **$data** structures as a [table](https://en.wikipedia.org/wiki/Table_(information)) with titles as specified by **$columnTitles**: either a reference to an [array](https://en.wikipedia.org/wiki/Dynamic_array) of column titles or a [string](https://en.wikipedia.org/wiki/String_(computer_science)) each line of which contains the column title as the first [word](https://en.wikipedia.org/wiki/Doc_(computing)) with the rest of the line describing that column.

170 [formatTableA](#formattablea) - Tabularize an [array](https://en.wikipedia.org/wiki/Dynamic_array). 
171 [formatTableAA](#formattableaa) - Tabularize an [array](https://en.wikipedia.org/wiki/Dynamic_array) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array). 
172 [formatTableAH](#formattableah) - Tabularize an [array](https://en.wikipedia.org/wiki/Dynamic_array) of hashes.

173 [formatTableBasic](#formattablebasic) - Tabularize an [array](https://en.wikipedia.org/wiki/Dynamic_array) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of text.

174 [formatTableCheckKeys](#formattablecheckkeys) - Options available for formatting tables.

175 [formatTableClearUpLeft](#formattableclearupleft) - Blank identical column values up and left.

176 [formatTableH](#formattableh) - Tabularize a [hash](https://en.wikipedia.org/wiki/Hash_table). 
177 [formatTableHA](#formattableha) - Tabularize a [hash](https://en.wikipedia.org/wiki/Hash_table) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array). 
178 [formatTableHH](#formattablehh) - Tabularize a [hash](https://en.wikipedia.org/wiki/Hash_table) of hashes.

179 [formatTableMultiLine](#formattablemultiline) - Tabularize text that has new lines in it.

180 [formattedTablesReport](#formattedtablesreport) - Report of all the reports created.

181 [fp](#fp) - Get the path from a [file](https://en.wikipedia.org/wiki/Computer_file) name.

182 [fpgaGowin](#fpgagowin) - Compile [Verilog](https://en.wikipedia.org/wiki/Verilog) to a gowin device.

183 [fpn](#fpn) - Remove the extension from a [file](https://en.wikipedia.org/wiki/Computer_file) name.

184 [fullFileName](#fullfilename) - Full name of a [file](https://en.wikipedia.org/wiki/Computer_file). 
185 [fullyQualifiedFile](#fullyqualifiedfile) - Check whether a **$file** name is fully qualified or not and, optionally, whether it is fully qualified with a specified **$prefix** or not.

186 [fullyQualifyFile](#fullyqualifyfile) - Return the fully qualified name of a [file](https://en.wikipedia.org/wiki/Computer_file). 
187 [genHash](#genhash) - Return a **$bless**ed [hash](https://en.wikipedia.org/wiki/Hash_table) with the specified **$attributes** accessible via [lvalue method](http://perldoc.perl.org/perlsub.html#Lvalue-subroutines) method calls.

188 [genLValueArrayMethods](#genlvaluearraymethods) - Generate [lvalue method](http://perldoc.perl.org/perlsub.html#Lvalue-subroutines) [array](https://en.wikipedia.org/wiki/Dynamic_array) methods in the current package.

189 [genLValueHashMethods](#genlvaluehashmethods) - Generate [lvalue method](http://perldoc.perl.org/perlsub.html#Lvalue-subroutines) [hash](https://en.wikipedia.org/wiki/Hash_table) methods in the current package.

190 [genLValueScalarMethods](#genlvaluescalarmethods) - Generate [lvalue method](http://perldoc.perl.org/perlsub.html#Lvalue-subroutines) scalar methods in the current package, A method whose value has not yet been set will return a new scalar with value **undef**.

191 [genLValueScalarMethodsWithDefaultValues](#genlvaluescalarmethodswithdefaultvalues) - Generate [lvalue method](http://perldoc.perl.org/perlsub.html#Lvalue-subroutines) scalar methods with default values in the current package.

192 [getCCompiler](#getccompiler) - Return the name of the C compiler on this system.

193 [getCodeContext](#getcodecontext) - Recreate the [code](https://en.wikipedia.org/wiki/Computer_program) context for a referenced [sub](https://perldoc.perl.org/perlsub.html). 
194 [getFieldOffsetInStructureFromIncludeFile](#getfieldoffsetinstructurefromincludefile) - Get the offset of a field in a system structures from an include [file](https://en.wikipedia.org/wiki/Computer_file). 
195 [getNumberOfCpus](#getnumberofcpus) - Number of cpus.

196 [getStructureSizeFromIncludeFile](#getstructuresizefromincludefile) - Get the size of a system structure from an include [file](https://en.wikipedia.org/wiki/Computer_file). 
197 [getSubName](#getsubname) - Returns the (package, name, [file](https://en.wikipedia.org/wiki/Computer_file), line) of a [Perl](http://www.perl.org/) **$sub** reference.

198 [getSystemConstantsFromIncludeFile](#getsystemconstantsfromincludefile) - Get the value of the named system constants from an include [file](https://en.wikipedia.org/wiki/Computer_file). 
199 [guidFromMd5](#guidfrommd5) - Create a [guid](https://en.wikipedia.org/wiki/Universally_unique_identifier) from an [MD5](https://en.wikipedia.org/wiki/MD5) [hash](https://en.wikipedia.org/wiki/Hash_table). 
200 [guidFromString](#guidfromstring) - Create a [guid](https://en.wikipedia.org/wiki/Universally_unique_identifier) representation of the [MD5](https://en.wikipedia.org/wiki/MD5) of the content of a [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
201 [hashifyFolderStructure](#hashifyfolderstructure) - Hashify a [list](https://en.wikipedia.org/wiki/Linked_list) of [file](https://en.wikipedia.org/wiki/Computer_file) names to get the corresponding [folder](https://en.wikipedia.org/wiki/File_folder) structure.

202 [hexToAsciiString](#hextoasciistring) - Decode a [string](https://en.wikipedia.org/wiki/String_(computer_science)) of [hexadecimal](https://en.wikipedia.org/wiki/Hexadecimal) digits as an [Ascii](https://en.wikipedia.org/wiki/ASCII) [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
203 [hostName](#hostname) - The name of the host we are running on.

204 [htmlToc](#htmltoc) - Generate a [table](https://en.wikipedia.org/wiki/Table_(information)) of contents for some [HTML](https://en.wikipedia.org/wiki/HTML). 
205 [imageSize](#imagesize) - Return (width, height) of an **$image**.

206 [includeFiles](#includefiles) - Read the given [file](https://en.wikipedia.org/wiki/Computer_file) and expand all lines that start "includeThisFile " with the [file](https://en.wikipedia.org/wiki/Computer_file) named by the rest of the line and keep doing this until all the included files have been expanded or a repetition is detected.

207 [indentString](#indentstring) - Indent lines contained in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) or formatted [table](https://en.wikipedia.org/wiki/Table_(information)) by the specified [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
208 [indexOfMax](#indexofmax) - Find the index of the maximum number in a [list](https://en.wikipedia.org/wiki/Linked_list) of numbers confessing to any ill defined values.

209 [indexOfMin](#indexofmin) - Find the index of the minimum number in a [list](https://en.wikipedia.org/wiki/Linked_list) of numbers confessing to any ill defined values.

210 [intersectionOfHashesAsArrays](#intersectionofhashesasarrays) - Form the intersection of the specified hashes **@h** as one [hash](https://en.wikipedia.org/wiki/Hash_table) whose values are an [array](https://en.wikipedia.org/wiki/Dynamic_array) of corresponding values from each [hash](https://en.wikipedia.org/wiki/Hash_table). 
211 [intersectionOfHashKeys](#intersectionofhashkeys) - Form the intersection of the keys of the specified hashes **@h** as one [hash](https://en.wikipedia.org/wiki/Hash_table) whose keys represent the intersection.

212 [invertHashOfHashes](#inverthashofhashes) - Invert a [hash](https://en.wikipedia.org/wiki/Hash_table) of hashes: given {a}{b} = c return {b}{c} = c.

213 [ipAddressOfHost](#ipaddressofhost) - Get the first [IP address](https://en.wikipedia.org/wiki/IP_address) address of the specified host via Domain Name Services.

214 [ipAddressViaArp](#ipaddressviaarp) - Get the [IP address](https://en.wikipedia.org/wiki/IP_address) address of a [server](https://en.wikipedia.org/wiki/Server_(computing)) on the local network by hostname via arp.

215 [isBlank](#isblank) - Test whether a [string](https://en.wikipedia.org/wiki/String_(computer_science)) is blank.

216 [isFileUtf8](#isfileutf8) - Return the [file](https://en.wikipedia.org/wiki/Computer_file) name quoted if its contents are in [utf8](https://en.wikipedia.org/wiki/UTF-8) else return [undef](https://perldoc.perl.org/functions/undef.html). 
217 [isSubInPackage](#issubinpackage) - Test whether the specified **$package** contains the subroutine &lt;$sub>.

218 [javaPackage](#javapackage) - Extract the package name from a [Java](https://en.wikipedia.org/wiki/Java_(programming_language)) [string](https://en.wikipedia.org/wiki/String_(computer_science)) or [file](https://en.wikipedia.org/wiki/Computer_file). 
219 [javaPackageAsFileName](#javapackageasfilename) - Extract the package name from a [Java](https://en.wikipedia.org/wiki/Java_(programming_language)) [string](https://en.wikipedia.org/wiki/String_(computer_science)) or [file](https://en.wikipedia.org/wiki/Computer_file) and convert it to a [file](https://en.wikipedia.org/wiki/Computer_file) name.

220 [javaScriptExports](#javascriptexports) - Extract the Javascript functions marked for export in a [file](https://en.wikipedia.org/wiki/Computer_file) or [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
221 [keyCount](#keycount) - Count keys down to the specified level.

222 [lengthOfLongestSubArray](#lengthoflongestsubarray) - Given an [array](https://en.wikipedia.org/wiki/Dynamic_array) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) [find](https://en.wikipedia.org/wiki/Find_(Unix)) the length of the longest [sub](https://perldoc.perl.org/perlsub.html) [array](https://en.wikipedia.org/wiki/Dynamic_array). 
223 [lll](#lll) - Log messages with a time stamp and originating [file](https://en.wikipedia.org/wiki/Computer_file) and line number.

224 [loadArrayArrayFromLines](#loadarrayarrayfromlines) - Load an [array](https://en.wikipedia.org/wiki/Dynamic_array) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) from lines of text: each line is an [array](https://en.wikipedia.org/wiki/Dynamic_array) of words.

225 [loadArrayFromLines](#loadarrayfromlines) - Load an [array](https://en.wikipedia.org/wiki/Dynamic_array) from lines of text in a [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
226 [loadArrayHashFromLines](#loadarrayhashfromlines) - Load an [array](https://en.wikipedia.org/wiki/Dynamic_array) of hashes from lines of text: each line is a [hash](https://en.wikipedia.org/wiki/Hash_table) of words.

227 [loadHash](#loadhash) - Load the specified blessed **$hash** generated with [genHash](#genhash) with **%attributes**.

228 [loadHashArrayFromLines](#loadhasharrayfromlines) - Load a [hash](https://en.wikipedia.org/wiki/Hash_table) of [arrays](https://en.wikipedia.org/wiki/Dynamic_array) from lines of text: the first [word](https://en.wikipedia.org/wiki/Doc_(computing)) of each line is the key, the remaining words are the [array](https://en.wikipedia.org/wiki/Dynamic_array) contents.

229 [loadHashFromLines](#loadhashfromlines) - Load a [hash](https://en.wikipedia.org/wiki/Hash_table): first [word](https://en.wikipedia.org/wiki/Doc_(computing)) of each line is the key and the rest is the value.

230 [loadHashHashFromLines](#loadhashhashfromlines) - Load a [hash](https://en.wikipedia.org/wiki/Hash_table) of hashes from lines of text: the first [word](https://en.wikipedia.org/wiki/Doc_(computing)) of each line is the key, the remaining words are the [sub](https://perldoc.perl.org/perlsub.html) [hash](https://en.wikipedia.org/wiki/Hash_table) contents.

231 [lpad](#lpad) - Left Pad the specified **$string** to a multiple of the specified **$length**  with blanks or the specified padding character to a multiple of a specified length.

232 [makeDieConfess](#makedieconfess) - Force [die](http://perldoc.perl.org/functions/die.html) to [confess](http://perldoc.perl.org/Carp.html#SYNOPSIS/) where the death occurred.

233 [makePath](#makepath) - Make the path for the specified [file](https://en.wikipedia.org/wiki/Computer_file) name or [folder](https://en.wikipedia.org/wiki/File_folder) on the local machine.

234 [makePathRemote](#makepathremote) - Make the path for the specified **$file** or [folder](https://en.wikipedia.org/wiki/File_folder) on the [Amazon Web Services](http://aws.amazon.com) instance whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp).

235 [matchPath](#matchpath) - Return the deepest [folder](https://en.wikipedia.org/wiki/File_folder) that exists along a given [file](https://en.wikipedia.org/wiki/Computer_file) name path.

236 [mathematicalBoldItalicString](#mathematicalbolditalicstring) - Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Bold Italic.

237 [mathematicalBoldItalicStringUndo](#mathematicalbolditalicstringundo) - Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Bold Italic.

238 [mathematicalBoldString](#mathematicalboldstring) - Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Bold.

239 [mathematicalBoldStringUndo](#mathematicalboldstringundo) - Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Bold.

240 [mathematicalItalicString](#mathematicalitalicstring) - Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Italic.

241 [mathematicalMonoSpaceString](#mathematicalmonospacestring) - Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical MonoSpace.

242 [mathematicalMonoSpaceStringUndo](#mathematicalmonospacestringundo) - Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical MonoSpace.

243 [mathematicalSansSerifBoldItalicString](#mathematicalsansserifbolditalicstring) - Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Sans Serif Bold Italic.

244 [mathematicalSansSerifBoldItalicStringUndo](#mathematicalsansserifbolditalicstringundo) - Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Sans Serif Bold Italic.

245 [mathematicalSansSerifBoldString](#mathematicalsansserifboldstring) - Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Sans Serif Bold.

246 [mathematicalSansSerifBoldStringUndo](#mathematicalsansserifboldstringundo) - Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Sans Serif Bold.

247 [mathematicalSansSerifItalicString](#mathematicalsansserifitalicstring) - Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Sans Serif Italic.

248 [mathematicalSansSerifItalicStringUndo](#mathematicalsansserifitalicstringundo) - Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Sans Serif Italic.

249 [mathematicalSansSerifString](#mathematicalsansserifstring) - Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Sans Serif.

250 [mathematicalSansSerifStringUndo](#mathematicalsansserifstringundo) - Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [Unicode](https://en.wikipedia.org/wiki/Unicode) Mathematical Sans Serif.

251 [max](#max) - Find the maximum number in a [list](https://en.wikipedia.org/wiki/Linked_list) of numbers confessing to any ill defined values.

252 [maximumLineLength](#maximumlinelength) - Find the longest line in a **$string**.

253 [md5FromGuid](#md5fromguid) - Recover an [MD5](https://en.wikipedia.org/wiki/MD5) sum from a [guid](https://en.wikipedia.org/wiki/Universally_unique_identifier). 
254 [mergeFolder](#mergefolder) - Copy the **$source** [folder](https://en.wikipedia.org/wiki/File_folder) into the **$target** [folder](https://en.wikipedia.org/wiki/File_folder) retaining any existing files not replaced by copied files.

255 [mergeFolderFromRemote](#mergefolderfromremote) - Merge the specified **$Source** [folder](https://en.wikipedia.org/wiki/File_folder) from the corresponding remote [folder](https://en.wikipedia.org/wiki/File_folder) on the [server](https://en.wikipedia.org/wiki/Server_(computing)) whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp).

256 [mergeHashesBySummingValues](#mergehashesbysummingvalues) - Merge a [list](https://en.wikipedia.org/wiki/Linked_list) of hashes **@h** by summing their values.

257 [microSecondsSinceEpoch](#microsecondssinceepoch) - Micro seconds since [Unix](https://en.wikipedia.org/wiki/Unix) epoch.

258 [min](#min) - Find the minimum number in a [list](https://en.wikipedia.org/wiki/Linked_list) of numbers confessing to any ill defined values.

259 [mmm](#mmm) - Log messages with a differential time in milliseconds and originating [file](https://en.wikipedia.org/wiki/Computer_file) and line number.

260 [moveFileNoClobber](#movefilenoclobber) - Rename the **$source** [file](https://en.wikipedia.org/wiki/Computer_file), which must exist, to the **$target** [file](https://en.wikipedia.org/wiki/Computer_file) but only if the $target [file](https://en.wikipedia.org/wiki/Computer_file) does not exist already.

261 [moveFileWithClobber](#movefilewithclobber) - Rename the **$source** [file](https://en.wikipedia.org/wiki/Computer_file), which must exist, to the **$target** [file](https://en.wikipedia.org/wiki/Computer_file) but only if the $target [file](https://en.wikipedia.org/wiki/Computer_file) does not exist already.

262 [nameFromFolder](#namefromfolder) - Create a name from the last [folder](https://en.wikipedia.org/wiki/File_folder) in the path of a [file](https://en.wikipedia.org/wiki/Computer_file) name.

263 [nameFromString](#namefromstring) - Create a readable name from an arbitrary [string](https://en.wikipedia.org/wiki/String_(computer_science)) of text.

264 [nameFromStringRestrictedToTitle](#namefromstringrestrictedtotitle) - Create a readable name from a [string](https://en.wikipedia.org/wiki/String_(computer_science)) of text that might contain a title tag - fall back to [nameFromString](#namefromstring) if that is not possible.

265 [newProcessStarter](#newprocessstarter) - Create a new [process starter](#data-table-text-starter-definition) with which to start parallel [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) up to a specified **$maximumNumberOfProcesses** maximum number of parallel [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) at a time, wait for all the started [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) to finish and then optionally retrieve their saved results as an [array](https://en.wikipedia.org/wiki/Dynamic_array) from the [folder](https://en.wikipedia.org/wiki/File_folder) named by **$transferArea**.

266 [newServiceIncarnation](#newserviceincarnation) - Create a new service incarnation to record the start up of a new instance of a service and return the description as a [Data::Exchange::Service Definition hash](#data-exchange-service-definition).

267 [newUdsr](#newudsr) - Create a communicator - a means to communicate between [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) on the same machine via [Udsr::read](#udsr-read) and [Udsr::write](#udsr-write).

268 [newUdsrClient](#newudsrclient) - Create a new communications client - a means to communicate between [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) on the same machine via [Udsr::read](#udsr-read) and [Udsr::write](#udsr-write).

269 [newUdsrServer](#newudsrserver) - Create a communications [server](https://en.wikipedia.org/wiki/Server_(computing)) - a means to communicate between [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) on the same machine via [Udsr::read](#udsr-read) and [Udsr::write](#udsr-write).

270 [numberOfCpus](#numberofcpus) - Number of cpus scaled by an optional factor - but only if you have nproc.

271 [numberOfLinesInFile](#numberoflinesinfile) - Return the number of lines in a [file](https://en.wikipedia.org/wiki/Computer_file). 
272 [numberOfLinesInString](#numberoflinesinstring) - The number of lines in a [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
273 [numberWithCommas](#numberwithcommas) - Place commas in a number.

274 [nws](#nws) - Normalize white space in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to make comparisons easier.

275 [onAws](#onaws) - Returns 1 if we are on AWS else return 0.

276 [onAwsPrimary](#onawsprimary) - Return 1 if we are on [Amazon Web Services](http://aws.amazon.com) and we are on the primary session instance as defined by [awsParallelPrimaryInstanceId](https://metacpan.org/pod/awsParallelPrimaryInstanceId), return 0 if we are on a secondary session instance, else return **undef** if we are not on [Amazon Web Services](http://aws.amazon.com).

277 [onAwsSecondary](#onawssecondary) - Return 1 if we are on [Amazon Web Services](http://aws.amazon.com) but we are not on the primary session instance as defined by [awsParallelPrimaryInstanceId](https://metacpan.org/pod/awsParallelPrimaryInstanceId), return 0 if we are on the primary session instance, else return **undef** if we are not on [Amazon Web Services](http://aws.amazon.com).

278 [onMac](#onmac) - Are we on mac.

279 [onWindows](#onwindows) - Are we on windows.

280 [overrideAndReabsorbMethods](#overrideandreabsorbmethods) - Override methods down the [list](https://en.wikipedia.org/wiki/Linked_list) of **@packages** then reabsorb any unused methods back up the [list](https://en.wikipedia.org/wiki/Linked_list) of packages so that all the packages have the same methods as the last package with methods from packages mentioned earlier overriding methods from packages mentioned later.

281 [overrideMethods](#overridemethods) - For each method, if it exists in package **$from** then export it to package **$to** replacing any existing method in **$to**, otherwise export the method from package **$to** to package **$from** in order to merge the behavior of the **$from** and **$to** packages with respect to the named methods with duplicates resolved if favour of package **$from**.

282 [overWriteBinaryFile](#overwritebinaryfile) - Write to **$file**, after creating a path to the [file](https://en.wikipedia.org/wiki/Computer_file) with [makePath](https://metacpan.org/pod/makePath) if necessary, the binary content in **$string**.

283 [overWriteFile](#overwritefile) - Write to a **$file**, after creating a path to the $file with [makePath](https://metacpan.org/pod/makePath) if necessary, a **$string** of [Unicode](https://en.wikipedia.org/wiki/Unicode) content encoded as [utf8](https://en.wikipedia.org/wiki/UTF-8).

284 [overWriteHtmlFile](#overwritehtmlfile) - Write an [HTML](https://en.wikipedia.org/wiki/HTML) [file](https://en.wikipedia.org/wiki/Computer_file) to /var/www/html and make it readable.

285 [overWritePerlCgiFile](#overwriteperlcgifile) - Write a [Perl](http://www.perl.org/) [file](https://en.wikipedia.org/wiki/Computer_file) to /usr/lib/cgi-bin and make it executable after checking it for syntax errors.

286 [packBySize](#packbysize) - Given **$N** buckets and a [list](https://en.wikipedia.org/wiki/Linked_list) **@sizes** of (\[size of [file](https://en.wikipedia.org/wiki/Computer_file), name of file\].

287 [pad](#pad) - Pad the specified **$string** to a multiple of the specified **$length**  with blanks or the specified padding character to a multiple of a specified length.

288 [parseCommandLineArguments](#parsecommandlinearguments) - Call the specified **$sub** after classifying the specified [array](https://en.wikipedia.org/wiki/Dynamic_array) of \[arguments\] in **$args** into positional and keyword parameters.

289 [parseDitaRef](#parseditaref) - Parse a [Dita](http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html) reference **$ref** into its components (file name, topic id, id) .

290 [parseFileName](#parsefilename) - Parse a [file](https://en.wikipedia.org/wiki/Computer_file) name into (path, name, extension) considering .

291 [parseIntoWordsAndStrings](#parseintowordsandstrings) - Parse a **$string** into words and quoted [strings](https://en.wikipedia.org/wiki/String_(computer_science)). 
292 [parseS3BucketAndFolderName](#parses3bucketandfoldername) - Parse an [S3](https://aws.amazon.com/s3/) bucket/folder name into a bucket and a [folder](https://en.wikipedia.org/wiki/File_folder) name removing any initial s3://.

293 [parseXmlDocType](#parsexmldoctype) - Parse an [Xml](https://en.wikipedia.org/wiki/XML) DOCTYPE and return a [hash](https://en.wikipedia.org/wiki/Hash_table) indicating its components.

294 [partitionStringsOnPrefixBySize](#partitionstringsonprefixbysize) - Partition a [hash](https://en.wikipedia.org/wiki/Hash_table) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)) and associated sizes into partitions with either a maximum size **$maxSize** or only one element; the [hash](https://en.wikipedia.org/wiki/Hash_table) **%Sizes** consisting of a mapping {string=>size}; with each partition being named with the shortest [string](https://en.wikipedia.org/wiki/String_(computer_science)) prefix that identifies just the [strings](https://en.wikipedia.org/wiki/String_(computer_science)) in that partition.

295 [perlPackage](#perlpackage) - Extract the package name from a [Perl](http://www.perl.org/) [string](https://en.wikipedia.org/wiki/String_(computer_science)) or [file](https://en.wikipedia.org/wiki/Computer_file). 
296 [powerOfTwo](#poweroftwo) - Test whether a number **$n** is a power of two, return the power if it is else **undef**.

297 [ppp](#ppp) - Pad the specified **$string** to a multiple of the specified **$length**  with blanks or the specified padding character to a multiple of a specified length.

298 [prefferedFileName](#prefferedfilename) - Normalize a [file](https://en.wikipedia.org/wiki/Computer_file) name.

299 [printQw](#printqw) - Print an [array](https://en.wikipedia.org/wiki/Dynamic_array) of words in qw() format.

300 [processFilesInParallel](#processfilesinparallel) - Process files in parallel using (8 \* the number of CPUs) [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) with the [process](https://en.wikipedia.org/wiki/Process_management_(computing)) each [file](https://en.wikipedia.org/wiki/Computer_file) is assigned to depending on the size of the [file](https://en.wikipedia.org/wiki/Computer_file) so that each [process](https://en.wikipedia.org/wiki/Process_management_(computing)) is loaded with approximately the same number of bytes of data in total from the files it [processes](https://en.wikipedia.org/wiki/Process_management_(computing)). 
301 [processJavaFilesInParallel](#processjavafilesinparallel) - Process [Java](https://en.wikipedia.org/wiki/Java_(programming_language)) files of known size in parallel using (the number of CPUs) [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) with the [process](https://en.wikipedia.org/wiki/Process_management_(computing)) each item is assigned to depending on the size of the [Java](https://en.wikipedia.org/wiki/Java_(programming_language)) item so that each [process](https://en.wikipedia.org/wiki/Process_management_(computing)) is loaded with approximately the same number of bytes of data in total from the [Java](https://en.wikipedia.org/wiki/Java_(programming_language)) files it [processes](https://en.wikipedia.org/wiki/Process_management_(computing)). 
302 [processSizesInParallel](#processsizesinparallel) - Process items of known size in parallel using (8 \* the number of CPUs) [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) with the [process](https://en.wikipedia.org/wiki/Process_management_(computing)) each item is assigned to depending on the size of the item so that each [process](https://en.wikipedia.org/wiki/Process_management_(computing)) is loaded with approximately the same number of bytes of data in total from the items it [processes](https://en.wikipedia.org/wiki/Process_management_(computing)). 
303 [processSizesInParallelN](#processsizesinparalleln) - Process items of known size in parallel using the specified number **$N** [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) with the [process](https://en.wikipedia.org/wiki/Process_management_(computing)) each [file](https://en.wikipedia.org/wiki/Computer_file) is assigned to depending on the size of the [file](https://en.wikipedia.org/wiki/Computer_file) so that each [process](https://en.wikipedia.org/wiki/Process_management_(computing)) is loaded with approximately the same number of bytes of data in total from the files it [processes](https://en.wikipedia.org/wiki/Process_management_(computing)). 
304 [quoteFile](#quotefile) - Quote a [file](https://en.wikipedia.org/wiki/Computer_file) name.

305 [randomizeArray](#randomizearray) - Randomize an [array](https://en.wikipedia.org/wiki/Dynamic_array). 
306 [readBinaryFile](#readbinaryfile) - Read a binary [file](https://en.wikipedia.org/wiki/Computer_file) on the local machine.

307 [readFile](#readfile) - Return the content of a [file](https://en.wikipedia.org/wiki/Computer_file) residing on the local machine interpreting the content of the [file](https://en.wikipedia.org/wiki/Computer_file) as [utf8](https://en.wikipedia.org/wiki/UTF-8).

308 [readFileFromRemote](#readfilefromremote) - Copy and read a **$file** from the remote machine whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp) and return the content of $file interpreted as [utf8](https://en.wikipedia.org/wiki/UTF-8) .

309 [readFiles](#readfiles) - Read all the files in the specified [list](https://en.wikipedia.org/wiki/Linked_list) of folders into a [hash](https://en.wikipedia.org/wiki/Hash_table). 
310 [readGZipFile](#readgzipfile) - Read the specified [file](https://en.wikipedia.org/wiki/Computer_file) containing compressed [Unicode](https://en.wikipedia.org/wiki/Unicode) content represented as [utf8](https://en.wikipedia.org/wiki/UTF-8) through [gzip](https://en.wikipedia.org/wiki/Gzip).

311 [readStdIn](#readstdin) - Return the contents of STDIN and return the results as either an [array](https://en.wikipedia.org/wiki/Dynamic_array) or a [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
312 [readUtf16File](#readutf16file) - Read a [file](https://en.wikipedia.org/wiki/Computer_file) containing [Unicode](https://en.wikipedia.org/wiki/Unicode) encoded in utf-16.

313 [rectangularArray](#rectangulararray) - Create a two dimensional rectangular [array](https://en.wikipedia.org/wiki/Dynamic_array) whose first dimension is **$first** from a one dimensional linear [array](https://en.wikipedia.org/wiki/Dynamic_array). 
314 [rectangularArray2](#rectangulararray2) - Create a two dimensional rectangular [array](https://en.wikipedia.org/wiki/Dynamic_array) whose second dimension is **$second** from a one dimensional linear [array](https://en.wikipedia.org/wiki/Dynamic_array). 
315 [reinstateWellKnown](#reinstatewellknown) - Contract references to well known Urls to their abbreviated form.

316 [relFromAbsAgainstAbs](#relfromabsagainstabs) - Relative [file](https://en.wikipedia.org/wiki/Computer_file) from one absolute [file](https://en.wikipedia.org/wiki/Computer_file) **$a** against another **$b**.

317 [reloadHashes](#reloadhashes) - Ensures that all the hashes within a tower of data structures have LValue methods to get and set their current keys.

318 [reloadHashes2](#reloadhashes2) - Ensures that all the hashes within a tower of data structures have LValue methods to get and set their current keys.

319 [removeDuplicatePrefixes](#removeduplicateprefixes) - Remove duplicated leading directory names from a [file](https://en.wikipedia.org/wiki/Computer_file) name.

320 [removeFilePathsFromStructure](#removefilepathsfromstructure) - Remove all [file](https://en.wikipedia.org/wiki/Computer_file) paths from a specified **$structure** to make said $structure testable with ["is\_deeply" in Test::More](https://metacpan.org/pod/Test%3A%3AMore#is_deeply).

321 [removeFilePrefix](#removefileprefix) - Removes a [file](https://en.wikipedia.org/wiki/Computer_file) **$prefix** from an [array](https://en.wikipedia.org/wiki/Dynamic_array) of **@files**.

322 [renormalizeFolderName](#renormalizefoldername) - Normalize a [folder](https://en.wikipedia.org/wiki/File_folder) name by ensuring it has a single trailing directory separator.

323 [replaceStringWithString](#replacestringwithstring) - Replace all instances in **$string** of **$source** with **$target**.

324 [reportAttributes](#reportattributes) - Report the attributes present in a **$sourceFile**.

325 [reportAttributeSettings](#reportattributesettings) - Report the current values of the attribute methods in the calling [file](https://en.wikipedia.org/wiki/Computer_file) and optionally write the report to **$reportFile**.

326 [reportExportableMethods](#reportexportablemethods) - Report the exportable methods marked with #e in a **$sourceFile**.

327 [reportReplacableMethods](#reportreplacablemethods) - Report the replaceable methods marked with #r in a **$sourceFile**.

328 [reportSettings](#reportsettings) - Report the current values of parameterless subs.

329 [retrieveFile](#retrievefile) - Retrieve a **$file** created via [Storable](https://metacpan.org/pod/Storable).

330 [runInParallel](#runinparallel) - Process the elements of an [array](https://en.wikipedia.org/wiki/Dynamic_array) in parallel using a maximum of **$maximumNumberOfProcesses** [processes](https://en.wikipedia.org/wiki/Process_management_(computing)). 
331 [runInSquareRootParallel](#runinsquarerootparallel) - Process the elements of an [array](https://en.wikipedia.org/wiki/Dynamic_array) in square root parallel using a maximum of **$maximumNumberOfProcesses** [processes](https://en.wikipedia.org/wiki/Process_management_(computing)). 
332 [s3Delete](#s3delete) - Return an S3 --delete keyword from an S3 option set.

333 [s3DownloadFolder](#s3downloadfolder) - Download a specified **$folder** on S3 to a **$local** [folder](https://en.wikipedia.org/wiki/File_folder) using the specified **%options** if any.

334 [s3FileExists](#s3fileexists) - Return (name, size, date, time) for a **$file** that exists on S3 else () using the specified **%options** if any.

335 [s3ListFilesAndSizes](#s3listfilesandsizes) - Return {file=>size} for all the files in a specified **$folderOrFile** on S3 using the specified **%options** if any.

336 [s3Profile](#s3profile) - Return an S3 profile keyword from an S3 option set.

337 [s3ReadFile](#s3readfile) - Read from a **$file** on S3 and write the contents to a local [file](https://en.wikipedia.org/wiki/Computer_file) **$local** using the specified **%options** if any.

338 [s3ReadString](#s3readstring) - Read from a **$file** on S3 and return the contents as a [string](https://en.wikipedia.org/wiki/String_(computer_science)) using specified **%options** if any.

339 [s3WriteFile](#s3writefile) - Write to a [file](https://en.wikipedia.org/wiki/Computer_file) **$fileS3** on S3 the contents of a local [file](https://en.wikipedia.org/wiki/Computer_file) **$fileLocal** using the specified **%options** if any.

340 [s3WriteString](#s3writestring) - Write to a **$file** on S3 the contents of **$string** using the specified **%options** if any.

341 [s3ZipFolder](#s3zipfolder) - Zip the specified **$source** [folder](https://en.wikipedia.org/wiki/File_folder) and write it to the named **$target** [file](https://en.wikipedia.org/wiki/Computer_file) on S3.

342 [s3ZipFolders](#s3zipfolders) - Zip local folders and [upload](https://en.wikipedia.org/wiki/Upload) them to S3 in parallel.

343 [saveAwsDomain](#saveawsdomain) - Make the [server](https://en.wikipedia.org/wiki/Server_(computing)) at [Amazon Web Services](http://aws.amazon.com) with the given [domain name](https://en.wikipedia.org/wiki/Domain_name) name the default primary [server](https://en.wikipedia.org/wiki/Server_(computing)) as used by all the methods whose names end in **r** or **Remote**.

344 [saveAwsIp](#saveawsip) - Make the [server](https://en.wikipedia.org/wiki/Server_(computing)) at [Amazon Web Services](http://aws.amazon.com) with the given IP address the default primary [server](https://en.wikipedia.org/wiki/Server_(computing)) as used by all the methods whose names end in **r** or **Remote**.

345 [saveCodeToS3](#savecodetos3) - Save source [code](https://en.wikipedia.org/wiki/Computer_program) every **$saveCodeEvery** seconds by zipping [folder](https://en.wikipedia.org/wiki/File_folder) **$folder** to [zip](https://linux.die.net/man/1/zip) [file](https://en.wikipedia.org/wiki/Computer_file) **$zipFileName** then saving this [zip](https://linux.die.net/man/1/zip) [file](https://en.wikipedia.org/wiki/Computer_file) in the specified [S3](https://aws.amazon.com/s3/) **$bucket** using any additional [S3](https://aws.amazon.com/s3/) parameters in **$S3Parms**.

346 [saveSourceToS3](#savesourcetos3) - Save source [code](https://en.wikipedia.org/wiki/Computer_program). 
347 [searchDirectoryTreeForSubFolders](#searchdirectorytreeforsubfolders) - Search the specified directory under the specified [folder](https://en.wikipedia.org/wiki/File_folder) for [sub](https://perldoc.perl.org/perlsub.html) folders.

348 [searchDirectoryTreesForMatchingFiles](#searchdirectorytreesformatchingfiles) - Search the specified directory [trees](https://en.wikipedia.org/wiki/Tree_(data_structure)) for the files (not folders) that match the specified [file name extensions](https://en.wikipedia.org/wiki/List_of_filename_extensions). 
349 [setCombination](#setcombination) - Count the elements in sets **@s** represented as [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)) and/or the keys of hashes.

350 [setDifference](#setdifference) - Subtract the keys in the second set represented as a [hash](https://en.wikipedia.org/wiki/Hash_table) from the first set represented as a [hash](https://en.wikipedia.org/wiki/Hash_table) to create a new [hash](https://en.wikipedia.org/wiki/Hash_table) showing the set difference between the two.

351 [setFileExtension](#setfileextension) - Given a **$file**, change its extension to **$extension**.

352 [setIntersection](#setintersection) - Intersection of sets **@s** represented as [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)) and/or the keys of hashes.

353 [setIntersectionOverUnion](#setintersectionoverunion) - Returns the size of the intersection over the size of the union of one or more sets **@s** represented as [arrays](https://en.wikipedia.org/wiki/Dynamic_array) and/or hashes.

354 [setPackageSearchOrder](#setpackagesearchorder) - Set a package search order for methods requested in the current package via AUTOLOAD.

355 [setPartitionOnIntersectionOverUnion](#setpartitiononintersectionoverunion) - Partition, at a level of **$confidence** between 0 and 1, a set of sets **@sets** so that within each partition the [setIntersectionOverUnion](#setintersectionoverunion) of any two sets in the partition is never less than the specified level of _$confidence\*\*2_.

356 [setPartitionOnIntersectionOverUnionOfHashStringSets](#setpartitiononintersectionoverunionofhashstringsets) - Partition, at a level of **$confidence** between 0 and 1, a set of sets **$hashSet** represented by a [hash](https://en.wikipedia.org/wiki/Hash_table), each [hash](https://en.wikipedia.org/wiki/Hash_table) value being a [string](https://en.wikipedia.org/wiki/String_(computer_science)) containing words and punctuation, each [word](https://en.wikipedia.org/wiki/Doc_(computing)) possibly capitalized, so that within each partition the [setPartitionOnIntersectionOverUnionOfSetsOfWords](#setpartitiononintersectionoverunionofsetsofwords) of any two sets of words in the partition is never less than the specified **$confidence\*\*2** and the partition entries are the [hash](https://en.wikipedia.org/wiki/Hash_table) keys of the [string](https://en.wikipedia.org/wiki/String_(computer_science)) sets.

357 [setPartitionOnIntersectionOverUnionOfHashStringSetsInParallel](#setpartitiononintersectionoverunionofhashstringsetsinparallel) - Partition, at a level of **$confidence** between 0 and 1, a set of sets **$hashSet** represented by a [hash](https://en.wikipedia.org/wiki/Hash_table), each [hash](https://en.wikipedia.org/wiki/Hash_table) value being a [string](https://en.wikipedia.org/wiki/String_(computer_science)) containing words and punctuation, each [word](https://en.wikipedia.org/wiki/Doc_(computing)) possibly capitalized, so that within each partition the [setPartitionOnIntersectionOverUnionOfSetsOfWords](#setpartitiononintersectionoverunionofsetsofwords) of any two sets of words in the partition is never less than the specified **$confidence\*\*2** and the partition entries are the [hash](https://en.wikipedia.org/wiki/Hash_table) keys of the [string](https://en.wikipedia.org/wiki/String_(computer_science)) sets.

358 [setPartitionOnIntersectionOverUnionOfSetsOfWords](#setpartitiononintersectionoverunionofsetsofwords) - Partition, at a level of **$confidence** between 0 and 1, a set of sets **@sets** of words so that within each partition the [setIntersectionOverUnion](#setintersectionoverunion) of any two sets of words in the partition is never less than the specified _$confidence\*\*2_.

359 [setPartitionOnIntersectionOverUnionOfStringSets](#setpartitiononintersectionoverunionofstringsets) - Partition, at a level of **$confidence** between 0 and 1, a set of sets **@strings**, each set represented by a [string](https://en.wikipedia.org/wiki/String_(computer_science)) containing words and punctuation, each [word](https://en.wikipedia.org/wiki/Doc_(computing)) possibly capitalized, so that within each partition the [setPartitionOnIntersectionOverUnionOfSetsOfWords](#setpartitiononintersectionoverunionofsetsofwords) of any two sets of words in the partition is never less than the specified _$confidence\*\*2_.

360 [setPermissionsForFile](#setpermissionsforfile) - Apply [chmod](https://linux.die.net/man/1/chmod) to a **$file** to set its **$permissions**.

361 [setUnion](#setunion) - Union of sets **@s** represented as [arrays](https://en.wikipedia.org/wiki/Dynamic_array) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)) and/or the keys of hashes.

362 [showGotVersusWanted](#showgotversuswanted) - Show the difference between the wanted [string](https://en.wikipedia.org/wiki/String_(computer_science)) and the wanted [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
363 [showHashes](#showhashes) - Create a map of all the keys within all the hashes within a tower of data structures.

364 [showHashes2](#showhashes2) - Create a map of all the keys within all the hashes within a tower of data structures.

365 [squareArray](#squarearray) - Create a two dimensional square [array](https://en.wikipedia.org/wiki/Dynamic_array) from a one dimensional linear [array](https://en.wikipedia.org/wiki/Dynamic_array). 
366 [startProcess](#startprocess) - Start new [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) while the number of child [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) recorded in **%$pids** is less than the specified **$maximum**.

367 [storeFile](#storefile) - Store into a **$file**, after creating a path to the [file](https://en.wikipedia.org/wiki/Computer_file) with [makePath](https://metacpan.org/pod/makePath) if necessary, a data **$structure** via [Storable](https://metacpan.org/pod/Storable).

368 [stringMd5Sum](#stringmd5sum) - Get the Md5 sum of a **$string** that might contain [utf8](https://en.wikipedia.org/wiki/UTF-8) [code](https://en.wikipedia.org/wiki/Computer_program) points.

369 [stringsAreNotEqual](#stringsarenotequal) - Return the common start followed by the two non equal tails of two non equal [strings](https://en.wikipedia.org/wiki/String_(computer_science)) or an empty [list](https://en.wikipedia.org/wiki/Linked_list) if the [strings](https://en.wikipedia.org/wiki/String_(computer_science)) are equal.

370 [subNameTraceBack](#subnametraceback) - Find the names of the calling subroutines and return them as a blank separated [string](https://en.wikipedia.org/wiki/String_(computer_science)) of names.

371 [subScriptString](#subscriptstring) - Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [sub](https://perldoc.perl.org/perlsub.html) scripts.

372 [subScriptStringUndo](#subscriptstringundo) - Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to [sub](https://perldoc.perl.org/perlsub.html) scripts.

373 [sumAbsAndRel](#sumabsandrel) - Combine zero or more absolute and relative names of **@files** starting at the current working [folder](https://en.wikipedia.org/wiki/File_folder) to get an absolute [file](https://en.wikipedia.org/wiki/Computer_file) name.

374 [summarizeColumn](#summarizecolumn) - Count the number of unique instances of each value a column in a [table](https://en.wikipedia.org/wiki/Table_(information)) assumes.

375 [superScriptString](#superscriptstring) - Convert alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to super scripts.

376 [superScriptStringUndo](#superscriptstringundo) - Undo alphanumerics in a [string](https://en.wikipedia.org/wiki/String_(computer_science)) to super scripts.

377 [swapFilePrefix](#swapfileprefix) - Swaps the start of a **$file** name from a **$known** name to a **$new** one if the [file](https://en.wikipedia.org/wiki/Computer_file) does in fact start with the $known name otherwise returns the original [file](https://en.wikipedia.org/wiki/Computer_file) name as it is.

378 [swapFolderPrefix](#swapfolderprefix) - Given a **$file**, swap the [folder](https://en.wikipedia.org/wiki/File_folder) name of the $file from **$known** to **$new** if the [file](https://en.wikipedia.org/wiki/Computer_file) $file starts with the $known [folder](https://en.wikipedia.org/wiki/File_folder) name else return the $file as it is.

379 [syncFromS3InParallel](#syncfroms3inparallel) - Download from [S3](https://aws.amazon.com/s3/) by using "aws [S3](https://aws.amazon.com/s3/) sync --exclude '\*' --include '.

380 [syncToS3InParallel](#synctos3inparallel) - Upload to [S3](https://aws.amazon.com/s3/) by using "aws [S3](https://aws.amazon.com/s3/) sync --exclude '\*' --include '.

381 [temporaryFile](#temporaryfile) - Create a new, empty, temporary [file](https://en.wikipedia.org/wiki/Computer_file). 
382 [temporaryFolder](#temporaryfolder) - Create a new, empty, temporary [folder](https://en.wikipedia.org/wiki/File_folder). 
383 [timeStamp](#timestamp) - Hours:minute:seconds.

384 [transitiveClosure](#transitiveclosure) - Transitive closure of a [hash](https://en.wikipedia.org/wiki/Hash_table) of hashes.

385 [trim](#trim) - Remove any white space from the front and end of a [string](https://en.wikipedia.org/wiki/String_(computer_science)). 
386 [Udsr::kill](#udsr-kill) - Kill a communications [server](https://en.wikipedia.org/wiki/Server_(computing)). 
387 [Udsr::read](#udsr-read) - Read a message from the [newUdsrServer](#newudsrserver) or the [newUdsrClient](#newudsrclient).

388 [Udsr::webUser](#udsr-webuser) - Create a systemd installed [server](https://en.wikipedia.org/wiki/Server_(computing)) that [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) [HTTP](https://en.wikipedia.org/wiki/HTTP) requests using a specified [userid](https://en.wikipedia.org/wiki/User_identifier). 
389 [Udsr::write](#udsr-write) - Write a communications message to the [newUdsrServer](#newudsrserver) or the [newUdsrClient](#newudsrclient).

390 [unbless](#unbless) - Remove the effects of bless from a [Perl](http://www.perl.org/) data **$structure** enabling it to be converted to [Json](https://en.wikipedia.org/wiki/JSON) or compared with [Test::More::is\_deeply](https://metacpan.org/pod/Test%3A%3AMore%3A%3Ais_deeply).

391 [unionOfHashesAsArrays](#unionofhashesasarrays) - Form the union of the specified hashes **@h** as one [hash](https://en.wikipedia.org/wiki/Hash_table) whose values are a [array](https://en.wikipedia.org/wiki/Dynamic_array) of corresponding values from each [hash](https://en.wikipedia.org/wiki/Hash_table). 
392 [unionOfHashKeys](#unionofhashkeys) - Form the union of the keys of the specified hashes **@h** as one [hash](https://en.wikipedia.org/wiki/Hash_table) whose keys represent the union.

393 [uniqueNameFromFile](#uniquenamefromfile) - Create a unique name from a [file](https://en.wikipedia.org/wiki/Computer_file) name and the [MD5](https://en.wikipedia.org/wiki/MD5) sum of its content.

394 [updateDocumentation](#updatedocumentation) - Update the [documentation](https://en.wikipedia.org/wiki/Software_documentation) for a Perl [module](https://en.wikipedia.org/wiki/Modular_programming) from the comments in its source [code](https://en.wikipedia.org/wiki/Computer_program). 
395 [updatePerlModuleDocumentation](#updateperlmoduledocumentation) - Update the [documentation](https://en.wikipedia.org/wiki/Software_documentation) in a **$perlModule** and display said [documentation](https://en.wikipedia.org/wiki/Software_documentation) in a web [web browser](https://en.wikipedia.org/wiki/Web_browser). 
396 [userId](#userid) - Get or confirm the [userid](https://en.wikipedia.org/wiki/User_identifier) we are currently running under.

397 [versionCode](#versioncode) - YYYYmmdd-HHMMSS.

398 [versionCodeDashed](#versioncodedashed) - YYYY-mm-dd-HH:MM:SS.

399 [waitForAllStartedProcessesToFinish](#waitforallstartedprocessestofinish) - Wait until all the [processes](https://en.wikipedia.org/wiki/Process_management_(computing)) started by [startProcess](#startprocess) have finished.

400 [wellKnownUrls](#wellknownurls) - Short names for some well known urls.

401 [writeBinaryFile](#writebinaryfile) - Write to a new **$file**, after creating a path to the [file](https://en.wikipedia.org/wiki/Computer_file) with [makePath](https://metacpan.org/pod/makePath) if necessary, the binary content in **$string**.

402 [writeFile](#writefile) - Write to a new **$file**, after creating a path to the $file with [makePath](https://metacpan.org/pod/makePath) if necessary, a **$string** of [Unicode](https://en.wikipedia.org/wiki/Unicode) content encoded as [utf8](https://en.wikipedia.org/wiki/UTF-8).

403 [writeFiles](#writefiles) - Write the values of a **$hash** reference into files identified by the key of each value using [overWriteFile](#overwritefile) optionally swapping the prefix of each [file](https://en.wikipedia.org/wiki/Computer_file) from **$old** to **$new**.

404 [writeFileToRemote](#writefiletoremote) - Write to a new **$file**, after creating a path to the [file](https://en.wikipedia.org/wiki/Computer_file) with [makePath](https://metacpan.org/pod/makePath) if necessary, a **$string** of [Unicode](https://en.wikipedia.org/wiki/Unicode) content encoded as [utf8](https://en.wikipedia.org/wiki/UTF-8) then copy the $file to the remote [server](https://en.wikipedia.org/wiki/Server_(computing)) whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp).

405 [writeGZipFile](#writegzipfile) - Write to a **$file**, after creating a path to the [file](https://en.wikipedia.org/wiki/Computer_file) with [makePath](https://metacpan.org/pod/makePath) if necessary, through [gzip](https://en.wikipedia.org/wiki/Gzip) a **$string** whose content is encoded as [utf8](https://en.wikipedia.org/wiki/UTF-8).

406 [writeStructureTest](#writestructuretest) - Write a [test](https://en.wikipedia.org/wiki/Software_testing) for a data **$structure** with [file](https://en.wikipedia.org/wiki/Computer_file) names in it.

407 [writeTempFile](#writetempfile) - Write an [array](https://en.wikipedia.org/wiki/Dynamic_array) of [strings](https://en.wikipedia.org/wiki/String_(computer_science)) as lines to a temporary [file](https://en.wikipedia.org/wiki/Computer_file) and return the [file](https://en.wikipedia.org/wiki/Computer_file) name.

408 [wwwDecode](#wwwdecode) - Percent decode a [url](https://en.wikipedia.org/wiki/URL) **$string** per: https://en.

409 [wwwEncode](#wwwencode) - Percent encode a [url](https://en.wikipedia.org/wiki/URL) per: https://en.

410 [wwwGitHubAuth](#wwwgithubauth) - Logon as a [GitHub](https://github.com/philiprbrenan) [Oauth](https://en.wikipedia.org/wiki/OAuth) app per: [https://github.](https://github.)

411 [xxx](#xxx) - Execute a [shell](https://en.wikipedia.org/wiki/Shell_(computing)) command optionally checking its response.

412 [xxxr](#xxxr) - Execute a command **$cmd** via [Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) on the [server](https://en.wikipedia.org/wiki/Server_(computing)) whose [IP address](https://en.wikipedia.org/wiki/IP_address) address is specified by **$ip** or returned by [awsIp](https://metacpan.org/pod/awsIp).

413 [yyy](#yyy) - Execute a block of [shell](https://en.wikipedia.org/wiki/Shell_(computing)) commands line by line after removing comments - stop if there is a non zero return [code](https://en.wikipedia.org/wiki/Computer_program) from any command.

414 [zzz](#zzz) - Execute lines of commands after replacing new lines with && then check that the pipeline execution results in a return [code](https://en.wikipedia.org/wiki/Computer_program) of zero and that the execution results match the optional regular expression if one has been supplied; confess() to an error if either check fails.

# Installation

This [module](https://en.wikipedia.org/wiki/Modular_programming) is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and [install](https://en.wikipedia.org/wiki/Installation_(computer_programs)) via **cpan**:

    sudo [CPAN](https://metacpan.org/author/PRBRENAN) [install](https://en.wikipedia.org/wiki/Installation_(computer_programs)) Data::Table::Text

# Author

[philiprbrenan@gmail.com](mailto:philiprbrenan@gmail.com)

[http://www.appaapps.com](http://www.appaapps.com)

# Copyright

Copyright (c) 2016-2023 Philip R Brenan.

This [module](https://en.wikipedia.org/wiki/Modular_programming) is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

# Acknowledgements

Thanks to the following [people](https://en.wikipedia.org/wiki/Person) for their [help](https://en.wikipedia.org/wiki/Online_help) with this [module](https://en.wikipedia.org/wiki/Modular_programming): 
- [mim@cpan.org](mailto:mim@cpan.org)

    Testing on windows

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 110:

    Non-ASCII character seen before =encoding in '𝗘𝘅𝗮𝗺𝗽𝗹𝗲'. Assuming CP1252

- Around line 12130:

    Unterminated L<...> sequence
