package ABNF::Generator;

=pod

=head1 NAME

B<ABNF::Generator> - abstract base class for ABNF-based generators

=head1 INHERITANCE

B<ABNF::Generator> is the root of the Honest and Liar generators

=head1 DESCRIPTION

B<ABNF::Generator> is the abstract base class for ABNF-based generators.

Also it provides function B<asStrings> to stringified generated sequences

=head1 METHODS

=cut

use 5.014;

use strict;
use warnings;
no warnings "recursion";

use Carp;
use Readonly;
use Method::Signatures;
use Data::Dumper;

use Parse::ABNF;
use List::Util qw(shuffle);

use ABNF::Grammar qw($BASIC_RULES splitRule);
use ABNF::Validator;

use base qw(Exporter);
our @EXPORT_OK = qw($CONVERTERS $BASIC_RULES $RECURSION_LIMIT);

Readonly our $CHOICE_LIMIT => 128;

Readonly our $CONVERTERS => {
	"hex" => sub { hex($_[0]) },
	"bin" => sub { oct($_[0]) },
	"decimal" => sub { int($_[0]) },
};

=pod

=head1 ABNF::Generator->C<new>($grammar, $validator?)

Creates a new B<ABNF::Generator> object.

$grammar isa B<ABNF::Grammar>.

$validator isa B<ABNF::Validator>.

Children classes can get acces for them by $self->{_grammar} and $self->{_validator}

=cut

method new(ABNF::Grammar $grammar, ABNF::Validator $validator?) {
	my $class = ref($self) || $self;

	croak "Cant create instance of abstract class" if $class eq 'ABNF::Generator';

	$self = {
		_cache => {},
		_grammar => $grammar,
		_validator => $validator || ABNF::Validator->new($grammar)
	};

	bless($self, $class);

	$self->_init();

	return $self;
}

method _init() {
	$self->{handlers} = {
		Range => $self->can("_range"),
		String => $self->can("_string"),
		Literal => $self->can("_literal"),
		Repetition => $self->can("_repetition"),
		ProseValue => $self->can("_proseValue"),
		Reference => $self->can("_reference"),
		Group => $self->can("_group"),
		Choice => $self->can("_choice"),
		Rule => $self->can("_rule"),
	};
}

=pod

=head1 $generator->C<_range>($rule, $recursion)

Generates chain for range element.

Abstract method, most of all children must overload it.

$recursion is a structure to controle recursion depth.

=cut

method _range($rule, $recursion) {
	croak "Range handler is undefined yet";
}

=pod

=head1 $generator->C<_string>($rule, $recursion)

Generates chain for string element.

Abstract method, most of all children must overload it

$recursion is a structure to controle recursion depth.

=cut

method _string($rule, $recursion) {
	croak "String handler is undefined yet";
}

=pod

=head1 $generator->C<_literal>($rule, $recursion)

Generates chain for literal element.

Abstract method, most of all children must overload it

$recursion is a structure to controle recursion depth.

=cut

method _literal($rule, $recursion) {
	croak "Literal handler is undefined yet";
}

=pod

=head1 $generator->C<_repetition>($rule, $recursion)

Generates chain for repetition element.

Abstract method, most of all children must overload it

$recursion is a structure to controle recursion depth.

=cut

method _repetition($rule, $recursion) {
	croak "Repetition handler is undefined yet";
}

=pod

=head1 $generator->C<_reference>($rule, $recursion)

Generates chain for reference element.

Abstract method, most of all children must overload it

$recursion is a structure to controle recursion depth.

=cut

method _reference($rule, $recursion) {
	croak "Reference handler is undefined yet";
}

=pod

=head1 $generator->C<_group>($rule, $recursion)

Generates chain for group element.

Abstract method, most of all children must overload it

$recursion is a structure to controle recursion depth.

=cut

method _group($rule, $recursion) {
	croak "Group handler is undefined yet";
}

=pod

=head1 $generator->C<_choice>($rule, $recursion)

Generates chain for choce element.

Abstract method, most of all children must overload it

$recursion is a structure to controle recursion depth.

=cut

method _choice($rule, $recursion) {
	croak "Choice handler is undefined yet";
}

=pod

=head1 $generator->C<_rule>($rule, $recursion)

Generates chain for rule element, usually -- basic element in chain.

Abstract method, most of all children must overload it

