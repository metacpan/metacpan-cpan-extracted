use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
  NAME          => 'CSS::LESS::Filter',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/CSS/LESS/Filter.pm',
  ABSTRACT_FROM => 'lib/CSS/LESS/Filter.pm',
  LICENSE       => 'perl',
  PREREQ_PM     => {
    'Data::Dump' => 0,
    'Parse::RecDescent' => '1.94',
    'Test::More'          => '0.88',
    'Test::UseAllModules' => '0.10',
  },
  META_MERGE => {
    resources => {
      repository => 'https://github.com/charsbar/css_less_filter',
    },
  },
);

my $eumm = $ExtUtils::MakeMaker::VERSION;
delete $params{LICENSE}    if $eumm le '6.31';
delete $params{META_MERGE} if $eumm le '6.46';

WriteMakefile(%params);
