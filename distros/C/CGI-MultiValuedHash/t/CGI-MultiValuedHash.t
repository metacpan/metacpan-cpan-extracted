# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/CGI-MultiValuedHash.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..45\n"; }
END {print "not ok 1\n" unless $loaded;}
use CGI::MultiValuedHash 1.09;
$loaded = 1;
print "ok 1\n";
use strict;
use warnings;

# Set this to 1 to see complete result text for each test
my $verbose = shift( @ARGV ) ? 1 : 0;  # set from command line

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

######################################################################
# Here are some utility methods:

my $test_num = 1;  # same as the first test, above

sub result {
	$test_num++;
	my ($worked, $detail) = @_;
	$verbose or 
		$detail = substr( $detail, 0, 50 ).
		(length( $detail ) > 47 ? "..." : "");	
	print "@{[$worked ? '' : 'not ']}ok $test_num $detail\n";
}

sub message {
	my ($detail) = @_;
	print "-- $detail\n";
}

sub vis {
	my ($str) = @_;
	$str =~ s/\n/\\n/g;  # make newlines visible
	$str =~ s/\t/\\t/g;  # make tabs visible
	return( $str );
}

sub serialize {
	my ($input,$is_key) = @_;
	return( join( '', 
		ref($input) eq 'HASH' ? 
			( '{ ', ( map { 
				( serialize( $_, 1 ), serialize( $input->{$_} ) ) 
			} sort keys %{$input} ), '}, ' ) 
		: ref($input) eq 'ARRAY' ? 
			( '[ ', ( map { 
				( serialize( $_ ) ) 
			} @{$input} ), '], ' ) 
		: defined($input) ?
			"'$input'".($is_key ? ' => ' : ', ')
		: "undef".($is_key ? ' => ' : ', ')
	) );
}

######################################################################

message( "START TESTING CGI::MultiValuedHash" );

######################################################################
# test url decode/encode methods

