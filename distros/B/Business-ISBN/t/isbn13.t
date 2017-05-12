use strict;

use Test::More 'no_plan';

use Business::ISBN qw(:all);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $GOOD_ISBN          = "9780596527242";
my $GOOD_ISBN_STRING   = "978-0-596-52724-2";

my $GOOD_ISBN10        = "0596527241";

my $PREFIX             = "978";

my $GROUP              = "English";
my $GROUP_CODE         = "0";

my $PUBLISHER          = "596";

my $ARTICLE            = "52724";

my $CHECKSUM           = "2";

my $BAD_CHECKSUM_ISBN  = "9780596527244";

my $BAD_GROUP_ISBN     = "978-9990022576";

my $BAD_PUBLISHER_ISBN = "978-9165022222"; # 91-650-22222-?  Sweden (stops at 649)

my $NULL_ISBN          = undef;

my $NO_GOOD_CHAR_ISBN  = "978abcdefghij";

my $SHORT_ISBN         = "978156592";


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# test to see if we can construct an object?
{
my $isbn = Business::ISBN->new( $GOOD_ISBN );
isa_ok( $isbn, 'Business::ISBN13' );

#use Data::Dumper;
#print STDERR Data::Dumper->Dump( [$isbn], [qw($isbn)] );

is( $isbn->is_valid, GOOD_ISBN, "$GOOD_ISBN is valid" );

is( $isbn->prefix,         $PREFIX,           "$GOOD_ISBN has right prefix");

is( $isbn->group_code,     $GROUP_CODE,       "$GOOD_ISBN has right group code");
like( $isbn->group,        qr/\Q$GROUP/,      "$GOOD_ISBN has right group");

is( $isbn->publisher_code, $PUBLISHER,        "$GOOD_ISBN has right publisher");

is( $isbn->article_code,   $ARTICLE,          "$GOOD_ISBN has right article");

is( $isbn->checksum,       $CHECKSUM,         "$GOOD_ISBN has right checksum");

is( $isbn->as_string,      $GOOD_ISBN_STRING, "$GOOD_ISBN stringifies correctly");
is( $isbn->as_string([]),  $GOOD_ISBN,        "$GOOD_ISBN stringifies correctly");


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# can I clone it?
{
my $clone = $isbn->as_isbn13;

isa_ok( $clone, 'Business::ISBN13' );
is( $isbn->is_valid, GOOD_ISBN, "$GOOD_ISBN is valid" );

is( $isbn->prefix,         $PREFIX,           "$GOOD_ISBN has right prefix");

is( $isbn->group_code,     $GROUP_CODE,       "$GOOD_ISBN has right group code");
like( $isbn->group,        qr/\Q$GROUP/,      "$GOOD_ISBN has right group");

is( $isbn->publisher_code, $PUBLISHER,        "$GOOD_ISBN has right publisher");

is( $isbn->article_code,   $ARTICLE,          "$GOOD_ISBN has right article");

is( $isbn->checksum,       $CHECKSUM,         "$GOOD_ISBN has right checksum");

is( $isbn->as_string,      $GOOD_ISBN_STRING, "$GOOD_ISBN stringifies correctly");
is( $isbn->as_string([]),  $GOOD_ISBN,        "$GOOD_ISBN stringifies correctly");
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# can I make it ISBN10?
{
my $isbn = Business::ISBN->new( $GOOD_ISBN );
my $clone = $isbn->as_isbn10;

isa_ok( $clone, 'Business::ISBN10' );
is( $clone->is_valid,       GOOD_ISBN,         "$GOOD_ISBN is valid" );

is( $isbn->type,           'ISBN13',           "$GOOD_ISBN has right type");
is( $clone->prefix,         '',                "$GOOD_ISBN has right prefix");
is( $clone->publisher_code, $PUBLISHER,        "$GOOD_ISBN has right publisher");
is( $clone->group_code,     $GROUP_CODE,       "$GOOD_ISBN has right country code");
like( $clone->group,        qr/\Q$GROUP/,      "$GOOD_ISBN has right country");
is( $clone->as_string([]),  $GOOD_ISBN10,      "$GOOD_ISBN stringifies correctly");
}

}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# and bad checksums?
{
my $isbn = Business::ISBN->new( $BAD_CHECKSUM_ISBN );
isa_ok( $isbn, 'Business::ISBN13' );
is( $isbn->error, BAD_CHECKSUM, 
	"Bad checksum [$BAD_CHECKSUM_ISBN] is invalid" );

#after this we should have a good ISBN
$isbn->fix_checksum;

ok( $isbn->is_valid, 
	"Bad checksum [$BAD_CHECKSUM_ISBN] had checksum fixed" );
is( $isbn->as_string,      $GOOD_ISBN_STRING, "$GOOD_ISBN stringifies correctly");
is( $isbn->as_string([]),  $GOOD_ISBN,        "$GOOD_ISBN stringifies correctly");
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# bad country code?
{
my $isbn = Business::ISBN->new( $BAD_GROUP_ISBN );
isa_ok( $isbn, 'Business::ISBN13' );
is( $isbn->error, INVALID_GROUP_CODE, 
	"Bad group code [$BAD_GROUP_ISBN] is invalid" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# bad publisher code?
{
my $isbn = Business::ISBN->new( $BAD_PUBLISHER_ISBN );
isa_ok( $isbn, 'Business::ISBN13' );
is( $isbn->error, INVALID_PUBLISHER_CODE, 
	"Bad publisher [$BAD_PUBLISHER_ISBN] is invalid" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Am I prevented from doing bad things?

{
my $isbn = Business::ISBN->new( $GOOD_ISBN );
my $result = eval { $isbn->_set_prefix( '977' ) };
ok( defined $@, "Setting prefix 977 on ISBN-13 fails" );

{
my $result = eval { $isbn->_set_prefix( '' ) };
ok( defined $@, "Setting prefix '' on ISBN-13 fails" );
}
}

=pod

# do exportable functions do the right thing?
{
my $SHORT_ISBN = $GOOD_ISBN;
chop $SHORT_ISBN;

my $valid = Business::ISBN10::is_valid_checksum( $SHORT_ISBN );
is( $valid, Business::ISBN10::BAD_ISBN, "Catch short ISBN string" );
}


TODO: {
	local $TODO = "not implemented";
eval {
is( Business::ISBN10::is_valid_checksum( $GOOD_ISBN ),
	Business::ISBN10::GOOD_ISBN, 'is_valid_checksum with good ISBN' );
is( Business::ISBN10::is_valid_checksum( $BAD_CHECKSUM_ISBN ),
	Business::ISBN10::BAD_CHECKSUM, 'is_valid_checksum with bad checksum ISBN' );
is( Business::ISBN10::is_valid_checksum( $NULL_ISBN ),
	Business::ISBN10::BAD_ISBN, 'is_valid_checksum with bad ISBN' );
is( Business::ISBN10::is_valid_checksum( $NO_GOOD_CHAR_ISBN ),
	Business::ISBN10::BAD_ISBN, 'is_valid_checksum with no good char ISBN' );
is( Business::ISBN10::is_valid_checksum( $SHORT_ISBN ),
	Business::ISBN10::BAD_ISBN, 'is_valid_checksum with short ISBN' );
}
}

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
SKIP:
	{
	my $file = "isbn13s.txt";

	open FILE, $file or 
		skip( "Could not read $file: $!", 1, "Need $file");

	diag "\nChecking ISBN13s... (this may take a bit)";
	
	my $bad = 0;
	while( <FILE> )
		{
		chomp;
		my $isbn = Business::ISBN->new( $_ );
		
		my $result = $isbn->is_valid;
		my $text   = $Business::ISBN::ERROR_TEXT{ $result };
		
		$bad++ unless $result eq Business::ISBN::GOOD_ISBN;
		diag "\n\t$_ is not valid? [ $result -> $text ]\n" 
			unless $result eq Business::ISBN::GOOD_ISBN;	
		}
	
	close FILE;
	
	ok( $bad == 0, "Match good ISBNs" );
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
SKIP:
	{
	my $file = "bad-isbn13s.txt";

	open FILE, $file or 
		skip( "Could not read $file: $!", 1, "Need $file");

	diag "\nChecking bad ISBN13s... (this should be fast)";
	
	my $good = 0;
	my @good = ();
	
	while( <FILE> )
		{
		chomp;
		my $valid = eval { Business::ISBN->new( $_ )->is_valid };
		next unless $valid;
		
		push @good, $_;
		
		$good++;	
		}
	
	close FILE;

	{
	local $" = "\n\t";
	ok( $good == 0, "Don't match bad ISBNs" ) || 
		diag( "Matched $good bad ISBNs\n\t@good\n" );
	}
	
	}
