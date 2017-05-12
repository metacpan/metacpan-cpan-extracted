use strict;
use warnings;
use Test::More tests => 2;
use Archive::Ar::Libarchive;

subtest defaults => sub {
  plan tests => 11;

  my $ar = Archive::Ar::Libarchive->new;
  
  is $ar->add_data("1",       'one'), 3, 'add_data';
  is $ar->add_data("foo.txt", 'bar'), 3, 'add_data';
  is $ar->add_data("2",       'two'), 3, 'add_data';

  my $data = $ar->get_content('foo.txt');
  is $data->{name}, 'foo.txt', 'name';
  like $data->{date}, qr{^[1-9]\d*$}, 'date';
  is $data->{uid}, 0, 'uid';
  is $data->{gid}, 0, 'gid';
  is $data->{mode}, 0100644, 'mode';
  is $data->{data}, 'bar', 'data';
  is $data->{size}, 3, 'size';
  
  is $ar->get_content('goose'), undef, 'not found';
};

subtest 'non default values' => sub {

  my $ar = Archive::Ar::Libarchive->new;
  
  is $ar->add_data("1",       'one'), 3, 'add_data';
  
  is $ar->add_data("foo.txt", 'barbaz', {
    uid  => 101,
    gid  => 201,
    mode => 0644,
  }), 6, 'add_data';
  
  is $ar->add_data("2",       'two'), 3, 'add_data';

  my $data = $ar->get_content('foo.txt');
  is $data->{name}, 'foo.txt', 'name';
  like $data->{date}, qr{^[1-9]\d*$}, 'date';
  is $data->{uid}, 101, 'uid';
  is $data->{gid}, 201, 'gid';
  is $data->{mode}, 0644, 'mode';
  is $data->{data}, 'barbaz', 'data';
  is $data->{size}, 6, 'size';
  
  is $ar->get_content('goose'), undef, 'not found';
};
