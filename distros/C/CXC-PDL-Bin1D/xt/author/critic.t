#!perl

use strict;
use warnings;

use Test::Perl::Critic %{+{
  "-profile" => "perlcritic.rc",
}};
all_critic_ok();
