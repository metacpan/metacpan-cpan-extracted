# $Id: test.pl,v 1.4 1999/07/29 18:46:23 daniel Exp $
#
######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $::loaded;}

use strict;
use Audio::MikMod qw(:all);
use Time::HiRes qw(usleep);

$::loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Check MikMod_*

my $i = 2;

ok($i++, MikMod_RegisterAllDrivers(), "Failed to register drivers!");
ok($i++, MikMod_RegisterAllLoaders(), "Failed to register loaders!");

ok($i++, !MikMod_Init(), MikMod_strerror());
ok($i++, !MikMod_EnableOutput(), "Failed to enable output!");

my $module = Player_Load('demo/2ND_PM.S3M', 64, 0);

ok($i++, defined $module, "Couldn't load module!");

ok($i++, Player_Free($module), "Couldn't free module!");

##########
# Sample_*

my $sample = Sample_Load('demo/fx1.wav');

ok($i++, defined $sample, "Couldn't load sample!");

my $front_vox = Sample_Play($sample,0,0);

ok($i++, defined $front_vox, "Failed to play sample!");

ok($i++, Voice_SetFrequency($front_vox, Voice_GetFrequency($front_vox)-1), 
	"Frequency get/set failed!");

ok($i++, Voice_SetVolume($front_vox, 0), "Couldn't set volume!");
ok($i++, Voice_SetPanning($front_vox ,512), "Couldn't set panning!");
ok($i++, Sample_Free($sample), "Failed to free sample!");
ok($i++, MikMod_DisableOutput(), "Failed to disable output!");
ok($i++, MikMod_Exit(), "Couldn't exit!");

sub ok {
	my ($n, $result, @info) = @_;
	if ($result) {
		print "ok $n\n";
	} else {
		print "not ok $n\n";
		print "# @info\n" if @info;
	}
}
