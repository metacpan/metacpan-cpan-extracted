#!perl -T
use strict;
use warnings;

use Test::More;
use Test::NoWarnings;
use Test::Exception;
use File::Spec;
use App::Toodledo::Task;

my $FUDGETIME = 5;
my ($APPID, $APPTOKEN) = qw(perlmodtest api4ce75135eaa24);
my $NEW_TITLE = 'Something completely different';
my $TESTTAG = 'APPTOODLEDO_TEST_TAG';
my $CLASS;
my ($userid, $password, $datafile);
BEGIN
{
  $CLASS = 'App::Toodledo'; 
  $datafile = File::Spec->catfile( t => 'live.data' );
  -f $datafile or $datafile = 'live.data';
  if ( open my $fh, '<', $datafile )
  {
    chomp( ($userid, $password) = <$fh> );
    plan tests => 16;
  }
  else
  {
    plan tests => 1;  # NoWarnings
    exit;
  }
  use_ok $CLASS;
}

my $todo = $CLASS->new( app_id => $APPID );

$todo->login( user_id => $userid, password => $password,
	      app_token => $APPTOKEN );

my @folders;
lives_ok { @folders = $todo->get( 'folders' ) } 'Can get folders';
ok @folders > 0, "You've got some folders";

my $task = App::Toodledo::Task->new( title => 'App::Toodledo test task',
				     tag => $TESTTAG );
my $time = time - $FUDGETIME;

my $id;
lives_ok { $id = $todo->add( $task ) } 'Task added';

my @tasks;
lives_ok { @tasks = $todo->get( tasks => modafter => $time ) } 'Got tasks';
is scalar(@tasks), 1, 'Found one task added...';
is $tasks[0]->title, $task->title, '...this one';
is $tasks[0]->id, $id, 'By ID also';

$tasks[0]->title( $NEW_TITLE );
lives_ok { $todo->edit( $tasks[0] ) } 'Edited task';

(@tasks) = $todo->get( tasks => modafter => $time );
is scalar(@tasks), 1, 'Found one task again...';
is $tasks[0]->title, $NEW_TITLE, '...the edited task';
is $tasks[0]->tag, $TESTTAG, 'Tag matches';

lives_ok { $todo->delete( $tasks[0] ) } 'Task deleted';
lives_ok { @tasks = $todo->get( tasks => modafter => $time ) } 'Checking';
is @tasks+0, 0, "It's gone";

unlink $datafile unless $ENV{APP_TOODLEDO_DEBUG};   # Security
