use 5.008001; # min Perl req for Catalyst 5.80004
use strict; use warnings;

my $sc = q<https://github.com/ap/Catalyst-Plugin-Flash>;
my $bt = q<https://rt.cpan.org/Public/Dist/Display.html?Name=Catalyst-Plugin-Flash>;

our %META = (
	name        => 'Catalyst-Plugin-Flash',
	author      => 'Aristotle Pagaltzis <pagaltzis@gmx.de>',
	x_copyright => { holder => 'Aristotle Pagaltzis', year => 2024 },
	license     => 'perl_5',
	resources   => {
		repository => { type => 'git', url => "$sc.git", web => $sc },
		bugtracker => { web => $bt },
	},
	dynamic_config => 0,
	prereqs => {
		runtime => {
			requires => {qw(
				perl 5.008001
				Catalyst 5.80004
				Moose::Role 0
				URI 0
				JSON::MaybeXS 0
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
