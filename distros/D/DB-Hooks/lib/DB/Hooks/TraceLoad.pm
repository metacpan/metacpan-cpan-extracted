package DB::Hooks::TraceLoad;

use strict;
use warnings;

use IO::Handle;
open my $stat, ">load.info";
$stat->autoflush(1);


sub load_handler {
	# DB::stop;
	my( $what ) =  @_;
	$what =~ s/\*main::_<//;

	# Find a module name by a file name
	$what =  (grep{ ($INC{$_}//'') eq $what } keys %INC)[0]  // 'UNKNOWN';
	$what =~ s!/!::!g;
	$what =~ s!\.pm$!!;

	my $from =  (caller(6))[0]  // 'UNKNOWN';
	$stat->print( "$what << $from\n" );

	# DB::say "\n\n\n>>>>>>>>>>>>>Loaded '@_'<<<<<<<<<<<<<<<<\n\n\n";
}

DB::on( load => \&load_handler );

1;
