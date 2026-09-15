#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The packed file of make dist: the bytes, the pruned @INC, and the
# module list (DIST-PACK).
#
# Each case builds a pack in a temporary tree, with a version that no
# release holds, so build/ stays untouched and no stamp of a checkout
# passes a case by accident.
#
# The pack build needs the installed Fugu, so its child carries
# PERL5LIB. The run of the packed file carries none, and its @INC
# holds the core directories alone. The packed file must need no
# installed Fugu (CLI-PROGRAM-1).
#
# Two cases hold the pack to the source floor. One reads every
# version pragma of the text, and it runs on every host. The other
# runs the pack on a perl 5.34, and it needs such a perl on the
# host. The runner of CI holds none, so the first case is the gate
# that catches a floor regression there.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use File::Copy       qw(copy);
use File::Find       ();
use File::Path       qw(make_path);
use File::Spec       ();
use File::Temp       qw(tempdir);
use FindBin          qw($RealBin);
use Module::CoreList ();
use lib "$RealBin/../../lib";

use Fugu;
use Fugu::Process;

my $root = "$RealBin/../..";

# The version of the pack under test.
my $VERSION = '9.9.9';

# The floor of the source and of the pack (D-02). Module::CoreList
# reads a perl version in this form.
my $FLOOR = 5.034;

# The pruned runner. The runner sets @INC to the core directories of
# its own perl, and then it runs the packed file. A -I option adds a
# directory and removes none, so the prune happens here. The runner
# reads the directories from the environment, because @INC must hold
# them before the compilation of the file starts.
my $RUNNER = <<'RUN';
BEGIN { @INC = split /:/, $ENV{FUGUBENCH_INC} }
my $file = shift @ARGV;
$0 = $file;
my $ran = do $file;
die $@ if $@;
die "cannot run $file: $!\n" unless defined $ran;
RUN

# _read($path):
#	The whole text of one file.
sub _read ($path)
{
	open my $fh, '<', $path or do {
		fail("$path is readable");
		return q{};
	};
	local $/ = undef;
	my $text = <$fh>;
	close $fh;

	return $text;
}

