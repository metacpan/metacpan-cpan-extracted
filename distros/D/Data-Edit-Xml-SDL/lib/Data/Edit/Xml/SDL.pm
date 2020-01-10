#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I/home/phil/perl/cpan/DataEditXmlSDL/lib/
#-------------------------------------------------------------------------------
# Create SDL file map from a set of linted xml files
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2016
#-------------------------------------------------------------------------------
# podDocumentation

package Data::Edit::Xml::SDL;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Edit::Xml::Lint;
use Data::Table::Text qw(:all);
our $VERSION = 20200109;

#1 Constructor                                                                  # Construct a new SDL file map creator

sub new                                                                         # Create a new SDL file map creator - call this method statically as in Data::Edit::Xml::Lint::new()
 {bless {sdlVersion=>'13.0.0.0', language=>(qq(en-US))}                         # Defaults that can be easily overridden
 }

#2 Attributes                                                                   # Attributes describing a lint

genLValueScalarMethods(qw(filePathFolder));                                     # Prefix this folder (if supplied) to the filepath
genLValueScalarMethods(qw(fileType));                                           # The fileType of the file to be processed
genLValueScalarMethods(qw(filesFlattened));                                     # Files have been flattened if true
genLValueScalarMethods(qw(folderHasMixedContent));                              # folderHasMixedContent field
genLValueScalarMethods(qw(ishType));                                            # IshType field
genLValueScalarMethods(qw(imagePath));                                          # Image path relative to sourcebasepath
genLValueScalarMethods(qw(language));                                           # The language of the content, defaults to: 'en-US'
genLValueScalarMethods(qw(lint));                                               # The lint of the file to be processed
genLValueScalarMethods(qw(sdlVersion));                                         # Version of SDL we are using, defaults to: '12.0.0.0'
genLValueScalarMethods(qw(section));                                            # Sub folder for file on SDL: maps, topics
genLValueScalarMethods(qw(sourcebasepath));                                     # Path to source to be uploaded
genLValueScalarMethods(qw(targetFolder));                                       # Input: The SDL target folder to be used in the filemap - the person doing the upload will give this to you.
genLValueScalarMethods(qw(version));                                            # Version of the input content

#1 SDL File Map                                                                 # Generate an SDL file map

sub xmlLineOne                                                                  #P Line one of all xml files
 {'<?xml version="1.0" encoding="utf-8"?>'."\n"
 }

sub getFileMap                                                                  #P File map tag
 {my ($sdl) = @_;                                                               # Sdl file map creator
  my $s = $sdl->sourcebasepath;
  my $v = $sdl->sdlVersion;
  <<END
 <filemap sourcebasepath="$s" version="$v">;
END
 }

sub getFile($)                                                                  #P File tag
 {my ($sdl) = @_;                                                               # Sdl file map creator
  my $targetFolder   = $sdl->targetFolder;
  my $ishType        = $sdl->ishType;
  my $section        = $sdl->section;
  my $imagePath      = $sdl->imagePath;
  my $lint           = $sdl->lint;
  my $project        = $lint->project;
  my $guid           = $lint->guid;
  my $file           = $lint->file;
  my $title          = $lint->title || 'REQUIRED-CLEANUP-TITLE';
  my $mixed          = ucfirst $sdl->folderHasMixedContent;
     $mixed =~ m/\A(True|False)\Z/s or
       confess "FolderhasMixedContent = (True|False) not $mixed";
  my $filePrefix = $lint->project;                                              # File name prefix if any

  my (undef, $fileName, $fileExt) = parseFileName($file);                       # Parse file name
  $fileExt or confess "No file extension for ".$file;
# my $relFile = filePathExt($filePrefix, $fileName, $fileExt);
  my $relFile = filePathExt($fileName, $fileExt);  ## Fully flattened
  return <<END unless $sdl->filesFlattened;
<file fileextension=".$fileExt" filename="$fileName.$fileExt" filepath="$filePrefix\\$fileName.$fileExt" filetype="$ishType" folderhasmixedcontent="$mixed" id="$guid" targetfolder="$targetFolder\\$project\\$section" title="$title">
END

  return <<END;
<file fileextension=".$fileExt" filename="$fileName.$fileExt" filepath="$fileName.$fileExt" filetype="$ishType" folderhasmixedcontent="$mixed" id="$guid" targetfolder="$targetFolder\\$project\\$section" title="$title">
END
 }

