#!/usr/bin/perl
use lib qw(./t blib/lib);
use strict;
no warnings;
use Test::More qw(no_plan);
use Data::Dumper;

use Bio::ConnectDots::Parser;

# test constructor
my $parser = new Bio::ConnectDots::Parser;
is(ref($parser), 'Bio::ConnectDots::Parser', 'check Parser constructor');

# test parse_constraint()
my $ret = $parser->parse_constraint('Unigene.Unigene=Hs.421202');
is ($ret->{'constant'} eq 'Hs.421202' &&
	$ret->{'op'} eq '=' &&
	$ret->{'term'}->[0] eq 'Unigene' &&
	$ret->{'term'}->[1] eq 'Unigene', 1, 'check parse_constraint(...) on =');	 

$ret = undef;	 
$ret = $parser->parse_constraint('LocusLink <= 20');
is ($ret->{'constant'} eq '20' &&
	$ret->{'op'} eq '<=' &&
	$ret->{'term'}->[0] eq 'LocusLink', 1, 'check parse_constraint(...) on <= and whitespace');	 

	 
# test parse_constraints()
$ret = undef;
$ret = $parser->parse_constraints('Unigene.Unigene = Hs.421202 AND LocusLink<=20');
is ($ret->[0]->{'constant'} eq 'Hs.421202' &&
	$ret->[0]->{'op'} eq '=' &&
	$ret->[0]->{'term'}->[0] eq 'Unigene' &&
	$ret->[0]->{'term'}->[1] eq 'Unigene' &&
	$ret->[1]->{'constant'} eq '20' &&
	$ret->[1]->{'op'} eq '<=' &&
	$ret->[1]->{'term'}->[0] eq 'LocusLink',
	1, 'check parse_constraints(list_of_constraints)');	 


# test parse_join()
$ret = undef;
$ret = $parser->parse_join('LocusLink.LocusLink=UG.LocusLink');
is ($ret->{'term0'}->[0] eq 'LocusLink' &&
	$ret->{'term0'}->[1] eq 'LocusLink' &&
	$ret->{'term1'}->[0] eq 'UG' &&
	$ret->{'term1'}->[1] eq 'LocusLink',
	1, 'check parse_join(join)');

$ret = undef;
$ret = $parser->parse_join('LocusLink.LocusLink = UG.LocusLink');
is ($ret->{'term0'}->[0] eq 'LocusLink' &&
	$ret->{'term0'}->[1] eq 'LocusLink' &&
	$ret->{'term1'}->[0] eq 'UG' &&
	$ret->{'term1'}->[1] eq 'LocusLink',
	1, 'check parse_join(join) seperated by non-word char');

# test parse_joins()
$ret = undef;
$ret = $parser->parse_joins('LocusLink.LocusLink = UG.LocusLink AND UG.UniGene = Affy.UniGene');
is ($ret->[0]->{'term0'}->[0] eq 'LocusLink' &&
	$ret->[0]->{'term0'}->[1] eq 'LocusLink' &&
	$ret->[0]->{'term1'}->[0] eq 'UG' &&
	$ret->[0]->{'term1'}->[1] eq 'LocusLink' &&
	$ret->[1]->{'term0'}->[0] eq 'UG' &&
	$ret->[1]->{'term0'}->[1] eq 'UniGene' &&
	$ret->[1]->{'term1'}->[0] eq 'Affy' &&
	$ret->[1]->{'term1'}->[1] eq 'UniGene',
	1, 'check parse_joins(join AND join)');

# test parse_alias()
$ret = undef;
$ret = $parser->parse_alias('\'LocusLink.LocusLink\' AS LL');
is ($ret->{'target_name'} eq 'LocusLink.LocusLink' &&
	$ret->{'alias_name'} eq 'LL',
	1, 'check parse_alias with seperator: AS');

$ret = undef;
$ret = $parser->parse_alias('LocusLink LL');
is ($ret->{'target_name'} eq 'LocusLink' &&
	$ret->{'alias_name'} eq 'LL',
	1, 'check parse_alias() with seperator: space');

