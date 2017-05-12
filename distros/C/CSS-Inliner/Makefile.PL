use ExtUtils::MakeMaker;

my $pkg = 'CSS::Inliner';
my $module = 'lib/CSS/Inliner.pm';

WriteMakefile(
    NAME => $pkg,
    PMLIBDIRS => [ 'lib' ],
    PREREQ_PM => {
	'HTML::TreeBuilder' => 5.03,
        'HTML::Query' => 0.09,
        'LWP' => 0,
        'URI' => 0,
        'Test::More' => 0
    },
    'test' => {
	TESTS => join(' ', map { glob } qw( t/*.t t/*/*.t )),
    },
    VERSION_FROM => $module,
    AUTHOR => 'Kevin Kamel <kamelkev@mailermailer.com>',
    ABSTRACT => 'Library for converting CSS <style> blocks to inline styles',
    LICENSE => 'perl',
);

sub MY::postamble {
  package MY;

  my $postamble = "all :: README\n\nREADME: $module\n\tpod2text $module > README";

  return $postamble;
}
