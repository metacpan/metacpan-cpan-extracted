### 00-variant.t #############################################################################
# Basic tests for variant objects

### Includes ######################################################################################

# Safe Perl
use warnings;
use strict;
use Carp;
# use FindBin qw($Bin);
# use lib "$Bin/../lib";

use Test::More tests => 3;
use Test::Exception;

### Tests #################################################################################

use BoutrosLab::TSVStream::Format::AnnovarInput::Human::Fixed;

my $data_start = tell DATA;
my $reader;
my @vars = (
	[ 'v1' =>
		[ 'chr1',      3,   3,   '-',    'A'   ]],
	);

seek( DATA, $data_start, 0 );
lives_ok { $reader
		= BoutrosLab::TSVStream::Format::AnnovarInput::Human::Fixed->reader(
			handle => \*DATA,
			file => 'DATA'
		)->filter(
			sub {
				my $record = shift;
				$record->start != 4
			}
		)->filter(
			sub {
				my $record = shift;
				$record->start != 5
			}
		)
	}
	"create a double filtered reader from DATA";

subtest 'check the records from the DATA stream after double filtering' => sub {
	plan tests => 2;
	for my $st (@vars) {
		my( $msg, $vals ) = @$st;
		next if $msg eq 'v2';
		my $variant;
		lives_ok { $variant = $reader->read } "read $msg";
		is_deeply( [ map { $variant->$_ } qw(chr start end ref alt) ], $vals, "check values $msg" );
		}
	};

is( $reader->read, undef, "and then EOF" );

done_testing();

1;

__END__
chr	start	end	ref	alt
1	3	3	-	A
1	4	4	-	A
1	5	5	-	A