{
	message( "testing url decode/encode methods" );

	my ($mvh, $did, $should);

	my @src_list_hash = (
		{
			visible_title => "What's your name?",
			type => 'textfield',
			name => 'name',
		}, {
			visible_title => "What's the combination?",
			type => 'checkbox_group',
			name => 'words',
			'values' => ['eenie', 'meenie', 'minie', 'moe'],
			default => ['eenie', 'minie'],
		}, {
			visible_title => "What's your favorite colour?",
			type => 'popup_menu',
			name => 'color',
			'values' => ['red', 'green', 'blue', 'chartreuse'],
		}, {
			type => 'submit', 
		},	
	);

	my @src_list_query = split( "\n", <<__endquote );
name=name&type=textfield&visible_title=What%27s+your+name%3F
default=eenie&default=minie&name=words&type=checkbox_group&values=eenie&values=meenie&values=minie&values=moe&visible_title=What%27s+the+combination%3F
name=color&type=popup_menu&values=red&values=green&values=blue&values=chartreuse&visible_title=What%27s+your+favorite+colour%3F
type=submit
__endquote

	my @src_list_cookie = split( "\n", <<__endquote );
name=name; type=textfield; visible_title=What%27s+your+name%3F
default=eenie&minie; name=words; type=checkbox_group; values=eenie&meenie&minie&moe; visible_title=What%27s+the+combination%3F
name=color; type=popup_menu; values=red&green&blue&chartreuse; visible_title=What%27s+your+favorite+colour%3F
type=submit
__endquote
	
	my @src_list_file = split( "\n=\n", substr( <<__endquote, 2 ) );
=
name=name
type=textfield
visible_title=What%27s+your+name%3F
=
default=eenie
default=minie
name=words
type=checkbox_group
values=eenie
values=meenie
values=minie
values=moe
visible_title=What%27s+the+combination%3F
=
name=color
type=popup_menu
values=red
values=green
values=blue
values=chartreuse
visible_title=What%27s+your+favorite+colour%3F
=
type=submit
__endquote

	my (@d1hash,@d2hash,@d1query,@d2query,@d1cookie,@d2cookie,@d1file,@d2file);

	# try decoding one record at a time
	
	foreach my $i (0..$#src_list_hash) {
		$d1hash[$i] = CGI::MultiValuedHash->new( 0, $src_list_hash[$i] );
		$d1query[$i] = CGI::MultiValuedHash->new( 0, $src_list_query[$i] );
		$d1cookie[$i] = CGI::MultiValuedHash->new( 0, $src_list_cookie[$i], "; ", "&" );
		$d1file[$i] = CGI::MultiValuedHash->new( 0, $src_list_file[$i], "\n" );
	}
	
	# try batch decoding all records at once

	@d2hash = CGI::MultiValuedHash->batch_new( 0, \@src_list_hash );
	@d2query = CGI::MultiValuedHash->batch_new( 0, \@src_list_query );
	@d2cookie = CGI::MultiValuedHash->batch_new( 0, \@src_list_cookie, "; ", "&" );
	@d2file = CGI::MultiValuedHash->batch_new( 0, \@src_list_file, "\n" );
	
	my @expected = (
		"{ 'name' => [ 'name', ], 'type' => [ 'textfield', ], 'visible_title' => [ 'What's your name?', ], }, ",
		"{ 'default' => [ 'eenie', 'minie', ], 'name' => [ 'words', ], 'type' => [ 'checkbox_group', ], 'values' => [ 'eenie', 'meenie', 'minie', 'moe', ], 'visible_title' => [ 'What's the combination?', ], }, ",
		"{ 'name' => [ 'color', ], 'type' => [ 'popup_menu', ], 'values' => [ 'red', 'green', 'blue', 'chartreuse', ], 'visible_title' => [ 'What's your favorite colour?', ], }, ",
		"{ 'type' => [ 'submit', ], }, ",
	);

	# compare decodes to what we expect

	foreach my $i (0..$#expected) {
		$should = $expected[$i];
	
		$did = serialize( scalar( $d1hash[$i]->fetch_all() ) );
		result( $did eq $should, "decode hash $i single returns '$did'" );
	
		$did = serialize( scalar( $d2hash[$i]->fetch_all() ) );
		result( $did eq $should, "decode hash $i batch returns '$did'" );
	
		$did = serialize( scalar( $d1query[$i]->fetch_all() ) );
		result( $did eq $should, "decode query $i single returns '$did'" );
	
		$did = serialize( scalar( $d2query[$i]->fetch_all() ) );
		result( $did eq $should, "decode query $i batch returns '$did'" );
	
		$did = serialize( scalar( $d1cookie[$i]->fetch_all() ) );
		result( $did eq $should, "decode cookie $i single returns '$did'" );
	
		$did = serialize( scalar( $d2cookie[$i]->fetch_all() ) );
		result( $did eq $should, "decode cookie $i batch returns '$did'" );
	
		$did = serialize( scalar( $d1file[$i]->fetch_all() ) );
		result( $did eq $should, "decode file $i single returns '$did'" );
	
		$did = serialize( scalar( $d2file[$i]->fetch_all() ) );
		result( $did eq $should, "decode file $i batch returns '$did'" );
	}

	# try encoding now

	foreach my $i (0..$#expected) {
		$did = $d1hash[$i]->to_url_encoded_string();
		$should = $src_list_query[$i];
		result( $did eq $should, "encode as query $i returns '$did'" );

		$did = $d1hash[$i]->to_url_encoded_string( "; ", "&" );
		$should = $src_list_cookie[$i];
		result( $did eq $should, "encode as cookie $i returns '$did'" );

		chomp( $did = $d1hash[$i]->to_url_encoded_string( "\n" ) );
		chomp( $should = $src_list_file[$i] );
		result( $did eq $should, "encode as file $i returns '".vis($did)."'" );
	}
}

######################################################################

message( "DONE TESTING CGI::MultiValuedHash" );

######################################################################

1;
