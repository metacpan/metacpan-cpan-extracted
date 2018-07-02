use Modern::Perl;
use Data::Dumper;
use Test::More qw(no_plan);
use Plack::Test;
use HTTP::Request::Common;
use File::Temp qw(tempfile);

eval 'require DBD::SQLite';
our $TEST_DB=!$@;

our $SESSION;
our $DBC;
my $class='Dancer2::Session::DatabasePlugin';
require_ok($class);
use_ok($class);

my $self=$class->new;

our $DB;
our $FH;
our ($FH2,$DB2);
BEGIN {
  ($FH,$DB)=tempfile(EXLOCK=>0);
  ($FH2,$DB2)=tempfile(EXLOCK=>0);
}

cmp_ok($self->create_flush_query,'eq','INSERT into SESSIONS (SESSION_ID,SESSION_DATA) values (?,?)','Validate INSERT');
cmp_ok($self->create_retrieve_query,'eq','SELECT SESSION_DATA FROM SESSIONS WHERE SESSION_ID=?','Validate SELECT');
cmp_ok($self->create_sessions_query,'eq','SELECT SESSION_ID FROM SESSIONS','Validate SELECT_ALL');
cmp_ok($self->create_destroy_query,'eq','DELETE FROM SESSIONS WHERE SESSION_ID=?','Validate DELETE');
cmp_ok($self->create_update_query,'eq','UPDATE SESSIONS SET SESSION_DATA=? WHERE SESSION_ID=?','Validate UPDATE');
cmp_ok($self->create_change_query,'eq','UPDATE SESSIONS SET SESSION_ID=? WHERE SESSION_ID=?','Validate RENAME');

my $app=Test::Session->to_app;

my $h='Set-Cookie';
is( ref $app, 'CODE', 'Got app' );
my $test = Plack::Test->create($app);

SKIP: {
  skip 'Cannot load DBD::SQLite',33 unless $TEST_DB;
  skip 'Cannot create test database',33 unless $FH;
  skip '$ENV{ENABLE_DB_TESTING} is false',33 unless $ENV{ENABLE_DB_TESTING};
  {
    my $res  = $test->request( GET '/setup' );
    cmp_ok($res->code,'==',200,'Should get a 200');
    ok(!$res->header($h),'Should not have a cookie!');
    cmp_ok(keys(%{$SESSION->sth_cache}),'==',0,'Should have 0 statement handles');
  }
  {
    my $res  = $test->request( GET '/' );
    cmp_ok($res->code,'==',200,'Should get a 200');
    ok(!$res->header($h),'Should not have a cookie!');
    cmp_ok(keys(%{$SESSION->sth_cache}),'==',0,'Should have 0 statement handles');
  }
  
  my $cookie;
  {
    my $res  = $test->request( GET '/session/create' );
    cmp_ok($res->code,'==',200,'Should get a 200');
    ok($cookie=$res->header($h),'Should have a cookie!');
    cmp_ok(keys(%{$SESSION->sth_cache}),'==',3,'Should have 3 statement handles') or die Dumper($SESSION->sth_cache);
  }
  
  my $saved={%{$SESSION->sth_cache}};
  {
    my $req=GET '/session/fetch',Cookie=>$cookie;
    my $res  = $test->request( $req );
    cmp_ok($res->code,'==',200,'Should get a 200');
    ok($cookie=$res->header($h),'Should have a cookie!');
    cmp_ok($res->decoded_content,'eq','I am a little teapot.');
    cmp_ok(keys(%{$SESSION->sth_cache}),'>',0,'Should have more than 0 statement handles');
  
  }
  {
    my $req=GET '/session/fetch',Cookie=>$cookie;
    my $res  = $test->request( $req );
    cmp_ok($res->code,'==',200,'Should get a 200');
    ok($cookie=$res->header($h),'Should have a cookie!');
    cmp_ok($res->decoded_content,'eq','I am a little teapot.');
    cmp_ok(keys(%{$SESSION->sth_cache}),'>',0,'Should have more than 0 statement handles');
    my @keys=keys %{$saved};
    is_deeply($saved,$SESSION->sth_cache,'Should have the same sth cache in both places') or die "Cannot continue testing";
    ok(join('',@{$saved}{@keys}) eq join('',@{$SESSION->sth_cache}{@keys}),'Statement handles should be cached') or die "cannot continue testing";

  }
  
  {
    my $req=GET 'disconnect',Cookie=>$cookie;
    my $res  = $test->request( $req );
    $DBC->('foo')->selectall_arrayref('select * from sessions');
    cmp_ok($res->code,'==',200,'Should get a 200');
    cmp_ok(keys(%{$SESSION->sth_cache}),'==',0,'post db reconnection, we should have 0 statement handles');
  
  }
  {
    my $req=GET '/bad/query',Cookie=>$cookie;
    my $res  = $test->request( $req );
    cmp_ok($res->code,'==',500,'Should get a 500');
    cmp_ok(keys(%{$SESSION->sth_cache}),'==',0,'Should have 0 statement handles');
  }
  
  {
    ok($SESSION->_change_id('tuesday','taco tuesday'),'Update should go through');
    my $results=$DBC->('foo')->selectall_arrayref(
        q{select * from sessions where session_id='taco tuesday'},
        {Slice=>{}}
      );
    diag Dumper($results);
    is_deeply($results ,
      [{ session_id=>'taco tuesday', session_data=>undef}],
      'validate session rename'
    );
    ok($SESSION->_destroy('taco tuesday'),'delete should go through');
    $results=$DBC->('foo')->selectall_arrayref(
        q{select * from sessions where session_id='taco tuesday'},
        {Slice=>{}}
      );
    diag Dumper($results);
    is_deeply($results ,
      [],
      'validate session delete'
    );
  }
  {
    my $req=GET '/session/fetch',Cookie=>$cookie;
    my $res  = $test->request( $req );
    cmp_ok($res->code,'==',200,'Should get a 200');
    ok($cookie=$res->header($h),'Should have a cookie!');
    cmp_ok($res->decoded_content,'eq','I am a little teapot.');
    cmp_ok(keys(%{$SESSION->sth_cache}),'>',0,'Should have more than 0 statement handles');
  }
  {
    my $req=GET 'disconnect2',Cookie=>$cookie;
    my $res  = $test->request( $req );
    cmp_ok($res->code,'==',200,'Should get a 200');
    cmp_ok(keys(%{$SESSION->sth_cache}),'>',0,'Should have more than 0 statement handles');
  }
  {
    my $req=GET '/bad/query2',Cookie=>$cookie;
    my $res  = $test->request( $req );
    cmp_ok($res->code,'==',500,'Should get a 500');
    cmp_ok(keys(%{$SESSION->sth_cache}),'>',0,'Should have more than 0 statement handles');
  }
  diag $cookie;
  done_testing;
}

