#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
	plan skip_all => "This test requires YAML::Syck to be installed" unless eval { require YAML::Syck };
	plan tests => 10;
}

use File::Spec;

use ok "Class::Workflow::YAML";

my $y = Class::Workflow::YAML->new;

isa_ok( $y, "Class::Workflow::YAML" );

can_ok( $y, "load_file" );

my $workflow = $y->load_file( File::Spec->catfile(qw/examples example.yaml/) );

isa_ok( $workflow, "Class::Workflow" );

isa_ok( $workflow->get_state("open"), "Class::Workflow::State::Simple", "open state" );

is( $workflow->initial_state, "new", "initial state" );

isa_ok( my $accept = $workflow->get_transition("accept"), "Class::Workflow::Transition::Simple" );

my $sub = $accept->body;

ok( $sub, "accept transition has a body" );

is( ref($sub), "CODE", "it's a sub" );

{
	package MockCxt;
	sub user { "foo" }
}

my $c = bless {}, "MockCxt";

is_deeply(
	[ $accept->$sub( $workflow->new_instance, $c ) ],
	[ { owner => "foo" } ],
	"body loaded OK from YAML",
);

