use strict;
BEGIN {
	require 5.003_96;
}
use ExtUtils::MakeMaker ();

WriteMakefile(
	NAME             => 'CPAN::Test::Dummy::Perl5::NoBugTracker',
	ABSTRACT         => 'CPAN Test Dummy that explicitly says there is no bug tracker',
	VERSION_FROM     => 'lib/CPAN/Test/Dummy/Perl5/NoBugTracker.pm',
	AUTHOR           => 'Adam Kennedy <adamk@cpan.org>',
	LICENSE          => 'perl',
	MIN_PERL_VERSION => '5.004',
	META_MERGE       => {
		resources => {
			bugtracker => '',
		},
	},
);

# Written by Alexandr Ciornii, version 0.20
sub WriteMakefile {
	my %params = @_;

	my $eumm_version = $ExtUtils::MakeMaker::VERSION;
	$eumm_version = eval $eumm_version;

	delete $params{MIN_PERL_VERSION}   if $eumm_version < 6.48;
	delete $params{META_MERGE}         if $eumm_version < 6.46;
	delete $params{LICENSE}            if $eumm_version < 6.31;
	delete $params{AUTHOR}             if $] < 5.005;

	ExtUtils::MakeMaker::WriteMakefile(%params);
}
