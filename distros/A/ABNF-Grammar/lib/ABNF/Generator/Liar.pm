package ABNF::Generator::Liar;

=pod

=head1 NAME

B<ABNF::Generator::Liar> - class to generate invalid messages for ABNF-based generators

=head1 INHERITANCE

B<ABNF::Generator::Liar>
isa B<BNF::Generator>

=head1 DESCRIPTION

=head1 METHODS

=cut

use 5.014;

use strict;
use warnings;

use Readonly;
use Data::Dumper;
use Carp;

use POSIX;

use base qw(ABNF::Generator Exporter);

use Method::Signatures; #some bug in B<Devel::Declare>...

use ABNF::Grammar qw(splitRule $BASIC_RULES);

Readonly my $STRING_LEN => 20;
Readonly my $CHARS => [map { chr($_) } (0 .. 0x0D - 1), (0x0D + 1 .. 255)];
Readonly my $ACHARS => [('A'..'Z', 'a'..'z')];
Readonly our $ENDLESS => 513 * 1024 / 4; # 513 kB of chars

our @EXPORT_OK = qw(Liar);

=pod

=head1 ABNF::Generator::Liar->C<new>($grammar, $validator?)

Creates a new B<ABNF::Generator::Liar> object.

$grammar isa B<ABNF::Grammar>.

$validator isa B<ABNF::Validator>.

=cut

method new(ABNF::Grammar $grammar, ABNF::Validator $validator?) {
	$self->SUPER::new($grammar, $validator ? $validator : ());
}

=pod

=head1 $liar->C<generate>($rule, $tail="")

Generates one invalid sequence string for command $rule. 

Using cache $self->{_cache}->{$rule} for this rule, that speeds up this call.

$rule is a command name.

$tail is a string added to result if it absent.

dies if there is no command like $rule.

=cut

method _rule($rule, $recursion) {
	my $result = "";

	if ( my $prefix = splitRule($rule) ) {
		do {
			$result = _stringRand($ACHARS);
		} while $self->{_validator}->validateArguments($rule->{name}, $result);
		$result = $prefix . $result;
	} else {
		do {
			$result = _stringRand($ACHARS);
		} while $self->{_validator}->validate($rule->{name}, $result);
	}

	return {class => "Atom", value => $result};
}

func _stringRand($chars, $len?) {
	$len ||= rand($STRING_LEN) + 1;
	my @gen = ();
	for ( my $i = 0; $i < $len; $i++ ) {
		push(@gen, @$chars[rand @$chars]);
	}
	return join("", @gen);
}

=pod

=head1 $liar->C<withoutArguments>($name, $tail="")

Return a string starts like command $name and without arguments if it possible.

Return an empty string if command may have no arguments.

$tail is a string added to result if it absent.

dies if there is no command like $rule.

=cut

method withoutArguments(Str $name, Str $tail="") {
	my $result = $self->SUPER::withoutArguments($name, $tail);
	return $self->{_validator}->validate($name, $result) ? "" : $result;
}

=pod

=head1 $liar->C<unExistedCommand>()

Return an string starts with char sequence that doesn't match any command

$tail is a string added to result if it absent.

dies if there is no command like $rule.

=cut

method unExistedCommand(Str $tail="") {
	my $result = "";
	do {
		$result = _stringRand($ACHARS);
	} while $self->{_validator}->validateCommand($result);

	my $rx = eval { qr/$tail$/ };
	croak "Bad tail" if $@;
	return $result =~ $rx ? $result : $result . $tail;
}

=pod

=head1 $liar->C<endlessCommand>($name)

Return an string starts like command $name and length more then $ENDLESS = 513 * 1024 / 4

$tail is a string added to result if it absent.

dies if there is no command like $rule.

=cut

method endlessCommand($name, Str $tail="") {
	croak "Unexisted commadn $name" unless $self->hasCommand($name);
	my $prefix = splitRule($self->{_grammar}->rule($name));
	my $result = $prefix . _stringRand($ACHARS, $ENDLESS);
	my $rx = eval { qr/$tail$/ };
	croak "Bad tail" if $@;
	return $result =~ $rx ? $result : $result . $tail;
}

=pod

=head1 FUNCTIONS

=head1 C<Liar>()

Return __PACKAGE__ to reduce class name :3

=cut

func Liar() {
	return __PACKAGE__;
}

1;

=pod

=head1 AUTHOR / COPYRIGHT / LICENSE

Copyright (c) 2013 Arseny Krasikov <nyaapa@cpan.org>.

This module is licensed under the same terms as Perl itself.

=cut