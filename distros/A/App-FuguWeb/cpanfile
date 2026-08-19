# NOTE: deps/*.txt with 'make deps' is the authoritative dependency
# list. This file exists for development convenience and carton
# compatibility.
#
# App::FuguWeb has no CPAN dependency: it uses Fugu:: and core Perl
# only, and t/fuguweb/boundary.t enforces it. The Fugu library itself
# installs from its latest GitHub release through the dist line of
# deps/*.txt, not from CPAN. The renderers - mandoc, lowdown, pod2man -
# are programs, not modules.

on 'test' => sub {
	requires 'Perl::Critic';
	requires 'Perl::Tidy';
};
