package DB::Hooks::TraceSubs;

use strict;
use warnings;

use IO::Handle;
use Time::HiRes qw/ gettimeofday /;
open my $stat, ">stat.info";
$stat->autoflush(1);


sub call_handler {
	# my $t =  [ gettimeofday ];
	my $fl =  join ':', (caller(4))[1..2];

	$stat->autoflush(1);
	print $stat "$_[0] > $fl\n";
	# DB::x 'main'; 1;
	# DB::stop 'main';
	1;
}


sub return_handler {
	# my $t =  [ gettimeofday ];
	$stat->autoflush(1);
	print $stat "$_[0] <\n";
}


DB::on( call   => \&call_handler   );
DB::on( return => \&return_handler );

1;
