package ABNF::Grammar;

=pod

=head1 NAME

B<ABNF-Grammar> - validator and generator for ABNF grammars.

B<ABNF::Grammar> - class for inner representation ABNF-grammar.

=head1 VERSION

This document describes B<ABNF::Grammar> version 0.08

=head1 SYNOPSIS

use ABNF::Grammar qw(Grammar);

use ABNF::Generator qw(asStrings);

use ABNF::Generator::Honest qw(Honest);

use ABNF::Generator::Liar qw(Liar);

use ABNF::Validator qw(Validator);

my $grammar = Grammar->new("smtp.bnf", qw(ehlo helo mail rcpt data rset vrfy noop quit data data-terminate));
my $valid = Validator->new($grammar);
my $liar = Liar->new($grammar, $valid);
my $honest = Honest->new($grammar, $valid);

$valid->validate("vrfy", "string");

my @strings = $liar->withoutArguments("vrfy");

my $string = $liar->unExistedCommand("vrfy");

my $string = $liar->endlessCommand("vrfy");

my $string = $liar->generate("helo");

my $string = $honest->generate("helo");

=head1 DESCRIPTION

This module parses IETF ABNF (STD 68, RFC 5234, 4234, 2234) grammars
via B<Parse::ABNF> and provides tools to :

=over 4

=item * verify validity of string

=item * generate valid messages

=item * generate invalid messages

=back

=head1 METHODS

=cut

use 5.014;

use strict;
use warnings;

use Carp;
use Readonly;
use Method::Signatures;
use Data::Dumper;

use Parse::ABNF;
use Storable qw(dclone);

use base "Exporter";
our @EXPORT_OK = qw(splitRule Grammar $BASIC_RULES);
our $VERSION = "0.08";

Readonly our $BASIC_RULES => do {
	my $res = {};
	foreach my $rule ( @{$Parse::ABNF::CoreRules} ) {
		die "Multiple definitions for $rule->{name}" if exists($res->{$rule->{name}});
		$res->{$rule->{name}} = $rule;
	}

	$res;
};

=pod

=head1 ABNF::Grammar->C<new>($fname, @commands)

Creates a new B<ABNF::Grammar> object.

Read ABNF rules from file with $fname.

@commands consists of main command names for generation and validation.

=cut

method new(Str $fname, @commands) {

	my $class = ref($self) || $self;

	$self = {_commands => { map {$_ => 1} @commands} };

	bless($self, $class);


	open(my $file, $fname)
	or croak "Cant open $fname";

	my $content = join("", <$file>) . "\n";

	close($file)
	or carp "Cant close $fname";	

	$self->_init($content);

	foreach my $command ( @commands ) {
		croak "Grammar doesn't have command $command" unless exists($self->{_rules}->{$command});
	}

	return $self;
}

=pod

=head1 ABNF::Grammar->C<fromString>($content, @commands)

Creates a new B<ABNF::Grammar> object.

Get ABNF rules from string $rule

@commands consists of main command names for generation and validation.

=cut

method fromString(Str $content, @commands) {

	my $class = ref($self) || $self;

	$self = {_commands => { map {$_ => 1} @commands} };

	bless($self, $class);

	$self->_init($content . "\n");

	foreach my $command ( @commands ) {
		croak "Grammar doesn't have command $command" unless exists($self->{_rules}->{$command});
	}

	return $self;
}

method _init($content) {

	my $parser = Parse::ABNF->new();
	my $rules = $parser->parse($content)
	or croak "Bad rules";

	foreach my $rule ( @$rules ) {
		croak "Multiple definitions for $rule->{name}" if exists($self->{_rules}->{$rule->{name}});
		$self->{_rules}->{$rule->{name}} = $rule;
	}

}

=pod

=head1 $grammar->C<rule>($name)

Return rule form $name with name $name.

Result structure is identical to B<Parse::ABNF> structure.

For debug only.

Do not modify result structure.

=cut

method rule(Str $name) {
	croak "Unexisted rule $name" unless exists($self->{_rules}->{$name});
	$self->{_rules}->{$name};
}

=pod

=head1 $grammar->C<rules>()

Return all rules.

Result structures is identical to B<Parse::ABNF> structure.

For debug only.

Do not modify result structure.

=cut

method rules() {
	$self->{_rules};
}

=pod

=head1 $grammar->C<replaceRule>($rule, $value)

Replace $rule with $value.

For debug use only.

dies if there is no rule like $rule.

=cut

method replaceRule(Str $rule, $value) {
	croak "Unexisted rule $rule" unless exists($self->{_rules}->{$rule});
	croak "new value name must be equal to rule" unless $value->{name} eq $rule;
	$self->{_rules}->{$rule} = $value;
}

=pod

=head1 $grammar->C<replaceBasicRule>($rule, $value)

Replace $rule with $value.

For debug use only.

dies if there is no rule like $rule.

=cut

method replaceBasicRule(Str $rule, $value) {
	croak "Unexisted rule $rule" unless exists($BASIC_RULES->{$rule});
	croak "new value name must be equal to rule" unless $value->{name} eq $rule;
	$BASIC_RULES->{$rule} = $value;
}


=pod

=head1 $grammar->C<hasCommand>($name)

Return 1 if $name is command, 0 otherwise.

=cut

method hasCommand(Str $name) {
	exists $self->{_commands}->{$name};
}

=pod

=head1 $grammar->C<commands>()

Return all grammar commands as arrayref.

=cut

method commands() {
	[ keys $self->{_commands} ]
}

=pod

=head1 FUNCTIONS

=head1 C<splitRule>($rule)

In scalar context return prefix only, in list -- prefix and arguments rules.

$rule is structure that returns from C<rule> and like in B<Parse::ABNF>.

=cut

func splitRule($rule) {
	my $value = $rule->{value};
	my $prefix = "";

	if (
		   $value->{class} eq 'Group'
		&& $value->{value}->[0]->{class} eq 'Literal'
	) {
		$prefix = $value->{value}->[0]->{value};
		$value = dclone($value);
		shift($value->{value});
		if (
			   $value->{value}->[0]->{class} eq 'Reference'
			&& $value->{value}->[0]->{name} eq 'SP'
		) {
			$prefix .= "\x20";
			shift($value->{value});
		}

		if (
			   $value->{value}->[-1]->{class} eq 'Reference'
			&& $value->{value}->[-1]->{name} eq 'CRLF'
		) {
			pop($value->{value});
		}
	}

	return wantarray ? ($prefix, $value) : $prefix;
}

=pod

=head1 C<Grammar>()

Return __PACKAGE__ to reduce class name :3

=cut

func Grammar() {
	return __PACKAGE__;
}


1;

__END__

=pod

=head1 DEPENDENCIES

=over 4

=item B<Parse::ABNF>

=item B<Regexp::Grammars>

=item B<Storable>

=item B<Method::Signatures>

=item B<Readonly>

=item B<perl 5.014>

=back

=head1 BUG REPORTS

Please report bugs in this module via <nyaapa@cpan.org>

=head1 SEE ALSO

=over 4

=item * ABNF RFC

L<http://www.ietf.org/rfc/rfc5234.txt>

=item * Abnf parser

L<Parse::ABNF>

=item * Validator base

L<Regexp::Grammars>

=item * Cool guy from monks with idea how to validate

L<http://www.perlmonks.org/?node_id=957506>

=back

=head1 AUTHOR / COPYRIGHT / LICENSE

Copyright (c) 2013 Arseny Krasikov <nyaapa@cpan.org>.

This module is licensed under the same terms as Perl itself.

=cut