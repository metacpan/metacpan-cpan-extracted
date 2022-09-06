use 5.006; use strict; use warnings;

my $sc = q<https://github.com/ap/Class-Closure>;
my $bt = q<https://rt.cpan.org/Public/Dist/Display.html?Name=Class-Closure>;

our %META = (
	name        => 'Class-Closure',
	author      => 'Aristotle Pagaltzis <pagaltzis@gmx.de>',
	x_copyright => { holder => 'Aristotle Pagaltzis', year => 2015 },
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
				Carp 0
				Devel::Caller 0
				Exporter 0
				PadWalker 0
				Sentinel 0
				Symbol 0
			)},
		},
		test => {
			requires => {qw(
				File::Find 0
				File::Temp 0
				Test::More 0.88
			)},
		},
	},
);

require './inc/WriteMakefile.pl';
