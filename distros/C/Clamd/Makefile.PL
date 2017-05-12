use ExtUtils::MakeMaker;

$ENV{CLAMD_PATH} ||= -e "/usr/local/sbin/clamd" ? 
	"/usr/local/sbin" : -e "/usr/sbin/clamd" ?
	"/usr/sbin" : -e "/usr/local/bin/clamd" ?
	"/usr/local/bin" : -e "/usr/bin/clamd" ?
	"/usr/bin" : "$ENV{HOME}/bin";

my $help = `$ENV{CLAMD_PATH}/clamd --help 2>&1` || '';
if ($help !~ /clam/i) {
  die "Cannot find clamd in $ENV{CLAMD_PATH} (or a number of other places)\n - are you sure clamav in installed?\n";
}

WriteMakefile(
    'NAME' => 'Clamd',
    'VERSION_FROM' => 'lib/Clamd.pm',
    'PREREQ_PM' => {},
    'ABSTRACT_FROM' => 'lib/Clamd.pm',
    'AUTHOR' => 'Matt Sergeant <matt@sergeant.org>',
);

sub MY::test {
  package MY;
  my $self = shift;
  my $make = $self->SUPER::test();
  $make =~ s/PERL_DL_NONLAZY=1/PERL_DL_NONLAZY=1 CLAMD_PATH=$ENV{CLAMD_PATH}/g;
  return $make;
}

