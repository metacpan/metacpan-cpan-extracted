# Makefile.PL for DBD::cubrid
# Copyright (C) 2008 Search Solution Corporation. All rights reserved by Search Solution.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# - Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
#
# - Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# - Neither the name of the <ORGANIZATION> nor the names of its contributors
#   may be used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
# OF SUCH DAMAGE.
#

use 5.008;
use ExtUtils::MakeMaker;
use Config;
use strict;
use File::Spec;
require DBI::DBD;

my $os = $^O;
my $sep;

if ($os =~ /^MSWin32$/i) {
    $sep = "\\";
} else {
    $sep = "/";
}

my $CUBRID_INCLUDE;
my $CUBRID_INCLUDE_BASE;
my $CUBRID_INCLUDE_BROKER;
my $CUBRID_INCLUDE_CCI;
my $CUBRID_LIB;
my $CUBRID_LIB_EX;
my $dbi_arch_dir;

my $volume;
my $directory;
my $file;
my $abs_path = File::Spec->rel2abs($0);
($volume, $directory, $file) = File::Spec->splitpath($abs_path);
my $script_path = File::Spec->catpath($volume, $directory);


if ($os =~ /^MSWin32$/i) {
    $CUBRID_INCLUDE = $ENV{CUBRID} . $sep . "include";
		$CUBRID_LIB = $ENV{CUBRID} . $sep . "lib";
} elsif ($os =~ /^linux$/i) {
    $CUBRID_INCLUDE_BASE = File::Spec->catpath("", $script_path,  "cci-src/src/base");
    $CUBRID_INCLUDE_CCI = File::Spec->catpath("", $script_path,  "cci-src/src/cci");
    $CUBRID_INCLUDE_BROKER = File::Spec->catpath("", $script_path,  "cci-src/src/broker");

    my $arch_type = "";
    if ($Config{longsize} == 8) {
           $arch_type = "x64"; 
    } else {
        $arch_type = "x86";
    }
    system('chmod +x build_cci.sh');
    system('./build_cci.sh',$arch_type);
    
    $CUBRID_LIB = File::Spec->catpath("", $script_path, "cci-src/cci/.libs");
    
} else {
    $CUBRID_INCLUDE_CCI = $ENV{CUBRID} . $sep . "include";
    $CUBRID_LIB = $ENV{CUBRID} . $sep . "lib";
}

$dbi_arch_dir = DBI::DBD::dbd_dbi_arch_dir();
eval {require_version DBI 1.61;};
if ($@) {
    warn $@;
    print "Please install DBI version 1.61 or higher. Exit.\n";
    exit 1;
}

my $libs;
my $incflags;
my $myextlib;
my $lddlflags;
my %opts; 
if ($os =~ /^MSWin32$/i) {
	  %opts = (
		    'NAME'          => 'DBD::cubrid',
		    'VERSION_FROM'  => 'cubrid.pm',
		    'INC'           => "-I$CUBRID_INCLUDE -I$dbi_arch_dir",
		    'LIBS'          => ["-L$CUBRID_LIB -lcascci"],
		    'AUTHOR'        => 'Zhang Hui',
		    'ABSTRACT'      => 'CUBRID database driver for the DBI module',
		    'dist'          => { 'SUFFIX'   => '.gz',
		                         'COMPRESS' => 'gzip -9f' },
		    'clean'         => { 'FILES' => '*.xsi' },
		    'PREREQ_PM'     => { DBI => '1.61' },
		    'OBJECT'        => '$(O_FILES)',
		    'LINKTYPE'      => 'dynamic',		    
		);
} else {
	  $libs = "-lpthread -lstdc++";
	  if($ARGV[0] eq "daily")
	  {
	  	$incflags ="-fprofile-arcs -ftest-coverage -I$CUBRID_INCLUDE_CCI -I$CUBRID_INCLUDE_BROKER -I$CUBRID_INCLUDE_BASE -I$dbi_arch_dir";
	  }
	  else
	  {
	  	$incflags ="-I$CUBRID_INCLUDE_CCI -I$CUBRID_INCLUDE_BROKER -I$CUBRID_INCLUDE_BASE -I$dbi_arch_dir";
	  }    
    $myextlib = $CUBRID_LIB . $sep ."libcascci" . '$(LIB_EXT)';
    $lddlflags = "";


		%opts = (
		    'NAME'          => 'DBD::cubrid',
		    'VERSION_FROM'  => 'cubrid.pm',
		    'INC'           => $incflags,
		    'LIBS'          => ["$libs"],
		    'AUTHOR'        => 'Zhang Hui',
		    'ABSTRACT'      => 'CUBRID database driver for the DBI module',
		    'dist'          => { 'SUFFIX'   => '.gz',
		                         'COMPRESS' => 'gzip -9f' },
		    'clean'         => { 'FILES' => '*.xsi' },
		    'PREREQ_PM'     => { DBI => '1.61' },
		    'OBJECT'        => '$(O_FILES)',
		    'LINKTYPE'      => 'dynamic',
		    'MYEXTLIB'      => $myextlib,		    
		    'LDDLFLAGS'     => $lddlflags,
		);
}
WriteMakefile(%opts);

package MY;

sub postamble {
    return DBI::DBD::dbd_postamble (@_);
}

sub libscan {
    my ($self, $path) = @_;
    ($path =~ m/\~$/) ? undef : $path;
}
