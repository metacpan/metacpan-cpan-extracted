#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I/home/phil/perl/cpan/GitHubCrud/lib/ -I/home/phil/perl/cpan/DataEditXmlXref/lib/ -I/home/phil/perl/cpan/DitaGBStandard/lib/ -I/home/phil/perl/cpan/FlipFlop/lib/
#-------------------------------------------------------------------------------
# Data::Edit::Xml::To::Dita - Convert multiple Xml documents in parallel to Dita
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2019
#-------------------------------------------------------------------------------
# podDocumentation

package Data::Edit::Xml::To::DitaVb;
our $VERSION = 20190708;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Edit::Xml;
use Data::Edit::Xml::Lint;
use Data::Edit::Xml::Xref;
use Data::Table::Text qw(:all);
use Dita::GB::Standard qw(:all);
use Flip::Flop;
use GitHub::Crud;
use Scalar::Util qw(blessed);
use Time::HiRes qw(time);
use utf8;

#D1 Convert Xml to the Dita standard.                                           # Convert Xml to the Dita standard.

sub changeBadXrefToPh{0}                                                        #I Change xrefs being placed in M3 by L<Data::Edit::Xml::Xref> to B<ph>.
sub clearCount       {&develop ? 1e4 : 1e6}                                     # Limit on number of files to clear from each output folder.
sub client           {q()}                                                      # The name of the client
sub conversion       {&conversionName}                                          # Conversion name
sub convert          {1}                                                        # Convert documents to dita if true.
sub debug            {0}                                                        # Debug if true.
sub deguidize        {0}                                                        # 0 - normal processing, 1 - replace guids in hrefs with their target files to deguidize dita references. Given href g1#g2/id convert g1 to a file name by locating the topic with topicId g2.
sub ditaXrefs        {0}                                                        # Convert xref hrefs expressed as just ids to dita format - useful in non Dita to Dita conversions for example: docBook
sub docSet           {1}                                                        # Select set of documents to convert.
sub download         {&develop ? 0 : 1}                                         # Download from S3 if true.
sub exchange         {&develop ? 2 : 2}                                         # 1 - upload to S3 Exchange if at 100% lint, 2 - upload to S3 Exchange regardless, 0 - no upload to S3 Exchange.
sub exchangeItems    {q()}                                                      # The items to be uploaded to the exchange folder: d - downloads, i - in, p - perl, o - out, t - topic trees. Reports are uploaded by default
sub extendedNames    {0}                                                        # Expected number of output topics or B<undef> if unknown
sub fixBadRefs       {0}                                                        # Mask bad references using M3: the Monroe Masking Method if true
sub fixDitaRefs      {0}                                                        # Fix references in a corpus of L<Dita> documents that have been converted to the L<GBStandard>.
sub fixFailingFiles  {0}                                                        # Fix failing files in the L<testFails|/testFails> folder if this attribute is true
sub fixRelocatedRefs {1}                                                        # Fix references to (re|un)located files that adhere to the GB standard.
sub fixXrefsByTitle  {0}                                                        # Fix failing xrefs by looking for the unique topic with a title that matches the text of the xref.
sub hits             {Flip::Flop::hits(0)}                                      # 1 - track hits so we can see which transformations are actually being used - normally off to avoid the overhead
sub lint             {1}                                                        # Lint output xml
sub mimajen          {0}                                                        # 1- Copy files to web, 0 - suppress
sub notify           {!&develop and &upload ? &upload : 0}                      # 1 - Broadcast results of conversion if at 100% lint, 2 - broadcast regardless of error count.
sub numberOfFiles    {undef}                                                    # Expected number of output files
sub printTopicTrees  {1}                                                        # 1 - print the parse tree before cutting out the topics
sub publish          {0}                                                        # 1 - convert Dita to Html and publish via DITA-OT if at 100% lint,  2 - publish regardless
sub restructure      {0}                                                        # 1 - Restructure results of conversion if at 100% lint, 2 - restructure regardless of error count.
sub restructurePhases{1}                                                        # Number of restructuring phases to run
sub testMode         {&develop ? 1 : 0}                                         # 1 - run development tests, 2- run standalone tests, 0 run production documents
sub titleOnly        {0}                                                        # Use only the title of topics to create GB Standard file names otherwise use the following text as well if the title is too short
sub unicode          {download}                                                 # Convert to utf8 if true.
sub upload           {&develop ? 0 : 1}                                         # Upload to S3 Bucket if true and the conversion is at 100%, 2 - upload to S3 Bucket regardless, 0 - no upload to S3 Bucket.
sub version          {q()}                                                      # Description of this run as printed in notification message and title
sub xref             {1}                                                        # Xref output xml.
sub xrefAddNavTitles {1}                                                        # Add navtitles to bookmap entries if true
sub xrefAllowUniquePartialMatches{1}                                            # Allow partial matching - i.e ignore the stuff to the right of the # in a reference if doing so produces a unique result
sub xrefMatchTopics  {0}                                                        # Either 0 for no topic matching or the percentage confidence level for topic matching
#ub relinkDitaRefs   {0}                                                        # Relink dita references that are valid in the input corpus so that they are valid in the output corpus as well.
#ub singleTopicBM    {fixDitaRefs}                                              # 1 - allow single topic book maps when cutting out topics which is required if using L<fixDitaRefs>, 0 - multiple topics required for a bookmap

sub catalog          {q(/home/phil/r/dita/dita-ot-3.1/catalog-dita.xml)}        # Dita catalog to be used for linting.
sub develop          {-e q(/home/ubuntu/) ? 0 : 1}                              # Production run if this file folder is detected otherwise development.
sub ditaBin          {fpf(qw(/home phil r dita dita-ot-3.1 bin dita))}          # Location of Dita tool
sub downloads        {fpd(&home,    qw(download))}                              # Downloads folder.
sub errorLogFile     {fpe(&perl,    qw(eee txt))}                               # Error log file.
sub exchangeHome     {fpd(qw(/home phil x aws))}                                # Home of exchange folder
sub fails            {fpd(&reports, qw(fails))}                                 # Copies of failing documents in a separate folder to speed up downloading.
sub gathered         {fpd(&home,    qw(gathered))}                              # Folder containing saved parse trees after initial parse and information gathering - pretty well obsolete
sub hitsFolder       {fpd(&home,    qw(hits))}                                  # Folder containing at method hits by process id
sub home             {&getHome}                                                 # Home folder containing all the other folders.
sub imageCache       {fpd(home,     qw(imageCache))}                            # Converted images are cached here to speed things up
sub in               {fpd(&home,    qw(in))}                                    # Input documents folder.
sub inputExt         {qw(.xml .dita .ditamap)}                                  # Extension of input files.
sub out              {fpd(&home,    qw(out))}                                   # Converted documents output folder.
sub outExtTopic      {q(dita)}                                                  # Preferred output extension for a topic
sub outExtMap        {q(ditamap)}                                               # Preferred output extension for a map
sub parseCache       {fpd(&home,    qw(parseCache))}                            # Cached parse trees.
sub parseFailed      {fpd(&home,    qw(parseFailed))}                           # Folder for details of xml parse failures
sub perl             {fpd(&home,    qw(perl))}                                  # Perl folder.
sub process          {fpd(&home,    qw(process))}                               # Process data folder used to communicate results between processes.
sub publications     {fpd(&www,     qw(publications), client)}                  # Publications folder on web server for client
sub reports          {fpd(&home,    qw(reports))}                               # Reports folder.
sub s3Bucket         {q(s3Bucket)}                                              # Bucket on S3 holding documents to convert and the converted results.
sub s3FolderIn       {q(originals).docSet}                                      # Folder on S3 containing original documents.
sub s3FolderUp       {q(results).docSet}                                        # Folder on S3 containing results of conversion.
sub s3Exchange       {fpd(qw(exchange.ryffine users aws), client)}              # Exchange folder on S3
sub s3Profile        {undef}                                                    # Aws cli profile keyword value if any.
sub s3Parms          {q(--quiet --delete)}                                      # Additional S3 parameters for uploads and downloads.
sub summaryFile      {fpe(reports,  qw(summary txt))}                           # Summary report file.
sub targets          {fpd(&home,    qw(targets))}                               # Duplicates the in file structure - each file there-in shows us where the original file went
sub tests            {fpd(&home,    qw(tests/in))}                              # Folder containing test input files received from test developer at L<testExchangeIn|/testExchangeIn>
sub testExpected     {fpd(&home,    qw(tests/expected))}                        # Folder containing test results expected.
sub testExchangeIn   {undef}                                                    # Exchange folder in which to receive tests so that test writers can disarrange their exchange folders as they please without disrupting testing at this end.
sub testExchangeOut  {undef}                                                    # Exchange folder to publish tests results in so test writers can see the results in at L<testResults|/testResults>
sub testResults      {fpd(&home,    qw(tests/results))}                         # Folder containing actual test results locally, copied to: L<testExchangeOut|/testExchangeOut>
sub testStandAlone   {fpd(&home,    qw(tests/standalone/active))}               # Folder containing standalone tests which is used instead of regression tests if content is present
sub testFails        {fpd(&home,    qw(fails))}                                 # Folder containing failing files to be fixed by reprocessing them but only if fixFailingFiles is true
sub testFails2       {fpd(&home,    qw(fails2))}                                # Folder containing files still unfixed by the current set of fixes
sub topicTrees       {fpd(&home,    qw(topicTrees))}                            # Folder to contain printed topic trees if requested by printTopicTrees
sub user             {q(phil)}                                                  # Aws userid
sub www              {fpd(qw(/var www html))}                                   # Web server folder

my $startTime = time;                                                           # Start time.
my $endTime;                                                                    # End time value.
my $runTime;                                                                    # Run time value.

sub startTime        {$startTime}                                               # Start time of run in seconds since the epoch.
sub endTime          {$endTime}                                                 # End time of run in seconds since the epoch.
sub runTime          {$runTime}                                                 # Elapsed run time in seconds.

sub maximumNumberOfProcesses    {develop ?   2 : 256}                           # Maximum number of conversion processes to run in parallel.
#ub maximumFileFromStringLength {50}                                            # Maximum amount of title to use in constructing output file names.

our $standAlone;                                                                # When true we are operating in stand alone mode to test documents from testStandalone in isolation
our $projects    = {};                                                          # Projects == documents to convert.
our $project;                                                                   # Visible, thus loggable.
our $lintResults = q(No lint results yet!);                                     # Lint results.
our $lintReport;                                                                # Lint report if available.

my $home;                                                                       # Cached value of home

sub getHome                                                                     #P Compute home directory once.
 {return $home if $home;
  my $c = currentDirectory;
  return $home = $c if $c =~ m(\A/home/phil/perl/cpan/)s;
  $home = fpd(Data::Table::Text::sumAbsAndRel($c, "../"));
 }

sub s3ProfileValue                                                              #P S3 profile keyword.
 {return '' unless my $p = s3Profile;
  qq( --profile $p)
 }

sub conversionName                                                              #P Conversion name.
 {return q(Free ).&client.q( from SDL) if deguidize;                            # Must be escape from SDL if we are deguidizing
  q(Convert ).&client.q( to Dita)
 }

my %atHits;                                                                     # Track hits via the at method which is more stable than line number
my $startProcess = -1;                                                          # The process leader

