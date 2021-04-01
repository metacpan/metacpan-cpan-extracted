package main;

use 5.006002;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };

use My::Module::Meta;

eval {
    require Test::Prereq::Meta;
    1;
} or plan skip_all => 'Test::Prereq::Meta not available';

my $tpm = Test::Prereq::Meta->new(
    accept	=> [
	do {
	    local $] = My::Module::Meta->requires_perl();
	    require My::Module::Recommend;
	    My::Module::Recommend->optionals();
	},
	qw{
	    File::HomeDir
	    File::Spec
	    List::Util
	    Test::MockTime
	}
    ],
    prune	=> [ qw{ blib/script } ],
);

$tpm->all_prereq_ok();

$tpm->all_prereqs_used();

done_testing;

1;

# ex: set textwidth=72 :
