
use v5.10;
use strict;
use warnings;

package Context::Singleton::Frame::Deducer::Notifying;
$Context::Singleton::Frame::Deducer::Notifying::VERSION = '1.0.8';
use Moo;

use Context::Singleton::Frame::Promise;
use Context::Singleton::Frame::Promise::Builder;
use Context::Singleton::Frame::Promise::Rule;

use namespace::clean;

BEGIN { extends q (Context::Singleton::Frame::Deducer) }

has q (_class_builder_promise)
	=> is       => q (ro)
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { Context::Singleton::Frame::Promise::Builder:: }
	;

has q (_class_rule_promise)
	=> is       => q (ro)
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { Context::Singleton::Frame::Promise::Rule:: }
	;

has q (promises)
	=> is       => q (ro)
	=> init_arg => +undef
	=> default  => sub { +{} }
	;

sub _build_builder_promise_for {
	my ($deducer, $builder) = @_;

	my $promise = $deducer->_class_builder_promise->new (
		depth   => $deducer->depth,
		builder => $builder,
	);

	my %optional = $builder->default;
	my %required = map +($_ => 1), $builder->required;
	delete @required{ keys %optional };

	$promise->add_dependencies (
		map $deducer->_establish_promise_for ($_), keys %required
	);

	$promise->set_deducible (0)
		unless keys %required
		;

	$promise->listen ($deducer->_establish_promise_for ($_))
		for keys %optional
		;

	$promise;
}

sub _build_rule_promise_for {
	my ($deducer, $singleton) = @_;

	$deducer->promises->{$singleton} // do {
		my $promise = $deducer->promises->{$singleton} = $deducer->_class_rule_promise->new (
			depth => $deducer->depth,
			rule => $singleton,
		);

		$promise->add_dependencies ($deducer->parent->_establish_promise_for ($singleton))
			if $deducer->parent
			;

		for my $builder ($deducer->db->search_builder_for ($singleton)) {
			$promise->add_dependencies (
				$deducer->_build_builder_promise_for ($builder)
			);
		}

		$promise;
	};
}

sub _deduce_rule {
	my ($deducer, $singleton) = @_;

	my $promise = $deducer->_establish_promise_for ($singleton);
	return $promise->value
		if $promise->is_deduced
		;

	my $builder_promise = $promise->deducible_builder;
	return $builder_promise->value
		if $builder_promise->is_deduced
		;

	my $builder = $builder_promise->builder;
	my %deduced = $builder->default;

	for my $dependency ($builder->required) {
		# dependencies with default values may not be deducible
		# relying on promises to detect deducible values
		next
			unless $deducer->is_deducible ($dependency)
			;

		$deduced{$dependency} = $deducer->deduce ($dependency);
	}

	$builder->build (\%deduced);
}

sub _execute_triggers {
	my ($deducer, $singleton, $value) = @_;

	$_->($value)
		for $deducer->db->search_trigger_for ($singleton)
		;
}

sub _search_promise_for {
	my ($deducer, $singleton) = @_;

	$deducer->promises->{$singleton};
}

sub _deducer_by_depth {
	my ($deducer, $depth) = @_;

	my $frame = $deducer->frame->_frame_by_depth ($depth);

	return
		unless $frame
		;
	return $frame->_deducer;
}

sub _establish_promise_for {
	my ($deducer, $singleton) = @_;

	$deducer->_search_promise_for ($singleton)
		// $deducer->_build_rule_promise_for ($singleton)
		;
}

sub _set_promise_value {
	my ($deducer, $promise, $value) = @_;

	$promise->set_value ($value, $deducer->depth);
	$deducer->_execute_triggers ($promise->rule, $value);

	return $value;
}

sub deduce {
	my ($deducer, $singleton) = @_;

	$deducer->frame->_throw_nondeducible ($singleton)
		unless $deducer->try_deduce ($singleton)
		;

	$deducer->_search_promise_for ($singleton)->value;
}

sub is_deduced {
	my ($deducer, $singleton) = @_;

	return
		unless my $promise = $deducer->_search_promise_for ($singleton)
		;
	return $promise->is_deduced;
}

sub is_deducible {
	my ($deducer, $singleton) = @_;

	return
		unless my $promise = $deducer->_establish_promise_for ($singleton)
		;
	return $promise->is_deducible;
}

sub proclaim {
	my ($deducer, $key, $value) = @_;

	my $promise = $deducer->_search_promise_for ($key)
		// $deducer->_build_rule_promise_for ($key)
		;

	return $deducer->_set_promise_value ($promise, $value);
}

sub try_deduce {
	my ($deducer, $singleton) = @_;

	my $promise = $deducer->_establish_promise_for ($singleton);
	return
		unless $promise->is_deducible
		;

	my $value = $deducer
		->_deducer_by_depth ($promise->deduced_in_depth)
		->_deduce_rule ($promise->rule)
		;

	$promise->set_value ($value, $promise->deduced_in_depth);

	1;
}

1;

__END__

