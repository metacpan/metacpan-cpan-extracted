package Foo;
use Moose;
with 'DateTimeX::Format';

sub parse_datetime {
	my ( $self, $time, $env, @args ) = @_;
	[ $time, $env, @args ];
};

sub format_datetime {;}

package main;
use Test::More tests => 7;
require_ok( 'DateTime::Locale' );

my $dt1 = Foo->new({ locale => 'en_US', pattern => undef });

		is ( @{ $dt1->parse_datetime("5:00:00") }, 2, "Right ammount of arguments" );
		is ( @{ $dt1->parse_datetime("5:00:00", {}, "foo" ) }, 3, "Right ammount of arguments when more are supplied" );

		is (
			$dt1->parse_datetime( "5:00:00" )->[1]->{locale}->id
			, 'en_US'
			, 'Setting locale in const worked'
		);

		my $newLocale = DateTime::Locale->load( 'en_AU' );
		is (
			$dt1->parse_datetime( "5:00:00", {locale=>$newLocale} )->[1]->{locale}->id
			, 'en_AU'
			, 'Setting locale in call worked'
		);

		## The call didn't change env
		is (
			$dt1->parse_datetime( "5:00:00" )->[1]->{locale}->id
			, 'en_US'
			, 'Setting locale in const still worked'
		);

		$dt1->locale( $newLocale );
		is (
			$dt1->parse_datetime( "5:00:00" )->[1]->{locale}->id
			, 'en_AU'
			, 'Setting locale in runtime worked'
		);

