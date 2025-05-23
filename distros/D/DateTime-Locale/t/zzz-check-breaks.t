use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::CheckBreaks 0.020

use Test::More tests => 2;
use Term::ANSIColor 'colored';

SKIP: {
    eval { +require DateTime::Locale::Conflicts; DateTime::Locale::Conflicts->check_conflicts };
    skip('no DateTime::Locale::Conflicts module found', 1) if not $INC{'DateTime/Locale/Conflicts.pm'};

    diag $@ if $@;
    pass 'conflicts checked via DateTime::Locale::Conflicts';
}

# this data duplicates x_breaks in META.json
my $breaks = {
  "DateTime::Format::Strptime" => "<= 1.1000"
};

use CPAN::Meta::Requirements;
use CPAN::Meta::Check 0.011;

my $reqs = CPAN::Meta::Requirements->new;
$reqs->add_string_requirement($_, $breaks->{$_}) foreach keys %$breaks;

our $result = CPAN::Meta::Check::check_requirements($reqs, 'conflicts');

if (my @breaks = grep defined $result->{$_}, keys %$result) {
    diag colored('Breakages found with DateTime-Locale:', 'yellow');
    diag colored("$result->{$_}", 'yellow') for sort @breaks;
    diag "\n", colored('You should now update these modules!', 'yellow');
}

pass 'checked x_breaks data';
