use lib qw( ./lib ../lib );
use Test::More;

eval{
  use File::Temp qw/ tempdir /;
  use File::Slurp;
  };
if (my $error= $@) { plan skip_all=> $error } else {

eval{ require Authen::Quiz::FW };
if ($@) { plan skip_all=> 'Authen::Quiz::FW cannot be loaded.' } else {

Authen::Quiz::FW->import;

plan tests=> 4;

my $temp= tempdir( CLEANUP => 1 );

my($quiz_data, $quiz_session)= do {
	( File::Spec->catfile($temp, $Authen::Quiz::QuizYaml),
	  File::Spec->catfile($temp, $Authen::Quiz::QuizSession) );
  };

write_file($quiz_data, <DATA>);
write_file($quiz_session, "");

ok my $q= Authen::Quiz::FW->new( data_folder=> $temp ), 'Constructor.';

isa_ok $q, 'Authen::Quiz::FW';
isa_ok $q, 'Authen::Quiz';
isa_ok $q, 'Authen::Quiz::FW::Base';

} }


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