# test parse_aliases()
$ret = undef;
$ret = $parser->parse_aliases('LocusLink AS LL, Unigene UG');
is ($ret->[0]->{'target_name'} eq 'LocusLink' &&
	$ret->[0]->{'alias_name'} eq 'LL' &&
	$ret->[1]->{'target_name'} eq 'Unigene' &&
	$ret->[1]->{'alias_name'} eq 'UG',
	1, 'check parse_aliases() for list of aliases');

# test parse_term1()
$ret = undef;
$ret = $parser->parse_term1('*andthensomestuff');
is ($ret, '*', 'check parse_term1(*)');

$ret = undef;
$ret = $parser->parse_term1('this_is_a_word', 1);
is ($ret->{'match'} eq 'this_is_a_word' &&
	$ret->{'rule'} eq 'word', 
	1, 'check parse_term1(word) with want_tree rule verification');

$ret = undef;
$ret = $parser->parse_term1('\'a quoted phrase\'', 1);
is ($ret->{'match'} eq 'a quoted phrase' &&
	$ret->{'rule'} eq 'quoted_phrase', 
	1, 'check parse_term1(quoted_phrase) with want_tree rule verification');

$ret = undef;
$ret = $parser->parse_term1('[2, 5, 25, 2500]', 1);
is ($ret->{match}->{match}->[0]->{match} eq '2' &&
	$ret->{match}->{match}->[3]->{match} eq '2500' &&
	$ret->{rule} eq 'list', 
	1, 'check parse_term1(list) with want_tree rule verification');

# test parse_term()
$ret = undef;
$ret = $parser->parse_term('term1');
is ($ret->[0], 'term1', 'check parse_term(term1)');

$ret = undef;
$ret = $parser->parse_term('term1.term2');
is ($ret->[0] eq 'term1' &&
	$ret->[1] eq 'term2',
	1, 'check parse_term(term1.term1)');
	
$ret = undef;
$ret = $parser->parse_term('term1.term2.term3');
is ($ret->[0] eq 'term1' &&
	$ret->[1] eq 'term2' &&
	$ret->[2] eq 'term3',
	1, 'check parse_term(term1.term1.term1)');

# test parse_op
$ret = undef;
$ret = $parser->parse_op(' = snart');
is ($ret, '=', 'check parse_op() for one operator');

$ret = undef;
$ret = $parser->parse_op('in trans');
is ($ret, 'IN', 'check parse_op() for one operator');

# test parse_constant
$ret = undef;
$ret = $parser->parse_constant('Hs.421202 thensomestuff');
is ($ret, 'Hs.421202', 'check parse_constant() on single word');

$ret = undef;
$ret = $parser->parse_constant('[Hs.421202, 20]');
is ($ret->[0] eq 'Hs.421202' &&
	$ret->[1] eq '20',
	1, 'check parse_constant() on list');

# test parse_output
$ret = undef;
$ret = $parser->parse_output('LocusLink.LocusLink');
is ($ret->{termlist}->[0] eq 'LocusLink' &&
	$ret->{termlist}->[1] eq 'LocusLink' &&
	$ret->{output_name} eq undef, 
	1, 'check parse_output(word.word)');

$ret = undef;
$ret = $parser->parse_output('Unigene.Unigene AS UG');
is ($ret->{termlist}->[0] eq 'Unigene' &&
	$ret->{termlist}->[1] eq 'Unigene' &&
	$ret->{output_name} eq 'UG', 
	1, 'check parse_output(word.word AS alias)');

# test parse_qword
$ret = undef;
$ret = $parser->parse_qword('a_word',1);
is ($ret->{match} eq 'a_word' &&
	$ret->{rule} eq 'word',
	1, 'check parse_qword()');

$ret = undef;
$ret = $parser->parse_qword('\'quoted phrase!\'',1);
is ($ret->{match} eq 'quoted phrase!' &&
	$ret->{rule} eq 'quoted_phrase',
	1, 'check parse_qword()');








1;