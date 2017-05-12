#!perl -I./t

$| = 1;

use strict;
use warnings;
use DBI qw(:sql_types);
use DBD_TEST();

use Test::More;

if (defined $ENV{DBI_DSN}) {
  plan tests => 53;
} else {
  plan skip_all => 'Cannot test without DB info';
}

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
ok ( defined $dbh,'Connection');

my @test_sets;
for my $t ( SQL_LONGVARCHAR, SQL_WLONGVARCHAR(), SQL_LONGVARBINARY() ) { # SQL_VARCHAR,
  my @ti = $dbh->type_info( $t );
  for my $ti ( @ti ) {
    my $tn = $ti->{TYPE_NAME};
    next if $tn =~ m/nclob/i;
    next if $tn =~ m/raw/i;
    next if $tn =~ m/^lo$/i;
    print "# Using $tn for $t\n";
    push @test_sets, [ $tn, $t ];
    last;
  }
  last if @test_sets; # TODO: remove?
}
# TODO:
my $tests_per_set = 35;
my $tests = @test_sets * $tests_per_set;

# Set size of test data (in 10KB units)
# Minimum value 3 (else tests fail because of assumptions)
# Normal  value 8 (to test 64KB threshold well)
my $sz = 8;

my $tbl = $DBD_TEST::table_name;


run_long_tests( @$_ ) for @test_sets;

sub run_long_tests {
  my ($tn2, $type2) = @_;
  my ($sth, $p1, $row);
  my $LongReadLen;
  my $type1 = DBD_TEST::get_type_for_column( $dbh,'A')->{DATA_TYPE};

# relationships between these lengths are important # e.g.
my $val0 = ("0\177x\0X"  x 2048) x (1    );  # 10KB  < 64KB
my $val1 = ('1234567890' x 1024) x ($sz  );  # 80KB >> 64KB && > val2
my $val2 = ('2bcdefabcd' x 1024) x ($sz-1);  # 70KB  > 64KB && < val1

# special hack for val0 since RAW types need pairs of HEX
$val0 = '00FF' x ( length $val0 / 2 ) if $tn2 =~ /RAW/i;

my $len0 = length $val0; # print "# val0 length $len0\n";
my $len1 = length $val1; # print "# val1 length $len1\n";
my $len2 = length $val2; # print "# val2 length $len2\n";

# warn if some of the key aspects of the data sizing are tampered with
warn "val0 is >  64KB : $len0\n"          if $len0 >  65535;
warn "val1 is <  64KB : $len1\n"          if $len1 <  65535;
warn "val2 is >= $val1: $len2 >= $len1\n" if $len2 >= $len1;


if (!DBD_TEST::tab_long_create( $dbh, $type2 ) ) {
  warn "Unable to create test table for '$tn2' data ($DBI::err). Tests skipped.\n";
  ok(0) for 1..$tests_per_set;
  return;
}

ok( $sth = $dbh->prepare("INSERT INTO $tbl( A, C ) VALUES( ?, ? )"),"Insert some $tn2 data");

$sth->bind_param( 1,    40, { TYPE => $type1 } ) or die $DBI::errstr;
$sth->bind_param( 2, $val0, { TYPE => $type2 } ) or die $DBI::errstr;
ok( $sth->execute,'Inserted data');

$sth->bind_param( 1,    41, { TYPE => $type1 } ) or die $DBI::errstr;
$sth->bind_param( 2, $val1, { TYPE => $type2 } ) or die $DBI::errstr;
ok( $sth->execute,'Inserted data');

$sth->bind_param( 1,    42, { TYPE => $type1 } ) or die $DBI::errstr;
$sth->bind_param( 2, $val2, { TYPE => $type2 } ) or die $DBI::errstr;
ok( $sth->execute,'Inserted data');


pass("Fetch $tn2 data back again -- truncated - LongTruncOk == 1");

$LongReadLen = 20;
$dbh->{LongReadLen} = $LongReadLen;
is( $dbh->{LongReadLen}, $LongReadLen,"LongReadLen (dbh): $LongReadLen");
$dbh->{LongTruncOk} =  1;
ok( $dbh->{LongTruncOk},'LongTruncOk (dbh): 1');

# This behaviour is not specified anywhere, sigh:
my $out_len  = $dbh->{LongReadLen};
   $out_len *= 2 if $tn2 =~ /RAW/i;

ok( $sth = $dbh->prepare("SELECT A, C FROM $tbl ORDER BY A"),'prepare');
is( $sth->{LongReadLen}, $LongReadLen,"LongReadLen (sth): $LongReadLen");
ok( $sth->{LongTruncOk},'LongTruncOk (sth): 1');
ok( $sth->execute,'execute');
ok( $row = $sth->fetchall_arrayref,'fetch');
is(     $row->[0][1], substr( $val0, 0, $out_len ),
  cdif( $row->[0][1], substr( $val0, 0, $out_len ) ) );
is(     $row->[1][1], substr( $val1, 0, $out_len ),
  cdif( $row->[1][1], substr( $val1, 0, $out_len ) ) );
is(     $row->[2][1], substr( $val2, 0, $out_len ),
  cdif( $row->[2][1], substr( $val2, 0, $out_len ) ) );


pass("Fetch $tn2 data back again -- truncated - LongTruncOk == 0");

$LongReadLen = $len1 - 10; # so $val0 fits but val1 does not
$LongReadLen = $dbh->{LongReadLen} / 2 if $tn2 =~ /RAW/i;  # /
$dbh->{LongReadLen} = $LongReadLen;
is( $dbh->{LongReadLen}, $LongReadLen,"LongReadLen (dbh): $LongReadLen");
$dbh->{LongTruncOk} = 0;
ok(!$dbh->{LongTruncOk},'LongTruncOk (dbh): 0');

ok( $sth = $dbh->prepare("SELECT A, C FROM $tbl ORDER BY A"),'prepare');
is( $sth->{LongReadLen}, $LongReadLen,"LongReadLen (sth): $LongReadLen");
ok(!$sth->{LongTruncOk},'LongTruncOk (sth): 0');
ok( $sth->execute,'execute');

ok( $row = $sth->fetch,'fetch');
is( $row->[1], $val0,'compare length : '. length $row->[1] );

$sth->{PrintError} = 0;
ok( !defined $sth->fetch,'truncation error: '
  ."LongReadLen $dbh->{LongReadLen}, data ". length $row->[1] );
$sth->{PrintError} = 1;
is( $sth->err, -920,'error number');


pass("Fetch $tn2 data back again -- complete - LongTruncOk == 0");

$LongReadLen = $len1 * 2; # + 1000
$dbh->{LongReadLen} = $LongReadLen;
is( $dbh->{LongReadLen}, $LongReadLen,"LongReadLen (dbh): $LongReadLen");
$dbh->{LongTruncOk} = 0;
ok(!$dbh->{LongTruncOk},'LongTruncOk (dbh): 0');

ok( $sth = $dbh->prepare("SELECT A, C FROM $tbl ORDER BY A"),'prepare');
is( $sth->{LongReadLen}, $LongReadLen,"LongReadLen (sth): $LongReadLen");
ok(!$sth->{LongTruncOk},'LongTruncOk (sth): 0');
ok( $sth->execute,'execute');

ok( $row = $sth->fetch,'fetch');
is( $row->[1], $val0,'compare length: '. length $row->[1] );

ok( $row = $sth->fetch,'fetch');
is( $row->[1], $val1,'compare length: '. length $row->[1] );

ok( $row = $sth->fetch,'fetch');
is( $row->[1], $val2,'compare length: '. length $row->[1] );
# ok( length $row->[1] == length $val1
#  and substr( $row->[1], 0, length $val2 ) eq $val2,'data match');
# is( $row->[1], $val2, " compare lengths: ". cdif( $row->[1], $val2 ) );


pass("Fetch $tn2 data back again -- via blob_read");

$dbh->{LongReadLen} = 0;
$dbh->{LongTruncOk} = 1;

ok( $sth = $dbh->prepare("SELECT A, C FROM $tbl ORDER BY A"),'prepare');
ok( $sth->execute,'execute');

ok( $row = $sth->fetch,'fetch');
is( blob_read_all( $sth, 1, \$p1,  4096 ), length $val0,'blob_read_all: '. $row->[0] );
is( $p1, $val0,'compare differences: '. cdif( $p1, $val0 ) );

ok( $row = $sth->fetch,'fetch');
is( blob_read_all( $sth, 1, \$p1, 12345 ), length $val1,'blob_read_all: '. $row->[0] );
is( $p1, $val1,'compare differences: '. cdif( $p1, $val1 ) );

ok( $row = $sth->fetch,'fetch');
is( blob_read_all( $sth, 1, \$p1, 34567 ), length $val2,'blob_read_all: '. $row->[0] );
is( $p1, $val2,'compare differences: '. cdif( $p1, $val2 ) );

#my $len = blob_read_all( $sth, 1, \$p1, 34567 );
# if ( $len == length $val2 ) {
#   is( $len, length $val2, ' length compare: '. length $len );
#   # Oracle may return the right length but corrupt the string.
#   is( $p1, $val2, cdif( $p1, $val2 ) );
# }
# elsif ( $len == length $val1 && substr( $p1, 0, length $val2 ) eq $val2 ) {
#   pass( "Length correct" );
# }
# else {
#   fail("Fetched length $len, expected ". length $val2 );
# }

  $sth->finish;
  $dbh->do("DROP TABLE $tbl");
} # end of run_long_tests

