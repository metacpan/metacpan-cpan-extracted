#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib
#-------------------------------------------------------------------------------
# Exchange files and update issues from your colleagues via an S3 bucket.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2018
#-------------------------------------------------------------------------------
# podDocumentation

package Data::Exchange;
our $VERSION = q(20180916);
require v5.16;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use POSIX qw(strftime);                                                         # http://www.cplusplus.com/reference/ctime/strftime/
use utf8;

our $user  = q(phil);                                                           # Default user
our $quiet = q(--quiet);                                                        # Quiet S3

if (@ARGV)                                                                      # Processs any command line arguments
 {parseCommandLineArguments
   {my ($pos, $key) = @_;
    if (my $f = $$key{file})
     {my $p = evalFile($f);
      my $x = new(%$p);
      $x->go();
      exit;
     }
    elsif (my $u = $$key{user})
     {$user = $u;
     }
   } \@ARGV, [qw(file user)];
 }

#D1                                                                             # Exchange files.
sub new(@)                                                                      # New exchanger - see: L<Data::Exchange Definition|/Data::Exchange Definition> for the attributes that can be set by this constructor.
 {my @parms = @_;                                                               # Optional parameters
  genHash(__PACKAGE__,                                                          # Exchanger attributes.
    bucket   => q(ryffine.exchange),                                            # Bucket used for exchanges
    exchange => &exchangeFolder,                                                # Folder containing files
    ext      => q(txt),                                                         # Extension of issue files
    interval => q(10),                                                          # Interval between exchanges
    s3Parms  => q(--profile fmc),                                               # Additional S3 parms
    user     => $user,                                                          # User who owns this instance
    @_,
   );
 }

sub exchangeFolder                                                              #P Folder containing files.
 {fpf(q(/home/phil/perl/exchange));
 }

sub sep                                                                         #P Time section separator
 {q(At \d\d\d\d\.\d\d\.\d\d \d\d:\d\d:\d\d \d{7});
 }

my $stampCount = 0;                                                             # Separate otherwise identical stamps

sub stampLength                                                                 #P Length of stamp
 {30}

sub stamp                                                                       #P Gmt time stamp.
 {my $c = sprintf("%07d", ++$stampCount);
  strftime(qq(At %Y.%m.%d %H:%M:%S $c\n), gmtime)
 }

my $tests = 0;                                                                  # Distinguish between starts at the same time which occur in testing but not else where

sub newService($)                                                               # Create a new service.
 {my ($service) = @_;                                                           # Service name
  my $file = fpe($ENV{HOME},                                                    # File to log service in
    qw(.config com.appaapps services), $service, q(txt));
  my $t = genHash(q(Data::Exchange::Service),                                   # Service details.
    service=> $service,                                                         # Service name
    tests  => ++$tests,                                                         # Test number
    start  => time,                                                             # Service start time
    file   => $file,                                                            # Service details file
   );
  dumpFile($file, $t);                                                          # Write details
  $t                                                                            # Return service details
 }

sub Data::Exchange::Service::check($)                                           # Check that we are the current instance of the named service with details obtained from L<setService|/setService>.
 {my ($s) = @_;                                                                 # Service details
  my $t = evalFile($s->file);
##return 1; ###TEST###
  return 1 if $t->start == $s->start and $t->tests == $s->tests;
  confess "Replaced by a newer version\n";
 }

sub cutByTime($)                                                                #P Cut a single file into time sections.
 {my ($file) = @_;                                                              # File

  my $t = readFile($file);                                                      # Read file
     $t =~ s(\A\s*) ()gs;                                                       # Remove leading white space
  my $s = sep;
  my @a = split /(?=^$s$)/m, $t;                                                # Split into time sections
  if (@a and $a[0] =~ m(\S)s and $a[0] !~ m(\A$s)s)                             # Add separator for unseparated text
   {$a[0] = stamp.$a[0];
   }
  @a
 }

sub assemble(@)                                                                 #P Assemble the time sections in multiple files into one file.
 {my (@files) = @_;                                                             # Files

  my %times;
  for my $file(@files)                                                          # Time sections
   {for my $section(cutByTime($file))
     {$times{substr($section, 0, stampLength)} = $section;                      # Hash of sections by time
     }
   }

  my @t = ("\n\n",                                                              # Sections in reverse time order
    map {$times{$_}}
    reverse sort keys %times);

  my $t = join '', @t;                                                          # Text of new file
  $t
 }

sub matchFiles($)                                                               #P Match files that have the same file name.
 {my ($x) = @_;                                                                 # Exchanger
  my %files;

  my @files = searchDirectoryTreesForMatchingFiles                              # Find files to match
   ($x->exchange,
    $x->ext);

  for my $file(@files)                                                          # Match files
   {my $f = fne $file;
    push @{$files{$f}}, $file;
   }

  for my $file(sort keys %files)                                                # Assemble issue files
   {my $f = fpf($x->exchange, $x->user, $file);                                 # User's copy of issue
    my $a = assemble(@{$files{$file}});
    if (-e $f and readFile($f) ne $a)                                           # Issue has been changed
     {my $F = fpf($x->exchange, $x->user, boldString($file));                   # Bold file name
      owf($F, $a);
      unlink $f;                                                                # Write user's copy of changed issue
     }
   }
 }

