package DDG::Test::Spice;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Adds keywords to easily test Spice plugins.
$DDG::Test::Spice::VERSION = '1017';
use strict;
use warnings;
use Carp;
use Test::More;
use DDG::Test::Block;
use DDG::ZeroClickInfo::Spice;
use DDG::Meta::ZeroClickInfoSpice;
use Package::Stash;
use Class::Load 'load_class';


sub import {
	my ( $class, %params ) = @_;
	my $target = caller;
	my $stash = Package::Stash->new($target);


	my %spice_params = (
		call_type => 'include',
	);

	$stash->add_symbol('&test_spice', sub {
		my $call = shift;
		ref $_[0] eq 'HASH'
			? DDG::ZeroClickInfo::Spice->new(%spice_params, %{$_[0]}, call => $call )
			: DDG::ZeroClickInfo::Spice->new(%spice_params, @_, call => $call )
	});


	$stash->add_symbol('&spice', sub {
		if (ref $_[0] eq 'HASH') {
			for (keys %{$_[0]}) {
				$spice_params{$_} = $_[0]->{$_};
			}
		} else {
			while (@_) {
				my $key = shift;
				my $value = shift;
				$spice_params{$key} = $value;
			}
		}
	});


	$stash->add_symbol('&ddg_spice_test', sub { block_test(sub {
		my $query = shift;
		my $answer = shift;
		my $spice = shift;
		if ($answer) {
			is_deeply($answer,$spice,'Testing query '.$query);
		} else {
			fail('Expected result but dont get one on '.$query);
		}
	},@_)});


	$stash->add_symbol('&alt_to_test', sub {
		my ($spice, $alt_tos) = @_;

		load_class($spice);

		my $rewrites = $spice->alt_rewrites;
		ok($rewrites, "$spice has rewrites");

		ok($spice =~ /^(DDG.+::)/, "Extract base from $spice");
		my $base = $1;

		for my $alt (@$alt_tos){
			my ($cb, $path) = @{DDG::Meta::ZeroClickInfoSpice::params_from_target("$base$alt")};
			my $rw = $rewrites->{$alt};
			ok($rw, "$alt exists");
			ok($rw->callback eq $cb, "$alt callback");
			ok($rw->path eq $path, "$alt path");
		}
	});
}

1;

__END__

=pod

=head1 NAME

DDG::Test::Spice - Adds keywords to easily test Spice plugins.

=head1 VERSION

version 1017

=head1 DESCRIPTION

Installs functions for testing Spice.

B<Warning>: Be aware that you only use this module inside your test files in B<t/>.

=head1 EXPORTS FUNCTIONS

=head2 test_spice

Easy function to generate a L<DDG::ZeroClickInfo::Spice> for the test. See
L</ddg_spice_test>.

You can predefine parameters via L</spice>.

The first parameter gets treated as the
L<call of the DDG::ZeroClickInfo::Spice|DDG::ZeroClickInfo::Spice/call>

=head2 spice

You can predefine L<DDG::ZeroClickInfo::Spice> parameters for usage in
L</test_spice>.

This function can be used several times to change specific defaults on the
fly.

=head2 ddg_spice_test

With this function you can easily generate a small own L<DDG::Block> for
testing your L<DDG::Spice> alone or in combination with others.

  ddg_spice_test(
    [qw( DDG::Spice::MySpice )],
    'myspice data' => test_spice('/js/spice/my_spice/data'),
    'myspice data2' => test_spice('/js/spice/my_spice/data2'),
  );

=head2 alt_to_test

Use this function to verify your spice's alt_to definitions:

	alt_to_test('DDG::Spice::My::Spice', [qw(alt1 alt2 alt3)]);

This would check for the following:

	callbacks 'ddg_spice_my_alt[123]'
	paths '/js/spice/my/alt[123]/'

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
