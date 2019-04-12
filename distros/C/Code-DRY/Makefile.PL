use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# exit if a pure-perl build is requested
if (PurePerlRequested()) {
	die "Error: a pure perl build is not available within this distribution\n";
}


WriteMakefile(
    'NAME'              => 'Code::DRY',
    'VERSION_FROM'      => 'lib/Code/DRY.pm', # finds $VERSION
    'PREREQ_PM'         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      ('ABSTRACT_FROM'  => 'lib/Code/DRY.pm', # retrieve abstract from module
       'AUTHOR'         => 'hexcoder <hexcoder@cpan.org>') : ()),
    'DEFINE'            => '-DNDEBUG',
    'INC'               => '-I.', # e.g., '-I. -I/usr/include/other'
    'OBJECT'            => '$(O_FILES)', # link all the C files too
    'INSTALLDIRS'       => 'site',
    'EXE_FILES' => [
                     'bin/CP_reporter'
                   ],
    'PL_FILES'          => {},
);

# The Lancaster Consensus specifies how pure perl builds are requested
sub PurePerlRequested
{
	my $found_in_commandline_arguments;
	if (0 < scalar @ARGV) {
		# have command line arguments
		for my $arg (reverse @ARGV) {
		       	if ($arg =~ m{\bPUREPERL_ONLY=(\d)\b}xms) {
				$found_in_commandline_arguments = 1;
				# have option specifying PUREPERL_ONLY request
				if ('1' eq $1) {
					# wants a PUREPERL distribution
					return 1;
				}
				last;
			}
		}
	}
	if (!defined $found_in_commandline_arguments && exists $ENV{'PERL_MM_OPT'}) {
		# have options via environment variable
	       	if ($ENV{'PERL_MM_OPT'} =~ m{\bPUREPERL_ONLY=(\d)\b}xms) {
			# have option specifying PUREPERL_ONLY request
			if ('1' eq $1) {
				# wants a PUREPERL distribution
				return 1;
			} else {
				# does not want a PUREPERL distribution
				# clean up, since not all MakeMakers understand this yet?
#				$ENV{'PERL_MM_OPT'} =~ s{\bPUREPERL_ONLY=\d\b}{}xms;
			}
		}
	}
	return 0;
}
