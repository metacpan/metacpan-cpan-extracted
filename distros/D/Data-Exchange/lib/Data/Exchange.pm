#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib
#-------------------------------------------------------------------------------
# Exchange files and update issues with your colleagues via an S3 bucket or rsync.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2018
#-------------------------------------------------------------------------------
# podDocumentation
# rsync remote requires we create the target nexus folder

package Data::Exchange;
our $VERSION = q(20181002);
require v5.16;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use POSIX qw(strftime);                                                         # http://www.cplusplus.com/reference/ctime/strftime/
use utf8;

sub debug        {0}                                                            # 0 - distribution, 1 - test, 2 - production
sub testTransport{2}                                                            # 0 - S3, 1 - rsync locally, 2 - rsync remote

sub lll(@)                                                                      # Log messages
 {my $m = join '', @_;
  return unless $m =~ m(\S)s;                                                   # Blank messages
  say STDERR $m;
  if (userId =~ m(\Aphil\Z)s)
   {appendFile(q(/home/phil/zzz2.txt), dateTimeStamp." $m\n");
   }
 }

lll "Exchange Start version $VERSION";

if (@ARGV)                                                                      # Process any command line arguments
 {parseCommandLineArguments
   {my ($pos, $key) = @_;
    lll "Exchange parse ", dump(\@ARGV);
    if (my $f = $$key{file})
     {lll "Evaluate: $f";
      my $p = evalFile($f);
      my $x = new(%$p);
      lll "Exchange go\n", dump($x);
      $x->go();
      exit;
     }
   } \@ARGV,
   {file=>q(The file from which to read parameters),
   }
 }

sub boldFilesWithChanges                                                        #P Bold file names with changed contents                                                    # Bold file names with changed contents
 {0
 }
sub bucket                                                                      #P Default bucket used for exchanges
 {q(ryffine.exchange)
 }

sub issueFileExtension                                                          #P Default  extension that identifies issue files
 {q(txt)
 }

sub nexus                                                                       #P Default nexus folder every-one can reach
 {return fpf(q(phil@13.58.60.171:/home/phil/perl/xxx/)) if testTransport == 2;
  fpf(q(/home/phil/perl/xxxNexus/));
 }

sub quiet                                                                       #P Quiet S3/rsync if true
 {0
 }

sub rsyncOptions                                                                #P Rsync options
 {q(-mpqrt)
 }

sub sep                                                                         #P Time section separator
 {q(At \d\d\d\d\.\d\d\.\d\d \d\d:\d\d:\d\d \d{7} from \w+);
 }

sub transport                                                                   #P Default file transferm can be q(s3) or q(rsync)
 {q(rsync)
 }

sub writeLine                                                                   #P Write line
 {q(Write below then remove this line when done);
 }

#D1 File and Issue Exchanger                                                    # Exchange files and update issues with your colleagues via an S3 bucket or rsync.

sub new(@)                                                                      # Create a new exchanger for a specified user allowing them to exchange files and issues with their colleagues via an S3 bucket or rsync - see: L<Data::Exchange Definition|/Data::Exchange Definition> for the attributes that can be set by this constructor.
 {my (@parms) = @_;                                                             # Optional parameters
  genHash(q(Data::Exchange::Details),                                           # Exchanger attributes.
    boldFilesWithChanges => boldFilesWithChanges,                               # Bold file names with changed contents
    bucket               => bucket,                                             # The meeting point expressed as bucket/optionalPrefix for S3 transport
    exchange             => undef,                                              # Folder containing files locally
    ext                  => issueFileExtension,                                 # Extension of issue files
    interval             => q(120),                                             # Interval between exchanges
    nexus                => nexus,                                              # The meeting point expressed as a target for rsync transport
    quiet                => quiet,                                              # Quiet S3/rsync if true
    rsyncOptions         => rsyncOptions,                                       # Rsync options
    s3Parms              =>  q(--profile fmc),                                  # Additional S3 parms
    service              => undef,                                              #P Service incarnation
    start                => time,                                               # Time this exchanger was  started
    transport            => transport,                                          # Default file transfer
    user                 => undef,                                              # User who owns this instance
    version              => $VERSION,                                           #P Version of this software
    inProgressFiles      => {},                                                 #P Files that are in progress and so cannot be updated
    @_,
   );
 }

