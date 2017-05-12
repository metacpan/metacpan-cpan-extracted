package ABNF::Generator::Honest;

=pod

=head1 NAME

B<ABNF::Generator::Honest> - class to generate valid messages for ABNF-based generators

It have $RECURSION_LIMIT = 16. You can change it to increase lower alarm bound on choices and repetition recursion.
but use it carefully!

=head1 INHERITANCE

B<ABNF::Generator::Honest>
isa B<ABNF::Generator>

=head1 DESCRIPTION

=head1 METHODS

=cut

use 5.014;

use strict;
use warnings;
no warnings "recursion";

use Data::Dumper;
use Readonly;
use List::Util qw(reduce);

use POSIX;

use base qw(ABNF::Generator Exporter);

use Method::Signatures; #some bug in B<Devel::Declare>...

use ABNF::Generator qw($CONVERTERS);

our @EXPORT_OK = qw(Honest);
our $RECURSION_LIMIT = 16;

=pod

=head1 ABNF::Generator::Honest->C<new>($grammar, $validator?)

Creates a new B<ABNF::Generator::Honest> object.

$grammar isa B<ABNF::Grammar>.

$validator isa B<ABNF::Validator>. 

=cut

method new(ABNF::Grammar $grammar, ABNF::Validator $validator?) {
	$self->SUPER::new($grammar, $validator ? $validator : ());
}

=pod

=head1 $honest->C<generate>($rule, $tail="")

Generates one valid sequence string for command $rule. 

Using cache $self->{_cache}->{$rule} for this rule, that speeds up this call.

$rule is a command name.

$tail is a string added to result if it absent.

dies if there is no command like $rule.

=cut

method _range($rule, $recursion) {
	my $converter = $CONVERTERS->{$rule->{type}};
	my $min = $converter->($rule->{min});
	my $max = $converter->($rule->{max});
	return {class => "Atom", value => chr($min + int(rand($max - $min + 1)))};
}

method _string($rule, $recursion) {
	my $converter = $CONVERTERS->{$rule->{type}};
	return {
		class => "Atom",
		value => join("", map { chr($converter->($_)) } @{$rule->{value}})
	};
}

method _literal($rule, $recursion) {
	return {class => "Atom", value => $rule->{value}};
}

method _repetition($rule, $recursion) {
	my $min = $rule->{min};
	my $count = ($rule->{max} || LONG_MAX) - $min;
	my @result = ();

	push(@result, $self->_generateChain($rule->{value}, $recursion)) while $min--;
	if ( $recursion->{level} < $RECURSION_LIMIT ) {
		push(@result, $self->_generateChain($rule->{value}, $recursion)) while $count-- && int(rand(2));
	}

	return {class => "Sequence", value => \@result};
}

method _proseValue($rule, $recursion) {
	return $self->_generateChain($rule->{name}, $recursion);
}

method _reference($rule, $recursion) {
	return $self->_generateChain($rule->{name}, $recursion);
}

method _group($rule, $recursion) {
	my @result = ();
	foreach my $elem ( @{$rule->{value}} ) {
		push(@result, $self->_generateChain($elem, $recursion));
	}

	return {class => "Sequence", value => \@result};
}

method _choice($rule, $recursion) {
	$recursion->{level}++;
	my @result = ();
	if ( $recursion->{level} < $RECURSION_LIMIT ) {
		foreach my $choice ( @{$rule->{value}} ) {
			push(@result, $self->_generateChain($choice, $recursion));
		}
	} else {
		$recursion->{choices} ||= {};
		my $candidate = reduce {
			if ( not exists($recursion->{choices}->{$a}) ) {
				$b
			} elsif ( not exists($recursion->{choices}->{$b}) ) {
				$a
			} else {
				$recursion->{choices}->{$a} <=> $recursion->{choices}->{$b} 
			}
		} @{$rule->{value}};
		$recursion->{choices}->{$candidate}++;
		push(@result, $self->_generateChain( $candidate, $recursion));
		$recursion->{choices}->{$candidate}--;
	}
	$recursion->{level}--;

	return {class => "Choice", value => \@result};
}

method _rule($rule, $recursion) {
	return $self->_generateChain($rule->{value}, $recursion);
}

=pod

=head1 $honest->C<withoutArguments>($name, $tail="")

Return a string starts like command $name and without arguments if command may have no arguments.

Return an empty string otherwise.

$tail is a string added to result if it absent.

dies if there is no command like $rule.

=cut

method withoutArguments(Str $name, Str $tail="") {
	my $result = $self->SUPER::withoutArguments($name, $tail);
	return $self->{_validator}->validate($name, $result) ? $result : "";
}

=pod

=head1 FUNCTIONS

=head1 C<Honest>()

Return __PACKAGE__ to reduce class name :3

=cut

func Honest() {
	return __PACKAGE__;
}

1;

=pod

=head1 AUTHOR / COPYRIGHT / LICENSE

Copyright (c) 2013 Arseny Krasikov <nyaapa@cpan.org>.

This module is licensed under the same terms as Perl itself.

=cut
