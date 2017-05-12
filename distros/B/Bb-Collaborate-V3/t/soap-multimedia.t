#!perl -T
use warnings; use strict;
use Test::More tests => 15;
use Test::Fatal;

use lib '.';
use t::Bb::Collaborate::V3;

use Bb::Collaborate::V3::Multimedia;
use Bb::Collaborate::V3::Session;
use Elive::Util;

our $t = Test::More->builder;
my $class = 'Bb::Collaborate::V3::Multimedia';

my $data = 'unplayable junk data U(&(* 090 -0';

SKIP: {

    my %result = t::Bb::Collaborate::V3->test_connection();
    my $auth = $result{auth};

    skip ($result{reason} || 'skipping live tests', 15)
	unless $auth;

    my $connection_class = $result{class};
    my $connection = $connection_class->connect(@$auth);
    Bb::Collaborate::V3->connection($connection);

    my $multimedia;

  do {
      is( exception {
	  $multimedia = Bb::Collaborate::V3::Multimedia->upload(
	      {
		filename => 'elive-standardv3-soap-session-multimedia-t.mpeg',
		content => $data,
                description => 'created by standard v3 t/soap-multimedia.t',
		creatorId => 'elive-standardv3-tester',
	      })
	       } => undef,
	       'insert multimedia - lives'
	  );
  };

    die 'unable to continue without an multimedia upload object'
	unless $multimedia;

    isa_ok($multimedia, $class, 'multimedia object');

    my $multimedia_id = $multimedia->multimediaId;
    ok($multimedia_id, 'got multimedia id');

    my $multimedia_list;

    # you need to supply a creatator id
    is( exception {$multimedia_list = Bb::Collaborate::V3::Multimedia->list(filter => {multimediaId => $multimedia_id, creatorId => 'elive-standardv3-tester'})} => undef,  'retrieve multimedia - lives');

     die 'unable to continue without a multimedia list object'
	unless $multimedia_list && $multimedia_list->[0]; 

    is($multimedia_list->[0]->creatorId, 'elive-standardv3-tester', 'multimedia creatorId, as expected');
    is($multimedia_list->[0]->size, length($data), 'multimedia size, as expected');
    is($multimedia_list->[0]->description, 'created by standard v3 t/soap-multimedia.t', 'description, as expected'); 

    my $start_time = Elive::Util::next_quarter_hour();
    my $end_time = Elive::Util::next_quarter_hour( $start_time);

    ok(my $session = Bb::Collaborate::V3::Session->insert({
	sessionName => 'created by t/soap-multimedia.t',
	creatorId => Bb::Collaborate::V3->connection->user,
	startTime => $start_time . '000',
	endTime => $end_time . '000',
	nonChairList => [qw(alice bob)],
    }),
	'inserted session');

    is( exception {
	$session->set_multimedia( $multimedia_list )
	} => undef,
	'$session->set_multimedia(...) - lives');

    isnt( exception {$multimedia_list->[0]->delete} => undef, 'deletion of referenced multimedia - dies');

    $multimedia_list = undef;

    $multimedia_list = $session->list_multimedia;

     die 'unable to continue without a multimedia list object'
	unless $multimedia_list && $multimedia_list->[0]; 

    isa_ok($multimedia_list->[0], $class, 'multimedia list object');
    is($multimedia_list->[0]->multimediaId, $multimedia_id, 'multimedia list id');

    is( exception {
	$session->remove_multimedia($multimedia_list->[0]);
	} => undef,
	'$session->removed_multimedia - lives'); 

    is( exception {$multimedia_list->[0]->delete} => undef, 'deletion of unreferenced multimedia - lives');

    is( exception {$session->delete} => undef, 'deletion of session - lives');

}

Bb::Collaborate::V3->disconnect;

