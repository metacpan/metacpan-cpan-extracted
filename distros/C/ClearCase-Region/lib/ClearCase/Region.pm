#!/usr/local/bin/perl -w

package Region;

$VERSION = 1.01;

use strict;
use vars qw($region_name @region_subregions %byproj $logger);
use Carp;
use Log::Log4perl;
use ClearCase::Region_Cfg_Parser;

BEGIN {

	#*************************************************************************
	# Initialize variables
	#*************************************************************************
	my(@regions			) = ();
	my($k				) = "";
	my(%subregion		) = ();
	my($conf_file		) = "";
	my($subregion_ref	) = {};
	my($platform		) = "";

	$logger = Log::Log4perl->get_logger("Region");

	if (defined $^O) {
		if ($^O eq "MSWin32") {
			$platform = "MSWin32";
		}
		else {
			$platform = "Unix";
		}
	}
	else {
		$platform = "MSWin32";
	}

	#*************************************************************************
	# Determine the region that is being used
	#*************************************************************************
	if ($platform eq "Unix") {
		$conf_file = "/var/adm/atria/rgy/rgy_region.conf";
		open(INFILE, "< $conf_file")
			or $logger->error("Bad Open on $conf_file for reading: $!\n");
		# put contents of conf_file into an array
		@regions = <INFILE>;
		close(INFILE);
	
		chomp(@regions);
		$region_name = $regions[0];
	}
	else {
		require Win32::Registry;
		
		my($p				) = "";
		my($key				) = "";
		my($CurrentVersion	) = "";
		my($dummyvar		) = "";
		my(%vals			) = ();
		
		#
		#	Using variables from Registry.pm to prevent warning messages
		#
		$dummyvar = $main::HKEY_CLASSES_ROOT;
		$dummyvar = $main::HKEY_CURRENT_USER;
		$dummyvar = $main::HKEY_USERS;
		$dummyvar = $main::HKEY_PERFORMANCE_DATA;
		$dummyvar = $main::HKEY_CURRENT_CONFIG;
		$dummyvar = $main::HKEY_DYN_DATA;
		$Win32::Registry::pack = "";
		$Win32::WinError::pack = "";

		$p = "SOFTWARE\\Atria\\ClearCase\\CurrentVersion";
		$main::HKEY_LOCAL_MACHINE->Open($p, $CurrentVersion) || 
			die "Open: $!";
		$CurrentVersion->GetValues(\%vals); # get values -hash ref
		foreach $k (keys %vals) {
			$key = $vals{$k};
			if ($$key[0] eq "InteropRegion") {
				$region_name = $$key[2];
				chomp($region_name);
				last;
			}
		}
	}

	#*************************************************************************
	# Store region info in hashes
	#*************************************************************************
	$subregion_ref = ClearCase::Region_Cfg_Parser->new($region_name);
	%subregion = %$subregion_ref;
	@region_subregions	= keys %subregion;
	foreach $k (keys %subregion) {
		$byproj{$k} = $subregion{$k};
	}

}		# End of BEGIN

###############################################################################
#	Class Methods
###############################################################################
sub name
{
	return($region_name);
}

sub subregions
{
	return(@region_subregions);
}

sub vobs
{
	use strict;

	my($self	) = shift;
	my($subregion	) = $_[0];

	return @{$byproj{$subregion}->{'vobs'}};
}

###############################################################################
#	Class Methods	- get subregion for a given vob name.
###############################################################################
#
#	For a given Vob, find the corresponding subregion in the region.
#
#	Exit with an error if no subregion is found.
#	Return subregion if exactly one subregion is located for the given vob
#	name.	Prompt for correct subregion if the vob name is found in
#	more than one subregion.
#
sub get_subregion_for_vob
{
	my($self		) = shift;
	my($vobname		) = $_[0];
	my($subregion	) = "";
	my($vob			) = "";
	my($cnt			) = 0;
	my($i			) = 0;
	my($j			) = 0;
	my(@vobs		) = ();
	my(@subs		) = ();
	my(@subregions	) = Region->subregions();
	my($validinput	) = 0;
	my($inline		) = "";
	my($desc		) = "";

	foreach $subregion (@subregions) {
		@vobs = Region->vobs($subregion);
		foreach $vob (@vobs) {
			if ($vobname eq $vob) {
				$subs[$cnt] = $subregion;
				$cnt++;
			}
		}
	}

	if ($cnt == 0) {
		$logger->error("Error:  no subregion found for $vobname - check Region.cfg\n");
		exit 1;
	}
	elsif ($cnt == 1) {
		return($subs[0]);
	}
	else {
		while ($validinput == 0) {
	
			$i = 0;
			$logger->info("Please select the subregion for VOB $vobname:\n");
			for ($i = 0 ; $i < $cnt ; $i++) {
				$desc = $byproj{$subs[$i]}->{'description'};
				$j = $i + 1;
				$logger->info("   $j)  $subs[$i] - ${desc}\n");
			}
			$logger->info("\nEnter 1, 2, ... $i): ");
	
			$inline = <STDIN>;
			chomp($inline);			# vital or the test includes the newline.
	
			#	Check if user entered a number
			if ($inline =~ /\D/) {
				$logger->warn("Invalid input:  $inline  ... try again\n");
				next;
			}
	
			#	Check that input number was between 1 and $i
			if ($inline <= 0 || $inline > $i) {
				$logger->warn("Invalid input:  $inline  ... try again\n");
				next;
			}
	
			return($subs[int($inline)-1]);
		}
	}
}

