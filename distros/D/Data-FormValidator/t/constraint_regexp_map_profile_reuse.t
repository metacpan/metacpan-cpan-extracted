#!/usr/bin/env perl
use strict;
use warnings;
use Test::More (qw/no_plan/);
use Data::FormValidator;

my $profile = {
  required              => [qw( test1 )],
  constraint_regexp_map => {
    qr/^test/ => 'email',
  },
};

my $data = { test1 => 'not an email', };

my $results1 = Data::FormValidator->check( $data, $profile );
my $c1       = { %{ $profile->{constraints} } };
my $results2 = Data::FormValidator->check( $data, $profile );
my $c2       = { %{ $profile->{constraints} } };

is_deeply( $results1->{profile}, $results2->{profile},
  "constraints aren't duped when profile with constraint_regexp_map is reused"
);
is_deeply( $c1, $c2,
  "constraints aren't duped when profile with constraint_regexp_map is reused"
);

{
  my $profile = {
    required                => [qw( test1 )],
    field_filter_regexp_map => {
      qr/^test/ => 'trim',
    },
  };

  my $data = { test1 => ' not an email ', };

  my $results1 = Data::FormValidator->check( $data, $profile );
  my $c1       = { %{ $profile->{constraints} } };
  my $results2 = Data::FormValidator->check( $data, $profile );
  my $c2       = { %{ $profile->{constraints} } };
  is_deeply( $results1->{profile}, $results2->{profile},
    "field_filters aren't duped when profile with field_filter_regexp_map is reused"
  );
  is_deeply( $c1, $c2,
    "field_filters aren't duped when profile with field_filter_regexp_map is reused"
  );

}
