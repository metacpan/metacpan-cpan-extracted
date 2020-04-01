#!/usr/bin/env perl

use strict;
use warnings;

use utf8;

use Test::More;
use Test::Deep;
use Test::Exception;
use Capture::Tiny ':all';
use MongoDB;

use lib 't/lib';

use MongoDBTest 'test_db_or_skip';

use CreateTimeEntries qw/generate/;

use YAML::Any qw( LoadFile );

my $cfg = LoadFile('t/test.yml');

test_db_or_skip($cfg);

use_ok('App::Jiffy');

my $client = MongoDB::MongoClient->new;
my $db     = $client->get_database('jiffy-test');
my $app    = App::Jiffy->new( cfg => $cfg, );

subtest 'prep' => sub {
  ok $db->drop, 'cleared db';
};

subtest 'STDOUT' => sub {
  my @layers = PerlIO::get_layers(STDOUT);

  ok grep( /utf8/, @layers ), 'set to utf8';
};

subtest 'add_entry' => sub {
  subtest 'works on UTC edge cases' => sub {
    {
      no warnings 'redefine';
      local *DateTime::now = sub {
        DateTime->new(
          day       => 10,
          hour      => 20,
          minute    => 0,
          year      => 2016,
          month     => 2,
          time_zone => 'local',
        );
      };
      $ENV{TZ} = 'America/Chicago';

      $app->add_entry( {
          time => '18:37',
        },
        'Next day for UTC'
      );

      my @entries = App::Jiffy::TimeEntry::search(
        $cfg,
        query => {
          title => 'Next day for UTC',
        },
      );
      is scalar @entries, 1, 'created timeEntry w/ time option';

      is $entries[0]->start_time->hour, 18, 'got Chicago hour';
      is $entries[0]->start_time->day,  10, 'got Chicago day';
      ok $entries[0]->duration->is_positive, 'Doesn\'t go back in time';
    }
  };
};

subtest 'current' => sub {
  ok $db->drop, 'cleared db';

  # Seed db
  generate(
    $cfg,
    [ {
        start_time => {
          days => 1,
        },
      },
      {
        start_time => {
          hours => 23,
        },
        title => 'done',
      },
      { title => 'foobarbaz' }    # Current Entry
    ] );

  subtest 'returns current entry title' => sub {
    my ( $stdout, $stderr, $exit ) = capture {
      $app->current_time();
    };

    like $stdout, qr/foobarbaz/, 'returns title';
  };
};

subtest 'timesheet' => sub {
  ok $db->drop, 'cleared db';

  # Seed db
  generate(
    $cfg,
    [ {
        start_time => {
          days => 1,
        },
      },
      {
        start_time => {
          hours => 23,
        },
        title => 'done',
      },
      {}    # Default Entry
    ] );

  subtest 'for multiple days' => sub {
    my ( $stdout, $stderr, $exit ) = capture {
      $app->time_sheet(2);
    };

    like $stdout, qr/\d{2}\/\d{2}\/\d{4}/, 'returns datetimes';
  };

  subtest 'can be verbose' => sub {
    my ( $stdout, $stderr, $exit ) = capture {
      $app->time_sheet( {
        verbose => 1,
      } );
    };

    like $stdout, qr/\d{1,2}:\d{2}/, 'found times';
  };

  subtest 'can be rounded' => sub {
    ok $db->drop, 'cleared db';

    # Seed db
    my $now = DateTime->now->subtract( hours => 1 );
    generate(
      $cfg,
      [ {
          start_time => sub {
            return $now->clone()->set_minute(0);
          },
        },
        {
          start_time => sub {
            return $now->clone()->set_minute(23);
          },
          title => 'done',
        },
        {
          start_time => sub {
            return $now->clone()->set( {
              minute => 30,
              second => 0,
            } );
          },
        },
        {
          start_time => sub {
            return $now->clone()->set( {
              minute => 37,
              second => 30,
            } );
          },
          title => 'done',
        },
      ] );

    my ( $stdout, $stderr, $exit ) = capture {
      $app->time_sheet( {
        round => 1,
      } );
    };

    like $stdout, qr/30 minutes/, 'found minute rounded time';
    like $stdout, qr/15 minutes/, 'found second then minute rounded time';
  };
};

subtest 'search' => sub {

  subtest 'w/ regex' => sub {

    # Populate
    ok $db->drop, 'cleared db';
    generate(
      $cfg,
      [ {
          title => 'Company A - Stuff',
        },
        {
          title => 'Company B - Other Stuff',
        },
        {
          title => 'Company A  - More Stuff',
        },
      ] );

    my ( $stdout, $stderr, $exit ) = capture {
      $app->search('^Company\sA\s*-');
    };

    unlike $stdout, qr/Company B/m,     'Didn\'t print other entries';
    like $stdout,   qr/- Stuff$/m,      'Found first entry';
    like $stdout,   qr/- More Stuff$/m, 'Found second entry';
  };

  subtest 'w/ plain text' => sub {

    # Populate
    ok $db->drop, 'cleared db';
    generate(
      $cfg,
      [ {
          title => 'Company A - Stuff',
        },
        {
          title => 'Company B - Other Stuff',
        },
        {
          title => 'Company A  - More Stuff',
        },
      ] );

    my ( $stdout, $stderr, $exit ) = capture {
      $app->search('Company A');
    };

    unlike $stdout, qr/Company B/m,     'Didn\'t print other entries';
    like $stdout,   qr/- Stuff$/m,      'Found first entry';
    like $stdout,   qr/- More Stuff$/m, 'Found second entry';
  };

  subtest 'w/ multiple days' => sub {

    # Populate
    ok $db->drop, 'cleared db';
    generate(
      $cfg,
      [ {
          title      => 'Company A - Foo',
          start_time => {
            days => 3,
          },
        },
        {
          title      => 'Company C - Bar',
          start_time => {
            days => 1,
          },
        },
        {
          title => 'Company B - Baz',
        },
      ] );

    my ( $stdout, $stderr, $exit ) = capture {
      $app->search( '^Company \w -', 2 );
    };

    unlike $stdout, qr/Company A/m, 'Didn\'t print older entry';
    like $stdout,   qr/Company C/m, 'Found one day old entry';
    like $stdout,   qr/Company B/m, 'Found today\'s entry';
  };

  subtest 'w/ no matches' => sub {

    # Populate
    ok $db->drop, 'cleared db';
    generate( $cfg,
      [ { title => 'Foo', }, { title => 'Bar', }, { title => 'Biz', }, ] );

    my ( $stdout, $stderr, $exit ) = capture {
      $app->search('Baz');
    };

    unlike $stdout, qr/Foo|Bar|Biz/m,      'Didn\'t report entries';
    like $stdout,   qr/No Entries Found/m, 'Shows "Not Found" message';
  };
};

done_testing;
