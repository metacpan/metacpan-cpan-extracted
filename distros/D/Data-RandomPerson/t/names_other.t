#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 112;

################################################################################
# Test all the extra name modules
################################################################################

foreach my $module ( qw/AncientGreekFemale AncientGreekMale ArabicFemale ArabicLast ArabicMale BasqueFemale BasqueMale CelticFemale CelticMale EnglishFemale EnglishLast EnglishMale HindiFemale HindiMale JapaneseFemale JapaneseMale LatvianFemale LatvianMale ModernGreekFemale ModernGreekLast ModernGreekMale SpanishFemale SpanishLast SpanishMale ThaiFemale ThaiMale VikingFemale VikingMale/ ) {
	my $class = "Data::RandomPerson::Names::$module";
	
	use_ok( $class );

	my $m = $class->new();

	is( ref($m), $class );

	can_ok( $m, qw/new get size/ );

	ok( $m->size() > 0 );
}

# vim: syntax=perl :
