package TestAppBothWith;

use Dancer2;

BEGIN {
   set logger     => 'null';
   set serializer => 'JSON';

   set plugins => {
      'DBIx::Class' => {
         default => {
            schema_class => 'FirstSchemaWith',
            dsn          => 'dbi:SQLite:t/db/test_database.sqlite3',
         },
         second => {
            schema_class => 'SecondSchemaWith',
            dsn          => 'dbi:SQLite:t/db/test_database2.sqlite3',
         },
         third => { alias => 'second' }
      }
   };
}

use Dancer2::Plugin::DBIx::Class;

get '/test_rs'        => sub { [ rs('Human')->result_source->columns ] };
get '/test_rset'      => sub { [ rset('Human')->result_source->columns ] };
get '/test_resultset' =>
   sub { [ resultset('Human')->result_source->columns ] };
get '/test_schema' =>
   sub { [ schema->resultset('Human')->result_source->columns ] };
get '/test_defschema' =>
   sub { [ schema('default')->resultset('Human')->result_source->columns ] };
get '/test_otherschema' =>
   sub { [ schema('second')->resultset('Human')->result_source->columns ] };
get '/test_alias' =>
   sub { [ schema('third')->resultset('Human')->result_source->columns ] };
get '/test_humans' => sub { [ humans->result_source->columns ] };
get '/test_human'  => sub {
   my %human = human(1)->get_columns();
   return \%human;
};

get '/test_mugs' => sub { [ mugs->result_source->columns ] };
get '/test_mug'  => sub {
   my %mug = mug(1)->get_columns();
   return \%mug;
};

get '/test_session' => sub {
   my %session = session(1)->get_columns();
   return \%session;
};
get '/test_sessions' => sub { [ sessions->result_source->columns ] };

1;
