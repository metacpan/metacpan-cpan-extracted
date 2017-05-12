require 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME          => 'Anarres::Mud::Driver',
    VERSION_FROM  => 'lib/Driver.pm', # finds $VERSION
    ABSTRACT_FROM => 'lib/Driver.pm',
    AUTHOR        => 'Shevek (cpan@anarres.org)',
    # ABSTRACT      => 'Module abstract'
	PREREQ_PM     => {
					String::Escape		=> 2002.001,
					File::Basename		=> 0,
					Storable			=> 1.014,
					Time::HiRes			=> 0,
					String::Scanf		=> 2.0,
					List::Util			=> 1.13,
				}, # e.g., Module::Name => 1.1
	DIR				=> [ qw(lib Type Efun Compiler Interpreter) ],
	OPTIMIZE		=> '-O2 -g -Wall',
);

sub MY::postamble {
	my $self = shift;
	my $old = $self->MM::postamble(@_);
	chomp($old);

	my $new = <<'EON';

.PHONY : readme

readme : lib/Driver.pm
	perldoc -t lib/Driver.pm > README

EON
	return $old . $new;
}
