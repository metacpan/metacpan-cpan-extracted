#!perl -T

use Test::More;
use Test::Fatal qw/dies_ok lives_ok/;
# use File::Temp;
use DBI;
use DBD::SQLite;

use lib 't/lib';

use My::Schema;
use My::Model;

my $TEST_SIZE = 1000;

## Connect to a DB and dynamically build the DBIC model.
ok( my $dbh = DBI->connect("dbi:SQLite::memory:" , "" , "") , "Ok connected as a DBI");
ok( $dbh->{AutoCommit} = 1 , "Ok autocommit set");
ok( $dbh->do("CREATE TABLE simple_record(some_id INTEGER PRIMARY KEY AUTOINCREMENT , value INTEGER NOT NULL)") , "Ok creating some simple table");
ok( $dbh->do(qq{ CREATE TABLE complex_record(top_id INTEGER NOT NULL,
                                             middle_id VARCHAR(255) NOT NULL,
                                             bottom_id BOOLEAN NOT NULL,
                                             value INTEGER NOT NULL,
                                             PRIMARY KEY( top_id, middle_id , bottom_id )
                                             )
               }) , "Ok can create complex record table" );

## Build a schema dynamically.
ok( my $schema = My::Schema->connect(sub{ return $dbh ;} , { unsafe => 1 } ), "Ok built schema with dbh");
## Just to check
ok( $schema->resultset('SimpleRecord') , "Simple record is there");
ok( $schema->resultset('ComplexRecord') , "Complex record is there");


## Build a My::Model using it
ok( my $bm = My::Model->new({ dbic_schema => $schema }) , "Ok built a model");

ok( my $sf = $bm->dbic_factory('SimpleRecord') );
ok( my $cf =  $bm->dbic_factory('ComplexRecord') );

my @SIMPLE_ROWS = ();

# Insert a lot of dummy data
{
  my $i = 0;
  while( $i++ < $TEST_SIZE ){
    push @SIMPLE_ROWS , $sf->create({ value => $i });
  }
}
is( $sf->count() , $TEST_SIZE, "Ok got right number of dummy data");


my @COMPLEX_ROWS = ();

{
  my $top = 0;
  my $middle = 0;
  my $bottom = 0;

  my $n_rows = $TEST_SIZE;
  while( $n_rows-- ){
    push @COMPLEX_ROWS  , $cf->create({ top_id => $top,
                                        middle_id => 'STRING'.sprintf('%02d',$middle),
                                        bottom_id => $bottom,
                                        value => $n_rows
                                      });
    $bottom++;
    unless( $bottom = $bottom % 2 ){
      # Bottom has been reset
      $middle++;
      unless(  $middle = $middle % 100 ){
        # Middle has been reset
        $top++;
      }
    }
  }
}

is( $cf->count() , $TEST_SIZE , "Ok inserted right number of dummy data");


# Standard versions of loop through.
{
  my %ticks = map{ $_->some_id() => 1  } @SIMPLE_ROWS;

  my $simple_count = 0;
  $sf->search(undef , { order_by => 'some_id' })
    ->loop_through(sub{
                     my ($o) = @_;
                     delete $ticks{$o->some_id()};
                     $simple_count++;
                   }, { rows => 100 });
  is( $simple_count , $TEST_SIZE );
  ok( ! keys %ticks , "Ok no keys left");
}

{
  my %ticks = map{ join('-' , $_->id() ) => 1 } @COMPLEX_ROWS;

  my $complex_count = 0;
  $cf->search(undef , { order_by => [ { -asc => 'top_id' }, { -asc => 'middle_id' } , { -asc =>  'bottom_id' } ] })
    ->loop_through(sub{
                     my ($o) = @_;
                     delete $ticks{ join('-' , $o->id() )};
                     $complex_count++;
                   } , { rows => 100 });
  is( $complex_count , $TEST_SIZE );
  ok( ! keys %ticks , "Ok been through all records");
}

