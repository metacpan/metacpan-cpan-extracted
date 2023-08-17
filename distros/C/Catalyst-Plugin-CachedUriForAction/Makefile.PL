use 5.008005; # min Perl req for URI::Encode::XS
use strict; use warnings;

my $sc = q<https://github.com/ap/Catalyst-Plugin-CachedUriForAction>;
my $bt = q<https://rt.cpan.org/Public/Dist/Display.html?Name=Catalyst-Plugin-CachedUriForAction>;

our %META = (
	name        => 'Catalyst-Plugin-CachedUriForAction',
	author      => 'Aristotle Pagaltzis <pagaltzis@gmx.de>',
	x_copyright => { holder => 'Aristotle Pagaltzis', year => 2023 },
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
				perl 5.008005
				Moose::Role 0
				Class::MOP::Class 0
				Catalyst 5.90090
				URI::Encode::XS 0.11
			)},
		},
		test => {
			requires => {qw(
				Test::More 0.88
				URI 0
			)},
		},
	},
);

require './inc/WriteMakefile.pl';
