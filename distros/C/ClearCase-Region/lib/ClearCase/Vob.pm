#!/usr/local/bin/perl -w  

package Vob;

$VERSION = 1.01;

use strict;
use Carp;
use Log::Log4perl;
use ClearCase::Region;
use ClearCase::Vob_Cfg_Parser;

my($logger	) = Log::Log4perl->get_logger("Vob");

###############################################################################
#	Class Methods
###############################################################################
sub vobs
{
	use strict;

	my($self		) = shift;
	my($subregion	) = $_[0];
	my(@vobs		) = ();

	@vobs = Region->vobs($subregion);

	return @vobs;
}

sub list_all
{
	use strict;

	my($self		) = shift;
	my($subregion	) = "";
	my(@vobs		) = ();
	my(@subregions	) = Region->subregions();

	foreach $subregion (@subregions) {
		push(@vobs, Region->vobs($subregion));
	}

	return @vobs;
}

sub name_is_valid
{
	use strict;

	my($self		) = shift;
	my($vobname		) = $_[0];
	my($vob			) = "";
	my(@vobs		) = ();
	my($subregion	) = "";
	my(@subregions	) = Region->subregions();

	foreach $subregion (@subregions) {
		push(@vobs, Region->vobs($subregion));
		foreach $vob (@vobs) {
			if ($vobname eq $vob) {
				return 1;
			}
		}
	}

	return 0;
}

###############################################################################
#	Class or Object Methods
#
#	Class Method Example:
#		$subregion = Vob->subregion($vobname);
#
#	Object Method Example:
#		$subregion = $obj->subregion();
###############################################################################
sub subregion
{
	use strict;

	my($obj			) = shift;
	my($subregion	) = "";

	if (ref($obj)) {
		return $obj->{'subregion'};
	}
	else {
		return Region->get_subregion_for_vob($_[0]);
	}
}

###############################################################################
#	Object Methods
###############################################################################
sub active_rels
{
	use strict;

	my($self		) = shift;
	my(@relnums		) = @{$self->{'relnums'}};
	my(@active		) = @{$self->{'active'}};
	my(@active_rels	) = ();
	my($relno		) = "";
	my($i			) = 0;

	$i = 0;
	foreach $relno (@relnums) {
		if ($active[$i] == 1) {
			push(@active_rels, $relno);
		}
		$i++;
	}

	return @active_rels;
}

sub is_the_trunk
{
	use strict;

	my($self		) = shift;
	my($relnum		) = $_[0];
	my(@relnums		) = @{$self->{'relnums'}};

	if ($relnums[0] == $relnum) {
		return 1;
	}
	else {
		return 0;
	}
}

sub on_a_branch
{
	use strict;

	my($self		) = shift;
	my($relnum		) = $_[0];
	my(@relnums		) = @{$self->{'relnums'}};

	if ($relnums[0] == $relnum) {
		return 0;
	}
	else {
		return 1;
	}
}

###############################################################################
#	Accessor Methods
###############################################################################
sub vob { my $obj = shift; return $obj->{'vob'}; }

sub src_dir { my $obj = shift; return $obj->{'src_dir'}; }

sub lib_dirs { my $obj = shift; return @{$obj->{'lib_dirs'}}; }

sub relnums { my $obj = shift; return @{$obj->{'relnums'}}; }

sub active { my $obj = shift; return @{$obj->{'active'}}; }

###############################################################################
#	Set the vob variables:
#		$vob
#		$subregion
#		$src_dir
#		$lib_dirs
#		$relnums		- release numbers in a flatten array
#		$active			- active flags in a flatten array
#
###############################################################################
sub set_vob
{
	use strict;

	my($pnum		) = $_[0];

	my($vob			) = "";
	my($i			) = 0;
	my(@outarr		) = ();
	my($subregion	) = "";
	my(@subregions	) = Region->subregions();
	my(@vobs		) = ();

	$i = int($pnum - 1);
	foreach $subregion (@subregions) {
		push(@vobs, Region->vobs($subregion));
	}
	$vob = $vobs[$i];

	$outarr[0] = $vob;
	$outarr[1] = Region->get_subregion_for_vob($vob);

	return(@outarr);
}

###############################################################################
sub ask_vob
{
	use strict;

	croak("Private method, Vob->ask_vob(), cannot be called directly")
		unless caller->isa("Vob");
	my($validinput	) = 0;
	my($inline		) = "";
	my($askcorrect	) = "";
	my($i			) = 0;
	my($vob			) = "";
	my(@outarr		) = ();
	my($subregion	) = "";
	my(@subregions	) = Region->subregions();
	my(@vobs		) = ();

	while ($validinput == 0) {

		$i = 0;
		$logger->info("Please select vob:\n");
		foreach $subregion (@subregions) {
			@vobs = Region->vobs($subregion);
			foreach $vob (@vobs) {
				$i += 1;
				$logger->info("   $i)  $vob\n");
			}
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

		@outarr = set_vob(int($inline));

		$logger->info("You have chosen $outarr[0].  Is this CORRECT?(y/n): ");
		$askcorrect = <STDIN>;
		chomp($askcorrect);  
		$askcorrect = uc($askcorrect);
		$logger->info("You answered $askcorrect \n");

		if ($askcorrect ne "Y") {
			$validinput = 0 ;
		}
		else {
			$validinput = 1;
		}
	}

	return(@outarr);
}

###############################################################################

sub new
{
	use strict;

	my($proto			) = shift;
	my($class			) = ref($proto) || $proto;
	my($subregion_name	) = shift;  
	my($vname			) = shift;  
	my($myvob			) = {};
	my(@outarr			) = ();
	my(@vobs			) = ();
	my($vob				) = "";
	my($subregion		) = "";
	my(@subregions		) = Region->subregions();

	if (! defined $subregion_name) {
		$logger->info("\nDid not get vob. Must ask...\n");
		@outarr = ask_vob();
		$myvob = ClearCase::Vob_Cfg_Parser->new($outarr[1], $outarr[0]);
		$logger->debug("new: vob is $$myvob{'vob'}\n");

		bless $myvob, $class;
		return $myvob;
	}
	else {
		foreach $subregion (@subregions) {
			if ($subregion_name eq $subregion) {
				@vobs = Region->vobs($subregion);
				foreach $vob (@vobs) {
					if ($vname eq $vob) {
						$outarr[0] = $vob;
						$outarr[1] = $subregion;
						$myvob = ClearCase::Vob_Cfg_Parser->new($outarr[1], $outarr[0]);
						$logger->debug("new: vob is $$myvob{'vob'}\n");
					
						bless $myvob, $class;
						return $myvob;
					}
				}
			}
		}
	}

	$logger->error("only one vob option can be specified.");
	exit 1;
}

1;
