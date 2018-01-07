use strict;
use warnings;

use Test::More;
use Test::Deep; # (); # uncomment to stop prototype errors
use Test::Exception;

use YAML::Any qw( LoadFile );

use_ok('App::Jiffy::TimeEntry');

my $cfg = LoadFile('t/test.yml');

my $client = MongoDB::MongoClient->new;
my $db = $client->get_database( 'jiffy-test' );

subtest 'prep' => sub {
  ok $db->drop, 'cleared db';
};
subtest 'Attributes' => sub {
  my $time_entry = App::Jiffy::TimeEntry->new(
    title => 'Thing',
    cfg => $cfg,
  );
  can_ok $time_entry, (
    # attributes
    'title',
    'start_time',
    'id',
    # subs
    'db',
    'save',
  );

  subtest 'save' => sub {
      my $id;
      subtest 'insert' => sub {
        is_deeply [ $db->get_collection('timeEntry')->find->all ], [],
          'starts with no documents';
        lives_ok {
            $id = $time_entry->save();
        } 'saving doesn\'t die';
        isa_ok $id, 'MongoDB::OID', 'saving returns OID';
        is $time_entry->id, $id, 'id is set';
      };

      # Depends on previous subtest working...
      subtest 'update' => sub {
        ok $db->get_collection('timeEntry')->find_one({ _id => $id }), 'found timeEntry';
        my $entry = App::Jiffy::TimeEntry::find( $cfg, $id );
        is $entry->title, 'Thing', 'title starts out with expected value';
        $entry->title('Bar');
        lives_ok {
            $entry->save;
        } 'save lives ok when updating';
        my $entry_after = $db->get_collection('timeEntry')->find_one({ _id => $id });
        is $entry_after->{ title }, 'Bar', 'title changes correctly';
      };
  };
};
subtest 'Class methods' => sub {
  subtest 'last_entry' => sub {
    my $time_entry = App::Jiffy::TimeEntry->new(
      title => 'Latest thing',
      cfg => $cfg,
      # Add a day to ensure it comes up last. If you don't the previously
      # created item can come up as last
      start_time => DateTime->now->add( days => 1 ),
    );
    ok $time_entry->save, 'create entry';

    my $last_entry = App::Jiffy::TimeEntry::last_entry($cfg);
    is $last_entry->id, $time_entry->id, 'received latest entry';
  };
};

done_testing;