my $stampCount = 0;                                                             # Separate otherwise identical time stamps with one second resolution

sub Data::Exchange::Details::stamp($)                                           #P Match files that have the same file name.
 {my ($x) = @_;                                                                 # Exchanger
  my $c = sprintf("%07d", ++$stampCount);                                       # Sequence number
  my $u = $x->user;                                                             # User
  strftime(qq(At %Y.%m.%d %H:%M:%S $c from $u\n), gmtime)                       # Stamp
 }

sub replaceWriteLine($$)                                                        #P Replace the write line in a file
 {my ($file, $line) = @_;                                                       # File, new line
  my $w = writeLine;                                                            # Write line
  my $s = my $S = readFile($file);                                              # Read file
     $s =~ s(\A\+$w\n) ($line\n)s;                                              # Change write line to add message and release
  owf($file, $s) unless $s eq $S;                                               # Rewrite file
 }

sub cutByTime($)                                                                #P Cut a single file into time sections.
 {my ($file) = @_;                                                              # File

  my $t = readFile($file);                                                      # Read file
  my $s = sep;
  my $w = writeLine;
  my @a = split /(?=^$s$)/m, $t;                                                # Split into time sections
  my @b;
  for(@a)
   {if (/\A\s*($s\s*)?(\+$w\s*)+\Z/s)                                           # Ignore empty sections
     {lll "cutByTime ignored $_";
     }
    else
     {lll "cutByTime saved   $_";
     push @b, $_;
     }
   }
  @b
 }

sub Data::Exchange::Details::findIssueFiles($)                                  #P Find all the files that are issues
 {my ($x) = @_;                                                                 # Exchanger
  searchDirectoryTreesForMatchingFiles
   ($x->exchange,
    $x->ext);
 }

sub inProgressFile($)                                                           #P Check whether a file is a work in progress depending on whether it has a plus sign in column 1 of line 1 or not.
 {my ($file) = @_;                                                              # File
  return 0 unless -e $file;
  my $s = readFile($file);
  my $r = $s =~ m(\A\+)s ? 1 : 0;                                               # Plus sign present or not
  $r
 }

sub Data::Exchange::Details::findInProgressFiles($)                             #P Find all the files that are in progress.
 {my ($x) = @_;                                                                 # Exchanger

  my %files;
  for my $file($x->findIssueFiles)                                              # Find all issue files in progress
   {if (inProgressFile($file))
     {$files{$file}++
     }
   }

  $x->inProgressFiles = \%files
 }

sub Data::Exchange::Details::assemble($@)                                       #P Assemble the time sections in multiple files into one file.
 {my ($x, @files) = @_;                                                         # Exchanger, Files

  my %times;
  for my $file(@files)                                                          # Time sections
   {for my $s(cutByTime($file))
     {$times{substr($s, 0, length($x->stamp))} = $s;                            # Hash of sections by time
     }
   }

  my @t = map {$times{$_}}                                                      # Sections in reverse time order
    reverse sort keys %times;

  my $t = join '', @t;                                                          # Text of new file
  $t
 }

