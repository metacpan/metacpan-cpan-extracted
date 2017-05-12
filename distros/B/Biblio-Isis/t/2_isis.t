#!/usr/bin/perl -w

use strict;
use blib;

use Test::More tests => 181;
use File::Spec;

BEGIN {
	use_ok( 'Biblio::Isis' );
	eval "use Data::Dump";

	if (! $@) {
		*Dumper = *Data::Dump::dump;
	} else {
		use Data::Dumper;
	}
}


my $debug = length( shift(@ARGV) || '' );
my $isis;

my $path_winisis = File::Spec->catfile('data', 'winisis', 'BIBL');
my $path_isismarc = File::Spec->catfile('data', 'isismarc', 'BIBL');

sub test_data {

	my $args = {@_};

	isa_ok ($isis, 'Biblio::Isis');

	cmp_ok($isis->count, '==', 5, "count is 5");

	# test .CNT data

	SKIP: {
		skip "no CNT file for this database", 5 unless $isis->{cnt_file};

		ok(my $isis_cnt = $isis->read_cnt, "read_cnt");

		cmp_ok(scalar keys %{$isis_cnt}, '==', 2, "returns 2 elements");

		my $cnt = {
			'1' => {
				'N' => 15,
				'K' => 5,
				'FMAXPOS' => 8,
				'POSRX' => 1,
				'ABNORMAL' => 1,
				'ORDN' => 5,
				'LIV' => 0,
				'ORDF' => 5,
				'NMAXPOS' => 1
				},
			'2' => {
				'N' => 15,
				'K' => 5,
				'FMAXPOS' => 4,
				'POSRX' => 1,
				'ABNORMAL' => 0,
				'ORDN' => 5,
				'LIV' => 0,
				'ORDF' => 5,
				'NMAXPOS' => 1
				}
		};

		foreach my $c (keys %{$cnt}) {
			foreach my $kn (keys %{$cnt->{$c}}) {
				cmp_ok($isis_cnt->{$c}->{$kn}, '==', $cnt->{$c}->{$kn}, "cnt $c $kn same");
			}
		}
	}

	# test fetch

	my $data = [ {
		'801' => [ '^aFFZG' ],
		'702' => [ '^aHolder^bElizabeth' ],
		'990' => [ '2140', '88', 'HAY' ],
		'675' => [ '^a159.9' ],
		'210' => [ '^aNew York^cNew York University press^dcop. 1988' ],
	}, {
		'210' => [ '^aNew York^cUniversity press^d1989' ],
		'700' => [ '^aFrosh^bStephen' ],
		'990' => [ '2140', '89', 'FRO' ],
		'200' => [ '^aPsychoanalysis and psychology^eminding the gap^fStephen Frosh' ],
		'215' => [ '^aIX, 275 str.^d23 cm' ],
	}, {
		'210' => [ '^aLondon^cFree Associoation Books^d1992' ],
		'700' => [ '^aTurkle^bShirlie' ],
		'990' => [ '2140', '92', 'LAC' ],
		'200' => [ '^aPsychoanalitic politics^eJacques Lacan and Freud\'s French Revolution^fSherry Turkle' ],
		'686' => [ '^a2140', '^a2140' ],
	
	}, {
		'700' => [ '^aGross^bRichard' ],
		'200' => [ '^aKey studies in psychology^fRichard D. Gross' ],
		'210' => [ '^aLondon^cHodder & Stoughton^d1994' ],
		'10' => [ '^a0-340-59691-0' ],
	}, {
		# identifier test
		'200' => [ '1#^aPsychology^fCamille B. Wortman, Elizabeth F. Loftus, Mary E. Marshal' ],
		225 => ["1#^aMcGraw-Hill series in Psychology"],
		205 => ["^a4th ed"],
	} ];
		
	foreach my $mfn (1 .. $isis->count) {

		my $rec;
		ok($rec = $isis->fetch($mfn), "fetch $mfn");

		diag "<<<<< rec = ",Dumper( $rec ), "\n>>>>> data = ", Dumper( $data->[$mfn-1] ) if ($debug);

		foreach my $f (keys %{$data->[$mfn-1]}) {
			my $i = 0;
			foreach my $v (@{$data->[$mfn-1]->{$f}}) {
				$v =~ s/^[01# ][01# ]// if ($args->{no_ident});
				diag "compare '", $rec->{$f}->[$i], "' eq '$v'" if ($debug);
				cmp_ok($rec->{$f}->[$i], 'eq', $v, "MFN $mfn field: $f offset: $i");
				$i++;
			}
		}

		cmp_ok($isis->mfn, '==', $mfn, 'mfn');

	}

	# test to_ascii

	SKIP: {
		eval "use Digest::MD5 qw(md5_hex)";

		skip "no Digest::MD5 module", 5 if ($@);

		foreach my $mfn (1 .. $isis->count) {
			my $md5 = md5_hex($isis->to_ascii($mfn));
			cmp_ok($md5, 'eq', $args->{md5_ascii}[$mfn - 1], "md5 $mfn");
		}
	}

}

$isis = Biblio::Isis->new (
	isisdb => $path_winisis,
	include_deleted => 1,
	debug => $debug > 1 ? ($debug - 1) : 0,
);

diag "new Biblio::Isis = ", Dumper($isis) if ($debug);

test_data(
	no_ident => 1,
	md5_ascii => [ qw(
		a369eff702307ba12eb81656ee0587fe
		4fb38537a94f3f5954e40d9536b942b0
		579a7c6901c654bdeac10547a98e5b71
		7d2adf1675c83283aa9b82bf343e3d85
		4cc1f798bbcf36862f7aa78c3410801a
	) ],
);

$isis = Biblio::Isis->new (
	isisdb => $path_isismarc,
	include_deleted => 1,
);

test_data(
	md5_ascii => [ qw(
		f5587d9bcaa54257a98fe27d3c17a0b6
		3be9a049f686f2a36af93a856dcae0f2
		3961be5e3ba8fb274c89c08d18df4bcc
		5f73ec00d08af044a2c4105f7d889e24
		843b9ebccf16a498fba623c78f21b6c0
	) ],
);

# check logically deleted

$isis = Biblio::Isis->new (
	isisdb => $path_winisis,
	include_deleted => 1,
);

ok($isis->fetch(3), "deleted found");
cmp_ok($isis->{deleted}, '==', 3, "MFN 3 is deleted");
ok($isis->{record}, "record exists");

diag "record = ",Dumper($isis->{record}) if ($debug);

$isis = Biblio::Isis->new (
	isisdb => $path_winisis,
	debug => $debug,
	hash_filter => sub {
		my ($l,$nr) = @_;
		ok(grep(/$nr/, keys %{ $isis->{record} }), "hash_filter $nr in record");
		ok(grep(/\Q$l\E/, @{ $isis->{record}->{$nr} }), "hash_filter line $l found");
		return($l);
	},
);

ok(! $isis->fetch(3), "deleted not found");
cmp_ok($isis->{deleted}, '==', 3, "MFN 3 is deleted");
ok(! $isis->{record}, 'no record');

$isis->{record} = {
	900 => [ '^a900a^b900b^c900c' ],
	901 => [
		'^a901a-1^b901b-1^c901c-1',
		'^a901a-2^b901b-2',
		'^a901a-3',
	],
	902 => [
		'^aa1^aa2^aa3^bb1^aa4^bb2^cc1^aa5',
	],
};
$isis->{current_mfn} = 42;

ok(my $hash = $isis->to_hash( $isis->mfn ), 'to_hash');
diag "to_hash = ",Dumper( $hash ) if ($debug);
is_deeply( $hash, {
	"000" => [42],
	900   => [{ a => "900a", b => "900b", c => "900c" }],
	901   => [
		{ a => "901a-1", b => "901b-1", c => "901c-1" },
		{ a => "901a-2", b => "901b-2" },
		{ a => "901a-3" },
	],
	902   => [
		{ a => ["a1", "a2", "a3", "a4", "a5"], b => ["b1", "b2"], c => "c1" },
	],
}, 'hash is_deeply');

ok(my $ascii = $isis->to_ascii( $isis->mfn ), 'to_ascii');
diag "to_ascii = \n", $ascii if ($debug);
cmp_ok($ascii, 'eq', <<'__END_OF_ASCII__', 'to_ascii output');
0	42
900	^a900a^b900b^c900c
901	^a901a-1^b901b-1^c901c-1
901	^a901a-2^b901b-2
901	^a901a-3
902	^aa1^aa2^aa3^bb1^aa4^bb2^cc1^aa5
__END_OF_ASCII__

ok(my $hash2 = $isis->to_hash({ mfn => $isis->mfn }), 'to_hash(mfn)');
is_deeply( $hash2, $hash, 'same hash' );

# test to_hash( include_subfields )
ok($hash = $isis->to_hash({ mfn => $isis->mfn, include_subfields => 1 }), 'to_hash(mfn,include_subfields)');
diag "to_hash = ",Dumper( $hash ) if ($debug);
is_deeply( $hash, {
  "000" => [42],
  900   => [
	{ a => "900a", b => "900b", c => "900c", subfields => ["a", 0, "b", 0, "c", 0] },
  ],
  901   => [
	{ a => "901a-1", b => "901b-1", c => "901c-1", subfields => ["a", 0, "b", 0, "c", 0] },
	{ a => "901a-2", b => "901b-2", subfields => ["a", 0, "b", 0] },
	{ a => "901a-3", subfields => ["a", 0] },
  ],
  902   => [
	{ a => ["a1", "a2", "a3", "a4", "a5"], b => ["b1", "b2"], c => "c1",
	  subfields => ["a", 0, "a", 1, "a", 2, "b", 0, "a", 3, "b", 1, "c", 0, "a", 4],
	},
  ],
}, 'hash is_deeply');

# test to_hash( join_subfields_with )
ok($hash = $isis->to_hash({ mfn => $isis->mfn, join_subfields_with => ' ; ' }), 'to_hash(mfn,join_subfields_with)');
diag "to_hash = ",Dumper( $hash ) if ($debug);
is_deeply( $hash, {
   "000" => [42],
   900   => [{ a => "900a", b => "900b", c => "900c" }],
   901   => [
              { a => "901a-1", b => "901b-1", c => "901c-1" },
              { a => "901a-2", b => "901b-2" },
              { a => "901a-3" },
            ],
   902   => [{ a => "a1 ; a2 ; a3 ; a4 ; a5", b => "b1 ; b2", c => "c1" }],
}, 'hash is_deeply');

my $isis2;
ok($isis2 = Biblio::Isis->new (
	isisdb => $path_winisis,
	join_subfields_with => ' ; ',
),"new( join_subfields_with )");
ok($isis2->{record} = $isis->{record}, "copy record");
ok($isis2->{current_mfn} = $isis->{current_mfn}, "copy current_mfn");

ok($hash = $isis2->to_hash( $isis->mfn ), 'to_hash(mfn)');
diag "to_hash = ",Dumper( $hash ) if ($debug);
is_deeply( $hash, {
   "000" => [42],
   900   => [{ a => "900a", b => "900b", c => "900c" }],
   901   => [
              { a => "901a-1", b => "901b-1", c => "901c-1" },
              { a => "901a-2", b => "901b-2" },
              { a => "901a-3" },
            ],
   902   => [{ a => "a1 ; a2 ; a3 ; a4 ; a5", b => "b1 ; b2", c => "c1" }],
}, 'hash is_deeply');

# test to_hash( hash_filter )
ok($hash = $isis->to_hash({ mfn => $isis->mfn, hash_filter => sub {
	my ($l,$f) = @_;
	if ($f == 900) {
		$l =~ s/0/o/g;
	} elsif ($f == 901) {
		$l =~ s/1/i/g;
	} elsif ($f == 902) {
		$l =~ s/2/s/g;
	}
	return $l;
}}), 'to_hash(mfn,hash_filter)');
diag "to_hash = ",Dumper( $hash ) if ($debug);
is_deeply( $hash, {
   "000" => [42],
   900   => [{ a => "9ooa", b => "9oob", c => "9ooc" }],
   901   => [
              { a => "90ia-i", b => "90ib-i", c => "90ic-i" },
              { a => "90ia-2", b => "90ib-2" },
              { a => "90ia-3" },
            ],
   902   => [{ a => ["a1", "as", "a3", "a4", "a5"], b => ["b1", "bs"], c => "c1" }],
}, 'hash is_deeply');

