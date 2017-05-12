
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => "Author testing disabled");
  }
}

use Test::More;
eval "use Test::Perl::Critic";
plan skip_all => "Test::Perl::Critic required" if $@;
Test::Perl::Critic->import( -profile => "perlcritic.rc" ) if -e "perlcritic.rc";
all_critic_ok();
