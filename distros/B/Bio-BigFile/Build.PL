#!/usr/bin/perl

use strict;
use Module::Build;

my $HeaderFile = "bigWig.h";
my $LibFile    = "jkweb.a";
my $ReadLine;

my ($jk_include,$jk_lib) = find_jk(); # may exit with error here

my $build = Module::Build->new(
    module_name        => 'Bio::BigFile',
    dist_version_from  => 'lib/Bio/DB/BigFile.pm',
    dist_author        => 'Lincoln Stein <lincoln.stein@gmail.com>',
    dist_abstract      => "Manipulate Jim Kent's BigWig and BigBed index files for genomic features.",
    license            => 'perl',
    include_dirs       => [$jk_include],
    extra_linker_flags => ["$jk_lib/$LibFile",'-lz','-lssl'],

    extra_compiler_flags=>[
	# turn off warnings originating in Perl's Newx* calls
	'-Wno-format',
	'-Wformat=0',
	"-DMACHTYPE_$ENV{MACHTYPE}"
    ],

    build_requires => {
      'ExtUtils::CBuilder' => 0,
    },
    requires     => {
	'perl'                => '5.008',
	'IO::String'          => 0,
	'Bio::Root::Version'  => '1.005009001',
    },
    recommends => {
	'LWP'      => 0,
	'URI::URL' => 0,
    }
#    create_makefile_pl => 'passthrough',
    );

$build->create_build_script;

exit 0;

sub find_jk {
    my ($jk_include,$jk_lib);

    if (my $jksrc = $ENV{KENT_SRC}) {
	$jk_include = "$jksrc/inc"
	    if -e "$jksrc/inc/$HeaderFile";
	$jk_lib     = "$jksrc/lib/$ENV{MACHTYPE}"
	    if -e "$jksrc/lib/$ENV{MACHTYPE}/$LibFile";
    }

    unless ($jk_include && $jk_lib) {
	print STDERR <<END;

This module requires the compiled jkweb.a library from Jim Kent's source tree.
If you haven't already done so, please download the source from
http://hgdownload.cse.ucsc.edu/admin/jksrc.zip, unpack it, and build the
contents of the "kent/src/lib" subdirectory as directed in the README. Then
enter the location of the "kent/src" subdirectory at the prompt below. To prevent
this message from appearing in the future, set the environment variable KENT_SRC 
to point to the "kent/src" subdirectory.

END
	my $prompt = "Please enter the location of Kent source tree: ";
	my $found;
	while (!$found) {
	    my $path = prompt($prompt);
	    print STDERR "\n";
	    last unless $path;
	    $jk_include = "$path/inc"
		if -e "$path/inc/$HeaderFile";
	    $jk_lib = "$path/lib/$ENV{MACHTYPE}"
		if -e "$path/lib/$ENV{MACHTYPE}/$LibFile";
	    $found = $jk_include && $jk_lib;
	    unless ($found) {
		print STDERR "Can't find the $HeaderFile and $LibFile files at this location.\n";
		$prompt = "Try again, or hit <enter> to cancel: ";
	    }
	}
    }
    return ($jk_include,$jk_lib);
}


sub prompt {
    my $msg = shift;

    unless (defined $ReadLine) {
	eval "require Term::ReadLine";
	$ReadLine   = Term::ReadLine->can('new') || 0;
	$ReadLine &&= Term::ReadLine->new(\*STDOUT);
	eval {readline::rl_set('TcshCompleteMode','On')};
    }

    
    unless ($ReadLine) {
	print STDOUT $msg;
	chomp (my $in = <>);
	return $in;
    }

    my $in = $ReadLine->readline($msg);
    chomp $in;
    $in=~ s/\s+//;
    $ReadLine->addhistory($in) if $in =~ /\S/;
    return $in;
}
