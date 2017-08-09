#!/usr/bin/perl
# -I/home/phil/z/perl/cpan/DataTableText/lib
#-------------------------------------------------------------------------------
# Zip some files to Amazon S3
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------
# podDocumentation

package Data::Save::S3;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Table::Text qw(:all);
our $VERSION = 20170809;

#1 Zip and Send to S3                                                           # L<Copy|http://perldoc.perl.org/File/Copy.html/> the named files into one folder, B<zip> the folder and send the zip archive to L<S3|https://console.aws.amazon.com/s3/home/>

sub new                                                                         # New zipper.
 {bless {}
 }

genLValueArrayMethods (qw(files));                                              # Array of files to zip and send to L<S3|https://console.aws.amazon.com/s3/home/>
genLValueScalarMethods(qw(folder));                                             # Folder in which to build the zip file - defaults to B<zip/>
genLValueScalarMethods(qw(profile));                                            # Optional L<aws-cli|http://docs.aws.amazon.com/cli/latest/userguide/awscli-install-bundle.html> profile to use.
genLValueScalarMethods(qw(s3));                                                 # Bucket/folder on L<S3|https://console.aws.amazon.com/s3/home/> into which to upload the zip file, without the leading s3:// or trailing zip file name.
genLValueScalarMethods(qw(zip));                                                # The short name of the zip file minus the zip extension and path.

sub send($)                                                                     # Zip and send files to L<S3|https://console.aws.amazon.com/s3/home/>
 {my ($zip) = @_;                                                               # Zipper

  unless(my $missing = &checkEnv)                                               # Check that the necessary commands are installed
   {confess "Ensure that 'zip' and 'aws' commands are installed";
   }

  my $d = $zip->folder // qq(zip);                                              # Folder in which to create zip file
  my $z = $zip->zip;                                                            # Short zip name
  my $Z = filePathExt($d, $z, qw(zip));                                         # Long  zip file name

  my $folder = filePathDir($d, $z);                                             # Create a folder into which we can make temporary copies of the files to process
  makePath($folder);                                                            # Make a path to the  zip folder

  unlink($Z);                                                                   # Unlink any existing zip file

  for my $file(@{$zip->files})                                                  # Copy files to temporary folder
   {my ($F, $f, $e) = parseFileName($file);
    my $source = $file;
    -e $source or confess "File does not exist:\n$source";
    my $target = filePathExt($folder, $f, $e);
    copy($source, $target) or confess "Copy failed: $!";
   }

  my $s3 = $zip->s3;                                                            # Position on S3
  my $profile = $zip->profile // '';                                            # Profile keyword
     $profile = "--profile $profile" if $profile;

  xxx("cd $d && zip -mqrT $z $z");                                              # Zip temporary files
  xxx("aws s3 cp $d/$z.zip s3://$s3/$z.zip $profile");                          # Send to AWS
 }

sub clean($)                                                                    # Remove local copy.
 {my ($zip) = @_;                                                               # Zipper
  my $d = $zip->folder // qq(zip);                                              # Folder in which to create zip file
  my $z = $zip->zip;                                                            # Short zip name
  my $Z = filePathExt($d, $z, qw(zip));                                         # Long  zip file name

  my $folder = filePathDir($d, $z);                                             # Create a folder into which we can make temporary copies of the files to process
  unlink($Z);                                                                   # Unlink local zip file
  rmdir $d;                                                                     # Remove zip folder if empty
 }

sub checkEnv                                                                    #P Check environment.
 {return "zip "    if qx(zip 2>&1) !~ m/Usage:/;                                # Zip is not installed
  return "aws cli" if qx(aws --version 2>&1) !~ m/aws-cli:/;                    # aws cli is not installed
  undef
 }

# podDocumentation

=pod

=encoding utf-8

=head1 Name

Data::Save::S3 - Zip some files to L<S3|https://console.aws.amazon.com/s3/home/>

=head1 Synopsis

