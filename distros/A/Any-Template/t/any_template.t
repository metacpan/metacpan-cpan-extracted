#!/usr/local/bin/perl

###############################################################################
# Purpose : Unit test for Any::Template
# Author  : John Alden
# Created : Dec 04
# CVS     : $Header: /home/cvs/software/cvsroot/any_template/t/any_template.t,v 1.7 2006/05/08 12:28:00 mattheww Exp $
###############################################################################
#
# -t Trace
# -T Deep trace
# -s save output
#
###############################################################################

use strict;
BEGIN{ unshift @INC, "../lib" };
use Test::Assertions qw(test);
use Log::Trace;
use Getopt::Std;
use File::Spec;
use File::Path;

use vars qw($opt_t $opt_T $opt_s);
getopts("tTs");

#List of possible backends and template files for them
my %files = (
	'HTML::Template'  => 'html_template.tmpl',
	'Text::Template'  => 'text_template.tmpl',
	'IFL::Template'   => 'ifl_template.tmpl',
	'TemplateToolkit' => 'template_toolkit.tmpl',
	'Text::MicroMason' => 'text_micromason.tmpl',
);

my %modules = (
	'TemplateToolkit' => 'Template',
);


# Only run tests for the backend modules installed on this system and a test template in distribution 
my @backends = grep {
	my $module = $modules{$_} || $_;
	eval "require $module";
	not ( $@ || ! -e $files{$_} );
} keys %files;

plan tests => 3 + 11*scalar @backends;

#Move into the t directory
chdir($1) if($0 =~ /(.*)(\/|\\)(.*)/);

#Compilation
require Any::Template;
ASSERT($INC{'Any/Template.pm'}, "Compiled Any::Template version $Any::Template::VERSION");

#Log::Trace
import Log::Trace qw(print) if($opt_t);
deep_import Log::Trace qw(print) if($opt_T);

#Check list of available backends
#(i.e. that the ones we are about to run tests on are all listed)
my $possible_backends = Any::Template::available_backends();
my %possible = map {$_ => 1} @$possible_backends;
ASSERT(
	(scalar grep {$possible{$_}} @backends) == (scalar @backends),
	"available_backends"
);

#Check for mandatory backend
ASSERT(DIED(sub { new Any::Template() }), "Check for backend");

my $outdir = "output";
my $output;
my $capture = sub {$output .= shift()};

#Clean slate for file output
rmtree($outdir);
mkdir($outdir);

#Run tests on each of the backends
for my $backend(@backends)
{
	my $obj = new Any::Template({
		Backend => $backend,
		Filename => $files{$backend}
	});

	ASSERT(ref $obj eq 'Any::Template', "Constructor using $backend");
	deep_import Log::Trace qw(print) if($opt_T);

	#String output
	$output = $obj->process({x => 4321});
	TRACE($output);
	ASSERT($output eq "Label: 4321", "$backend - string output");

	#File output
	my $output_file = File::Spec->catfile($outdir, $files{$backend});
	$obj->process({x => 1234}, $output_file);
	ASSERT(EQUALS_FILE("Label: 1234", $output_file), "$backend - file output");
	unlink($output_file);

	#Filehandle output	
	open(OUT, ">$output_file") or die("Unable to open output file $output_file - $!");
	$obj->process({x => 1234}, *OUT);
	close OUT;
	ASSERT(EQUALS_FILE("Label: 1234", $output_file), "$backend - filehandle output");
	unlink($output_file);
	
	#Filehandle ref output	
	open(OUT, ">$output_file") or die("Unable to open output file $output_file - $!");
	$obj->process({x => 1234}, \*OUT);
	close OUT;
	ASSERT(EQUALS_FILE("Label: 1234", $output_file), "$backend - filehandle ref output");

	#Coderef output
	$output = "";
	$obj->process({x => 2323}, $capture);
	TRACE($output);
	ASSERT($output eq "Label: 2323", "$backend - code output");

	#String input
	undef $obj;
	$obj = new Any::Template({
		Backend => $backend,
		String => READ_FILE($files{$backend})
	});
	$output = $obj->process({x => 1359});
	TRACE($output);
	ASSERT($output eq "Label: 1359", "$backend - string input");
	
	#Filehandle input
	local *FH;
	open(FH, $files{$backend}) or die("Unable to open ".$files{$backend});
	$obj = new Any::Template({
		Backend => $backend,
		Filehandle => \*FH
	});
	$output = $obj->process({x => 5678});
	TRACE($output);
	ASSERT($output eq "Label: 5678", "$backend - filehandle input");	
	close FH;

	#Raise error for no input type
	ASSERT(DIED(sub { new Any::Template({
		Backend => $backend,
	}) }) && scalar $@ =~ /You must supply/, "No source");
	
	#Raise error for no data
	ASSERT(DIED(sub { 
		$obj->process();
	}) && scalar $@ =~ /You must supply a data structure/, "No data");
	ASSERT(DIED(sub { 
		$obj->process("a string");
	}) && scalar $@ =~ /should be a reference/, "Data not a reference");	
}

#Cleanup
rmtree($outdir) unless($opt_s);
