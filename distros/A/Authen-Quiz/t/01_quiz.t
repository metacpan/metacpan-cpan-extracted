use lib qw( ./lib ../lib );
use Test::More;
use Authen::Quiz;
eval{
  use File::Temp qw/ tempdir /;
  use File::Slurp;
  };
if (my $error= $@) { plan skip_all=> $error } else {

plan tests=> 33;

my $temp= tempdir( CLEANUP => 1 );

my $quiz_data   = File::Spec->catfile($temp, $Authen::Quiz::QuizYaml);
my $quiz_session= File::Spec->catfile($temp, $Authen::Quiz::QuizSession);

write_file($quiz_data, <DATA>);
write_file($quiz_session, "");

ok my $q= Authen::Quiz->new( data_folder=> $temp ), 'Constructor.';

isa_ok $q, 'Authen::Quiz';
isa_ok $q, 'Class::Accessor::Fast';

can_ok $q, 'data_folder';
  is $q->data_folder, $temp, qq{\$q->data_folder eq $temp};

can_ok $q, 'expire';
  is $q->expire, 30, qq{\$q->expire == 30};

can_ok $q, 'quiz_yaml';
  is $q->quiz_yaml, File::Spec->catfile($temp, $Authen::Quiz::QuizYaml);

can_ok $q, 'session_file';
  is $q->session_file, File::Spec->catfile($temp, $Authen::Quiz::QuizSession);

can_ok $q, 'load_quiz';
  ok my $quiz= $q->load_quiz, q{my $hash= $q->load_quiz};
  isa_ok $quiz, 'HASH';
  is scalar(keys %$quiz), 3, q{scalar(keys %$quiz) == 3};
  isa_ok $quiz->{F01}, 'ARRAY';
  isa_ok $quiz->{F02}, 'ARRAY';
  isa_ok $quiz->{F03}, 'ARRAY';

can_ok $q, 'session_id';
  ok ! $q->session_id, q{! $q->session_id};

can_ok $q, 'question';
  ok my $question  = $q->question,   q{my $question= $q->question};
  ok my $session_id= $q->session_id, q{my $session_id= $q->session_id};
  my($T, $sid, $key)= do {
  	my $line= read_file($q->session_file);
  	$line=~m{^(.+?)\t(.+?)\t([^\n]+)};
    };
  is $session_id, $sid, q{$session_id eq $sid};

can_ok $q, 'check_answer';
  ok $q->check_answer($session_id, $quiz->{$key}[1]), q{$q->check_answer( ...};
  ok ! $q->check_answer($session_id, $quiz->{$key}[1]), q{! $q->check_answer( ...};

ok ! read_file($q->session_file), q{! read_file($q->session_file)};
ok $q->question,                  q{$q->question};
ok read_file($q->session_file),   q{read_file($q->session_file)};

can_ok $q, 'remove_session';
  ok $q->remove_session,            q{$q->remove_session};
  ok ! read_file($q->session_file), q{! read_file($q->session_file)};

}


__DATA__
---
F01:
 - test1
 - OK1
F02:
 - test2
 - KO2
F03:
 - test3
 - OK3