sub getImageFile($)                                                             #P Image file tag
 {my ($sdl, $file) = @_;                                                        # Sdl file map creator, image file name
  my $targetFolder = $sdl->targetFolder;
  my $ishType      = $sdl->ishType;
  my $section      = $sdl->section;
  my $imagePath    = $sdl->imagePath;
  my $project      = "images";
  my $guid         = guidFromMd5(fn $file);
  my $mixed        = ucfirst $sdl->folderHasMixedContent;
     $mixed =~ m/\A(True|False)\Z/s or
       confess "FolderhasMixedContent = (True|False) not $mixed";

  my $filePrefix = filePathDir($imagePath);                                     # The image file prefix if we are processing an image

  my (undef, $fileName, $fileExt) = parseFileName($file);                       # Parse file name
# my $relFile = filePathExt($filePrefix, $fileName, $fileExt);
  my $relFile = filePathExt($fileName, $fileExt); ## Fully flattened
  my $r = <<END;
<file fileextension=".$fileExt" filename="$relFile" filepath="$relFile" filetype="$ishType" folderhasmixedcontent="$mixed" id="$guid" targetfolder="$targetFolder\\$section" title="$fileName">
END
  $r
 }

sub getIshObject                                                                #P IshObject tag
 {my ($sdl) = @_;                                                               # Sdl
  my $ishType = $sdl->ishType;
  my $lint    = $sdl->lint;
  my $guid    = $lint->guid;
     $guid or confess "No guid supplied";
  <<END
<ishobject ishref="$guid" ishtype="$ishType">
END
 }

sub getImageIshObject($$)                                                       #P IshObject tag for an image
 {my ($sdl, $file) = @_;                                                        # Sdl, image file
  my $ishType = $sdl->ishType;
  my $lint    = $sdl->lint;
  my $guid    = fn $file;
  <<END
<ishobject ishref="$guid" ishtype="$ishType">
END
 }

sub getFTitle($;$)                                                              #P FTITLE tag
 {my ($sdl, $imageFile) = @_;                                                   # Sdl, image file name which might have an image title following the md5 sum
  my $lint  = $sdl->lint;                                                       # Lint
  my $Title = $lint->title;                                                     # Title

  if ($imageFile)                                                               # Image files some times have their titles after the md5 sum
   {my $i = $imageFile.q(.imageDef);
    if (-e $i)
     {$Title = readFile($i);
     }
   }

# warn "No title in\n".dump($lint)."\n" unless $Title;
  my $title = $Title || 'REQUIRED-CLEANUP-TITLE';
  <<END
<ishfield level="logical" name="FTITLE" xml:space="preserve">$title</ishfield>
END
 }

sub getVersion                                                                  #P Version tag
 {my ($sdl) = @_;                                                               # Sdl
  my $v = $sdl->sdlVersion;
  <<END
<ishfield level="version" name="VERSION" xml:space="preserve">$v</ishfield>
END
 }

sub getDocLanguage                                                              #P DOC-LANGUAGE tag
 {my ($sdl) = @_;                                                               # Sdl
  my $l = $sdl->language;
  <<END
<ishfield level="lng" name="DOC-LANGUAGE" xml:space="preserve">$l</ishfield>
END
 }

sub getAuthor                                                                   #P Author tag
 {my ($sdl) = @_;                                                               # Sdl
  my $lint  = $sdl->lint;
  my $a     = sub
   {my $a = $lint->author;
    return $a if $a;
    "bill.gearhart";
   }->();

  <<END
<ishfield name="FAUTHOR" level="lng" xml:space="preserve">$a</ishfield>
END
 }

sub getResolution                                                               #P Resolution
 {my ($sdl) = @_;                                                               # Sdl
  <<END
<ishfield level="lng" name="FRESOLUTION" xml:space="preserve">High</ishfield>
END
 }

