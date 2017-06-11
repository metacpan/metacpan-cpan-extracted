package DDG::Test::Goodie;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Adds keywords to easily test Goodie plugins.
$DDG::Test::Goodie::VERSION = '1017';
use strict;
use warnings;
use Carp;
use Test::More;
use Test::Deep;
use DDG::Test::Block;
use DDG::ZeroClickInfo;
use Package::Stash;

binmode STDOUT, ':utf8';
binmode Test::More->builder->output, ':utf8';
binmode Test::More->builder->failure_output, ':utf8';


sub import {
	my ( $class, %params ) = @_;
	my $target = caller;
	my $stash = Package::Stash->new($target);


	my %zci_params;

	$stash->add_symbol('&test_zci', sub {
		my $answer = shift;
		ref $_[0] eq 'HASH' ?
			DDG::ZeroClickInfo->new(%zci_params, %{$_[0]}, answer => $answer ) :
			DDG::ZeroClickInfo->new(%zci_params, @_, answer => $answer )
	});


	$stash->add_symbol('&zci', sub {
		if (ref $_[0] eq 'HASH') {
			for (keys %{$_[0]}) {
				$zci_params{$_} = $_[0]->{$_};
			}
		} else {
			while (@_) {
				my $key = shift;
				my $value = shift;
				$zci_params{$key} = $value;
			}
		}
	});


	$stash->add_symbol('&ddg_goodie_test', sub { block_test(sub {
			my ($query, $answer, $zci) = @_;
		subtest "Query: $query" => sub {
			if ($answer) {
				$zci->{caller} = $answer->caller;    # TODO: Review all this cheating; seriously.
				cmp_deeply($answer,$zci,'Deep: full ZCI object');
			} else {
				fail('Expected result but dont get one on '.$query) unless defined $answer;
			}
		};
		},@_)
	});

}

1;

__END__

=pod

=head1 NAME

DDG::Test::Goodie - Adds keywords to easily test Goodie plugins.

=head1 VERSION

version 1017

=head1 DESCRIPTION

Installs functions for testing Goodies.

B<Warning>: Be aware that you only use this module inside your test files in B<t/>.

=head1 EXPORTS FUNCTIONS

=head2 test_zci

Easy function to generate a L<DDG::ZeroClickInfo> for the test. See
L</ddg_goodie_test>.

You can predefine parameters via L</zci>.

=head2 zci

You can predefine L<DDG::ZeroClickInfo> parameters for usage in L</test_zci>.

This function can be used several times to change specific defaults on the
fly.

=head2 ddg_goodie_test

With this function you can easily generate a small own L<DDG::Block> for
testing your L<DDG::Goodie> alone or in combination with others.

  ddg_goodie_test(
	[qw( DDG::Goodie::MyGoodie )],
	'mygooodie data' => test_zci('data', html => '<div>data</div>'),
	'mygooodie data2' => test_zci('data2', html => '<div>data2</div>'),
  );

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