sub setAtHits                                                                   # Set hit tracking
 {if (hits)                                                                     # Only when hit tracking is enabled
   {*dexAt = *Data::Edit::Xml::at;                                              # Existing at method
    $startProcess = $$;
    sub at                                                                      # Replacement at method
     {if (my $r = &dexAt(@_))                                                   # Normal at succeeded
       {$atHits{join '_', @_[1..$#_]}++;                                        # Record at context
        return $r;                                                              # Return result
       }
      undef                                                                     # At failed
     }

    *Data::Edit::Xml::at = *at;                                                 # Reassign at method so that the hits can be tracked
    Flip::Flop::hits();                                                         # Reset hits to avoid overhead
   }
 }

sub analyzeHits()                                                               # Analyze the hits to find "at" calls that always fail so we can consider them for removal
 {my %hits;                                                                     # Hits encountered
  for my $file(searchDirectoryTreesForMatchingFiles(hitsFolder))                # Hits in each process
   {my $hits = evalFile($file);                                                 # Load hits for a process
    $hits{$_} += $$hits{$_} for keys %$hits;                                    # Accumulate hits from each process
   }
  my @s = readFile($0);                                                         # Read source file looking for "at" calls
  my @miss; my @hits;                                                           # At that never hit. At that hit.
  for my $i(keys @s)                                                            # Each line by number
   {my $line = $s[$i];                                                          # Line content
    if ($line =~ m(\w+((_\w+)+))s)                                              # Look for at call
     {my $at = substr($1, 1);                                                   # Remove leading underscore
      if (my $n = $hits{$at})                                                   # Number of hits
       {push @hits, [$i+1, $n, $line];                                          # Record hit
       }
      else
       {push @miss, [$i+1, $line];                                              # Record miss
       }
     }
   }
  formatTable([@miss], <<END,                                                   # Report misses
Line The line containing the "at" call that failed to hit
At   The text of the "at" call
END
     title=>q(Calls to "at" that missed.),
     head=>qq(Found NNNN lines in $0 containing "at" that missed on DDDD),
     file=>fpe(reports, qw(misses txt)),
   );

  formatTable([@hits], <<END,                                                   # Report hits
Line  The line containing the "at" call that succeeded
Count The number of times this "at" succeeded
At    The text of the "at" call
END
     title=>q(Calls to "at" that succeeded.),
     head=>qq(Found NNNN lines in $0 containing "at" that succeeded on DDDD),
     file=>fpe(reports, qw(hits txt)),
   );
 }

END                                                                             # Dump hits by process at the end
 {dumpFile(fpe(hitsFolder, $$, q(data)), \%atHits) if hits and keys %atHits;
  if ($startProcess == $$)                                                      # Analyze the hits if we are the main process
   {analyzeHits;                                                                # Analyze hits
    clearFolder(hitsFolder, clearCount);                       # Rather than letting the files accumulate
   }
 }

#D1 Methods                                                                     # Methods defined in this package.

sub ddd(@)                                                                      # Log development messages
 {my (@m) = @_;                                                                 # Messages
  goto &lll if debug;
 }

sub eee(@)                                                                      # Log error messages
 {my (@m) = @_;                                                                 # Messages
  my $m = join ' ', dateTimeStamp, "Error: ", @_;                               # Time stamp each message
  if ($project)
   {$m .= " in project $project";
   }
  my ($p, $f, $l) = caller();
  $m .= " at $f line $l\n";

  appendFile(errorLogFile, ($m =~ s(\s+) ( )gsr).qq(\n));
  say STDERR $m;
 }

sub s3InputFolder                                                               #P S3 input folder
 {q(s3://).fpd(s3Bucket, s3FolderIn);
 }

sub s3OutputFolder                                                              #P S3 output folder
 {q(s3://).fpd(s3Bucket, s3FolderUp);
 }

sub s3ExchangeFolder                                                            #P S3 exchange folder
 {q(s3://).fpd(s3Exchange);
 }

sub copyToAws                                                                   # Copy to aws
 {my $aws = awsIp;                                                              # Get ip address of aws
  lll "Upload ".conversion." to AWS at $aws";                                   # Title

  my $perl = fpd(perl);
  my $user = user;
  owf(fpe(perl, qw(batchOnAws pl)), <<END2);                                    # Create at command file
at now <<END
perl ${perl}convert.pl 2>${perl}zzz.txt
END
END2

  my @foldersToUpload =                                                         # Sync folders
   (perl,
    fp(catalog),
    q(/home/phil/perl/cpan));

  for my $f(@foldersToUpload)
   {my $c = qq(rsync -mpqrt --del $f/ phil\@$aws:$f);
    lll qq($c);
    lll qx($c);
   }

  if (1)                                                                        # Run command on aws
   {my $c = qq(ssh $user\@$aws "bash $perl/batchOnAws.sh");
    lll qq($c);
    lll qx($c);
   }

  Flip::Flop::action();
  lll "Done!";
 }

sub getFromAws                                                                  # Get results from Aws
 {my $home  = home;                                                             # Home folder
  my $aws   = awsIp;                                                            # Get ip address of aws
  lll "Download ".conversion." to AWS at $aws";                                 # Title

  my $user  = user;
  for my $dir(out, reports)
   {my $c   = qq(rsync -mpqrt --del $user\@$aws:$dir $dir);
    lll qq($c);
    lll qx($c);
   }

  Flip::Flop::action();
  lll "Done!";
 }

sub pleaseSee($$)                                                               #P AWS command to see results
 {my ($lint, $xref) = @_;                                                       # Lint results, xref results
  my $success = $lintReport && $lintReport->totalErrors == 0;
  my $p = qq(Please see:);
  my @p;
  push @p, fpe(q(http://).awsIp, q(publications), client, qw(index html))
    if &mimajen;
  push @p, qq(aws s3 sync ).s3OutputFolder
    if &upload && &s3OutputFolder &&  $success || &upload == 2;
  push @p, s3Exchange
    if &exchange && &s3Exchange && !$success || &exchange == 2;

  return join ' ', $p, join " or ", @p if @p;
  q()
 }

sub mifToXml($)                                                                 # Convert Mif to Xml
 {my ($inputFile) = @_;                                                         # File containing mif
  lll "Convert mif file: $inputFile";

  my @xml;                                                                      # Generated Xml
  my @stack;                                                                    # Bracket stack

  my $string = readFile($inputFile);                                            # Read mif source
  my @lines = split /\n/, $string;                                              # Lines of input

  for my $i(keys @lines)                                                        # Fix strings spread across several lines
   {my $line = $lines[$i];
    if ($line =~ m(\A\s*<\w+\s*`)s and $line !~ m('>\s*\Z))                     # Non terminated string line
     {for my $j($i+1..$#lines)                                                  # Following lines
       {my $l = $lines[$j];
        if ($l !~ m('\s*\Z))                                                    # Not terminated
         {$lines[$i] .= $l;
          $lines[$j] = qq(# Moved to line $i);
         }
        else                                                                    # Terminated, pull in closing > from next line
         {$lines[$i]  .= $l.q(>);
          $lines[$j]   = qq(# Moved to line $i);
          $lines[$j+1] = qq(# Moved to line $i);
          last;
         }
       }
     }
   }

  my @image;
  my $image = undef;                                                            # In an image when set
  for my $i(keys @lines)
   {my $line = $lines[$i];
    if ($line =~ m(\A<Book ))                                                   # Ignore Book tag
     {next;
     }
    if (!$image)                                                                # Not in an image
     {if ($line =~ m(\A=(DIB|EMF|FrameVector|OLE2|TIFF|WMF))s)                  # Image types
       {$image = $1;
        next;
       }
      if ($line =~ m(\A<MIFFile)s)                                              # Skip file format
       {next;
       }
      if ($line =~ m(\A\s*<(\w+)\s*(.*?)>\s*\Z))                                # Entity all on one line
       {my ($tag, $Value) = ($1, $2);
        if ($Value =~ m(\A`(.*)'\Z)s)
         {$Value = $1;
         }
        my $value = Data::Edit::Xml::replaceSpecialChars($Value);
        $line = qq(<$tag value="$value"/>);
       }
      elsif ($line =~ m(\A\s*<(\w+)\s*\Z))                                      # Opening entity
       {push @stack, $1;
        $line = qq(<$1>);
       }
      elsif ($line =~ m(\A(\s*)>\s*#\s*end\s*of\s*(\w+)\s*\Z))                  # Closing entity
       {if (@stack)
         {my $w = pop @stack;
          if ($2 eq $w)
           {$line = $1.q(</).$w.q(>);
           }
          else
           {confess "Stack mismatch, expected $w, got $2 at line $i:\n$line\n".dump(\@stack);
           }
         }
        else
         {confess "Stack empty, but got $2 at line $i";
         }
       }
      elsif ($line =~ m(\A(\s*)>\s*\Z))                                         # Closing entity not specified
       {if (@stack)
         {my $w = pop @stack;
          $line = $1.q(</).$w.q(>);
         }
        else
         {confess "Stack empty, but got $2 at line $i";
         }
       }
      if ($line =~ m(\A#))                                                      # Remove comment lines
       {$line = '';
       }
      push @xml, $line;
     }
    else                                                                        # Process an image
     {if ($line =~ m(\A=))                                                      # End of an image
       {shift @image;                                                           # Remove initial &%v
        my $content = join '', @image;
        my @content = split //, $content =~ s(\r) ()gsr;                        # Remove spaces in image
        my $binary = '';                                                        # Binary content of image
        my $state = 0;                                                          # 0 - in character mode, 1 in hex mode
        for(my $j = 0; $j < @content; ++$j)
         {my $c = $content[$j];
          if ($state == 0)
           {if ($c eq qq(\\))
             {my $d = $content[$j+1];
              if ($d eq q(x))                                                   # Convert to x
               {$state = 1; ++$j;
               }
              elsif ($d eq qq(\\))                                              # A real back slash
               {$binary .= qq(\\); ++$j;
               }
              elsif ($d =~ m([rn]))                                             # r|n
               {++$j;
               }
              else
               {fff $i, $inputFile, "Backslash followed by $d not n|r|x|\\";
               }
             }
            else
             {$binary .= $c;
             }
           }
          else
           {my $d = $content[$j+1];
            if ($c eq q(\\))
             {if ($d eq q(x))
               {$state = 0; ++$j;
               }
              else
               {confess "Backslash followed by $d not x";
               }
             }
            else
             {$binary .= chr hex qq($c$d);
              ++$j;
             }
           }
         }

        my $i = gbBinaryStandardCreateFile                                      # Return the name of a file in the specified B<$folder> whose name is constructed from the md5 sum of the specified B<$content>, whose content is B<$content> and whose accompanying B<.imageDef> file contains the specified B<$name>.  Such a file can be copied multiple times by L<gbBinaryStandardCopyFile|/gbBinaryStandardCopyFile> regardless of the other files in the target folders while retaining the original name information.
         ($inputFile, $binary, lc($image), qq($inputFile at line $i));

        push @xml, qq(<image href="$i"/>);                                      # Xml to image

        if ($line =~ m(\A=EndInset)s)                                           # End of images
         {$image = undef;                                                       # Finished image cutting out
         }
        else                                                                    # Another image
         {$image = lc $line =~ s(\A=|\n|\r) ()gr;                               # Image type
         }
        @image = ();
       }
      else
       {push @image, substr($line, 1);
       }
     }
   }

  my $text = join "\n", qq(<mif>\n), @xml, qq(</mif>\n);                        # Write results - pretty printed if possible
  my $out  = fpe(fpn($inputFile), q(xml));
  if (my $x = eval {Data::Edit::Xml::new($text)})                               # Parse xml
   {owf($out, -p $x);                                                           # Indented
   }
  else
   {owf($out, $text);                                                           # Output as xml and return file
   }

  $out
 } # mifToXml

sub convertImageToSvg($)                                                        # Convert a graphics file to svg
 {my ($file) = @_;                                                              # File to convert
  return if $file =~ m((ole2)\Z)s;                                              # Add file types we cannot process correctly here to prevent them from being converted on each run

  my $svg = setFileExtension($file, q(svg));                                    # Converted image name

  my $cached = fpe(imageCache, fn($file), q(svg));                              # Cached image conversion - cannot use GB yet because the file will be called for by name

  if (-e $cached)                                                               # Reuse cached version
   {copyBinaryFile($cached, $svg);
   }
  else                                                                          # Convert and cache the image.
   {my $e = fe($file);
    my $c = qq(unoconv  -f svg -o "$svg" "$file");                              # Libre office
       $c = qq(pdftocairo -svg "$file"  "$svg") if $e =~ m(pdf)is;              # Pdf
       $c = qq(convert         "$file"  "$svg") if $e =~ m(tiff)is;             # Tiff
       $c = qq(inkscape -e "$svg" "$file")      if $e =~ m(emf)is;              # Inkscape

    lll qx($c);                                                                 # Convert

    if (-e $svg)                                                                # Check results
     {copyBinaryFile($svg, $cached);
     }
    else
     {lll "Unable to convert image file to svg:\n$file";                        # Need to extend converter to new image type
     }
   }
 }

sub downloadFromS3                                                              #P Download documents from S3 to the L<downloads|/downloads> folder.
 {if (&download)                                                                # Download if requested
   {lll "Download from S3";
    clearFolder(downloads, clearCount);                        # Clear last run
    makePath(downloads);                                                        # Make folder as aws cli will not

    my $s = s3InputFolder;                                                      # Download from S3
    my $t = downloads;                                                          # Download target
    my $p = s3Parms.s3ProfileValue;                                             # Cli parameters
    xxx qq(aws s3 sync $s $t $p);                                               # Run download

    for my $f(searchDirectoryTreesForMatchingFiles(downloads, qw(.odp .odt)))   # Rename odp and odt files to zip so they get unzipped
     {my $target = setFileExtension($f, q(zip));                                # Set extension
      rename $f, $target;                                                       # Rename to zip
     }

    if (1)                                                                      # Some people put zip files inside zip files so we have to unzip until there are no more zip files to unzip
     {my %unzipped;                                                             # Unzipped files
      for my $pass(1..3)                                                        # Let us hope that even the most ingenious customer will not zip file up to this depth!
       {lll "Unzip pass $pass";
         for my $zip(searchDirectoryTreesForMatchingFiles(downloads, q(.zip)))  # Unzip files
         {next if $unzipped{$zip}++;                                            # Skip if already unzipped
          my $d = fp $zip;                                                      # Unzip target folder
          my $D = fpd($d, fn $zip);                                             # Folder in downloads into which to unzip the file as we do not know the internal file structure
          makePath($D);                                                         # Make the path as zip will not
          my $c = qq(cd "$d"; unzip -d "$D" -qn "$zip"; rm -r "${D}__MACOSX" 2>/dev/null;);
          lll $c;                                                               # Print unzip
          xxx $c;                                                               # Run unzip
         }
       }
     }

    for my $zip(searchDirectoryTreesForMatchingFiles(downloads, q(.7z)))        # Unzip 7z files - no need for recursion so far
     {my $d = downloads;                                                        # Downloads folder
      my $D = fpd($d, fn $zip);                                                 # Folder in downloads into which to unzip the file as we do not know the internal file structure
      makePath($D);                                                             # Make the path as 7z will not
      my $c = qq(cd "$d"; 7z e "$zip" -y -o"$D");                               # 7z command
      lll $c;                                                                   # Print 7z
      xxx $c;                                                                   # Run 7z
     }

    if (1)                                                                      # Convert any mif files to xml as part of converting any downloaded files into something parseable
     {my $ps = newProcessStarter(maximumNumberOfProcesses);                     # Process starter
      for my $mif(searchDirectoryTreesForMatchingFiles(downloads, q(.mif)))     # Convert each mif file to xml
       {$ps->start(sub                                                          # Convert in parallel
         {my $f = mifToXml($mif);                                               # Convert to xml
          eval {Data::Edit::Xml::new($f)};                                      # Trial parse
          if ($@)                                                               # Report errors
           {confess "Unable to parse file:\n$mif\n$f\n$@\n";                    # Reason for failure
           }
          1                                                                     # Return success from multiverse to universe
         });
       }
      $ps->finish;                                                              # Finish parallel conversions
     }

    if (1)                                                                      # Convert images to svg where possible - run in parallel
     {my @images = searchDirectoryTreesForMatchingFiles(downloads,
                  qw(.dib .emf .ole2 .pdf .tiff .wmf .vsd .vsdx));
      my $images = @images;
      lll "Found images of numerosity $images";
      for my $image(@images)                                                    # Convert images
       {convertImageToSvg($image);
       }
     }

    Flip::Flop::download();                                                     # Downloads as completed
   }
  else
   {ddd "Download from S3 not requested";
   }
 }

sub spelling($$)                                                                #r Fix spelling in source string
 {my ($s, $file) = @_;                                                          # Source string, file being processed
  $s
 }

sub spellingOut($)                                                              #r Fix spelling in output string
 {my ($s) = @_;                                                                 # Output string
  $s
 }

sub convertOneFileToUTF8                                                        #P Convert one file to utf8 and return undef if successful else the name of the document in error
 {my ($source) = @_;                                                            # File to convert

  ddd "Convert one file to utf8: $source";                                      # Title

  my $target = swapFilePrefix($source, downloads, in);                          # Target file from source file
  makePath($target);

  my $fileType = sub                                                            # File type
   {my $c = qx(file "$source") // q(unknown file type);                         # Decode contents using B<file>

    return q(htmlAscii)   if $c =~ m(HTML document, ASCII text)s;               # Html
    return q(htmlUtf8)    if $c =~ m(HTML document, UTF-8 Unicode text)s;
    return q(htmlIso8859) if $c =~ m(HTML document, ISO-8859 text)s;
    return q(htmlNonIso)  if $c =~ m(HTML document, Non-ISO extended-ASCII)s;

    return q(xmlUtf8)     if $c =~ m(XML 1.0 document text)s;                   # Xml

    return q(ASCII)       if $c =~ m(ASCII text)s;                              # Something to be converted to Xml
    return q(ISO_8859-16) if $c =~ m(ISO-8859 text);
    return q(UTF8)        if $c =~ m(UTF-8 Unicode .*text)s;
    return q(UTF16)       if $c =~ m(UTF-16 Unicode text)s;

    my $t = readBinaryFile($source);                                            # Search unknown file for clues as to its content
    return q(UTF16)       if $t =~ m(\Aencoding="UTF-16"\Z);
    confess "\nUnknown file type $c\n\n";
   }->();

  if (isFileUtf8($source))                                                      # Copy file directly if already in utf8
   {if ($source =~ m(\.html?\Z)s and $fileType =~ m(\Ahtml)s)                   # Dita xml gets reported as html by file so further restrict the definition of what might be html
     {xxx qq(hxnormalize -x < "$source" > "$target");                           # Normalize html to xml
     }
    else
     {copyFile($source, $target);                                               # Direct copy
     }
   }
  else                                                                          # Convert file to utf8
   {if ($fileType =~ m(\Ahtml(Ascii|Utf8)))
     {xxx qq(hxnormalize -x < "$source" > "$target");                           # Normalize html to xml
     }
    elsif ($fileType =~ m(\Ahtml(Iso8859|NonIso)))                              # Normalize ISO8859 html to xml
     {xxx qq(hxnormalize -x < "$source" | iconv -c -f ISO_8859-16 -t UTF8 -o "$target" -);
     }
    else
     {xxx qq(iconv -c -f $fileType -t UTF8 -o "$target" "$source");             # Silently discard any unconvertible characters with -c !
     }
   }

  if (-e $target)                                                               # Preprocess source file
   {my $Text = readFile($target);
    my $text = $Text =~ s(encoding="[^"]+") (encoding="UTF-8")r;                # Write encoding if necessary
    $text    = spelling $text, $target;                                         # Check/fix spelling
    owf($target, $text) unless $text eq $Text;
    return undef
   }

  $source;
 }

sub convertToUTF8                                                               #P Convert the encoding of documents in L<downloads|/downloads> to utf8 equivalents in folder L<in|/in>.
 {if (unicode)
   {clearFolder(in, clearCount);

    my @d = searchDirectoryTreesForMatchingFiles(downloads, inputExt);          # Files downloaded
    my $n = @d;
    confess "No documents to convert" unless $n;                                # Stop right here if there is nothing to convert

    lll "Unicode conversion $n ",
        "xml documents to convert from folder: ", downloads;

    my @results = runInSquareRootParallel(maximumNumberOfProcesses,             # Convert in square parallel because we have a lot of small fast conversions
       sub{convertOneFileToUTF8(@_)},
       sub{@_},
       @d);

    if (my @failed = grep {$_} @results)                                        # Consolidate results -  list of conversions that failed
     {my $t = formatTableBasic([[qw(File)], map {[$_]} @failed]);
      eee "The following source files failed to convert:\n", $t;
     }
    else
     {lll "Unicode conversion - converted all $n documents";
      Flip::Flop::unicode();
     }
   }
  else
   {ddd "Unicode conversion not requested";
   }
 }

sub convertToUTF822                                                             #P Convert the encoding of documents in L<downloads|/downloads> to utf8 equivalents in folder L<in|/in>.
 {if (unicode)
   {clearFolder(in, clearCount);

    my @d = searchDirectoryTreesForMatchingFiles(downloads, inputExt);          # Files downloaded
    my $n = @d;
    confess "No documents to convert" unless $n;                                # Stop right here if there is nothing to convert

    lll "Unicode conversion $n ",
        "xml documents to convert from folder: ", downloads;

    my $ps = newProcessStarter(maximumNumberOfProcesses);                       # Process starter
#       $ps->processingTitle   = q(Convert documents to uft8);
#       $ps->totalToBeStarted  = $n;
#       $ps->processingLogFile = fpe(reports, qw(log convertUtf8 txt));

    for my $d(@d)                                                               # Convert projects
     {$ps->start(sub
       {[convertOneFileToUTF8($d)]
       });
     }
    if (my @results = $ps->finish)                                              # Consolidate results
     {my @failed;                                                               # Projects that failed to convert
      for my $r(@results)                                                       # Results
       {my ($source) = @$r;                                                     # Each result
        if ($source)                                                            # A failing file
         {push @failed, $source;                                                # Report failures
         }
       }
      if (@failed)                                                              # Confess to projects that failed to covert
       {my $t = formatTableBasic([[qw(File)], map {[$_]} @failed]);
        eee "The following source files failed to convert:\n", $t;
       }
      else
       {lll "Unicode conversion - converted all $n documents";
        Flip::Flop::unicode();
       }
     }
   }
  else
   {ddd "Unicode conversion not requested";
   }
 }

sub projectCount()                                                              #P Number of projects.
 {scalar keys %$projects
 }

sub chooseIDGroup($)                                                            #r Return the id group for a project - files with the same id group share the same set of id attributes.
 {my ($project) = @_;                                                           # Project
  q(all);
 }

# 2019.06.19 00:01:06
#sub chooseNameFromString($)                                                     #r Choose a name from a string
# {my ($string) = @_;                                                            # String
#  nameFromStringRestrictedToTitle($string);
# }

sub newProject($)                                                               #P Project details including at a minimum the name of the project and its source file.
 {my ($source) = @_;                                                            # Source file

  confess "Source file does not exist:\n$source\n" unless -e $source;
  my $name = fileMd5Sum(qq($source\n));                                         # The new line forces fileMd5Sum to get the md5 sum of the name not the content - which might well be identical to other files

  if (my $p = $projects->{$name})                                               # Check that we have a unique source file
   {confess "Duplicate source files:\n", $source, "\n".$p->source;
   }

  my $p = genHash(q(Project),                                                   # Project definition
    idGroup     => undef,                                                       # Projects with the same id group share id attributes.
    name        => $name,                                                       # Name of project
    number      => projectCount + 1,                                            # Number of project
    parseFailed => undef,                                                       # Parse of source file failed
    source      => $source,                                                     # Input file
    sourceSize  => fileSize($source),                                           # Size of input file
    targets     => undef,                                                       # Where the items cut out of this topic wind up
    test        => undef,                                                       # Test projects write their results unlinted to testResults
   );

  $p->idGroup = chooseIDGroup($p);                                              # Choose the id group for the project
  $projects->{$name} = $p;                                                      # Save project definition
 }

# 2019.06.19 00:01:06
#sub chooseProjectName($)                                                        #r Create a project name for each file to convert
# {my ($file) = @_;                                                              # Full file name
#  chooseNameFromString($file);
# }

sub findProjectFromSource($)                                                    #P Locate a project by its source file
 {my ($source) = @_;                                                            # Full file name
  my @p;
  my $file = swapFilePrefix($source, in);
  for my $p(values %$projects)
   {push @p, $p if swapFilePrefix($p->source, in) eq $file;
   }

  return $p[0] if @p == 1;                                                      # Found the matching project
  undef                                                                         # No such unique project
 }

sub findProjectWithLargestSource                                                #P Locate the project with the largest input source file
 {my $l;                                                                        # Project with largest input source file size
  for my $p(values %$projects)                                                  # Each project
   {$l = $p if !$l or $l->size < $p->size;                                      # Compare size
   }
  $l                                                                            # Largest project found
 }

my %failingFiles;

sub loadFailingFiles                                                            # Find source of each failing file while developing
 {if (&develop)                                                                 # Development only
   {my $failingFilesFolder = fpd(&exchangeHome, &client, qw(reports fails));    # Failing files folder
    for my $file(searchDirectoryTreesForMatchingFiles($failingFilesFolder))
     {if (my $l = Data::Edit::Xml::Lint::read($file))
       {$failingFiles{$l->inputFile}++;
       }
     }
   }
 }

sub selectFileForProcessing($$;$)                                               #r Select an input file for processing
 {my ($file, $number, $failed) = @_;                                            # Full file name, project number, known to have failed on last AWS run if true
  $file
 }

sub loadProjects                                                                #P Locate documents to convert from folder L<in|/in>.
 {$projects = {};                                                               # Reset projects
  if (testMode eq q(1) or ref(testMode))                                        # Local tests
   {lll "Run local tests";                                                      # Title

    for my $file(searchDirectoryTreesForMatchingFiles(testExchangeIn, inputExt))# Copy in new tests
     {my $fileName = fn $file;
      if ($fileName =~ m(b\Z)s)                                                 # Before file
       {my $project = $fileName =~ s(b\Z) ()gsr;
        my $in = fpe(tests, $project, q(dita));                                 # Input test file name
        if (!-e $in)                                                            # Copy to local input tests folder if not already present
         {warn "Added before file for $project as:\n$in\n";
          copyFile($file, $in);
         }
       }
      elsif ($fileName =~ m(a\Z)s)                                              # After file
       {my $project = $fileName =~ s(a\Z) ()gsr;
        my $in = fpe(testExpected, $project, q(dita));                          # Expected file name
        if (!-e $in)                                                            # Copy to local expected folder if not already present
         {warn "Added after file for project $project as:\n$in\n";
          copyFile($file, $in);
         }
       }
      else                                                                      # Complain about an unexpected file
       {#warn "Ignored unexpected test file:\n$file\n";
       }
     }

    for my $file(searchDirectoryTreesForMatchingFiles(tests, inputExt))         # Load tests
     {if (testMode eq q(1) or Data::Edit::Xml::atPositionMatch($file, testMode))# Filter tests if requested
       {my $p = newProject($file);
        $p->test = 1;
       }
     }

    clearFolder($_, 1e3) for out, parseFailed, reports, targets, testResults;   # Clear results folders
   }
  elsif (testMode eq q(2))                                                      # Standalone tests
   {if (my @files = searchDirectoryTreesForMatchingFiles(testStandAlone, inputExt))
     {$projects = {};                                                           # Remove any regression tests as they will only confuse the issue
      $standAlone = @files;
      warn "Entered standalone mode with $standAlone files in folder: ",
            testStandAlone;
      for my $file(@files)                                                      # Potential test documents from Phil
       {my $project = fn $file;
        if (!$$projects{$project})
         {newProject($file);
          warn "Added test project $project source $file";
         }
       }
     }
   }
  else                                                                          # Production documents
   {my @files = searchDirectoryTreesForMatchingFiles(in, inputExt);
    loadFailingFiles;
    for my $i(keys @files)
     {my $file = $files[$i];
      next unless selectFileForProcessing($file, $i+1, $failingFiles{$file});
      newProject($file);
     }
   }
 }

# 2019.06.15 00:29:11
#sub Project::by($$$)                                                           #P Process parse tree with checks to confirm features
# {my ($project, $x, $sub) = @_;                                                # Project, node, sub
#  $x->by($sub);
# }

sub formatXml($)                                                                #r Format xml
 {my ($x) = @_;                                                                 # Parse tree
  $x->prettyStringDitaHeaders;
 }

sub parseCacheFile($)                                                           #P Name of the file in which to cache parse trees
 {my ($project) = @_;                                                           # Project
  my $s = $project->source;
  my $m = fileMd5Sum($s);
  fpe(parseCache, $m, q(data));
 }

sub parseFile($)                                                                #P Parse a file
 {my ($file) = @_;                                                              # File
  my $e = fpe(parseFailed, $$, q(xml));                                         # Errors file
  my $x = eval {Data::Edit::Xml::new($file, errorsFile=>$e)};                   # Parse the source file

  if ($@)                                                                       # Report parse failure
   {eee join "\n", "Failed to parse file, errors in file:", $file, $e;          # Failure message
    return undef;
   }

  $x                                                                            # Return parse tree
 }

sub parseProject($)                                                             #r Parse a project.  Originally the results were cached for later reuse but it takes on only a few milliseconds and the cached results slow the AMI start up.
 {my ($project) = @_;                                                           # Project
  parseFile $project->source                                                    # Parse the source
 }

#sub parseProject22($)                                                           #P Parse a project.
# {my ($project) = @_;                                                           # Project
#  my $projectName = $project->name;
#
#  my $c = parseCacheFile($project);                                             # Cache parse file name
#
#  if (!&develop and -e $c)                                                      # Reuse cached parse if available on aws
#   {return retrieveFile($c);
#   }
#
#  if (my $x = parseFile($project->source))                                      # Parse the source
#   {storeFile($c, $x);                                                          # Cache parse
#    return $x;
#   }
#
#  undef                                                                         # Failed to parse
# }

# 2019.06.14 23:21:01
#sub fileFromString($$)                                                          #r Convert a string into a file name in the context of a parse tree to provide an md5 sum and a root tag
# {my ($x, $string) = @_;                                                        # Parse tree, string
#  defined($string) or confess "No string to convert to a file name";
#  my $s = firstNChars                                                           # String with junk removed
#   (chooseNameFromString($string), maximumFileFromStringLength);
#  my $f = join q(_),                                                            # File name
#    substr($x->tag, 0, 1),                                                      # Topic indicator
#    firstNChars
#     (chooseNameFromString($string), maximumFileFromStringLength),              # String with junk removed
#    fileMd5Sum -p $x;                                                           # Guid from parse content
#  $f =~ s(_+) (_)gs;                                                            # Collapse multiple _
#  $f
# }

sub lintTopic($$;$)                                                             #P Lint a topic and return the lint details
 {my ($project, $x, $title) = @_;                                               # Project, parse tree, optional title of lint

  $x->createGuidId;                                                             # Create an id for the topic saving any existing one as a label
# $x->set(xtrf=>$project->source);  # PS2-474                                   # Show source file on xtrf attribute so that it can be retrieved by xref - we do this after the creation of the guid for the topic to avoid affecting it with information that is about the content but not of the content
  my $source = spellingOut formatXml $x;                                        # Pretty print topic
  my $extension = $x->tag =~ m(map\Z)s ? &outExtMap : &outExtTopic;             # Choose output extension

  my $file = gbStandardFileName($source, $extension, titleOnly=>titleOnly);     # Standard name recorded in the lint details

  my $l = Data::Edit::Xml::Lint::new;                                           # Linter
     $l->catalog   = &catalog;                                                  # Catalog
     $l->ditaType  = -t $x;                                                     # Topic type
     $l->file      = fpf(&out, $file);                                          # Output file
     $l->guid      = $x->id;                                                    # Guid
     $l->inputFile = $project->source;                                          # Add source file information
     $l->labels    = $x;                                                        # Add label information to the output file so when all the files are written they can be retargeted by Data::Edit::Xml::Lint
     $l->project   = $project->idGroup;                                         # Group files into Id scopes
     $l->title     = $title if $title;                                          # Optional title
     $l->source    = $source;                                                   # Source from parse tree

  if ($project->test)                                                           # Write test results unlinted
   {my $f = fpf(&testResults, fne($project->source));
    if (!-e $f)
     {$l->file = owf($f, $source);
     }
   }
  else
   {$l->lint;                                                                   # Lint the results
   }

  $l
 }

sub createTarget($$$$)                                                          #P Lint a book map
 {my ($source, $target, $sourceDocType, $targetType) = @_;                      # Source file, target file produced from source file, source document type, target type: bookmap|image|topic

  -e $source or confess "No such file:\n$source";

  my $sourceFolder = sub                                                        # Source folder
   {for my $w(in, downloads)                                                    # Possible locations from whence came this file
     {return $w if index($source, $w) == 0;                                     # File came from this source folder
     }
    confess "Unknown source folder for file:\n$source";                         # The file does not come from a known foler
   }->();

  my $targetFile = swapFilePrefix($source, $sourceFolder, targets);             # Fully qualified target file name

  $targetType =~ m(\A(bookmap|image|topic)\Z)s or confess                       # Check target type
   "Invalid target type: $targetType";

  if    ($targetType eq q(image))                                               # check source folder is appropriate
   {$sourceFolder eq downloads or confess
     "Wrong source folder for image file:\n$source\n$sourceFolder";
   }
  else
   {$sourceFolder eq in or confess
     "Wrong source folder for topic or bookmap file:\n$source\n$sourceFolder";
   }

  my $r = genHash(q(SourceToTarget),                                            # Details of the target file created from the source file
    source        => $source,
    target        => $target,
    sourceDocType => $sourceDocType,
    targetType    => $targetType);

  dumpFile $targetFile, $r;                                                     # Save details in targets/ folder

  $r                                                                            # Return source to target mapping
 }

sub lintBookMap($$$$)                                                           #P Lint a book map
 {my ($project, $x, $bookMap, $title) = @_;                                     # Project, parse tree of source, book map parse tree, title of lint
  if ($bookMap->at_bookmap)                                                     # Change outermost topics refs to chapters
   {$_->change_chapter_topicref for @$bookMap;
   }

  my $lint = lintTopic($project, $bookMap, $title);                             # Lint book map

  $project->targets = createTarget                                              # Source file to target bookmap details
   ($project->source,
    $lint->file,
    $x->tag,
    q(bookmap));

  $lint                                                                         # Return lint result
 }

# at 2019.06.19 00:02:32
#sub relintTopic($$;$)                                                           #P Relint a topic and return the lint details
# {my ($file, $x, $newFile) = @_;                                                # File to relint, new parse tree, optional new file else overwrite existing file
#
#  my $l = Data::Edit::Xml::Lint::read($file);                                   # Linter
#     $l->file   = $newFile // $file;                                            # New file or existing file
#     $l->source = formatXml($x);                                                # Source from parse tree
#     $l->lint;                                                                  # Lint the results
#
#  $l
# }

sub cleanUpCutOutTopic($$)                                                      #r Clean up a topic once it has been cut out and its output file has been assigned
 {my ($project, $x) = @_;                                                       # Project, parse
 }

sub cleanUpBookMap($$)                                                          #r Clean up a book map once all its topics have been cut out and its output file has been assigned
 {my ($project, $x) = @_;                                                       # Project, parse
 }

sub topicIsEssentiallyEmpty($)                                                  #P Return B<1> if the topic is essentially empty else B<undef>.
 {my ($file) = @_;                                                              # File to check
  if (fileSize($file) < 2e3)                                                    # Only consider small files
   {if (my $x = parseFile($file))                                               # Parse the source
     {my $c = $x->countNonEmptyTags                                             # Count tags with content
       (qw(concept conbody reference refbody task taskbody));
      return 1 unless keys %$c;                                                 # Return empty unless there is content
     }
   }
  0                                                                             # Topic has content
 }

my @imageFiles;                                                                 # Cache the possible image files

sub findImage($)                                                                #P Find an image that has been misplaced
 {my ($image) = @_;                                                             # Image to locate

  @imageFiles = searchDirectoryTreesForMatchingFiles(downloads) if !@imageFiles;# Possible targets

  my $L; my $I;                                                                 # Best match length so far, best target that had that match
  my $i = reverse $image;                                                       # Image name reversed
  for my $file(@imageFiles)                                                     # Possible targets
   {if (my @e = stringsAreNotEqual($i, reverse $file))                          # Find common prefix of reversed file names
     {if (my $c = $e[0])                                                        # Common prefix
       {my $l = length($c);                                                     # Length of common prefix
        if (!$L or $L < $l)                                                     # Longer length
         {$L = $l; $I = $file;                                                  # Best match so far
         }
       }
     }
   }

  return $I if $I and fne($I) eq fne($image);                                   # Check that at least the lowest level matches
  $image                                                                        # No improvement possible
 }

sub standardDitaCleanUpDefault($$)                                              #P Clean up some items that always need to be done in Dita topics
 {my ($project, $x) = @_;                                                       # Project, parse

  $x->ditaObviousChanges;                                                       # Safe because preceded by convertDocument and followed by cleanUpCutoutTopic

  $x->by(sub                                                                    # External xref
   {my ($o, $p) = @_;
    if ($o->at_xref)
     {if (my $h = $o->href)
       {if ($h =~ m(\Ahttps?://|\Awww\.|\.com\Z|\.org\Z|\Amailto:)s)
         {$o->set(scope=>q(external), format=>q(html));
         }
       }
      $o->wrapWith_p if $p and -t $p =~ m(body\Z)s;                             # Buffer xref from parent body
     }
    elsif ($o->at_table)                                                        # Fix tables
     {$o->fixTable;
      $o->wrapWith_p if $o->at_table_entry;                                     # Resolve nested tables by wrapping the table in a p
     }

    if ($o->at_p_p)                                                             # Break out p under p
     {$o->breakOutChild;
     }

    $o->tag =~ s([^-0-9a-z]) ()gis;                                             # Remove any punctuation in tag names
    if (my $attr = $o->attributes)                                              # Remove any punctuation in attribute names
     {my %attr = %$attr;
      if (my @a = grep {m(\A[^0-9a-z]*\Z)is} keys %attr)                        # Attributes with punctuation in them
       {for my $a(@a)
         {my $A = $a =~ s([^0-9a-z]) ()gisr;                                    # Attribute minus punctuation
          if (!defined($attr{$A}))
           {$attr{$A} = delete $attr{$a};
           }
         }
        $o->attributes = \%attr;                                                # Modified attributes
       }
     }

    if ($o->at_image)                                                           # Copy images across
     {if (my $h = $o->href)                                                     # Image name
       {my $i = index($h, &in) == 0 ? $h :                                      # Href is fully qualified
                absFromAbsPlusRel($project->source, $h);                        # Relative image source in input
        my $d = swapFilePrefix($i, &in, &downloads);                            # Image source in downloads
           $d = findImage($d) unless -e $d;                                     # The right image often gets delivered in the wrong place
        if (-e $d)                                                              # Copy file across if it exists - Xref will report if it is missing
         {my $t = gbBinaryStandardCopyFile($d, &out);                           # Copy image into position - this might happen multiple times but so what - to compute is cheap!
          $o->href = fne($t);                                                   # Xref will take care of the path
          createTarget($d, $t, q(image), q(image));                             # Image to image mapping
         }
       }
     }
   });
 } # standardDitaCleanUpDefault

sub standardDitaCleanUp($$)                                                     #r Clean up some items that always need to be done in Dita topics
 {my ($project, $x) = @_;                                                       # Project, parse
  standardDitaCleanUpDefault($project, $x);                                     # Default standard clean up
 } # standardDitaCleanUp

sub couldBeCutOut($)                                                            #P Return true if this node can be cut out
 {my ($node) = @_;                                                              # Node to test
  $node->at(qr(\A(concept|glossentry|reference|task)\Z))                        # Topics we can cut on
 }

sub isAMap($)                                                                   # Return true if this node is a map
 {my ($node) = @_;                                                              # Node to test
  $node->tag =~ m(map\Z)                                                        # Map
 }

sub cutOutTopics($$)                                                            #P Cut out the topics in a document assuming that they are nested within the parse tree and create a bookmap from the residue if it is not already a bookmap
 {my ($project, $x) = @_;                                                       # Project == document to cut, parse tree.
  my $title = fn $project->source;                                              # Default title for residual book map
  my $topicRef;                                                                 # Topic refs tree
  my $topicPath;                                                                # Path of latest topic

  standardDitaCleanUp($project, $x);                                            # Standard dita clean up

  if (printTopicTrees)                                                          # Print tree before cutting out begins if requested
   {my $f = swapFilePrefix($project->source, in, topicTrees);
    owf($f, -p $x);
   }

  $x->by(sub                                                                    # Cut out each topic converting the residue to a bookmap if it is not already a bookmap
   {my ($o, $p)  = @_;
    if (couldBeCutOut($o))                                                      # Cut out topics
     {$topicRef  = $o->wrapWith(qq(topicref));                                  # Wrap inner concepts in topicref

      $o->downToDie(sub                                                         # Nest topic references
       {my ($r)  = @_;
        if ($r->at(qr(\A(appendix|chapter|mapref|topicref)\Z)))
         {$topicRef->putLastCut($r);                                            # Move topics and their sub topics out of section into containing topic
          die "Topmost topic reached";                                          # Finished with this enclosing topicref
         }
       });

      $o->cut;                                                                  # Cut out referenced section
      my $O = $o->renew;                                                        # Renew the parse tree to eliminate corner cases involving white space
      cleanUpCutOutTopic($project, $O);                                         # Clean up renewed topic

      my $Title = $O->go_title;                                                 # Get the title of the piece
      my $title = $Title ? $Title->stringText : q();                            # Title content
      my $lint  = lintTopic($project, $O, $title);                              # Lint topic

      $topicRef->setAttr(navtitle=>$title, href=>fne($lint->file));             # Set navtitle and href for topicref knowing it conforms to the GB Standard
      $topicPath = $lint->file;
     }
   });

  if ($topicRef)                                                                # Create book map from topicRefs  that have content
   {$topicRef->cut;                                                             # Cut out the topic tree so we can print the notices if any

    if (!$topicRef->isAllBlankText)                                             # Topicref has content or overridden by single topic bookmaps
     {my $notices = sub                                                         # The notices are any remaining text
       {return q() if couldBeCutOut($x)  or                                     # Cut out everything
                      isAMap($x)         or                                     # We are processing a map so there is no need for notices
                      $x->isAllBlankText;                                       # Notice content would be all blank so there is no need for notices
        my $c = $x->wrapWith_conbody_wrapWith_concept;                          # Put the notices in a concept
        $c->putFirstAsTree(<<END);
<title>$title</title>
END
        my $l = lintTopic($project, $c, 'Notices for: '.$title);                # Lint the notices
        fne($l->file)                                                           # File containing notices concept
       }->();

      my $bookMap = isAMap($x) ? $x : $x->ditaSampleBookMap                     # Create a bookmap unless we have been left with a bookmap
       (chapters=>$topicRef, title=>$title, notices=>$notices);


      cleanUpBookMap($project, $bookMap);                                       # Clean up book map
      lintBookMap($project, $x, $bookMap, $title);                              # Lint bookmap
     }
    else                                                                        # Not creating a book map for a single item
     {$project->targets =                                                       # Source file to target file details
        createTarget($project->source, $topicPath, $x->tag, q(topic));
     }
   }
  else                                                                          # No recognized structure so we will just create a bookmap so we get errors that we can see
   {my $bookMap = isAMap($x) ? $x : $x->wrapWith_bookmap;                       # Either its a bookmap or its something that we might be able to improve into being a bookmap
    cleanUpBookMap($project, $bookMap);                                         # Clean up book map
    lintBookMap($project, $x, $bookMap, $title);                                # Lint bookmap
   }
 } # cutOutTopics

sub convertDocument($$)                                                         #r Convert one document.
 {my ($project, $x) = @_;                                                       # Project == document to convert, parse tree.
  $x->wrapDown_conbody_concept unless couldBeCutOuut($x) or isAMap($x);         # Turn it into a concept if not already a recognizable type
  $x->ditaObviousChanges;
  $x                                                                            # Return parse tree
 }

sub convertProject($)                                                           #P Convert one document held in folder L<in|/in> into topic files held in L<out|/out>.
 {my ($project) = @_;                                                           # Project == document to convert
  ddd "convertProject           $$:", $project->source;

#  undef &Data::Edit::Xml::byStart;                                              # Print the name of the projects still being converted
#        *Data::Edit::Xml::byStart = sub
#   {my (undef, $file, $line) = caller(1);
#    lll "convertProject converting $$:", $project->source, "at $file line $line";
#   };

  my $x = parseProject $project;                                                # Reload parse into this process
  return $project unless $x;                                                    # Parse failed

  my $y = convertDocument($project, $x);                                        # Convert document optionally returning a new parse tree
  $x = $y if ref($y) and ref($y) eq ref($x);                                    # Continue with new parse tree if one provided

  cutOutTopics($project, $x);                                                   # Cut out topics
  $project->targets or confess                                                  # Check every source file has a target file
    "No target for project from source file:\n".$project->source;

  ddd "convertProject finished  $$:", $project->source;
  $project                                                                      # Conversion succeeded for project
 } # convertProject

sub xrefResults                                                                 #P Run Xref to fix check results
 {if (xref)
   {Data::Edit::Xml::Xref::xref                                                 # Check and perhaps fix any cross references
     (addNavTitles              => xrefAddNavTitles,
      allowUniquePartialMatches => xrefAllowUniquePartialMatches,
      changeBadXrefToPh         => changeBadXrefToPh,
      deguidize                 => &deguidize,
      fixBadRefs                => &fixBadRefs,
      fixDitaRefs               => &fixDitaRefs ? targets : undef,              # Location of targets if we are going to fix dita refs in the output corpus that were valid in the input corpus
      fixRelocatedRefs          => &fixRelocatedRefs,                           # Fix references to relocated files that adhere to the GB Standard.
      fixXrefsByTitle           => &fixXrefsByTitle,                            # Fix xref by unique title
      inputFolder               => &out,
      matchTopics               => &xrefMatchTopics,
      maximumNumberOfProcesses  => &maximumNumberOfProcesses,
      reports                   => &reports,
     );
   }
  else
   {ddd "Xref not requested";
   }
  undef
 }

sub lintResultsDefault                                                          #P Lint results held in folder L<out|/out>and write reports to folder L<reports|/reports>.
 {if (lint)                                                                     # Only if lint requested
   {lll "Lint conversion results";
    if (my $report = $lintReport = Data::Edit::Xml::Lint::report                # Lint report
     (out, qr(\.(dita|ditamap|xml)\Z)))
     {my $xref = $report->failingFiles ? xrefResults : undef;                   # Xref results if we are at 100% lint
      my $d = dateTimeStamp;
      my $p = pleaseSee($report, $xref);
      my $r = $report->print;

      my $x = sub                                                               # Include xref results
       {return q() unless $xref;
        $xref->statusLine. " Tags To Text: ".$xref->tagsTextsRatio // q();
       }->();

      if (my $n = &numberOfFiles)                                               # Check number of files if a count has been supplied
       {if (my $r = $report->numberOfFiles)
         {if ($r != $n)
           {cluck "Number of output files: $r does not match expected number: $n";
       } } }

      my $s = <<END;                                                            # rrrr - write summary.txt
Summary of passing and failing projects on $d.\t\tVersion: $VERSION

$r

$x

$p
END
      say STDERR $s;                                                            # Write lint results
      owf(summaryFile, $s);
      Flip::Flop::lint();

      if (my $fails = $report->failingFiles)                                    # Copy failing files into their own folder  for easy access s
       {if (@$fails)
         {for my $file(@$fails)
           {my $f = $file->[2];                                                 # Failing file name
            my $F = fpf(fails, fne $f);                                         # Shorten file name path so we can find the file easily
            copyFile($f, $F);
           }
         }
       }

      $lintResults = join "\n\n", ($r =~ s(\n.*\Z) ()sr), $x, $p;               # Lint results summary, used to create GitHub notification after upload is complete
     }
    else
     {lll "No Lint report available";;
     }
   }
  else
   {ddd "Lint report not requested";
   }
 } # lintResultsDefault

sub lintResults                                                                 #r Lint results held in folder L<out|/out>and write reports to folder L<reports|/reports>.
 {lintResultsDefault;                                                           # Only if lint requested
 }

sub copyLogFiles                                                                #P Copy log files to reports/ so they get uploaded too
 {for my $source(errorLogFile)#, logFile, logStderr)
   {my $target = swapFilePrefix($source, perl, reports);
    copyBinaryFile($source, $target) if -e $source;
   }
 }

sub chunkFile($)                                                                #P Chunk a file name to make it more readable
 {my ($file) = @_;                                                              # File to chunk
  my $f = swapFilePrefix($file, home);                                          # Remove common prefix
  join " <big><b>/</b></big> ", split m(/), $f;                                 # Chunk the file name to make it more readable
 }

sub copyFilesToWeb2                                                             #P Copy files into position so that they can be web served
 {return if develop;
  my $client        = client;
  my $reports       = reports;
  my $www           = www;
  my $wwwClient     = publications;
  my $searchFolder  = qq(<input style="display: none;" type="text" name="folder" value="$client">);
  my $date          = dateTimeStamp;
  my $aws           = awsIp;
  my $http          = "http://$aws/";                                           # Http address
  my $mimEdit       = "http://$aws/cgi-bin/fileManager.pl?";                    # Mim editor address

  push my @html, <<END;                                                         # Create html
<head>
  <meta charset="UTF-8">
  <style>

\@font-face
 {font-family: dvs
  src        : url(http://$aws/woff/DejaVuSans.woff)
 }

*
 {font-family: dvs
 }

.even {
  background-color: #ddffdd;
}

.odd {
  background-color: #ffdddd;
}
</style>

</head>
<body>

<body>
<table>

<tr>
<td>Run on: $date

<td><form action="/cgi-bin/fileManager.pl">
Grep: <input type="text" name="grep"> <input type="submit" value="Submit">$searchFolder
</form>

<td><form action="/cgi-bin/fileManager.pl">
Find: <input type="text" name="search" value=""> <input type="submit" value="Submit">$searchFolder
</form>

<td>F1 to switch help on and off

</table>

<div id="help" style="display : none;  position: fixed;
  z-index : 1;
  left    : 0;
  top     : 0;
  width   : 100%;
  height  : 100%;
  overflow: auto;
  background-color: #ffffff;
">
<p>Please send me your proposed help text and I will install it on this page!
</div>

<script>
document.onkeydown = function(e)                                                // Intercept help key and display help
 {if (e.key == 'F1')
   {const h = document.getElementById('help');
    if (h.style.display == "none") h.style.display = "block";
    else                           h.style.display = "none";

    e.preventDefault();
    e.stopImmediatePropagation();
   }
 }
</script>

<table border=1 cellspacing=5 cellpadding=5 style="width: 100%; version: 20190315-111">
END
  xxx qq(sudo rm -r $wwwClient; sudo mkdir -p $wwwClient);

  my @files =                                                                   # File list
    grep {!-d $_}
    grep {!m(/\.)}                                                              # Dot files
    searchDirectoryTreesForMatchingFiles(perl, reports, out);

  my @sorted  = ((grep { m($reports.*summary.txt)} @files),                     # Put reports first so they are to hand
                 (grep { m($reports)} @files),
                 (grep {!m($reports)} @files),
                  searchDirectoryTreesForMatchingFiles(downloads, q(.xml)));    # Xml files

  my %files;                                                                    # {existing file name} = GB standard name - this allows all the web served files to be placed in one folder which makes referencing them much easier
  my %action;                                                                   # {existing file name} = action
  for my $file(@sorted)                                                         # List files
   {my ($action, $ext) = sub
     {my $e = fe $file;
      return (q(skip), q())   unless $e;                                        # Accompanying files
      return (q(edit),  $e)   if $e =~ m((dita|ditamap|xml)\Z)is;               # Edit Dita files
      return qw(pre     html) if $e =~ m(txt\Z)is;                              # Copy txt files with pre wrapped around them
      return (q(copy),  $e)   if $e =~ m((csv|html|svg)\Z)is;                   # Copy csv, html and svg as they are.
      return (q(image), $e);                                                    # Make as an image
     }->();
    next unless $ext;                                                           # Skip companion files
    $files {$file} = setFileExtension(uniqueNameFromFile($file), $ext) if $ext; # Target file name for each file with possible new extension
    $action{$file} = $action;
   }

  my $tempFile = temporaryFile;
  my $count    = 0;
  for my $file(@sorted)                                                         # Edit files to link to other files and copy to web server area so that when reruns are occurring we can still see the content
   {my $relFile = $files{$file};                                                # File relative to index.html
    next unless $relFile;                                                       # Keep the special sort order
    my $target  = fpf($wwwClient, $relFile);                                    # Web file relative to web server home
    my $action  = $action{$file};                                               # Wrap text files with pre to make them into html

    if ($action eq q(say))                                                      # Skip companion files
     {next;
     }
    elsif ($action eq q(pre))                                                   # Wrap text files with pre to make them into html
     {my $s = eval {readFile($file)};                                           # Read source
      if ($@)
       {lll "Cannot read file:\$file\n$@";
        next;
       }
      my $S = $s =~ s(<) (&lt;)gsr =~ s(>) (&gt;)gsr;                           # Replace angle brackets

      my $T = sub                                                               # Convert fully qualified names in tables to anchors
       {my ($s) = @_;
        my @s = split /\x{200b}/, $s;                                           # Split on zero width space
        for my $s(@s)
         {if ($s =~ m(\A(.*?)\s*\Z)s)
           {if (my $f = $files{$1})
             {$s = qq(<a href="$f">$s</a>);
             }
           }
         }
        join q(), @s;
       }->($S);

      my $H = sub                                                               # Expand hrefs
       {my ($text) = @_;
        my @hrefs = split m((?= href="[^"]+)), $text;
        for my $h(@hrefs)
         {if ($h =~ m(\A href="([^"]+)"(.*)\Z)s)
           {my $hrefFile = $1;
            my $rest     = $2;
            my $F = absFromAbsPlusRel($file, $hrefFile);
            if (my $f = $files{$F})
             {$h = qq( <a href="$f">$hrefFile</a> $rest);
             }
           }
         }
        join q(), @hrefs;
       }->($T);

      owf($tempFile, <<END);
<html>
<meta charset="UTF-8">
<pre>
$H
</pre>
</html>
END
      my $cmd = qq(sudo cp "$tempFile" "$target");
      lll $cmd;
      lll qx($cmd);
     }
    else                                                                        # Not a text file so copy directly
     {my $cmd = qq(sudo cp "$file" "$target");
      lll $cmd;
      lll qx($cmd);
     }

    my $publish = sub                                                           # Link to html version of bookmap
     {if ($file =~ m(.ditamap\Z)s)
       {my $p = bookMapPublicationFolder($file);
        my $f = fn $file;
        return qq(<td><a href="$f/index.html"><b>html</b></a>);
       }
      return q(<td>);
     }->();


    if (1)                                                                      # Generate html table row for file
     {++$count;
      my $bg          = qw(even odd)[$count % 2];                               # Row back ground colour
      my $row         = sprintf("%04d", $count);
      my $size        = fileSize($file);                                        # Size of file
      my $original    = gbBinaryStandardCompanionFileContent($file);            # Original file name
      my $chunkedFile = chunkFile($original // $file);                          # Easier to format file name

      push @html, qq(<tr class="$bg"><td align="right">$row).                   # Row number
                  qq(<td align="right">$size).                                  # File size
                  $publish.                                                     # Html after conversion by Dita OT
                  qq(<td>);

      if ($action    =~ m(image|svg))                                           # Image
       {push @html, qq(<img src="$relFile">$chunkedFile);
       }
      elsif ($action eq q(edit))                                                # Edit
       {push @html, <<END;
<a href="${mimEdit}mim=$relFile&folder=$client">$chunkedFile</a>
END
       }
      else                                                                      # Browse
       {push @html, qq(<a href="$relFile">$chunkedFile</a>);
       }
     }
   }
  push @html, <<END;
</table>
</body>
END

  if (1)                                                                        # Create index
   {my $target = fpe($wwwClient, qw(index html));
    my $source = owf($tempFile, join "\n", @html);
    xxx qq(sudo cp $source $target; sudo chmod -R ugo+r $wwwClient), qr();
   }
  unlink $tempFile;
 }

sub copyFilesToWeb                                                              #P Copy files into position so that they can be web served
 {if (mimajen)
   {lll "Copy file to server for viewing with mimajen";
    copyFilesToWeb2;
   }
  else
   {ddd "Upload to S3 not requested";
   }
 }

sub beforeUploadToS3                                                            #r Copy additional files into position before upload to s3
 {
 }

sub uploadFoldersToS3                                                           #r Upload folders to S3
 {my ($processStarter) = @_;                                                    # Process starter

  my $p = s3Parms.s3ProfileValue;

  for my $dir(reports, out, perl, parseFailed, targets)
   {next unless -d $dir;
    my $target = swapFolderPrefix($dir, home, s3OutputFolder);
    my $c = qq(aws s3 sync $dir $target $p);
    lll $c;
    $processStarter->start(sub
     {say STDERR qx($c);
     });
   }
 }

sub uploadToS3($)                                                               #P Copy entire home folder to S3
 {my ($processStarter) = @_;                                                    # Process starter

  beforeUploadToS3;                                                             # Copy in additional files if required
  my $upload = sub                                                              # Decode upload requirements
   {return undef unless upload;
    return 2 if upload == 2;
    if ($lintReport)
     {return 1 if $lintReport->totalErrors == 0;
     }
    undef
   }->();

  if ($upload)
   {lll "Upload to S3";
    if (s3OutputFolder)                                                         # Upload to output area if requested
     {uploadFoldersToS3($processStarter);
     }
    else
     {eee q(Upload to S3 requested but S3OutputFolder not set);
     }
    Flip::Flop::uploadToS3();                                                   # Reset upload flip flop
   }
  elsif (upload)
   {lll "Upload to S3 ".upload."/".$lintReport->totalErrors." suppressed by lint results";
   }
  else
   {ddd "Upload to S3 not requested";
   }
 } # uploadToS3

sub uploadToExchange                                                            #P Copy entire home folder to Exchange
 {my ($processStarter) = @_;                                                    # Process starter
  my $h = home;
  my $p = s3Parms.s3ProfileValue;

  my $exchange = sub                                                            # Decode upload requirements
   {return undef unless exchange;
    return 2 if exchange == 2;
    if ($lintReport)
     {return 1 if $lintReport->totalErrors == 0;
     }
    undef
   }->();

  if ($exchange)
   {lll "Upload to Exchange";

    if (s3ExchangeFolder)
     {my @d;                                                                    # Folders to upload
      my $e = exchangeItems||'';
      push @d, downloads    if $e =~ m(d)i;
      push @d, in           if $e =~ m(i)i;
      push @d, perl         if $e =~ m(p)i;
      push @d, out          if $e =~ m(o)i;
      push @d, reports
      push @d, topicTrees   if $e =~ m(t)i;
      push @d, parseFailed;
      push @d, targets;

      for my $dir(@d)                                                           # Upload requested folders
       {next unless -e $dir;
        my $target = swapFilePrefix($dir, home, s3ExchangeFolder);
        $processStarter->start(sub
         {xxx qq(aws s3 sync $dir $target $p);
         });
       }
     }
    else
     {lll q(Upload to Exchange requested but S3ExchangeFolder not set);
     }
    Flip::Flop::uploadToExchange();                                             # Reset upload flip flop
   }
  elsif (exchange)
   {lll "Upload to S3 Exchange ".exchange."/".$lintReport->totalErrors." suppressed by lint results";
   }
  else
   {lll "Upload to Exchange not requested";
   }
 } # uploadToExchange

sub uploadResults                                                               #P Upload results
 {my $p = newProcessStarter(maximumNumberOfProcesses);                          # Process starter
  uploadToS3($p);
  uploadToExchange($p);
  $p->finish();
 } # uploadResults

sub bookMapPublicationFolder($)                                                 #P Folder for html obtained by converting bookmap in supplied file
 {my ($bookMap) = @_;                                                           # Bookmap file
  fpd(publications, fn $bookMap)
 }

sub convertBookMapToHtml($)                                                     #P Publish bookmaps on web server
 {my ($bookMap) = @_;                                                           # Bookmap
  my $d = ditaBin;
  my $o = fpd(publications, fn $bookMap);

  yyy(<<END);                                                                   # Publish bookmap
sudo mkdir -p $o
sudo rm -r $o
sudo $d -input=$bookMap -format=html5 -output $o
END

  if (1)                                                                        # DitaOT puts our files in the wrong folder!!!  Fix this problem...
   {my @files = searchDirectoryTreesForMatchingFiles($o);
    for my $source(@files)
     {next if -d $source;
      my $target = fpf($o, fne $source);
      if (!-e $target)
       {my $c = qq(sudo mv $source $o);
        lll qx($c);
       }
     }
   }
 }

sub convertBookMapsToHtml                                                       #P Publish bookmaps on web server
 {my $h = home;

  my $ps = newProcessStarter(maximumNumberOfProcesses);                         # Process starter
  for my $bm(searchDirectoryTreesForMatchingFiles(out, q(.ditamap)))            # Convert each bookmap to html
   {$ps->start(sub
     {convertBookMapToHtml($bm);                                                # Convert to html
      1
     });
   }

  $ps->finish;                                                                  # Finish publication
 }

sub convertDitaToHtml                                                           #P Publish bookmaps on web server
 {my $h = home;

  my $publish = sub                                                             # Decode publication requirements
   {return undef unless publish;
    return 2 if publish == 2;
    if ($lintReport)
     {return 1 if $lintReport->totalErrors == 0;
     }
    undef
   }->();

  if ($publish)                                                                 # Publish
   {lll "Convert Dita to HTML and publish";
    convertBookMapsToHtml;
    Flip::Flop::publish();                                                      # Reset publish flip flop
   }
  elsif (publish)
   {lll "Publish ".publish."/".$lintReport->totalErrors." suppressed by lint results";
   }
  else
   {ddd "Publish not requested";
   }
 } # convertDitaToHtml

# Could not cope with file flattening at 2019.06.14 23:24:48
#sub relinkDitaRefsInOutputFiles($)                                              #r Relink the valid dita references in the old corpus so they are valid in the new corpus contained in B<$folder>.
# {my ($folder) = @_;                                                            # Folder containing corpus to be linked
# lll "Relink dita references";
#
#  my %newFileToOldFile;                                                         # {newFile} = oldFile
#  my %oldFileAndIdToNewFile;                                                    # {project}{oldFile}{id} = newFile
#
#  Data::Edit::Xml::Lint::relint(maximumNumberOfProcesses,                       # Relint all the files
#
#  sub                                                                           # Analysis sub
#   {my ($linkMap, $filesToGuids) = @_;                                          # Link map, files to guids
#
#    for  my $newFile(sort keys %$filesToGuids)                                  # Map new files back to their old source files
#     {my $oldFile = gbStandardCompanionFileContent($newFile);
#      $newFileToOldFile{$newFile} = $oldFile;
#     }
#
#    for  my $project(sort keys %$linkMap)                                       # Map an id in an old file to the new file, believed unique, that now contains it.
#     {for  my $label(sort keys %{$$linkMap{$project}})
#       {for my $targets($$linkMap{$project}{$label})
#         {for my $target(@$targets)
#           {my ($newFile, $id) = @$target;
#            if (my $oldFile = $newFileToOldFile{$newFile})
#             {$oldFileAndIdToNewFile{$project}{$oldFile}{$id} = $newFile;
#             }
#           }
#         }
#       }
#     }
#
#    1
#   },
#
#  sub                                                                           # Reprocess each dita file sub
#   {my ($x, $linkMap, $filesToGuids, $lint) = @_;
#    my $project       = $lint->project;                                         # Project we are in
#    my $newSourceFile = $lint->file;                                            # Source file we are processing
#    my $oldSourceFile = $newFileToOldFile{$newSourceFile};                      # Origin of source file we are processing
#    my $count;                                                                  # Count the number of changes made
#
#    $x->by(sub                                                                  # Look for conrefs and hrefs in the parse tree
#     {my ($o) = @_;
#      if (my $h = $o->attr_conref // $o->href)                                  # Conref or Href
#       {my ($OldFile, $topicId, $id) = parseDitaRef($h);                        # Parse reference
#        if ($OldFile and $topicId and $id)                                      # Full reference
#         {my $oldFile = absFromAbsPlusRel($oldSourceFile, $OldFile);;           # The full name of the old file that contained this reference target
#
#          if (my $newFile = $oldFileAndIdToNewFile{$project}{$oldFile}{$id})    # Locate new file containing reference target
#           {if (my $newTopicId = $$filesToGuids{$newFile})                      # Topic id of new file
#             {my $NewFile      = fne($newFile);                                 # Short name of new file containing reference target
#              my $H            = $NewFile.q(#).$newTopicId.q(/).$id;            # Updated reference
#              $o->set(($o->attr_conref ? q(conref) : q(href)), $H);             # Update conref or href
#              ++$count;
#             }
#           }
#         }
#        elsif ($OldFile)                                                        # File reference
#         {my $oldFile = absFromAbsPlusRel($oldSourceFile, $OldFile);;           # The full name of the old file that contained this reference target
#
#          if (my $newFile = $newFileToOldFile{$oldFile})                        # Locate corresponding new file
#           {my $NewFile = fne($newFile);                                        # Short name of new file containing reference target
#            my $H       = $NewFile;                                             # Updated reference
#            $o->set(($o->attr_conref ? q(conref) : q(href)), $H);               # Update conref or href
#            ++$count;
#           }
#         }
#       }
#     });
#
#    $count
#
#   }, $folder, &inputExt);                                                      # Reprocess all the output files
# } # relinkDitaRefsInOutputFiles
#
#sub relinkDitaRefsInOutputCorpus                                                #r Use Data::Edit::Xml::Lint to convert dita references in input corpus to valid references in the output corpus
# {if (relinkDitaRefs)
#   {lll "Relink Dita references";
#    relinkDitaRefsInOutputFiles(&out);
#    Flip::Flop::relinkDitaRefs();                                               # Reset flip flop
#   }
#  else
#   {ddd "Relink Dita references not requested";
#   }
# } # relinkDitaRefsInOutputCorpus

my @failedTests;                                                                # Failing tests
my @passedTests;                                                                # Passed tests
my @availableTests;                                                             # Available Tests

sub runTests                                                                    #P Run tests by comparing files in folder L<out|/out> with corresponding files in L<testResults|/testResults>.
 {if (develop and testMode == 1)                                                # Run tests if developing
   {&checkResults;
    my $F = join " ", @failedTests;
    my $f = @failedTests;
    my $p = @passedTests;
    my $a = @availableTests;

    $f + $p != $a and confess "Passing tests: $p plus failing tests: $f".
     " not equal to tests available: $a";

    if ($f)
     {confess "Failed tests $f tests out $F";
     }
    else
     {lll "Passed all tests";
     }
   }
 }

sub normalizeXml($)                                                             #P Remove document processor tags
 {my ($string) = @_;                                                            # Text to normalize
  $string =~ s(<[!?][^>]*>)  ()gs;                                              # Headers and comments
  $string =~ s( (props|id)="[^"]*") ()gs;
  $string =~ s( xtrf="[^"]*") ()gs;                                             # Remove xtrf attribute as it often contains meta data
  $string
 }

sub testResult($$$)                                                             #P Evaluate the results of a test
 {my ($test, $got, $expected) = @_;                                             # Test name, what we got, what we expected result
  my $g = normalizeXml($got);
  my $e = normalizeXml($expected);

  if ($e !~ m(\S)s)                                                             # Blank test file
   {confess "Expected results for test $test is all blank";
   }

  my %g = map {trim($_)=>1} split /\n/, $g;                                     # Remove lines that match
  my %e = map {trim($_)=>1} split /\n/, $e;

  for my $k(keys(%g), keys(%e))
   {if ($e{$k} and $g{$k})
     {delete $e{$k}; delete $g{$k};
   } }

  if (!keys(%g) and !keys(%e))                                                  # Compare got with expected
   {push @passedTests, $test;
    say STDERR "ok $test";
    return 1;
   }
  else                                                                          # Not as expected - the results are  not printed in sequential order as one might reasonably expect.
   {push @failedTests, $test;
    my $e = join "\n", sort keys %e;
    my $g = join "\n", sort keys %g;
    cluck "Got/expected in test $test:\n".
          "Got:\n$g\nExpected:\n$e\n";
    return 0;
   }
 }

sub checkResults                                                                #P Check test results
 {for my $file(searchDirectoryTreesForMatchingFiles(tests, &inputExt))
   {my $test = fn $file;
    my $expected = fpe(testExpected, $test, q(dita));
    my $got      = fpe(testResults,  $test, q(dita));
    if (-e $got)
     {if (!-e $expected)
       {lll "Created expected results for $test\n$expected\n";
        copyFile($got, $expected);                                              # Create expected test results
       }
      else
       {push @availableTests, $test;
        my $g = readFile($got);
        my $e = readFile($expected);
        if (!testResult($test, $g, $e))
         {#owf($expected, $g);                                                  # Force all test results to be up to date if necessary
         }
       }
     }
    else
     {cluck "No test output for $test";
     }
   }
 }

sub reportProjectsThatFailedToParse                                             #P Report projects that failed to parse
 {ddd "Report projects that failed to parse";

  my @parseFailed;                                                              # Projects that failed to parse
  for my $p(sort keys %$projects)                                               # Each project
   {my $project = $projects->{$p};

    if (my $f = $project->parseFailed)                                          # Report projects that failed to parse
     {push @parseFailed, [$project->name, $project->source, $f];
     }
   }
  delete $$projects{$$_[0]} for @parseFailed;                                   # Remove projects that failed to parse

  formatTable(\@parseFailed, <<END,
Project Project name
Source  Source file
Errors  Error listing
END
    head=><<END,
NNNN projects failed to parse on DDDD.

END
    file=>my $parseFailedReportFile = fpe(reports, qw(failedToParse txt)));

  if (my $n = @parseFailed)                                                     # Report parse failures summary
   {eee "$n projects failed to parse, see:\n$parseFailedReportFile"
   }
 }

sub reportSourceMapToTargets                                                    #P Report where the source files went - done in Xref at: lists source_to_targets
 {ddd "Report source files mapped to targets";
  my @files = searchDirectoryTreesForMatchingFiles(targets);                    # Files in targets folder
  my $files = @files;
  my @r;

  for my $file(@files)                                                          # Each target file
   {my $m = evalFile($file);                                                    # Source to target details

    push @r, [$m->sourceDocType, $m->source, $m->targetType, $m->target];

    if ($m->targetType =~ m(map\Z))                                             # The target might be a map beciase a map was inout or bbecuase one was generted by cuttiing out.  The generated one will have the correct file names in it. Thecopied mma;p will have the originals file names in it - Xref will fix them by looking for their true targets elsewhere in the targets folder.
     {my $x = parseFile($m->target);
      $x->by(sub
       {my ($o) = @_;
        if ($o->at(qr(\A(chapter|topicref)\Z)))
         {my $targetFile =
           push @r, [q(), q(),  q(), $o->href, $o->attrX_navtitle];
         }
       });
     }
   }

  my $r = @r;

  formatTable(\@r, <<END,
DocType DocType tag of source document
Source  Source input file
Type    Whether the target file represents a bookmap, image or topicTarget
Target  Target file
Title   The title of the target file
END
    title=> q(Source to Target mapping for ).conversion,
    head => <<END,
$files source files mapped to $r target files on DDDD.
END
    summarize=>1,
    file => fpe(reports, qw(lists sourceToTargetMapping txt)));
 }

sub convertSelectedProjects                                                     #P Convert the selected documents by reading their source in L<in|/in>, converting them and writing the resulting topics to L<out|/out>.
 {my @p = sort keys %$projects;                                                 # Projects
  my $p = @p;
  lll "Convert selected projects of numerosity $p with process $$";

  my $ps = newProcessStarter(maximumNumberOfProcesses);                         # Process starter
#     $ps->processingTitle   = q(Convert xml to dita);
#     $ps->totalToBeStarted  = $p;
#     $ps->processingLogFile = fpe(reports, qw(log convertXmlToDita txt));

  for $project(@p)                                                              # Convert projects
   {$ps->start(sub{&convertProject($projects->{$project})});                    # Convert each project in a separate process
   }

  if (my @results = $ps->finish)                                                # Consolidate results
   {reloadHashes(\@results);                                                    # Recreate attribute methods
    my %convert = %$projects;                                                   # Projects to convert
    for my $project(@results)                                                   # Each result
     {my $projectName = $project->name;                                         # Converted project name
      if (my $p = $$projects{$projectName})                                     # Find project
       {$$projects{$projectName} = $project;                                    # Consolidate information gathered
        delete $convert{$projectName};                                          # Mark project as converted
       }
      else                                                                      # Confess to invalid project
       {confess "Unknown converted project $projectName";
       }
     }

    if (my @f = sort keys %convert)                                             # Confess to projects that failed to convert
     {formatTable(
       [map {$convert{$_}->source} @f], [q(), q(Source File)],
        head=>qq(NNNN of $p source files failed to convert on DDDD),
        msg =>1,
        file=>fpe(reports, qw(bad sourceFileConversions txt)));
     }
    else
     {lll "Successfully converted selected projects of numerosity $p";
     }

    reportProjectsThatFailedToParse;                                            # Report projects that failed to parse
    reportSourceMapToTargets;                                                   # Report where each source file went

    for my $project(values %$projects)                                          # Each project definition
     {$project->targets or confess                                              # Check every source file has a target file
       "No target for project from source file:\n".$project->source;
     }
   }
  else
   {eee "No projects selected for conversion";                                  # No projects selected
   }
 }

sub beforeConvertProjects                                                       #r Run just before project conversion starts
 {
 }

sub afterConvertProjects                                                        #r Run just after project conversion starts
 {
 }

sub fixDitaXrefHrefs                                                            #P Fix single word xref href attributes so that they are in dita format - these tend to originate in non dita xml.
 {if (ditaXrefs)                                                                # Fix if requested
   {lll "Convert xref hrefs to Dita format";
    Data::Edit::Xml::Lint::fixDitaXrefHrefs
     (maximumNumberOfProcesses, out, inputExt);
   }
  else
   {ddd "Convert xref hrefs to Dita format not requested";
   }
 }

sub reportProgramAttributeSettings                                              #P Report the attribute settings
 {my $f = fpe(&reports, qw(parameterSettings txt));                             # Report settings file
  reportAttributeSettings($f);                                                  # Report settings
 }

sub reportDownloadExtensions                                                    # Report extensions of downloaded files
 {my $e = countFileExtensions(&downloads);                                      # Count file extensions
  my @e = map {[$$e{$_}, $_]} sort keys %$e;                                    # Sort by extension
  formatTable([@e], <<END,                                                      # Report extensions
Count Number of files with the following extension
Ext   Fike extension
END
     title=>q(Extensions present in downloads folder),
     head=>qq(Found NNNN extensions on DDDD),
     file=>fpe(reports, qw(lists downloadExtensions txt)),
   );
 }

sub convertProjects                                                             #P Convert the selected documents.
 {if (convert)                                                                  # Convert the documents if requested.
   {lll "Convert documents";
    clearFolder($_, clearCount)                                                 # Clear output folders
      for out, parseFailed, process, reports, targets, topicTrees;
    reportProgramAttributeSettings;                                             # Report attribute settings
    reportDownloadExtensions;                                                   # Report extensions of downloaded files
    loadProjects;                                                               # Projects to run
    beforeConvertProjects;
    convertSelectedProjects;                                                    # Convert selected projects
    afterConvertProjects;
    fixDitaXrefHrefs;                                                           # Fix Dita xref href attributes
    Flip::Flop::convert();                                                      # Reset conversion flip flop
    confess "Exiting because we are in stand alone mode" if $standAlone;        # Stop testing at this point to look at results
   }
  else
   {ddd "Convert documents not requested";
   }
 }

sub restructureOutputFiles                                                      #r Restructure output folders based on results from Lint and Xref
 {
 }

sub restructureOneDocument($$$)                                                 #r Restructure one document
 {my ($phase, $lint, $x) = @_;                                                  # Phase, lint results, parse tree
 }

sub restructureOneFile($$)                                                      #P Restructure one output file
 {my ($phase, $file) = @_;                                                      # Phase, file to restructure

  my $lint   = Data::Edit::Xml::Lint::read($file);
  my $x      = Data::Edit::Xml::new($lint->source);
  my $source = $x->ditaPrettyPrintWithHeaders;

  my $result = &restructureOneDocument($phase, $lint, $x);                      # Restructure

  my $Source = $x->ditaPrettyPrintWithHeaders;

  if ($Source ne $source)                                                       # Write out modified source
   {$lint->catalog = &catalog;
    $lint->source  = $Source;
    $lint->lint;
   }

  $result
 }

sub restructureCleanUp($@)                                                      #r Cleanup after each restructuring phase
 {my ($phase, @cleanUps) = @_;                                                  # Phase, cleanup requests
 }

sub restructureResultsFiles                                                     #P Restructure output folders based on results from Lint and Xre
 {my %projects;                                                                 # Details of each file processed
  for my $phase(1..restructurePhases)                                           # Performed specified number of restructuring phases
   {my @files = searchDirectoryTreesForMatchingFiles                            # Reload files on each phase as there might be changes to the file structure given the name of this sub
     (&out, &outExtMap, &outExtTopic);

    my $ps = newProcessStarter(maximumNumberOfProcesses);                       # Process starter
#       $ps->processingTitle   = q(Restructure results);
#       $ps->totalToBeStarted  = scalar @files;
#       $ps->processingLogFile = fpe(reports, qw(log restructure txt));

    for my $file(@files)                                                        # Convert files
     {$ps->start(sub{&restructureOneFile($phase, $file)});                      # Convert each file in a separate process
     }

    my @results = $ps->finish;                                                  # Consolidate results
    restructureCleanUp($phase, @results);                                       # Cleanup after the restructuring
   }
 } # restructureResultsFiles

sub restructureResults                                                          #P Restructure output folders based on results from Lint and Xre
 {my $restructure = sub                                                         # Decode restructure requirements
   {return undef unless restructure;
    return 2 if restructure == 2;
    if ($lintReport)
     {return 1 if $lintReport->totalErrors == 0;
     }
    undef
   }->();

  if ($restructure)                                                             # Restructure if requested
   {lll "Restructure documents";
    restructureResultsFiles;
   }
  elsif (restructure)
   {lll "Restructure results ".restructure."/".
     $lintReport->totalErrors."  suppressed by lint results";
   }
  else
   {ddd "Restructure results not requested";
   }
 }

sub notifyUsers                                                                 #P Notify users of results
 {if (&notify)                                                                  # Convert the documents if requested.
   {ddd "Notify users";
    if ($lintReport)
     {my $pass = $lintReport->passRatePercent;
      my $ffs  = @{$lintReport->failingFiles};
      my $ff   = $ffs ? qq( and $ffs failing files) : q();

      if (notify == 1 && $lintReport->totalErrors == 0 or notify == 2)          # Notify of results if at 100% or all notifications requested
       {GitHub::Crud::createIssueFromSavedToken
         ("philiprbrenan", "notifications",
          conversion." ".version." completed with $pass % success$ff",
          $lintResults. "\n\n".
          q(http://www.ryffine.com));
        lll "Notification sent";
        Flip::Flop::notify();
       }
      else
       {lll "Notify conditions not met", dump(&notify);
       }
     }
    else
     {lll "No lint report for", dump(&notify);
     }
   }
  else
   {lll "Notify not requested", dump(&notify);
   }
 }

sub replaceableMethods                                                          #P Replaceable methods
 {qw(Project
afterConvertProjects
beforeConvertProjects
beforeUploadToS3
bookMapPublicationFolder
checkResults
chooseIDGroup
chooseNameFromString
chooseProjectName
cleanUpBookMap
cleanUpCutOutTopic
convertBookMapToHtml
convertBookMapsToHtml
convertDitaToHtml
convertDocument
convertProject
convertProjects
convertSelectedProjects
convertToUTF8
convertXmlToDita
copyFilesToWeb
copyLogFiles
copyToAws
cutOutTopics
downloadFromS3
fileFromString
findImage
findProjectFromSource
fixDitaXrefHrefs
formatXml
getFromAws
lintResults
lintTopic
loadProjects
normalizeXml
notifyUsers
parseProject
projectCount
relinkDitaRefsInOutputCorpus
relinkDitaRefsInOutputFiles
relintTopic
reportProjectsThatFailedToParse
restructureCleanUp
restructureOutputFiles
restructureOneDocument
restructureOneFile
restructureResults
restructureResultsFiles
runTests
s3ExchangeFolder
s3InputFolder
s3OutputFolder
s3ProfileValue
selectFileForProcessing
spelling
spellingOut
standardDitaCleanUp
testResult
uploadFoldersToS3
uploadToExchange
uploadToS3
)
 }

if (0)                                                                          # Format replaceable methods
 {lll "Replaceable methods in $0\n", join "\n",
   (sort keys %{reportReplacableMethods($0)}),
   '';
  exit;
 }


sub attributeMethods                                                            #P Attribute methods
 {qw(catalog
changeBadXrefToPh
clearCount
client
conversion
convert
debug
deguidize
develop
ditaBin
ditaXrefs
docSet
download
downloads
endTime
errorLogFile
exchange
exchangeHome
exchangeItems
extendedNames
fails
fixBadRefs
fixDitaRefs
fixFailingFiles
fixXrefsByTitle
fixRelocatedRefs
gathered
hits
hitsFolder
home
imageCache
in
inputExt
lint
maximumFileFromStringLength
maximumNumberOfProcesses
mimajen
notify
numberOfFiles
out
outExtMap
outExtTopic
parseCache
parseFailed
perl
printTopicTrees
process
publications
publish
relinkDitaRefs
reports
restructure
restructurePhases
runTime
s3Bucket
s3Exchange
s3FolderIn
s3FolderUp
s3Parms
s3Profile
startTime
summaryFile
targets
testExchangeIn
testExchangeOut
testExpected
testFails
testFails2
testMode
testResults
testStandAlone
tests
titleOnly
topicTrees
unicode
upload
user
version
www
xref
xrefAllowUniquePartialMatches
xrefMatchTopics
)
 }

if (0)                                                                          # Format replaceable attributes
 {lll "Replaceable attributes in $0\n", join "\n",
   (sort keys %{reportAttributes($0)}), '';
  exit;
 }

my $overrideMethods;                                                            # Merge packages only once

sub overrideMethods(;$)                                                         #P Merge packages
 {my ($package) = @_;                                                           # Name of package to be merged defaulting to that of the caller.
  my ($p) = caller();                                                           # Default package if none supplied
  $package //= $p;                                                              # Supply default package if none supplied
  return if $overrideMethods++;                                                 # Merge packages only once
  Data::Table::Text::overrideMethods($package, __PACKAGE__,
    replaceableMethods, attributeMethods);
 }

sub saveCode                                                                    #r Save code if developing
 {if (develop)
   {saveCodeToS3(1200, &perl, client, q(ryffine/code/perl/),
           q(--only-show-errors --profile fmc --region eu-west-1));
   }
 }

sub checkParameters                                                             #P Check parameters for obvious failures
 {my $h = home;
  $h =~ m(\A/.*/\Z)s or confess "home must start and end with / but got: $h";
  $h =~ m(//)s      and confess "home contains // see: $h";
 }

sub convertXmlToDita                                                            #P Perform all the conversion projects.
 {my ($package) = caller;
  lll conversion;                                                               # Title of run

  unlink errorLogFile;                                                          # Clear log

  for my $phase(q(saveCode),                                                    # Execute conversion phases
                q(reportProgramAttributeSettings),
                q(checkParameters),
                q(setAtHits),
                q(downloadFromS3),
                q(convertToUTF8),
                q(convertProjects),
#               q(relinkDitaRefsInOutputCorpus),                                # Now done by Xref using fixDitaRefs=>targets/
                q(lintResults),
                q(restructureOutputFiles),                                      # Deprecated in favor of: restructureResults
                q(restructureResults),
                q(runTests),
                q(copyLogFiles),
                q(copyFilesToWeb),
#               q(uploadToS3),
#               q(uploadToExchange),
                q(uploadResults),
                q(convertDitaToHtml),
                q(notifyUsers))
   {no strict;
    #lll "Phase: ", $phase;
    &{$phase};
   }

  say STDERR $lintResults if $lintReport;                                       # Avoid line number info on helpful statement

  $endTime = time;                                                              # Run time statistics
  $runTime = int($endTime - $startTime);
  lll conversion, "finished in $runTime seconds";                               # Print run time

  $lintReport;                                                                  # Return the lint report
 }

#D0

#-------------------------------------------------------------------------------
# Export - eeee
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();

@EXPORT_OK   = qw(
$projects $project $lintResults $lintReport %fileToTopicId %labelToFile %labelToId
ddd
eee
isAMap
lll
overrideMethods
topicIsEssentiallyEmpty
);

%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation

=pod

=encoding utf-8

=head1 Name

Data::Edit::Xml::To::Dita - Convert multiple Xml documents in parallel to Dita.

=head1 Synopsis

A framework for converting multiple Xml documents in parallel to Dita:

  use Data::Edit::Xml::To::Dita;

  sub convertDocument($$)
   {my ($project, $x) = @_;                   # use sumAbsRel to get default home

    $x->by(sub
     {my ($c) = @_;
      if ($c->at_conbody)
       {$c->putFirst($c->new(<<END));
<p>Hello world!</p>
END
       }
     });
   }

  Data::Edit::Xml::To::Dita::createSampleInputFiles;
  Data::Edit::Xml::To::Dita::convertXmlToDita;

Evaluate the results of the conversion by reading the summary file in the
B<reports/> folder:

  use Data::Table::Text qw(fpe readFile);

  if (lint) # Lint report if available
   {my $s = readFile(&summaryFile);
    $s =~ s(\s+on.*) ()ig;
    my $S = <<END;

  Summary of passing and failing projects

  100 % success. Projects: 0+1=1.  Files: 0+1=1. Errors: 0,0

  CompressedErrorMessagesByCount (at the end of this file):        0

  FailingFiles   :         0
  PassingFiles   :         1

  FailingProjects:         0
  PassingProjects:         1


  FailingProjects:         0
     #  Percent   Pass  Fail  Total  Project
                                               # use sumAbsRel to get default home


  PassingProjects:         1
     #   Files  Project
     1       1  1


  DocumentTypes: 1

  Document  Count
  concept       1


  100 % success. Projects: 0+1=1.  Files: 0+1=1. Errors: 0,0

  END

    ok $s eq $S;
   }

See the converted files in the B<out/> folder:

  if (1) # Converted file
   {my $s = nwsc(readFile(fpe(&out, qw(hello_world dita))));
    my $S = nwsc(<<END);

  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd" []>
  <concept id="c1">
    <title id="title">Hello World</title>
    <conbody>
      <p>Hello world!</p>
    </conbody>
  </concept>
  END

    ok $S eq $s;
   }

=head1 Description

Convert multiple Xml documents in parallel to Dita.


Version 20190620.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Convert Xml to the Dita standard.

Convert Xml to the Dita standard.

=head2 setAtHits()

Set hit tracking


=head2 analyzeHits()

Analyze the hits to find "at" calls that always fail so we can consider them for removal


=head1 Methods

Methods defined in this package.

=head2 ddd(@)

Log development messages

     Parameter  Description
  1  @m         Messages

=head2 eee(@)

Log error messages

     Parameter  Description
  1  @m         Messages

=head2 copyToAws()

Copy to aws


=head2 getFromAws()

Get results from Aws


=head2 mifToXml($)

Convert Mif to Xml

     Parameter   Description
  1  $inputFile  File containing mif

=head2 convertImageToSvg($)

Convert a graphics file to svg

     Parameter  Description
  1  $file      File to convert

=head2 spelling($$)

Fix spelling in source string

     Parameter  Description
  1  $s         Source string
  2  $file      File being processed

B<Example:>


  sub 𝘀𝗽𝗲𝗹𝗹𝗶𝗻𝗴($$)
   {my ($s, $file) = @_;                                                          # Source string, file being processed
    $s
   }


You can provide you own implementation of this method in your calling package
via:

  sub spelling {...}

if you wish to override the default processing supplied by this method.



=head2 spellingOut($)

Fix spelling in output string

     Parameter  Description
  1  $s         Output string

B<Example:>


  sub 𝘀𝗽𝗲𝗹𝗹𝗶𝗻𝗴𝗢𝘂𝘁($)
   {my ($s) = @_;                                                                 # Output string
    $s
   }


You can provide you own implementation of this method in your calling package
via:

  sub spellingOut {...}

if you wish to override the default processing supplied by this method.



=head2 chooseIDGroup($)

Return the id group for a project - files with the same id group share the same set of id attributes.

     Parameter  Description
  1  $project   Project

B<Example:>


  sub 𝗰𝗵𝗼𝗼𝘀𝗲𝗜𝗗𝗚𝗿𝗼𝘂𝗽($)
   {my ($project) = @_;                                                           # Project
    q(all);
   }


You can provide you own implementation of this method in your calling package
via:

  sub chooseIDGroup {...}

if you wish to override the default processing supplied by this method.



=head2 selectFileForProcessing($$)

Select an input file for processing

     Parameter  Description
  1  $file      Full file name
  2  $number    Project number

B<Example:>


  sub 𝘀𝗲𝗹𝗲𝗰𝘁𝗙𝗶𝗹𝗲𝗙𝗼𝗿𝗣𝗿𝗼𝗰𝗲𝘀𝘀𝗶𝗻𝗴($$)
   {my ($file, $number) = @_;                                                     # Full file name, project number
    $file
   }


You can provide you own implementation of this method in your calling package
via:

  sub selectFileForProcessing {...}

if you wish to override the default processing supplied by this method.



=head2 formatXml($)

Format xml

     Parameter  Description
  1  $x         Parse tree

B<Example:>


  sub 𝗳𝗼𝗿𝗺𝗮𝘁𝗫𝗺𝗹($)
   {my ($x) = @_;                                                                 # Parse tree
    $x->prettyStringDitaHeaders;
   }


You can provide you own implementation of this method in your calling package
via:

  sub formatXml {...}

if you wish to override the default processing supplied by this method.



=head2 cleanUpCutOutTopic($$)

Clean up a topic once it has been cut out and its output file has been assigned

     Parameter  Description
  1  $project   Project
  2  $x         Parse

B<Example:>


  sub 𝗰𝗹𝗲𝗮𝗻𝗨𝗽𝗖𝘂𝘁𝗢𝘂𝘁𝗧𝗼𝗽𝗶𝗰($$)
   {my ($project, $x) = @_;                                                       # Project, parse
   }


You can provide you own implementation of this method in your calling package
via:

  sub cleanUpCutOutTopic {...}

if you wish to override the default processing supplied by this method.



=head2 cleanUpBookMap($$)

Clean up a book map once all its topics have been cut out and its output file has been assigned

     Parameter  Description
  1  $project   Project
  2  $x         Parse

B<Example:>


  sub 𝗰𝗹𝗲𝗮𝗻𝗨𝗽𝗕𝗼𝗼𝗸𝗠𝗮𝗽($$)
   {my ($project, $x) = @_;                                                       # Project, parse
   }


You can provide you own implementation of this method in your calling package
via:

  sub cleanUpBookMap {...}

if you wish to override the default processing supplied by this method.



=head2 standardDitaCleanUp($$)

Clean up some items that always need to be done in Dita topics

     Parameter  Description
  1  $project   Project
  2  $x         Parse

B<Example:>


  sub 𝘀𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗗𝗶𝘁𝗮𝗖𝗹𝗲𝗮𝗻𝗨𝗽($$)
   {my ($project, $x) = @_;                                                       # Project, parse
    standardDitaCleanUpDefault($project, $x);                                     # Default standard clean up
   } # 𝘀𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗗𝗶𝘁𝗮𝗖𝗹𝗲𝗮𝗻𝗨𝗽


You can provide you own implementation of this method in your calling package
via:

  sub standardDitaCleanUp {...}

if you wish to override the default processing supplied by this method.



=head2 isAMap($)

Return true if this node is a map

     Parameter  Description
  1  $node      Node to test

=head2 convertDocument($$)

Convert one document.

     Parameter  Description
  1  $project   Project == document to convert
  2  $x         Parse tree.

B<Example:>


  sub 𝗰𝗼𝗻𝘃𝗲𝗿𝘁𝗗𝗼𝗰𝘂𝗺𝗲𝗻𝘁($$)
   {my ($project, $x) = @_;                                                       # Project == document to convert, parse tree.
    lll "𝗰𝗼𝗻𝘃𝗲𝗿𝘁𝗗𝗼𝗰𝘂𝗺𝗲𝗻𝘁: ", $project->source;
    $x->wrapDown_conbody_concept unless couldBeCutOuut($x) or isAMap($x);         # Turn it into a concept if not already a recognizable type
    $x->ditaObviousChanges;
    $x                                                                            # Return parse tree
   }


You can provide you own implementation of this method in your calling package
via:

  sub convertDocument {...}

if you wish to override the default processing supplied by this method.



=head2 lintResults()

Lint results held in folder L<out|/out>and write reports to folder L<reports|/reports>.


B<Example:>


  sub 𝗹𝗶𝗻𝘁𝗥𝗲𝘀𝘂𝗹𝘁𝘀
   {lintResultsDefault;                                                           # Only if lint requested
   }


You can provide you own implementation of this method in your calling package
via:

  sub lintResults {...}

if you wish to override the default processing supplied by this method.



=head2 beforeUploadToS3()

Copy additional files into position before upload to s3


B<Example:>


  sub 𝗯𝗲𝗳𝗼𝗿𝗲𝗨𝗽𝗹𝗼𝗮𝗱𝗧𝗼𝗦𝟯
   {
   }


You can provide you own implementation of this method in your calling package
via:

  sub beforeUploadToS3 {...}

if you wish to override the default processing supplied by this method.



=head2 beforeConvertProjects()

Run just before project conversion starts


B<Example:>


  sub 𝗯𝗲𝗳𝗼𝗿𝗲𝗖𝗼𝗻𝘃𝗲𝗿𝘁𝗣𝗿𝗼𝗷𝗲𝗰𝘁𝘀
   {
   }


You can provide you own implementation of this method in your calling package
via:

  sub beforeConvertProjects {...}

if you wish to override the default processing supplied by this method.



=head2 afterConvertProjects()

Run just after project conversion starts


B<Example:>


  sub 𝗮𝗳𝘁𝗲𝗿𝗖𝗼𝗻𝘃𝗲𝗿𝘁𝗣𝗿𝗼𝗷𝗲𝗰𝘁𝘀
   {
   }


You can provide you own implementation of this method in your calling package
via:

  sub afterConvertProjects {...}

if you wish to override the default processing supplied by this method.



=head2 restructureOutputFiles()

Restructure output folders based on results from Lint and Xref


B<Example:>


  sub 𝗿𝗲𝘀𝘁𝗿𝘂𝗰𝘁𝘂𝗿𝗲𝗢𝘂𝘁𝗽𝘂𝘁𝗙𝗶𝗹𝗲𝘀
   {
   }


You can provide you own implementation of this method in your calling package
via:

  sub restructureOutputFiles {...}

if you wish to override the default processing supplied by this method.



=head2 restructureOneDocument($$$)

Restructure one document

     Parameter  Description
  1  $phase     Phase
  2  $lint      Lint results
  3  $x         Parse tree

B<Example:>


  sub 𝗿𝗲𝘀𝘁𝗿𝘂𝗰𝘁𝘂𝗿𝗲𝗢𝗻𝗲𝗗𝗼𝗰𝘂𝗺𝗲𝗻𝘁($$$)
   {my ($phase, $lint, $x) = @_;                                                  # Phase, lint results, parse tree
   }


You can provide you own implementation of this method in your calling package
via:

  sub restructureOneDocument {...}

if you wish to override the default processing supplied by this method.



=head2 restructureCleanUp($@)

Cleanup after each restructuring phase

     Parameter  Description
  1  $phase     Phase
  2  @cleanUps  Cleanup requests

B<Example:>


  sub 𝗿𝗲𝘀𝘁𝗿𝘂𝗰𝘁𝘂𝗿𝗲𝗖𝗹𝗲𝗮𝗻𝗨𝗽($@)
   {my ($phase, @cleanUps) = @_;                                                  # Phase, cleanup requests
   }


You can provide you own implementation of this method in your calling package
via:

  sub restructureCleanUp {...}

if you wish to override the default processing supplied by this method.



=head2 saveCode()

Save code if developing


B<Example:>


  sub 𝘀𝗮𝘃𝗲𝗖𝗼𝗱𝗲
   {if (develop)
     {saveCodeToS3(1200, &perl, client, q(ryffine/code/perl/),
             q(--only-show-errors --profile fmc --region eu-west-1));
     }
   }


You can provide you own implementation of this method in your calling package
via:

  sub saveCode {...}

if you wish to override the default processing supplied by this method.




=head2 Project Definition


Project definition




=head3 Output fields


B<idGroup> - Projects with the same id group share id attributes.

B<name> - Name of project

B<number> - Number of project

B<parseFailed> - Parse of source file failed

B<source> - Input file

B<targets> - Where the items cut out of this topic wind up

B<test> - Test projects write their results unlinted to testResults



=head1 Attributes


The following is a list of all the attributes in this package.  A method coded
with the same name in your package will over ride the method of the same name
in this package and thus provide your value for the attribute in place of the
default value supplied for this attribute by this package.

=head2 Replaceable Attribute List


catalog clearCount client conversion convert debug deguidize develop ditaBin ditaXrefs docSet download downloads endTime errorLogFile exchange exchangeHome exchangeItems extendedNames fails fixBadRefs fixDitaRefs fixFailingFiles fixXrefsByTitle gathered hits hitsFolder home imageCache in inputExt lint maximumFileFromStringLength maximumNumberOfFilesToClear maximumNumberOfProcesses mimajen notify numberOfFiles out outExtMap outExtTopic parseCache parseFailed perl printTopicTrees process publications publish reports restructure restructurePhases runTime s3Bucket s3Exchange s3FolderIn s3FolderUp s3Parms s3Profile singleTopicBM startTime summaryFile targets testExchangeIn testExchangeOut testExpected testFails testFails2 testMode testResults testStandAlone tests titleOnly topicTrees unicode upload user version www xref xrefAllowUniquePartialMatches


=head2 catalog

Dita catalog to be used for linting.


=head2 clearCount

Limit on number of files to clear from each output folder.


=head2 client

The name of the client


=head2 conversion

Conversion name


=head2 convert

Convert documents to dita if true.


=head2 debug

Debug if true.


=head2 deguidize

0 - normal processing, 1 - replace guids in hrefs with their target files to deguidize dita references. Given href g1#g2/id convert g1 to a file name by locating the topic with topicId g2.


=head2 develop

Production run if this file folder is detected otherwise development.


=head2 ditaBin

Location of Dita tool


=head2 ditaXrefs

Convert xref hrefs expressed as just ids to dita format - useful in non Dita to Dita conversions for example: docBook


=head2 docSet

Select set of documents to convert.


=head2 download

Download from S3 if true.


=head2 downloads

Downloads folder.


=head2 endTime

End time of run in seconds since the epoch.


=head2 errorLogFile

Error log file.


=head2 exchange

1 - upload to S3 Exchange if at 100% lint, 2 - upload to S3 Exchange regardless, 0 - no upload to S3 Exchange.


=head2 exchangeHome

Home of exchange folder


=head2 exchangeItems

The items to be uploaded to the exchange folder: d - downloads, i - in, p - perl, o - out, r - reports


=head2 extendedNames

0 - derive names solely from titles, 1 - consider text beyond the title when constructing file names


=head2 fails

Copies of failing documents in a separate folder to speed up downloading.


=head2 fixBadRefs

Mask bad references using M3: the Monroe Masking Method if true


=head2 fixDitaRefs

Fix references in a corpus of L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> documents that have been converted to the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>.


=head2 fixFailingFiles

Fix failing files in the L<testFails|/testFails> folder if this attribute is true


=head2 fixXrefsByTitle

Fix failing xrefs by looking for the unique topic with a title that matches the text of the xref.


=head2 gathered

Folder containing saved parse trees after initial parse and information gathering - pretty well obsolete


=head2 hits

1 - track hits so we can see which transformations are actually being used - normally off to avoid the overhead


=head2 hitsFolder

Folder containing at method hits by process id


=head2 home

Home folder containing all the other folders.


=head2 imageCache

Converted images are cached here to speed things up


=head2 in

Input documents folder.


=head2 inputExt

Extension of input files.


=head2 lint

Lint output xml


=head2 maximumFileFromStringLength

Maximum amount of title to use in constructing output file names.


=head2 maximumNumberOfFilesToClear

Maximum number of files to clear.


=head2 maximumNumberOfProcesses

Maximum number of conversion processes to run in parallel.


=head2 mimajen

1- Copy files to web, 0 - suppress


=head2 notify

1 - Broadcast results of conversion if at 100% lint, 2 - broadcast regardless of error count.


=head2 numberOfFiles

Expected number of output files


=head2 out

Converted documents output folder.


=head2 outExtMap

Preferred output extension for a map


=head2 outExtTopic

Preferred output extension for a topic


=head2 parseCache

Cached parse trees.


=head2 parseFailed

Folder for details of xml parse failures


=head2 perl

Perl folder.


=head2 printTopicTrees

1 - print the parse tree before cutting out the topics


=head2 process

Process data folder used to communicate results between processes.


=head2 publications

Publications folder on web server for client


=head2 publish

1 - convert Dita to Html and publish via DITA-OT if at 100% lint,  2 - publish regardless


=head2 reports

Reports folder.


=head2 restructure

1 - Restructure results of conversion if at 100% lint, 2 - restructure regardless of error count.


=head2 restructurePhases

Number of restructuring phases to run


=head2 runTime

Elapsed run time in seconds.


=head2 s3Bucket

Bucket on S3 holding documents to convert and the converted results.


=head2 s3Exchange

Exchange folder on S3


=head2 s3FolderIn

Folder on S3 containing original documents.


=head2 s3FolderUp

Folder on S3 containing results of conversion.


=head2 s3Parms

Additional S3 parameters for uploads and downloads.


=head2 s3Profile

Aws cli profile keyword value if any.


=head2 singleTopicBM

1 - allow single topic book maps when cutting out topics which is required if using L<fixDitaRefs>, 0 - multiple topics required for a bookmap


=head2 startTime

Start time of run in seconds since the epoch.


=head2 summaryFile

Summary report file.


=head2 targets

Duplicates the in file structure - each file there-in shows us where the original file went


=head2 testExchangeIn

Exchange folder in which to receive tests so that test writers can disarrange their exchange folders as they please without disrupting testing at this end.


=head2 testExchangeOut

Exchange folder to publish tests results in so test writers can see the results in at L<testResults|/testResults>


=head2 testExpected

Folder containing test results expected.


=head2 testFails

Folder containing failing files to be fixed by reprocessing them but only if fixFailingFiles is true


=head2 testFails2

Folder containing files still unfixed by the current set of fixes


=head2 testMode

1 - run development tests, 2- run standalone tests, 0 run production documents


=head2 testResults

Folder containing actual test results locally, copied to: L<testExchangeOut|/testExchangeOut>


=head2 testStandAlone

Folder containing standalone tests which is used instead of regression tests if content is present


=head2 tests

Folder containing test input files received from test developer at L<testExchangeIn|/testExchangeIn>


=head2 titleOnly

Use only the title of topics to create GB Standard file names otherwise use the following text as well if the title is too short


=head2 topicTrees

Folder to contain printed topic trees if requested by printTopicTrees


=head2 unicode

Convert to utf8 if true.


=head2 upload

Upload to S3 Bucket if true and the conversion is at 100%, 2 - upload to S3 Bucket regardless, 0 - no upload to S3 Bucket.


=head2 user

Aws userid


=head2 version

Description of this run as printed in notification message and title


=head2 www

Web server folder


=head2 xref

Xref output xml.


=head2 xrefAllowUniquePartialMatches

Allow partial matching - i.e ignore the stuff to the right of the # in a reference if doing so produces a unique result




=head1 Optional Replace Methods

The following is a list of all the optionally replaceable methods in this
package.  A method coded with the same name in your package will over ride the
method of the same name in this package providing your preferred processing for
the replaced method in place of the default processing supplied by this
package. If you do not supply such an over riding method, the existing method
in this package will be used instead.

=head2 Replaceable Method List


afterConvertProjects beforeConvertProjects beforeUploadToS3 chooseIDGroup cleanUpBookMap cleanUpCutOutTopic convertDocument formatXml lintResults restructureCleanUp restructureOneDocument restructureOutputFiles saveCode selectFileForProcessing spelling spellingOut standardDitaCleanUp




=head1 Private Methods

=head2 getHome()

Compute home directory once.


=head2 s3ProfileValue()

S3 profile keyword.


=head2 conversionName()

Conversion name.


=head2 s3InputFolder()

S3 input folder


=head2 s3OutputFolder()

S3 output folder


=head2 s3ExchangeFolder()

S3 exchange folder


=head2 pleaseSee($$)

AWS command to see results

     Parameter  Description
  1  $lint      Lint results
  2  $xref      Xref results

=head2 downloadFromS3()

Download documents from S3 to the L<downloads|/downloads> folder.


=head2 convertOneFileToUTF8()

Convert one file to utf8 and return undef if successful else the name of the document in error


=head2 convertToUTF8()

Convert the encoding of documents in L<downloads|/downloads> to utf8 equivalents in folder L<in|/in>.


=head2 projectCount()

Number of projects.


=head2 newProject($)

Project details including at a minimum the name of the project and its source file.

     Parameter  Description
  1  $source    Source file

=head2 findProjectFromSource($)

Locate a project by its source file

     Parameter  Description
  1  $source    Full file name

=head2 loadProjects()

Locate documents to convert from folder L<in|/in>.


=head2 parseCacheFile($)

Name of the file in which to cache parse trees

     Parameter  Description
  1  $project   Project

=head2 parseFile($)

Parse a file

     Parameter  Description
  1  $file      File

=head2 parseProject($)

Parse a project.

     Parameter  Description
  1  $project   Project

=head2 lintTopic($$$)

Lint a topic and return the lint details

     Parameter  Description
  1  $project   Project
  2  $x         Parse tree
  3  $title     Optional title of lint

=head2 lintBookMap($$$$)

Lint a book map

     Parameter  Description
  1  $project   Project
  2  $x         Parse tree of source
  3  $bookMap   Bookmap parse tree
  4  $title     Title of lint

=head2 topicIsEssentiallyEmpty($)

Return B<1> if the topic is essentially empty else B<undef>.

     Parameter  Description
  1  $file      File to check

=head2 findImage($)

Find an image that has been misplaced

     Parameter  Description
  1  $image     Image to locate

=head2 standardDitaCleanUpDefault($$)

Clean up some items that always need to be done in Dita topics

     Parameter  Description
  1  $project   Project
  2  $x         Parse

=head2 couldBeCutOut($)

Return true if this node can be cut out

     Parameter  Description
  1  $node      Node to test

=head2 cutOutTopics($$)

Cut out the topics in a document assuming that they are nested within the parse tree and create a bookmap from the residue if it is not already a bookmap

     Parameter  Description
  1  $project   Project == document to cut
  2  $x         Parse tree.

=head2 convertProject($)

Convert one document held in folder L<in|/in> into topic files held in L<out|/out>.

     Parameter  Description
  1  $project   Project == document to convert

=head2 xrefResults()

Run Xref to fix check results


=head2 lintResultsDefault()

Lint results held in folder L<out|/out>and write reports to folder L<reports|/reports>.


=head2 copyLogFiles()

Copy log files to reports/ so they get uploaded too


=head2 chunkFile($)

Chunk a file name to make it more readable

     Parameter  Description
  1  $file      File to chunk

=head2 copyFilesToWeb2()

Copy files into position so that they can be web served


=head2 copyFilesToWeb()

Copy files into position so that they can be web served


=head2 uploadFoldersToS3()

Upload folders to S3


=head2 uploadToS3()

Copy entire home folder to S3


=head2 uploadToExchange()

Copy entire home folder to Exchange


=head2 bookMapPublicationFolder($)

Folder for html obtained by converting bookmap in supplied file

     Parameter  Description
  1  $bookMap   Bookmap file

=head2 convertBookMapToHtml($)

Publish bookmaps on web server

     Parameter  Description
  1  $bookMap   Bookmap

=head2 convertBookMapsToHtml()

Publish bookmaps on web server


=head2 convertDitaToHtml()

Publish bookmaps on web server


=head2 runTests()

Run tests by comparing files in folder L<out|/out> with corresponding files in L<testResults|/testResults>.


=head2 normalizeXml($)

Remove document processor tags

     Parameter  Description
  1  $string    Text to normalize

=head2 testResult($$$)

Evaluate the results of a test

     Parameter  Description
  1  $test      Test name
  2  $got       What we got
  3  $expected  What we expected result

=head2 checkResults()

Check test results


=head2 reportProjectsThatFailedToParse()

Report projects that failed to parse


=head2 reportSourceMapToTargets()

Report where the source files went


=head2 convertSelectedProjects()

Convert the selected documents by reading their source in L<in|/in>, converting them and writing the resulting topics to L<out|/out>.


=head2 fixDitaXrefHrefs()

Fix single word xref href attributes so that they are in dita format - these tend to originate in non dita xml.


=head2 reportProgramAttributeSettings()

Report the attribute settings


=head2 convertProjects()

Convert the selected documents.


=head2 restructureOneFile($$)

Restructure one output file

     Parameter  Description
  1  $phase     Phase
  2  $file      File to restructure

=head2 restructureResultsFiles()

Restructure output folders based on results from Lint and Xre


=head2 restructureResults()

Restructure output folders based on results from Lint and Xre


=head2 notifyUsers()

Notify users of results


=head2 replaceableMethods()

Replaceable methods


=head2 attributeMethods()

Attribute methods


=head2 overrideMethods($)

Merge packages

     Parameter  Description
  1  $package   Name of package to be merged defaulting to that of the caller.

=head2 checkParameters()

Check parameters for obvious failures


=head2 convertXmlToDita()

Perform all the conversion projects.



=head1 Index


1 L<afterConvertProjects|/afterConvertProjects> - Run just after project conversion starts

2 L<analyzeHits|/analyzeHits> - Analyze the hits to find "at" calls that always fail so we can consider them for removal

3 L<attributeMethods|/attributeMethods> - Attribute methods

4 L<beforeConvertProjects|/beforeConvertProjects> - Run just before project conversion starts

5 L<beforeUploadToS3|/beforeUploadToS3> - Copy additional files into position before upload to s3

6 L<bookMapPublicationFolder|/bookMapPublicationFolder> - Folder for html obtained by converting bookmap in supplied file

7 L<checkParameters|/checkParameters> - Check parameters for obvious failures

8 L<checkResults|/checkResults> - Check test results

9 L<chooseIDGroup|/chooseIDGroup> - Return the id group for a project - files with the same id group share the same set of id attributes.

10 L<chunkFile|/chunkFile> - Chunk a file name to make it more readable

11 L<cleanUpBookMap|/cleanUpBookMap> - Clean up a book map once all its topics have been cut out and its output file has been assigned

12 L<cleanUpCutOutTopic|/cleanUpCutOutTopic> - Clean up a topic once it has been cut out and its output file has been assigned

13 L<conversionName|/conversionName> - Conversion name.

14 L<convertBookMapsToHtml|/convertBookMapsToHtml> - Publish bookmaps on web server

15 L<convertBookMapToHtml|/convertBookMapToHtml> - Publish bookmaps on web server

16 L<convertDitaToHtml|/convertDitaToHtml> - Publish bookmaps on web server

17 L<convertDocument|/convertDocument> - Convert one document.

18 L<convertImageToSvg|/convertImageToSvg> - Convert a graphics file to svg

19 L<convertOneFileToUTF8|/convertOneFileToUTF8> - Convert one file to utf8 and return undef if successful else the name of the document in error

20 L<convertProject|/convertProject> - Convert one document held in folder L<in|/in> into topic files held in L<out|/out>.

21 L<convertProjects|/convertProjects> - Convert the selected documents.

22 L<convertSelectedProjects|/convertSelectedProjects> - Convert the selected documents by reading their source in L<in|/in>, converting them and writing the resulting topics to L<out|/out>.

23 L<convertToUTF8|/convertToUTF8> - Convert the encoding of documents in L<downloads|/downloads> to utf8 equivalents in folder L<in|/in>.

24 L<convertXmlToDita|/convertXmlToDita> - Perform all the conversion projects.

25 L<copyFilesToWeb|/copyFilesToWeb> - Copy files into position so that they can be web served

26 L<copyFilesToWeb2|/copyFilesToWeb2> - Copy files into position so that they can be web served

27 L<copyLogFiles|/copyLogFiles> - Copy log files to reports/ so they get uploaded too

28 L<copyToAws|/copyToAws> - Copy to aws

29 L<couldBeCutOut|/couldBeCutOut> - Return true if this node can be cut out

30 L<cutOutTopics|/cutOutTopics> - Cut out the topics in a document assuming that they are nested within the parse tree and create a bookmap from the residue if it is not already a bookmap

31 L<ddd|/ddd> - Log development messages

32 L<downloadFromS3|/downloadFromS3> - Download documents from S3 to the L<downloads|/downloads> folder.

33 L<eee|/eee> - Log error messages

34 L<findImage|/findImage> - Find an image that has been misplaced

35 L<findProjectFromSource|/findProjectFromSource> - Locate a project by its source file

36 L<fixDitaXrefHrefs|/fixDitaXrefHrefs> - Fix single word xref href attributes so that they are in dita format - these tend to originate in non dita xml.

37 L<formatXml|/formatXml> - Format xml

38 L<getFromAws|/getFromAws> - Get results from Aws

39 L<getHome|/getHome> - Compute home directory once.

40 L<isAMap|/isAMap> - Return true if this node is a map

41 L<lintBookMap|/lintBookMap> - Lint a book map

42 L<lintResults|/lintResults> - Lint results held in folder L<out|/out>and write reports to folder L<reports|/reports>.

43 L<lintResultsDefault|/lintResultsDefault> - Lint results held in folder L<out|/out>and write reports to folder L<reports|/reports>.

44 L<lintTopic|/lintTopic> - Lint a topic and return the lint details

45 L<loadProjects|/loadProjects> - Locate documents to convert from folder L<in|/in>.

46 L<mifToXml|/mifToXml> - Convert Mif to Xml

47 L<newProject|/newProject> - Project details including at a minimum the name of the project and its source file.

48 L<normalizeXml|/normalizeXml> - Remove document processor tags

49 L<notifyUsers|/notifyUsers> - Notify users of results

50 L<overrideMethods|/overrideMethods> - Merge packages

51 L<parseCacheFile|/parseCacheFile> - Name of the file in which to cache parse trees

52 L<parseFile|/parseFile> - Parse a file

53 L<parseProject|/parseProject> - Parse a project.

54 L<pleaseSee|/pleaseSee> - AWS command to see results

55 L<projectCount|/projectCount> - Number of projects.

56 L<replaceableMethods|/replaceableMethods> - Replaceable methods

57 L<reportProgramAttributeSettings|/reportProgramAttributeSettings> - Report the attribute settings

58 L<reportProjectsThatFailedToParse|/reportProjectsThatFailedToParse> - Report projects that failed to parse

59 L<reportSourceMapToTargets|/reportSourceMapToTargets> - Report where the source files went

60 L<restructureCleanUp|/restructureCleanUp> - Cleanup after each restructuring phase

61 L<restructureOneDocument|/restructureOneDocument> - Restructure one document

62 L<restructureOneFile|/restructureOneFile> - Restructure one output file

63 L<restructureOutputFiles|/restructureOutputFiles> - Restructure output folders based on results from Lint and Xref

64 L<restructureResults|/restructureResults> - Restructure output folders based on results from Lint and Xre

65 L<restructureResultsFiles|/restructureResultsFiles> - Restructure output folders based on results from Lint and Xre

66 L<runTests|/runTests> - Run tests by comparing files in folder L<out|/out> with corresponding files in L<testResults|/testResults>.

67 L<s3ExchangeFolder|/s3ExchangeFolder> - S3 exchange folder

68 L<s3InputFolder|/s3InputFolder> - S3 input folder

69 L<s3OutputFolder|/s3OutputFolder> - S3 output folder

70 L<s3ProfileValue|/s3ProfileValue> - S3 profile keyword.

71 L<saveCode|/saveCode> - Save code if developing

72 L<selectFileForProcessing|/selectFileForProcessing> - Select an input file for processing

73 L<setAtHits|/setAtHits> - Set hit tracking

74 L<spelling|/spelling> - Fix spelling in source string

75 L<spellingOut|/spellingOut> - Fix spelling in output string

76 L<standardDitaCleanUp|/standardDitaCleanUp> - Clean up some items that always need to be done in Dita topics

77 L<standardDitaCleanUpDefault|/standardDitaCleanUpDefault> - Clean up some items that always need to be done in Dita topics

78 L<testResult|/testResult> - Evaluate the results of a test

79 L<topicIsEssentiallyEmpty|/topicIsEssentiallyEmpty> - Return B<1> if the topic is essentially empty else B<undef>.

80 L<uploadFoldersToS3|/uploadFoldersToS3> - Upload folders to S3

81 L<uploadToExchange|/uploadToExchange> - Copy entire home folder to Exchange

82 L<uploadToS3|/uploadToS3> - Copy entire home folder to S3

83 L<xrefResults|/xrefResults> - Run Xref to fix check results

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Data::Edit::Xml::To::DitaVb

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2019 Philip R Brenan.

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
qx(perl /home/phil/perl/cpan/DataEditXmlToDita/test.pl);
