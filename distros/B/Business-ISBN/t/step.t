use Test::More 0.95;

use strict;
use warnings;

my $class       = 'Business::ISBN';
my @methods     = qw( increment decrement _step_article_code );
my $isbn_string = '978-1-4493-9311-3'; # Mastering Perl

my $isbn;

subtest setup => sub {
	use_ok( $class );
	can_ok( $class, @methods );
	};

subtest make_isbn => sub {
	$isbn = $class->new( $isbn_string );
	isa_ok( $isbn, $class );
	can_ok( $class, @methods );	
	};

subtest one_more => sub {
	my $isbn     = $class->new( '978-1-4493-9311-3' );
	isa_ok( $isbn, $class );
	my $one_more = $class->new( '978-1-4493-9312-3' );
	$one_more->fix_checksum;
	isa_ok( $one_more, $class );

	my $isbn_one_more = $isbn->increment;
	isa_ok( $isbn_one_more, $class );
	
	is( $one_more->as_string, $isbn_one_more->as_string, 'One more matches' );
	};

subtest one_less => sub {
	my $isbn     = $class->new( '978-1-4493-9311-3' );
	isa_ok( $isbn, $class );
	my $one_less = $class->new( '978-1-4493-9310-3' );
	$one_less->fix_checksum;
	isa_ok( $one_less, $class );

	my $isbn_one_less = $isbn->decrement;
	isa_ok( $isbn_one_less, $class );
	
	is( $one_less->as_string, $isbn_one_less->as_string, 'One less matches' );
	};

subtest too_little => sub {
	my $isbn     = $class->new( '978-1-4493-0000-3' );
	$isbn->fix_checksum;
	isa_ok( $isbn, $class );

	my $isbn_one_less = $isbn->decrement;

	is( $isbn_one_less, Business::ISBN::ARTICLE_CODE_OUT_OF_RANGE(),
		'Incrementing below 0 would be out of range' );
	};

subtest too_much => sub {
	my $isbn     = $class->new( '978-1-4493-9999-3' );
	$isbn->fix_checksum;
	isa_ok( $isbn, $class );

	my $isbn_one_more = $isbn->increment;
	is( $isbn_one_more, Business::ISBN::ARTICLE_CODE_OUT_OF_RANGE(),
		'Incrementing past 9999 would be out of range' );
	};

done_testing();