$recursion is a structure to controle recursion depth.

=cut

method _rule($rule, $recursion) {
	croak "Rule handler is undefined yet";
}

=pod

=head1 $generator->C<_generateChain>($rule, $recursion)

Generates one chain per different rule in $rule.

$rule is structure that Return from B<ABNF::Grammar::rule> and like in B<Parse::ABNF>.

$rule might be a command name.

$recursion is a structure to controle recursion depth.

at init it have only one key -- level == 0.

You can create new object perl call or use one.

See use example in ABNF::Generator::Honest in method _choice

=cut

method _generateChain($rule, $recursion) {

	my @result = ();

	if ( ref($rule) ) {
		croak "Bad rule " . Dumper($rule) unless UNIVERSAL::isa($rule, "HASH");
	} elsif ( exists($BASIC_RULES->{$rule}) ) {
		$rule = $BASIC_RULES->{$rule};
	} else {
		$rule = $self->{_grammar}->rule($rule);
	}

	$self->{handlers}->{ $rule->{class} }
	or die "Unknown class " . $rule->{class};

	return $self->{handlers}->{ $rule->{class} }->($self, $rule, $recursion);
}

=pod

=head1 $generator->C<generate>($rule, $tail="")

Generates one sequence string for command $rule. 

Using cache $self->{_cache}->{$rule} for this rule, that speeds up this call.

$rule is a command name.

$tail is a string added to result if it absent.

dies if there is no command like $rule.

=cut

method generate(Str $rule, Str $tail="") {
	croak "Unexisted command" unless $self->{_grammar}->hasCommand($rule);

	$self->{_cache}->{$rule} ||= [];
	unless ( @{$self->{_cache}->{$rule}} ) {
		$self->{_cache}->{$rule} = _asStrings( $self->_generateChain($rule, {level => 0}) );
	}
	my $result = pop($self->{_cache}->{$rule});
	
	my $rx = eval { qr/$tail$/ };
	croak "Bad tail" if $@;
	return $result =~ $rx ? $result : $result . $tail;
}

=pod

=head1 $generator->C<withoutArguments>($name, $tail="")

Return an strings starts like command $name and without arguments.

$tail is a string added to a result.

dies if there is no command like $rule.

=cut

method withoutArguments(Str $name, Str $tail="") {
	croak "Unexisted command" unless $self->{_grammar}->hasCommand($name);

	my ($prefix, $args) = splitRule( $self->{_grammar}->rule($name) );
	
	my $rx = eval { qr/$tail$/ };
	croak "Bad tail" if $@;
	return $prefix =~ $rx ? $prefix : $prefix . $tail;
}

=pod

=head1 $generator->C<hasCommand>($name)

Return 1 if there is a $name is command, 0 otherwise

=cut

method hasCommand(Str $name) {
	$self->{_grammar}->hasCommand($name);
}

=pod

=head1 FUNCTIONS

=head1 C<_asStrings>($generated)

Return stringification of genereted sequences from C<_generateChain>.

Uses in generate call to stringify chains.

=cut

func _asStrings($generated) {
	given ( $generated->{class} ) {
		when ( "Atom" ) { return [ $generated->{value} ] }

		when ( "Sequence" ) {
			my $value = $generated->{value};
			return [] unless @$value;

			my $begin = _asStrings($value->[0]);

			for ( my $pos = 1; $pos < @$value; $pos++ ) {
				my @new_begin = ();
				my $ends = _asStrings($value->[$pos]);
				next unless @$ends;

				my @ibegin = splice([shuffle(@$begin)], 0, $CHOICE_LIMIT);
				my @iends = splice([shuffle(@$ends)], 0, $CHOICE_LIMIT);
				foreach my $end ( @iends ) {
					foreach my $begin ( @ibegin ) {
						push(@new_begin, $begin . $end);
					}
				}
		
				$begin = \@new_begin;
			}

			return $begin;
		}

		when ( "Choice" ) {
			return [
				map { @{_asStrings($_)} } @{$generated->{value}}
			];
		}

		default { die "Unknown class " . $generated->{class} . Dumper $generated }
	}
}

1;

=pod

=head1 AUTHOR / COPYRIGHT / LICENSE

Copyright (c) 2013 Arseny Krasikov <nyaapa@cpan.org>.

This module is licensed under the same terms as Perl itself.

=cut
