package ABNF::Validator;

=pod

=head1 NAME

ABNF::Validator - class to verify strings based on ABNF-grammars

=head1 DESCRIPTION

=head1 METHODS

=cut

use 5.014;

use strict;
use warnings;
use re 'eval';

use Carp;
use Readonly;
use Method::Signatures;
use Data::Dumper;

use Parse::ABNF;

use ABNF::Grammar qw(splitRule $BASIC_RULES);

use base qw(Exporter);

our @EXPORT_OK = qw(Validator);

Readonly my $ARGUMENTS_RULES => "generic_arguments_rule_for_";

Readonly my $CLASS_MAP => {
	Choice => \&_choice,
	Group => \&_group,
	Range => \&_range,
	Reference => \&_reference,
	Repetition => \&_repetition,
	Rule => \&_rule,
	String => \&_string,
	Literal => \&_literal,
	ProseValue => \&_proseValue
};

=pod

=head1 ABNF::Validator->C<new>($grammar)

Creates a new B<ABNF::Validator> object.

$grammar isa B<ABNF::Grammar>.

=cut

method new(ABNF::Grammar $grammar) {

	my $class = ref($self) || $self;

	$self = { _grammar => $grammar };

	bless($self, $class);

	$self->_init();

	return $self;
}

method _init() {
	my $commands = $self->{_grammar}->commands();
	$self->{_commandsPattern} = do {
		my $pattern = join(" | ", @$commands);
		qr/\A (?: $pattern ) \Z/ix;
	};

	$self->{_rules} = _value([
		values($self->{_grammar}->rules()),
		values($BASIC_RULES)
	]);

	$self->{_regexps} = do {
		use Regexp::Grammars;

		my %res = ();
		foreach my $token ( @$commands ) {
			# command
			my $str = "
					#<logfile: /dev/null>

					^ <" . _fixRulename($token) . "> \$

					$self->{_rules}
			";
			$res{$token} = qr{$str }ixs;

			# arguments
			my $value = $self->{_grammar}->rule($token);
			my $name = _fixRulename($ARGUMENTS_RULES . $token);
			my $rule = {class => "Rule", name => $name};
			my $val = (splitRule($value))[-1];

			if ( $value->{value} != $val ) {
				$rule->{value} = $val;
				my $converted = _value($rule);
				$res{$name} = qr{
					^ <$name> $

					$converted

					$self->{_rules}
				}xis;
			}
		}

		\%res;
	};
}

func _value($val, $dent = 0) {

	if ( UNIVERSAL::isa($val, 'ARRAY') ) {
		return join('', map { _value($_ , $dent) } @$val);
	} elsif ( UNIVERSAL::isa($val, 'HASH') && exists($CLASS_MAP->{ $val->{class} }) ) {
		return $CLASS_MAP->{ $val->{class} }->($val, $dent);
	} else {
		croak "Unknown substance " . Dumper($val);
	}
}


func _choice($val, $dent) {
    return "(?: " . join(' | ', map { _value($_ , $dent + 1) } @{$val->{value}}) . ")";
}

func _group($val, $dent) {
    return '(?: ' . _value($val->{value}, $dent + 1) . ' )';
}

func _reference($val, $dent) {
    return "<" . _fixRulename($val->{name}) . ">";
}

func _repetition($val, $dent) {

    no warnings 'uninitialized';
    my %maxMin = (
        # max min
        "1 0" => '?',
        " 0"  => '*',
        " 1"  => '+',
    );

    if ( my $mm = $maxMin{"$val->{max} $val->{min}"} ) {
        return " (?: " . _value($val->{value}, $dent + 1) . " )$mm ";
    } elsif( $val->{min} == $val->{max} ){
        return " (?: ". _value($val->{value}, $dent + 1) . " ){$val->{max}} ";
    } else {
        return " (?: " . _value($val->{value}, $dent+1) . " ){$val->{min}, $val->{max}} ";
    }
}

