use Modern::Perl;
use Log::LogMethods::Log4perlLogToString;
use Carp qw(confess);
use Data::Dumper;
use JSON qw(to_json from_json);
use AnyEvent::Loop;
#BEGIN { $SIG{__DIE__} = sub { confess @_ }; }
use Test::More qw(no_plan);

my $class='AnyEvent::SparkBot';
require_ok($class);
use_ok($class);

my $string;
my $logger=LoggerToString($class,$string);
my $token=exists $ENV{SPARK_TOKEN} ? $ENV{SPARK_TOKEN} : 'this is not a valid token';
my $self=$class->new(logger=>$logger,token=>$token,on_message=>sub {});

$self->spark->{retryCount}=2;
isa_ok($self,$class);


my $final=0;
my $teamName='sparkbot-test-team';
my $testRoom="sparkbot-test-room";
SKIP: {
  skip '$ENV{SPARK_TOKEN} and $ENV{RUN_HTTP_TESTS} are required',11 unless $ENV{SPARK_TOKEN} and $ENV{RUN_HTTP_TESTS};
  $final=1;

  $self->run_lookup('que_getMe',sub {
    my ($sb,$id,$result)=@_;
    ok($result,'Should fetch me without error');

    my $me=$result->get_data;

    $self->run_lookup('que_createTeam',sub {
      my ($sb,$id,$result)=@_;
      ok($result,'Should have created the team without an error');
      my $team=$result->get_data;
      diag Dumper($team);

      $self->run_lookup('que_listTeams',sub {
      my ($sb,$id,$result)=@_;
        ok($result,'should be able to list the teams without a problem') or die $result;

	my $teams=$result->get_data->{items};

	foreach my $t (@{$teams}) {
	  my $id=$t->{id};
	  if($t->{name} eq $team->{name} and $t->{id} ne $team->{id}) {
	    $self->run_lookup('que_deleteTeam',sub {
              my ($sb,$id,$result)=@_;
	      ok($result,"Cleaning up bad team") or diag $result;
	    },$t->{id});
	  }
	}
	$self->run_lookup('que_createRoom',sub {
          my ($sb,$id,$result)=@_;
	  ok($result,'Should create the room without a problem') or diag $result;
	  my $room=$result->get_data;

	  diag Dumper($room);

	  $self->run_lookup('que_listRooms',sub {
            my ($sb,$id,$result)=@_;

	    ok($result,'should list rooms without problems') or die $result;

	    my $rooms=$result->get_data->{items};
	    diag("total Rooms with the name [$testRoom]: ".scalar(@{$rooms}));

	    foreach my $r (@{$rooms}) {
	      next unless $r->{title} eq $room->{title} and $r->{id} ne $room->{id};
	      diag Dumper $r;
	      $self->run_lookup('que_deleteRoom',sub {
                my ($sb,$id,$result)=@_;
		ok($result,'Should clean up bad room without error') or diag $result;
	      },$r->{id});
	    }

	    $self->run_lookup('que_createMessage',sub {
              my ($sb,$id,$result)=@_;
	      ok($result,'Should post a message to our room without eror');
	      $self->run_lookup('que_listMessages',sub {
                my ($sb,$id,$result,$request,$response)=@_;

		ok($result,'Should list our messages without a problem') or die $result;

		$self->run_lookup('que_deleteRoom',sub {
                  my ($sb,$id,$result,$request,$response)=@_;
		  ok($result,'Should delete our room without a problem');
		  $self->run_lookup('que_deleteTeam',sub {
                    my ($sb,$id,$result,$request,$response)=@_;
		    ok($result,'Should delete our team without a problem');
		    $final=0;
		    no warnings;
		    last SKIP;
		  },$team->{id});
		},$room->{id});
	      },{roomId=>$room->{id},mentionedPeople=>'me'});
	      
	    },{roomId=>$room->{id},text=>'this is a test'});
	  },{teamId=>$team->{id}});
	},{teamId=>$team->{id},title=>$testRoom});
      });

     
    },{name=>$teamName});

  });
  
  my $max=AnyEvent->timer(after=>300,cb=>sub { no warnings;last SKIP });
  AnyEvent::Loop::run;
}

ok(!$final,'should have cleared final');
