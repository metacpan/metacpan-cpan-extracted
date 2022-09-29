package main;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::Recommend;

eval {
    require Test::Prereq::Meta;
    1;
} or plan skip_all => 'Test::Prereq::Meta not available';

my $tpm = Test::Prereq::Meta->new(
    accept	=> [
	My::Module::Recommend->optionals(),
	qw{ Date::Manip::DM5 Test::MockTime },
    ],
    uses	=> [ qw{
	IPC::System::Simple
	} ],
);

$tpm->all_prereq_ok();

$tpm->all_prereqs_used();

done_testing;

1;

# ex: set textwidth=72 :
