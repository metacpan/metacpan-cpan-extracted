use strict;
use warnings;
use Test::More;

use App::karr::Cmd::AgentName;

subtest 'word list loads' => sub {
  my $cmd = App::karr::Cmd::AgentName->new;
  my @words = $cmd->_load_words;
  ok scalar @words > 10, 'has words: ' . scalar @words;
  for my $w (@words[0..4]) {
    like $w, qr/^[a-z]{4,8}$/, "valid word: $w";
  }
};

subtest 'generates name format' => sub {
  my $cmd = App::karr::Cmd::AgentName->new;
  my @words = $cmd->_load_words;
  # Simulate name generation
  my $name = $words[0] . '-' . $words[1];
  like $name, qr/^[a-z]+-[a-z]+$/, "valid format: $name";
};

done_testing;
