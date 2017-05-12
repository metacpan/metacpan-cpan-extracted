use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> 'Acme::HaltingProblem',
	VERSION_FROM	=> 'HaltingProblem.pm',
	ABSTRACT_FROM	=> "HaltingProblem.pm",
	AUTHOR			=> 'Shevek <cpan@anarres.org>',
	PREREQ_PM		=> { },
);

sub MY::postamble {
	my $self = shift;
	my $old = $self->MM::postamble(@_);
	chomp($old);
	my $new = <<'EON';

.PHONY : aux readme

aux : readme

readme : HaltingProblem.pm
	perldoc -t HaltingProblem.pm > README

EON
	return $old . $new;
}

1;
