use strict;
use warnings;

use Test::More tests => 128;
use CDB_File;

my $good_file_db   = 'good.cdb';
my $good_file_temp = 'good.tmp';

my %h;
ok( !( tie( %h, "CDB_File", 'nonesuch.cdb' ) ), "Tie non-existant file" );

open OUT, '> bad.cdb';
close OUT;
ok( ( tie( %h, "CDB_File", 'bad.cdb' ) ), "Load blank cdb file (invalid file, but loading it works)" );

eval { print $h{'one'} };
like( $@, qr/^Read of CDB_File failed:/, "Test that attempt to read incorrect file fails" );

untie %h;
cleanup_cdb('bad');

my %a = qw(one Hello two Goodbye);
eval { CDB_File::create( %a, $good_file_db, $good_file_temp ) or die "Failed to create cdb: $!" };
is( "$@", '', "Create cdb" );

# Test that good file works.
tie( %h, "CDB_File", $good_file_db ) and pass("Test that good file works");

my $t = tied %h;
isa_ok( $t, "CDB_File" );
is( $t->FETCH('one'), 'Hello', "Test that good file FETCHes right results" );

is( $h{'one'}, 'Hello', "Test that good file hash access gets right results" );

ok( !defined( $h{'1'} ), "Check defined() non-existant entry works" );

ok( exists( $h{'two'} ), "Check exists() on a real entry works" );

ok( !exists( $h{'three'} ), "Check exists() on non-existant entry works" );

# Test low level access.
my $fh = $t->handle;
my $x;

exists( $h{'one'} );    # go to this entry
print "# Datapos: ", $t->datapos, ", Datalen: ", $t->datalen, "\n";
sysseek( $fh, $t->datapos, 0 );
sysread( $fh, $x, $t->datalen );
is( $x, 'Hello', "Check low level access read worked" );

exists( $h{'two'} );
print "# Datapos: ", $t->datapos, ", Datalen: ", $t->datalen, "\n";
sysseek( $fh, $t->datapos, 0 );
sysread( $fh, $x, $t->datalen );
is( $x, 'Goodbye', "Check low level access read worked" );

exists( $h{'three'} );
print "# Datapos: ", $t->datapos, ", Datalen: ", $t->datalen, "\n";
is( $t->datapos, 0, "Low level access on no-exist entry" );
is( $t->datalen, 0, "Low level access on no-exist entry" );

my @h = sort keys %h;
is( scalar @h, 2,     "keys length == 2" );
is( $h[0],     'one', "first key right" );
is( $h[1],     'two', "second key right" );

eval { $h{'four'} = 'foo' };
like( $@, qr/Modification of a CDB_File attempted/, "Check modifying throws exception" );

eval { delete $h{'five'} };
like( $@, qr/Modification of a CDB_File attempted/, "Check modifying throws exception" );

close $fh;    # Duped file handle must be closed.
undef $t;
untie %h;     # Release the tie so the file closes and we can remove it.
cleanup_cdb('good');

# Test empty file.
%a = ();
eval { CDB_File::create( %a, 'empty.cdb', 'empty.tmp' ) || die "CDB create failed" };
is( !$@, 1, "No errors creating cdb" );

ok( ( tie( %h, "CDB_File", 'empty.cdb' ) ), "Tie new empty cdb" );

@h = keys %h;
is( scalar @h, 0, "Empty cdb has no keys" );

untie %h;
cleanup_cdb('empty');

# Test failing new.
ok( !CDB_File->new( '..', '.' ), "Creating cdb with dirs fails" );

# Test file with repeated keys.
my $tmp = 'repeat.tmp';
my $cdbm = CDB_File->new( 'repeat.cdb', $tmp );
isa_ok( $cdbm, 'CDB_File::Maker' );

$cdbm->insert( 'dog',    'perro' );
$cdbm->insert( 'cat',    'gato' );
$cdbm->insert( 'cat',    'chat' );
$cdbm->insert( 'dog',    'chien' );
$cdbm->insert( 'rabbit', 'conejo' );

$tmp = 'ERROR!';    # Test that name was stashed correctly.

$cdbm->finish;
undef $cdbm;

$t = tie %h, "CDB_File", 'repeat.cdb';
isa_ok( $t, 'CDB_File' );

eval { $t->NEXTKEY('dog') };

# ok($@, qr/^Use CDB_File::FIRSTKEY before CDB_File::NEXTKEY/, "Test that NEXTKEY can't be used immediately after TIEHASH");
is( $@, '', "Test that NEXTKEY can be used immediately after TIEHASH" );

# Check keys/values works
my @k = keys %h;
my @v = values %h;
is( $k[0], 'dog' );
is( $v[0], 'perro' );
is( $k[1], 'cat' );
is( $v[1], 'gato' );
is( $k[2], 'cat' );
is( $v[2], 'chat' );
is( $k[3], 'dog' );
is( $v[3], 'chien' );
is( $k[4], 'rabbit' );
is( $v[4], 'conejo' );

@k = ();
@v = ();

