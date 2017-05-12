# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-FixedFormat.t'

use strict;
use warnings;

#########################

use Test::More tests => 41;
BEGIN { use_ok('Data::FixedFormat') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#$Test::Harness::verbose = 1;

# variables used throughout
my ($hash,$rec,$dff);

# reference variables
my $simple_ref = { FieldA=>'AAAAAA', FieldB=>'BBBB', FieldC=>'CCCC',
                   FieldD=>'DDDDDDDDDDDDDDDDDD' };
my $simple = 'AAAAAABBBBCCCCDDDDDDDDDDDDDDDDDD';

# simple record
$dff = Data::FixedFormat->new([ 'FieldA:A6', 'FieldB:A4',
                                'FieldC:A4', 'FieldD:A18' ]);

isa_ok ( $dff, 'Data::FixedFormat',
	'object has the proper class' );
ok ( $hash = $dff->unformat( $simple ),
	'unformat returns something' );
isa_ok ( $hash, 'HASH',
	'it is a hash' );
is ( scalar keys %$hash, scalar keys %$simple_ref,
	'correct number of keys returned' );
is ( $hash->{$_}, $simple_ref->{$_},
	"field $_ broken out correctly" ) for sort keys %$simple_ref;
ok ( $rec = $dff->format($hash),
	'format can convert back to a record' );
is ( $rec, $simple,
	'returned record matches original' );
$hash = undef;
$rec = undef;

SKIP: {
	skip('Tied interface not supported in this version', 9)
		if $Data::FixedFormat::VERSION < '0.03';
# tied interface
ok ( $hash = $dff->unformat_tied( $simple ),
	'unformat_tied returns something for simple format' );
isa_ok ( $hash, 'HASH',
	'it is a hash' );
ok ( defined(tied(%$hash)),
	'it is tied' );
isa_ok ( tied(%$hash), 'Data::FixedFormat::Tied',
	'tied to the right class' );
is ( scalar keys %$hash, scalar keys %$simple_ref,
	'correct number of keys returned' );
is ( $hash->{$_}, $simple_ref->{$_},
	"field $_ returned correctly" ) for sort keys %$simple_ref;
$hash = undef;
$rec = undef;
$dff = undef;
}

# reference variables
my $variant1_ref = { RecordType=>0, FieldA=>'AAAAAA',
                     FieldB=>['B1B1','B2B2','B3B3','B4B4'] };
my $variant2_ref = { RecordType=>1, FieldC=>'CCCC',
                     FieldD=>'DDDDDDDDDDDDDDDDDD' };
my $variant1 = '0AAAAAAB1B1B2B2B3B3B4B4';
my $variant2 = '1CCCCDDDDDDDDDDDDDDDDDD';

# variant record
$dff = Data::FixedFormat->new({
    Chooser => sub { my $rec=shift;
		     $rec->{RecordType} eq '0' ? 1 : 2
	           },
    Formats => [ [ 'RecordType:A1' ],
		 [ 'RecordType:A1', 'FieldA:A6', 'FieldB:A4:4' ],
		 [ 'RecordType:A1', 'FieldC:A4', 'FieldD:A18' ] ]
});

isa_ok ( $dff, 'Data::FixedFormat::Variants',
	'it is the right class' );

# variant 1
ok ( $hash = $dff->unformat($variant1),
	'unformat returns something for first variant' );
isa_ok ( $hash, 'HASH',
	'it is a hash' );
is ( scalar keys %$hash, scalar keys %$variant1_ref,
	'correct number of keys returned' );
is ( $hash->{$_}, $variant1_ref->{$_},
	"scalar field $_ returned correctly" ) for qw(RecordType FieldA);
is ( scalar @{$hash->{FieldB}}, scalar @{$variant1_ref->{FieldB}},
	'correct number of elements returned' );
is ( $hash->{FieldB}[$_], $variant1_ref->{FieldB}[$_],
	"array field FieldB[$_] returned correctly" ) for 0..3;
ok ( $rec = $dff->format($hash),
	'format can convert back to a record' );
is ( $rec, $variant1,
	'returned record matches original' );
$hash = undef;
$rec = undef;

# variant 2
ok ( $hash = $dff->unformat($variant2),
	'unformat returns something for second variant' );
isa_ok ( $hash, 'HASH',
	'it is a hash' );
is ( scalar keys %$hash, scalar keys %$variant2_ref,
	'correct number of keys returned' );
is ( $hash->{$_}, $variant2_ref->{$_},
	"scalar field $_ returned correctly" ) for qw(RecordType FieldC FieldD);
ok ( $rec = $dff->format($hash),
	'format can convert back to a record' );
is ( $rec, $variant2,
	'returned record matches original' );
$hash = undef;
$rec = undef;
$dff = undef;
