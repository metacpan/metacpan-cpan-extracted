use strict;
use warnings;

# without this the stacktrace of $schema will be activated
BEGIN { $ENV{DBIO_TRACE} = 0 }

use Test::More;
use Test::Warn;
use Test::Exception;
use DBIO::Test;
use DBIO::Carp;

{
  sub DBIO::Test::DBIOCarp::frobnicate {
    DBIO::Test::DBIOCarp::branch1();
    DBIO::Test::DBIOCarp::branch2();
  }

  sub DBIO::Test::DBIOCarp::branch1 { carp_once 'carp1' }
  sub DBIO::Test::DBIOCarp::branch2 { carp_once 'carp2' }


  warnings_exist {
    DBIO::Test::DBIOCarp::frobnicate();
  } [
    qr/carp1/,
    qr/carp2/,
  ], 'expected warnings from carp_once';
}

{
  {
    package DBIO::Test::DBIOCarp::Exempt;
    use DBIO::Carp;

    sub _skip_namespace_frames { qr/^DBIO::Test::DBIOCarp::Exempt/ }

    sub thrower {
      sub {
        DBIO::Test->init_schema(no_deploy => 1)->storage->dbh_do(sub {
          shift->throw_exception('time to die');
        })
      }->();
    }

    sub dcaller {
      sub {
        thrower();
      }->();
    }

    sub warner {
      eval {
        sub {
          eval {
            carp ('time to warn')
          }
        }->()
      }
    }

    sub wcaller {
      warner();
    }
  }

  # the __LINE__ relationship below is important - do not reformat
  throws_ok { DBIO::Test::DBIOCarp::Exempt::dcaller() }
    qr/\QDBIO::Test::DBIOCarp::Exempt::thrower(): time to die at @{[ __FILE__ ]} line @{[ __LINE__ - 1 ]}\E$/,
    'Expected exception callsite and originator'
  ;

  # the __LINE__ relationship below is important - do not reformat
  warnings_like { DBIO::Test::DBIOCarp::Exempt::wcaller() }
    qr/\QDBIO::Test::DBIOCarp::Exempt::warner(): time to warn at @{[ __FILE__ ]} line @{[ __LINE__ - 1 ]}\E$/,
  ;
}

done_testing;
