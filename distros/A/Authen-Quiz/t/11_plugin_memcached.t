use lib qw( ./lib ../lib );
use Test::More;
eval{
  use File::Temp qw/ tempdir /;
  use File::Slurp;
  };

my $error;
if ($error= $@) {
	plan skip_all=> $error;
} else {
	eval{ require Cache::Memcached::Fast };
	if ($error= $@) {
		eval{ require Cache::Memcached };
		if ($error= $@) {
			plan skip_all=> 'Cache::Memcached::Fast or Cache::Memcached is not installed.';
		}
	}
	unless ($ENV{AUTHEN_QUIZ_MEMCACHED_PORT}) {
		plan skip_all=> qq{'AUTHEN_QUIZ_MEMCACHED_SERVER' and 'AUTHEN_QUIZ_MEMCACHED_PORT' environment is empty. };
		$error= 1;
	}
}

unless ($error) {

require Authen::Quiz::FW;
Authen::Quiz::FW->import(qw/ Memcached /);

plan tests=> 5;

my $temp= tempdir( CLEANUP => 1 );

my $quiz_data   = File::Spec->catfile($temp, $Authen::Quiz::QuizYaml);
my $quiz_session= File::Spec->catfile($temp, $Authen::Quiz::QuizSession);

write_file($quiz_data, <DATA>);
write_file($quiz_session, "");

my $server= $ENV{AUTHEN_QUIZ_MEMCACHED_SERVER} || '127.0.0.1';
my $port  = $ENV{AUTHEN_QUIZ_MEMCACHED_PORT};

ok my $q= Authen::Quiz::FW->new(
  data_folder => $temp,
  memcached   => { servers=> ["${server}:${port}"] },
  ), 'Constructor.';

isa_ok $q, 'Authen::Quiz::Plugin::Memcached';
ok my $quiz= $q->load_quiz, q{my $hash= $q->load_quiz};
isa_ok $quiz, 'HASH';
isa_ok $quiz->{F01}, 'ARRAY';

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
