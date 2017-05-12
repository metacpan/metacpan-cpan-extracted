use strict;
use warnings;

use Test::More tests => 5;
use Data::InputMonster;

sub stash_a {
  my ($entry) = @_;
  return sub {
    my ($monster, $input) = @_;
    return $input->{a}->{ $entry };
  };
}

sub stash_b {
  my ($entry) = @_;
  return sub {
    my ($monster, $input, $arg) = @_;
    my $entry = defined $entry ? $entry : $arg->{field_name};
    return $input->{b}->{ $entry };
  };
}

sub update_href {
  my ($hash_ref, $field) = @_;
  return sub {
    my ($monster, $arg) = @_;

    return if $arg->{source} eq 'hash';

    Carp::croak("cowardly refusing to overwrite existing entry")
      if exists $hash_ref->{$field};

    $hash_ref->{ $field } = $arg->{value};
  };
}

my %stored_data;

sub check_hash {
  my ($field) = @_;
  sub {
    return exists $stored_data{$field} ? $stored_data{$field} : ();
  }
}

my $monster = Data::InputMonster->new({
  fields => {
    per_page => {
      check    => sub { /\A\d+\z/ && $_ > 0 && $_ < 100 },
      store    => update_href(\%stored_data, 'per_page'),
      default  => 10,
      sources  => [
        alpha => stash_a('per_page'),
        bravo => stash_b, # this will default to looking up by field name
        hash  => check_hash('per_page'),
      ],
    },
    page => {
      check   => sub { /\A\d+\z/ && $_ > 0 && $_ < 10000 },
      default => 1,
      sources => [
        alpha_p  => stash_a('page'),
        alpha_cp => stash_b('cur_page'),
      ],
    },
    search => {
      sources => [ stash_b('search') ],
      check   => sub { /\A\w+\z/ },
      filter  => sub { s/^\s+//; s/\s+$//; },
    },
  },
});

{
  my $input = {
    a => { cur_page => 19, per_page => -1,                       },
    b => {                 per_page => 99, search => " trim_me " },
  };

  my $result = $monster->consume($input);

  is_deeply(
    $result,
    {
      page     => 1,
      per_page => 99,
      search   => "trim_me",
    },
    "we got the correct values from a first round of input"
  );

  is_deeply(
    \%stored_data,
    { per_page => 99, },
    "...and the stored parameter was stored",
  );
}

{
  my $input = {
    a => { },
  };

  my $result = $monster->consume($input);

  is_deeply(
    $result,
    {
      page     => 1,
      per_page => 99,
      search   => undef,
    },
    "on the second round, the stored value is used and not re-stored",
  );
}

{
  my $input = {
    a => { },
  };

  my $result = $monster->consume($input, { no_default_for => [ qw(page) ] });

  is_deeply(
    $result,
    {
      page     => undef,
      per_page => 99,
      search   => undef,
    },
    "skipped page default with [qw(page)]",
  );
}

{
  my $input = {
    a => { },
  };

  my $result = $monster->consume($input, { no_default_for => 'page' });

  is_deeply(
    $result,
    {
      page     => undef,
      per_page => 99,
      search   => undef,
    },
    "skipped page default with 'page'",
  );
}