The specified L<files|/files> are L<copied|http://perldoc.perl.org/File/Copy.html> into a sub
L<folder|/folder>/L<zip|/zip>, then moved into a zip file
L<folder|/folder>/L<zip|/zip>B<.zip> and uploaded to L<S3|/s3> using
L<aws-cli|http://docs.aws.amazon.com/cli/latest/userguide/awscli-install-bundle.html>
optionally using a specified L<profile|/profile>.

At the end of the process a zipped copy of the files will exist in the local
file: L<folder|/folder>/L<zip|/zip>B<.zip> and in the L<S3 bucket|/s3>. If you
do not want to keep the locally zipped copy call method L<clean|/clean> to
L<unlink|http://perldoc.perl.org/functions/unlink.html/> it and
L<remove|http://perldoc.perl.org/functions/rmdir.html> the containing
L<folder|/folder> if it is empty.

=head2 Required software

You should install the B<zip> command and
L<aws-cli|http://docs.aws.amazon.com/cli/latest/userguide/awscli-install-bundle.html>
before using this module.

=head2 Example

 use Data::Save::S3;

 my $z   = Data::Save::S3::new;
 $z->zip = qq(DataSaveS3);
 $z->add = [filePathExt(currentDirectory, qw(test c)))];
 $z->s3  = qq(AppaAppsSourceVersions);
 $z->send;

produces:

 cd zip && zip -mqrT DataSaveS3 DataSaveS3
 aws s3 cp zip/DataSaveS3.zip s3://AppaAppsSourceVersions/DataSaveS3.zip
 Completed 1.8 KiB/1.8 KiB (296 Bytes/s) with 1 file(s) remaining
 upload: zip/DataSaveS3.zip to s3://AppaAppsSourceVersions/DataSaveS3.zip

=head1 Description

=head2 Zip and Send to S3

L<Copy|http://perldoc.perl.org/File/Copy.html/> the named files into one folder, B<zip> the folder and send the zip archive to L<S3|https://console.aws.amazon.com/s3/home/>

=head3 new

New zipper.


=head3 files :lvalue

Array of files to zip and send to L<S3|https://console.aws.amazon.com/s3/home/>


=head3 folder :lvalue

Folder in which to build the zip file - defaults to B<zip/>


=head3 profile :lvalue

Optional L<aws-cli|http://docs.aws.amazon.com/cli/latest/userguide/awscli-install-bundle.html> profile to use.


=head3 s3 :lvalue

Bucket/folder on L<S3|https://console.aws.amazon.com/s3/home/> into which to upload the zip file, without the leading s3:// or trailing zip file name.


=head3 zip :lvalue

The short name of the zip file minus the zip extension and path.


=head3 send

Zip and send files to L<S3|https://console.aws.amazon.com/s3/home/>

  1  $zip  Zipper  

=head3 clean

Remove local copy.

  1  $zip  Zipper  

=head3 checkEnv

Check environment.


This is a private method.



=head1 Index


L<checkEnv|/checkEnv>

L<clean|/clean>

L<files|/files>

L<folder|/folder>

L<new|/new>

L<profile|/profile>

L<s3|/s3>

L<send|/send>

L<zip|/zip>

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
use File::Copy;
use Test::More tests=>1;
use Data::Table::Text qw(:all);

#Test::More->builder->output("/dev/null");                                      # Show only errors during testing - but this must be commented out for production
my $n = Test::More->builder->expected_tests;

my $f = filePathExt(currentDirectory, qw(S3 pm));                               # File to upload

unless (-e $f)                                                                  # Check that we have a file to upload
 {diag("No file to upload:\n$f");
  ok 1 for 1..$n;
  exit 0
 }

unless (my $missing = checkEnv)                                                 # Skip tests if components are missing
 {diag("$missing not installed - skipping all tests");
  ok 1 for 1..$n;
  exit 0
 }

if (1)
 {my $z     = Data::Save::S3::new;
  $z->zip   = qq(DataSaveS3);
  $z->files = [$f, $f];
  $z->s3    = qq(AppaAppsSourceVersions);
  $z->send;
  $z->clean;
 }

ok 1;
