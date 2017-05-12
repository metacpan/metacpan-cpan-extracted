use Test2::Bundle::Extended;
use App::af;
use lib 't/lib';
use lib 'corpus/lib';
use MyTest;
do './bin/af';

subtest 'basic' => sub {

  run 'list';
  
  is last_exit, 0;

};

subtest 'detailed' => sub {

  run 'list', '--long';
  
  is last_exit, 0;

};

done_testing;