# _env(%extra):
#	The environment of a child. The child holds the named
#	variables and nothing else, so no variable of the operator
#	reaches it.
sub _env (%extra)
{
	return { PATH => $ENV{PATH} // '/usr/bin:/bin', %extra };
}

# _pack($label):
#	Build one pack in a temporary tree, and return its path. The
#	child carries PERL5LIB, because scripts/dist and scripts/pack
#	load the installed Fugu.
sub _pack ($label)
{
	my $dir = tempdir( CLEANUP => 1 );
	my $env = _env(
		HOME => $dir,
		defined $ENV{PERL5LIB} ? ( PERL5LIB => $ENV{PERL5LIB} ) : ()
	);

	my $r = Fugu::Process->run(
		cmd => [
			$^X, 'scripts/pack', '--version', $VERSION,
			'--out', $dir
		],
		cwd => $root,
		env => $env,
	);
	die "cannot run scripts/pack: $r->{error}\n" if defined $r->{error};

	is( $r->{exit_code}, 0,   "the $label pack exits 0" );
	is( $r->{stdout},    q{}, "the $label pack prints nothing" );

	my $packed = File::Spec->catfile( $dir, 'fugubench' );
	ok( -f $packed, "the $label pack writes fugubench" );

	return $packed;
}

# _core_dirs($perl):
#	The core library directories of one perl, joined with a colon.
sub _core_dirs ($perl)
{
	my $r = Fugu::Process->run(
		cmd => [
			$perl, '-MConfig', '-e',
			'print join ":", @Config{qw(privlibexp archlibexp)}'
		],
		env => _env(),
	);

	return $r->{success} ? $r->{stdout} : undef;
}

# _version($perl):
#	The $] value of one perl, or undef.
sub _version ($perl)
{
	my $r = Fugu::Process->run(
		cmd => [ $perl, '-e', 'print $]' ],
		env => _env(),
	);

	return $r->{success} ? $r->{stdout} : undef;
}

# _pruned($perl, $dirs, $home, @argv):
#	Run the pruned runner with one perl. The environment names no
#	PERL5LIB, so the child reads no library of the operator.
sub _pruned ( $perl, $dirs, $home, @argv )
{
	my $r = Fugu::Process->run(
		cmd => [ $perl, '-e', $RUNNER, @argv ],
		env => _env( HOME => $home, FUGUBENCH_INC => $dirs ),
	);
	die "cannot run $perl: $r->{error}\n" if defined $r->{error};

	return $r;
}

# _fugu_uses($path):
#	Every Fugu module that one file loads with use or require.
sub _fugu_uses ($path)
{
	return map { /\A\s*(?:use|require)\s+(Fugu(?:::\w+)*)\b/ ? $1 : () }
	    split /^/, _read($path);
}

# _app_modules():
#	The require name of every module under lib/.
sub _app_modules ()
{
	my $lib = "$root/lib";

	my @names;
	File::Find::find(
		sub {
			push @names,
			    File::Spec->abs2rel( $File::Find::name, $lib )
			    if -f $_ && /\.pm\z/;
		},
		$lib
	);

	return @names;
}

# _closure():
#	The require name of every Fugu module that the program needs:
#	the modules that lib/ and bin/fugubench load, and the closure
#	of those modules over the installed library.
sub _closure ()
{
	my @queue = _fugu_uses("$root/bin/fugubench");
	push @queue, _fugu_uses("$root/lib/$_") for _app_modules();

	my %seen;
	while (@queue) {
		my $module = shift @queue;
		my $name   = ( $module =~ s{::}{/}gr ) . '.pm';
		next if $seen{$name}++;

		eval { require $name; 1 } or do {
			fail("the host holds $module");
			next;
		};
		push @queue, _fugu_uses( $INC{$name} );
	}

	return keys %seen;
}

# _packed_modules($text):
#	The require name of every module of one packed file.
sub _packed_modules ($text)
{
	return map { /\A\$source\{'([^']+)'\} = <</ ? $1 : () }
	    split /^/, $text;
}

# _module_name($file):
#	The package name of one require name.
sub _module_name ($file)
{
	my $name = $file =~ s/\.pm\z//r;
	$name =~ s{/}{::}g;

	return $name;
}

# _minor($pragma):
#	The minor number of one version pragma. A pragma with a `v`
#	prefix, or with a third field, is a v-string, and a v-string
#	holds the minor in the second field. So `use v5.36;`,
#	`use v5.36.0;` and `use 5.36.0;` each name 36. A pragma with
#	one dot and no prefix is a decimal, and a decimal holds the
#	minor in three digits of the fraction. So `use 5.034;` names
#	34, and `use 5.36;` names 360.
sub _minor ($pragma)
{
	return $1 if $pragma =~ /\Av5[.]([0-9]+)/;
	return $1 if $pragma =~ /\A5[.]([0-9]+)[.]/;

	my ($fraction) = $pragma =~ /\A5[.]([0-9]+)\z/;
	die "cannot read the version pragma $pragma\n" unless defined $fraction;

	return 0 + substr( "${fraction}00", 0, 3 );
}

# _above_floor($source):
#	Each version pragma of one text that names a perl above the
#	floor. A pragma takes a `v` prefix or none, two fields or
#	three, and a padded fraction or none. The case below holds
#	the scan to each spelling.
sub _above_floor ($source)
{
	my @above;
	for my $line ( split /^/, $source ) {
		next unless $line =~ /\A\s*use\s+(v?5[.][0-9.]+)\s*;/;
		push @above, $1 if _minor($1) > 34;
	}

	return @above;
}

# _write($path, $text):
#	Write one file of a temporary tree.
sub _write ( $path, $text )
{
	open my $fh, '>', $path or die "cannot write $path: $!\n";
	print {$fh} $text;
	close $fh or die "cannot close $path: $!\n";

	return $path;
}

my $packed = _pack('first');
my $text   = _read($packed);

# The same tree gives the same bytes (DIST-PACK-4)
{
	my $second = _pack('second');
	is( _read($second), $text, 'two packs of one tree are byte-equal' );
}

# The one-file program: the shebang of DIST-PACK-5, the mode, and no
# line that reaches outside the file. The packer drops the FindBin
# and lib lines of bin/fugubench, because they put lib/ of a checkout
# in front of the pack.
{
	like( $text, qr{\A\#!/usr/bin/env perl\n}, 'the pack starts with the shebang' );
	ok( -x $packed, 'the pack is executable' );
	unlike(
		$text, qr/^use \s+ (?: lib | FindBin ) \b/mx,
		'the pack holds no lib line of a checkout'
	);
}

# The module list: the modules of lib/ and the closure of the Fugu
# modules over the installed library (DIST-PACK-1, DIST-PACK-2)
{
	# The list goes through a variable, because sort reads a bare
	# call in front of a list as its comparison routine.
	my @want   = ( _app_modules(), _closure() );
	my @packed = _packed_modules($text);
	is_deeply(
		[ sort @packed ], [ sort @want ],
		'the pack holds the modules of the program'
	);
}

# Every version pragma of the pack names the floor or less (D-02).
# A source that names a later perl runs on the perl of CI and fails
# on the floor, so this case reads the text of the pack and needs no
# perl 5.34 (DIST-PACK-5).
{
	my @above = _above_floor($text);
	is( "@above", q{}, 'every version pragma of the pack names perl 5.34 or less' );

	# Each spelling of a version pragma, and the minor number
	# that perl reads from it. `use 5.34.0;` is a v-string with
	# no prefix, and a read of its fraction gives 340, which
	# reports the floor itself as above the floor.
	my @spelling = (
		[ 'v5.34',   34 ],
		[ 'v5.34.0', 34 ],
		[ '5.34.0',  34 ],
		[ '5.034',   34 ],
		[ 'v5.36',   36 ],
		[ 'v5.36.0', 36 ],
		[ '5.36.0',  36 ],
		[ '5.036',   36 ],
		[ '5.36',    360 ],
	);
	is( _minor( $_->[0] ), $_->[1], "the scan reads use $_->[0]; as $_->[1]" )
	    for @spelling;

	# The scan reads a whole source, so this case holds it to
	# each spelling there as well. A scan that misreads one
	# reports a clean pack, and the register of STATUS.md then
	# overstates its coverage.
	my $sample = join q{}, map { "use $_->[0];\n" } @spelling;
	is_deeply(
		[ _above_floor($sample) ],
		[ 'v5.36', 'v5.36.0', '5.36.0', '5.036', '5.36' ],
		'and it flags each spelling above the floor'
	);
}

# No core module enters the pack (DIST-PACK-3)
{
	my @core =
	    grep { Module::CoreList->is_core( $_, undef, $FLOOR ) }
	    map  { _module_name($_) } _packed_modules($text);
	is( "@core", q{}, 'no packed module is core in perl 5.34' );
}

# The packed file runs with core modules alone and no installed Fugu
# (DIST-PACK-5, CLI-PROGRAM-1). The case runs the perl of the suite,
# and the perl 5.34 that macOS ships at /usr/bin/perl. The source
# floor is that perl (D-02).
my $floor;
{
	my %perl = ( $^X => 1 );
	$perl{'/usr/bin/perl'} = 1 if -x '/usr/bin/perl';

	for my $perl ( sort keys %perl ) {
		my $dirs = _core_dirs($perl);
		ok( defined $dirs && length $dirs, "$perl names its core directories" )
		    or next;

		my $release = _version($perl) // q{};
		$floor = $perl if $release =~ /\A5\.034/;
		my $home = tempdir( CLEANUP => 1 );

		# The prune holds: the same runner that starts the pack
		# finds no Fugu of the host.
		my $probe = _write( "$home/probe.pl",
			'print eval { require Fugu; 1 } ? "yes" : "no";' );
		my $absent = _pruned( $perl, $dirs, $home, $probe );
		is(
			$absent->{stdout}, 'no',
			"$perl $release loads no Fugu under the pruned \@INC"
		);

		my $r = _pruned( $perl, $dirs, $home, $packed, 'version' );
		is( $r->{exit_code}, 0, "$perl $release runs the pack" );
		is(
			$r->{stdout},
			sprintf( "fugubench %s (Fugu %s)\n", $VERSION, Fugu->VERSION ),
			"$perl $release prints the packed versions"
		);

		my $h = _pruned( $perl, $dirs, $home, $packed, '--help' );
		is( $h->{exit_code}, 0, "$perl $release runs the pack with --help" );
		like(
			$h->{stdout}, qr/^usage: fugubench /m,
			"$perl $release prints the usage of the pack"
		);
	}
}

SKIP: {
	skip 'no perl 5.34 on this host', 1 unless $floor;
	pass("$floor proves the pack on the source floor");
}

# The pack loads its own modules beside a checkout. build/fugubench
# sits beside lib/, and a decoy there must never run.
{
	my $dir = tempdir( CLEANUP => 1 );
	make_path( "$dir/build", "$dir/lib/App" );

	my $beside = "$dir/build/fugubench";
	copy( $packed, $beside ) or die "cannot copy the pack: $!\n";

	_write( "$dir/lib/App/FuguBench.pm",
		"package App::FuguBench;\n"
		    . qq{sub new { die "the decoy ran\\n" }\n}
		    . "1;\n" );

	my $r = Fugu::Process->run(
		cmd => [ $^X, $beside, 'version' ],
		env => _env( HOME => $dir ),
	);
	is( $r->{exit_code}, 0, 'the pack runs beside a checkout lib' );
	like(
		$r->{stdout}, qr/\Afugubench \Q$VERSION\E /,
		'the pack loads its own modules beside a checkout lib'
	);
}

done_testing();
