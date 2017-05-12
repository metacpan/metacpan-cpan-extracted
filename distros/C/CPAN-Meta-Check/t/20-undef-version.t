use strict;
use warnings;

use Test::More 0.88;
use Test::Deep;
use CPAN::Meta 2.120920;
use CPAN::Meta::Check 'check_requirements';

use lib 't/lib';

my %prereq_struct = (
	runtime => {
		requires => {
			'Local::HasNoVersion'	=> '!= 1.0',	# check should pass
		},
		conflicts => {
			'Local::HasNoVersion' => '>= 1.0',	# check should pass
		},
	},
	test => {
		requires => {
			'Local::HasNoVersion'	=> '== 1.0',	# check should fail
		},
		conflicts => {
			'Local::HasNoVersion' => '<= 1.0',	# check should fail
		},
	},
);

my %expected_issues = (
	runtime => {
		conflicts => { 'Local::HasNoVersion' => undef },
		requires => { 'Local::HasNoVersion' => undef },
	},
	test => {
		conflicts => { 'Local::HasNoVersion' => re(qr/Installed version \(undef\) of Local::HasNoVersion is in range '<= 1.0'/) },
		requires => { 'Local::HasNoVersion' => re(qr/Installed version \(undef\) of Local::HasNoVersion is not in range '== 1.0'/) },
	},
);

my $meta = CPAN::Meta->create({ prereqs => \%prereq_struct, version => 1, name => 'Foo'  }, { lazy_validation => 1 });

foreach my $phase (sort keys %expected_issues) {
	foreach my $type (sort keys %{$expected_issues{$phase}}) {
		my $issues = check_requirements($meta->effective_prereqs->requirements_for($phase, $type), $type, ['t/lib']);
		cmp_deeply(
			$issues,
			$expected_issues{$phase}{$type},
			"$phase $type checked",
		)
			or diag 'CPAN::Meta::Check returned: ', explain $issues;
	}
}

done_testing;
# vi:noet:sts=2:sw=2:ts=2
