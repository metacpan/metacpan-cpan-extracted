use lib qw( ./lib ../lib );
use Test::More;

eval{
  use File::Temp qw/ tempdir /;
  use File::Slurp;
  };
if (my $error= $@) { plan skip_all=> $error } else {

eval{ require Authen::Quiz::FW };
if ($@) { plan skip_all=> 'Authen::Quiz::FW cannot be loaded.' } else {

Authen::Quiz::FW->import(qw/ JS /);

eval{ require Jcode };
my $jcode_ok= $@ ? do {
	plan tests=> 6;
	0;
  }: do {
	plan tests=> 10;
	1;
  };

my $temp= tempdir( CLEANUP => 1 );

my $quiz_data   = File::Spec->catfile($temp, $Authen::Quiz::QuizYaml);
my $quiz_session= File::Spec->catfile($temp, $Authen::Quiz::QuizSession);

write_file($quiz_data, <DATA>);
write_file($quiz_session, "");

ok my $q= Authen::Quiz::FW->new( data_folder=> $temp ), 'Constructor.';

isa_ok $q, 'Authen::Quiz::Plugin::JS';

can_ok $q, 'question2js';
  ok my $jsq= $q->question2js('boxid'), q{my $jsq= $q->question2js};
  like $jsq, qr{new\s+Array\(.+?test\d.+?test\d.+?test.+?\)}s, q{ regex1 };
  like $jsq, qr{document\.getElementById\(.+?boxid.+?\)}s,     q{ regex2 };

if ($jcode_ok) {
	can_ok $q, 'question2js_multibyte';
	  ok $jsq= $q->question2js_multibyte('boxid'), q{$jsq= $q->question2js_multibyte};
	  like $jsq, qr{new\s+Array\(.+?test\d.+?test\d.+?test.+?\)}s, q{ regex1 };
	  like $jsq, qr{document\.getElementById\(.+?boxid.+?\)}s,     q{ regex2 };
}

} }


__DATA__
---
F01:
 - test1 test1 test1
 - OK1
F02:
 - test2 test2 test2
 - KO2
F03:
 - test3 test3 test3
 - OK3