sub Data::Exchange::Details::matchFiles($)                                      #P Match files that have the same file name.
 {my ($x) = @_;                                                                 # Exchanger
  my %files;
  $x->exchange or confess;
  my $user = $x->user;

  for my $file($x->findIssueFiles)                                              # Files that can be matched
   {my $f = fne $file;
    $files{$f}{$file}++;
   }

  for my $file(sort keys %files)                                                # Do not match files that are in progress
   {if ($x->inProgressFiles->{fpe($x->localFolder, $file, $x->ext)})
     {delete $files{$file};
     }
   }

  if (!keys %files)
   {lll "Match files: no files to match";
    return;
   }
  else
   {lll "Match files ", dump(\%files);
   }

  for my $file(sort keys %files)                                                # Assemble issue files
   {my $subFiles = $files{$file};
    lll "Match file $file with ", dump($subFiles);
    my $f = fpf($x->exchange, $x->user, $file);                                 # User's copy of issue
    if (-e $f and inProgressFile($f))
     {lll "Match file $file with in progress file $f";
      next;
     }
    my $w = writeLine;
    my @F = sort keys %$subFiles;
    if (@F == 1)                                                                # A single file is already assembled
     {lll "Match file for user $user: ", dump([@F]);
      my $F = $F[0];
      if ($F =~ m(/$user/)s)
       {lll "Match file $f is a single user file and so does not need to be reassembled";
       }
      elsif (!-e $f)
       {lll "Match file create $f from $F";
        writeFile($f, qq(+$w\n\n\n).readFile($F));
       }
      else
       {lll "Match file cannot create file $f from $F";
       }
     }
    else                                                                        # Assemble files
     {my $a = $x->assemble(keys %$subFiles);
      if (-e $f)
       {my $b = readFile($f);
        if ($a ne $b)
         {my $c = qq(+$w\n\n\n).$a;
          lll "Match files update $f\n$a";
          if (!inProgressFile($f))                                              # Last minute check that the file is not in progress
           {$x->service->check;                                                 # Check that we are still the update service
            owf($f, $c);
           }
         }
       }
     }
   }
 }

sub Data::Exchange::Details::listFiles($)                                       #P List user files
 {my ($x) = @_;                                                                 # Exchanger
  my @files;

  my @f = searchDirectoryTreesForMatchingFiles                                  # Find files to match
   ($x->exchange,
    $x->ext);

  my $sep = sep;

  for my $file(@f)                                                              # Match files
   {my $t = readFile($file);                                                    # Read file
    my @t = split /(?=^$sep$)/m, $t;                                            # Split into time sections
    for my $t(keys @t)
     {$t[$t] =~ s($sep) (At $t\n)gs;
     }
    push @files, [$file, @t];
   }

  [@files]
 }

sub boldFileName($)                                                             #P Create a bold file name
 {my ($file) = @_;                                                              # File name
  my $p = fp $file;
  my $f = fn $file;
  my $x = fe $file;
  fpe($p, boldString($f), $x)
 }

sub unBoldFileName($)                                                           #P Remove bolding from file name
 {my ($file) = @_;                                                              # File name
  boldStringUndo($file)
 }

sub Data::Exchange::Details::unBoldFiles($)                                     #P Make all issue files non bold.
 {my ($x) = @_;                                                                 # Exchanger
  my @files = searchDirectoryTreesForMatchingFiles                              # Issue files
   ($x->exchange,
    $x->ext);

  for my $File(@files)                                                          # Each file
   {if (!inProgressFile($File))
     {my $file = boldStringUndo($File);
      qx(cp $File $file; rm $File) if $file ne $File;                           # Unbold file name
     }
   }
 }

sub Data::Exchange::Details::localFolder($)                                     #P The local folder containing the users own files.
 {my ($x) = @_;                                                                 # Exchanger
  fpd($x->exchange, $x->user);
 }

sub Data::Exchange::Details::stampUnstampedFiles($)                             #P Add a time stamp to files that are no longer in progress
 {my ($x) = @_;                                                                 # Exchanger
  my $sep = sep;
  my $ipf = $x->inProgressFiles;
  for my $file($x->findIssueFiles)                                              # Each issue file
   {if (!$ipf->{$file})                                                         # Each updateable issue file
     {my $s = readFile($file);                                                  # Read file
      if ($s !~ m(\A$sep)s)                                                     # Add stamp if not stamped and not in progress
       {owf($file, $x->stamp.$s);                                               # Write stamp
       }
     }
   }
 }

