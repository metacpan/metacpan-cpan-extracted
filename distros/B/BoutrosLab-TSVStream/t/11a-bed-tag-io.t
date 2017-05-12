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

use BoutrosLab::TSVStream::Format::AnnovarInput::HumanTag::Fixed;

my $reader;
lives_ok { $reader
		= BoutrosLab::TSVStream::Format::AnnovarInput::HumanTag::Fixed->reader( handle => \*DATA, file => 'DATA' ) }
	"create a reader from DATA";

my @vars = (
	[ 'v1' =>
		[ 'chr1_tag1',      3,   3,   '-',    'A'   ]],
	[ 'v2' =>
		[ 'chrX_tagX',   3,   3,   'A',    'CGATCGAT'   ]],
	);

subtest 'check the records from DATA stream' => sub {
	plan tests => 2 * scalar(@vars);
	for my $st (@vars) {
		my( $msg, $vals ) = @$st;
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
1_tag1	3	3	-	A
chrX_tagX	3	3	A	CGATCGAT
