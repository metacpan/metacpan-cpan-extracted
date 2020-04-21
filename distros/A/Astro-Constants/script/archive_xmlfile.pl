#!/usr/bin/perl -w
#
# Archive the PhysicalConstants.xml file in data/old_versions
# Boyd Duffee, July 2017
#
# TODO
# - use relative paths to run script from anywhere

use strict;
use autodie;
use 5.010;
use XML::LibXML;
use Digest::MD5;
use File::Copy;

my $file = $ARGV[0] || 'data/PhysicalConstants.xml';
die "Can't file $file (run from the top directory)" unless -f $file;
my $archive_dir = join '/', qw/data old_versions/;

my $xml = XML::LibXML->load_xml(location => $file, no_blanks => 1);

my $version = $xml->getElementsByTagName('version');
my $standard = $xml->getElementsByTagName('reference_standard');
my $year = (localtime)[5] + 1900;

print "My version is $version for the $standard standard\n";
my $archive_name = join '_', 'constants', $year, $version;
my $extension = '.xml';

my $save_file = join '/', $archive_dir, "$archive_name$extension";
if (-e $save_file) {
	print "File $save_file exists.  Renaming\n";
	my @versions = glob("$archive_dir/$archive_name*");
	my $last_version = pop @versions;
	if ( check_same_files($file, $last_version) ) {
		say "File already archived as $save_file  Exiting";
		exit;
	}
	my $n = 2;
	if ( $last_version =~ /$extension\.(\d+)$/ ) {
		$save_file = join '.', $save_file, ($1 + 1);
	}
	else {
		$save_file .= '.1';
	}
}

copy( $file, $save_file );
say "$file archived as $save_file";

exit;

sub check_same_files {
	my ($didi, $gogo) = @_;
	return checksum($didi) eq checksum($gogo);
}

sub checksum {
	my $filename = shift;
	open (my $fh, '<', $filename) or die "Can't open '$filename': $!";
	binmode ($fh);

	say "Checking $filename";
	return Digest::MD5->new->addfile($fh)->hexdigest;
}
