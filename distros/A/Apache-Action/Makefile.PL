use strict;
use ExtUtils::MakeMaker;

my $file = 'lib/Apache/Action.pm';

WriteMakefile(
	NAME			=> 'Apache::Action',
	VERSION_FROM	=> $file,
	ABSTRACT_FROM	=> $file,
	AUTHOR			=> 'Shevek <cpan@anarres.org>',
	PREREQ_PM		=> {
				'Apache::Constants'	=> 1,
					},
);

sub MY::postamble {
	my $self = shift;
	my $old = $self->MM::postamble(@_);
	chomp($old);
	my $new = <<"EON";

.PHONY : aux readme

aux : readme

readme : $file
	perldoc -t $file > README

EON
	return $old . $new;
}

1;
