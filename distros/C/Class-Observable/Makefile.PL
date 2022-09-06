use 5.006; use strict; use warnings;

my $sc = q<https://github.com/ap/Class-Observable>;
my $bt = q<https://rt.cpan.org/Public/Dist/Display.html?Name=Class-Observable>;

our %META = (
	name        => 'Class-Observable',
	author      => [ 'Aristotle Pagaltzis <pagaltzis@gmx.de>', 'Chris Winters' ],
	x_copyright => { holder => 'Aristotle Pagaltzis', year => 2021 },
	license     => 'perl_5',
	resources   => {
		license    => [ 'http://dev.perl.org/licenses/' ],
		repository => { type => 'git', url => "$sc.git", web => $sc },
		bugtracker => { web => $bt },
	},
	dynamic_config => 0,
	prereqs => {
		runtime => {
			requires => {qw(
				perl 5.006
				Config 0
				Scalar::Util 1.14
				Class::ISA 0.32
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
