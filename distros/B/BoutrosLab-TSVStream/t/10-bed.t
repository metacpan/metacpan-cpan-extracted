### 10-bed.t #############################################################################
# Basic tests for variant objects

### Includes ######################################################################################

# Safe Perl
use warnings;
use strict;
use Carp;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More tests => 1;
use Test::Exception;

### Tests #################################################################################

# BEGIN { $DB::single = 1; };

use BoutrosLab::TSVStream::Format::AnnovarInput::Human::Fixed;

my $goodchr1     = q{1};
my $goodchrX     = q{X};
my $goodchrchr1  = q{chr1};
my $goodchrchrX  = q{chrX};
my $badchrZ      = q{Z};
my $badchrchrZ   = q{chrZ};
my $badchrnul    = q{};
my $badchrchrnul = q{chr};

my $goodstart   = 3;
my $badstartnul = q{};
my $badstartZ   = q{Z};

my $goodend   = 3;
my $badendnul = q{};
my $badendZ   = q{Z};

my $goodrefdash = q{-};
my $goodref     = q{A};
my $goodreflong = q{CGAT} x 125;
my $badrefZ     = q{Z};
my $badreflong  = q{CGAT} x 126;

my $goodaltdash = q{-};
my $goodalt     = q{A};
my $goodaltlong = q{CGAT} x 125;
my $badaltZ     = q{Z};
my $badaltlong  = q{CGAT} x 126;

# Verify some validation checking
subtest 'attribute validation' => sub {
	plan tests => 3;
	dies_ok { BoutrosLab::TSVStream::Format::AnnovarInput::Human::Fixed->new() }
		"new with no attributes aborts!";
	my @should_die = (
		[ 'badchrZ' =>
		   	[ $badchrZ,      $goodstart,   $goodend,   $goodref,    $goodalt   ]],
		[ 'badchrchrZ' =>
		   	[ $badchrchrZ,   $goodstart,   $goodend,   $goodref,    $goodalt   ]],
		[ 'badchrnul' =>
		   	[ $badchrnul,    $goodstart,   $goodend,   $goodref,    $goodalt   ]],
		[ 'badchrchrnul' =>
		   	[ $badchrchrnul, $goodstart,   $goodend,   $goodref,    $goodalt   ]],
		[ 'badstartZ' =>
		   	[ $goodchr1,     $badstartZ,   $goodend,   $goodref,    $goodalt   ]],
		[ 'badstartnul' =>
		   	[ $goodchr1,     $badstartnul, $goodend,   $goodref,    $goodalt   ]],
		[ 'badendZ' =>
		   	[ $goodchr1,     $goodstart,   $badendZ,   $goodref,    $goodalt   ]],
		[ 'badendnul' =>
		   	[ $goodchr1,     $goodstart,   $badendnul, $goodref,    $goodalt   ]],
		[ 'badrefZ' =>
		   	[ $goodchr1,     $goodstart,   $goodend,   $badrefZ,    $goodalt   ]],
		[ 'badreflong' =>
		   	[ $goodchr1,     $goodstart,   $goodend,   $badreflong, $goodalt   ]],
		[ 'badaltZ' =>
		   	[ $goodchr1,     $goodstart,   $goodend,   $goodref,    $badaltZ   ]],
		[ 'badaltlong' =>
		   	[ $goodchr1,     $goodstart,   $goodend,   $goodref,    $badaltlong]],
		);
	my @should_live = (
		[ '1,3,3,-,-' =>
		   	[ $goodchr1,      $goodstart,   $goodend,   $goodrefdash, $goodaltdash ]],
		[ 'X,3,3,A,A' =>
		   	[ $goodchrX,      $goodstart,   $goodend,   $goodref,     $goodalt     ]],
		[ 'chr1,3,3,[long],A' =>
		   	[ $goodchrchr1,   $goodstart,   $goodend,   $goodreflong, $goodalt     ]],
		[ 'chrX,3,3,A,[long]' =>
		   	[ $goodchrchrX,   $goodstart,   $goodend,   $goodref,     $goodaltlong ]],
		);
	subtest 'bad attribute values should fail' => sub {
		plan tests => scalar(@should_die);
		for my $st (@should_die) {
			my ( $msg, $vals ) = @$st;
			dies_ok {
				BoutrosLab::TSVStream::Format::AnnovarInput::Human::Fixed->new(
					fields => $vals );
				}
			$msg;
			}
		};
	subtest 'good attribute values should pass' => sub {
		plan tests => scalar(@should_live);
		for my $st (@should_live) {
			my ( $msg, $vals ) = @$st;
			dies_ok {
				BoutrosLab::TSVStream::Format::AnnovarInput::Human::Fixed->new(
					fields => $vals );
				}
			$msg;
			}
		}
	};

done_testing();

1;
