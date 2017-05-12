use Test::More tests => 11;

use Business::ISBN;

$|++;

my $GOOD_ISBN          = "9992701579";
my $GOOD_ISBN_STRING   = "99927-0-157-9";
my $GROUP              = "Albania";
my $GROUP_CODE         = "99927";
my $PUBLISHER          = "0";
my $ARTICLE_CODE       = "157";
my $CHECKSUM           = "9";

# test to see if we can construct an object?
my $isbn = Business::ISBN->new( $GOOD_ISBN );
isa_ok( $isbn, 'Business::ISBN10' );

ok( defined $isbn->_max_group_code_length, "Data module imported" );

use Data::Dumper;
#print STDERR Data::Dumper->Dump( [$isbn], [qw($isbn)] );

is( $isbn->is_valid, Business::ISBN::GOOD_ISBN, "$GOOD_ISBN is valid" );

is( $isbn->group_code,     $GROUP_CODE,         "$GOOD_ISBN has right group code");
is( $isbn->publisher_code, $PUBLISHER,          "$GOOD_ISBN has right publisher");
is( $isbn->group,          $GROUP,              "$GOOD_ISBN has right group");
is( $isbn->article_code,   $ARTICLE_CODE,       "$GOOD_ISBN has right article code" );
is( $isbn->checksum,       $CHECKSUM,           "$GOOD_ISBN has right checksum" );
is( $isbn->_checksum,      $CHECKSUM,           "$GOOD_ISBN has right checksum" );




is( $isbn->as_string,      $GOOD_ISBN_STRING,   "$GOOD_ISBN stringifies correctly");
is( $isbn->as_string([]),  $GOOD_ISBN,          "$GOOD_ISBN stringifies correctly");