# Fast versions of loop through
{
  my %ticks = map{ join('-' , $_->id() ) => 1 } @SIMPLE_ROWS;

  my $simple_count = 0;
  $sf->search(undef)
    ->fast_loop_through(sub{
                          my ($o) = @_;
                          delete $ticks{ join('-' , $o->id() )};
                          $simple_count++;
                        });
  is( $simple_count , $TEST_SIZE );
  ok( ! keys %ticks , "Ok been through all records");
}

{
    # Test fast_loop_through simple with extra criteria
    my $simple_count = 0;
    $sf->search({ 'me.some_id' => { -between => [ 11 , 20 ] } })
        ->fast_loop_through(
            sub{
                my ($o) = @_;
                $simple_count++;
            });
    is( $simple_count , 10 , "Ok only 10 records");
}

{
  my %ticks = map{ join('-' , $_->id() ) => 1 } @COMPLEX_ROWS;

  my $complex_count = 0;
  $cf->search(undef)
    ->fast_loop_through(sub{
                          my ($o) = @_;
                          delete $ticks{ join('-' , $o->id() )};
                          $complex_count++;
                        });
  is( $complex_count , $TEST_SIZE );
  ok( ! keys %ticks , "Ok been through all records");
}

{
  # And now with reverse order
  my %ticks = map{ join('-' , $_->id() ) => 1 } @SIMPLE_ROWS;

  my $simple_count = 0;
  $sf->search(undef)
    ->fast_loop_through(sub{
                          my ($o) = @_;
                          delete $ticks{ join('-' , $o->id() )};
                          $simple_count++;
                        } , { order => 'desc' });
  is( $simple_count , $TEST_SIZE );
  ok( ! keys %ticks , "Ok been through all records");
}

{
  # Complex reverse order
  my %ticks = map{ join('-' , $_->id() ) => 1 } @COMPLEX_ROWS;

  my $complex_count = 0;
  $cf->search(undef)
    ->fast_loop_through(sub{
                          my ($o) = @_;
                          delete $ticks{ join('-' , $o->id() )};
                          $complex_count++;
                        } , { order => 'desc' } );
  is( $complex_count , $TEST_SIZE );
  ok( ! keys %ticks , "Ok been through all records");
}

# Delete random rows and check things are still consistent
my @NEW_SIMPLE_ROWS;
foreach my $row ( @SIMPLE_ROWS ){
  unless( rand(1) < 0.1 ){
    push @NEW_SIMPLE_ROWS  , $row;
    next;
  }
  $row->delete();
}

my @NEW_COMPLEX_ROWS;
foreach my $row ( @COMPLEX_ROWS ){
  unless( rand(1) < 0.1 ){
    push @NEW_COMPLEX_ROWS  , $row;
    next;
  }
  $row->delete();
}


{
  # Simple reverse order with deletions
  my %ticks = map{ join('-' , $_->id() ) => 1 } @NEW_SIMPLE_ROWS;

  my $simple_count = 0;
  $sf->search(undef)
    ->fast_loop_through(sub{
                          my ($o) = @_;
                          delete $ticks{ join('-' , $o->id() )};
                          $simple_count++;
                        } , { order => 'desc' });
  is( $simple_count , scalar(@NEW_SIMPLE_ROWS) );
  ok( ! keys %ticks , "Ok been through all records");
}

{
  # Complex reverse order with deletions
  my %ticks = map{ join('-' , $_->id() ) => 1 } @NEW_COMPLEX_ROWS;

  my $complex_count = 0;
  $cf->search(undef)
    ->fast_loop_through(sub{
                          my ($o) = @_;
                          delete $ticks{ join('-' , $o->id() )};
                          $complex_count++;
                        } , { order => 'desc' } );
  is( $complex_count , scalar(@NEW_COMPLEX_ROWS) );
  ok( ! keys %ticks , "Ok been through all records");
}




done_testing();
