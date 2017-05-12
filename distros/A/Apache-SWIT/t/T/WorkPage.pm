use strict;
use warnings FATAL => 'all';

package T::WorkPage::Worker;
use base 'Queue::Worker';
use File::Slurp;

sub name { return 'swi'; }

sub process {
	sleep 1 unless $_[0]->{slept};
	$_[0]->{slept} = 1;
	append_file("/tmp/swit_worker.res", $_[1]);
}

package T::WorkPage;
use base 'Apache::SWIT';

sub swit_render {
	my ($class, $r) = @_;
	$class->swit_schedule($r, 'T::WorkPage::Worker', "hi", "bye");
	return "../swit/r";
}

sub swit_update {
	my ($class, $r) = @_;
	$class->swit_schedule($r, 'T::WorkPage::Worker', "worku");
	return "../swit/r";
}

1;
