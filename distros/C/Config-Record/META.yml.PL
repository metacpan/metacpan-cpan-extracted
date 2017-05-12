# Copyright (C) 2001-2007 Daniel Berrange <dan@berrange.com>

use strict;
use warnings;

die unless (scalar @ARGV == 1);

unless (do "lib/Config/Record.pm")
  {
    if ($@) { die $@ }
    die "lib/Config/Record.pm: $!"
  }

local $/ = undef;
$_ = <DATA>;
s/\@VERSION\@/$Config::Record::VERSION/g;

open YML, ">$ARGV[0]" or die "$!";
print YML $_;
close YML;
__DATA__
--- #YAML:1.0
name:         Config-Record
abstract:     Configuration file access
version:      @VERSION@
author:
  - Daniel P. Berrange <dan@berrange.com>
license: gpl
generated_by: ExtUtils::MakeMaker version 6.30
requires:
   Carp:                          0
   IO::File:                      0
build_requires:
   Test::More:                    0
   File::Temp:                    0
   Test::Pod:                     0
   Test::Pod::Coverage:           0

resources:
  license: http://www.gnu.org/licenses/gpl.html
  homepage: http://autobuild.org/
  bugtracker: https://gna.org/bugs/?group=testautobuild
  repository: https://gna.org/cvs/?group=testautobuild
  MailingList: https://gna.org/mail/?group=testautobuild

distribution_type: module

meta-spec:
   version: 1.3
   url: http://module-build.sourceforge.net/META-spec-v1.3.html
