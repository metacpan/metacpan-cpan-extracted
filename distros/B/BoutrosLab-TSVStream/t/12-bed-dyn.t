### 00-variant.t #############################################################################
# Basic tests for variant objects

### Includes ######################################################################################

# Safe Perl
use warnings;
use strict;
use Carp;
use Carp::Always;
# use FindBin qw($Bin);
# use lib "$Bin/../lib";

use Test::More tests => 10;
use Test::Exception;

### Tests #################################################################################

use BoutrosLab::TSVStream::Format::AnnovarInput::Human::Dyn;
use BoutrosLab::TSVStream::Format::AnnovarInput::HumanNoChr::Dyn;

my $dyn_fields = [qw(dyn am ic)];

my @vars = (
	[ 'v1' =>
		[ 'chr1',      3,   3,   '-',    'A'   ], [qw(dyn1 am1 ic1)]],
	[ 'v2' =>
		[ 'chrX',   3,   3,   'A',    'CGATCGAT'   ], [qw(dyn2 am2 ic2)]],
	);

sub map_lol {
	return map { ref $_ ? [ map_lol(@$_) ] : $_ } @_;
	}

my @vars_nochr = map_lol( @vars );

my $data_start = tell DATA;

$_->[1][0] =~ s/^chr// for @vars_nochr;

my @outfile;

sub run_test {
	my ( $r_ext, $w_ext, $vars ) = @_;

	subtest "read($r_ext) write($w_ext)" => sub {
		plan tests => 5;
		seek( DATA, $data_start, 0 );
		my $reader;
		lives_ok {
			$reader = "BoutrosLab::TSVStream::Format::AnnovarInput::Human${r_ext}::Dyn"->reader(
				handle => \*DATA,
				file   => 'DATA'
				);
			}
		"create a reader from DATA";

		my $outfile = "/tmp/jmm.$$.r.$r_ext.w.$w_ext";
		{
			my $writer;
			my $filtwriter;
			push @outfile, $outfile;

			lives_ok {
				$writer = "BoutrosLab::TSVStream::Format::AnnovarInput::Human${w_ext}::Dyn"
					->writer(
						file       => $outfile,
						dyn_fields => $dyn_fields
					);
				}
				"create a writer from DATA";

			lives_ok {
				$filtwriter = "BoutrosLab::TSVStream::Format::AnnovarInput::Human${w_ext}::Dyn"
					->writer(
						file       => "$outfile.filter",
						dyn_fields => $dyn_fields
					)->filter(
						sub {
							my $obj = shift;
							$obj->chr !~ /X/
						}
					)
				}
				"create a filtered writer from DATA";

			subtest 'check the records from DATA stream' => sub {
				plan tests => 5 * scalar(@$vars);
				for my $st (@$vars) {
					my ( $msg, $vals, $dvals ) = @$st;
					my $variant;
					lives_ok { $variant = $reader->read } "read $msg";
					is_deeply(
						[ map { $variant->$_ } qw(chr start end ref alt) ],
						$vals,
						"check values $msg"
						);
					is_deeply( $variant->dyn_values, $dvals,
						"check dynamic values $msg" );
					lives_ok { $writer->write($variant) } 'write the record';
					lives_ok { $filtwriter->write($variant) } 'write the record, filtering';
					}
				};
			}

		is( $reader->read, undef, "and then EOF" );
		};
	}

run_test( "", "", \@vars);
run_test( "NoChr", "", \@vars_nochr);
run_test( "", "NoChr", \@vars);
run_test( "NoChr", "NoChr", \@vars_nochr);

is( system( "cmp -s $outfile[0] $outfile[1]"), 0, "The chr outputs should be identical." );
is( system( "cmp -s $outfile[2] $outfile[3]"), 0, "The NoChr outputs should be identical." );
is( system( "sed -e '2,\$s/^chr//' $outfile[0] | cmp -s - $outfile[2]"), 0, "Stripping chr from the chr outputs should be identical to the NoChr outputs." );
is( system( "cmp -s $outfile[0].filter $outfile[1].filter"), 0, "The filtered chr outputs should be identical." );
is( system( "cmp -s $outfile[2].filter $outfile[3].filter"), 0, "The filtered NoChr outputs should be identical." );
is( system( "grep -v chrX $outfile[0] | cmp -s $outfile[0].filter -"), 0, "The filtered outputs should be identical to the unfiltered with 'chrX' line removed." );

unlink @outfile, map { "$_.filter" } @outfile;

done_testing();

1;

__END__
chr	start	end	ref	alt	dyn	am	ic
1	3	3	-	A	dyn1	am1	ic1
chrX	3	3	A	CGATCGAT	dyn2	am2	ic2