{
  package
     Test::Session;
  use Modern::Perl;
  use Dancer2;
  use FindBin qw($Bin);
  use Data::Dumper;
  use Dancer2::Plugin::Database;
  use Dancer2::Plugin::SessionDatabase;
  BEGIN {
    #set session=>'YAML';
    set session=>'DatabasePlugin';
    set engines=>{
      session=>{ 
        DatabasePlugin=>{
          connection=>"foo",
        }
      }
    };
    set plugins=>{
      Database=>{
        connections=>{
	  foo=>{
	    driver=>'SQLite',
	    database=>$DB,
	    dbi_params=>{
	      RaiseError=>1,
	    }
	  },
	  bar=>{
	    driver=>'SQLite',
	    database=>$DB2,
	    dbi_params=>{
	      RaiseError=>1,
	    }
	  },
        },
      }
    };

  #main::diag Dumper config;
  $DBC=\&database;

  # setup our test table
  get '/setup'=>sub {
    $SESSION=engine 'session';
    database('foo')->do('create table sessions (session_id varchar unique,session_data blob)');
    database('foo')->do('insert into sessions (session_id) values ("tuesday")');
    database('bar')->do('create table sessions (session_id varchar unique,session_data blob)');
    database('bar')->do('insert into sessions (session_id) values ("tuesday")');
  };

  get '/'=>sub {
    $SESSION=engine 'session';
    return "test";
  };
  get '/session/create'=>sub {
    $SESSION=engine 'session';
    session test=>'I am a little teapot.';
    return "session test";
  };
  get '/session/fetch'=>sub {
    $SESSION=engine 'session';
    return session 'test';
  };
  get '/session/update'=>sub {
    $SESSION=engine 'session';
    session test=>'short and stout.';
    return "session test";
  };
  get '/bad/query'=>sub {
    my $dbh=database('foo');
    $dbh->prepare('select * from DoesNotExist!!!');
  };
  get '/bad/query2'=>sub {
    my $dbh=database('bar');
    $dbh->prepare('select * from DoesNotExist!!!');
  };
  get '/disconnect'=>sub {
    my $dbh=database('foo');
    $dbh->disconnect;
  };
  get '/disconnect2'=>sub {
    my $dbh=database('foo');
    $dbh->disconnect;
  };
  }
}
