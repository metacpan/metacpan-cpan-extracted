use 5.008003; use strict; use warnings;

my $sc = q<https://github.com/jjn1056/Catalyst-ActionRole-Methods>;
my $bt = q<https://github.com/jjn1056/Catalyst-ActionRole-Methods/issues>;

our %META = (
	name        => 'Catalyst-ActionRole-Methods',
	author      => [
		'Aristotle Pagaltzis <pagaltzis@gmx.de>',
		'John Napiorkowski <jjnapiork@cpan.org>',
	],
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
				perl 5.008003
				Catalyst 5.90060
				Moose::Role 2.0602
			)},
		},
		test => {
			requires => {qw(
				Test::More 0.88
				Catalyst::Test 0
				Catalyst::Controller 0
				HTTP::Request::Common 0
			)},
		},
	},
);

require './inc/WriteMakefile.pl';
