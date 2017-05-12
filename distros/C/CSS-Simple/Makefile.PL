use ExtUtils::MakeMaker;

my $pkg = 'CSS::Simple';
my $module = 'lib/CSS/Simple.pm';

WriteMakefile(
    NAME => $pkg,
    PMLIBDIRS => [ 'lib' ],
    PREREQ_PM => {
	'Carp' => 0,
        'Tie::IxHash' => 0
    },
    'test' => {
	TESTS => join(' ', map { glob } qw( t/*.t t/*/*.t )),
    },
    VERSION_FROM => $module,
    AUTHOR => 'Kevin Kamel <kamelkev@mailermailer.com>',
    ABSTRACT => 'Interface through which to read/write/manipulate CSS files while respecting the cascade order',
    LICENSE => 'perl',
);

sub MY::postamble {
  package MY;

  my $postamble = "all :: README\n\nREADME: $module\n\tpod2text $module > README";

  return $postamble;
}
