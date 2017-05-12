### 02-tsvstreamdynonly.t #########################################################################
# Basic tests for tsvstreamdynonly objects

### Includes ######################################################################################

# Safe Perl
use warnings;
use strict;

use Carp;
use File::Temp;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More tests => 5;
use Test::Exception;
use IO::String;

### Tests #################################################################################

use BoutrosLab::TSVStream::Format::None::Dyn;


my $good_stream = <<'_END_TEST1_';
dyn1	dyn2	dyn3
a1	b1	c1
a2	b2	c2
_END_TEST1_

my $good_stream_x = <<'_END_TEST1_';
dyn1x	dyn2x	dyn3x
a1	b1	c1
a2	b2	c2
_END_TEST1_

my $dup_head_stream = <<'_END_TEST1_';
dyn1	dyn2	dyn1
a1	b1	c1
a2	b2	c2
_END_TEST1_

my $flds  = [ qw(dyn1  dyn2  dyn3)  ];
my $xflds = [ qw(dyn1x dyn2x dyn3x) ];

should_work(
	"good_stream",
	$good_stream,
	[ extra_class_params => [ install_methods => 1 ] ],
	''
	);
should_work(
	"dup_head_stream with no methods",
	$dup_head_stream,
	[ extra_class_params => [ install_methods => 0 ] ],
	''
	);
should_work(
	"good_stream_x",
	$good_stream_x,
	[ extra_class_params => [ install_methods => 1 ] ],
	'x'
	);

open my $fh, '<', \$dup_head_stream ;
my $reader;
lives_ok { $reader = BoutrosLab::TSVStream::Format::None::Dyn->reader(
		handle => $fh,
		file => "dup_head_stream",
		extra_class_params => [ install_methods => 1 ],
		)
	}
	"    open a reader on a stream with dup column names";

dies_ok { my $rec = $reader->read } "    fail to read a record on a stream with dup column names";

sub should_work {
	my ($name, $stream, $args, $x) = @_;

	subtest "$name - should scan correctly" => sub {
		plan tests =>  23;
		my $reader;
		my $good_fields;
		my $bad_fields;
		use Data::Dump qw(dump);
		my ($dyn1, $dyn2, $dyn3);
		if ($args->[1][1]) {
			$good_fields = $x ? $xflds : $flds;
			$bad_fields  = $x ? $flds  : $xflds;
			($dyn1, $dyn2, $dyn3) = @$good_fields;
			}
		else {
			$good_fields = [];
			$bad_fields  = [ @$flds, @$xflds ];
			}

		open my $fh, '<', \$stream ;

		lives_ok { $reader = BoutrosLab::TSVStream::Format::None::Dyn->reader(
				handle => $fh,
				file => $name,
				@$args,
				)
			}
			"    open a reader";

		for my $i (1..2) {
			my $rec;
			lives_ok { $rec = $reader->read } "    read record $i";
			lives_ok { $rec->$_ }             "     has attribute for $_"
				for @$good_fields;
			dies_ok  { $rec->$_ }             "     no attribute for $_"
				for @$bad_fields;
			if (@$good_fields) {
				is( $rec->$dyn1, "a$i", "    field $dyn1 value is correct");
				is( $rec->$dyn2, "b$i", "    field $dyn2 value is correct");
				is( $rec->$dyn3, "c$i", "    field $dyn3 value is correct");
				}
			else {
				my $vals = $rec->dyn_values;
				is( $vals->[0], "a$i", "    field 1 value is correct");
				is( $vals->[1], "b$i", "    field 2 value is correct");
				is( $vals->[2], "c$i", "    field 3 value is correct");
				}
			}

		is($reader->read, undef, "    read at EOF");
		ok($reader->_at_eof, "    status at EOF");
		};
	}

done_testing();

1;
