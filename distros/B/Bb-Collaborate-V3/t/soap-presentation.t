#!perl -T
use warnings; use strict;
use Test::More tests => 3;
use Test::Fatal;

use lib '.';
use t::Bb::Collaborate::V3;

use Bb::Collaborate::V3::Presentation;

our $t = Test::More->builder;
my $class = 'Bb::Collaborate::V3::Presentation';

my $data = 'random junk data U(&(* 090 -0';

SKIP: {

    my %result = t::Bb::Collaborate::V3->test_connection();
    my $auth = $result{auth};

    skip ($result{reason} || 'skipping live tests', 3)
	unless $auth;

    my $connection_class = $result{class};
    my $connection = $connection_class->connect(@$auth);
    Bb::Collaborate::V3->connection($connection);

    my $presentation;

  TODO : {
      local($TODO) = 'UploadRespositoryPresentation - mixed up filename and description in response?'
          if $connection->scheduling_manager->manager eq 'ELM';
      is( exception {
	  $presentation = Bb::Collaborate::V3::Presentation->upload(
	      {
		filename => 'elive-standardv3-soap-session-presentation-t.wbd',
		content => $data,
                description => 'created by standard v3 t/soap-presentation.t',
		creatorId => 'elive-standardv3-tester',
	      })
	       } => undef,
	       'insert presentation - lives'
	  );
  };

    skip('unable to continue without an object', 2)
	unless $presentation;

    isa_ok($presentation, $class, 'multimedia object');

    #
    # Body of tests to be adapted from Elive/t/soap-preload.t
    #

    is( exception {$presentation->delete} => undef, 'presentation deletion - lives');
}

Bb::Collaborate::V3->disconnect;

