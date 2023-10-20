use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;

my $libopts = '';
$libopts    = '-lquadmath'
  if ($^O eq 'cygwin' && $Config{nvtype} eq '__float128');

my %options = (
  NAME => 'Acme::Stack',
  AUTHOR => "sisyphus <shlomif\@cpan.org>",
  ABSTRACT => 'Silly XS stack manipulations',

  LIBS => [
    $libopts
  ],

  LICENSE  => 'perl',
  VERSION_FROM => 'Stack.pm',
);

WriteMakefile(%options);