ok( $dbh->disconnect,'Disconnect');

# -----------------------------------------------------------------------------

sub blob_read_all {
  my ($sth, $field_idx, $blob_ref, $lump) = @_;

  $lump ||= 4096; # use benchmarks to get best value for you
  my $offset = 0;
  my @frags;
  while ( 1 ) {
    my $frag = $sth->blob_read( $field_idx, $offset, $lump );
    return unless defined $frag;
    my $len = length $frag;
    last unless $len;
    push @frags, $frag;
    $offset += $len;
  }
  $$blob_ref = join '', @frags;
  return length $$blob_ref;
}

sub unc {
  my @str = @_;
  for ( @str ) { s/([\000-\037\177-\377])/ sprintf "\\%03o", ord($_) /eg; }
  return join '', @str unless wantarray;
  return @str;
}

sub cdif {
  my ($s1, $s2, $msg) = @_;
  $msg = ($msg) ? ", $msg" : '';
  my ($l1, $l2) = ( length $s1, length $s2 );
  return "Strings are identical, length=$l1 $msg" if $s1 eq $s2;
  return "Strings are of different lengths ($l1 vs $l2) $msg" # check substr matches?
    if $l1 != $l2;
  my $i;
  for ( $i = 0; $i < $l1; ++$i ) {
    my ($c1,$c2) = (ord(substr($s1,$i,1)), ord(substr($s2,$i,1)));
    next if $c1 == $c2;
    return sprintf "Strings differ at position %d (\\%03o vs \\%03o) $msg",
      $i,$c1,$c2;
  }
  return "(cdif error $l1/$l2/$i)";
}
