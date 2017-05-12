#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use v5.10;

use lib 'lib';

use AnyEvent;
use AnyEvent::Pg::Pool::Multiserver;

my $servers = [
  {
    id   => 1,
    name => 'remote 1',
    conn => 'host=remote1 port=5432 dbname=mydb user=myuser password=mypass',
  },
  {
    id   => 2,
    name => 'remote 2',
    conn => 'host=remote2 port=5432 dbname=mydb user=myuser password=mypass',
  },
];
my $pool = AnyEvent::Pg::Pool::Multiserver->new( servers => $servers, local => 1 );

my $cv;

$cv = AE::cv;

# multi-server request

$pool->selectall_arrayref(
  query  => 'SELECT val FROM ( SELECT 1 AS val ) tmp WHERE tmp.val = $1;',
  args   => [ 1 ],
  cb     => sub {
    my $results = shift;
    my $errors  = shift;

    if ( $errors ) {
      foreach my $srv ( @$errors ) {
        say "err $srv->{error} with $srv->{server_name} $srv->{server_id}";
      }
    }

    if ( $results ) {
      foreach my $val ( @$results ) {
        say "server_id=$val->{_server_id} value=$val->{val}";
      }
    }

    $cv->send;
  },
);

$cv->recv;

$cv = AE::cv;

# single-server request

$pool->selectall_arrayref(
  query     => 'SELECT val FROM ( SELECT 1 AS val ) tmp WHERE tmp.val = $1;',
  args      => [ 1 ],
  server_id => 1,
  cb        => sub {
    my $results = shift;
    my $errors  = shift;

    if ( $errors ) {
      foreach my $srv ( @$errors ) {
        say "err $srv->{error} with $srv->{server_name} $srv->{server_id}";
      }
    }

    if ( $results ) {
      foreach my $val ( @$results ) {
        say "server_id=$val->{_server_id} value=$val->{val}";
      }
    }

    $cv->send;
  },
);

$cv->recv;

$cv = AE::cv;

# multi-server request with sub-callbacks to some data manipulation
# and may be to make another request to current server

# main request | server_1 select -> ... select end -> cb_server call -> subrequests to current server | wait both   | global callback
#              | server_2 select -> ... select end -> cb_server call -> subrequests to current server | subrequests |

$pool->selectall_arrayref(
  query  => 'SELECT val FROM ( SELECT 1 AS val ) tmp WHERE tmp.val = $1;',
  args   => [ 1 ],
  cb     => sub {
    my $results = shift;
    my $errors  = shift;

    if ( $errors ) {
      foreach my $srv ( @$errors ) {
        say "err $srv->{error} with $srv->{server_name} $srv->{server_id}";
      }
    }

    if ( $results ) {
      foreach my $val ( @$results ) {
        say "server_id=$val->{_server_id} value=$val->{val}";
      }
    }

    $cv->send;
  },
  cb_server => sub {
    my $params = { @_ };

    my $result_of_main_request = $params->{result};

    # Now we can do some sub-request to current server

    # And MUST call cb
    $params->{cb}->();
  },
);

$cv->recv;

# single-server request to select row in arrayref

$pool->selectrow_array(
  query     => 'SELECT val FROM ( SELECT 1 AS val ) tmp WHERE tmp.val = $1;',
  args      => [ 1 ],
  server_id => 1,
  cb        => sub {
    my $result = shift;
    my $error  = shift;

    if ( $error ) {
      say "err $error->{error} with $error->{server_name} $error->{server_id}";
    }

    if ( $result ) {
      say "server_id=$result->[ 0 ] value=$result->[ 1 ]";
    }

    $cv->send;
  },
);

$cv->recv;

$cv->recv;

# single-server request to select row in hashref

$pool->selectrow_hashref(
  query     => 'SELECT val FROM ( SELECT 1 AS val ) tmp WHERE tmp.val = $1;',
  args      => [ 1 ],
  server_id => 1,
  cb        => sub {
    my $result = shift;
    my $error  = shift;

    if ( $error ) {
      say "err $error->{error} with $error->{server_name} $error->{server_id}";
    }

    if ( $result ) {
      say "server_id=$result->{_server_id} value=$result->{val}";
    }

    $cv->send;
  },
);

$cv->recv;

$cv->recv;

# single-server request to do something

$pool->do(
  query     => 'UPDATE table SET column = 1 WHERE id = $1;',
  args      => [ 1 ],
  server_id => 1,
  cb        => sub {
    my $result = shift;
    my $error  = shift;

    if ( $error ) {
      say "err $error->{error} with $error->{server_name} $error->{server_id}";
    }

    if ( $result ) {
      say "server_id=$result->[ 0 ] updated=$result->[ 1 ]";
    }

    $cv->send;
  },
);

$cv->recv;

$cv->recv;

# local-server request to do something

$pool->do(
  query     => 'UPDATE table SET column = 1 WHERE id = $1;',
  args      => [ 1 ],
  server_id => $pool->local(),
  cb        => sub {
    my $result = shift;
    my $error  = shift;

    if ( $error ) {
      say "err $error->{error} with $error->{server_name} $error->{server_id}";
    }

    if ( $result ) {
      say "server_id=$result->[ 0 ] updated=$result->[ 1 ]";
    }

    $cv->send;
  },
);

$cv->recv;

