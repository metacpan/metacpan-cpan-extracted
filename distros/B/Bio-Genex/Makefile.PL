use ExtUtils::MakeMaker qw(WriteMakefile);
use Getopt::Long;

# First we check if this is a local install
print STDERR "Loading Config.pm\n";

if (-f '../Bio/Genex/Config.pm') {
  # configure.pl has already been run, we just load Config.pm
  eval {
    use lib '..';
    require Bio::Genex::Config;
  };
  die "$0: Couldn't load local Config.pm: $@\n"
    if $@;
} else {
  eval {
    require Bio::Genex::Config;
  };
  if ($@) {
    die <<"EOE";

Could not load Bio::Genex::Config. This means you did not read the README.

EOE
  }
  $START_PERL = $Bio::Genex::Config->{'START_PERL'};
  die "Bogus START_PERL: $Bio::Genex::Config->{'START_PERL'}\n"
    unless $START_PERL;

  # since this is an update, we have to run configure.pl ourselves
  my $infile = './scripts/configure.pl.in';
  my $outfile = './scripts/configure.pl';

  print STDERR "Running $outfile ...\n\n";
  open(IN,$infile) or die "Couldn't open $infile for reading";
  open(OUT,">$outfile") or die "Couldn't open $outfile for writing";
  my $done = 0;
  while (<IN>) {
    if ($done) {
      print OUT;
      next;
    } else {
      if ($_ =~ /\%\%START_PERL\%\%/) {
	$_ =~  s/\%\%START_PERL\%\%/$START_PERL/g;
	$done = 1;
	print OUT;
      }
    }
  }
  close(OUT);
  close(IN);
  chmod(0775,$outfile);

  `$outfile`;
  die "Couldn't run $outfile: $!"
    if $?;
}

$EXAMPLE_DIR = $Bio::Genex::Config->{'GENEX_EXAMPLE_DIR'};
$GENEX_MAN1 = $Bio::Genex::Config->{'GENEX_MAN1'};
$GENEX_MAN3 = $Bio::Genex::Config->{'GENEX_MAN3'};
$GENEX_INSTALLSITE = $Bio::Genex::Config->{'GENEX_INSTALLSITE'};

###############################################################################
#
# Now begin the process of constructing the files
#
#

#
# Tell perl where to install the cgi scripts and Genex.pm
#
my $PM = {'Genex.pm' => '$(INST_LIBDIR)/Genex.pm',
	 };

print STDERR "EXAMPLE_DIR undefined!!!!\n" 
  unless defined $EXAMPLE_DIR;
print STDERR "MAN3_DIR undefined!!!!\n" 
  unless defined $GENEX_MAN3;
print STDERR "MAN1_DIR undefined!!!!\n" 
  unless defined $GENEX_MAN1;
print STDERR "INSTALLSITELIB undefined!!!!\n" 
  unless defined $GENEX_INSTALLSITE;

print STDOUT <<"EOM";
Using the following installation parameters from Genex::Config:

    'INSTALLSITELIB' => $GENEX_INSTALLSITE,
    'INSTALLMAN1DIR' => $GENEX_MAN1,
    'INSTALLMAN3DIR' => $GENEX_MAN3,

EOM

WriteMakefile(
    INSTALLSITELIB => $GENEX_INSTALLSITE,
    INSTALLMAN1DIR => $GENEX_MAN1,
    INSTALLMAN3DIR => $GENEX_MAN3,
    PM             => $PM,
    NAME	   => 'Bio::Genex',
    VERSION_FROM   => 'Genex.pm.in',
    PREREQ_PM      => { 'Class::ObjectTemplate::DB' => '0.22',
		      }
);

sub libscan {
    my($self, $path) = @_;
    if ($path =~ /(PerlPP\.pm|Config\.pm|Install\.pm|,v|~)$/) { return undef; }
    $path;
}

sub MY::install {
  package MY;
  my ($self) = shift;
  my $text = $self->SUPER::install(@_);

  # we want to replace the following line:
  #   'install :: all pure_install doc_install'
  # with this:
  #   'install :: all pure_install doc_install install_samples''
  #
  $text =~ s/(install\s+::\s+.*)\n/\1 install_samples\n/;

  # we append on the 'install_samples' target
  $text .= '
install_samples :: 
	cd samples ; make install_samples
';
  return $text;
}