###############################################################################
#	Set the Region attributes
#		_name
#		_subregion
#		_description
#		_vobdir
#
###############################################################################
sub ask_region
{
	use strict;

	my($validinput	) = 0;
	my($inline		) = "";
	my($askcorrect	) = "";
	my($i			) = 0;
	my($subregion	) = "";
	my($vob			) = "";
	my($vobstr		) = "";
	my(@vobs		) = ();
	my(@outarr		) = ();
	my(@subregions	) = ();
	my(@descriptions) = ();
	my(@vobdir		) = ();
	my($desc		) = "";
	my($vob_dir		) = "";

	croak("Private method, Region->ask_region(), cannot be called directly")
		unless caller->isa("Region");
	while ($validinput == 0) {

		$i = 0;
		$logger->info("Please select project:\n");
		foreach $subregion (keys %byproj) {
			$vob_dir = $byproj{$subregion}->{'vobdir'};
			$desc = $byproj{$subregion}->{'description'};
			@vobs = @{$byproj{$subregion}->{'vobs'}};
			$vobstr = join(" ", @vobs);
			$subregions[$i] = $subregion;
			$descriptions[$i] = $desc;
			$vobdir[$i] = $vob_dir;
			$i += 1;
			$logger->info("   $i)  ${desc} uses $vobstr with project id = \"${subregion}\"\n");
		}
		$logger->info("\nEnter 1, 2, ... $i): ");

		$inline = <STDIN>;
		chomp($inline);			# vital or the test includes the newline.

		#	Check if user entered a number
		if ($inline =~ /\D/) {
			$logger->info("Invalid input:  $inline  ... try again\n");
			next;
		}

		#	Check that input number was between 1 and $i
		if ($inline <= 0 || $inline > $i) {
			$logger->info("Invalid input:  $inline  ... try again\n");
			next;
		}

		$outarr[0] = $region_name;
		$outarr[1] = $subregions[$inline-1];
		$outarr[2] = $descriptions[$inline-1];
		$outarr[3] = $vobdir[$inline-1];

		return(@outarr);
	}
}

###############################################################################
#	Accessor Methods
###############################################################################
sub subregion { my $obj = shift; return $obj->{'_subregion'}; }

sub description { my $obj = shift; return $obj->{'_description'}; }

sub vobdir
{
	my($obj			) = shift;

	if (ref($obj)) {
		return $obj->{'_vobdir'};
	}
	else {
		#
		#	Class method:  $vob_dir = Region->vobdir($subregion);
		#
		return $byproj{$_[0]}->{'vobdir'};
	}
}


###############################################################################

sub new
{
	use strict;

	my($proto			) = shift;
	my($class			) = ref($proto) || $proto;
	my($subregion		) = shift;
	my($region			) = {};
	my(@outarr			) = ();
	my($i			) = 0;
	my($found		) = 0;

	if (! defined $subregion) {
		$logger->info("\nDid not get subregion for project. Must ask...\n");
		@outarr = ask_region();
	}
	else {
		#
		#	Check if subregion is valid for this region
		#
		for ($i = 0 ; $i <= $#region_subregions ; $i++) {
			if ( $region_subregions[$i] eq $subregion ) {
				$found = 1;
			}
		}
		if ( $found == 0 ) {
			return undef;
		}
		
		$outarr[0] = $region_name;
		$outarr[1] = $subregion;						# "tr", "ma", etc.
		$outarr[2] = $byproj{$subregion}->{'description'};
		$outarr[3] = $byproj{$subregion}->{'vobdir'};
	}

	$region->{'_name'}			= $outarr[0];
	$region->{'_subregion'}		= $outarr[1];
	$region->{'_description'}	= $outarr[2];
	$region->{'_vobdir'}		= $outarr[3];

	bless $region, $class;
	return $region;
}

1;
