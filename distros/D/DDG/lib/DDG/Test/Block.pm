package DDG::Test::Block;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Adds a function to easily test L<DDG::Block>.
$DDG::Test::Block::VERSION = '1018';
use strict;
use warnings;
use Carp;
use Test::More;
use Class::Load ':all';
use DDG::Request;
use DDG::Block::Words;
use DDG::Block::Regexp;
use DDG::Test::Location;
use DDG::Test::Language;
use Package::Stash;

sub import {
	my ( $class, %params ) = @_;
	my $target = caller;

	my $stash = Package::Stash->new($target);


	$stash->add_symbol('&block_test',sub {
		my $result_callback = shift;
		my $plugins_ref = shift;
		my @plugins = @{$plugins_ref};
		my @regexp; my @words;
		foreach my $plugin (@plugins) {
			load_class($plugin);
			if ($plugin->triggers_block_type eq 'Words') {
				push @words, $plugin;
			} elsif ($plugin->triggers_block_type eq 'Regexp') {
				push @regexp, $plugin;
			} else {
				croak "Unknown plugin type";
			}
		}
		my $words_block = @words ? DDG::Block::Words->new( plugins => [@words]) : undef;
		my $regexp_block = @regexp ? DDG::Block::Regexp->new( plugins => [@regexp]) : undef;
		while (@_) {
			my $query = shift;
			my $request;
			if (ref $query eq 'DDG::Request') {
				$request = $query;
				$query = $request->query_raw;
			} else {
				$request = DDG::Request->new(
					query_raw => $query,
					location => test_location('us'),
					language => test_language('us'),
				);
			}
			my $target = shift;
			my $answer = undef;
			( $answer ) = $words_block->request($request) if $words_block;
			( $answer ) = $regexp_block->request($request) if $regexp_block && !$answer;
			if ( defined $target ) {
				for ($answer) {
					$result_callback->($query,$answer,$target);
				}
			} else {
				is($answer,$target,'Checking for not matching on '.$query);
			}
		}
	});

}

1;

__END__

=pod

=head1 NAME

DDG::Test::Block - Adds a function to easily test L<DDG::Block>.

=head1 VERSION

version 1018

=head1 EXPORTS FUNCTIONS

=head2 block_test

This exported function is used by L<DDG::Test::Spice> and L<DDG::Test::Goodie>
to get easier access to test a plugin with a block. Please see there for more
informations.

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