func _rule($val, $dent) {
    my $ret = "";
    my $name = $val->{name};

    if ( 'ws' eq lc($name) ) {
        warn "Changing rule ws to token to avoid 'infinitely recursive unpleasantness.'\n";
        $ret .= "<rule: ws>\n  "; # may be token
    } else {
        $ret .= "<token: " . _fixRulename($val->{name}) . ">\n  ";
    }
    $ret .= _value($val->{value}, $dent + 1);
    $ret . "\n\n";
}

#~ @{[_fixRulename($$v{name})]}
func _fixRulename($name) {
    $name =~ s/[-\W]/_/g;
    $name;
}

func _range($val, $dent) {
    my $ret = "";
    $ret .= '[';
    given ( $val->{type} ) {
		when ( 'hex' ) {
			$ret .= join('-', map { '\x{' . $_ . '}' } $val->{min}, $val->{max});
		}
		when ( 'binary' ) {
	        $ret .= join('-', map { sprintf('\\%o', oct("0b$_")) } $val->{min}, $val->{max});
	    }
		when ( 'decimal' ) {
			$ret .= join('-', map { sprintf('\\%o', $_) } $val->{min}, $val->{max});
		}
		default {
			croak "## Range type $val->{type}  $val->{value} \n";
		}
	}
    $ret .= "]";
    $ret;
}

func _string($val, $dent) {
    my $ret = "";
    given ( $val->{type} ) {
		when ( 'hex' ) {
		    $ret = join('', map { '\x' . $_ } @{$val->{value}});
		}
		when ( 'binary' ) {
			$ret .= join('', map { sprintf('\\%o', oct("0b$_")) } @{$val->{value}});
		}
		when ( 'decimal' ) {
			$ret .= join('', map { sprintf('\\%o', $_) } @{$val->{value}});
		}
		default {
			die "## String type $val->{type}  $val->{value} \n";
		}
#~         warn "##",  map({ "$_ ( $val->{$_} ) " } sort keys %$val ), "\n";
    }
#~     " $ret ";
    $ret;
}

func _literal($val, $dent) {
    return quotemeta($val->{value});
}

func _proseValue($val, $dent) {
	return "<" . _fixRulename($val->{value}) . ">";
}

=pod

=head1 $validator->C<validate>($rule, $string)

Return 1 if $string matches $rule and 0 otherwise.

$rule is rulename.

$string is arguments string.

dies if there is no command like $rule.

=cut

method validate(Str $rule, Str $string) {
	croak "Unexisted command $rule" unless exists($self->{_regexps}->{$rule});
	scalar($string =~ $self->{_regexps}->{$rule});
}

=pod

=head1 $validator->C<validateArguments>($rule, $string)

Return 1 if $string matches arguments rules form $rule and 0 otherwise.

$rule is rulename.

$string is arguments string.

dies if there is no command like $rule.

=cut


method validateArguments($rule, $string) {
	croak "Unexisted command $rule" unless exists($self->{_regexps}->{$rule});
	my $args = _fixRulename($ARGUMENTS_RULES . $rule);
	scalar(exists($self->{_regexps}->{$args}) && ($string =~ $self->{_regexps}->{$args}));
}

=pod

=head1 $validator->C<validateCommand>($command)

Return 1 if there exists command like $command and 0 otherwise

=cut

method validateCommand($command) {
	return $command =~ $self->{_commandsPattern};
}

=pod

=head1 $validator->C<hasCommand>($command)

Return 1 if there exists command like $command and 0 otherwise

=cut

method hasCommand($command) {
	return exists($self->{_regexps}->{$command});
}

=pod

=head1 FUNCTIONS

=head1 C<Validator>()

Return __PACKAGE__ to reduce class name :3

=cut

func Validator() {
	return __PACKAGE__;
}

1;

=pod

=head1 AUTHOR / COPYRIGHT / LICENSE

Copyright (c) 2013 Arseny Krasikov <nyaapa@cpan.org>.

This module is licensed under the same terms as Perl itself.

=cut