package App::HL7::Compare;
$App::HL7::Compare::VERSION = '0.002';
use v5.10;
use strict;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use App::HL7::Compare::Parser;
use Types::Standard qw(Tuple Str ScalarRef InstanceOf Bool);
use List::Util qw(max);

has param 'files' => (
	isa => Tuple [Str | ScalarRef, Str | ScalarRef],
);

has param 'exclude_matching' => (
	isa => Bool,
	default => sub { 1 },
);

has field 'parser' => (
	isa => InstanceOf ['App::HL7::Compare::Parser'],
	default => sub { App::HL7::Compare::Parser->new },
);

sub _compare_line
{
	my ($self, $segment, $field, $component, $subcomponent, $message_num, $comps) = @_;

	my $name = sprintf "%s.%s", $segment->name, $segment->number;
	my $order = $comps->{order}{$name} //= @{$comps->{segments}};
	$comps->{segments}[$order]
		[$field->number][$component->number][$subcomponent->number]
		[$message_num] = $subcomponent->value;
}

sub _gather_recursive
{
	my ($self, $item, $levels_down) = @_;
	$levels_down -= 1;

	my @results;
	foreach my $subitem (@{$item->parts}) {
		if ($levels_down == 0) {
			push @results, [$subitem];
		}
		else {
			push @results, map {
				[$subitem, @{$_}]
			} @{$self->_gather_recursive($subitem, $levels_down)};
		}
	}

	return \@results;
}

sub _build_comparison_recursive
{
	my ($self, $parts, $levels_down) = @_;
	$levels_down -= 1;

	if ($levels_down == 0) {
		return [
			{
				path => [],
				value => [@{$parts}[0, 1]],
			}
		];
	}

	my @results;
	foreach my $part_num (0 .. $#{$parts}) {
		my $part = $parts->[$part_num];
		next unless defined $part;

		my $deep_results = $self->_build_comparison_recursive($part, $levels_down);
		if (@{$deep_results} == 1 && defined $deep_results->[0]{path}[0]) {
			$deep_results->[0]{path}[0] = $part_num
				if $deep_results->[0]{path}[0] == 1;
			push @results, $deep_results->[0];
		}
		else {
			push @results, map {
				unshift @{$_->{path}}, $part_num;
				$_
			} @{$deep_results};
		}
	}

	return \@results;
}

sub _build_comparison
{
	my ($self, $comps) = @_;

	my %reverse_order = map { $comps->{order}{$_} => $_ } keys %{$comps->{order}};
	my @results;

	foreach my $segment_num (0 .. $#{$comps->{segments}}) {
		my $segment = $comps->{segments}[$segment_num];
		push @results, {
			segment => $reverse_order{$segment_num},
			compared => $self->_build_comparison_recursive($segment, 4)
		};
	}

	return \@results;
}

sub _compare_messages
{
	my ($self, $message1, $message2) = @_;

	my %comps = (
		order => {},
		segments => [],
	);

	my $message_num = 0;
	foreach my $message ($message1, $message2) {
		my $parts = $self->_gather_recursive($message, 4);
		foreach my $part (@{$parts}) {
			$self->_compare_line(@{$part}, $message_num, \%comps);
		}

		$message_num += 1;
	}

	return $self->_build_comparison(\%comps);
}

sub _get_files
{
	my ($self) = @_;

	my $slurp = sub {
		my ($file) = @_;

		open my $fh, '<', $file
			or die "couldn't open file $file: $!";

		local $/;
		return readline $fh;
	};

	my @files = @{$self->files};
	foreach my $file (@files) {
		if (ref $file eq 'SCALAR') {
			$file = ${$file};
		}
		else {
			$file = $slurp->($file);
		}
	}

	return @files;
}

sub _remove_matching
{
	my ($self, $compared) = @_;

	return unless $self->exclude_matching;

	foreach my $segment (@{$compared}) {
		my @to_delete;

		foreach my $comp_num (0 .. $#{$segment->{compared}}) {
			my $comp = $segment->{compared}[$comp_num];

			my @values = @{$comp->{value}};
			if ((grep { defined } @values) == 2 && $values[0] eq $values[1]) {
				push @to_delete, $comp_num;
			}
		}

		foreach my $comp_num (reverse @to_delete) {
			splice @{$segment->{compared}}, $comp_num, 1;
		}
	}
}

sub compare
{
	my ($self) = @_;

	my $compared = $self->_compare_messages(map { $self->parser->parse($_) } $self->_get_files);
	$self->_remove_matching($compared);

	return $compared;
}

sub compare_stringify
{
	my ($self) = @_;
	my $compared = $self->compare;

	my @out;
	my $longest = 0;
	foreach my $segment (@{$compared}) {
		my @stringified;
		foreach my $comp (@{$segment->{compared}}) {
			my $stringified = [
				$segment->{segment} . join('', map { "[$_]" } @{$comp->{path}}) . ':',
				map { defined $_ ? $_ : '(empty)' } @{$comp->{value}}
			];

			push @stringified, $stringified;
		}

		$longest = max $longest, map { length $_->[0] } @stringified;
		my $blueprint = "%-${longest}s %s => %s";
		push @out, map { sprintf $blueprint, @{$_} } @stringified;
	}

	return join "\n", @out;
}

1;

# ABSTRACT: compare two HL7 v2 messages against one another

