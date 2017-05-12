#!/usr/bin/env perl 
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use strict;
use warnings;
use 5.010;
use Acpi::Class;
use Test::More tests => 1;

# Check if the value of /sys/class/power_supply/$bat/technology 
# is the same that the one reported by Acpi::Class
my $class   = Acpi::Class->new( class => 'power_supply' );
# my $dir = '/sys/class/power_supply';
my $dir = '/home/mimosinnet/borrem';
my $battery;
if (-d $dir) {
	opendir(my $device_dir, $dir) or last;
	while(readdir($device_dir))
	{
		last unless defined $_;
		$battery = $_ if ($_ =~ /BAT/);
	}
	closedir($device_dir);
	if (defined $battery) 
	{
		my $file = "$dir/$battery/technology";
		if (-f $file ) {
			my $content = do {
				local @ARGV = $file; 
				local $/    = <ARGV>;
			};
			$class->device($battery);
			my $bat_technology = $class->g_values->{'technology'};
			ok ( $bat_technology = $content, "Returned the correct value of $battery technology: $content");
		}
	}
	else
	{
		ok ( 1, "There is no BAT* file in folder $dir");
	}
}
else
{
	ok ( 1, "Directory $dir does not exist");
}

done_testing(1);
