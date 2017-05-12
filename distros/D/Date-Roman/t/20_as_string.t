#testing if the as_string method works
use Date::Roman;
use strict;
my @data;
my $tests = 0;

BEGIN {
  @data = (
	   {
	    roman => "id 3 702",
	    outputs => [
			{
			 params => {},
			 value => "Id. Mar. DCCII AUC"
			},
			{
			 params => {num => 'Roman'},
			 value => "Id. Mar. DCCII AUC"
			},
			{
			 params => {words => 'abbrev'},
			 value => "Id. Mar. DCCII AUC"
			},
			{
			 params => {annus => 'Roman', fday => 'abbrev', mons => 'abbrev'},
			 value => "Id. Mar. DCCII AUC"
			},
			{
			 params => {annus => 'Roman', fday => 'abbrev', 
				    mons => 'complete'},
			 value => "Id. Martias DCCII AUC"
			},
			{
			 params => {annus => 'roman', fday => 'complete'},
			 value => "Idus Mar. dccii AUC"
			},
			{
			 params => {words => 'complete',
				    auc => 'abbrev'},
			 value => "Idus Martias DCCII AUC"
			},
			{
			 params => {words => 'complete',
				    num => 'roman'
				   },
			 value => "Idus Martias dccii ab Urbe Condida"
			}
		       ]
	   },
	   {
	    roman => "11 kal 5 1000",
	    outputs => [
			{
			 params => {},
			 value => "a.d. XI Kal. Mai. M AUC"
			},
			{
			 params => {num => 'Roman'},
			 value => "a.d. XI Kal. Mai. M AUC"
			},
			{
			 params => {words => 'abbrev'},
			 value => "a.d. XI Kal. Mai. M AUC"
			},
			{
			 params => {annus => 'Roman', fday => 'abbrev', mons => 'abbrev'},
			 value => "a.d. XI Kal. Mai. M AUC"
			},
			{
			 params => {annus => 'Roman', fday => 'abbrev', 
				    mons => 'complete'},
			 value => "a.d. XI Kal. Maias M AUC"
			},
			{
			 params => {annus => 'roman', fday => 'complete'},
			 value => "a.d. XI Kalendas Mai. m AUC"
			},
			{
			 params => {words => 'complete',
				    auc => 'abbrev'},
			 value => "ante diem XI Kalendas Maias M AUC"
			},
			{
			 params => {words => 'complete',
				    num => 'roman'
				   },
			 value => "ante diem xi Kalendas Maias m ab Urbe Condida"
			},
		       ]
	   },
	   {
	    roman => "b6 kal 3 1753",
	    outputs => [
			{
			 params => {},
			 value => "a.d. VI Kal. Mar. MDCCLIII AUC"
			},
			{
			 params => {num => 'Roman'},
			 value => "a.d. VI Kal. Mar. MDCCLIII AUC"
			},
			{
			 params => {words => 'abbrev'},
			 value => "a.d. VI Kal. Mar. MDCCLIII AUC"
			},
			{
			 params => {annus => 'Roman', fday => 'abbrev', mons => 'abbrev'},
			 value => "a.d. VI Kal. Mar. MDCCLIII AUC"
			},
			{
			 params => {annus => 'Roman', fday => 'abbrev', 
				    mons => 'complete'},
			 value => "a.d. VI Kal. Martias MDCCLIII AUC"
			},
			{
			 params => {annus => 'roman', fday => 'complete'},
			 value => "a.d. VI Kalendas Mar. mdccliii AUC"
			},
			{
			 params => {words => 'complete',
				    auc => 'abbrev'},
			 value => "ante diem VI Kalendas Martias MDCCLIII AUC"
			},
			{
			 params => {words => 'complete',
				    num => 'roman'
				   },
			 value => "ante diem vi Kalendas Martias mdccliii ab Urbe Condida"
			},
		       ]
	   },

	  );
  foreach (@data) {
    $tests += @{$_->{outputs}} + 1;
  }
}

use Test::More tests => $tests;


foreach my $data (@data) {
  my $roman = Date::Roman->new(roman => $data->{roman});
  ok(defined $roman);
  foreach my $test (@{$data->{outputs}}) {
    is($roman->as_string(%{$test->{params}}),
       $test->{value});
  }
}
