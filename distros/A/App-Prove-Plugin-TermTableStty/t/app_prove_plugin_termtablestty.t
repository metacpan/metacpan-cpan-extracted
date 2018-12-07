use Test2::V0 -no_srand => 1;
use App::Prove::Plugin::TermTableStty;
use Env qw( @PATH );
use Cwd qw( cwd );

subtest 'already set' => sub {

  local $ENV{TABLE_TERM_SIZE} = 9999;
  App::Prove::Plugin::TermTableStty->load;
  is $ENV{TABLE_TERM_SIZE}, 9999;

};

subtest 'not already set' => sub {

  local $ENV{TERM_TABLE_SIZE};
  delete $ENV{TERM_TABLE_SIZE};

  local $ENV{PATH} = $ENV{PATH};

  unshift @PATH, join('/', cwd(), 'corpus/bin');

  App::Prove::Plugin::TermTableStty->load;
  is $ENV{TERM_TABLE_SIZE}, 140;

};

done_testing