sub Data::Exchange::Details::exchangeUp($)                                      #P Send one set of files.
 {my ($x) = @_;                                                                 # Exchanger
  if ($x->transport =~ m(\Arsync\Z)i)                                           # Empty folder reached by rsync
   {my $o = $x->rsyncOptions;                                                   # Rsync options
    my $s = fpd($x->exchange, $x->user);                                        # User's own files locally
    my $t = fpd($x->nexus,    $x->user);                                        # User's own files on nexus
    makePath($_) for $s, $t;
    my $c = qq(rsync $o $s $t);                                                 # Command
    qx($c 2>&1);                                                                # Execute
   }
  else                                                                          # Use S3 as default transport
   {my $s = fpd($x->localFolder);                                               # User's own files
    my $t = fpd($x->bucket, $x->user);                                          # User's own files on S3
    my $p = $x->s3Parms;                                                        # Additional parameters for s3
    my $q = $x->quiet ? q(--quiet) : q();                                       # Quiet S3
    lll my $c = qq(aws s3 sync $s s3://$t $q --delete $p);                      # Command
    lll qx($c 2>&1);                                                            # Execute
   }
 }

sub Data::Exchange::Details::exchangeDown($)                                    #P Receive one set of files.
 {my ($x) = @_;                                                                 # Exchanger
  if ($x->transport =~ m(\Arsync\Z)i)                                           # Empty folder reached by rsync
   {my $o = $x->rsyncOptions;                                                   # Rsync options
    my $u = $x->user;                                                           # User
    my $s = fpd($x->nexus);                                                     # Nexus
    my $t = fpd($x->exchange);                                                  # Local files
    makePath($_) for $s, $t;
    my $c = qq(rsync $o --exclude="*/$u/*" $s $t);                          # Command
    qx($c 2>&1);                                                            # Execute
   }
  else                                                                          # Use S3 as default transport
   {my $u = $x->user;                                                           # Receiver
    my $s = fpd($x->bucket);                                                    # User's own files on S3
    my $t = fpd($x->exchange);                                                  # All possible exchange files
    my $p = $x->s3Parms;                                                        # Additional parameters for s3
    my $q = $x->quiet ? q(--quiet) : q();                                       # Quiet S3
    lll my $c = qq(aws s3 sync s3://$s $t $q --exclude "$u/*" $p);              # Command
    lll qx($c 2>&1);                                                            # Execute
   }
 }

sub Data::Exchange::Details::exchangeOneSet($)                                  #P Exchange one set of files.
 {my ($x) = @_;                                                                 # Exchanger
  makePath(fpd($x->exchange, $x->user));                                        # Otherwise no issues will be created for this user
  lll "\nExchangeOneSet";
# $x->unBoldFiles;                                                              # Unbold file names
  $x->findInProgressFiles;                                                      # Issue files not in progress which can, therefore, be updated
  $x->stampUnstampedFiles;                                                      # Stamp unstampted files
  $x->exchangeUp;                                                               # Send files
  $x->exchangeDown;                                                             # Receive files
  $x->matchFiles;                                                               # Match files
 }

sub Data::Exchange::Details::go($)                                              #P Run until forcibly stopped.
 {my ($x) = @_;                                                                 # Exchanger
  lll "Go";
  my $s = newServiceIncarnation(q(exchange).$x->user);                          # Service representing exchanger
  makePath($x->localFolder);                                                    # Make the folder for the user
  $x->service = $s->check;                                                      # Assigns service
  for(;;)                                                                       # Exchange and sleep
   {$x->service->check;                                                         # Check we should continue
    $x->exchangeOneSet;                                                         # Exchange
    sleep $x->interval unless hostName =~ m(\A(pousadouros|secarias)\Z)s;       # Testing
    sleep 10;                                                                   # Stop runaways
   }
 }

sub Data::Exchange::Details::start                                              # Start a new exchanger as a service via atq.
 {my ($x) = @_;                                                                 # Exchanger
  my $e = dumpFile(undef, $x);                                                  # Temporary file with exchange parameters
  my $p = qq(perl $0 --file=$e);                                                # Perl command to start exchanger
  my $f = writeFile(undef, $p);                                                 # Temporary file with perl command
  if ($^O =~ m(MSWin32)is)                                                      # Run windows directly from command line
   {lll "Execute ", $p;
    say STDERR $_ for qx($p);                                                   # Execute from command line
   }
  else                                                                          # Unix - run as atq
   {my $c = qq(at now -f $f);
    say STDERR $c;
    say STDERR $_ for qx($c);                                                   # Execute from at queue
   }
 }

#D
# podDocumentation

=pod

=encoding utf-8

=head1 Name

Exchange files and update issues with your colleagues via an S3 bucket or rsync.

=head1 Synopsis

Configure and run an exchanger:

  use Data::Exchange;
  my $x        = Data::Exchange::new();
  $x->user     = q(phil);
  $x->bucket   = q(com.appaapps.exchange);
  $x->exchange = q(/home/phil/exchange);
  $x->start;

Files that end in .txt no matter where they are located below the exchange
folder:

  $x->exchange

will be merged with files of the same name from your colleagues whose files
show up in other folders under the exchange folder, allowing you to share files
and update issues with your colleagues.

Issue files that start with a plus sign B<+> in column one of line one are
assumed to be work in progress and will be ignored until the initial plus sign
is removed.

Lines which start with defined keywords in column one have special meanings if
the occur in the first section of an issues file:

 to: user

The name of the user to which this issue is addressed otherwise B<all> users will
see copies of this issue.

=head1 Description

files and update issues with your colleagues via an S3 bucket or rsync.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 File and Issue Exchanger

Exchange files and update issues with your colleagues via an S3 bucket or rsync.

=head2 new(@)

Create a new exchanger for a specified user allowing them to exchange files and issues with their colleagues via an S3 bucket or rsync - see: L<Data::Exchange Definition|/Data::Exchange Definition> for the attributes that can be set by this constructor.

     Parameter  Description
  1  @parms     Optional parameters

Example:


      my $x        = Data::Exchange::𝗻𝗲𝘄();


=head2 Data::Exchange::Details::start()

Start a new exchanger as a service via atq.


Example:


      $x->start;



=head1 Hash Definitions




=head2 Data::Exchange::Details Definition


Exchanger attributes.


B<boldFilesWithChanges> - Bold file names with changed contents

B<bucket> - The meeting point expressed as bucket/optionalPrefix for S3 transport

B<exchange> - Folder containing files locally

B<ext> - Extension of issue files

B<interval> - Interval between exchanges

B<nexus> - The meeting point expressed as a target for rsync transport

B<quiet> - Quiet S3/rsync if true

B<rsyncOptions> - Rsync options

B<s3Parms> - Additional S3 parms

B<start> - Time this exchanger was  started

B<transport> - Default file transfer

B<user> - User who owns this instance



=head1 Private Methods

=head2 Data::Exchange::Details::stamp($)

Match files that have the same file name.

     Parameter  Description
  1  $x         Exchanger

=head2 replaceWriteLine($$)

Replace the write line in a file

     Parameter  Description
  1  $file      File
  2  $line      New line

=head2 cutByTime($)

Cut a single file into time sections.

     Parameter  Description
  1  $file      File

=head2 Data::Exchange::Details::findIssueFiles($)

Find all the files that are issues

     Parameter  Description
  1  $x         Exchanger

=head2 inProgressFile($)

Check whether a file is a work in progress depending on whether it has a plus sign in column 1 of line 1 or not.

     Parameter  Description
  1  $file      File

=head2 Data::Exchange::Details::findInProgressFiles($)

Find all the files that are in progress.

     Parameter  Description
  1  $x         Exchanger

=head2 Data::Exchange::Details::assemble($@)

Assemble the time sections in multiple files into one file.

     Parameter  Description
  1  $x         Exchanger
  2  @files     Files

=head2 Data::Exchange::Details::matchFiles($)

Match files that have the same file name.

     Parameter  Description
  1  $x         Exchanger

=head2 Data::Exchange::Details::listFiles($)

List user files

     Parameter  Description
  1  $x         Exchanger

=head2 boldFileName($)

Create a bold file name

     Parameter  Description
  1  $file      File name

=head2 unBoldFileName($)

Remove bolding from file name

     Parameter  Description
  1  $file      File name

=head2 Data::Exchange::Details::unBoldFiles($)

Make all issue files non bold.

     Parameter  Description
  1  $x         Exchanger

=head2 Data::Exchange::Details::localFolder($)

The local folder containing the users own files.

     Parameter  Description
  1  $x         Exchanger

=head2 Data::Exchange::Details::stampUnstampedFiles($)

Add a time stamp to files that are no longer in progress

     Parameter  Description
  1  $x         Exchanger

=head2 Data::Exchange::Details::exchangeUp($)

Send one set of files.

     Parameter  Description
  1  $x         Exchanger

=head2 Data::Exchange::Details::exchangeDown($)

Receive one set of files.

     Parameter  Description
  1  $x         Exchanger

=head2 Data::Exchange::Details::exchangeOneSet($)

Exchange one set of files.

     Parameter  Description
  1  $x         Exchanger

=head2 Data::Exchange::Details::go($)

Run until forcibly stopped.

     Parameter  Description
  1  $x         Exchanger


=head1 Index


1 L<boldFileName|/boldFileName> - Create a bold file name

2 L<cutByTime|/cutByTime> - Cut a single file into time sections.

3 L<Data::Exchange::Details::assemble|/Data::Exchange::Details::assemble> - Assemble the time sections in multiple files into one file.

4 L<Data::Exchange::Details::exchangeDown|/Data::Exchange::Details::exchangeDown> - Receive one set of files.

5 L<Data::Exchange::Details::exchangeOneSet|/Data::Exchange::Details::exchangeOneSet> - Exchange one set of files.

6 L<Data::Exchange::Details::exchangeUp|/Data::Exchange::Details::exchangeUp> - Send one set of files.

7 L<Data::Exchange::Details::findInProgressFiles|/Data::Exchange::Details::findInProgressFiles> - Find all the files that are in progress.

8 L<Data::Exchange::Details::findIssueFiles|/Data::Exchange::Details::findIssueFiles> - Find all the files that are issues

9 L<Data::Exchange::Details::go|/Data::Exchange::Details::go> - Run until forcibly stopped.

10 L<Data::Exchange::Details::listFiles|/Data::Exchange::Details::listFiles> - List user files

11 L<Data::Exchange::Details::localFolder|/Data::Exchange::Details::localFolder> - The local folder containing the users own files.

12 L<Data::Exchange::Details::matchFiles|/Data::Exchange::Details::matchFiles> - Match files that have the same file name.

13 L<Data::Exchange::Details::stamp|/Data::Exchange::Details::stamp> - Match files that have the same file name.

14 L<Data::Exchange::Details::stampUnstampedFiles|/Data::Exchange::Details::stampUnstampedFiles> - Add a time stamp to files that are no longer in progress

15 L<Data::Exchange::Details::start|/Data::Exchange::Details::start> - Start a new exchanger as a service via atq.

16 L<Data::Exchange::Details::unBoldFiles|/Data::Exchange::Details::unBoldFiles> - Make all issue files non bold.

17 L<inProgressFile|/inProgressFile> - Check whether a file is a work in progress depending on whether it has a plus sign in column 1 of line 1 or not.

18 L<new|/new> - Create a new exchanger for a specified user allowing them to exchange files and issues with their colleagues via an S3 bucket or rsync - see: L<Data::Exchange Definition|/Data::Exchange Definition> for the attributes that can be set by this constructor.

19 L<replaceWriteLine|/replaceWriteLine> - Replace the write line in a file

20 L<unBoldFileName|/unBoldFileName> - Remove bolding from file name

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Data::Exchange

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2018 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
__DATA__
use Test::More tests=>14;

if (!debug)                                                                     # Full production
 {ok 1 for 1..14;
  exit;
 }
else                                                                            # Testing
 {if (testTransport >= 1)                                                       # Empty folder reached by rsync
   {makePath(nexus);
    clearFolder(&nexus, 12);
   }
  elsif (testTransport == 0)                                                    # Empty folder reached by rsync
   {my $b = bucket;
    for my $file([qw(bill 1)], [qw(phil 1)])                                    # Go slow: this is a very dangerous command
     {my ($u, $f) = @$file;
      my $c = qq(aws s3 rm s3://$b/$u/$f.txt --profile fmc);
      say STDERR $c;
      say STDERR $_ for qx($c);
     }
   }

  my $b = new();                                                                # Create exchanges for each user
     $b->user     = q(bill);
     $b->exchange = q(/home/phil/perl/xxx/exchangeBill/);

  clearFolder($b->exchange, 12);
  is_deeply $b->listFiles, [];

  my $p = new
   (user     => q(phil),
    exchange => q(/home/phil/perl/xxx/exchangePhil/),
   );

  clearFolder($p->exchange, 12);
  is_deeply $p->listFiles, [];

  if (debug == 1)
   {writeFile(my $pf = fpe($p->exchange, qw(phil 1 txt)), <<END);               # Work in progress file
  +W
  Hello from Phil
END
    is_deeply $p->listFiles,
     [["/home/phil/perl/xxx/exchangePhil/phil/1.txt",
       "+W\nHello from Phil\n",
     ]];

    $p->exchangeOneSet;
    is_deeply $b->listFiles, [];
    is_deeply $p->listFiles,
     [["/home/phil/perl/xxx/exchangePhil/phil/1.txt",
       "+W\nHello from Phil\n",
     ]];

    owf($pf, <<END);                                                            # Release work in progress
  Hello from Phil
END
    is_deeply $p->listFiles,
    [["/home/phil/perl/xxx/exchangePhil/phil/1.txt",
      "Hello from Phil\n",
    ]];

    $p->exchangeOneSet;
    is_deeply $p->listFiles,
    [["/home/phil/perl/xxx/exchangePhil/phil/1.txt",
      "At 0\n\nHello from Phil\n",
    ]];

    $b->exchangeOneSet;
    is_deeply $b->listFiles,
  [["/home/phil/perl/xxx/exchangeBill/bill/1.txt",
    "+Write below then remove this line when done\n\n\n",
    "At 1\n\nHello from Phil\n",
   ],
   ["/home/phil/perl/xxx/exchangeBill/phil/1.txt",
    "At 0\n\nHello from Phil\n",
  ]];

    my $bf = fpe($b->exchange, qw(bill 1 txt));                                 # Communication
    replaceWriteLine($bf, q(Hello from Bill to Phil));                          # Change first line to add message and release
    is_deeply $b->listFiles,
  [["/home/phil/perl/xxx/exchangeBill/bill/1.txt",
     "Hello from Bill to Phil\n\n\n",
     "At 1\n\nHello from Phil\n",
   ],
   ["/home/phil/perl/xxx/exchangeBill/phil/1.txt",
     "At 0\n\nHello from Phil\n",
  ]];

    $b->exchangeOneSet;
    is_deeply $b->listFiles,
  [["/home/phil/perl/xxx/exchangeBill/bill/1.txt",
    "At 0\n\nHello from Bill to Phil\n\n\n",
    "At 1\n\nHello from Phil\n",
    ],
    ["/home/phil/perl/xxx/exchangeBill/phil/1.txt",
     "At 0\n\nHello from Phil\n",
  ]];

    $p->exchangeOneSet;
    is_deeply $p->listFiles,
  [["/home/phil/perl/xxx/exchangePhil/bill/1.txt",
    "At 0\n\nHello from Bill to Phil\n\n\n",
    "At 1\n\nHello from Phil\n",
   ],
   ["/home/phil/perl/xxx/exchangePhil/phil/1.txt",
    "+Write below then remove this line when done\n\n\n",
    "At 1\n\nHello from Bill to Phil\n\n\n",
    "At 2\n\nHello from Phil\n",
  ]];

    replaceWriteLine($pf, q(Hello to Bill from Phil again));                    # Change first line to add message and release
    $_->exchangeOneSet for $p,$b,$p,$b,$p,$b;
    is_deeply $p->listFiles,
  [["/home/phil/perl/xxx/exchangePhil/bill/1.txt",
    "+Write below then remove this line when done\n\n\n",
    "At 1\n\nHello to Bill from Phil again\n\n\n",
    "At 2\n\nHello from Bill to Phil\n\n\n",
    "At 3\n\nHello from Phil\n",
   ],
   ["/home/phil/perl/xxx/exchangePhil/phil/1.txt",
    "At 0\n\nHello to Bill from Phil again\n\n\n",
    "At 1\n\nHello from Bill to Phil\n\n\n",
    "At 2\n\nHello from Phil\n",
  ]];
    is_deeply $b->listFiles,
  [["/home/phil/perl/xxx/exchangeBill/bill/1.txt",
    "+Write below then remove this line when done\n\n\n",
    "At 1\n\nHello to Bill from Phil again\n\n\n",
    "At 2\n\nHello from Bill to Phil\n\n\n",
    "At 3\n\nHello from Phil\n",
   ],
   ["/home/phil/perl/xxx/exchangeBill/phil/1.txt",
    "At 0\n\nHello to Bill from Phil again\n\n\n",
    "At 1\n\nHello from Bill to Phil\n\n\n",
    "At 2\n\nHello from Phil\n",
  ]];
    replaceWriteLine($bf, q(Hello from Bill to Phil again));                    # Change first line to add message and release
    $_->exchangeOneSet for $b,$p,$b,$p,$b,$p;

    is_deeply $p->listFiles,
  [["/home/phil/perl/xxx/exchangePhil/bill/1.txt",
    "At 0\n\nHello from Bill to Phil again\n\n\n",
    "At 1\n\nHello to Bill from Phil again\n\n\n",
    "At 2\n\nHello from Bill to Phil\n\n\n",
    "At 3\n\nHello from Phil\n",
   ],
   ["/home/phil/perl/xxx/exchangePhil/phil/1.txt",                              # Phil
    "+Write below then remove this line when done\n\n\n",
    "At 1\n\nHello from Bill to Phil again\n\n\n",
    "At 2\n\nHello to Bill from Phil again\n\n\n",
    "At 3\n\nHello from Bill to Phil\n\n\n",
    "At 4\n\nHello from Phil\n",
  ]];
    is_deeply $b->listFiles,
  [["/home/phil/perl/xxx/exchangeBill/bill/1.txt",                              # Bill
    "At 0\n\nHello from Bill to Phil again\n\n\n",
    "At 1\n\nHello to Bill from Phil again\n\n\n",
    "At 2\n\nHello from Bill to Phil\n\n\n",
    "At 3\n\nHello from Phil\n",
   ],
   ["/home/phil/perl/xxx/exchangeBill/phil/1.txt",
    "+Write below then remove this line when done\n\n\n",
    "At 1\n\nHello from Bill to Phil again\n\n\n",
    "At 2\n\nHello to Bill from Phil again\n\n\n",
    "At 3\n\nHello from Bill to Phil\n\n\n",
    "At 4\n\nHello from Phil\n",
  ]];
   }
  elsif (debug == 2)
   {ok 1 for 1..12;
    my $x        = Data::Exchange::new();                                       #Tnew
    $x->user     = hostName =~ m(\Apousadouros\Z)s ? q(phil) : q(bill);
    $x->exchange = q(/home/phil/perl/xxx/exchange/);
    $x->start;                                                                  #TData::Exchange::Details::start
   }
say STDERR "PPPP ", dump($p->listFiles);
#say STDERR "BBBB ", dump($b->listFiles);
 }
