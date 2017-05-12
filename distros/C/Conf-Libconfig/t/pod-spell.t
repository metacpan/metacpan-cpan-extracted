#!perl
use strict;
use warnings FATAL => 'all';
use Test::More;
eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing" if $@;

$ENV{'LC_ALL'} = "en_US.UTF-8";

my @stopwords;
for (<DATA>) {
    chomp;
    push @stopwords, $_
      unless /\A (?: \# | \s* \z)/msx;    # skip comments, whitespace
};
add_stopwords(@stopwords);
set_spell_cmd('aspell list -l en');
all_pod_files_spelling_ok();

__DATA__
Alibaba
cnangel
Cnangel
Destructor
libconfig
Redistributions
xml
yaml
MERCHANTABILITY
transportability
