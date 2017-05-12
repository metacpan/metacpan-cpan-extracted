#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->parent->parent->subdir('t', 'lib')->stringify;

use Test::DBIx::Class;

fixtures_ok 'basic', 'installed the basic fixtures from configuration files';

# tests for ->add_column() being called

{
  throws_ok {
    Schema->resultset('Artist')->result_source->column_info('guess');
  } qr/No such column ['"`]?guess['"`]?/,
    "the 'guess' attribute has no column_info";

  lives_and {
    cmp_deeply(
      Schema->resultset('Artist')->result_source->column_info('artist_id'),
      superhashof({
        is_auto_increment => 1,
      })
    );
  } "column_info of 'id' contains ('is_auto_increment' => 1)";

  lives_and {
    cmp_deeply(
      Schema->resultset('Artist')->result_source->column_info('name'),
      superhashof({
        is_nullable => 0,
      })
    );
  } "column_info of 'name' contains ('is_nullable' => 0)";
}

# tests for the reader/writer

{
  my $artist1 = Schema->resultset('Artist')->find({ artist_id => 1 });

  lives_and {
    cmp_deeply(
      $artist1->name,
      'foo'
    );
  } "value returned by 'name' accessor is 'foo'";

  lives_and {
    cmp_deeply(
      $artist1->name('bar'),
      'bar'
    );
  } "calling the 'name' accessor to set 'name' to 'bar' returns 'bar'";

  lives_and {
    cmp_deeply(
      $artist1->get_column('name'),
      'bar'
    );
  } "value returned by get_column('name') is 'bar'";

  lives_and {
    cmp_deeply(
      $artist1->name('bar'),
      'bar'
    );
  } "value returned by 'name' accessor is 'bar'";

  lives_ok {
    $artist1->set_column(name => 'quux');
  } "calling set_column('name', 'quux') does not die";

  lives_and {
    cmp_deeply(
      $artist1->name,
      'quux'
    );
  } "value returned by 'name' accessor is 'quux'";


  lives_and {
    cmp_deeply(
      $artist1->name(undef),
      undef
    );
  } "calling the 'name' accessor to set 'name' to undef returns undef";

  lives_and {
    cmp_deeply(
      $artist1->get_column('name'),
      undef
    );
  } "value returned by get_column('name') is undef";

  lives_and {
    cmp_deeply(
      $artist1->name,
      undef
    );
  } "value returned by 'name' accessor is undef";
}

# tests for the predicate method

{
  my $artist1 = Schema->resultset('Artist')->find({ artist_id => 1 });

  lives_and {
    cmp_deeply(
      $artist1->has_name,
      bool(1)
    );
  } "'has_name' predicate returns true for a loaded column";

  lives_ok {
    $artist1 = Schema->resultset('Artist')->new({ artist_id => 1 });
  } "'new' does not die";

  lives_and {
    cmp_deeply(
      $artist1->has_name,
      bool(0)
    );
  } "'has_name' predicate returns false for an uninitialized column";
}

# tests for the clearer method

{
  my $artist1 = Schema->resultset('Artist')->find({ artist_id => 1 });

  TODO: {
    local $TODO = "Currently the clearer is unimplemented";

    lives_ok {
      $artist1->clear_name;
    } "'clear_name' does not die";

    lives_and {
      cmp_deeply(
        $artist1->has_name,
        bool(1)
      );
    } "'has_name' predicate returns true for a cleared column";
  }
}

# tests for using the default value ('default' attribute option)

{
  my $artist1;
  lives_ok {
    $artist1 = Schema->resultset('Artist')->new({
      artist_id => 1,
    });
  } "'new' does not die";

  lives_and {
    cmp_deeply(
      $artist1->is_active,
      1,
    );
  } "'is_active' accessor returns the default value";
}

# tests for the builder method

{
  my $artist1;
  lives_ok {
    $artist1 = Schema->resultset('Artist')->new({
      artist_id => 1,
      name      => 'John Lennon',
    });
  } "'new' does not die";

  lives_and {
    cmp_deeply(
      $artist1->initials,
      'JL'
    );
  } "'initials' accessor returns the value built by the builder";
}

# tests for the initializer method

{
  my $artist1;
  lives_ok {
    $artist1 = Schema->resultset('Artist')->new({
      artist_id       => 1,
      favourite_color => 'BLUE',
    });
  } "'new' does not die";

  lives_and {
    cmp_deeply(
      $artist1->favourite_color,
      'blue'
    );
  } "'favourite_color' accessor returns the value munged by the initializer";
}

# tests for custom accessor name

{
  my $artist1 = Schema->resultset('Artist')->find({ artist_id => 1 });

  lives_and {
    cmp_deeply(
      $artist1->title,
      'Dr'
    );
  } "value returned by 'title' method is 'Dr'";

  lives_and {
    cmp_deeply(
      $artist1->title('Prof'),
      'Prof'
    );
  } "calling the 'title' method to set 'title' to 'Prof' returns 'Prof'";

  lives_and {
    cmp_deeply(
      $artist1->get_column('title'),
      'Prof'
    );
  } "value returned by get_column('title') is 'Prof'";

  lives_and {
    cmp_deeply(
      $artist1->title('Prof'),
      'Prof'
    );
  } "value returned by 'title' method is 'Prof'";

  throws_ok {
    $artist1->title('Mr')
  } qr/Invalid title/,
    "calling set_column('title', 'Mr') dies";

  lives_ok {
    $artist1->set_column(title => undef);
  } "calling set_column('title', undef) does not die";

  lives_and {
    cmp_deeply(
      $artist1->title,
      undef
    );
  } "value returned by 'title' method is undef";
}

# tests for the trigger method

{
  my $artist1 = Schema->resultset('Artist')->find({ artist_id => 1 });

  $artist1->is_active(0);

  lives_ok {
    $artist1->last_album('Foo Bar');
  } "setting the attribute with the trigger does not throw";

  cmp_deeply(
    $artist1->is_active,
    1,
    "the trigger set the 'is_active' attribute"
  );
}

#FIXME other methods/options

done_testing;