sub createSDLFileMap($@)                                                        # Generate an SDL file map for a selected set of files
 {my ($sdl, @foldersAndExtensions) = @_;                                        # Sdl, Directory tree search specification

  my @files = searchDirectoryTreesForMatchingFiles(@foldersAndExtensions);      # Find matching files

  my @map = (xmlLineOne, $sdl->getFileMap);                                     # The generated map

  for my $file(@files)                                                          # Each file contributing to the map
   {next if $file =~ m(\.imageDef\Z)s;                                          # Image definition files
    my $lint = Data::Edit::Xml::Lint::read($file);                              # Linter for the file
    $sdl->lint = $lint;

    my $ditaType = sub
     {return $lint->ditaType if $lint->ditaType;
      return q(bookmap) if fe($file) =~ m(ditamap)is;
      return q(image)   if fe($file) =~ m((emf|gif|png|jpg|jpeg|pdf|tiff))is;
      return q(image)   if fe($file) =~ m(imageDef);                            # File has been guidized the corresponding imageDef file tells us its original name
      undef;
     }->();

    $ditaType or confess "DitaType required for file:\n$file";

    if ($ditaType =~ m/map/i)
     {$sdl->ishType = (qq(ISHMasterDoc));
      $sdl->section = (qq(maps));
      $sdl->folderHasMixedContent = (qq(true));
      push @map,
        $sdl->getFile,
        $sdl->getIshObject, <<END,
<ishfields>
END
        $sdl->getFTitle,
        $sdl->getVersion,
        $sdl->getDocLanguage,
        $sdl->getAuthor,
        <<END,
</ishfields>
</ishobject>
</file>
END
     }

    elsif ($ditaType =~ m/concept|reference|task|troubleShooting/i)
     {$sdl->ishType = (qq(ISHModule));
      $sdl->section = (qq(topics));
      $sdl->folderHasMixedContent = (qq(true));
      push @map,
        $sdl->getFile,
        $sdl->getIshObject, <<END,
<ishfields>
END
        $sdl->getFTitle,
        $sdl->getVersion,
        $sdl->getDocLanguage,
        $sdl->getAuthor,
        <<END,
</ishfields>
</ishobject>
</file>
END
     }

    elsif ($ditaType  =~ m/image/i)
     {$sdl->ishType   = qq(ISHIllustration);
      $sdl->section   = qq(images);
      $sdl->imagePath = qq(images);
      $sdl->folderHasMixedContent = qq(false);
      push @map,
        $sdl->getImageFile($file),
        $sdl->getImageIshObject($file), <<END,
<ishfields>
END
        $sdl->getFTitle($file),
        $sdl->getVersion,
        $sdl->getDocLanguage,
        $sdl->getResolution,
        q(image), #$sdl->getAuthor,
        <<END,
</ishfields>
</ishobject>
</file>
END
     }
    else {confess "Unrecognized ditaType $ditaType"}
   }
  my $T = dateTimeStamp;
  push @map, <<END;
 </filemap>
<!--Created: $T -->
END
  join "", @map;
 } # createSDLFileMap

# podDocumentation

=pod

=encoding utf-8

=head1 Name

Data::Edit::Xml::SDL - Create SDL file map from a set of linted xml files
produced by L<Data::Edit::Xml::Lint>

=head1 Synopsis

Create an SDL file map from a set of linted xml files produced by
L<Data::Edit::Xml::Lint>

 my $s = Data::Edit::Xml::SDL::new();
    $s->sourcebasepath = 'C:\frame\batch1\out';
    $s->targetFolder   = qq(RyffineImportSGIfm);
    $s->imagePath      = qq(images);
    $s->version = 1;

 say STDERR $s->createSDLFileMap(qw(. xml));

