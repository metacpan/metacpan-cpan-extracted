#!/usr/bin/env perl 
use strict;
use warnings;
use feature qw(say);
use IO::Async::Loop;
use DBIx::Async;
my $loop = IO::Async::Loop->new;
say 'Connecting to db';
$loop->add(my $dbh = DBIx::Async->connect(
  'dbi:SQLite:dbname=:memory:',
  '',
  '', {
    AutoCommit => 1,
    RaiseError => 1,
  }
));
$dbh->do(q{CREATE TABLE tmp(id integer primary key autoincrement, content text)})
# ... put some values in it
->then(sub { $dbh->do(q{INSERT INTO tmp(content) VALUES ('some text'), ('other text') , ('more data')}) })
# ... and then read them back
->then(sub {
  # obviously you'd never really use * in a query like this...
  my $sth = $dbh->prepare(q{select * from tmp});
  $sth->execute;
  # the while($row = fetchrow_hashref) construct isn't a good fit
  # but we attempt to provide something reasonably close using the
  # ->iterate helper
  $sth->iterate(
    fetchrow_hashref => sub {
      my $row = shift;
      say "Row: " . join(',', %$row);
    }
  );
})->on_done(sub {
  say "Query complete";
})->on_fail(sub { warn "Failure: @_\n" })->get;


