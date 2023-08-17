use 5.006; use strict; use warnings;

my $sc = q<https://github.com/ap/Config-INI-Tiny>;
my $bt = q<https://rt.cpan.org/Public/Dist/Display.html?Name=Config-INI-Tiny>;

our %META = (
	name        => 'Config-INI-Tiny',
	author      => 'Aristotle Pagaltzis <pagaltzis@gmx.de>',
	x_copyright => { holder => 'Aristotle Pagaltzis', year => 2021 },
	license     => 'perl_5',
	resources   => {
		license    => [ q<https://dev.perl.org/licenses/> ],
		repository => { type => 'git', url => "$sc.git", web => $sc },
		bugtracker => { web => $bt },
	},
	dynamic_config => 0,
	prereqs => {
		runtime => {
			requires => {qw(
				perl 5.006
				Carp 0
			)},
		},
		test => {
			requires => {qw(
				Test::More 0
			)},
		},
	},
);

require './inc/WriteMakefile.pl';