Produces:

 <?xml version="1.0" encoding="utf-8"?>
 <filemap sourcebasepath="C:\hp\frame\batch1\out" version="12.0.0.0">;
   <file fileextension=".ditamap" >
     <ishobject ishref="GUID-D7147C7F-2017-0012-FRMB-000000000002" ishtype="ISHMasterDoc">
       <ishfields>
      <ishfield level="logical" name="FTITLE" xml:space="preserve">bm_0003388-002</ishfield>'
      <ishfield level="version" name="VERSION" xml:space="preserve">1</ishfield>
      <ishfield level="lng" name="DOC-LANGUAGE" xml:space="preserve">en-US</ishfield>
      <ishfield name="FAUTHOR" level="lng" xml:space="preserve">bill.gearhart@hpe.com</ishfield>
     </ishfields>
   </ishobject>
 </file>

etc.

=head1 Description

=head2 Constructor

Construct a new SDL file map creator

=head3 new()

Create a new SDL file map creator - call this method statically as in Data::Edit::Xml::Lint::new()


=head3 Attributes

Attributes describing a lint

=head4 filePathFolder :lvalue

Prefix this folder (if supplied) to the filepath


=head4 fileType :lvalue

The fileType of the file to be processed


=head4 folderHasMixedContent :lvalue

folderHasMixedContent field


=head4 ishType :lvalue

IshType field


=head4 imagePath :lvalue

Image path relative to sourcebasepath


=head4 language :lvalue

The language of the content, defaults to: 'en-US'


=head4 lint :lvalue

The lint of the file to be processed


=head4 sdlVersion :lvalue

Version of SDL we are using, defaults to: '12.0.0.0'


=head4 section :lvalue

Sub folder for file on SDL: maps, topics


=head4 sourcebasepath :lvalue

Path to source to be uploaded


=head4 targetFolder :lvalue

The SDL target folder to be used


=head4 version :lvalue

Version of the input content


=head2 SDL File Map

Generate an SDL file map

=head3 createSDLFileMap($@)

Generate an SDL file map for a selected set of files

  1  $sdl                   Sdl
  2  @foldersAndExtensions  Directory tree search specification


=head1 Private Methods

=head2 xmlLineOne()

Line one of all xml files


=head2 getFileMap()

File map tag


=head2 getFile($$)

File tag

  1  $sdl     Sdl file map creator
  2  $images  Processing an image file or not

=head2 getIshObject()

IshObject tag


=head2 getFTitle()

FTITLE tag


=head2 getVersion()

Version tag


=head2 getDocLanguage()

DOC-LANGUAGE tag


=head2 getAuthor()

Author tag


=head2 getResolution()

Resolution



=head1 Index


L<createSDLFileMap|/createSDLFileMap>

L<filePathFolder|/filePathFolder>

L<fileType|/fileType>

L<folderHasMixedContent|/folderHasMixedContent>

L<getAuthor|/getAuthor>

L<getDocLanguage|/getDocLanguage>

L<getFile|/getFile>

L<getFileMap|/getFileMap>

L<getFTitle|/getFTitle>

L<getIshObject|/getIshObject>

L<getResolution|/getResolution>

L<getVersion|/getVersion>

L<imagePath|/imagePath>

L<ishType|/ishType>

L<language|/language>

L<lint|/lint>

L<new|/new>

L<sdlVersion|/sdlVersion>

L<section|/section>

L<sourcebasepath|/sourcebasepath>

L<targetFolder|/targetFolder>

L<version|/version>

L<xmlLineOne|/xmlLineOne>

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

=cut


# Tests and documentation

