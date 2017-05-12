#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 5;
use Test::Exception;

BEGIN {
	use_ok ( 'Acme::KnowledgeWisdom' ) or exit;
}

exit main();

sub main {
	my $kw_has_already = Acme::KnowledgeWisdom->new('has_already' => 1);
	isa_ok($kw_has_already, 'Acme::KnowledgeWisdom', 'are you sure?');
	is($kw_has_already->get, 42, 'get if has already');

	# not in questions
	my $kw_answers = Acme::KnowledgeWisdom->new('in_questions' => 0);
	is($kw_answers->get, 42, 'get if in answers');

	# in questions
	my $kw_questions = Acme::KnowledgeWisdom->new();
	dies_ok { $kw_questions->get } 'get if in questions';
	
	return 0;
}

