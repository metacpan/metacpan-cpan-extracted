#!/usr/bin/perl
# -I/home/phil/z/perl/cpan/DataTableText/lib
#-------------------------------------------------------------------------------
# Zip some files to Amazon S3
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2016
#-------------------------------------------------------------------------------
# podDocumentation

package Data::Save::S3;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Table::Text qw(:all);
our $VERSION = 20170801;

#1 Zip and Send to S3                                                           # Zip the named files into one folder, zip the folder and send it to AWS S3

sub new                                                                         # New zipper
 {bless {}
 }

genLValueArrayMethods (qw(files));                                              # Array of files to zip and send to S3
genLValueScalarMethods(qw(profile));                                            # Optional aws profile to use on the --profile keyword of the aws s3 command
genLValueScalarMethods(qw(s3));                                                 # Bucket/folder on S3 into which to upload the zip file, without the initial s3:// or trailing the zip file name
genLValueScalarMethods(qw(zip));                                                # The short name of the zip file minus the zip extension and path

sub send($)                                                                     # Zip and send files to S3.
 {my ($zip) = @_;                                                               # Zipper

  unless(my $missing = &checkEnv)                                               # Check that the necessary commands are installed
   {confess "Ensure that 'zip' and 'aws' commands are installed";
   }

  my $z = $zip->zip;                                                            # Short zip name

  my $tmp = filePathDir(qw(zip), $z);                                           # Create a folder into which we can make temporary copies of the files to process
  makePath($tmp);                                                               # Make a path to the  zip folder

  unlink("zip/$z.zip");                                                         # Unlink any existing zip file

  for my $file(@{$zip->files})                                                  # Copy files to temporary folder
   {my ($F, $f, $e) = parseFileName($file);
    my $source = $file;
    -e $source or confess "File does not exist:\n$source";
    my $target = filePathExt($tmp, $f, $e);
    copy($source, $target) or confess "Copy failed: $!";
   }

  my $s3 = $zip->s3;                                                            # Position on S3
  my $profile = $zip->profile // '';                                            # Profile keyword
     $profile = "--profile $profile" if $profile;

  xxx("cd zip && zip -mqrT $z $z");                                             # Zip temporary files
  xxx("aws s3 cp zip/$z.zip s3://$s3/$z.zip $profile");                         # Send to AWS
 }

sub checkEnv                                                                    ## Check environment
 {return "zip "    if qx(zip 2>&1) !~ m/Usage:/;                                # Zip is not installed
  return "aws cli" if qx(aws --version 2>&1) !~ m/aws-cli:/;                    # aws cli is not installed
  undef
 }

# Tests and documentation

sub test{eval join('', <Data::Save::S3::DATA>) or die $@} test unless caller;   # Test

1;

# podDocumentation

=pod

=encoding utf-8

=head1 Name

Data::Save::S3 - Zip some files to Amazon S3

=head1 Synopsis

If you have installed the zip command and L<aws-cli|http://docs.aws.amazon.com/cli/latest/userguide/awscli-install-bundle.html> then:

 use Data::Save::S3;

 my $z   = Data::Save::S3::new;
 $z->zip = qq(latestCode);
 $z->add = [filePathExt(currentDirectory, qw(test c)))];
 $z->s3  = qq(bucket/folder);
 $z->send;

produces:

 cd zip && zip -mqrT DataSaveS3 DataSaveS3
 aws s3 cp zip/DataSaveS3.zip s3://AppaAppsSourceVersions/DataSaveS3.zip
 Completed 1.8 KiB/1.8 KiB (296 Bytes/s) with 1 file(s) remaining
 upload: zip/DataSaveS3.zip to s3://AppaAppsSourceVersions/DataSaveS3.zip

=head1 Description

=cut

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
 {diag("No file to upload");
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
 }

ok 1;