sub test
 {my $p = __PACKAGE__;
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
use warnings FATAL=>qw(all);
use strict;
use Test::More tests=>3;

my $pwd    = currentDirectory;
my $out    = filePathDir($pwd, qq(out));
my @filesWritten;
my @search = ($out, qw(xml dita ditamap));                                      # Search for files to process with this specification

#Test::More->builder->output("/dev/null");                                      # Show only errors during testing - but this must be commented out for production

my $s = new();

$s->sourcebasepath = 'C:\hp\frame\batch1\out';
$s->targetFolder   = qq(RyffineImportSGIfm);
$s->version        = 1;

sub writeTest($$$)
 {my ($file, $ext, $source) = @_;
  my $path = filePathExt($out, $file, $ext);
  push @filesWritten, $path;
  writeFile($path, $source);
 }

unlink for searchDirectoryTreesForMatchingFiles(@search);                       # Confirm removal
&writeTest(qw(bookmap ditamap), &testBookMap);
&writeTest(qw(concept1 dita),   &testConcept);
&writeTest(qw(GUID-11112222-3333-4444-5555-666677778888_image1.jpg imageDef),
           &testImage);

my $t = $s->createSDLFileMap(@search);                                          # Create file map
   $t =~ s/\n<!--Created.*?\Z//s;                                               # Remove date

ok $t eq &expectedOutput;

unlink for @filesWritten;                                                       # Remove test files
ok !scalar(searchDirectoryTreesForMatchingFiles(@search));                      # Confirm removal

rmdir $out;                                                                     # Remove test folder
ok !-d $out;                                                                    # Confirm removal

sub testBookMap {<<END}
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE bookmap PUBLIC "-//HPE//DTD HPE DITA BookMap//EN" "bookmap.dtd">
<bookmap/>
<!--generated: 2017-Jul-26 -->
<!--ditaType: bookmap -->
<!--project: 007-6301-001 -->
<!--projectNumber: 1 -->
<!--tags: 313 -->
<!--file:
bm_007-6301-001.ditamap
-->
<!--guid: GUID-D7147C7F-2017-0001-FRMB-000000000001 -->
<!--author: bill.gearhart\@hpe.com -->
<!--title: Title of the bookmap goes here -->
END

sub testConcept {<<END}
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//HPE//DTD HPE DITA Concept//EN" "concept.dtd">
<concept/>
<!--generated: 2017-Jul-26 -->
<!--ditaType: concept -->
<!--project: 007-6301-001 -->
<!--projectNumber: 1 -->
<!--tags: 313 -->
<!--file:
concept1.dita
-->
<!--guid: GUID-D7147C7F-2017-0001-FRMB-000000000002 -->
<!--author: bill.gearhart\@hpe.com -->
<!--title: Test Concept One -->
END

sub testImage {<<END}
TestImage.png
END

sub expectedOutput{<<'END'}
<?xml version="1.0" encoding="utf-8"?>
 <filemap sourcebasepath="C:\hp\frame\batch1\out" version="13.0.0.0">;
<file fileextension=".ditamap" filename="bookmap.ditamap" filepath="007-6301-001\bookmap.ditamap" filetype="ISHMasterDoc" folderhasmixedcontent="True" id="GUID-D7147C7F-2017-0001-FRMB-000000000001" targetfolder="RyffineImportSGIfm\007-6301-001\maps" title="Title of the bookmap goes here">
<ishobject ishref="GUID-D7147C7F-2017-0001-FRMB-000000000001" ishtype="ISHMasterDoc">
<ishfields>
<ishfield level="logical" name="FTITLE" xml:space="preserve">Title of the bookmap goes here</ishfield>
<ishfield level="version" name="VERSION" xml:space="preserve">13.0.0.0</ishfield>
<ishfield level="lng" name="DOC-LANGUAGE" xml:space="preserve">en-US</ishfield>
<ishfield name="FAUTHOR" level="lng" xml:space="preserve">bill.gearhart@hpe.com</ishfield>
</ishfields>
</ishobject>
</file>
<file fileextension=".dita" filename="concept1.dita" filepath="007-6301-001\concept1.dita" filetype="ISHModule" folderhasmixedcontent="True" id="GUID-D7147C7F-2017-0001-FRMB-000000000002" targetfolder="RyffineImportSGIfm\007-6301-001\topics" title="Test Concept One">
<ishobject ishref="GUID-D7147C7F-2017-0001-FRMB-000000000002" ishtype="ISHModule">
<ishfields>
<ishfield level="logical" name="FTITLE" xml:space="preserve">Test Concept One</ishfield>
<ishfield level="version" name="VERSION" xml:space="preserve">13.0.0.0</ishfield>
<ishfield level="lng" name="DOC-LANGUAGE" xml:space="preserve">en-US</ishfield>
<ishfield name="FAUTHOR" level="lng" xml:space="preserve">bill.gearhart@hpe.com</ishfield>
</ishfields>
</ishobject>
</file>
 </filemap>
END