sub unBoldFiles($)                                                              #P Make all issue files non bold.
 {my ($x) = @_;                                                                 # Exchanger
  my @files = searchDirectoryTreesForMatchingFiles                              # Issue files
   ($x->exchange,
    $x->ext);
  for my $File(@files)                                                          # Each file
   {my $file = boldStringUndo($File);
    qx(cp $File $file; rm $File) if $file ne $File;                             # Unbold file name
   }
 }

sub localFolder($)                                                              #P The local folder containing the users own files.
 {my ($x) = @_;                                                                 # Exchanger
  fpd($x->exchange, $x->user);
 }

sub exchangeUp($)                                                               #P Send one set of files.
 {my ($x) = @_;                                                                 # Exchanger
  my $s = $x->localFolder;                                                      # User's own files
  my $t = fpf($x->bucket, $x->user);                                            # User's own files on S3
  my $p = $x->s3Parms;                                                          # Additional parameters for s3
  my $c = qq(aws s3 sync $s s3://$t $quiet --delete $p);                        # Command
  say STDERR $c;
  say STDERR $_ for qx($c);                                                     # Execute
 }

sub exchangeDown($)                                                             #P Receive one set of files.
 {my ($x) = @_;                                                                 # Exchanger
  my $u = $x->user;
  my $t = $x->exchange;                                                         # All possible exchange files
  my $s = $x->bucket;                                                           # User's own files on S3
  my $p = $x->s3Parms;                                                          # Additional parameters for s3
  my $c = qq(aws s3 sync s3://$s $t $quiet --exclude "*/$u/*" $p);               # Command
  say STDERR $c;
  say STDERR $_ for qx($c);                                                     # Execute
 }

sub exchangeOneSet($)                                                           #P Exchange one set of files.
 {my ($x) = @_;                                                                 # Exchanger
  $x->unBoldFiles;                                                              # Unbold file names
  $x->exchangeUp;                                                               # Send files
  $x->exchangeDown;                                                             # Receive files
  $x->matchFiles;                                                               # Match files
 }

sub go($)                                                                       #P Run until forcibly stopped.
 {my ($x) = @_;                                                                 # Exchanger
  my $s = newService(q(exchange));                                              # Service representing exchanger
  makePath($x->localFolder);                                                    # Make the folder for the user
  for(;;)                                                                       # Exchange and sleep
   {$s->check;
    $x->exchangeOneSet;
    sleep $x->interval;
    sleep 10;                                                                   # Stop runaways
   }
 }

sub start                                                                       # Start a new exchanger as a service.
 {my ($x) = @_;                                                                 # Exchanger
  my $e = dumpFile(undef, $x);
  my $p = qq(perl $0 --file=$e);
  my $f = writeFile(undef, $p);
  if (1)
   {say STDERR $p;
    say STDERR $_ for qx($p);                                                   # Execute from command line
   }
  else
   {my $c = qq(at now --file=$f);
    say STDERR $c;
    say STDERR $_ for qx($c);                                                   # Execute from at queue
   }
 }

#D
# podDocumentation

=pod

=encoding utf-8

=head1 Name

Data::Exchange - Exchange files and update issues from your colleagues via an
S3 bucket.

=head1 Synopsis

Configure and run an exchanger:

  use Data::Exchanger;
  my $x        = Data::Exchanger::new();
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

=head1 Description

Exchange files and update issues via an S3 bucket.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1

Exchange files.

=head2 new(@)

New exchanger - see: L<Data::Exchange Definition|/Data::Exchange Definition> for the attributes that can be set by this constructor.

     Parameter         Description
  1  {my @parms = @_;  Optional parameters

Example:


    my $x = Data::Exchanger::new();


=head2 newService($)

Create a new service.

     Parameter  Description
  1  $service   Service name

Example:


  if (1)
   {my $s = newService("aaa");
    eval {$s->check};
    ok $@ =~ m(|Replaced by a newer version);
    my $t = newService("aaa");
    eval {$s->check};
    ok $@ =~ m(Replaced by a newer version);
   }


=head2 Data::Exchange::Service::check($)

Check that we are the current instance of the named service with details obtained from L<setService|/setService>.

     Parameter  Description
  1  $s         Service details

Example:


  if (1)
   {my $s = newService("aaa");
    eval {$s->check};
    ok $@ =~ m(|Replaced by a newer version);
    my $t = newService("aaa");
    eval {$s->check};
    ok $@ =~ m(Replaced by a newer version);
   }


=head2 start()

Start a new exchanger as a service.


Example:


    $x->start;



=head1 Hash Definitions




=head2 Data::Exchange Definition


Exchanger attributes.


B<bucket> - Bucket used for exchanges

B<exchange> - Folder containing files

B<ext> - Extension of issue files

B<interval> - Interval between exchanges

B<s3Parms> - Additional S3 parms

B<user> - User who owns this instance



=head2 Data::Exchange::Service Definition


Service details.


B<file> - Service details file

B<service> - Service name

B<start> - Service start time

B<tests> - Test number



=head1 Private Methods

=head2 exchangeFolder()

Folder containing files.


=head2 sep()

Time section separator


=head2 stampLength()

Length of stamp


=head2 stamp()

Gmt time stamp.


=head2 cutByTime($)

Cut a single file into time sections.

     Parameter  Description
  1  $file      File

=head2 assemble(@)

Assemble the time sections in multiple files into one file.

     Parameter  Description
  1  @files     Files

=head2 matchFiles($)

Match files that have the same file name.

     Parameter  Description
  1  $x         Exchanger

=head2 unBoldFiles($)

Make all issue files non bold.

     Parameter  Description
  1  $x         Exchanger

=head2 localFolder($)

The local folder containing the users own files.

     Parameter  Description
  1  $x         Exchanger

=head2 exchangeUp($)

Send one set of files.

     Parameter  Description
  1  $x         Exchanger

=head2 exchangeDown($)

Receive one set of files.

     Parameter  Description
  1  $x         Exchanger

=head2 exchangeOneSet($)

Exchange one set of files.

     Parameter  Description
  1  $x         Exchanger

=head2 go($)

Run until forcibly stopped.

     Parameter  Description
  1  $x         Exchanger


=head1 Index


1 L<assemble|/assemble> - Assemble the time sections in multiple files into one file.

2 L<cutByTime|/cutByTime> - Cut a single file into time sections.

3 L<Data::Exchange::Service::check|/Data::Exchange::Service::check> - Check that we are the current instance of the named service with details obtained from L<setService|/setService>.

4 L<exchangeDown|/exchangeDown> - Receive one set of files.

5 L<exchangeFolder|/exchangeFolder> - Folder containing files.

6 L<exchangeOneSet|/exchangeOneSet> - Exchange one set of files.

7 L<exchangeUp|/exchangeUp> - Send one set of files.

8 L<go|/go> - Run until forcibly stopped.

9 L<localFolder|/localFolder> - The local folder containing the users own files.

10 L<matchFiles|/matchFiles> - Match files that have the same file name.

11 L<new|/new> - New exchanger - see: L<Data::Exchange Definition|/Data::Exchange Definition> for the attributes that can be set by this constructor.

12 L<newService|/newService> - Create a new service.

13 L<sep|/sep> - Time section separator

14 L<stamp|/stamp> - Gmt time stamp.

15 L<stampLength|/stampLength> - Length of stamp

16 L<start|/start> - Start a new exchanger as a service.

17 L<unBoldFiles|/unBoldFiles> - Make all issue files non bold.

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
use Test::More tests=>2;

if (1)                                                                          #TnewService #TData::Exchange::Service::check
 {my $s = newService("aaa");
  eval {$s->check};
  ok $@ =~ m(|Replaced by a newer version);
  my $t = newService("aaa");
  eval {$s->check};
  ok $@ =~ m(Replaced by a newer version);
 }

clearFolder(exchangeFolder, 1e2);                                               # Clear test area

if (0)
 {my @f = (                                                                     # Test files
owf(fpe(exchangeFolder, qw(mim 1 txt)), <<END),

Hello
At 2018.09.15 22:23:04 0000001
AAAA
At 2018.09.15 22:23:02 0000002
CCCC
END

owf(my $f = fpe(exchangeFolder, qw(phil 1 txt)), <<END),


At 2018.09.15 22:23:03 0000003
bbbb
At 2018.09.15 22:23:01 0000004
dddd
END

owf(fpe(exchangeFolder, qw(bill 1 txt)), <<END),

aaaa
END
  );

  my $x = new();
  $x->matchFiles;
  my $s = join "\n", grep {!/\AAt/s} split /\n/, readFile($f);
  ok $s eq <<END =~ s(\s\Z) ()gsr;


Hello
aaaa
AAAA
bbbb
CCCC
dddd
END
 }

if (0) {                                                                        # Run exchanger
  my $x = Data::Exchanger::new();                                               #Tnew

  if (my $user = $Data::Exchanger::user =~ m(bill)is)
   {my $u = $x->user = $user;
    my $d = $x->exchange = q(/home/phil/perl/exchange/exchangeBill/);
    clearFolder($d, 12);                                                        # Clear test area
    writeFile(fpe($d, qw(bill 1 txt)), <<END);
Hello from Bill
END
   }
  else
   {my $d = $x->exchange;
    clearFolder($d, 12);                                                        # Clear test area
    writeFile(fpe($d, qw(phil 1 txt)), <<END);
Hello from Phil
END
   }

  $x->start;                                                                    #Tstart
 }
