#!/usr/bin/perl -w
use strict;

our $VERSION = "0.020";

warn <<GPL unless -f 'Makefile';
----------------------------------------------------------------
Audio::LADSPA v$VERSION
A collection of perl modules for interfacing with LADSPA plugins
Copyright (C) 2003 - 2007 Joost Diepenmaat.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

See the COPYING file for more information.
----------------------------------------------------------------
GPL
use ExtUtils::MakeMaker;
use Config;


$ENV{LADSPA_PATH} ||= "/usr/local/lib/ladspa:/usr/lib/ladspa";


my $found = 0;
for (split/:/,$ENV{LADSPA_PATH}) {
    if (-f "$_/delay.$Config{so}") {
        $found = 1;
        last;
    }
}

unless ($found) {
	my $continue = prompt(
qq(the ladspa_sdk plugin "delay.$Config{so}" cannot be found in
LADSPA_PATH: "$ENV{LADSPA_PATH}"

The tests specifically need the plugins from the ladspa_sdk
package, with the LADSPA_PATH environment variable pointing 
to the directory where they are installed.

Please correct your LADSPA_PATH and/or download and  install
the SDK from from http://www.ladspa.org/

If you want, you can proceed without the ladspa_sdk package
installed, but most of the tests will  be skipped.

Do you want to proceed? y/n),"y");
    if ($continue !~ /^y/i) {
        exit;
    }
}

my $play_audio = 1;
if (! eval { require Audio::Play; } ) {
    $play_audio = prompt(
"No Audio::Play module was found on your system. Without it, 
we can't do audio output. If you want to test audio output,
answer yes to the following question. Audio::Play will then 
be added to the required module list. This means it will be
installed automatically if you're using the CPAN / CPANPLUS
modules.

Do you want to test audio output (requires Audio::Play)? y/n","n");
}
$play_audio = $play_audio =~ /^y/i ? 1 : 0;

WriteMakefile(
    'NAME'		=> 'Audio::LADSPA',
    'VERSION_FROM'	=> 'LADSPA.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	'Test::More' => 0, 
    'Class::Publisher' => 0,
    ( $play_audio ?	('Audio::Play' => 1.000, 'Audio::Data' => 1.000) : ()),
	'Graph' => 0.5,         # NEW interface for graph
	'Scalar::Util' => 0, 
	'Data::Uniqid' => 0,
    }, # e.g., Module::Name => 1.i
    
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
       (AUTHOR     => 'Joost Diepenmaat <jdiepen AT cpan.org>') : ()),
    'EXE_FILES'		=> ['eg/pluginfo'],
    'OPTIMIZE'		=> '-O',
);

