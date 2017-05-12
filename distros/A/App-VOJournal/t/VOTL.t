#! perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok( 'App::VOJournal::VOTL' ) || print "Bail out!\n";
}

diag( "Testing App::VOJournal::VOTL $App::VOJournal::VOTL::VERSION, Perl $], $^X" );

my $votl = App::VOJournal::VOTL->new();

# check reading and writing vimoutliner files

ok(1 == $votl->read_file('t/otl/TODO.otl'),'number of top level elements');

$votl->write_file('t/otl/TODO.otl-out');

ok(0 == diff_files('t/otl/TODO.otl','t/otl/TODO.otl-out'),'compare read and written file');

unlink 't/otl/TODO.otl-out';

# check filtering out unchecked boxes

$votl->write_file_no_checked_boxes('t/otl/TODO.otl-out');

ok(0 == diff_files('t/otl/TODO-unchecked.otl','t/otl/TODO.otl-out'),'write unchecked file');

# !!! The following test work with undocumented internal functions.
# You may have a look at these tests to understand the working of the
# module but never expect these functions to remain unchanged and never
# use them when working  with this module !!!
#
# You have been warned.
#
# test detection of checkboxes
#
my $ub = $votl->{objects}->[0];
my $cb = $votl->{objects}->[0]->{children}->[2];

ok(App::VOJournal::VOTL::_unchecked_box($ub),'unchecked box');
ok(! App::VOJournal::VOTL::_unchecked_box($cb),'not unchecked box');

ok(App::VOJournal::VOTL::_checked_box($cb),'checked box');
ok(! App::VOJournal::VOTL::_checked_box($ub),'not checked box');

unlink 't/otl/TODO.otl-out';

$votl = App::VOJournal::VOTL->new();
$votl->read_file_no_checked_boxes('t/otl/TODO.otl');
$votl->write_file('t/otl/TODO.otl-out');

ok(0 == diff_files('t/otl/TODO-unchecked.otl','t/otl/TODO.otl-out'),'read file unchecked');

# Test inserting objects
my $object;

$votl = App::VOJournal::VOTL->new();

ok(!defined ($object = $votl->fetch_line(0)), 'fetch in empty VOTL');

$votl->insert_line(3, 'number three');


$object = $votl->fetch_line(0);
ok(0 == ('number three' cmp $object), 'fetch the first');
$object = $votl->fetch_line(-1);
ok(0 == ('number three' cmp $object), 'fetch the last');
$object = $votl->fetch_line(1);
ok(!defined $object,                  'fetch non existant');

$votl->delete_line(0);
ok(!defined ($object = $votl->fetch_line(0)), 'fetch in emptied VOTL');

unlink 't/otl/TODO.otl-out';

# finished the testing
#
done_testing;

# only auxiliary functions following

sub diff_files {
	my ($fn1,$fn2) = @_;
	my $diff = 0;
	if (open my $in1, '<', $fn1) {
		if (open my $in2, '<', $fn2) {
			my @lines1 = <$in1>;
			my @lines2 = <$in2>;
			close $in2;
			if (scalar @lines1 <=> scalar @lines2) {
				$diff = 1;
			}
			else {
				for (my $i = 0; $i <= $#lines1; $i++) {
					if ($lines1[$i] cmp $lines2[$i]) {
						$diff = 1;
						last;
					}
				}
			}
		}
		else {
			$diff = 1;
		}
		close $in1;
	}
	elsif (open my $in2,'<', $fn2) {
		$diff = 1;
	}
	return $diff;
}