# Check each works
while ( my ( $k, $v ) = each %h ) {
    push @k, $k;
    push @v, $v;
}
is( $k[0], 'dog' );
is( $v[0], 'perro' );
is( $k[1], 'cat' );
is( $v[1], 'gato' );
is( $k[2], 'cat' );
is( $v[2], 'chat' );
is( $k[3], 'dog' );
is( $v[3], 'chien' );
is( $k[4], 'rabbit' );
is( $v[4], 'conejo' );

my $v = $t->multi_get('cat');
is( @$v, 2, "multi_get returned 2 entries" );
is( $v->[0], 'gato' );
is( $v->[1], 'chat' );

$v = $t->multi_get('dog');
is( @$v, 2, "multi_get returned 2 entries" );
is( $v->[0], 'perro' );
is( $v->[1], 'chien' );

$v = $t->multi_get('rabbit');
is( @$v, 1, "multi_get returned 1 entry" );
is( $v->[0], 'conejo' );

$v = $t->multi_get('foo');
is( ref($v), 'ARRAY', "multi_get on non-existant entry works" );
is( @$v, 0 );

while ( my ( $k, $v ) = each %h ) {
    $v = $t->multi_get($k);

    ok( $v->[0] eq 'gato'  and $v->[1] eq 'chat' )  if $k eq 'cat';
    ok( $v->[0] eq 'perro' and $v->[1] eq 'chien' ) if $k eq 'dog';
    ok( $v->[0] eq 'conejo' ) if $k eq 'rabbit';
}

# Test undefined keys.
{

    my $warned = 0;
    local $SIG{__WARN__} = sub { $warned = 1 if $_[0] =~ /^Use of uninitialized value/ };
    local $^W = 1;

    my $x;
    ok( !defined $h{$x} );
  SKIP: {
        skip 'Perl 5.8.2 and below do not warn about $x{undef}', 1 unless $] > 5.008003;
        ok($warned);
    }

    $warned = 0;
    ok( !exists $h{$x} );
  SKIP: {
        skip 'Perl 5.6 does not warn about $x{undef}', 1 unless $] > 5.007;
        ok($warned);
    }

    $warned = 0;
    my $v = $t->multi_get('rabbit');
    ok($v);
    ok( !$warned );
}

# Check that object is readonly.
eval { $$t = 'foo' };
like( $@, qr/^Modification of a read-only value/, "Check object (\$t) is read only" );
is( $h{'cat'}, 'gato' );

undef $t;
untie %h;
cleanup_cdb('repeat');

# Regression test - dumps core in 0.6.
%a = ( 'one', '' );
ok( ( CDB_File::create( %a, $good_file_db, $good_file_temp ) ), "Create good.cdb" );
ok( ( tie( %h, "CDB_File", $good_file_db ) ), "Tie good.cdb" );
ok( !exists $h{'zero'}, "missing key test" );

ok( defined( $h{'one'} ), "one is found and defined" );
is( $h{'one'}, '', "one is empty" );

untie %h;    # Release the tie so the file closes and we can remove it.
cleanup_cdb('good');

# Test numeric data (broken before 0.8)
my $h = CDB_File->new( 't.cdb', 't.tmp' );
isa_ok( $h, 'CDB_File::Maker' );
$h->insert( 1, 1 * 23 );
ok( $h->finish );
ok( tie( %h, "CDB_File", 't.cdb' ) );
is( $h{1}, 23, "Numeric comparison works" );

untie %h;
cleanup_cdb('t');

# Test zero value with multi_get (broken before 0.85)
$h = CDB_File->new( 't.cdb', 't.tmp' );
isa_ok( $h, 'CDB_File::Maker' );
$h->insert( 'x', 0 );
$h->insert( 'x', 1 );
ok( $h->finish );
$t = tie( %h, "CDB_File", 't.cdb' );
isa_ok( $t, 'CDB_File' );
$x = $t->multi_get('x');
is( @$x,     2 );
is( $x->[0], 0 );
is( $x->[1], 1 );

undef $t;
untie %h;
cleanup_cdb('t');

$h = CDB_File->new( 't.cdb', 't.tmp' );
isa_ok( $h, 'CDB_File::Maker' );
for ( my $i = 0; $i < 10; ++$i ) {
    $h->insert( $i, $i );
}
ok( $h->finish );
undef $h;

$t = tie( %h, "CDB_File", 't.cdb' );
isa_ok( $t, 'CDB_File' );

for ( my $i = 0; $i < 10; ++$i ) {
    my ( $k, $v ) = each %h;
    if ( $k == 2 ) {
        ok( exists( $h{4} ) );
    }
    if ( $k == 5 ) {
        ok( !exists( $h{23} ) );
    }
    if ( $k == 7 ) {
        my $m = $t->multi_get(3);
        is( @$m,     1 );
        is( $m->[0], 3 );
    }
    is( $k, $i, "$k eq $i" );
    is( $v, $i, "$v eq $i" );
}
undef $t;
untie %h;
cleanup_cdb('t');

sub cleanup_cdb {
    my $file = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    unlink "$file.cdb", "$file.tmp";
    ok( !-e $_, "Remove $_" ) foreach ( "$file.cdb", "$file.tmp" );
}
