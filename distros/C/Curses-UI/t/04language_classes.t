# -*- perl -*-
use strict;
use Test::Simple tests => 15;
use File::Spec;
use FindBin;
use lib "$FindBin::RealBin/../lib";
use Curses::UI;

my $filename;
foreach my $mod (keys %INC) {
	$filename  = $INC{$mod} if ($mod =~ /UI\.pm/);
}

$filename =~ s/\.pm//gi;
$filename = File::Spec->catfile($filename, "Language");

opendir DIR, "$filename" or die "Couldn't open language dir $filename: $!\n";
my @entries = grep /.pm$/, readdir(DIR);

foreach my $file (@entries) {
    require "Curses/UI/Language/$file";
	$file =~ s/\.pm//gi;
    ok(1,$file);
}

