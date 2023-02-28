use strict;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

sub MY::libscan
{
    package MY;

    my ($self, $file) = @_;

    # Don't install the README.pod or any .pl file
    return undef if $file =~ /\.pl$|^README.pod/;
    return $self->SUPER::libscan ($file);
}


########################################
########################################	
# reroute the main POD into a separate README.pod if requested. This is here
# purely to generate a README.pod for the github front page
my $POD_header = <<EOF;
=head1 OVERVIEW

Alien::Gnuplot is intended for distribution via CPAN.  This repository
stores the history for the Alien::Gnuplot module on CPAN. Install the
module via CPAN.

=cut
EOF
if(exists $ARGV[0] && $ARGV[0] eq 'README.pod')
{
  open MOD, 'lib/Alien/Gnuplot.pm' or die "Couldn't open main module";
  open README, '>README.pod'       or die "Couldn't open README.pod";

  print README $POD_header;

  while (<MOD>)
  {
    if (/^=/../^=cut/)
    { print README; }
  }
}

##############################
##############################
## Write a generic Makefile that puts the module in place.  Include a postamble
## that will also make the source code, if necessary.

my $abmm = Alien::Build::MM->new;

my %configure_and_build_prereqs = (
    "Alien::Build" => "0.32",
    "Alien::Build::MM" => "0.32",
    "ExtUtils::MakeMaker" => "6.52",
);

## Shared build and runtime prereqs because the `alienfile` calls into
## `lib/Alien/Gnuplot.pm`.
my %build_and_runtime_prereqs = (
    'Time::HiRes' => 0,
    'File::Temp'  => 0,
    'HTTP::Tiny'  => 0,
    'POSIX'       => 0,
    'Env'         => 0,
    'File::Spec'  => 0,
    'File::Which' => 0,
);

WriteMakefile($abmm->mm_args(
    NAME                => 'Alien::Gnuplot',
    AUTHOR              => 'Craig DeForest <craig@deforest.org>',
    DISTNAME            => 'Alien-Gnuplot',
    VERSION_FROM        => 'lib/Alien/Gnuplot.pm',
    ABSTRACT_FROM       => 'lib/Alien/Gnuplot.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
     ? ('LICENSE'=> 'perl')
     : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.48
     ? ('MIN_PERL_VERSION' => '5.6.0')
     : ()),
    PREREQ_PM => {
        %build_and_runtime_prereqs,
    },
    BUILD_REQUIRES => {
        'version' => '0.77',
        %configure_and_build_prereqs,
        %build_and_runtime_prereqs,
    },
    CONFIGURE_REQUIRES => {
        %configure_and_build_prereqs,
    },
    META_ADD => {
	resources => {
	    homepage => 'https://github.com/drzowie/Alien-Gnuplot',
	    repository => 'git://github.com/drzowie/Alien-Gnuplot.git',
	    bugtracker => 'craig@deforest.org'
	}
    },		  
    TEST_REQUIRES => {
		   'Test::More'      => 0,
		   'Test::Exception' => 0
    },

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Alien-Gnuplot-* src/*[0-9]' },
));

sub MY::postamble {
    $abmm->mm_postamble(@_);
}

sub MY::install {
    $abmm->mm_install(@_);
}
