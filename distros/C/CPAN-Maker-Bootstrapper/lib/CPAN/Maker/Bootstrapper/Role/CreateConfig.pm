package CPAN::Maker::Bootstrapper::Role::CreateConfig;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);

use Role::Tiny;

########################################################################
sub cmd_create_config {
########################################################################
  my ($self) = @_;

  print <<'END_STUB';
# CPAN::Maker configuration file
# Use with: cpan-maker-bootstrapper --config /path/to/this/file
# Or set:   export CPAN_MAKER_CONFIG=/path/to/this/file

[user]
    # your full name
    name   =
    # your email address
    email  =
    # your GitHub username (used to construct repository URLs)
    github =

[cpan-maker]
    # directory in which new projects are created
    # basedir = ~/git

    # generate GitHub resource URLs (currently only 'github' supported)
    # resources = github

    # enable perl -wc syntax checking in pattern rules
    # syntax-checking = on

    # path to perltidy configuration file (enables tidy checking)
    # perltidyrc = ~/.perltidyrc

    # path to perlcritic configuration file (enables critic checking)
    # perlcriticrc = ~/.perlcriticrc

    # shell command that prints your LLM API key (recommended)
    # llm-api-key-helper = cat ~/.ssh/anthropic-api-key

    # maximum number of output tokens
    # max-tokens = 4096

END_STUB

  return $SUCCESS;
}

1;
