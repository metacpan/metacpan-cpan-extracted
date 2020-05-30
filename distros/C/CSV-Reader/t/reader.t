# Save this file in UTF-8 encoding!
use strict;
use warnings;
use utf8;
use Data::Dumper qw(Dumper); local $Data::Dumper::Terse = 1;
#use open ':std', ':encoding(utf8)';
use open OUT => ':locale';	# before Test::More because it duplicates STDOUT and STDERR
use Test::More qw(no_plan);
use Cwd ();
use File::Basename;
use lib (
	File::Basename::dirname(Cwd::abs_path(__FILE__)) . '/../lib',	# in build dir
	File::Basename::dirname(Cwd::abs_path(__FILE__)) . '/../..'		# in project dir with t subdir in same dir as .pm file
);

my $verbose = !$ENV{'HARNESS_ACTIVE'} && 0;

my $class = 'CSV::Reader';
require_ok($class) || BAIL_OUT("$class has errors");
my %default_options = (
	'delimiter' => ';',
	'enclosure' => '',
	'field_aliases'	=> {
		'Postal Code'	=> 'postcode',
	},
);

#my $csvfile = ($0 =~ s|[^/]+$||r) . 'utf8_with_bom.csv';
my $csvfile = $0; $csvfile =~ s|[^/]+$||; $csvfile .= 'utf8_with_bom.csv';

my %tests = (
	'file name' =>	{
		'construct' => sub {
			return $class->new($csvfile, %default_options);
		},
		'extra tests'	=> sub {
			my $name = shift;
			my $o = shift;
			is_deeply(
				[$o->fieldNames()],
				[
					'ID',
					'postcode',				# Aliased 'Postal Code',
					'Street No',
					'Street Entrance',
					'Floor',
					'Address Code 1',
					'Address Code 2',
					'Subscription list',
				],
				"$name: fieldNames() returns expected names"
			);
		},
		'extra row tests' => sub {
			my $name = shift;
			my $o = shift;
			my $row = shift;
			my $addr = $row->{'Address Code 2'};
			if (defined($addr)) {
				ok(utf8::is_utf8($addr), "$name: Address \"$addr\" is flagged as UTF-8");
				is($addr, 'Déjà vu straat', "$name: UTF-8 encoding is OK after parsing");
			}
		},
	},
	#'file handle' => {
	#	'construct' => sub {
	#		open(my $h, '<', $csvfile) || die("Failed to open $csvfile: $!");
	#		seek($h, 3, 0);	# skip passed BOM
	#		return $class->new($h, %default_options);
	#	},
	#},
	'file handle via File::BOM' => {
		'construct' => sub {
			my $h;
			open($h, '<:via(File::BOM)', $csvfile) || die("Failed to open $csvfile: $!");
			return $class->new($h, %default_options);
		},
		'requires' => sub {
			require File::BOM;
		},
	},
	'IO::File (IO::Handle)' => {
		'construct' => sub {
			require IO::File;
			my $io = IO::File->new(); # subclass of IO::Handle
			$io->open($csvfile, '<:via(File::BOM)') || die("Failed to open $csvfile: $!");
			return $class->new($io, %default_options);
		},
		'requires' => sub {
			require File::BOM;
			require IO::File;
		},
	},
	'IO::Scalar (IO::Handle)' => {
		'construct' => sub {
			my $data = '';
			my $h;
			open($h, '<:via(File::BOM)', $csvfile) || die("Failed to open $csvfile: $!");
			while (my $line = <$h>) {
				$data .= $line;
			}
			close($h);
			my $io = new IO::Scalar(\$data); # subclass of IO::Handle
			return $class->new($io, %default_options);
		},
		'extra row tests' => sub {
			my $name = shift;
			my $o = shift;
			my $row = shift;
			my $addr = $row->{'Address Code 2'};
			if (defined($addr)) {
				ok(utf8::is_utf8($addr), "$name: Address \"$addr\" is flagged as UTF-8");
				is($addr, 'Déjà vu straat', "$name: UTF-8 encoding is OK after parsing");
			}
		},
		'requires' => sub {
			require File::BOM;
			require IO::Scalar;
		},
	},
	'complex' => {
		'construct' => sub {
			my $h;
			open($h, '<:via(File::BOM)', $csvfile) || die($!);
			my %opts = (
				%default_options,
			);
			return $class->new($h, %opts);
		},
		'extra row tests' => sub {
			my $name = shift;
			my $o = shift;
			my $row = shift;
			my $addr = $row->{'Address Code 2'};
			if (defined($addr)) {
				ok(utf8::is_utf8($addr), "$name: Address \"$addr\" is flagged as UTF-8");
				is($addr, 'Déjà vu straat', "$name: UTF-8 encoding is OK after parsing");
			}
		},
		'requires' => sub {
			require File::BOM;
		},
	},
	'include_fields' =>	{
		'construct' => sub {
			return $class->new($csvfile, %default_options,
				'include_fields' => [
					'ID',
					'postcode',
					'Subscription list',
				],
			);
		},
		'extra tests' => sub {
			my $name = shift;
			my $o = shift;
			is_deeply(
				[$o->fieldNames()],
				[
					'ID',
					'postcode',				# Aliased 'Postal Code',
					'Subscription list',
				],
				"$name: fieldNames() returns expected names"
			);
		},
	},
);

foreach my $name (keys %tests) {
	my $test = $tests{$name};
	SKIP: {
		if (my $sub = $test->{'requires'}) {
			eval {
				&{$test->{'requires'}}();
			};
			if ($@) {
				skip("$name: Module(s) required for test not installed: $@", 1);
				next;
			}
		}
		my $o = eval {
			return &{$test->{'construct'}}();
		};
		is($@, '', "$name: Create $class object");
		isa_ok($o, $class);
		if ($test->{'extra tests'}) {
			&{$test->{'extra tests'}}($name, $o);
		}
		while (my $row = $o->nextRow()) {
			ok(!$o->eof(), "$name: eof() not reached while reading");
			$verbose && diag("$name " . Data::Dumper::Dumper($row));
			ok(defined($row->{'ID'}) && ($row->{'ID'} =~ /^\d+$/), "$name: \$row->{'ID'} returns the expected value");
			ok(defined($row->{'postcode'}), "$name: \$row->{'postcode'} returns a value");
			if (my $sub = $test->{'extra row tests'}) {
				&{$test->{'extra row tests'}}($name, $o, $row);
			}
		}
		ok($o->eof(), "$name: eof() reached at EOF");
	}
}

if ('test rewind') {
	my $o = $class->new($csvfile, %default_options);
	my @rows1;
	while (my $row = $o->nextRow()) {
		push(@rows1, $row);
	}
	$o->rewind();
	my @rows2;
	while (my $row = $o->nextRow()) {
		push(@rows2, $row);
	}
	is_deeply(\@rows1, \@rows2, 'rewind() works');
	#diag(Dumper(\@rows1));
	#diag(Dumper(\@rows2));
}


unless($ENV{'HARNESS_ACTIVE'}) {
	my $o = $class->new(
		$csvfile,
		%default_options,
		#'debug' => 1
	);
	require Encode;
	while (my $row = $o->nextRow()) {
		diag(Dumper($row));
		diag($row->{'Address Code 2'});
		#warn '# ' . $row->{'Address Code 2'} . "\n";
		#print '# ' . $row->{'Address Code 2'} . "\n";
		diag('is_utf8: ' . int(Encode::is_utf8($row->{'Address Code 2'})));
		last;
	}
}
