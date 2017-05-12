use strict;
use warnings;

use Data::InputMonster;

sub cgi_param {
  my ($form_entry) = @_;
  return sub {
    my ($monster, $input, $field) = @_;
    return $input->req->param->{ $form_entry };
  };
}

sub hive_path {
  my ($hive_path) = @_;
  return sub {
    my ($monster, $input, $field) = @_;
    return $input->account->info( join q{.}, @$hive_path );
  };
}

sub update_hive {
  my ($hive_path) = @_;
  return sub {
    my ($monster, $arg) = @_;

    return if $arg->{source} eq 'hive';
    return $input->account->info(
      (join q{.}, @$hive_path),
      $arg->{value};
    );
  };
}

my $monster = InputMonster->new({
  fields => {
    per_page => {
      check    => sub { /\A\d+\z/ && $_ > 0 && $_ < 100 },
      store    => update_hive([ qw(spam display per_page) ]),
      default  => 10,
      sources  => [
        per_page => cgi_param('per_page'),
        hive     => hive_path([ qw(spam display per_page) ]),
      ],
    },
    page => {
      check   => sub { /\A\d+\z/ && $_ > 0 && $_ < 10000 },
      default => 1,
      sources => [
        page     => cgi_param('page'),
        cur_page => cgi_param('cur_page'),
      ],
    },
    search => {
      sources => [ cgi_param('search') ],
      filter  => sub { s/^\s+//; s/\s+$//; },
    },
  },
});

my $input = $monster->consume($c);
